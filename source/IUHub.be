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

use App:Alert;

use App:AuthenticatedLocalApp;
use App:AuthenticatedWebApp;
use App:AuthenticatedApp as AuthedApp;
use Text:String;
use App:CallBackUI;

use class IUHub:ConnectionUpdate {

  new() self {
  
    fields {
      any app;
      any oapp;
      IO:Log log =@ IO:Logs.get(self);
      Int lastPoll = 0;
      Int lastUpdate = 0;
      Int lastFwd = 0;
      Int pollSecs = 1200;//how often to check for ip changes
      Int uupdateSecs = 600;//how often to update upnp fwd
      Int forceUpdate = 3600;//imap force update
      Bool disable = false;
      String webPort;
      String certificateThumbprint; 
      Ssh ssh;
      Set rforwarded;
    }
  
  }
  
  clear() {
    lastPoll = 0;
    lastUpdate = 0;
    lastFwd = 0;
  }
  
  updateOnInterval() {
    Int currSec = Time:Interval.now().seconds;
    if (currSec - lastPoll > pollSecs) {
      lastPoll = currSec;
      doUpdate();
    }
  }
  
  loadWc() {
    if (undef(app.plugin.wcol.o)) {
      loadWcInner();
    }
  }
  
  loadWcInner() {
    String wcs = app.configManager.get("wui.webConnect");
    if (TS.notEmpty(wcs)) {
      log.log("deserializing wcs");
      WebConnect wc = WebConnect.new();
      wc.fromMap(Json:Unmarshaller.unmarshall(wcs));
      //log.log("after load ext port " + wc.externalPort);
      app.plugin.wcol.o = wc;
      oapp.plugin.wcol.o = wc;
    }  
  }
  
  loadLinks() {
    if (undef(app.plugin.linksol.o)) {
      loadLinksInner();
    }
  }
  
  loadLinksInner() {
    Map links = Map.new();
    Json:Unmarshaller unmar = Json:Unmarshaller.new();
    for (any kv in app.configManager.getMap("link.")) {
      WebConnect wc = WebConnect.new();
      wc.fromMap(unmar.unmarshall(kv.value));
      links.put(wc.deviceId, wc);
      log.log("loaded link " + wc.deviceName);
    }
    wc = app.plugin.wcol.o;
    if (def(wc)) {
      links.put(wc.deviceId, wc);
    }
    app.plugin.linksol.o = links;
    oapp.plugin.linksol.o = links;
  }
  
  doUpdate() {
    any e;
    log.log("In upnp doUpdate");
    unless (disable) {
      
      Bool update = false;
      Bool fwd = false;
      
      Int currSec = Time:Interval.now().seconds;
      if (currSec - lastUpdate > forceUpdate) {
        lastUpdate = currSec;
        update = true;
      }
      if (currSec - lastFwd > uupdateSecs) {
        lastFwd = currSec;
        fwd = true;
      }
      log.log("getting wc");
      loadWc();
      WebConnect wc = app.plugin.wcol.o;
      if (def(wc)) {
        log.log("wc from wcol");
      } else {
        log.log("new wc");
        wc = WebConnect.new();
        wc.extraPorts = app.configManager.get("upnp.extraPorts");
      }
      log.log("after wc init");
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
      if (TS.isEmpty(wc.externalPort)) {
        wc.externalPort = app.configManager.get("wui.extPort");
      }
      log.log("starting wc update");
      if (fwd) {
        log.log("wc forwarding ports");
        
        String sshHost = app.configManager.get("il.sshHost");
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
          log.log("Error during ssh op " + sshe);
          try {
             ssh.close();
             ssh = null;
           } catch (sshe) {
             ssh = null;
           }
        }
        wc.update();
        wc.forwardPorts(ssh, rforwarded);
      } else {
        if (def(ssh) && ssh.isClosed!) {
          try {
            ssh.sendKeepAlive();
          } catch (sshe) {
           log.log("Error during ssh op " + sshe);
           try {
             ssh.close();
             ssh = null;
           } catch (sshe) {
           
           }
          }
        }
        wc.update();
      }
      log.log("setting links");
      app.plugin.wcol.o = wc;
      oapp.plugin.wcol.o = wc;
      log.log("updating addresses");
      app.plugin.updateNetAddresses();
      app.plugin.updateUrls();
      log.log("saving");
      app.configManager.put("wui.webConnect", Json:Marshaller.marshall(wc.toMap()));
      log.log("upnp doUpdate done");
    }
  }
  
  init() {
    
    String disables = app.configManager.get("upnp.disable");
    if (TS.notEmpty(disables) && disables == "true") {
      disable = true;
    }
    
    String pollSecsS = app.configManager.get("upnp.pollSecs");
    if (TS.notEmpty(pollSecsS)) {
      pollSecs = Int.new(pollSecsS);
    } else {
      app.configManager.put("upnp.pollSecs", pollSecs.toString());
    }
    
    String forceUpdateS = app.configManager.get("imap.forceUpdateSecs");
    if (TS.notEmpty(forceUpdateS)) {
      forceUpdate = Int.new(forceUpdateS);
    } else {
      app.configManager.put("upnp.forceUpdateSecs", forceUpdate.toString());
    }
    
    String uupdateSecsS = app.configManager.get("upnp.updateSecs");
    if (TS.notEmpty(uupdateSecsS)) {
      uupdateSecs = Int.new(uupdateSecsS);
    } else {
      app.configManager.put("upnp.updateSecs", uupdateSecs.toString());
    }
    
    loadWc();
    loadLinks();
    
    webPort = app.webPort;
    certificateThumbprint = app.certificateThumbprint; 
    
  }

}

