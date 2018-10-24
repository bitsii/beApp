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
use Container:Pair;

use Net:Wol;
use Net:IP;

use App:Alert;

use App:LocalWebApp;
use App:RemoteWebApp;
use App:WebApp;
use Text:String;
use App:CallBackUI;

use System:Thread:Lock;
use System:Thread:ObjectLocker as OLocker;

use Crypto:Symmetric as Crypt;
emit(jv) {
"""
import java.util.Properties;
import javax.mail.Session;
import javax.mail.Store;
import javax.mail.Folder;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.InternetAddress;
import javax.mail.Transport;
import javax.mail.Message;
import javax.mail.Flags.Flag;
"""
}

emit(cs) {
"""
using System;
using MailKit.Net.Imap;
using MailKit.Search;
using MailKit;
using MimeKit;
"""
}

use class IUHub:HubStart {

   new() self {
      fields {
          IO:Log log =@ IO:Logs.get(self);
          Bool ownBackground = false;
        }
        ifEmit(iuOwnBackground) {
          ownBackground = true;
        }
    }
    
}

use System:Parameters;

use class IUHub:HubPlugin(IU:IUPlugin) {

     new() self {
       fields {
          any oapp;
          String homePage = "/App/" + self.name + "/Konn.html";
          OLocker wcol = OLocker.new();
          App:Background trc = App:Background.new();
          App:Background buu = App:Background.new();
          Bool runBackground = true;
          Lock wcl = Lock.new();
        }
        super.new();
        log =@ IO:Logs.get(self);
        //ifEmit(appDebug) {
          IO:Logs.turnOnAll();
        //}
        Web:Client:CertificateManager.validateHosts = false;
     }
     
     nameGet() String {
       String name =@ "IUHub";
       return(name);
     }
     
     restart() {
       log.log("hub doing restart/exit appstop");
       app.stop();
       log.log("exit");
       System:Process.exit(3);
     }
     
     handleCmd(Parameters params) Bool {
      String mode = params.getFirst("hubCmd");
      if (TS.isEmpty(mode)) {
        return(false);
      }
      if (mode == "onetimeSetup") {
        Bool doSetup = true;
        for (String login in app.pluginsByName.get("Auth").accountManager.getLogins()) {
          doSetup = false;
        }
        if (doSetup) {
          mode = "initialSetup";
        }
      }
      if (mode == "initialSetup" || mode == "initialRemoteSetup") {
        log.log("initialSetup");
        
        Int toksz = System:Random.getIntMax(16);
        String token = System:Random.getString(toksz + 16);
        
        app.configManager.put("setupToken", token);
        
        defadd = Net:Gateway.defaultAddress;
        
        if (TS.isEmpty(defadd)) { log.log(" No gw "); }
        ni = Net:Interface.new();
        defadd = ni.interfaceForNetwork(defadd).address;
        if (TS.isEmpty(defadd)) { log.log(" No addr "); }
        
        if (mode == "initialRemoteSetup") {
          String intPort = app.configManager.get("web.port");
          String iurl = "https://" + defadd + ":" += intPort += "/App/KBridge/Konn.html?setupToken=" + token;
          log.log("Please navigate to this address in your browser on a device on the same network as this device to complete the setup - " + iurl);
        } else {
          intPort = app.configManager.get("app.port");
          iurl = "http://127.0.0.1:" += intPort += "/App/KBridge/Konn.html?setupToken=" + token;
          log.log("Attempting to open on-device browser to " + iurl);
          UI:ExternalBrowser.openToUrl(iurl);
        }
        
        //log.log("int url is " + iurl);
        //File.apNew(params.getFirst("urlDoc")).writer.open().write(iurl).close();
        //File.apNew(params.getFirst("urlScript")).writer.open().write("#!/bin/bash\nx-www-browser " + iurl + "\n").close();
      }
      if (mode == "saveLocalUrl") {
        log.log("saveLocalUrl");
        
        Int intPorti = System:Random.getIntMax(30000);
        intPorti += 3000;
        intPort = intPorti.toString();
        app.configManager.put("app.port", intPort);
        
        String defadd = Net:Gateway.defaultAddress;
        Net:Interface ni = Net:Interface.new();
        defadd = ni.interfaceForNetwork(defadd).address;
        
        iurl = app.webProto + "://" + defadd + ":" += intPort;
        File.apNew(params.getFirst("urlFile")).writer.open().write(iurl).close();
      }
      return(true);
    }
     
     loadWc() {
    if (undef(app.plugin.wcol.o)) {
      loadWcInner();
    }
  }
  
  loadWcInner() {
    String wcs = app.configManager.get("hub.webConnect");
    if (TS.notEmpty(wcs)) {
      log.log("deserializing wcs " + wcs);
      WebConnect wc = WebConnect.new();
      wc.fromMap(Json:Unmarshaller.unmarshall(wcs));
      //log.log("after load ext port " + wc.externalPort);
      app.plugin.wcol.o = wc;
      oapp.plugin.wcol.o = wc;
      if (TS.notEmpty(wc.internalUrl)) {
        app.pluginsByName.get("Auth").authedUrls.put(wc.internalUrl);
      }
      if (TS.notEmpty(wc.externalUrl)) {
        app.pluginsByName.get("Auth").authedUrls.put(wc.externalUrl);
      }
      if (TS.notEmpty(wc.hostedUrl)) {
        app.pluginsByName.get("Auth").authedUrls.put(wc.hostedUrl);
      }
      if (TS.notEmpty(wc.konnUrl)) {
        app.pluginsByName.get("Auth").authedUrls.put(wc.konnUrl);
      }
      if (TS.notEmpty(wc.konniUrl)) {
        app.pluginsByName.get("Auth").authedUrls.put(wc.konniUrl);
      }
    }  
  }
  
  fromSameNet(WebConnect wc, request) Bool {
    Bool internal = false;
    if (request.embedded) {
       internal = true;
     } else {
       if (def(wc)) {
        internal = onSameNet(request.inputAddress, wc.internalAddress);
       } else {
        internal = false;
       }
     }
     return(internal);
  }
  
  getLinks(Account a) Map {
    Map links = Map.new();
    Json:Unmarshaller unmar = Json:Unmarshaller.new();
    if (def(a)) {
      String key = "link." + a.user + "!";
    } else {
      key = "devlink!";
    }
    for (any kv in app.getKvDb("DEVLINKS").getMap(key)) {
      WebConnect wc = WebConnect.new();
      wc.fromMap(unmar.unmarshall(kv.value));
      links.put(wc.deviceId, wc);
      log.log("loaded link " + wc.deviceName);
    }
    return(links);
  }
  
  getLink(Account a, String deviceId) {
    Map links = getLinks(a);
    if (def(links)) {
      return(links.get(deviceId));
    }
    return(null);
  }
  
  doUpdate() {
    try {
      wcl.lock();
      doUpdateInner();
      wcl.unlock();
    } catch(any e) {
      wcl.unlock();
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
    log.log("setting links");
    wc.updateInternal(homePage);
    app.plugin.wcol.o = wc;
    oapp.plugin.wcol.o = wc;
    log.log("saving");
    app.configManager.put("hub.webConnect", Json:Marshaller.marshall(wc.toMap()));
    log.log("upnp doUpdate done");
  }
  
  initLinks() {
    fields {
      String webPort;
      String certificateThumbprint; 
    }
    
    loadWc();
    
    webPort = app.webPort;
    certificateThumbprint = app.certificateThumbprint; 
    
  }
     
     cohostWith(IUHub:HubPlugin ohp) {
       log.log("in Hub cohostWith");
       runBackground = false;
       oapp = ohp.app;
       ohp.oapp = self.app;
     }
     
     appSet(_app) {
      app = _app;
      oapp = _app;
     }
     
     clearTrackingAndRenew() {
       try {
         clearTracking();
       } catch (e) { 
         log.log("error background");
         if (def(e)) { log.log("error " + e); }
       }
       try {
         renewCert();
       } catch (e) { 
         log.log("error background");
         if (def(e)) { log.log("error " + e); }
       }
       any e;
     }
     
     renewCert() {
       doLego("renew");
     }
     
     clearTracking() {
      log.log("clearing tracking");
      app.pluginsByName.get("Auth").trackingManager.clear();
     }
     
     start() {
      if (Logic:Bools.fromString(app.configManager.get("logs.turnOnAll"))) {
        IO:Logs.turnOnAll();
      }
      log.log("in hubplugin start");
      app.pluginsByName.get("Auth").nonAuthedRequests.put("pingRequest");
     
      trc.repeatDelay = Time:Interval.new(7200, 0);
      trc.minimumDelay = Time:Interval.new(7000, 0);
      trc.toInvoke = getInvocation("clearTrackingAndRenew", List.new());
      
      buu.startDelay = Time:Interval.new(10, 0);
      buu.repeatDelay = Time:Interval.new(600, 0);
      buu.minimumDelay = Time:Interval.new(300, 0);
      buu.toInvoke = getInvocation("doUpdate", List.new());
      initLinks();
      if (runBackground) {
        trc.start();
        buu.start();
      }
    }
    
  pingRequest(Map arg, request) {
    log.log("in pingrequest");
    Map res = Map.new();
    res["msg"] = "Here";
    res["action"] = "pingResponse";
    return(res);
  }
    
  runBackgroundTasks() {
    trc.runMyTasks();
    buu.runMyTasks();
  }
  
  runBackgroundTasksRequest(request) {
    log.log("IN RUN BACKGROUND TASKS REQUEST");
    for (any pl in app.plugins) {
      if (pl.can("runBackgroundTasks", 0)) {
        any res = pl.invoke("runBackgroundTasks", List.new());
      }
    }
  }
  
  saveAccountRequest(Map arg, request) {
    log.log("in hub saveAccountRequest");
    unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    any authPlug = app.pluginsByClassName.get("App:AuthPlugin");
    authPlug.saveAccountRequest(arg, request);
    return(null);
  }
     
  deviceNameGet() String {
    fields {
      String deviceName;
    }
    if (TS.isEmpty(deviceName)) {
      deviceName = app.configManager.get("deviceName");
      if (TS.isEmpty(deviceName)) {
        deviceName = "Device-" + System:Random.getString(4);
        app.configManager.put("deviceName", deviceName);
      }
    }
    return(deviceName);
  }
  
  deviceNameSet(String _deviceName) {
    if (TS.notEmpty(_deviceName)) {
      deviceName = _deviceName;
      app.configManager.put("deviceName", deviceName);
      //TODO update imap wc
      WebConnect wc = wcol.o;
      if (def(wc)) {
        wc.deviceName = deviceName;
      } 
    }
  }
  
  deviceIdGet() String {
    fields {
      String deviceId;
    }
    if (TS.isEmpty(deviceId)) {
      deviceId = app.configManager.get("deviceId");
      if (TS.isEmpty(deviceId)) {
        deviceId = System:Random.getString(16);
        app.configManager.put("deviceId", deviceId);
      }
    }
    return(deviceId);
  }
  
  profileGet() String {
    return("hub");
  }
  
  loggedIn(Account a, Map res, Map arg, request) Map {
      res["action"] = "updateResponse";
      res["profile"] = self.profile;
      res["justLoggedIn"] = true;
      res["permsString"] = a.permsString;
      res["actionLinks"] = getActionLinks(a, arg, request);
      res["appVersion"] = self.version;
      res["deviceName"] = self.deviceName;
      res["loginUri"] = self.getLoginUri(request);
      res["certificatePrint"] = wcol.o.certificatePrint;
      if (TS.notEmpty(wcol.o.internalAddress)) {
        res["internalAddress"] = wcol.o.internalAddress;
        String inx = app.configManager.get("webApp.Nxc.int.web.port");
        String ido = app.configManager.get("webApp.Domo.int.web.port");
        if (undef(inx)) { inx = ""; }
        if (undef(ido)) { ido = ""; }
        res["inx"] = inx;
        res["ido"] = ido;
      }
      
      String imso = app.configManager.get("imapSetOnce");
      if (TS.isEmpty(imso) || imso != "true") {
        //res["imapSetOnce"] = "false";
      }
      
      return(res);
    }
    
    versionGet() String {
      fields {
        String version =@ "5.8.1";
      }
      return(version);
    }
   
   checkPublicReadPath(Path pa, request) Bool {
      String pas = pa.toString();
      Path adz = Path.apNew("App/" + self.name).file.absPath;
      if (pas.begins(adz.toString()) && (pas.ends(".html") || pas.ends(".js") || pas.ends(".svg") || pas.ends(".txt") || pas.ends(".css"))) {
        return(true);
      }
      return(false);
   }
   
   okForPageToken(request) Bool {
     if (request.embedded) {
       return(true);
     }
     String ref = request.getInputHeader("referer");
     if (TS.isEmpty(ref)) {
      return(false);
     }
     Int pos = 0;
     for (Int i = 0;i < 3;i++=) {
       pos = ref.find("/", pos + 1);
     }
     ref = ref.substring(pos);
     log.log("okForPageToken " + ref);
     if (ref.has("?")) {
      ref = ref.substring(0, ref.find("?"));
     }
     log.log("okForPageToken second " + ref);
     String pref = "/App/" + self.name;
     if (ref == pref + "/Konn.html") {
      return(true);
     }
     return(false);
   }
   
   getDeviceNameRequest(request) {
      return(CallBackUI.setElementsValuesResponse(Maps.from("deviceNameDiv", self.deviceName)));
   }
   
   showImapRequest(Map arg, request) {
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      Map res = Map.new();
      return(res);
   }
   
   imapSettingsRequest(Map arg, request) {
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      app.configManager.put("imap.user", arg["imapAccount"]);
      app.configManager.put("imap.endpoint", arg["imapEndpoint"]);
      app.configManager.put("imap.pass", arg["imapPass"]);
      app.configManager.put("imap.subFolder", arg["imapFolder"]);
      String lastImSo = app.configManager.get("imapSetOnce");
      app.configManager.put("imapSetOnce", "true");
      
      //if (TS.isEmpty(lastImSo) || lastImSo != "true") {
      //  return(CallBackUI.reloadResponse());
      //}
      
      Map res = Map.new();
      res["action"] = "hideImapResponse";
      return(res);
   }
   
   runCommandRequest(Map arg, request) {
      Account a = request.context.get("account");
      String cmdKey = arg["cmdKey"];
      String user = cmdKey.substring(4, cmdKey.find("!"));
      log.log("cmd user " + user + " acct user " + a.user);
      unless (user == a.user) {
        log.log("Cmd not for user");
        return(null);
      }
      String cmd = app.configManager.get(cmdKey);
      if (TS.notEmpty(cmd)) {
        log.log("running command " + cmd);
        System:Command.new(cmd).run();
      }
      return(null);
   }
   
   restoreConfig(String path) {
     File dirFile = File.apNew(path);
     any e;
     IO:Reader inr = dirFile.reader.open();
     String res = dirFile.contents;
     Map conf = Json:Unmarshaller.unmarshall(res);
     any ac = app.configManager;
     for (any kv in conf) {
       ac.put(kv.key, kv.value);
     }
   }
   
   restoreConfigRequest(Map arg, request) Map {
     log.log("rs request");
     String path = arg["path"];
     Account a = request.context.get("account");
     unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("must be admin"));
     }
     if (TS.notEmpty(path)) {
       restoreConfig(Encode:Hex.new().decode(path));
     }
     //TODO update imap wc
     return(null);
   }
   
   upgradeRequest(Map arg, request) Map {
     log.log("upgrade request");
     String path = arg["path"];
     unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("must be admin"));
     }
     upgrade(Encode:Hex.new().decode(path));
     return(null);
   }
     
   upgrade(String path) {
     if (TS.notEmpty(path)) {
       Path dpath = Path.apNew("App/KBridge.zip");
       File dirFile = File.apNew(path);
       if (dirFile.path.steps.last.begins("KBridge")!) {
        throw(Alert.new("upgrade file must be named KBridge*.zip and must be a bridge installer/upgrade zip file"));
       }
       any e;
       try {
        app.lock.lock();
        log.log("copying " + dirFile.path + " to " + dpath);
        if (dirFile.exists!) { throw(Alert.new("upgrade file does not exist")); }
        if (dpath.file.exists) { dpath.file.delete(); }
        IO:Writer outw = dpath.file.writer.open();
        IO:Reader inr = dirFile.reader.open();
        inr.copyData(outw);
        outw.close();
        inr.close();
        log.log("upgrade copy complete");
        Path upd = Path.apNew("App/KBridge/upgradeDone.txt");
        if (upd.file.exists) { log.log("del updf"); upd.file.delete(); }
        log.log("running upgrade");
        String piccmd = "App/KBridge/upgrade.sh";
        System:Command.new(piccmd).run();
        log.log("waiting for upgradeDone");
        for (Int i = 0;i < 200;i++=) {
          if (upd.file.exists) {
            log.log("upd exists exit");
            System:Process.exit(4);
          } else {
            log.log("upd not exist sleep");
            Time:Sleep.sleepSeconds(2);
          }
        }
        app.lock.unlock();
       } catch (e) {
          app.lock.unlock();
       }
     }
     return(null);
   }
   
   getLoginUri(request) String {
     String loginBookmark = "/App/" + self.name + "/Konn.html";
     return(loginBookmark);
   }
   
   
  
  isInternal(request) Bool {
    WebConnect wc = wcol.o;
    Bool internal = false;
    if (request.embedded) {
       internal = true;
     } else {
       if (def(wc)) {
        internal = onSameNet(request.inputAddress, wc.internalAddress);
       } else {
        internal = false;
       }
     }
     return(internal);
  }
  
  pingUrl(String destUrl, Int waitFirst) String {
    if (pingUrlInner(destUrl, waitFirst)) {
      return(destUrl);
    }
    return(null);
  }
  
  chooseUrl(WebConnect wco) String {
    System:Thread cui = System:Thread.new(getInvocation("pingUrl", Lists.from(wco.internalUrl, 0)));
    System:Thread cue = System:Thread.new(getInvocation("pingUrl", Lists.from(wco.externalUrl, 0)));
    System:Thread cuh = System:Thread.new(getInvocation("pingUrl", Lists.from(wco.hostedUrl, 100)));
    List pingers = Lists.from(cui, cue, cuh);
    try {
      Web:Client:CertificateManager.validateHosts = false;
      //Web:Client:CertificateManager.validateCertificates = false;
      Web:Client:CertificateManager.acceptedThumbprints.put(wco.certificatePrint);
      
      for (System:Thread pinger in pingers) {
        pinger.start();
      }
      
      for (Int i = 0;i < 1500;i++=) {
        Bool allDone = true;
        for (pinger in pingers) {
          if (pinger.finished.o) {
            if (TS.notEmpty(pinger.returned.o)) {
              resetCertMan(wco.certificatePrint);
              return(pinger.returned.o);
            }
          } else {
            allDone = false;
          }
        }
        if (allDone) {
          resetCertMan(wco.certificatePrint);
          return(null);
        }
        Time:Sleep.sleepMilliseconds(20);
      }
      resetCertMan(wco.certificatePrint);
    } catch(any e) {
      resetCertMan(wco.certificatePrint);
    }
    return(null);
  }
  
  resetCertMan(String certPrint) {
    Web:Client:CertificateManager.validateHosts = true;
    Web:Client:CertificateManager.acceptedThumbprints.delete(certPrint);
  }
  
  pingUrlInner(String destUrl, Int waitFirst) Bool {
    Bool worked = false;
    if (TS.isEmpty(destUrl)) {
      return(false);
    }
    try {
      if (waitFirst > 0) {
        Time:Sleep.sleepMilliseconds(waitFirst);
      }
      log.log("PINGING " + destUrl);
      Map argOut = Maps.from("action", "pingRequest");
      Web:Client client = Web:Client.new();
      String payload = Json:Marshaller.marshall(argOut);
      client.outputHeaders.put("referer", destUrl);
      client.url = destUrl;
      client.openOutput().write(payload);
      String res = client.openInput().readString();
      client.close();
      if (TS.notEmpty(res)) {
        log.log("!!! PING got res from pingRequest  " + res);
        Map resMap = Json:Unmarshaller.unmarshall(res);
        if (TS.notEmpty(resMap.get("action")) && resMap["action"] == "pingResponse") {
          worked = true;
          log.log("PING REQUEST GOOD " + destUrl);
        }
      } else {
        log.log("!!! PING RES EMPTY");
      }
    } catch (any e) {
      log.log("ERROR DURING PING ");
      if (def(e)) {
        log.log("PING ERROR IS " + e);
      } else {
        log.log("PING ERROR EMPTY");
      }
    }
    return(worked);
  }
  
  onSameNet(String firstAddr, String secondAddr) Bool {
     Bool internal = false;
     String cp = TS.commonPrefix(firstAddr, secondAddr);
      if (TS.notEmpty(cp)) {
        LinkedList ll = cp.split(".");
        log.log(" rint dotsplit size " + ll.size + " ra " + firstAddr + " ia " + secondAddr);
        if (ll.size > 2) {
          internal = true;
        }
      }
      return(internal);
    }
    
  getActionLinks(Account a, Map arg, request) String {
    String actionLinks = String.new();
    for (any plugin in app.plugins) {
      if (plugin.can("updateActionLinks", 4)) {
        plugin.updateActionLinks(actionLinks, a, arg, request);
      }
    }
    return(actionLinks);
  }
  
  prepKonnName() {
    String duckDomain = app.configManager.get("duck.domain");
    String cfHost = app.configManager.get("cf.host");
    String cfZone = app.configManager.get("cf.zone");
    
    String cfiHost = app.configManager.get("cf.ihost");
    String duckiDomain = app.configManager.get("duck.idomain");
    
    loadWc();
    WebConnect wc = app.plugin.wcol.o;
    if (TS.notEmpty(cfHost) && TS.notEmpty(cfZone)) {
      wc.konnAddress = cfHost + "." + cfZone;
    } elseIf (TS.notEmpty(duckDomain)) {
      wc.konnAddress = duckDomain + ".duckdns.org";
    } else {
      wc.konnAddress = "";
    }
    
    if (TS.notEmpty(cfiHost) && TS.notEmpty(cfZone)) {
      wc.konniAddress = cfiHost + "." + cfZone;
    } elseIf (TS.notEmpty(duckiDomain)) {
      wc.konniAddress = duckiDomain + ".duckdns.org";
    } else {
      wc.konniAddress = "";
    }
    
    wc.updateKonnLink();
    if (TS.notEmpty(wc.konnUrl)) {
      app.pluginsByName.get("Auth").authedUrls.put(wc.konnUrl);
    }
    wc.updateKonniLink();
    if (TS.notEmpty(wc.konniUrl)) {
      app.pluginsByName.get("Auth").authedUrls.put(wc.konniUrl);
    }
    app.configManager.put("hub.webConnect", Json:Marshaller.marshall(wc.toMap()));
    
  }
  
  saveCfRequest(String cfHost, String cfiHost, String cfZone, String cfEmail, String cfToken, request) {
    unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    app.configManager.put("cf.host", cfHost);
    app.configManager.put("cf.ihost", cfiHost);
    app.configManager.put("cf.zone", cfZone);
    app.configManager.put("cf.email", cfEmail);
    app.configManager.put("cf.token", cfToken);
    updateCf();
  }
  
  updateCf() {
    any fpe;
    try {
        updateCfInner();
    } catch (fpe) {
      log.log("exception during updateDuck ");
      if (def(fpe)) {
        log.log("fpe " + fpe);
      }
    }
  }
  
  updateCfInner() {
    log.log("in updateCfInner");
    prepKonnName();
    String cfHost = app.configManager.get("cf.host");
    String cfiHost = app.configManager.get("cf.ihost");
    String cfZone = app.configManager.get("cf.zone");
    String cfEmail = app.configManager.get("cf.email");
    String cfToken = app.configManager.get("cf.token");
    
    String hip = app.configManager.get("il.sshHost");
    if (TS.notEmpty(hip)) {
      unless (IP.isIP(hip)) {
        hip = IP.IPForName(hip);
      }
    }
    
    if (TS.notEmpty(cfiHost)) {
      WebConnect wc = app.plugin.wcol.o;
      if (def(wc) && TS.notEmpty(wc.internalAddress)) {
        String iaddr = wc.internalAddress;
      }
    }
    
    if (TS.isEmpty(cfHost) || TS.isEmpty(cfZone) || TS.isEmpty(cfEmail) || TS.isEmpty(cfToken)) {
      log.log("one of the params for cf is missing");
      return(self);
    }
    
    Path cfp = app.paths.dataPath.addStep("ddclient");
    if (cfp.file.exists!) {
      cfp.file.makeDirs();
    }
    cfp = cfp.addStep("ddclient.conf");
    if (cfp.file.exists) {
      cfp.file.delete();
    }
    
    String ddconf = String.new();
    if (TS.notEmpty(hip)) {
      ddconf += "use=cmd, cmd=App/KBridge/ddclip.sh\n";
      Path dip = Path.apNew("Data/KBridge/ddclient/ddip");
      if (dip.file.exists) { dip.file.delete(); }
      dip.file.writer.open().writeStringClose(hip + "\n");
    } else {
      ddconf += "use=web\n";
    }
    ddconf += "protocol=cloudflare\n";
    ddconf += "ssl=yes\n";
    ddconf += "login=" += cfEmail += "\n";
    ddconf += "password=" += cfToken += "\n";
    ddconf += "zone=" += cfZone += "\n";
    ddconf += cfHost += "." += cfZone += "\n";
    
    log.log("ddconf " + ddconf);

    cfp.file.writer.open().writeStringClose(ddconf);
    
    String res = System:Command.new("./App/KBridge/ddrun.sh").open().output.readStringClose();
    log.log("ddclient res " + res);
    
    if (TS.notEmpty(cfiHost) && TS.notEmpty(iaddr)) {
      
      cfp = app.paths.dataPath.addStep("ddclient");
      if (cfp.file.exists!) {
        cfp.file.makeDirs();
      }
      cfp = cfp.addStep("ddclienti.conf");
      if (cfp.file.exists) {
        cfp.file.delete();
      }
      
      ddconf = String.new();
      ddconf += "use=cmd, cmd=App/KBridge/ddclipi.sh\n";
      dip = Path.apNew("Data/KBridge/ddclient/ddipi");
      if (dip.file.exists) { dip.file.delete(); }
      dip.file.writer.open().writeStringClose(iaddr + "\n");
      ddconf += "protocol=cloudflare\n";
      ddconf += "ssl=yes\n";
      ddconf += "login=" += cfEmail += "\n";
      ddconf += "password=" += cfToken += "\n";
      ddconf += "zone=" += cfZone += "\n";
      ddconf += cfiHost += "." += cfZone += "\n";
      
      log.log("ddconfi " + ddconf);

      cfp.file.writer.open().writeStringClose(ddconf);
      
      res = System:Command.new("./App/KBridge/ddruni.sh").open().output.readStringClose();
      log.log("ddclient resi " + res);
    
    }
    
    
  }
  
  doLego(String actionType) {
    String cfHost = app.configManager.get("cf.host");
    String cfiHost = app.configManager.get("cf.ihost");
    String cfZone = app.configManager.get("cf.zone");
    String cfEmail = app.configManager.get("cf.email");
    String cfToken = app.configManager.get("cf.token");
    
    String duckEmail = app.configManager.get("duck.email");
    String duckDomain = app.configManager.get("duck.domain");
    String duckiDomain = app.configManager.get("duck.idomain");
    String duckToken = app.configManager.get("duck.token");
    
    String lecmd;
    if (TS.notEmpty(cfHost) && TS.notEmpty(cfZone) && TS.notEmpty(cfEmail) && TS.notEmpty(cfToken)) {
      lecmd = "./App/KBridge/lecf.sh " + cfEmail + " " + cfToken + " " + cfHost + "." + cfZone + " " + actionType + " " + "cert.pem";
    } elseIf(TS.notEmpty(duckEmail) && TS.notEmpty(duckDomain) && TS.notEmpty(duckToken)) {
      lecmd = "./App/KBridge/ledd.sh " + duckEmail + " " + duckToken + " " + duckDomain + ".duckdns.org" + " " + actionType + " " + "cert.pem";
    } else {
      log.log("did not have doLego configs for any option");
      return(self);
    }
    
    log.log("running lecmd " + lecmd);
    
    String res = System:Command.new(lecmd).open().output.readStringClose();
    
    log.log("lecmd res " + res);
    
    if (TS.notEmpty(cfiHost) && TS.notEmpty(cfZone) && TS.notEmpty(cfEmail) && TS.notEmpty(cfToken)) {
      lecmd = "./App/KBridge/lecf.sh " + cfEmail + " " + cfToken + " " + cfiHost + "." + cfZone + " " + actionType + " " + "certi.pem";
    } elseIf(TS.notEmpty(duckEmail) && TS.notEmpty(duckiDomain) && TS.notEmpty(duckToken)) {
      lecmd = "./App/KBridge/ledd.sh " + duckEmail + " " + duckToken + " " + duckiDomain + ".duckdns.org" + " " + actionType + " " + "certi.pem";
    } else {
      log.log("did not have doLego configs for any optioni");
      return(self);
    }
    
    log.log("running lecmdi " + lecmd);
    
    res = System:Command.new(lecmd).open().output.readStringClose();
    
    log.log("lecmdi res " + res);
    
  }
   
  saveDuckRequest(String duckDomain, String duckiDomain, String duckEmail, String duckToken, request) {
    unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      throw(Alert.new("Must be administrator"));
    }
    app.configManager.put("duck.domain", duckDomain);
    app.configManager.put("duck.idomain", duckiDomain);
    app.configManager.put("duck.email", duckEmail);
    app.configManager.put("duck.token", duckToken);
    updateDuck();
  }
  
  updateDuck() this {
    any fpe;
    try {
        updateDuckInner();
    } catch (fpe) {
      log.log("exception during updateDuck ");
      if (def(fpe)) {
        log.log("fpe " + fpe);
      }
    }
  }
  
  updateDuckInner() this {
    log.log("in updateduck");
    prepKonnName();
    String duckDomain = app.configManager.get("duck.domain");
    String duckiDomain = app.configManager.get("duck.idomain");
    String duckToken = app.configManager.get("duck.token");
    String hip = app.configManager.get("il.sshHost");
    if (TS.notEmpty(hip)) {
      unless (IP.isIP(hip)) {
        hip = IP.IPForName(hip);
      }
    }
    if (TS.notEmpty(duckiDomain)) {
      WebConnect wc = app.plugin.wcol.o;
      if (def(wc) && TS.notEmpty(wc.internalAddress)) {
        String iaddr = wc.internalAddress;
      }
    }
    if (TS.notEmpty(duckDomain) && TS.notEmpty(duckToken)) {
       log.log("doing duckupdate");
       
       String url =  "https://www.duckdns.org/update/" + duckDomain + "/" + duckToken;
       if (TS.notEmpty(hip)) {
         url += "/" += hip;
       }
       log.log("duck update url " + url);
       Web:Client client = Web:Client.new();
       Web:Client:CertificateManager.validateCertificates = false;
       client.verb = "GET";
       client.url = url;
       String res = client.openInput().readString();
       client.close();
       
       if (TS.notEmpty(duckiDomain) && TS.notEmpty(iaddr)) {
         log.log("doing duckiupdate");
         url =  "https://www.duckdns.org/update/" + duckiDomain + "/" + duckToken;
         url += "/" += iaddr;
         log.log("duck update url " + url);
         client = Web:Client.new();
         Web:Client:CertificateManager.validateCertificates = false;
         client.verb = "GET";
         client.url = url;
         res = client.openInput().readString();
         client.close();
       }
       
       Web:Client:CertificateManager.validateCertificates = true;
       log.log("duckupdate done");
    }
  }
   
  updateActionLinks(String actionLinks, Account a, Map arg, request) String {
     //CMD.username!Display = cmd
     log.log("in hub updateActionLinks");
     Map ecm = app.configManager.getMap("CMD." + a.user + "!");
     for (kv in ecm) {
      String key = kv.key;
      key = key.substring(key.find("!") + 1, key.size);
      actionLinks += "<p><a href=\"#\" onclick=\"callUI('runCommand', '" += kv.key += "');return false;\">" += key += "</a></p>";
     }
     Bool internal = isInternal(request);
     
     String outerLinks = String.new();
     String innerLinks = String.new();
      
      WebConnect wc = wcol.o;
      
      if (def(wc)) {
        if (TS.notEmpty(wc.hostedLink)) {
          dlUse = innerLinks;
          if (TS.isEmpty(app.configManager.get("duck.domain")) && TS.isEmpty(app.configManager.get("cf.host"))) {
            outerLinks += "<p>" += wc.hostedLink += "</p>";
          } else {
            outerLinks += "<p>" += wc.konnLink += "</p>";
          }
        } elseIf((wc.manualForward || wc.internalResolve) && TS.notEmpty(wc.konnLink)) {
          dlUse = innerLinks;
          outerLinks += "<p>" += wc.konnLink += "</p>";
         } else {
           dlUse = outerLinks;
           if (internal) {
                if (TS.notEmpty(wc.konniLink)) {
                  outerLinks += "<p>" += wc.konniLink += "</p>";
                } else {
                  outerLinks += "<p>" += wc.internalLink += "</p>";
                }
              } else {
                if (TS.notEmpty(wc.hostedLink)) {
                  outerLinks += "<p>" += wc.hostedLink += "</p>";
                } elseIf (TS.notEmpty(wc.externalLink)) {
                  outerLinks += "<p>" += wc.externalLink += "</p>";
                } elseIf (TS.notEmpty(wc.konniLink)) {
                  outerLinks += "<p>" += wc.konniLink += "</p>";
                } elseIf (TS.notEmpty(wc.internalLink)) {
                  outerLinks += "<p>" += wc.internalLink += "</p>";
                }
              }
         }
         if (TS.notEmpty(wc.konnLink)) {
            dlUse += "<p>" += wc.konnLink += "</p>";
          }
          if (TS.notEmpty(wc.konniLink)) {
            dlUse += "<p>" += wc.konniLink += "</p>";
          }
          if (TS.notEmpty(wc.internalLink)) {
            dlUse += "<p>" += wc.internalLink += "</p>";
          }
          if (TS.notEmpty(wc.hostedLink)) {
            innerLinks += "<p>" += wc.hostedLink += "</p>";
          } 
          if (TS.notEmpty(wc.externalLink)) {
            dlUse += "<p>" += wc.externalLink += "</p>";
          }
      
        Map svcs = wc.getServices();
        if (def(svcs)) {
           Map accountLinks = getLinks(null);
          for (any kv in svcs) {
             if (TS.notEmpty(kv.value.get("hstLink"))) {
               dlUse = innerLinks;
               outerLinks += "<p>" += kv.value.get("hstLink") += "</p>";
            } elseIf((wc.manualForward || wc.internalResolve) && TS.notEmpty(kv.value.get("konnLink"))) {
              String dlUse = innerLinks;
              outerLinks += "<p>" += kv.value.get("konnLink") += "</p>";
            } else {
              dlUse = outerLinks;
              if (internal) {
                outerLinks += "<p>" += kv.value.get("intLink") += "</p>";
              } else {
                if (TS.notEmpty(kv.value.get("hstLink"))) {
                  outerLinks += "<p>" += kv.value.get("hstLink") += "</p>";
                } elseIf (TS.notEmpty(kv.value.get("extLink"))) {
                  outerLinks += "<p>" += kv.value.get("extLink") += "</p>";
                } elseIf (TS.notEmpty(kv.value.get("intLink"))) {
                  outerLinks += "<p>" += kv.value.get("intLink") += "</p>";
                }
              }
            }
            if (TS.notEmpty(kv.value.get("konnLink"))) {
              dlUse += "<p>" += kv.value.get("konnLink") += "</p>";
            }
            if (TS.notEmpty(kv.value.get("konniLink"))) {
              dlUse += "<p>" += kv.value.get("konniLink") += "</p>";
            }
            if (TS.notEmpty(kv.value.get("intLink"))) {
              dlUse += "<p>" += kv.value.get("intLink") += "</p>";
            }
            if (TS.notEmpty(kv.value.get("hstLink"))) {
              innerLinks += "<p>" += kv.value.get("hstLink") += "</p>";
            } 
            if (TS.notEmpty(kv.value.get("extLink"))) {
              dlUse += "<p>" += kv.value.get("extLink") += "</p>";
            }
          }
        }
      }
     
      
      actionLinks += "<div id=\"primaryLinksDiv\" style=\"display: none;\">";
      actionLinks += outerLinks;
      actionLinks += "<a href=\"#\" onclick=\"callUI('toggleDisplay', 'secondaryLinksDiv');return false;\">Show/Hide more service connection options</a>";
      actionLinks += "<div id=\"secondaryLinksDiv\" style=\"display: none;\">";
      actionLinks += innerLinks;
      actionLinks += "</div>";
      actionLinks += "</div>";
      
     return(actionLinks);
   }
   
   wakeDevRequest(String deviceId, request) {
     Wol wol = Wol.new();
     //WebConnect wc = getLink(request.context.get("account"), deviceId);
     WebConnect wc = getLink(null, deviceId);
     if (def(wc)) {
       log.log("waking " + wc.deviceName);
       for (Int i = 0;i < 3;i++=) {
         for (String mac in wc.internalMacAddresses) {
           if (TS.notEmpty(mac)) {
            log.log("wake for mac addr " + mac);
            wol.wakeMacAddr(mac);
           }
         }
       }
     }
   }
   
   aboutRequest(request) Map {
     String about = "<p>Edgii Bridge Version " + self.version + "<p>";
     return(CallBackUI.setElementsInnerHTMLResponse(Maps.from("aboutDivMsg", about)))
   }
   
}

use Email:Imap;

class Imap {

  new() self {
  
  }

}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;

class IUDoer:DoerPlugin(App:AjaxPlugin) {

  new() self {
     fields {
        any app;
        String name = "IUDoer";
      }
      super.new();
      log =@ IO:Logs.get(self);
   }
     
  start() {
  }
     
  updateActionLinks(String actionLinks, Account a, Map arg, request) String {
    //actionLinks += "<p>MOAR LINKS</p>";
    Map ecm = app.configManager.getMap("DO." + a.user + "!");
     for (any kv in ecm) {
      String key = kv.key;
      key = key.substring(key.find("!") + 1, key.size);
      String actionType = key.substring(0, key.find("!"));
      String actionTitle = key.substring(key.find("!") + 1, key.size);
      actionLinks += "<p><a href=\"#\" onclick=\"callApp('doerToggleRequest', '" + kv.key + "');return false;\">" + actionTitle + "</a></p>";
     }
    return(actionLinks);
  }

}

