// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use IO:File:Path;
use IO:File;
use System:Random;
use UI:WebBrowser as WeBr;
use Test:Assertions as Assert;
use Db:Relational:Database as DbDb;
use Db:Relational:Statement as DbSt;
use System:Thread:Lock;
use System:Thread:ContainerLocker as CLocker;
use System:Command as Com;
use Time:Sleep;
use System:Parameters;

use App:Alert;
use App:AppStart;
use App:CallBackUI;

use Net:UPnP as Upnp;
use Net:IP;

use App:LocalWebApp;
use App:RemoteWebApp;
use App:WebApp;
use IUHub:HubPlugin;

emit(jv) {
"""
//import java.io.*;
import java.net.*;
"""
}
use class IUBridge:BridgeStart {

   new() self {
      fields {
          IO:Log log =@ IO:Logs.get(self);
        }
    }
    
}

use System:Thread:ObjectLocker as OLocker;

use Crypto:Symmetric as Crypt;
use class IUBridge:BridgePlugin(HubPlugin) {

   new() self {
     fields {
      Ssh ssh;
      Set rforwarded;
      App:Background bfw = App:Background.new();
      App:Background bup = App:Background.new();
      App:Background bcf = App:Background.new();
      String profile = "bridge";
      String defaultUpnpF = "true";
      String defaultInternalResolveF = "false";
     }
     super.new();
     
   }
   
   nameGet() String {
       String name =@ "KBridge";
       return(name);
     }
   
   runBackgroundTasks() {
      bfw.runMyTasks();
      bup.runMyTasks();
      bcf.runMyTasks();
   }
   
   startLinkRequest(request) Map {
    return(CallBackUI.hideNShowOneResponse("devicelogindiv"));
   }
   
   getRemoteListenRequest(request) Map {
     
     String br = app.configManager.get("il.sshBridgedHost");
     if (TS.isEmpty(br)) {
      br = "(None)";
     }
     
     Map hb = Map.new();
     Map hsip = Map.new();
     Map links = getLinks(null);
     for (auto kv in links) {
      WebConnect wc = kv.value;
      if (TS.notEmpty(wc.deviceName) && TS.notEmpty(wc.hostedAddress)) {
        if (def(wc.onPublicNet) && wc.onPublicNet) {
          hb.put(wc.deviceName, wc.deviceName);
        } else {
          hsip.put(wc.deviceName, wc.deviceName);
        }
      }
     }
     hb.put("(None)", "(None)");
     hsip.put("(None)", "(None)");
     
     //, CallBackUI.setOptionsResponse("sipBridges", hsip)
     return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsValuesResponse(Maps.from("sshHost", app.configManager.get("il.sshHost", ""), "sshPort", app.configManager.get("il.sshPort", ""), "sshLogin", app.configManager.get("il.sshLogin", ""))), CallBackUI.hideNShowListResponse(Lists.from("remoteaccessdiv")), CallBackUI.setOptionsSelectedResponse("hostedBridges",hb, br), CallBackUI.setOptionsResponse("sipBridges", hsip))));
   }
   
   getRemoteAccessRequest(request) Map {
   
     return(CallBackUI.setElementsInnerHTMLResponse(Maps.from("forwardPortsListDiv", getForwardPortsList())));
   }
   
   getRemoteAccessRequest(String loadPort, request) Map {
   
     //return(CallBackUI.hideNShowListResponse(Lists.from("forwardPortsDiv")));
     if (TS.isEmpty(loadPort)) {
      return(getRemoteAccessRequest(request));
     }
     return(CallBackUI.multiResponse(Lists.from(loadForwardPortRequest(loadPort, request), CallBackUI.setElementsInnerHTMLResponse(Maps.from("forwardPortsListDiv", getForwardPortsList())))));
   }
   
   setCamPortsRequest(request) Map {
      String camPort = app.configManager.get("webApp.Cam.web.port");
      if (TS.notEmpty(camPort)) {
        Map pset = Maps.from("fpPort", camPort, "fpExPort", camPort);
        String camiPort = app.configManager.get("webApp.Cam.int.web.port");
        if (TS.notEmpty(camiPort)) {
          pset["fpiPort"] = camiPort;
        }
        return(CallBackUI.setElementsValuesResponse(pset));
      }
      return(CallBackUI.informResponse("Please enable IU Cam from the Apps menu before setting up"));
   }
   
   setDomoPortsRequest(request) Map {
      String camPort = app.configManager.get("webApp.Domo.web.port");
      if (TS.notEmpty(camPort)) {
        Map pset = Maps.from("fpPort", camPort, "fpExPort", camPort);
        String camiPort = app.configManager.get("webApp.Domo.int.web.port");
        if (TS.notEmpty(camiPort)) {
          pset["fpiPort"] = camiPort;
        }
        return(CallBackUI.setElementsValuesResponse(pset));
      }
      return(CallBackUI.informResponse("Please enable Domo from the Apps menu before setting up"));
   }
   
   setNxcPortsRequest(request) Map {
      String camPort = app.configManager.get("webApp.Nxc.web.port");
      if (TS.notEmpty(camPort)) {
        Map pset = Maps.from("fpPort", camPort, "fpExPort", camPort);
        String camiPort = app.configManager.get("webApp.Nxc.int.web.port");
        if (TS.notEmpty(camiPort)) {
          pset["fpiPort"] = camiPort;
        }
        return(CallBackUI.setElementsValuesResponse(pset));
      }
      return(CallBackUI.informResponse("Please enable Nxc from the Apps menu before setting up"));
   }
   
   getSipRequest(Map args, request) Map {
     
     unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
     }
     Map sipi = Map.new();
     for (String k in Lists.from("il.sshHost", "il.sshLogin", "il.sshPass", "il.sshPort")) {
      sipi.put(k, app.configManager.get(k));
     }
     return(sipi);
   }
   
   getSipFromBridgeRequest(String sipBridge, String sipLogin, String sipPass, request) Map {
    log.log("getting sip");
    
    unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    
    String destUrl;
    
    //find the wc and get it
    //use the hosted one ;-)
    
    Map links = getLinks(null);
     for (auto kv in links) {
      WebConnect wc = kv.value;
      if (TS.notEmpty(wc.deviceName) && wc.deviceName == sipBridge) {
        destUrl = wc.hostedBase;
      }
     }
    
    log.log("now sip " + destUrl);
    
    Map argOut = Map.new();
    argOut["accountName"] = sipLogin;
    argOut["accountPass"] = sipPass;
    argOut["sessionLength"] = "60";
    argOut["action"] = "loginRequest";
    argOut["serviceLogin"] = "yup";
    
    Web:Client client = Web:Client.new();
    String payload = Json:Marshaller.marshall(argOut);
    client.outputHeaders.put("referer", destUrl + "/App/KBridge/Konn.html");
    client.url = destUrl;
    
    try {
      //ifEmit(appDebug) {
        //Web:Client:CertificateManager.validateHosts = false; //appDebug
        //Web:Client:CertificateManager.validateCertificates = false; //appDebug
      //}
      //Web:Client:CertificateManager.acceptedThumbprints.put(wco.certificatePrint);
      client.openOutput().write(payload);
      String res = client.openInput().readString();
      log.log("GOT SOMETHING BACK!!!");
      client.close();
      if (TS.notEmpty(res)) {
        log.log("res " + res);
        Map resMap = Json:Unmarshaller.unmarshall(res);
        //prep next call
        Map ds = Map.new();
        ds["serviceSessionKey"] = resMap["serviceSessionKey"];
        ds["pageToken"] = resMap["pageToken"];
        ds["destUrl"] = destUrl;
        ds["certificatePrint"] = resMap["certificatePrint"];
        
        String dss = Json:Marshaller.marshall(ds);
        log.log("login for sip sldss " + dss);
        
        //call the api and get creds
        
        log.log("calling for sip creds " + destUrl);
        argOut = Map.new();
        argOut["action"] = "getSipRequest";
        argOut["pageToken"] = ds["pageToken"];
        argOut["serviceSessionKey"] = ds["serviceSessionKey"];
        //ifEmit(appDebug) {
          //Web:Client:CertificateManager.validateHosts = false; //appDebug
          //Web:Client:CertificateManager.validateCertificates = false; //appDebug
        //}
        //Web:Client:CertificateManager.acceptedThumbprints.put(ds["certificatePrint"]);
        client = Web:Client.new();
        payload = Json:Marshaller.marshall(argOut);
        log.log("payload " + payload);
        client.outputHeaders.put("referer", destUrl + "/App/KBridge/Konn.html");
        client.url = destUrl;
        client.openOutput().write(payload);
        res = client.openInput().readString();
        client.close();
        if (TS.notEmpty(res)) {
          resMap = Json:Unmarshaller.unmarshall(res);
          log.log("!!! got res from getSip  " + res);
          for (String k in Lists.from("il.sshHost", "il.sshLogin", "il.sshPass", "il.sshPort")) {
            app.configManager.put(k, resMap.get(k));
          }
        }
        
      }
      //resetCertMan(ds["certificatePrint"]);
    } catch(any e) {
      //resetCertMan(ds["certificatePrint"]);
      log.error("Failure during getsip");
      if (def(e)) {
        log.error("error " + e);
      }
    }
    reforwardAsync();
    return(CallBackUI.informResponse("Setup Successful"));
   }
   
   gcpLaunchRequest(String jsonCreds, request) Map {
    log.log("in gcpLaunchRequest");
    unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    
    log.log("unmarshlling jcr");
    Map jcr = Json:Unmarshaller.unmarshall(jsonCreds);
    log.log("done unmarshlling jcr");
    
    auto cm = app.configManager;
    
    String prid = jcr.get("project_id");
    cm.put("gcp.prid", prid);
    log.log("prid " + prid);
    
    //file, inst, user, pass
    file = cm.get("gcp.file");
    if (TS.isEmpty(file)) {
    Int addLen = System:Random.getIntMax(4);
    String file = "./" + System:Random.getString(8 + addLen).lower() + ".txt";
    cm.put("gcp.file", file);
    }
    if (File.apNew(file).exists) { File.apNew(file).delete(); }
    inst = cm.get("gcp.inst");
    if (TS.isEmpty(inst)) {
    addLen = System:Random.getIntMax(4);
    String inst = System:Random.getString(8 + addLen).lower();
    cm.put("gcp.inst", inst);
    }
    user = cm.get("gcp.user");
    if (TS.isEmpty(user)) {
    addLen = System:Random.getIntMax(4);
    String user = System:Random.getString(8 + addLen).lower();
    cm.put("gcp.user", user);
    }
    pass = cm.get("gcp.pass");
    if (TS.isEmpty(pass)) {
    addLen = System:Random.getIntMax(4);
    String pass = System:Random.getString(16 + addLen).lower();
    cm.put("gcp.pass", pass);
    }
    
    String uinst = user + "@" + inst;
    
    WebConnect wc = app.plugin.wcol.o;
    String gcname = wc.konnsName;
    String gctok = wc.sipTok;
    
    if (TS.isEmpty(gcname) || TS.isEmpty(gctok)) {
      throw(Alert.new("Must link to abelii.net before launching google cloud host."));
    }
    
    log.log("file inst user pass " + file + " " + inst + " " + user + " " + pass);
    File.apNew(file).writer.open().writeStringClose(jsonCreds);
    runCmd("gcloud auth activate-service-account --key-file=" + file);
    runCmd("gcloud config set project " + prid);
    runCmd("gcloud services enable compute.googleapis.com");
    runCmd("gcloud compute firewall-rules create allow-all --network default --action allow --direction ingress --rules all --source-ranges 0.0.0.0/0 --priority 1000");
    runCmd("gcloud compute instances create " + inst + " --image-family debian-9 --image-project debian-cloud --machine-type f1-micro --zone us-west1-a --metadata startup-script-url=https://www.abelii.net/App/KRouter/gcsetup.sh,gcuser=" + user + ",gcpass=" + pass + ",gcname=" + gcname + ",gctok=" + gctok); //token and dns
    
    //setup ilssh with config
    //il.sshHost, il.sshLogin, il.sshPass, il.sshPort
    String shname = gcname.lower() + ".abelii.net";
    app.configManager.put("il.sshHost", shname);
    app.configManager.put("il.sshLogin", user);
    app.configManager.put("il.sshPass", pass);
    app.configManager.put("il.sshPort", "22");
    
    //redoforward (from web page?)
    reforwardAsync();
    
    return(CallBackUI.informResponse("Setup Tried"));
    
   }
   
   runCmd(String cmd) {
     log.log("run cmd " + cmd);
     String res = System:Command.new(cmd).open().output.readStringClose();
     log.log("output " + res);
   }
   
   routerLinkRequest(String account, String pass, request) Map {
    log.log("in router link request");
    unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    unlinkAllRequest(request);
    String rtrurl = app.configManager.get("router.Url");
    if (TS.isEmpty(rtrurl)) {
      rtrurl = "https://www.abelii.net";
    }
    
    Account a = request.context.get("account");
    return(routerLink(rtrurl, a.user, account, pass));
    }
   
   routerLink(String url, String auser, String account, String pass) Map {
    log.log("linking");
    
    log.log("get the devicename deviceid going");
    String dn = self.deviceName;
    String did = self.deviceId;
    
    String destUrl = url;
    
    
    log.log("now link " + destUrl);
    
    Map argOut = Map.new();
    argOut["accountName"] = account;
    argOut["accountPass"] = pass;
    argOut["sessionLength"] = "-1";
    argOut["action"] = "loginRequest";
    argOut["serviceLogin"] = "yup";
    
    Web:Client client = Web:Client.new();
    String payload = Json:Marshaller.marshall(argOut);
    client.outputHeaders.put("referer", destUrl);
    client.url = destUrl;
    
    try {
      //ifEmit(appDebug) {
        //Web:Client:CertificateManager.validateHosts = false; //appDebug
        //Web:Client:CertificateManager.validateCertificates = false; //appDebug
      //}
      //Web:Client:CertificateManager.acceptedThumbprints.put(wco.certificatePrint);
      client.openOutput().write(payload);
      String res = client.openInput().readString();
      log.log("GOT SOMETHING BACK!!!");
      client.close();
      if (TS.notEmpty(res)) {
        log.log("res " + res);
        Map resMap = Json:Unmarshaller.unmarshall(res);
        //store stuff
        Map ds = Map.new();
        ds["serviceSessionKey"] = resMap["serviceSessionKey"];
        ds["pageToken"] = resMap["pageToken"];
        ds["destUrl"] = destUrl;
        ds["certificatePrint"] = resMap["certificatePrint"];
        String dss = Json:Marshaller.marshall(ds);
        log.log("sldss " + dss);
        app.kvdbs.get("DEVLINKS").put("LinkSession." + auser + "!" + destUrl, dss);
        //if (true) { resetCertMan(wco.certificatePrint); return(checkConnInner(wco, ds, destUrl)) };
        
        app.configManager.put("router.accountName", account);
        doUpdate();
        updateNames();
        
      }
      //resetCertMan(ds["certificatePrint"]);
    } catch(any e) {
      //resetCertMan(ds["certificatePrint"]);
      throw(e);
    }
    return(CallBackUI.informResponse("Device Link Successful"));
   }
   
   routerUpdate() {
   
    log.log("doing routerUpdate");
    loadWc();
    log.log("get the devicename deviceid going");
    String dn = self.deviceName;
    String did = self.deviceId;
    
    log.log("first do update");
    
    doForward(); //includes an update
        
   }
   
   unlinkAllRequest(request) {
     unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    
    Json:Unmarshaller unmar = Json:Unmarshaller.new();
    Json:Marshaller mar = Json:Marshaller.new();
    WebConnect wc = app.plugin.wcol.o;
    
    Map lss = app.kvdbs.get("DEVLINKS").getMap("LinkSession.");
     for (auto kv in lss) {
       Map ds = unmar.unmarshall(kv.value);
       if (def(wc)) {
        removeMyLink(wc, ds);
       }
       app.kvdbs.get("DEVLINKS").delete(kv.key);
     }
     if (def(wc)) {
      log.log("clearing wc konnname");
      wc.konnName = null;
      wc.konniName = null;
      wc.konnsName = null;
      if (TS.notEmpty(wc.konnAddress) && wc.konnAddress.ends("abelii.net")) {
        wc.konnAddress = null;
      }
      if (TS.notEmpty(wc.konniAddress) && wc.konniAddress.ends("abelii.net")) {
        wc.konniAddress = null;
      }
     }
     app.configManager.put("hub.webConnect", Json:Marshaller.marshall(wc.toMap()));
     clearAllDevsRequest(request);
   }
   
   clearAllDevsRequest(request) {
     unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    Map lss = app.kvdbs.get("DEVLINKS").getMap("devlink!");
     for (auto kv in lss) {
       app.kvdbs.get("DEVLINKS").delete(kv.key);
     }
   }
   
   updateMyLinks() {
     WebConnect wc = app.plugin.wcol.o;
     Json:Unmarshaller unmar = Json:Unmarshaller.new();
     Json:Marshaller mar = Json:Marshaller.new();
     Map lss = app.kvdbs.get("DEVLINKS").getMap("LinkSession.");
     for (auto kv in lss) {
       Map ds = unmar.unmarshall(kv.value);
       Map res = updateMyLink(wc, ds);
     }
     if (def(res) && res.has("links")) {
      KvDb knwc = app.kvdbs.get("KNAMEWCS");
      for (Map lm in res.get("links")) {
        log.log("putting into links");
        WebConnect awc = WebConnect.new().fromMap(lm);
        String conjs = mar.marshall(lm);
        app.kvdbs.get("DEVLINKS").put("devlink!" + awc.deviceId, conjs);
        log.log("awc did " + awc.deviceId + " wc did " + wc.deviceId);
        if (awc.deviceId == wc.deviceId) {
          //now with konnName et all
          app.plugin.wcol.o = awc;
          app.configManager.put("hub.webConnect", conjs);
          //update authedurls
          log.log("put awc in for webcon " + conjs);
        }
        if (TS.notEmpty(awc.konnName)) {
          knwc.put(awc.konnName, conjs);
        }
      }
     }
   }
   
   checkUpnp() {
     //hit own endpoint, register if hit on own side
     //do name lookup for reserved ip
   }
   
   updateMyLink(WebConnect wco, Map ds) Map {
    try {
      String destUrl = ds["destUrl"];
      log.log("sending wc to " + destUrl);
      Map argOut = Map.new();
      argOut["action"] = "updateLinkRequest";
      argOut["pageToken"] = ds["pageToken"];
      argOut["serviceSessionKey"] = ds["serviceSessionKey"];
      argOut["wc"] = wco.toMap();
      //ifEmit(appDebug) {
        //Web:Client:CertificateManager.validateHosts = false; //appDebug
        //Web:Client:CertificateManager.validateCertificates = false; //appDebug
      //}
      //Web:Client:CertificateManager.acceptedThumbprints.put(ds["certificatePrint"]);
      Web:Client client = Web:Client.new();
      String payload = Json:Marshaller.marshall(argOut);
      log.log("payload " + payload);
      client.outputHeaders.put("referer", destUrl);
      client.url = destUrl;
      client.openOutput().write(payload);
      String res = client.openInput().readString();
      client.close();
      if (TS.notEmpty(res)) {
        Map resMap = Json:Unmarshaller.unmarshall(res);
        log.log("!!! got res from updatelink  " + res);
      }
      //resetCertMan(ds["certificatePrint"]);
      //ifEmit(appDebug) {
        //Web:Client:CertificateManager.validateHosts = true; //appDebug
        //Web:Client:CertificateManager.validateCertificates = true; //appDebug
      //}
    } catch (any e) {
      //resetCertMan(ds["certificatePrint"]);
      //ifEmit(appDebug) {
        //Web:Client:CertificateManager.validateHosts = true; //appDebug
        //Web:Client:CertificateManager.validateCertificates = true; //appDebug
      //}
      log.error("got exception during updatemylink");
      if (def(e)) { log.error(e.toString()); }
    }
    return(resMap);
  }
  
  getCertLeab(String domain, String action) {
    loadWc();
    WebConnect wc = app.plugin.wcol.o;
     Json:Unmarshaller unmar = Json:Unmarshaller.new();
     Json:Marshaller mar = Json:Marshaller.new();
     Map lss = app.kvdbs.get("DEVLINKS").getMap("LinkSession.");
     for (auto kv in lss) {
       Map ds = unmar.unmarshall(kv.value);
       Int i = 0;
       Bool done = false;
       while (i < 3 && done!) {
         log.log("trying leab");
         Map res = getCertLeab(wc, ds, domain, action);
         if (res.has("key") && res.has("crt")) {
          log.log("got key crt");
          done = true;
          auto crt = File.apNew(".lego/certificates/" + domain + ".abelii.net.crt");
          auto key = File.apNew(".lego/certificates/" + domain + ".abelii.net.key");
          if (crt.exists) { crt.delete(); }
          if (key.exists) { key.delete(); }
          if (crt.path.parent.file.exists!) { crt.path.parent.file.mkdirs(); }
          crt.writer.open().writeStringClose(res["crt"]);
          key.writer.open().writeStringClose(res["key"]);
          reforward();
         } else {
          Time:Sleep.sleepSeconds(1);
         }
      }
     }
  }
  
  getCertLeab(WebConnect wco, Map ds, String domain, String action) Map {
    try {
      String destUrl = ds["destUrl"];
      log.log("getting cert for " + destUrl);
      Map argOut = Map.new();
      argOut["action"] = "leabRequest";
      argOut["pageToken"] = ds["pageToken"];
      argOut["serviceSessionKey"] = ds["serviceSessionKey"];
      argOut["args"] = Lists.from(wco.deviceId, domain, action);
      //ifEmit(appDebug) {
        //Web:Client:CertificateManager.validateHosts = false; //appDebug
        //Web:Client:CertificateManager.validateCertificates = false; //appDebug
      //}
      Web:Client client = Web:Client.new();
      String payload = Json:Marshaller.marshall(argOut);
      log.log("payload " + payload);
      client.outputHeaders.put("referer", destUrl);
      client.url = destUrl;
      client.openOutput().write(payload);
      String res = client.openInput().readString();
      client.close();
      if (TS.notEmpty(res)) {
        Map resMap = Json:Unmarshaller.unmarshall(res);
        log.log("!!! got res from leab  " + res);
      }
      //resetCertMan(ds["certificatePrint"]);
      //ifEmit(appDebug) {
        //Web:Client:CertificateManager.validateHosts = true; //appDebug
        //Web:Client:CertificateManager.validateCertificates = true; //appDebug
      //}
      
    } catch (any e) {
      //resetCertMan(ds["certificatePrint"]);
      //ifEmit(appDebug) {
        //Web:Client:CertificateManager.validateHosts = true; //appDebug
        //Web:Client:CertificateManager.validateCertificates = true; //appDebug
      //}
      log.error("got exception during leab");
      if (def(e)) { log.error(e.toString()); }
    }
    return(resMap);
  }
  
  removeMyLink(WebConnect wco, Map ds) Map {
    try {
      String destUrl = ds["destUrl"];
      log.log("unlinking from " + destUrl);
      Map argOut = Map.new();
      argOut["action"] = "removeLinkRequest";
      argOut["pageToken"] = ds["pageToken"];
      argOut["serviceSessionKey"] = ds["serviceSessionKey"];
      argOut["args"] = Lists.from(wco.deviceId);
      //ifEmit(appDebug) {
        //Web:Client:CertificateManager.validateHosts = false; //appDebug
        //Web:Client:CertificateManager.validateCertificates = false; //appDebug
      //}
      Web:Client client = Web:Client.new();
      String payload = Json:Marshaller.marshall(argOut);
      log.log("payload " + payload);
      client.outputHeaders.put("referer", destUrl);
      client.url = destUrl;
      client.openOutput().write(payload);
      String res = client.openInput().readString();
      client.close();
      if (TS.notEmpty(res)) {
        Map resMap = Json:Unmarshaller.unmarshall(res);
        log.log("!!! got res from removeLink  " + res);
      }
      //resetCertMan(ds["certificatePrint"]);
      //ifEmit(appDebug) {
        //Web:Client:CertificateManager.validateHosts = true; //appDebug
        //Web:Client:CertificateManager.validateCertificates = true; //appDebug
      //}
    } catch (any e) {
      //resetCertMan(ds["certificatePrint"]);
      //ifEmit(appDebug) {
        //Web:Client:CertificateManager.validateHosts = true; //appDebug
        //Web:Client:CertificateManager.validateCertificates = true; //appDebug
      //}
      log.error("got exception during removeLink");
      if (def(e)) { log.error(e.toString()); }
    }
    return(resMap);
  }
  
  startLes() Map {
    Json:Unmarshaller unmar = Json:Unmarshaller.new();
    Map lss = app.kvdbs.get("DEVLINKS").getMap("LinkSession.");
    for (auto kv in lss) {
       Map ds = unmar.unmarshall(kv.value);
       Map res = startLe(ds);
     }
     return(res);
     
  }
  
  stopLes() Map {
    Json:Unmarshaller unmar = Json:Unmarshaller.new();
    Map lss = app.kvdbs.get("DEVLINKS").getMap("LinkSession.");
    for (auto kv in lss) {
       Map ds = unmar.unmarshall(kv.value);
       Map res = stopLe(ds);
     }
     return(res);
     
  }
  
  setupLe() Map {
     loadWc();
     WebConnect wc = app.plugin.wcol.o;
     //getCert or renewCert domain email
     String cmd = "./App/KBridge/getLE.sh getCert " + app.configManager.get("router.accountName") + " " + wc.konnAddress.lower();
     log.log("running " + cmd);
     String res = System:Command.new(cmd).open().output.readStringClose();
     log.log("res " + res);
     return(null);
  }
  
  startLe(Map ds) Map {
     loadWc();
     WebConnect wc = app.plugin.wcol.o;
     Json:Unmarshaller unmar = Json:Unmarshaller.new();
     Json:Marshaller mar = Json:Marshaller.new();
     return(Map.new());
  }
  
  stopLe(Map ds) Map {
     loadWc();
     WebConnect wc = app.plugin.wcol.o;
     Json:Unmarshaller unmar = Json:Unmarshaller.new();
     Json:Marshaller mar = Json:Marshaller.new();
     return(Map.new());
  }
  
  changePiPassRequest(String piUser, String piPass, String piPass2, request) {
    unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    if (TS.isEmpty(piUser)) {
      return(CallBackUI.informResponse("An SSH Username must be provided."));
    }
    if (TS.isEmpty(piPass) || piPass != piPass2) {
      return(CallBackUI.informResponse("New and Repeat SSH Passwords don't match."));
    }
    System:Command.new("./App/KBridge/changePiPass.sh " + piUser + ":" + piPass).run();
    return(CallBackUI.informResponse("SSH Password Changed for " + piUser));
  }
  
  doConfig() {
    //log.log("in doconfig");
    
  }
   
   checkUpgrade() {
    log.log("in checkupgrade");
    String autoUp = app.configManager.get("app.BR");
    if (TS.isEmpty(autoUp)) {
      app.configManager.put("app.BR", "enabled"); //assure accurate apps page, default is enable
      autoUp = "enabled";
    }
    unless (autoUp == "enabled") {
      log.log("autoUpgrade disabled");
      return(null);
    }
    Web:Client client = Web:Client.new();
    client.url = "https://bitbucket.org/abelii/edgii/downloads/latestVersion.json";
    String res = client.openInput().readString();
    log.log("in checkupgrade response is " + res);
    client.close();
    if (TS.notEmpty(res)) {
      Map resMap = Json:Unmarshaller.unmarshall(res);
      String ver = resMap.get("latestVersion");
      Int build = resMap.get("latestBuild");
      log.log("latestVersion is " + ver + " latestBuild " + build);
      if (app.plugin.build >= build) {
        log.log("already on latest (or newer) build, currently on build " + app.plugin.build);
      } else {
        log.log("need to upgrade");
        String latestUrl = resMap.get("latestUrl");
        log.log("latest url is " + latestUrl);
        Path dld = app.paths.dataPath.addStep("Downloads");
        if (dld.file.exists!) {
          dld.file.makeDirs();
        }
        dld = dld.addStep("KBridge.zip");
        if (dld.file.exists) {
          dld.file.delete();
        }
        client = Web:Client.new();
        client.url = latestUrl;
        auto prd = client.openInput();
        IO:Writer pwr = dld.file.writer.open();
        prd.copyData(pwr);
        pwr.close();
        client.close();
        Bool doUpgrade = true;
        ifEmit(appDebug) {
          doUpgrade = false;
        }
        if (doUpgrade) {
          log.log("doing upgrade to " + build);
          app.plugin.upgrade(dld.toString());
        } else {
          log.log("not upgrading, is debug");
        }
      }
    }
   }
   
   handleCmd(Parameters params) Bool {
      String mode = params.getFirst("bridgeCmd");
      if (TS.isEmpty(mode)) {
        return(super.handleCmd(params));
      }
      if (mode == "leab") {
        log.log("!!!!in leab!!!!");
        String domain = params.getFirst("domain");
        String action = params.getFirst("action");
        log.log("leab domain " + domain + " action " + action);
        getCertLeab(domain, action);
      }
      if (mode == "doLego") {
        doLego("run");
      }
      if (mode == "startLe") {
        startLes();
      }
      if (mode == "stopLe") {
        stopLes();
      }
      if (mode == "routerLink") {
        routerLink(params.getFirst("konUrl"), params.getFirst("auser"), params.getFirst("konUser"), params.getFirst("konPass"));
      }
      if (mode == "routerUpdate") {
        routerUpdate();
      }
      if (mode == "sftpFile") {
        log.log("sftpFile");
        String sfps = params.getFirst("sourceFile");
        String sshHost = getSshHost();
        if (TS.isEmpty(sshHost)) {
          sshHost = app.configManager.get("sftp.sshHost");
        }
        String sshLogin = app.configManager.get("sftp.sshLogin");
        String sshPass = app.configManager.get("sftp.sshPass");
        String sshPort = app.configManager.get("sftp.sshPort");
        if (TS.isEmpty(sshPort)) {
          sshPort = "22";
        }
        String dfps = "WebCam/sftpFiles-" + app.plugin.deviceId;
        if (TS.isEmpty(sfps) || TS.isEmpty(sshHost) || TS.isEmpty(sshLogin) || TS.isEmpty(sshPass)) {
          log.log("sourceFile, ssh host, login, or pass empty, not copying file");
          return(true);
        }
        Path sfp = Path.apNew(sfps).makeNonAbsolute();
        Path dfp = Path.apNew(dfps + "/" + sfps);
        log.log("copying " + sfp + " to " + dfp);
        Ssh ssh = Ssh.new(sshHost, sshPort, sshLogin, sshPass);
        ssh.open();
        ssh.sftpPut(sfp, dfp);
        ssh.close();
      }
      return(true);
    }
    
    preprs() {
      prepReverseProxy();
      if (TS.notEmpty(app.configManager.get("app.Cam")) && app.configManager.get("app.Cam") == "enabled") {
        prepCamReverseProxy();
      }
      if (TS.notEmpty(app.configManager.get("app.Domo")) && app.configManager.get("app.Domo") == "enabled") {
        prepDomoReverseProxy();
      }
      if (TS.notEmpty(app.configManager.get("app.Nxc")) && app.configManager.get("app.Nxc") == "enabled") {
        prepNxcReverseProxy();
      }
    }
    
   start() {
      assurePorts();
      super.start();
      app.pluginsByName.get("Auth").nonAuthedRequests.put("initialSetupRequest");
      
      bfw.startDelay = Time:Interval.new(60, 0);
      bfw.repeatDelay = Time:Interval.new(300, 0);//was 60
      bfw.minimumDelay = Time:Interval.new(120, 0);//was 30
      bfw.toInvoke = getInvocation("doForward", List.new());
      
      bup.startDelay = Time:Interval.new(120, 0);
      bup.repeatDelay = Time:Interval.new(86400, 0);
      bup.minimumDelay = Time:Interval.new(43200, 0);
      bup.toInvoke = getInvocation("checkUpgrade", List.new());
      
      bcf.startDelay = Time:Interval.new(20, 0);
      bcf.repeatDelay = Time:Interval.new(20, 0);//was 60
      bcf.minimumDelay = Time:Interval.new(10, 0);//was 30
      bcf.toInvoke = getInvocation("doConfig", List.new());
      
      if (runBackground) {
        bfw.start();
        bup.start();
        bcf.start();
      }
      reforward();
   }
   
   getInternetListenRequest(request) Map {
     //String sshPass = app.configManager.get("il.sshHost", "");
     return(CallBackUI.setElementsValuesResponse(Maps.from("sshHost", app.configManager.get("il.sshHost", ""), "sshLogin", app.configManager.get("il.sshLogin", ""))));
   }
   
   getDuckRequest(request) Map {
   
     String duckDomain = app.configManager.get("duck.domain");
     String duckiDomain = app.configManager.get("duck.idomain");
     String duckEmail = app.configManager.get("duck.email");
     if (undef(duckDomain)) { duckDomain = ""; }
     if (undef(duckiDomain)) { duckiDomain = ""; }
     if (undef(duckEmail)) { duckEmail = ""; }
     
     return(CallBackUI.setElementsValuesResponse(Maps.from("duckDomain", duckDomain, "duckiDomain", duckiDomain, "duckEmail", duckEmail, "duckToken", "")));
   }
   
   getCfRequest(request) Map {
   
     String cfHost = app.configManager.get("cf.host");
     if (undef(cfHost)) { cfHost = ""; }
     
     String cfiHost = app.configManager.get("cf.ihost");
     if (undef(cfiHost)) { cfiHost = ""; }
     
     String cfZone = app.configManager.get("cf.zone");
     if (undef(cfZone)) { cfZone = ""; }
     
     return(CallBackUI.setElementsValuesResponse(Maps.from("cfHost", cfHost, "cfiHost", cfiHost, "cfZone", cfZone)));
   }
   
   
   getUpnpRequest(request) Map {
     return(CallBackUI.getUpnpResponse(self.upnpEnabled, self.internalResolve));
   }
   
   getOnPublicNetRequest(request) Map {
     return(CallBackUI.getOnPublicNetResponse(self.onPublicNet));
   }
   
   addSiteName(String proto, String host) {
      String siteNames = app.configManager.get("auth.siteNames");
      if (TS.notEmpty(host)) {
        if (undef(siteNames)) { siteNames = ""; }
        if (siteNames.has(proto + host)!) {
          if (TS.notEmpty(siteNames)) {
            siteNames += ",";
          }
          siteNames += proto += host;
          app.configManager.put("auth.siteNames", siteNames);
        }
      }
   }
   
   saveOnPublicNetRequest(Bool enableUpnp, request) {
      if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        log.log("in saveOnPublicNetRequest");
        if (enableUpnp) {
          app.configManager.put("onPublicNet", "true");
        } else {
          app.configManager.put("onPublicNet", "false");
        }
        doForwardAsync();
      }
   }
   
   saveUpnpRequest(Bool enableUpnp, Bool internalResolve, request) {
      if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        log.log("in saveupnpr");
        if (enableUpnp) {
          app.configManager.put("doUpnpForward", "true");
        } else {
          app.configManager.put("doUpnpForward", "false");
        }
        if (internalResolve) {
          app.configManager.put("internalResolve", "true");
        } else {
          app.configManager.put("internalResolve", "false");
        }
        doForwardAsync();
        return(CallBackUI.informResponse("Upnp configuration successful"));
      }
      return(self);
   }
   
   saveInternetListenRequest(String hostedBridge, String host, String port, String login, String pass, request) Map {
    if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      log.log("in sil");
      if (TS.isEmpty(host) && TS.notEmpty(hostedBridge)) {
        log.log("using hostedBridge");
        app.configManager.put("il.sshHost", "");
        if (hostedBridge == "(None)") { hostedBridge = ""; log.log("empty hb"); }
        app.configManager.put("il.sshBridgedHost", hostedBridge);
      } else {
        log.log("using sshHost");
        app.configManager.put("il.sshHost", host);
        app.configManager.put("il.sshBridgedHost", "");
      }
      app.configManager.put("il.sshLogin", login);
      app.configManager.put("il.sshPass", pass);
      app.configManager.put("il.sshPort", port); 
      reforwardAsync();  
      return(CallBackUI.informResponse("SSH Internet Listen setup successful"));
      }
    return(null);
   }
   
   unforward() {
      //kill haproxies
      System:Command.new("./App/KBridge/stophaps.sh").run();
      //kill socats
      System:Command.new("./App/KBridge/stopsocats.sh").run();
      closeSsh();
   }
   
   reforward() {
     //log.output("reforwarding");
     try {
       reforwardLock.lock();
       unforward();
       preprs();
       System:Command.new("./App/KBridge/restarthaps.sh").run();
       doForward();
       reforwardLock.unlock();
     } catch (any e) {
       reforwardLock.unlock();
       log.error("error in reforward");
       if (def(e)) {
        log.error("forward error " + e);
       }
     }
   }
   
   reforwardAsync() {
     System:Thread.new(getInvocation("reforward", List.new())).start();
   }
   
   doForwardAsync() {
     System:Thread.new(getInvocation("doForward", List.new())).start();
   }
   
   getForwardPortsList() String {
     String fpl = String.new();
     String rps = String.new();
     WebConnect wc = wcol.o;
       if (def(wc)) {
         if (wc.manualForward) {
          rps += "<p>Configured for Manual forwarding.  Please do the following on your router:</p><p>Set mac address " += wc.internalMacAddresses.get(0) += " to static dhcp ip address " += wc.internalAddress += "</p>";
          rps += "<p>Forward external port " += wc.externalPort += " to internal ip:port " += wc.internalAddress += ":" += wc.internalPort += "</p>";
         }
         for (any kv in wc.getServices()) {
          fpl += "<p><a href=\"#\" onclick=\"callApp('loadForwardPortRequest','" += kv.key += "');return false;\">Load config for " += kv.value.get("name") += "</a></p>";
          if (wc.manualForward) {
            rps += "<p>Forward external port " += kv.value.get("intPort") += " to internal ip:port " += wc.internalAddress += ":" += kv.key += "</p>";
          }
         }
     }
     return(fpl + rps);
   }
   
   loadForwardPortRequest(String port, request) Map {
     String fpl = String.new();
     WebConnect wc = wcol.o;
     Map fp = wc.getServices().get(port);
     if(def(fp)) {
       for (any kv in fp) {
        if (undef(kv.value)) { kv.value = ""; }
        log.log("fp " + kv.key + " " + kv.value);
       }
       log.log("urlPat " + fp.get("urlPat"));
      return(CallBackUI.setElementsValuesResponse(Maps.from("fpName", fp.get("name"), "fpPort", port, "fpiPort", fp.get("iport"), "fpExPort", wc.extraPortMap.get(port), "fpPattern", fp.get("urlPat"))));
     }
     return(null);
   }
   
   deleteForwardRequest(String port, request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
       WebConnect wc = app.plugin.wcol.o;
       //now fpname and urlpat tied to port
       wc.deleteService(port);
       app.configManager.put("hub.webConnect", Json:Marshaller.marshall(wc.toMap()));
       app.plugin.wcol.o = wc;
       oapp.plugin.wcol.o = wc;
       //reforward();
       reforwardAsync();
       return(getRemoteAccessRequest(request));
       }
       return(null);
   }
   
   reforwardRequest(request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
       log.log("let's reforward");
       reforwardAsync();
     }
     return(null);
   }
   
   assurePorts() {
      log.log("assurePorts");
      intPort = app.configManager.get("app.port");
      if (TS.isEmpty(intPort)) {
        intPorti = System:Random.getIntMax(30000);
        intPorti += 3000;
        String intPort = intPorti.toString();
        app.configManager.put("app.port", intPort);
      }
      intPort = app.configManager.get("web.port");
      if (TS.isEmpty(intPort)) {
        intPorti = System:Random.getIntMax(30000);
        intPorti += 3000;
        intPort = intPorti.toString();
        app.configManager.put("web.port", intPort);
      }
     if (TS.isEmpty(app.configManager.get("webApp.Cam.web.port"))) {
      Int intPorti = System:Random.getIntMax(30000);
      intPorti += 3000;
      app.configManager.put("webApp.Cam.web.port", intPorti.toString());
     }
     if (TS.isEmpty(app.configManager.get("webApp.Cam.int.web.port"))) {
      intPorti = System:Random.getIntMax(30000);
      intPorti += 3000;
      app.configManager.put("webApp.Cam.int.web.port", intPorti.toString());
     }
     if (TS.isEmpty(app.configManager.get("webApp.Cam.app.port"))) {
      intPorti = System:Random.getIntMax(30000);
      intPorti += 3000;
      app.configManager.put("webApp.Cam.app.port", intPorti.toString());
     }
     if (TS.isEmpty(app.configManager.get("webApp.Domo.web.port"))) {
      intPorti = System:Random.getIntMax(30000);
      intPorti += 3000;
      app.configManager.put("webApp.Domo.web.port", intPorti.toString());
     }
     if (TS.isEmpty(app.configManager.get("webApp.Domo.int.web.port"))) {
      intPorti = System:Random.getIntMax(30000);
      intPorti += 3000;
      app.configManager.put("webApp.Domo.int.web.port", intPorti.toString());
     }
     if (TS.isEmpty(app.configManager.get("webApp.Nxc.web.port"))) {
      intPorti = System:Random.getIntMax(30000);
      intPorti += 3000;
      app.configManager.put("webApp.Nxc.web.port", intPorti.toString());
     }
     if (TS.isEmpty(app.configManager.get("webApp.Nxc.int.web.port"))) {
      intPorti = System:Random.getIntMax(30000);
      intPorti += 3000;
      app.configManager.put("webApp.Nxc.int.web.port", intPorti.toString());
     }
   }
   
   updateForwardRequest(String fpName, String port, String iport, String exPort, String urlPat, request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
       WebConnect wc = app.plugin.wcol.o;
       //now fpname and urlpat tied to port
       wc.putService(fpName, port, iport, exPort, urlPat);
       app.configManager.put("hub.webConnect", Json:Marshaller.marshall(wc.toMap()));
       app.plugin.wcol.o = wc;
       oapp.plugin.wcol.o = wc;
       reforwardAsync();
       //return(CallBackUI.informResponse("Service Saved"));
       return(getRemoteAccessRequest(request));
       }
       return(null);
   }


   updateActionLinks(String actionLinks, Account a, Map arg, request) String {
      super.updateActionLinks(actionLinks, a, arg, request);
      return(actionLinks);
   }
   
   loggedIn(Account a, Map res, Map arg, request) Map {
    res = super.loggedIn(a, res, arg, request);
    res["devLinksList"] = "";
    String dnso = app.configManager.get("deviceNameSetOnce");
    if (TS.isEmpty(dnso) || dnso != "true") {
      //res["deviceNameSetOnce"] = "false";
    }
    String anso = app.configManager.get("accountSetOnce");
    if (TS.isEmpty(anso) || anso != "true") {
      //res["accountSetOnce"] = "false";
    }
    String dc = app.configManager.get("doCam");
    if (TS.isEmpty(dc) || dc != "true") {
      res["doCam"] = "true";
    } else {
      res["doCam"] = "true";
    }
    return(res);
   }
   
   profileGet() String {
    return(profile);
  }
  
  initialSetupRequest(String setupToken, String user, String pass, String devName, String konnLogin, String konnPass, Bool setupLE, Bool setupCam, request) {
    //(
    log.log("In isr, say hello :-)");
    if (TS.isEmpty(user) || TS.isEmpty(pass) || TS.isEmpty(devName) || TS.isEmpty(konnLogin) || TS.isEmpty(konnPass)) {
      throw(Alert.new("Account Name, Account Password, Device Name, and Abelii.net user and password are all required"));
    }
    
    log.log("" + setupToken);
    
    String stok = app.configManager.get("setupToken");
    //log.log("stok " + stok + " setuptoken " + setupToken);
     if (TS.notEmpty(stok) && TS.notEmpty(setupToken) && stok == setupToken) {
      log.log("stok passed");
      
      self.deviceName = devName;
      
      app.configManager.put("doUpnpForward", "true");
      
      Account a = Account.new();
      a.user = user;
      a.pass = pass;
      a.perms.put("admin");
      app.pluginsByName.get("Auth").accountManager.putAccount(a);
      app.pluginsByName.get("Auth").setupSession(Maps.from("accountName", user), request);
      request.context.put("account", a);
      app.configManager.delete("setupToken");
      unlinkAllRequest(request);
      String rtrurl = app.configManager.get("router.Url");
      if (TS.isEmpty(rtrurl)) {
        rtrurl = "https://www.abelii.net";
      }
      routerLink(rtrurl, user, konnLogin, konnPass); //includes doForward
      //async launch installs
      launchInstalls(setupLE, setupCam, request);
      
      
      return(CallBackUI.initialSetupResponse());
     }
     
     return(null);
    
  }
  
  launchInstalls(Bool setupLE, Bool setupCam, request) {
    //put bools in fields
    //async start
    log.output("enableing le");
    enableAppRequest("LE", request);
    log.output("le enable done");
  }
  
  doUpdate() {
    try {
      updateLock.lock();
      doUpdateInner();
      updateLock.unlock();
    } catch(any e) {
      updateLock.unlock();
      log.error("failure during doupdate");
      if (def(e)) { log.log("error " + e); }
    }
  }
  
  doUpdateInner() {
    any e;
    log.log("In upnp doUpdate");
    log.log("getting wc");
    loadWc();
    WebConnect wc = app.plugin.wcol.o;
    if (def(wc)) {
      log.log("wc from wcol");
    } else {
      log.log("new wc");
      wc = WebConnect.new();
      app.plugin.wcol.o = wc;
      oapp.plugin.wcol.o = wc;
    }
    log.log("after wc init");
    wc.webProto = app.webProto;
    if (TS.isEmpty(webPort)) {
      webPort = app.webPort;
    }
    wc.internalPort = webPort;
    if (TS.isEmpty(certificateThumbprint)) {
      certificateThumbprint = app.certificateThumbprint; 
    }
    if (TS.notEmpty(certificateThumbprint)) {
      wc.certificatePrint = certificateThumbprint;
      log.log("CERT PRINT IS " + certificateThumbprint);
    } else {
      log.log("CERT PRINT EMPTY");
    }
    wc.deviceId = app.plugin.deviceId;
    wc.deviceName = app.plugin.deviceName; 
    wc.externalPort = webPort;
    String webiPort = app.configManager.get(app.configPrefix + "int." + "web.port");
    if (TS.notEmpty(webiPort)) {
     wc.internaliPort = webiPort;
    }
    log.log("starting wc update");
    //fwd was here
    
    app.plugin.wcol.o = wc;
    oapp.plugin.wcol.o = wc;
    log.log("saving");
    app.configManager.put("hub.webConnect", Json:Marshaller.marshall(wc.toMap()));
    
    any fpe;
    log.log("updating addresses");
      updateDuck();
      updateCf();
      try {
        updateMyLinks();
      } catch (fpe) {
        log.error("exception during updateMyLinks ");
        if (def(fpe)) {
          log.error("fpe " + fpe);
        }
      }
      
      wc = app.plugin.wcol.o;
    log.log("setting links");
    wc.updateInternal(homePage);
    
      Bool doUpnpForward = self.upnpEnabled;
      Bool doesInternalResolve = self.internalResolve;
      Bool onPublicNet = self.onPublicNet;
      String extBase = "";
      wc.updateExternal(homePage, extBase, doUpnpForward, doesInternalResolve, onPublicNet);
      String dnsen = app.configManager.get("app.Dns");
      if (TS.notEmpty(dnsen) && dnsen == "enabled") {
        log.log("!!!SETTING DOING DNS TRUE");
        wc.doingDns = true;
      } else {
      log.log("!!!SETTING DOING DNS FALSE");
        wc.doingDns = false;
      }
      
      
      
      
    List au = List.new();
      if (TS.notEmpty(wc.internalUrl)) {
        app.pluginsByName.get("Auth").authedUrls.put(wc.internalUrl);
        auto parts = wc.internalUrl.split(":");
        String fs = parts[0] + ":" + parts[1];
        log.log("fs " + fs);
        au += fs; 
      }
      if (TS.notEmpty(wc.externalUrl)) {
        app.pluginsByName.get("Auth").authedUrls.put(wc.externalUrl);
        parts = wc.externalUrl.split(":");
        fs = parts[0] + ":" + parts[1];
        log.log("fs " + fs);
        au += fs;
      }
      if (TS.notEmpty(wc.hostedUrl)) {
        app.pluginsByName.get("Auth").authedUrls.put(wc.hostedUrl);
        parts = wc.hostedUrl.split(":");
        fs = parts[0] + ":" + parts[1];
        log.log("fs " + fs);
        au += fs;
      }
      if (TS.notEmpty(wc.konnUrl)) {
        app.pluginsByName.get("Auth").authedUrls.put(wc.konnUrl);
        parts = wc.konnUrl.split(":");
        fs = parts[0] + ":" + parts[1];
        log.log("fs " + fs);
        au += fs;
      }
      if (TS.notEmpty(wc.konniUrl)) {
        app.pluginsByName.get("Auth").authedUrls.put(wc.konniUrl);
        parts = wc.konniUrl.split(":");
        fs = parts[0] + ":" + parts[1];
        log.log("fs " + fs);
        au += fs;
      }
      any dpf = app.paths.dataPath.addStep("authedUrls");
      if (dpf.file.exists) { dpf.file.delete(); }
      dpf.file.writer.open().writeStringClose(Json:Marshaller.marshall(au));
      
    log.log("upnp doUpdate done");
  }
  
    
    doForward() {
      doUpdate();
      for (Int i = 0;i < 5;i++=) {
        log.log("doForward start");
        Bool res = false;
        try {
          forwardLock.lock();
          res = doForwardInner();
          forwardLock.unlock();
        } catch(any e) {
          forwardLock.unlock();
          log.error("error during doforward ");
          if (def(e)) { log.error("error " + e); }
        }
        if (res) {
          log.log("doForward done");
          i = 5;
        } else {
          Time:Sleep.sleepSeconds(5);
        }
      }
      unless (res) {
          log.log("keep failing doforward exiting / restarting");
          System:Process.exit(3);
      }
    }
    
    gsbSaveRequest(String gsbKey, String gsbSecret, gsbBucket, String gsbPass, String gsbRetain, request) {
    
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      if (TS.isEmpty(gsbKey) || TS.isEmpty(gsbSecret) || TS.isEmpty(gsbBucket) || TS.isEmpty(gsbPass) || TS.isEmpty(gsbRetain)) {
        cm = app.configManager;
        cm.delete("gsb.key");
        cm.delete("gsb.secret");
        cm.delete("gsb.bucket");
        cm.delete("gsb.pass");
        cm.delete("gsb.retain");
        cm.delete("gsb.full");
        throw(Alert.new("Key Secret, Bucket, Pass, and Retention required - backup is now disabled"));
      }
      Int gr = Int.new(gsbRetain);
      if (gr < 5) {
        throw(Alert.new("Must keep backups at least 5 days"));
      }
      Int full = gr / 2;
      auto cm = app.configManager;
      cm.put("gsb.key", gsbKey);
      cm.put("gsb.secret", gsbSecret);
      cm.put("gsb.bucket", gsbBucket);
      cm.put("gsb.pass", gsbPass);
      cm.put("gsb.retain", gsbRetain.toString());
      cm.put("gsb.full", full.toString());
      return(CallBackUI.informResponse("Backup Config Saved"));  
    }
    
    closeSsh() {
      if (def(ssh)) {
        try {
           ssh.close();
           ssh = null;
         } catch (any sshe) {
           ssh = null;
         }
      }
    }
        
    onPublicNetGet() Bool {
      String doUpnpForwardS = app.configManager.get("onPublicNet");
      if (TS.isEmpty(doUpnpForwardS)) {
        doUpnpForwardS = "false";
      }
      Bool doUpnpForward = Bool.new(doUpnpForwardS);
      return(doUpnpForward);
    }
    
    upnpEnabledGet() Bool {
      String doUpnpForwardS = app.configManager.get("doUpnpForward");
      if (TS.isEmpty(doUpnpForwardS)) {
        doUpnpForwardS = defaultUpnpF;
      }
      Bool doUpnpForward = Bool.new(doUpnpForwardS);
      return(doUpnpForward);
    }
    
    internalResolveGet() Bool {
      String doUpnpForwardS = app.configManager.get("internalResolve");
      if (TS.isEmpty(doUpnpForwardS)) {
        doUpnpForwardS = defaultInternalResolveF;
      }
      Bool doUpnpForward = Bool.new(doUpnpForwardS);
      return(doUpnpForward);
    }
    
    getSshHost() String {
      String si = app.configManager.get("il.sshHost");
      String br = app.configManager.get("il.sshBridgedHost");
      if (TS.isEmpty(br)) {
        //log.log("getSshHost is si " + si);
        return(si);
      }
      //log.log("getSshHost from hosted bridge " + br);
      Map links = getLinks(null);
       for (auto kv in links) {
        WebConnect wc = kv.value;
        if (TS.notEmpty(wc.deviceName) && wc.deviceName == br) {
          //log.log("get sshhost found hb, addr " + wc.hostedAddress);
          return(wc.hostedAddress);
        }
       }
       return(null);
    }
    
     doForwardInner() Bool {
      Bool success = true;
      Bool doUpnpForward = self.upnpEnabled;
      Bool doesInternalResolve = self.internalResolve;
      Bool onPublicNet = self.onPublicNet;
      log.log("wc forwarding ports");
      log.log("getting wc");
      loadWc();
      WebConnect wc = app.plugin.wcol.o;
      if (def(wc)) {
        log.log("wc from wcol");
      } else {
        log.log("new wc");
        wc = WebConnect.new();
        app.plugin.wcol.o = wc;
        oapp.plugin.wcol.o = wc;
      }
      String sshHost = getSshHost();
      String sshPort = app.configManager.get("il.sshPort");
      if (TS.isEmpty(sshPort)) {
        sshPort = "22";
      }
      String sshLogin = app.configManager.get("il.sshLogin");
      String sshPass = app.configManager.get("il.sshPass");
      try {
        if (TS.notEmpty(sshHost) && TS.notEmpty(sshLogin) && TS.notEmpty(sshPass)) {
          wc.hostedAddress = sshHost;
          if (undef(ssh) || ssh.isClosed) {
            log.log("ssh connecting " + sshHost + " " + sshLogin);
            if (sshLogin == "root") {
              log.log("is root, going to make sure gateway is enabled");
              Ssh gwssh = Ssh.new(sshHost, sshPort, sshLogin, sshPass);
              gwssh.open();
              String gwcmd = "if grep -q -x \"^GatewayPorts yes\" /etc/ssh/sshd_config; then echo -n \"\"; else cat /etc/ssh/sshd_config | grep -v GatewayPorts > sshd_config; echo \"GatewayPorts yes\" >> sshd_config; cp ./sshd_config /etc/ssh/sshd_config; service ssh restart; service sshd restart; sleep 5; fi";
              gwssh.execCommand(gwcmd);
              gwssh.close();
            }
            ssh = Ssh.new(sshHost, sshPort, sshLogin, sshPass);
            ssh.open();
            rforwarded = Set.new();
          } else {
            ssh.sendKeepAlive();
          }
        } else {
          wc.hostedAddress = "";
        }
      } catch (any sshe) {
        success = false;
        log.error("Error during ssh op " + sshe);
      }
      try {
        forwardPorts(wc, ssh, rforwarded);
      } catch (any fpe) {
        success = false;
        log.error("exception during forwardports " + fpe);
      }
      
      log.log("saving");
      app.configManager.put("hub.webConnect", Json:Marshaller.marshall(wc.toMap()));
      log.log("upnp doForward done");
      
      return(success);
  }
  
  
  forwardPorts(WebConnect wc, Net:Ssh ssh, Set rforwarded) {
      Bool doUpnpForward = self.upnpEnabled;
      log.log("Forwarding");
      Int fwdSecs = 7200;//fwd upnp for how long
      Upnp upnp = Upnp.new();
      upnp.netGw = IP.gatewayIP;
      if (doUpnpForward) {
        upnp.forwardPort(fwdSecs, Int.new(wc.externalPort), Int.new(wc.internalPort));
      }
      if (TS.notEmpty(wc.extraPorts)) {
        for (String ep in wc.extraPorts.split(",")) {
          String currPortS = wc.extraPortMap.get(ep);
          if (TS.isEmpty(currPortS)) {
            currPortS = wc.getAPort();
            wc.extraPortMap.put(ep, currPortS);
          }
          log.log("Forwarding extraport external " + currPortS + " to " + ep);
          if (doUpnpForward) {
            upnp.forwardPort(fwdSecs, Int.new(currPortS), Int.new(ep));
          }
        }
      }
      if (def(ssh) && def(wc.hostedAddress)) {
        if (rforwarded.has(wc.externalPort)!) {
          ssh.forwardPortR(Int.new(wc.externalPort), "127.0.0.1", Int.new(wc.internalPort));
        }
        rforwarded += wc.externalPort;
        if (TS.notEmpty(wc.extraPorts)) {
          for (ep in wc.extraPorts.split(",")) {
            currPortS = wc.extraPortMap.get(ep);
            if (TS.isEmpty(currPortS)) {
              currPortS = wc.getAPort();
              wc.extraPortMap.put(ep, currPortS);
            }
            log.log("SSH check Forwarding extraport external " + currPortS + " to " + ep);
            if (rforwarded.has(currPortS)!) {
              log.log("SSH Forwarding extraport external " + currPortS + " to " + ep);
              ssh.forwardPortR(Int.new(currPortS), "127.0.0.1", Int.new(ep));
              rforwarded += currPortS;
            }
          }
        }
      }
    }
    
    getAppsStatesRequest(request) Map {
      Map appStates = app.configManager.getMap("app.");
      Map displays = Map.new();
      for (any kv in appStates) {
        if (TS.notEmpty(kv.value) && TS.notEmpty(kv.key) && kv.key.size > 4) {
          if (kv.value == "enabled" || kv.value == "disabled") {
            String appName = kv.key.substring(4, kv.key.size);
            if (kv.value == "enabled") {
              log.log("setting " + appName + " enabled");
              displays.put(appName + "AppEnabled", "inline");
              displays.put(appName + "AppDisabled", "none");
            } else {
              log.log("setting " + appName + " disabled");
              displays.put(appName + "AppEnabled", "none");
              displays.put(appName + "AppDisabled", "inline");
            }
          }
        }
      }
      return(CallBackUI.setElementsDisplaysResponse(displays));
    }
    
    outRgw() {
      WebConnect wc = app.plugin.wcol.o;
      File rgw = Path.apNew("rgw").file;
      if (rgw.exists) { rgw.delete(); }
      rgw.writer.open().writeStringClose("recursor=" + wc.gateway + "\n");
    }
    
    enableAppRequest(String appName, request) Map {
      log.log("in enableApp");
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      log.log("enabling app");
      app.configManager.put("app." + appName, "enabled");
      String cmdPath = "./App/KBridge/" + appName + "Enable.sh";
      String enres = System:Command.new(cmdPath).open().output.readStringClose();
      log.log("enable done, output " + enres);
      updateNames();
      reforwardAsync();
      return(CallBackUI.setElementsDisplaysResponse(Maps.from(appName + "AppDisabled", "none", appName + "AppEnabled", "inline")));
      //return(CallBackUI.informResponse("App " + appName + " Enabled"));
    }
    
    disableAppRequest(String appName, request) Map {
      log.log("in disableApp");
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      log.log("disabling app");
      app.configManager.put("app." + appName, "disabled");
      String cmdPath = "./App/KBridge/" + appName + "Disable.sh";
      System:Command.new(cmdPath).run();    
      log.log("disable done");
      return(CallBackUI.setElementsDisplaysResponse(Maps.from(appName + "AppDisabled", "inline", appName + "AppEnabled", "none")));
      //return(CallBackUI.informResponse("App " + appName + " Disabled"));
    }
     
   
}

