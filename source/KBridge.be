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
      //App:Background bup = App:Background.new();
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
      //bup.runMyTasks();
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
     Map links = getLinks(null);
     for (auto kv in links) {
      WebConnect wc = kv.value;
      if (TS.notEmpty(wc.deviceName) && TS.notEmpty(wc.hostedAddress) && def(wc.onPublicNet) && wc.onPublicNet) {
        hb.put(wc.deviceName, wc.deviceName);
      }
     }
     hb.put("(None)", "(None)")
     
     
     return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsValuesResponse(Maps.from("sshHost", app.configManager.get("il.sshHost", ""), "sshPort", app.configManager.get("il.sshPort", ""), "sshLogin", app.configManager.get("il.sshLogin", ""))), CallBackUI.hideNShowListResponse(Lists.from("remoteaccessdiv")), CallBackUI.setOptionsSelectedResponse("hostedBridges",hb, br))));
   }
   
   getRemoteAccessRequest(request) Map {
   
     //return(CallBackUI.hideNShowListResponse(Lists.from("forwardPortsDiv")));
     
     return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsInnerHTMLResponse(Maps.from("forwardPortsListDiv", getForwardPortsList())), CallBackUI.hideNShowListResponse(Lists.from("forwardPortsDiv")))));
   }
   
   setCamPortsRequest(request) Map {
      String camPort = app.configManager.get("webApp.Cam.web.port");
      if (TS.notEmpty(camPort)) {
        return(CallBackUI.setElementsValuesResponse(Maps.from("fpPort", camPort, "fpExPort", camPort)));
      }
      return(CallBackUI.informResponse("Please enable IU Cam from the Apps menu before setting up"));
   }
   
   routerLinkRequest(String account, String pass, request) Map {
    log.log("in router link request");
    unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    
    String rtrurl = app.configManager.get("router.Url");
    if (TS.isEmpty(rtrurl)) {
      rtrurl = "https://www.edgii.io";
    }
    
    Account a = request.context.get("account");
    return(routerLink(rtrurl, a.user, account, pass));
    }
   
   routerLink(String url, String auser, String account, String pass) Map {
    log.log("linking");
    
    log.log("get the devicename deviceid going");
    String dn = self.deviceName;
    String did = self.deviceId;
    
    log.log("first do update");
    doUpdate();
    
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
      Web:Client:CertificateManager.validateHosts = false;
      Web:Client:CertificateManager.validateCertificates = false;
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
        app.getKvDb("DEVLINKS").put("LinkSession." + auser + "!" + destUrl, dss);
        //updateMyLink(app.plugin.wcol.o, ds);
        //updateMyLinks();
        //if (true) { resetCertMan(wco.certificatePrint); return(checkConnInner(wco, ds, destUrl)) };
        doForward(); //includes an update
        
        WebConnect wc = app.plugin.wcol.o;
        app.configManager.put("hub.webConnect", Json:Marshaller.marshall(wc.toMap()));
        app.plugin.wcol.o = wc;
        oapp.plugin.wcol.o = wc;
        app.configManager.put("router.accountName", account);
        //doForward();
        
      }
      //resetCertMan(ds["certificatePrint"]);
    } catch(any e) {
      //resetCertMan(ds["certificatePrint"]);
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
    doUpdate();
    
    //updateMyLinks();
    doForward(); //includes an update
    //updateMyLinks();
        
   }
   
   unlinkAllRequest(request) {
     unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    
   }
   
   clearAllDevsRequest(request) {
     unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    Map lss = app.getKvDb("DEVLINKS").getMap("devlink!");
     for (auto kv in lss) {
       app.getKvDb("DEVLINKS").delete(kv.key);
     }
   }
   
   updateMyLinks() {
     
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
      Web:Client:CertificateManager.validateHosts = false;
      Web:Client:CertificateManager.validateCertificates = false;
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
      Web:Client:CertificateManager.validateHosts = true;
      Web:Client:CertificateManager.validateCertificates = true;
    } catch (any e) {
      //resetCertMan(ds["certificatePrint"]);
      Web:Client:CertificateManager.validateHosts = true;
      Web:Client:CertificateManager.validateCertificates = true;
      log.log("got exception during updatemylink");
      log.log(e.toString());
    }
    return(resMap);
  }
  
  startLes() Map {
    Json:Unmarshaller unmar = Json:Unmarshaller.new();
    Map lss = app.getKvDb("DEVLINKS").getMap("LinkSession.");
    for (auto kv in lss) {
       Map ds = unmar.unmarshall(kv.value);
       Map res = startLe(ds);
     }
     return(res);
     
  }
  
  stopLes() Map {
    Json:Unmarshaller unmar = Json:Unmarshaller.new();
    Map lss = app.getKvDb("DEVLINKS").getMap("LinkSession.");
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
   
   checkUpgrade() {
    log.log("in checkupgrade");
    String autoUp = app.configManager.get("hub.autoUpgrade");
    unless (TS.isEmpty(autoUp) || autoUp == "true") {
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
      log.log("latestVersion is " + ver);
      if (ver == app.plugin.version) {
        log.log("already on latest version");
      } else {
        log.log("need to upgrade");
        String latestUrl = resMap.get("latestUrl");
        log.log("latest url is " + latestUrl);
        Path dld = app.paths.dataPath.addStep("Downloads");
        if (dld.file.exists!) {
          dld.file.makeDirs();
        }
        dld = dld.addStep("IUBHub.zip");
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
          log.log("doing upgrade to " + ver);
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
    
   start() {
      assurePorts();
      prepReverseProxy();
      if (TS.notEmpty(app.configManager.get("app.Cam")) && app.configManager.get("app.Cam") == "enabled") {
        prepCamReverseProxy();
      }
      super.start();
      app.pluginsByName.get("Auth").nonAuthedRequests.put("initialSetupRequest");
      
      bfw.startDelay = Time:Interval.new(20, 0);
      bfw.repeatDelay = Time:Interval.new(300, 0);//was 60
      bfw.minimumDelay = Time:Interval.new(120, 0);//was 30
      bfw.toInvoke = getInvocation("doForward", List.new());
      
      //bup.startDelay = Time:Interval.new(30, 0);
      //bup.repeatDelay = Time:Interval.new(86400, 0);
      //bup.minimumDelay = Time:Interval.new(43200, 0);
      //bup.toInvoke = getInvocation("checkUpgrade", List.new());
      
      if (runBackground) {
        bfw.start();
        //bup.start();
      }
   }
   
   getInternetListenRequest(request) Map {
     //String sshPass = app.configManager.get("il.sshHost", "");
     return(CallBackUI.setElementsValuesResponse(Maps.from("sshHost", app.configManager.get("il.sshHost", ""), "sshLogin", app.configManager.get("il.sshLogin", ""))));
   }
   
   getDuckRequest(request) Map {
   
     String duckDomain = app.configManager.get("duck.domain");
     String duckEmail = app.configManager.get("duck.email");
     if (undef(duckDomain)) { duckDomain = ""; }
     if (undef(duckEmail)) { duckEmail = ""; }
     
     return(CallBackUI.setElementsValuesResponse(Maps.from("duckDomain", duckDomain, "duckEmail", duckEmail)));
   }
   
   getCfRequest(request) Map {
   
     String cfHost = app.configManager.get("cf.host");
     if (undef(cfHost)) { cfHost = ""; }
     
     String cfZone = app.configManager.get("cf.zone");
     if (undef(cfZone)) { cfZone = ""; }
     
     return(CallBackUI.setElementsValuesResponse(Maps.from("cfHost", cfHost, "cfZone", cfZone)));
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
        doForward();
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
        doForward();
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
      closeSsh();     
      doForward();
      return(CallBackUI.informResponse("SSH Internet Listen setup successful"));
      }
    return(null);
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
     for (any kv in fp) {
      log.log("fp " + kv.key + " " + kv.value);
     }
     log.log("urlPat " + fp.get("urlPat"));
    return(CallBackUI.setElementsValuesResponse(Maps.from("fpName", fp.get("name"), "fpPort", port, "fpExPort", wc.extraPortMap.get(port), "fpPattern", fp.get("urlPat"))));
   }
   
   deleteForwardRequest(String port, request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
       WebConnect wc = app.plugin.wcol.o;
       //now fpname and urlpat tied to port
       wc.deleteService(port);
       app.configManager.put("hub.webConnect", Json:Marshaller.marshall(wc.toMap()));
       app.plugin.wcol.o = wc;
       oapp.plugin.wcol.o = wc;
       closeSsh();
       doForward();
       return(getRemoteAccessRequest(request));
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
   }
   
   updateForwardRequest(String fpName, String port, String exPort, String urlPat, request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
       WebConnect wc = app.plugin.wcol.o;
       //now fpname and urlpat tied to port
       wc.putService(fpName, port, exPort, urlPat);
       app.configManager.put("hub.webConnect", Json:Marshaller.marshall(wc.toMap()));
       app.plugin.wcol.o = wc;
       oapp.plugin.wcol.o = wc;
       //TODO update imap wc
       doForward();
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
  
  initialSetupRequest(String setupToken, String user, String pass, String devName, String konUser, String konPass, request) {
    //(
    log.log("In isr, say hello :-)");
    if (TS.isEmpty(user) || TS.isEmpty(pass) || TS.isEmpty(devName) || TS.isEmpty(konUser) || TS.isEmpty(konPass)) {
      throw(Alert.new("Account Name, Account Password, Device Name, Edgii User, and Edgii Password are all required"));
    }
    
    log.log("" + setupToken + " " + user + " " + pass + " " + devName + " " + konUser + " " + konPass);
    
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
      app.configManager.delete("setupToken");
      String rtrurl = app.configManager.get("router.Url");
      if (TS.isEmpty(rtrurl)) {
        rtrurl = "https://www.edgii.io";
      }
      routerLink(rtrurl, user, konUser, konPass);
      //updateMyLinks();
      updateDuck();
      updateCf();
      return(CallBackUI.initialSetupResponse());
     }
     
     return(null);
    
  }
    
    doForward() {
      doUpdate();
      for (Int i = 0;i < 5;i++=) {
        Bool res = false;
        try {
          wcl.lock();
          res = doForwardInner();
          wcl.unlock();
        } catch(any e) {
          wcl.unlock();
          log.log("error during doforward " + e);
        }
        if (res) {
          i = 5;
        } else {
          closeSsh();
          Time:Sleep.sleepSeconds(5);
        }
      }
      unless (res) {
          log.log("keep failing doforward exiting / restarting");
          System:Process.exit(3);
      }
    }
    
    closeSsh() {
      if (def(ssh)) {
        try {
           wcl.lock();
           ssh.close();
           ssh = null;
           wcl.unlock();
         } catch (any sshe) {
           ssh = null;
           wcl.unlock();
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
        log.log("Error during ssh op " + sshe);
      }
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
      try {
        forwardPorts(wc, ssh, rforwarded);
      } catch (any fpe) {
        success = false;
        log.log("exception during forwardports " + fpe);
      }
      log.log("updating addresses");
      updateDuck();
      updateCf();
      /*try {
        updateMyLinks();
      } catch (fpe) {
        log.log("exception during updateMyLinks ");
        if (def(fpe)) {
          log.log("fpe " + fpe);
        }
      }*/
      log.log("saving");
      app.configManager.put("hub.webConnect", Json:Marshaller.marshall(wc.toMap()));
      log.log("upnp doForward done");
      
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
      any dpf = app.paths.dataPath.addStep("authedUrls");
      if (dpf.file.exists) { dpf.file.delete(); }
      dpf.file.writer.open().writeStringClose(Json:Marshaller.marshall(au));
      
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
      if (appName == "Cam") {
        prepCamReverseProxy();
      }
      if (appName == "Nxc") {
        prepReverseProxy("80", "6443", "Nxc.", "cert.pem");
      }
      if (appName == "Dns") {
        outRgw();
      }
      app.configManager.put("app." + appName, "enabled");
      String cmdPath = "./App/KBridge/" + appName + "Enable.sh";
      String enres = System:Command.new(cmdPath).open().output.readStringClose();
      log.log("enable done, output " + enres);
      if (appName == "Dns") {
        doForward();
      }
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
