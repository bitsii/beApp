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
      if (TS.notEmpty(wc.deviceName) && TS.notEmpty(wc.hostedAddress)) {
        hb.put(wc.deviceName, wc.deviceName);
      }
     }
     hb.put("(None)", "(None)")
     
     
     return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsValuesResponse(Maps.from("sshHost", app.configManager.get("il.sshHost", ""), "sshLogin", app.configManager.get("il.sshLogin", ""))), CallBackUI.hideNShowListResponse(Lists.from("remoteaccessdiv")), CallBackUI.setOptionsSelectedResponse("hostedBridges",hb, br))));
   }
   
   getRemoteAccessRequest(request) Map {
   
     //return(CallBackUI.hideNShowListResponse(Lists.from("forwardPortsDiv")));
     
     return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsInnerHTMLResponse(Maps.from("forwardPortsListDiv", getForwardPortsList())), CallBackUI.hideNShowListResponse(Lists.from("forwardPortsDiv")))));
   }
   
   routerLinkRequest(String account, String pass, request) Map {
    log.log("in router link request");
    unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    
    String rtrurl = app.configManager.get("router.Url");
    if (TS.isEmpty(rtrurl)) {
      rtrurl = "https://www.konnectii.com";
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
        app.configManager.put("LinkSession." + auser + "!" + destUrl, dss);
        updateMyLink(app.plugin.wcol.o, ds);
        //if (true) { resetCertMan(wco.certificatePrint); return(checkConnInner(wco, ds, destUrl)) };
        doForward(); //includes an update
      }
      //resetCertMan(ds["certificatePrint"]);
    } catch(any e) {
      //resetCertMan(ds["certificatePrint"]);
    }
    return(CallBackUI.informResponse("Device Link Successful"));
   }
   
   unlinkAllRequest(request) {
     unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    Map lss = app.configManager.getMap("LinkSession.");
     for (auto kv in lss) {
       app.configManager.delete(kv.key);
     }
     WebConnect wc = app.plugin.wcol.o;
     if (def(wc)) {
      log.log("clearing wc konnname");
      wc.konnName = null;
     }
     app.configManager.put("hub.webConnect", Json:Marshaller.marshall(wc.toMap()));
     clearAllDevsRequest(request);
   }
   
   clearAllDevsRequest(request) {
     unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    Map lss = app.configManager.getMap("devlink!");
     for (auto kv in lss) {
       app.configManager.delete(kv.key);
     }
   }
   
   updateMyLinks() {
     WebConnect wc = app.plugin.wcol.o;
     Json:Unmarshaller unmar = Json:Unmarshaller.new();
     Json:Marshaller mar = Json:Marshaller.new();
     Map lss = app.configManager.getMap("LinkSession.");
     for (auto kv in lss) {
       Map ds = unmar.unmarshall(kv.value);
       Map res = updateMyLink(wc, ds);
     }
     if (def(res) && res.has("links")) {
      KvDb knwc = app.getKvDb("KNAMEWCS");
      for (Map lm in res.get("links")) {
        log.log("putting into links");
        WebConnect awc = WebConnect.new().fromMap(lm);
        String conjs = mar.marshall(lm);
        app.configManager.put("devlink!" + awc.deviceId, conjs);
        log.log("awc did " + awc.deviceId + " wc did " + wc.deviceId);
        if (awc.deviceId == wc.deviceId) {
          //now with konnUrl et all
          app.configManager.put("hub.webConnect", conjs);
          app.plugin.wcol.o = awc;
          log.log("put awc in for webcon " + conjs);
        }
        if (TS.notEmpty(awc.konnName)) {
          knwc.put(awc.konnName, conjs);
        }
      }
     }
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
   
   checkUpgrade() {
    log.log("in checkupgrade");
    String autoUp = app.configManager.get("hub.autoUpgrade");
    unless (TS.isEmpty(autoUp) || autoUp == "true") {
      log.log("autoUpgrade disabled");
      return(null);
    }
    Web:Client client = Web:Client.new();
    client.url = "https://bitbucket.org/ioturl/ioturl/downloads/latestVersion.json";
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
        ifEmit(iuDebug) {
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
      if (mode == "routerLink") {
        routerLink(params.getFirst("konUrl"), params.getFirst("auser"), params.getFirst("konUser"), params.getFirst("konPass"));
      }
      if (mode == "sftpFile") {
        log.log("sftpFile");
        String sfps = params.getFirst("sourceFile");
        String sshHost = getSshHost();
        String sshLogin = app.configManager.get("il.sshLogin");
        String sshPass = app.configManager.get("il.sshPass");
        String dfps = "WebCam/sftpFiles-" + app.plugin.deviceId;
        if (TS.isEmpty(sfps) || TS.isEmpty(sshHost) || TS.isEmpty(sshLogin) || TS.isEmpty(sshPass)) {
          log.log("sourceFile, ssh host, login, or pass empty, not copying file");
          return(true);
        }
        Path sfp = Path.apNew(sfps).makeNonAbsolute();
        Path dfp = Path.apNew(dfps + "/" + sfps);
        log.log("copying " + sfp + " to " + dfp);
        Ssh ssh = Ssh.new(sshHost, sshLogin, sshPass);
        ssh.open();
        ssh.sftpPut(sfp, dfp);
        ssh.close();
      }
      return(true);
    }
   
   start() {
      super.start();
      app.pluginsByName.get("Auth").nonAuthedRequests.put("initialSetupRequest");
      
      bfw.startDelay = Time:Interval.new(20, 0);
      bfw.repeatDelay = Time:Interval.new(60, 0);
      bfw.minimumDelay = Time:Interval.new(30, 0);
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
   
   getUpnpRequest(request) Map {
     return(CallBackUI.getUpnpResponse(self.upnpEnabled));
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
   
   saveUpnpRequest(Bool enableUpnp, request) {
      if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        log.log("in saveupnpr");
        if (enableUpnp) {
          app.configManager.put("doUpnpForward", "true");
        } else {
          app.configManager.put("doUpnpForward", "false");
        }
        doForward();
      }
   }
   
   saveInternetListenRequest(String hostedBridge, String host, String login, String pass, request) Map {
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
      doForward();
      }
    return(null);
   }
   
   getForwardPortsList() String {
     String fpl = String.new();
     WebConnect wc = wcol.o;
       if (def(wc)) {
       for (any kv in wc.getServices()) {
        fpl += "<p><a href=\"#\" onclick=\"callApp('loadForwardPortRequest','" += kv.key += "');return false;\">Load config for " += kv.value.get("name") += "</a></p>";
       }
     }
     return(fpl);
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
   
   imapSettingsRequest(Map arg, request) {
     Map res = super.imapSettingsRequest(arg, request);
     System:Thread.new(app.plugin.getInvocation("updateNetAddresses", List.new())).start();
     return(res);
   }
   
   loggedIn(Account a, Map res, Map arg, request) Map {
    res = super.loggedIn(a, res, arg, request);
    res["devLinksList"] = getDevLinks(null, arg, request);
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
      throw(Alert.new("Account Name, Account Password, Device Name, Konnectii User, and Konnectii Password are all required"));
    }
    
    log.log("" + setupToken + " " + user + " " + pass + " " + devName + " " + konUser + " " + konPass);
    
    String stok = app.configManager.get("setupToken");
    //log.log("stok " + stok + " setuptoken " + setupToken);
     if (TS.notEmpty(stok) && TS.notEmpty(setupToken) && stok == setupToken) {
      log.log("stok passed");
      
      self.deviceName = devName;
      
      Account a = Account.new();
      a.user = user;
      a.pass = pass;
      a.perms.put("admin");
      app.pluginsByName.get("Auth").accountManager.putAccount(a);
      app.pluginsByName.get("Auth").setupSession(Maps.from("accountName", user), request);
      app.configManager.delete("setupToken");
      String rtrurl = app.configManager.get("router.Url");
      if (TS.isEmpty(rtrurl)) {
        rtrurl = "https://www.konnectii.com";
      }
      routerLink(rtrurl, user, konUser, konPass);
      updateMyLinks();
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
        }
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
      String sshLogin = app.configManager.get("il.sshLogin");
      String sshPass = app.configManager.get("il.sshPass");
      try {
        if (TS.notEmpty(sshHost) && TS.notEmpty(sshLogin) && TS.notEmpty(sshPass)) {
          wc.hostedAddress = sshHost;
          if (undef(ssh) || ssh.isClosed) {
            log.log("ssh connecting " + sshHost + " " + sshLogin);
            ssh = Ssh.new(sshHost, sshLogin, sshPass);
            ssh.open();
            rforwarded = Set.new();
          } else {
            ssh.sendKeepAlive();
          }
        }
      } catch (any sshe) {
        success = false;
        log.log("Error during ssh op " + sshe);
      }
      String extBase = "";
      wc.updateExternal(homePage, extBase, doUpnpForward, onPublicNet);
      try {
        forwardPorts(wc, ssh, rforwarded);
      } catch (any fpe) {
        success = false;
        log.log("exception during forwardports " + fpe);
      }
      log.log("updating addresses");
      app.plugin.updateNetAddresses();
      try {
        updateMyLinks();
      } catch (fpe) {
        log.log("exception during updateMyLinks ");
        if (def(fpe)) {
          log.log("fpe " + fpe);
        }
      }
      app.plugin.updateUrls();
      log.log("saving");
      app.configManager.put("hub.webConnect", Json:Marshaller.marshall(wc.toMap()));
      log.log("upnp doForward done");
      
      List au = List.new();
      if (TS.notEmpty(wc.externalUrl)) {
        app.pluginsByName.get("Auth").authedUrls.put(wc.externalUrl);
        auto parts = wc.externalUrl.split(":");
        String fs = parts[0] + ":" + parts[1];
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
      upnp.netGw = upnp.gatewayAddress;
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
  
  new(String _host, String _user, String _pass) this {
    fields {
      String host = _host;
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
    emit(jv) {
    """
    bevi_jsch = new JSch();
    bevi_session = bevi_jsch.getSession(bevp_user.bems_toJvString(), bevp_host.bems_toJvString(), 22);
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

class KBridge:KBNamePlugin {

   new() self {
    fields {
      any app;
      any plugin = self;
      String dataName = "KBridge";
      IO:Log log =@ IO:Logs.get(self);
    }
    IO:Logs.turnOnAll();
   }
   
   start() {
   }
   
   
   getIpBack(WebConnect mywc, WebConnect wc) {
    //give back internal if box shared same gateway, external address as own
    //otherwise hosted first external second
    String ipback;
    if (TS.notEmpty(wc.gateway) && TS.notEmpty(mywc.gateway) && TS.notEmpty(wc.externalAddress) && TS.notEmpty(mywc.externalAddress) && wc.gateway == mywc.gateway && wc.externalAddress == mywc.externalAddress) {
      ipback = wc.internalAddress;
    } elseIf (TS.notEmpty(wc.hostedAddress)) {
      ipback = wc.hostedAddress;
    } elseIf (TS.notEmpty(wc.externalAddress)) {
      ipback = wc.externalAddress;
    } elseIf (TS.notEmpty(wc.internalAddress)) { //if nothing else available
      ipback = wc.internalAddress;
    }
    return(ipback);
   }
   
   getWcs() {
     String wcs = app.configManager.get("hub.webConnect");
    if (TS.notEmpty(wcs)) {
      log.log("deserializing wcs " + wcs);
      WebConnect wc = WebConnect.new();
      wc.fromMap(Json:Unmarshaller.unmarshall(wcs));
      return(wc);
    }  
    return(null);
   }
   
   addressForKName(String mykn, String otherkn) Map {
    try {
      String rtrurl = app.configManager.get("router.Url");
      if (TS.isEmpty(rtrurl)) {
        rtrurl = "https://www.konnectii.com";
      }
      log.log("in afk rtrurl " + rtrurl);
      String destUrl = rtrurl;
      Map argOut = Map.new();
      argOut["action"] = "addressForKNameRequest";
      argOut["mykn"] = mykn;
      argOut["otherkn"] = otherkn;
      Web:Client:CertificateManager.validateHosts = false;
      Web:Client:CertificateManager.validateCertificates = false;
      //Web:Client:CertificateManager.acceptedThumbprints.put(ds["certificatePrint"]);
      Web:Client client = Web:Client.new();
      String payload = Json:Marshaller.marshall(argOut);
      client.outputHeaders.put("referer", destUrl);
      client.url = destUrl;
      client.openOutput().write(payload);
      String res = client.openInput().readString();
      client.close();
      log.log("calling for kn");
      if (TS.notEmpty(res)) {
        Map resMap = Json:Unmarshaller.unmarshall(res);
        log.log("!!! got res from addressForKName  " + res);
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
   
   handleWeb(request) this {
     try {
       log.log("got req");
       
       String contentIn = request.inputContent;
       log.log("conin " + contentIn);
       
       Map inresm = Json:Unmarshaller.unmarshall(contentIn);
       Map inpar = inresm["parameters"];
       
       String inpqn = inpar.get("qname");
       if (TS.notEmpty(inpqn) && inpqn.ends("ioturl.net.")) {
       
        String qt = inpar["qtype"];
        String qn = inpar["qname"];
        
        auto llsp = qn.split(".");
        if (llsp.size > 2) {
          qn = llsp.first;
          log.log("qn at end " + qn);
        }
       
        Map ansob;
        List resl;
        Map rese;
        String ansres;
        
        KvDb knwc = app.getKvDb("KNAMEWCS");
        String wcs = knwc.get(qn);
        
        WebConnect mywc = getWcs();
        if (undef(mywc)) {
          throw(Exception.new("no wc"));
        }
        if (undef(mywc.internalAddress)) {
          throw(Exception.new("no wc internaladdr"));
        }
        
        
        if (qt == "SOA") {
          
          //  String soa = "mylocalnetaddr.";
          //  soa = "konnectii.duckdns.org.";
          
         // if (def(wcs)) {
            ansob = Maps.from("qtype", "SOA", "qname", "ioturl.net", "content", mywc.internalAddress + ". 2012080849 7200 3600 1209600 3600", "ttl", 3600, "domain_id", -1);
          //} else {
          //  ansob = Maps.from("qtype", "SOA", "qname", "ioturl.net", "content", "konnectii.duckdns.org. 2012080849 7200 3600 1209600 3600", "ttl", 3600, "domain_id", -1);
          //}
          
          
          resl = List.new();
          resl += ansob;
          rese = Map.new();
          rese.put("result", resl);
          
          ansres = Json:Marshaller.marshall(rese);
          log.log("soa res " + ansres);
          request.outputContent = ansres;
          
        } elseIf (qt == "ANY") {
          log.log("in any");
          if (TS.isEmpty(wcs)) {
            log.log("wcs empty");
            if (TS.notEmpty(mywc.konnName)) {
              log.log("kn not empty, doing address for kname");
              Map resmap = addressForKName(mywc.konnName, qn);
              if (def(resmap)) {
                ipback = resmap["ipback"];
              }
            } else {
              log.log("mywc konname empty");
            }
          } else {
            WebConnect wc = WebConnect.new().fromMap(Json:Unmarshaller.unmarshall(wcs));
            log.log("wcs " + wcs);
            String ipback = getIpBack(mywc, wc);
          }
          if (TS.notEmpty(ipback)) {
              //check for ipback starting with integer, cname if not
              
              //ansob = Maps.from("qtype","A", "qname", qn + ".ioturl.net", "content",ipback, "ttl", 60);
              //ansob = Maps.from("qtype","ALIAS", "qname", qn + ".ioturl.net", "content","konnectii.duckdns.org", "ttl", 60);
              
              Bool isIp = true;
              
              auto llip = ipback.split(".");
              log.log("llip sz " + llip.size);
              if (llip.size != 4) {
                isIp = false;
              } else {
                for (String llipp in llip) {
                  log.log("llipp " + llipp);
                  if (llipp.isInteger()!) {
                    isIp = false;
                  }
                }
              }
              
              if (isIp) {
                ansob = Maps.from("qtype","A", "qname", qn + ".ioturl.net", "content",ipback, "ttl", 60);
              } else {
                //ansob = Maps.from("qtype","ALIAS", "qname", qn + ".ioturl.net", "content",ipback, "ttl", 60);
                throw(Exception.new("not ip"));
              }
              
              resl = List.new();
              resl += ansob;
              rese = Map.new();
              rese.put("result", resl);
              
              ansres = Json:Marshaller.marshall(rese);
              log.log("any res " + ansres);
              request.outputContent = ansres;
            }
        }
        
      }
         
      } catch (any e) {
        log.log("Caught exception handling request");
        if (log.will()) { if (undef(e)) { log.log("undefined exception") } else { log.log(e.toString()); } }
      }
    }
    
    nameGet() String {
       String name =@ "KBName";
       return(name);
     }
}



use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;