emit(jv) {
"""
import com.jcraft.jsch.*;
"""
}
local use Net:Ssh {

  emit(jv) {
  """
  JSch bevi_jsch;
  Session bevi_session;
  """
  }
  
  new() self {
    fields {
    }
  }
  
  new(String _host, String _port, String _user, String _pass) this {
    fields {
      String host = _host;
      String port = _port;
      String user = _user;
      String pass = _pass; 
    }
  }
  
  forwardPortR(Int rport, String host, Int lport) this {
    emit(jv) {
    """
    bevi_session.setPortForwardingR(beva_rport.bevi_int, beva_host.bems_toJvString(), beva_lport.bevi_int);
    """
    }
  }
  
  isClosedGet() Bool {
    Bool fval =@ false;
    emit(jv) {
    """
    if (bevi_session != null && bevi_session.isConnected()) {
      return bevl_fval;
    }
    """
    }
    return(true);
  }
  
  open() this {
    Int porti = Int.new(port);
    emit(jv) {
    """
    bevi_jsch = new JSch();
    bevi_session = bevi_jsch.getSession(bevp_user.bems_toJvString(), bevp_host.bems_toJvString(), bevl_porti.bevi_int);
    bevi_session.setPassword(bevp_pass.bems_toJvString());
    bevi_session.setConfig("StrictHostKeyChecking", "no");
    bevi_session.connect();
    """
    }
  }
  
  close() this {
    emit(jv) {
    """
    bevi_session.disconnect();
    bevi_session = null;
    bevi_jsch = null;
    """
    }
  }
  
  sendKeepAlive() this {
    emit(jv) {
    """
    bevi_session.sendKeepAliveMsg();
    """
    }
  }
  
  sftpPut(Path src, Path dst) {
  Path dstPar = dst.parent;
  //("dstPar is " + dstPar).print();
  emit(jv) {
  """
  Channel channel = bevi_session.openChannel("sftp");
  channel.connect();
  ChannelSftp sftpChannel = (ChannelSftp) channel;
  """
  }
  //recursive check with stat and mkdir
  String parSoFar = String.new();
  for (String parst in dstPar.steps) {
    if (TS.notEmpty(parSoFar)) {
      parSoFar += "/";
    }
    parSoFar += parst;
    //("parSoFar " + parSoFar).print();
    emit(jv) {
    """
    SftpATTRS sa = null;
    try {
    sa = sftpChannel.stat(bevl_parSoFar.bem_toString_0().bems_toJvString());
    } catch (Exception e) { /*don't care, is no such file except*/ }
    if (sa == null || !sa.isDir()) {
      sftpChannel.mkdir(bevl_parSoFar.bem_toString_0().bems_toJvString());
    }
    """
    }
  }
  emit(jv) {
  """
  SftpATTRS sa = null;
  try {
  sa = sftpChannel.stat(beva_dst.bem_toString_0().bems_toJvString());
  sftpChannel.rm(beva_dst.bem_toString_0().bems_toJvString());
  } catch (Exception e) { /*don't care, is no such file except*/ }
  sftpChannel.put(beva_src.bem_toString_0().bems_toJvString(), beva_dst.bem_toString_0().bems_toJvString());
  sftpChannel.exit();
  """
  }
  }
  
  execCommand(String cmd) Int {
  Int result;
  Exception e;
  emit(jv) {
  """
   try {
     ChannelExec channelexe = (ChannelExec) bevi_session.openChannel("exec");
     channelexe.setCommand(beva_cmd.bems_toJvString());                
     channelexe.connect();
     bevl_result = new BEC_2_4_3_MathInt(channelexe.getExitStatus());
   } catch (Exception e) {
     System.err.println("exception during execCommand");
     e.printStackTrace();
     System.err.println(e.getMessage());
   }
  """
  }
  return(result);
  }

}

use Net:Ssh:Forward {

  new() self {
    fields {
      Int inPort;
      String host;
      Int outPort;
    }
  }
  
  new(Int _inPort, String _host, Int _outPort) {
    inPort = _inPort;
    host = _host;
    outPort = _outPort;
  }
  
}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;