use class IUHub:Background {

  new() self {
    fields {
      any app;
      any oapp;
      IO:Log log =@ IO:Logs.get(self);
      ConnectionUpdate uu = ConnectionUpdate.new();
    }
  }
  
  runMyTasks() {
    fields {
      Int lastTrackClear;
      Int clearSeconds =@ 7200;
      Int lastUpdCheck;
      Int updCheckSeconds =@ 43200;
    }
    
    if (def(lastTrackClear)) {
      Int ns = Time:Interval.now().seconds;
      if (ns - lastTrackClear > clearSeconds) {
        app.trackingManager.clear();
        lastTrackClear = ns;
      }
    } else {
      lastTrackClear = 0;
    }
    
    if (def(lastUpdCheck)) {
      ns = Time:Interval.now().seconds;
      if (ns - lastUpdCheck > updCheckSeconds) {
        app.plugin.checkAndUpdate();
        lastUpdCheck = ns;
      }
    } else {
      lastUpdCheck = 0;
    }
    
  }
  
  runTasks() {
    //log.log("Running tasks");
    runMyTasks();
    uu.updateOnInterval();
  }
  
  main() {
    any e;
    Time:Sleep.sleepSeconds(10);
    while (true) {
      try {
        runTasks();
      } catch (e) {
        log.log("Caught exception running tasks " + e);
      }
      try {          
        Time:Sleep.sleepMilliseconds(sleepTime);
      } catch (e) {
        log.log("Caught exception sleeping " + e);
      }
    }
  }
  
  init() self {
    fields {
      System:Thread myThread;
      Int sleepTime = 500;
    }
    String bkdis = app.configManager.get("bk.disable");
    if (TS.notEmpty(bkdis) && Bool.new(bkdis)) {
      return(self);
    }
    Int _sleepTime = app.configManager.get("bk.sleepTime");
    if (def(_sleepTime) && _sleepTime > 0) {
      sleepTime = _sleepTime;
    }
    uu.app = app;
    uu.init();
  }
  
  startBackground() self {
    init();
    myThread = System:Thread.new(self);
    myThread.start();
  }

}

use class IUHub:HubStart {

   new() self {
      fields {
          IO:Log log =@ IO:Logs.get(self);
        }
    }

  main() {
      main(System:Process.new().args);
    }
    
    main(List args) {
      outerMain(System:Process.new().args);
      /*try {
        app.configManager.close();
      } catch (any e) {
        log.log("Exception closing db in CmdUI, error is " + e);
      }*/
    }
    
    outerMain(List args) {
      try {
        innerMain(System:Process.new().args);
      } catch (any e) {
        log.log("Exception in CmdUI, error is " + e);
      }
    }
    
    innerMain(List args) {

      Web:Client:CertificateManager.validateHosts = false;

      if (args.length > 0) {
        String mode = args[0]; //ui, svc, both, [absent]
        log.log("mode " + mode);
      } else {
        log.log("mode empty");
      }
      if (TS.isEmpty(mode)) {
        mode = "wui";
      }
      if (mode == "lui" || mode == "wui" || mode == "cmd") {
        log.log("making hub");
        HubPlugin hub = HubPlugin.new();
        if (mode == "cmd") {
          hub.runBackground = false;
        }
        log.log("adding plugins");
        List plugins = List.new();
        plugins += hub;
        plugins += App:AuthPlugin.new();
        plugins += App:ConfigPlugin.new();
        plugins += App:FileManagerPlugin.new();
        if (mode == "lui") {
          //AuthenticatedLocalApp.new(plugins).main();
        }
        if (mode == "wui") {
          //AuthenticatedWebApp.new(plugins).main();
        }        
        if (mode == "cmd") {
          cmdMain(args, plugins);
        }
      }
      if (mode == "test") {
        IUHub:Test.new().main();
      }
    }

    cmdMain(List args, plugins) {
      AuthedApp ui = AuthedApp.new();
      
      if (args.length > 1) {
        String mode = args[1]; //ui, svc, both, [absent]
        log.log("cmd " + mode);
      } 
      if (TS.isEmpty(mode)) {
        log.log("cmd empty");
      }
      if (mode == "help") {
        log.log("Help");
        log.log("listLogins, putAccount, getAccount, setPermsString, setPass, deleteAccount, updateConfig, showConfig, createConfig, deleteConfig");
      }
      if (TS.notEmpty(mode) && mode == "portForward") {
        Net:PortForward pf = Net:PortForward.new(args[2], Int.new(args[3]), args[4], Int.new(args[5]));
        pf.start();
      }
      if (TS.notEmpty(mode) && mode == "listLogins") {
        for (String login in ui.accountManager.getLogins()) {
          log.log("Account login " + login);
        }
      }
      if (TS.notEmpty(mode) && (mode == "putAccount" || mode == "createAccount")) {
        String user = args[2];
        String pass = args[3];
        log.log("Putting Account " + user);
        Account ac = Account.new();
        ac.user = user;
        ac.pass = pass;
        if (args.length > 4) {
          ac.permsString = args[4];
        }
        ui.accountManager.putAccount(ac);
      }
      if (TS.notEmpty(mode) && mode == "getAccount") {
        user = args[2];
        log.log("Get Account " + user);
        ac = ui.accountManager.getAccount(user);
        log.log("Account " + ac);
      }
      if (TS.notEmpty(mode) && mode == "setPermsString") {
        user = args[2];
        String ps = args[3];
        log.log("Set Perms " + user);
        ac = ui.accountManager.getAccount(user);
        ac.permsString = ps;
        ui.accountManager.putAccount(ac);
        log.log("Account " + ac);
      }
      if (TS.notEmpty(mode) && mode == "setPass") {
        user = args[2];
        pass = args[3];
        log.log("Set Pass " + user);
        ac = ui.accountManager.getAccount(user);
        ac.pass = pass;
        ui.accountManager.putAccount(ac);
      }
      if (TS.notEmpty(mode) && mode == "deleteAccount") {
        user = args[2];
        log.log("Deleting Account " + user);
        ac = ui.accountManager.getAccount(user);
        if (def(ac)) {
          ui.accountManager.deleteAccount(ac);
          log.log("Deleted account " + user);
        } else {
          log.log("No such account for deletion " + user);
        }
      }
      if (TS.notEmpty(mode) && mode == "updateConfig") {
        String key = args[2];
        String value = args[3];
        log.log("Updating config " + key + " " + value);
        ui.configManager.put(key, value);
      }
      if (TS.notEmpty(mode) && mode == "showConfig") {
        for (any kv in ui.configManager.getMap()) {
          log.log("Config name " + kv.key + " value " + kv.value);
        }
      }
      if (TS.notEmpty(mode) && mode == "createConfig") {
        key = args[2];
        value = args[3];
        log.log("Creating config " + key + " " + value);
        ui.configManager.put(key, value);
      }
      if (TS.notEmpty(mode) && mode == "deleteConfig") {
        key = args[2];
        log.log("Deleting config " + key);
        ui.configManager.delete(key);
      }
      ui.configManager.close();
    }

}


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
use class IUHub:HubPlugin {

     new() self {
       fields {
          IO:Log log =@ IO:Logs.get(self);
          any app;
          String name = "IUHub";
          String homePage = "/App/IUHub/IU.html";
          OLocker wcol = OLocker.new();
          OLocker linksol = OLocker.new();
          Background bg = Background.new();
          Bool runBackground = true;
        }
     }
     
     cohostWith(IUHub:HubPlugin ohp) {
       log.log("in Hub cohostWith");
       runBackground = false;
       ohp.bg.oapp = app;
       ohp.bg.uu.oapp = app;
       bg.oapp = ohp.app;
       bg.uu.oapp = ohp.app;
     }
     
     start() {
      if (Logic:Bools.fromString(app.configManager.get("logs.turnOnAll"))) {
        IO:Logs.turnOnAll();
      }
      log.log("in hubplugin start");
      List acs = app.accountManager.getLogins();
      if (undef(acs) || acs.size < 1) {
        log.log("creating setup account");
        Account ac = Account.new();
        ac.permsString = "admin";
        ac.user = "setup_admin";
        ac.pass = System:Random.getString(64);
        app.accountManager.putAccount(ac);
        app.configManager.put("embeddedLogin", ac.user);
      }
     
      bg.app = app;
      if (undef(bg.oapp)) {
        bg.oapp = app;
        if (undef(bg.uu.oapp)) {
          bg.uu.oapp = app;
        }
      }
      if (runBackground) {
        bg.startBackground();
      }
    }
    
  connectToDeviceRequest(String devId, String devName, request) Map {
    //get one time login token    
    Account a = app.accountManager.getAccountForRequest(request);
    String devSession = app.configManager.get("DeviceSession." + a.user + "!" + devId);
    if (TS.isEmpty(devSession)) {
      return(CallBackUI.getDevCredsResponse(devId, devName));
    } else {
      Map ds = Json:Unmarshaller.unmarshall(devSession);
      if (true) { return(openBrowserFromDeviceSession(ds)) };
    }
    return(null);
  }
  
  onceLoginTokenRequest(Map arg, request) {
    log.log("in oncelogintokenreq");
    Account a = app.accountManager.getAccountForRequest(request);
    String olt = System:Random.getString(64);
    app.configManager.put("OnceToken." + olt, a.user);
    Map res = Map.new();
    res["OnceToken"] = olt;
    return(res);
  }
  
  openBrowserFromDeviceSession(Map ds) Map {
    Map links = self.linksol.o;
    if (def(links)) {
      WebConnect wco = links.get(ds.get("deviceId"));
      WebConnect wc = app.plugin.wcol.o;
      if (def(wc) && def(wco)) {
        String ia = wc.internalAddress;
        String iao = wco.internalAddress;
        String utype = chooseUrlType(wco);
        Map argOut = Map.new();
        argOut["action"] = "onceLoginTokenRequest";
        argOut["pageToken"] = ds["pageToken"];
        argOut["serviceSessionKey"] = ds["serviceSessionKey"];
        Web:Client client = Web:Client.new();
        String payload = Json:Marshaller.marshall(argOut);
        //referer
        //?hosted?
        if (utype == "internal") {
          String destUrl = wco.internalUrl;
        } else {
          destUrl = wco.externalUrl;
        }
        client.outputHeaders.put("referer", destUrl);
        client.url = destUrl;
        try {
          Web:Client:CertificateManager.validateHosts = false;
          //Web:Client:CertificateManager.validateCertificates = false;
          Web:Client:CertificateManager.acceptedThumbprints.put(wco.certificatePrint);
          client.openOutput().write(payload);
          String res = client.openInput().readString();
          client.close();
          if (TS.notEmpty(res)) {
            Map resMap = Json:Unmarshaller.unmarshall(res);
            log.log("!!! got res from obfds  " + res);
            if (resMap.has("OnceToken")) {
              worked = true;
              UI:ExternalBrowser.openToUrl(destUrl + "?onceToken=" + resMap.get("OnceToken"));
            } else {
              worked = false;
            }
          } else {
            Bool worked = false;
          }
          unless (worked) {
            return(CallBackUI.getDevCredsResponse(wco.deviceId, wco.deviceName));
          }
        } finally {
          Web:Client:CertificateManager.validateHosts = true;
          //Web:Client:CertificateManager.validateCertificates = true;
          Web:Client:CertificateManager.acceptedThumbprints.delete(wco.certificatePrint);
        }
      }
    }
    return(null);
  }
  
  deviceLoginRequest(Map arg, request) {
    log.log("in devlogin");
    Account a = app.accountManager.getAccountForRequest(request);
    if (def(a)) {
      Map links = self.linksol.o;
      if (def(links)) {
        WebConnect wco = links.get(arg.get("deviceId"));
      }
      WebConnect wc = app.plugin.wcol.o;
      if (def(wc) && def(wco)) {
        String ia = wc.internalAddress;
        String iao = wco.internalAddress;
        String utype = chooseUrlType(wco);
        log.log("down in wc wco utype is " + utype);
        Map argOut = Map.new();
        argOut["accountName"] = arg["accountName"];
        argOut["accountPass"] = arg["accountPass"];
        argOut["sessionLength"] = arg["sessionLength"];
        argOut["action"] = "loginRequest";
        argOut["serviceLogin"] = "yup";
        Web:Client client = Web:Client.new();
        String payload = Json:Marshaller.marshall(argOut);
        //referer
        if (utype == "internal") {
          client.outputHeaders.put("referer", wco.internalUrl);
          client.url = wco.internalUrl;
        } else {
          //?hosted?
          client.outputHeaders.put("referer", wco.externalUrl);
          client.url = wco.externalUrl;
        }
        try {
          Web:Client:CertificateManager.validateHosts = false;
          //Web:Client:CertificateManager.validateCertificates = false;
          Web:Client:CertificateManager.acceptedThumbprints.put(wco.certificatePrint);
          client.openOutput().write(payload);
          String res = client.openInput().readString();
          log.log("GOT SOMETHING BACK!!!");
          client.close();
          if (TS.notEmpty(res)) {
            Map resMap = Json:Unmarshaller.unmarshall(res);
            //store stuff
            Map ds = Map.new();
            ds["serviceSessionKey"] = resMap["serviceSessionKey"];
            ds["pageToken"] = resMap["pageToken"];
            ds["deviceId"] = arg["deviceId"];
            String dss = Json:Marshaller.marshall(ds);
            app.configManager.put("DeviceSession." + a.user + "!" + arg["deviceId"], dss);
            if (true) { return(openBrowserFromDeviceSession(ds)) };
          }
          log.log("!!! got res from dev loginrequest " + res);
        } finally {
          Web:Client:CertificateManager.validateHosts = true;
          //Web:Client:CertificateManager.validateCertificates = true;
          Web:Client:CertificateManager.acceptedThumbprints.delete(wco.certificatePrint);
        }
        //log.log("got res from dev loginRequest");
      }
    }
  }
  
  saveAccountRequest(Map arg, request) {
    log.log("in hub saveAccountRequest");
    unless (app.requestFromAdmin(request)) {
      throw(Alert.new("Must be administrator"));
    }
    any authPlug = app.pluginsByClassName.get("App:AuthPlugin");
    authPlug.saveAccountRequest(arg, request);
    //if (request.embedded) {
      String anso = app.configManager.get("accountSetOnce");
      if (TS.isEmpty(anso) || anso != "true") {
        if (arg["accountName"] != "setup_admin") {
          Account a = app.accountManager.getAccountForRequest(request);
          if (a.user == "setup_admin") {
            Account b = app.accountManager.getAccount(arg["accountName"]);
            if (def(b) && b.perms.has("admin")) {
              log.log("first account, swapping and setting");
              request.putSession("account.name", b.user);
              app.configManager.put("embeddedLogin", b.user);
              app.configManager.put("accountSetOnce", "true");
              app.accountManager.deleteAccount(a);
              return(CallBackUI.reloadResponse());
            }
          }
        }
      }
    //}
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
      bg.uu.clear(); 
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
  
  loggedIn(Account a, Map res, Map arg, request) {
      res["action"] = "updateResponse";
      res["justLoggedIn"] = true;
      res["permsString"] = a.permsString;
      res["actionLinks"] = getActionLinks(a, arg, request);
      res["devLinksList"] = getDevLinks(a, arg, request);
      res["appVersion"] = self.version;
      res["deviceName"] = self.deviceName;
      res["loginUri"] = self.getLoginUri(request);
      return(res);
    }
    
    versionGet() String {
      fields {
        String version =@ "5.7.0";
      }
      return(version);
    }
    
    updateUrls() {
      log.log("updateLinks");
      String user = app.configManager.get("imap.user");
      String endpoint = app.configManager.get("imap.endpoint");
      String pass = app.configManager.get("imap.pass");
      Map links = Map.new();
      if (TS.notEmpty(user) && TS.notEmpty(endpoint) && TS.notEmpty(pass)) {
        log.log("have imap info");
        any e;
        try {
            String prot = app.configManager.get("imap.protocol");
          if (TS.isEmpty(prot)) {
            prot = "imaps";
          }
          String subf = app.configManager.get("imap.subFolder");
          if (undef(subf)) {
            subf = "IotUrls";
          } elseIf (TS.isEmpty(subf)) {
            subf = null;
          }
          Json:Unmarshaller unmar = Json:Unmarshaller.new();
          //msg += "<p><input type=\"hidden\" value=\"" += Encode:Hex.encode(json) += "\"/></p>\n";
          String subjPref = "DeviceLinks ";
          //List froms = List.new();
          List contents = List.new();
          List devices = List.new();
          emit(jv) {
          """
          Properties props = new Properties();
          props.setProperty("mail.store.protocol", bevl_prot.bems_toJvString());
            Session session = Session.getDefaultInstance(props, null);
            Store store = session.getStore(bevl_prot.bems_toJvString());
            if (!store.isConnected()) {
              store.connect(bevl_endpoint.bems_toJvString(), bevl_user.bems_toJvString(), bevl_pass.bems_toJvString());
            }
            Folder f = store.getFolder("Inbox");
            if (bevl_subf != null) {
              Folder f2 = f.getFolder(bevl_subf.bems_toJvString());
              if (!f2.exists()) {
                f2.create(Folder.HOLDS_MESSAGES);
              }
              f = f2;
            }
            f.open(Folder.READ_WRITE);
            
            if (bevl_subjPref != null) {
            
              String ls = bevl_subjPref.bems_toJvString();
              
              Message[] messages = f.getMessages();
              if (messages != null) {
                for(int i = 0; i < messages.length; i++)
                {
                  String subj = messages[i].getSubject();
                  if (subj != null && subj.startsWith(ls)) {
                    //System.out.println("found message");
                    Message message = messages[i];
                    if (message != null) {
                      /*Address[] adda = message.getFrom();
                      if (adda != null && adda.length > 0) {
                        Address add = adda[0];
                        if (add != null) {
                          //String adds = add.toString();
                          //System.out.println("address " + adds);
                        }
                      }*/
                      Object con = message.getContent();
                      if (con != null) {
                        String mc = con.toString();
                        if (mc != null) {
                          //System.out.println("mc " + mc);
                          bevl_contents.bem_addValue_1(new $class/Text:String$(mc));
                        }
                      }
                    }
                  }
                }
              }            
            }
            
            f.close(true);
            store.close();
          """
          }
          Set dids = Set.new();
          for (String con in contents) {
            //log.log("got con " + con);
            try {
              String beg = "type=\"hidden\" name=\"payload\" value=\"";
              Int d = con.find(beg);
              if (def(d)) {
                con = con.substring(d + beg.size);
                d = con.find("\"");
                if (def(d)) {
                  con = con.substring(0, d);
                  //log.log("final con " + con);
                  String conjs = Encode:Hex.decode(con);
                  log.log("conjs " + conjs);
                  Map lm = unmar.unmarshall(conjs);
                  if (def(lm)) {
                    log.log("putting into links");
                    WebConnect wc = WebConnect.new().fromMap(lm);
                    links.put(wc.deviceId, wc);
                    dids.put(wc.deviceId);
                    app.configManager.put("link." + wc.deviceId, conjs);
                  }
                  //log.log("done with unmar " + lm.get("extAddress"));
                }
              }
            } catch (e) {
             log.log("Exception during imap stuff " );
            }
          }
          bg.app.plugin.linksol.o = links;
          bg.oapp.plugin.linksol.o = links;
          for (any kv in app.configManager.getMap("link.")) {
            String kid = kv.key.substring(5);
            log.log("checking kid " + kid);
            unless (dids.has(kid)) {
              log.log("deleteing " + kv.key);
              app.configManager.delete(kv.key);
            }
          }
          log.log("Done with imap stuff");
      } catch (e) {
        if(def(e)) {
          log.log("Exception during imap stuff ");
        }
      }
    }
  }
    
  updateNetAddresses() {
    log.log("In doimap");
    any e;
    try {
      WebConnect wc = wcol.o;
      if(def(wc)) {
        log.log("In doimap1");
        String prot = app.configManager.get("imap.protocol");
        if (TS.isEmpty(prot)) {
          prot = "imaps";
        }
        String endpoint = app.configManager.get("imap.endpoint");
        String user = app.configManager.get("imap.user");
        String pass = app.configManager.get("imap.pass");
        String subf = app.configManager.get("imap.subFolder");
        if (undef(subf)) {
          subf = "IotUrls";
        } elseIf (TS.isEmpty(subf)) {
          subf = null;
        }
        if (TS.isEmpty(endpoint) || TS.isEmpty(user) || TS.isEmpty(pass)) {
          return(null);
        }
        log.log("In doimap2");
        String msg = "";
        if (TS.notEmpty(wc.hostedLink)) {
          msg += "<p>" + wc.hostedLink += "</p>\n";
        }
        if (TS.notEmpty(wc.externalLink)) {
          msg += "<p>" + wc.externalLink += "</p>\n";
        }
        if (TS.notEmpty(wc.internalLink)) {
          msg += "<p>" += wc.internalLink += "</p>\n";
        }
        if (TS.notEmpty(wc.certificatePrint)) {
          msg += "<p>Certificate Thumbprint: " += wc.certificatePrint += "</p>";
        }
        //if (TS.notEmpty(wc.externalCamLink)) {
        //  msg += "<p>" + wc.externalCamLink += "</p>\n<p>" += //wc.internalCamLink += "</p>\n";
        //}
        String payload = Encode:Hex.new().encode(Json:Marshaller.marshall(wc.toMap()));
        msg += "<input type=\"hidden\" name=\"payload\" value=\"" += payload += "\"/>";
        log.log("In doimap3");
        Pair sl = self.serviceLinks;
        msg += "<p>Service connections for " += self.deviceName += "</p>";
        msg += sl.first;
        msg += sl.second;
        //for (any kv in wc.extraPortMap) {
        //  msg += "<p>External port " += kv.value += " redirected to internal port " += kv.key += "</p>";
        //}
        log.log("In doimap4");
        String subjPref = "DeviceLinks " + self.deviceId + " ";
        String subj = subjPref + Time:Interval.now().seconds + " " + self.deviceName;
        log.log("In doimap5");
        log.log("doing email subj " + subj);
        log.log("doing email msg " + msg);
        log.log("In doimap6");
        emit(jv) {
        """
        Properties props = new Properties();
        props.setProperty("mail.store.protocol", bevl_prot.bems_toJvString());
          Session session = Session.getDefaultInstance(props, null);
          Store store = session.getStore(bevl_prot.bems_toJvString());
          if (!store.isConnected()) {
            store.connect(bevl_endpoint.bems_toJvString(), bevl_user.bems_toJvString(), bevl_pass.bems_toJvString());
          }
          Folder f = store.getFolder("Inbox");
          if (bevl_subf != null) {
            Folder f2 = f.getFolder(bevl_subf.bems_toJvString());
            if (!f2.exists()) {
              f2.create(Folder.HOLDS_MESSAGES);
            }
            f = f2;
          }
          f.open(Folder.READ_WRITE);
          
          MimeMessage m = new MimeMessage(session);
          //m.setFrom(new InternetAddress(from));
          //m.addRecipient(Message.RecipientType.TO, new InternetAddress(to));
       
          String cs = bevl_subj.bems_toJvString();
          
          m.setSubject(cs);
          //m.setText(bevl_msg.bems_toJvString());
          m.setText(bevl_msg.bems_toJvString(), "utf-8", "html");

          
          m.setFlag(Flag.DRAFT, true);
          Message ms[] = {m};
          f.appendMessages(ms);
          
          if (bevl_subjPref != null) {
          
            String ls = bevl_subjPref.bems_toJvString();
            
            Message[] messages = f.getMessages();
            if (messages != null) {
              for(int i = 0; i < messages.length; i++)
              {
                String subj = messages[i].getSubject();
                if (subj != null && subj.startsWith(ls) && !subj.equals(cs)) {
                  //System.out.println("deleting message");
                  messages[i].setFlag(Flag.DELETED, true);
                }
              }
            }            
          }
          
          f.close(true);
          store.close();
        """
        }
        log.log("Done with imap stuff");
      }
    } catch (e) {
      if(def(e)) {
        log.log("Exception during imap update " + e);
      } else {
        log.log("Exception during imap update null");
      }
    }
  }
  
   restartRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        log.log("Restarting as requested, will have exit code 3 by login " + app.accountManager.getAccountForRequest(request).user);
        System:Process.exit(3);
     }
     return(null);
   }
   
   getInternetListenRequest(request) Map {
     //String sshPass = app.configManager.get("il.sshHost", "");
     return(CallBackUI.setElementsValuesResponse(Maps.from("sshHost", app.configManager.get("il.sshHost", ""), "sshLogin", app.configManager.get("il.sshLogin", ""))));
   }
   
   saveInternetListenRequest(String host, String login, String pass, request) Map {
    if (app.requestFromAdmin(request)) {
      //need to remove old if present
      app.configManager.put("il.sshHost", host);
      app.configManager.put("il.sshLogin", login);
      app.configManager.put("il.sshPass", pass);
      String siteNames = app.configManager.get("siteNames");
      if (TS.notEmpty(host)) {
        if (undef(siteNames)) { siteNames = ""; }
        if (siteNames.has("https://" + host)!) {
          if (TS.notEmpty(siteNames)) {
            siteNames += ",";
          }
          siteNames += "https://" += host;
          app.configManager.put("siteNames", siteNames);
        }
      }
    }
    return(null);
   }
   
   checkPublicReadPath(Path pa, request) Bool {
      String pas = pa.toString();
      Path adz = Path.apNew("App/" + self.name).file.absPath;
      if (pas.begins(adz.toString()) && (pas.ends(".html") || pas.ends(".js") || pas.ends(".svg"))) {
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
     if (ref.has("?") && ref.has("&")! && ref.has("?onceToken=")) {
      ref = ref.substring(0, ref.find("?"));
     }
     log.log("okForPageToken second " + ref);
     if (ref == "/App/IUHub/IU.html" || ref == "/App/IUHub/IUCam.html") {
      return(true);
     }
     return(false);
   }
   
   getDeviceNameRequest(request) {
      return(CallBackUI.setElementsValuesResponse(Maps.from("deviceNameDiv", self.deviceName)));
   }
   
   showImapRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      Map res = Map.new();
      res["action"] = "showImapResponse";
      String user = app.configManager.get("imap.user");
      if (TS.notEmpty(user)) {
        res["imapAccount"] = user;
      }
      String ep = app.configManager.get("imap.endpoint");
      if (TS.notEmpty(ep)) {
        res["imapEndpoint"] = ep;
      }
      String sf = app.configManager.get("imap.subFolder");
      if (TS.notEmpty(sf)) {
        res["imapFolder"] = sf;
      } else {
        res["imapFolder"] = "IotUrls";
      }
      return(res);
   }
   
   imapSettingsRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      app.configManager.put("imap.user", arg["imapAccount"]);
      app.configManager.put("imap.endpoint", arg["imapEndpoint"]);
      app.configManager.put("imap.pass", arg["imapPass"]);
      app.configManager.put("imap.subFolder", arg["imapFolder"]);
      String lastImSo = app.configManager.get("imapSetOnce");
      app.configManager.put("imapSetOnce", "true");
      bg.uu.clear();
      if (TS.isEmpty(lastImSo) || lastImSo != "true") {
        return(CallBackUI.reloadResponse());
      }
      Map res = Map.new();
      res["action"] = "hideImapResponse";
      return(res);
   }
   
   runCommandRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
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
   
   restoreConfigRequest(Map arg, request) Map {
     log.log("rs request");
     String path = arg["path"];
     Account a = app.accountManager.getAccountForRequest(request);
     unless (app.requestFromAdmin(request)) {
      throw(Alert.new("must be admin"));
     }
     if (TS.notEmpty(path)) {
       File dirFile = File.apNew(Encode:Hex.new().decode(path));
       any e;
       IO:Reader inr = dirFile.reader.open();
       String res = dirFile.contents;
       Map conf = Json:Unmarshaller.unmarshall(res);
       any ac = app.configManager;
       for (any kv in conf) {
         ac.put(kv.key, kv.value);
       }
     }
     bg.uu.clear();
     return(null);
   }
   
   upgradeRequest(Map arg, request) Map {
     log.log("upgrade request");
     String path = arg["path"];
     Account a = app.accountManager.getAccountForRequest(request);
     unless (app.requestFromAdmin(request)) {
      throw(Alert.new("must be admin"));
     }
     if (TS.notEmpty(path)) {
       Path dpath = Path.apNew("App/IUHub.zip");
       File dirFile = File.apNew(Encode:Hex.new().decode(path));
       any e;
       try {
       app.lock.lock();
       log.log("copying " + dirFile.path + " to " + dpath);
       if (dpath.file.exists) { dpath.file.delete(); }
        IO:Writer outw = dpath.file.writer.open();
        IO:Reader inr = dirFile.reader.open();
        inr.copyData(outw);
        outw.close();
        inr.close();
        app.lock.unlock();
        } catch (e) {
          app.lock.unlock();
        }
        if (System:CurrentPlatform.name == "mswin") {
          String piccmd = "App\\IUHub\\upgrade.bat";
        } else {
          piccmd = "App/IUHub/upgrade.sh";
        }
        try {
        app.lock.lock();
        Time:Sleep.sleepSeconds(1);
        System:Command.new(piccmd).run();
        app.lock.unlock();
        } catch (e) {
			app.lock.unlock();
        }
        try {
        app.lock.lock();
        Time:Sleep.sleepSeconds(10);
        System:Process.exit(4);
        app.lock.unlock();
        } catch (e) {
			app.lock.unlock();
        }
     }
     return(null);
   }
   
   getLoginUri(request) String {
     String loginBookmark = "/App/IUHub/IU.html";
     return(loginBookmark);
   }
   
   
  
  isInternal(request) Bool {
    WebConnect wc = wcol.o;
    Bool internal = false;
    if (request.embedded) {
       internal = true;
     } else {
       internal = onSameNet(request.remoteAddress, wc.internalAddress);
     }
     return(internal);
  }
  
  chooseUrlType(WebConnect wco) String {
    WebConnect wc = app.plugin.wcol.o;
    String ia = wc.internalAddress;
    String iao = wco.internalAddress;
    String certificatePrint = wco.certificatePrint;
    if (def(ia) && def(iao)) {
      Bool internal = onSameNet(ia, iao);
    }
    String ut;
    if (internal) {
      ut = "internal";
    } else {
      ut = "external";
    }
    //Try first choice, if no good try other, if no good try hosted
    //have a "prefer hosted" for the device id option
    //do ping request, return what works
    if (ut == "internal") {
      List tio = Lists.from("internal", "hosted", "external");
    } else {
      tio = Lists.from("external", "hosted", "internal");
    }
    for (String c in tio) {
      log.log("c in tio is " + c);
      if (c == "internal") {
        String utry = wco.internalUrl;
      } elseIf (c == "external") {
        utry = wco.externalUrl;
      } else {
        utry = wco.hostedUrl;
      }
      if (TS.notEmpty(utry)) {
        if (pingUrl(utry, certificatePrint)) {
          log.log("chooseurl ret " + c);
          return(c);
        }
      }
    }
    return(ut);
  }
  
  pingUrl(String destUrl, String print) Bool {
    Bool worked = false;
    Map argOut = Maps.from("action", "pingRequest");
    Web:Client client = Web:Client.new();
    String payload = Json:Marshaller.marshall(argOut);
    client.outputHeaders.put("referer", destUrl);
    client.url = destUrl;
    try {
      Web:Client:CertificateManager.validateHosts = false;
      //Web:Client:CertificateManager.validateCertificates = false;
      Web:Client:CertificateManager.acceptedThumbprints.put(print);
      client.openOutput().write(payload);
      String res = client.openInput().readString();
      client.close();
      if (TS.notEmpty(res)) {
        Map resMap = Json:Unmarshaller.unmarshall(res);
        log.log("!!! got res from pingRequest  " + res);
        if (TS.notEmpty(resMap.get("action")) && resMap["action"] == "pingResponse") {
          worked = true;
        }
      }
    } finally {
      Web:Client:CertificateManager.validateHosts = true;
      //Web:Client:CertificateManager.validateCertificates = true;
      Web:Client:CertificateManager.acceptedThumbprints.delete(print);
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
     Map ecm = app.configManager.getMap("CMD." + a.user + "!");
     for (any kv in ecm) {
      String key = kv.key;
      key = key.substring(key.find("!") + 1, key.size);
      actionLinks += "<p><a href=\"#\" onclick=\"ui.bem_runCommand_1(new be_BEC_2_4_6_TextString().bems_new('" + kv.key + "'));return false;\">" + key + "</a></p>";
     }
     /*String showCam = app.configManager.get("PLUGIN.cam");
     if (TS.isEmpty(showCam) || showCam == "enabled") {
       actionLinks += "<p><a href=\"IUCam.html\">Go to IUCam</a></p>";
     }*/
     //is remote
     //add links
     Bool internal = isInternal(request);
     WebConnect wc = wcol.o;
      Pair sl = self.serviceLinks;
      if (internal) {
        actionLinks += "<div id=\"primaryLinksDiv\" style=\"display: none;\">";
        actionLinks += sl.first;
        actionLinks += "<a href=\"#\" onclick=\"callUI('toggleDisplay', 'secondaryLinksDiv');return false;\">Show external service connections</a>";
        actionLinks += "<div id=\"secondaryLinksDiv\" style=\"display: none;\">";
        actionLinks += sl.second;
        actionLinks += "</div>";
        actionLinks += "</div>";
      } else {
        actionLinks += "<div id=\"primaryLinksDiv\" style=\"display: none;\">";
        actionLinks += sl.second;
        actionLinks += "<a href=\"#\" onclick=\"callUI('toggleDisplay', 'secondaryLinksDiv');return false;\">Show internal service connections</a>";
        actionLinks += "<div id=\"secondaryLinksDiv\" style=\"display: none;\">";
        actionLinks += sl.first;
        actionLinks += "</div>";
        actionLinks += "</div>";
      }
      String cdo = app.configManager.get("camsDetectedOnce");
      if (TS.isEmpty(cdo) || cdo != "true") {
        actionLinks += "<p><a id=\"detectCamsId\" href=\"#\" onclick=\"ui.bem_detectCams_0();return false;\" >Detect WebCams</a></p>";
      }
     return(actionLinks);
   }
   
   serviceLinksGet() Pair {
     WebConnect wc = wcol.o;
      String intsl = String.new();
      String extsl = String.new();
      if (def(wc)) {
        Map svcs = wc.getServices();
        if (def(svcs)) {
          for (any kv in svcs) {
            if (TS.notEmpty(kv.value.get("intLink"))) {
              intsl += "<p>" += kv.value.get("intLink") += "</p>";
            } 
            if (TS.notEmpty(kv.value.get("extLink"))) {
              extsl += "<p>" += kv.value.get("extLink") += "</p>";
            }
            if (TS.notEmpty(kv.value.get("hstLink"))) {
              extsl += "<p>" += kv.value.get("hstLink") += "</p>";
            }
          }
        }
      }
      return(Pair.new(intsl, extsl));
   }
   
   getDevLinks(Account a, Map arg, request) String {
    String devLinks = String.new();
    Json:Unmarshaller unmar = Json:Unmarshaller.new();
    for (any kv in app.plugin.linksol.o) {
      WebConnect wc = kv.value;
      
      if (request.embedded) {
        devLinks += "<p><a href=\"#\" onclick=\"callApp('connectToDeviceRequest', '" += wc.deviceId += "', '" += wc.deviceName += "');return false;\"><img style=\"margin-top:0px; margin-bottom:0px;margin-left:0px;margin-right:0px;\" src=\"web-browser.svg\" alt=\"Device Links\"/>Go to  " += wc.deviceName += "</a></p>";
      } else {
        devLinks += "<p><a href=\"#\" onclick=\"callUI('toggleDevLinks', '" += wc.deviceId += "');callApp('getDevLinksRequest', '" += wc.deviceId += "');return false;\"><img style=\"margin-top:0px; margin-bottom:0px;margin-left:0px;margin-right:0px;\" src=\"web-browser.svg\" alt=\"Device Links\"/>Links for  " += wc.deviceName += "</a></p>";
      }
      
    }
     return(devLinks);
   }
   
   wakeDevRequest(String deviceId, request) {
     Wol wol = Wol.new();
     WebConnect wc = app.plugin.linksol.o.get(deviceId);
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
   
   getDevLinksRequest(String deviceId, request) Map {
     String devLinks = String.new();
     Pair links = Pair.new();
     WebConnect wc = app.plugin.linksol.o.get(deviceId);
     WebConnect mywc = app.plugin.wcol.o;
     if (def(wc)) {
       Bool internal = isInternal(request);
       if (internal) {
        links.first = wc.internalLink;
        links.second = wc.externalLink;
       } else {
        links.second = wc.internalLink;
        links.first = wc.externalLink;
       }
       if (TS.notEmpty(links.first)) {
        devLinks += "<p>" += links.first += " (recommended)</p>";
       }
       if (TS.notEmpty(wc.hostedLink)) {
        devLinks += "<p>" += wc.hostedLink += "</p>";
       }
       if (TS.notEmpty(links.second)) {
        devLinks += "<p>" += links.second += "</p>";
       }
       //check to see if I am on same network as device first
       devLinks += "<p><a href=\"#\" onclick=\"callApp('wakeDevRequest', '" += wc.deviceId += "');return false;\">Wakeup  " += wc.deviceName += "</a></p>";
       if (TS.notEmpty(wc.certificatePrint)) {
         devLinks += "<p>Certificate Thumbprint: " += wc.certificatePrint += "</p>";
       }
    }
     return(CallBackUI.setElementsInnerHTMLResponse(Maps.from("devLinksDiv", devLinks)))
   }
   
   aboutRequest(request) Map {
     String about = "<p>IotUrl Hub Version " + self.version + "<p>";
     return(CallBackUI.setElementsInnerHTMLResponse(Maps.from("aboutDiv", about)))
   }
   
   getForwardPortsListRequest(request) Map {
     String fpl = String.new();
     WebConnect wc = wcol.o;
     for (any kv in wc.getServices()) {
      fpl += "<p><a href=\"#\" onclick=\"callApp('loadForwardPortRequest','" += kv.key += "');return false;\">Load config for " += kv.value.get("name") += "</a></p>";
     }
     return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsInnerHTMLResponse(Maps.from("forwardPortsListDiv", fpl)), CallBackUI.setElementsValuesResponse(Maps.from("fpName", "", "fpPort", "", "fpExPort", "", "fpPattern", "")))));
     
     //return(null);
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
     if (app.requestFromAdmin(request)) {
       WebConnect wc = app.plugin.wcol.o;
       //now fpname and urlpat tied to port
       wc.deleteService(port);
       app.configManager.put("wui.webConnect", Json:Marshaller.marshall(wc.toMap()));
       bg.app.plugin.wcol.o = wc;
       bg.oapp.plugin.wcol.o = wc;
       return(CallBackUI.setElementsDisplaysResponse(Maps.from("forwardPortsDiv", "none")));
       }
       return(null);
   }
   
   updateForwardRequest(String fpName, String port, String exPort, String urlPat, request) Map {
     if (app.requestFromAdmin(request)) {
       WebConnect wc = app.plugin.wcol.o;
       //now fpname and urlpat tied to port
       wc.putService(fpName, port, exPort, urlPat);
       app.configManager.put("wui.webConnect", Json:Marshaller.marshall(wc.toMap()));
       bg.app.plugin.wcol.o = wc;
       bg.oapp.plugin.wcol.o = wc;
       bg.uu.clear();
        return(CallBackUI.setElementsDisplaysResponse(Maps.from("forwardPortsDiv", "none")));
       }
       return(null);
   }
   
   checkAndUpdate() this {
     any e;
     //Web:Client:CertificateManager.validateHosts = true;
     try {
      //get sha, if diff update
      Web:Client client = Web:Client.new();
      client.url = "";
      //String received = client.openInput().readString();
      Web:Client:CertificateManager.validateHosts = false;
     } catch (e) {
      Web:Client:CertificateManager.validateHosts = false;
     }
     
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

use class IUHub:ConfigTest(Assert) {
  
  testConfig() {
    AuthedApp ui = AuthedApp.new();
    KvDb cm = ui.configManager.container;
    cm.delete("test.blarg");
    assertNull(cm.get("test.blarg"));
    cm.insert("test.blarg", "test");
    assertEqual(cm.get("test.blarg"), "test");
    cm.update("test.blarg", "foo");
    assertEqual(cm.get("test.blarg"), "foo");
    assertFalse(cm.testAndPut("test.blarg", "test", "la"));
    assertNotEqual(cm.get("test.blarg"), "la");
    assertTrue(cm.testAndPut("test.blarg", "foo", "la"));
    assertEqual(cm.get("test.blarg"), "la");
  }
  
  main() {
    "Begin ConfigTest".print();
    testConfig();
    "End ConfigTest".print();
  }
  
}

use class IUHub:HubPluginTest(Assert) {
    
  main() {
    "Begin HubPluginTest".print();
    "End HubPluginTest".print();
  }
  
}


use class IUHub:AccountTest(Assert) {
  
  testAccounts() {
    AuthedApp ui = AuthedApp.new();
    Account atest = Account.new();
    atest.user = "test";
    atest.pass = "pass";
    AccountManager am = ui.accountManager;
    am.deleteAccount(atest);
    Account a = am.getAccount(atest.user);
    assertNull(a);
    am.putAccount(atest);
    a = am.getAccount(atest.user);
    assertNotNull(a);
    assertFalse(a.perms.has("admin"));
    assertTrue(a.checkPass("pass"));
    assertFalse(a.checkPass("notpass"));
    a.pass = "yo";
    assertTrue(a.checkPass("yo"));
    a.perms.put("admin");
    am.putAccount(a);
    a = am.getAccount(a.user);
    assertEqual(a.user, "test");
    assertTrue(a.checkPass("yo"));
    //assertTrue(a.perms.has("admin"));
    am.deleteAccount(atest);
  }
  
  main() {
    "Begin AccountTest".print();
    testAccounts();
    "End AccountTest".print();
  }
  
}

