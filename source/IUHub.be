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
      Int lvl;
      IO:Log log;
      Int lastPoll = 0;
      Int lastUpdate = 0;
      Int lastFwd = 0;
      Int pollSecs = 1200;//how often to check for ip changes
      Int uupdateSecs = 600;//how often to update upnp fwd
      Int forceUpdate = 3600;//imap force update
      Bool disable = false;
      String webPort;
      String certificateThumbprint; 
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
      log.log(lvl, "deserializing wcs");
      WebConnect wc = WebConnect.new();
      wc.fromMap(Json:Unmarshaller.unmarshall(wcs));
      //log.log(lvl, "after load ext port " + wc.externalPort);
      app.plugin.wcol.o = wc;
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
      log.log(lvl, "loaded link " + wc.deviceName);
    }
    wc = app.plugin.wcol.o;
    if (def(wc)) {
      links.put(wc.deviceId, wc);
    }
    app.plugin.linksol.o = links;
  }
  
  doUpdate() {
    any e;
    log.log(lvl, "In upnp doUpdate");
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
      log.log(lvl, "getting wc");
      loadWc();
      WebConnect wc = app.plugin.wcol.o;
      if (def(wc)) {
        log.log(lvl, "wc from wcol");
      } else {
        log.log(lvl, "new wc");
        wc = WebConnect.new();
        wc.extraPorts = app.configManager.get("upnp.extraPorts");
      }
      log.log(lvl, "after wc init");
      wc.log = log;
      wc.lvl = lvl;
      wc.internalPort = webPort;
      wc.certificatePrint = certificateThumbprint;
      wc.deviceId = app.plugin.deviceId;
      wc.deviceName = app.plugin.deviceName; 
      if (TS.isEmpty(wc.externalPort)) {
        wc.externalPort = app.configManager.get("wui.extPort");
      }
      log.log(lvl, "starting wc update");
      wc.update();
      if (fwd) {
        log.log(lvl, "wc forwarding ports");
        //log.log(lvl, "wc ext port " + wc.externalPort);
        wc.forwardPorts();
      }
      log.log(lvl, "setting links");
      app.plugin.wcol.o = wc;
      log.log(lvl, "updating addresses");
      app.plugin.updateNetAddresses();
      app.plugin.updateUrls();
      log.log(lvl, "saving");
      app.configManager.put("wui.webConnect", Json:Marshaller.marshall(wc.toMap()));
      log.log(lvl, "upnp doUpdate done");
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
      Int lvl;
      IO:Log log;
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
    //log.log(lvl, "Running tasks");
    runMyTasks();
    uu.updateOnInterval();
  }
  
  main() {
    any e;
    while (true) {
      try {
        runTasks();
      } catch (e) {
        log.log(lvl, "Caught exception running tasks " + e);
      }
      try {          
        Time:Sleep.sleepMilliseconds(sleepTime);
      } catch (e) {
        log.log(lvl, "Caught exception sleeping " + e);
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
    uu.lvl = lvl;
    uu.log = log;
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
          IO:Log log = IO:Log.new();
          log.level = log.info;
          Int lvl = log.level;
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
        log.log(lvl, "Exception closing db in CmdUI, error is " + e);
      }*/
    }
    
    outerMain(List args) {
      try {
        innerMain(System:Process.new().args);
      } catch (any e) {
        log.log(lvl, "Exception in CmdUI, error is " + e);
      }
    }
    
    innerMain(List args) {

      Web:Client:CertificateManager.validateHosts = false;

      if (args.length > 0) {
        String mode = args[0]; //ui, svc, both, [absent]
        log.log(lvl, "mode " + mode);
      } else {
        log.log(lvl, "mode empty");
      }
      if (TS.isEmpty(mode)) {
        mode = "wui";
      }
      if (mode == "lui" || mode == "wui" || mode == "cmd") {
        log.log(lvl, "making hub");
        HubPlugin hub = HubPlugin.new();
        if (mode == "cmd") {
          hub.runBackground = false;
        }
        hub.log = log;
        hub.lvl = lvl;
        log.log(lvl, "adding plugins");
        List plugins = List.new();
        plugins += hub;
        plugins += App:AuthPlugin.new();
        plugins += App:ConfigPlugin.new();
        plugins += App:FileManagerPlugin.new();
        if (mode == "lui") {
          AuthenticatedLocalApp.new(plugins, log, lvl).main();
        }
        if (mode == "wui") {
          AuthenticatedWebApp.new(plugins, log, lvl).main();
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
      AuthedApp ui = AuthedApp.new(plugins, log, lvl);
      
      if (args.length > 1) {
        String mode = args[1]; //ui, svc, both, [absent]
        log.log(lvl, "cmd " + mode);
      } 
      if (TS.isEmpty(mode)) {
        log.log(lvl, "cmd empty");
      }
      if (mode == "help") {
        log.log(lvl, "Help");
        log.log(lvl, "listLogins, putAccount, getAccount, setPermsString, setPass, deleteAccount, updateConfig, showConfig, createConfig, deleteConfig");
      }
      if (TS.notEmpty(mode) && mode == "portForward") {
        Net:PortForward pf = Net:PortForward.new(args[2], Int.new(args[3]), args[4], Int.new(args[5]));
        pf.log = log;
        pf.lvl = lvl;
        pf.start();
      }
      if (TS.notEmpty(mode) && mode == "listLogins") {
        for (String login in ui.accountManager.getLogins()) {
          log.log(lvl, "Account login " + login);
        }
      }
      if (TS.notEmpty(mode) && (mode == "putAccount" || mode == "createAccount")) {
        String user = args[2];
        String pass = args[3];
        log.log(lvl, "Putting Account " + user);
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
        log.log(lvl, "Get Account " + user);
        ac = ui.accountManager.getAccount(user);
        log.log(lvl, "Account " + ac);
      }
      if (TS.notEmpty(mode) && mode == "setPermsString") {
        user = args[2];
        String ps = args[3];
        log.log(lvl, "Set Perms " + user);
        ac = ui.accountManager.getAccount(user);
        ac.permsString = ps;
        ui.accountManager.putAccount(ac);
        log.log(lvl, "Account " + ac);
      }
      if (TS.notEmpty(mode) && mode == "setPass") {
        user = args[2];
        pass = args[3];
        log.log(lvl, "Set Pass " + user);
        ac = ui.accountManager.getAccount(user);
        ac.pass = pass;
        ui.accountManager.putAccount(ac);
      }
      if (TS.notEmpty(mode) && mode == "deleteAccount") {
        user = args[2];
        log.log(lvl, "Deleting Account " + user);
        ac = ui.accountManager.getAccount(user);
        if (def(ac)) {
          ui.accountManager.deleteAccount(ac);
          log.log(lvl, "Deleted account " + user);
        } else {
          log.log(lvl, "No such account for deletion " + user);
        }
      }
      if (TS.notEmpty(mode) && mode == "updateConfig") {
        String key = args[2];
        String value = args[3];
        log.log(lvl, "Updating config " + key + " " + value);
        ui.configManager.put(key, value);
      }
      if (TS.notEmpty(mode) && mode == "showConfig") {
        for (any kv in ui.configManager.getMap()) {
          log.log(lvl, "Config name " + kv.key + " value " + kv.value);
        }
      }
      if (TS.notEmpty(mode) && mode == "createConfig") {
        key = args[2];
        value = args[3];
        log.log(lvl, "Creating config " + key + " " + value);
        ui.configManager.put(key, value);
      }
      if (TS.notEmpty(mode) && mode == "deleteConfig") {
        key = args[2];
        log.log(lvl, "Deleting config " + key);
        ui.configManager.delete(key);
      }
      /*if (TS.notEmpty(mode) && mode == "saveIntUrl") {
        log.log(lvl, "saveIntUrl");
        ui.plugin.bg.init().uu.doUpdate();
        log.log(lvl, "int url is " + ui.plugin.links.o.get("intUrl"));
        File.apNew(args[2]).writer.open().write(ui.plugin.links.o.get("intUrl")).close();
        File.apNew(args[3]).writer.open().write("#!/bin/bash\nx-www-browser " + ui.plugin.links.o.get("intUrl") + "\n").close();
      }*/
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
          IO:Log log;
          Int lvl;
          any app;
          String name = "IUHub";
          String homePage = "/App/IUHub/IUHub.html";
          OLocker wcol = OLocker.new();
          OLocker linksol = OLocker.new();
          Background bg = Background.new();
          Bool runBackground = true;
        }
     }
     
     start() {
      bg.log = log;
      bg.lvl = lvl;
      bg.app = app;
      if (runBackground) {
      bg.startBackground();
      }
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
        String version =@ "5.4.9";
      }
      return(version);
    }
    
    updateUrls() {
      log.log(lvl, "updateLinks");
      String user = app.configManager.get("imap.user");
      String endpoint = app.configManager.get("imap.endpoint");
      String pass = app.configManager.get("imap.pass");
      Map links = Map.new();
      if (TS.notEmpty(user) && TS.notEmpty(endpoint) && TS.notEmpty(pass)) {
        log.log(lvl, "have imap info");
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
                    System.out.println("found message");
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
            //log.log(lvl, "got con " + con);
            try {
              String beg = "type=\"hidden\" name=\"payload\" value=\"";
              Int d = con.find(beg);
              if (def(d)) {
                con = con.substring(d + beg.size);
                d = con.find("\"");
                if (def(d)) {
                  con = con.substring(0, d);
                  //log.log(lvl, "final con " + con);
                  String conjs = Encode:Hex.decode(con);
                  log.log(lvl, "conjs " + conjs);
                  Map lm = unmar.unmarshall(conjs);
                  if (def(lm)) {
                    log.log(lvl, "putting into links");
                    WebConnect wc = WebConnect.new().fromMap(lm);
                    links.put(wc.deviceId, wc);
                    dids.put(wc.deviceId);
                    app.configManager.put("link." + wc.deviceId, conjs);
                  }
                  //log.log(lvl, "done with unmar " + lm.get("extAddress"));
                }
              }
            } catch (e) {
             log.log(lvl, "Exception during imap stuff " );
            }
          }
          linksol.o = links;
          for (any kv in app.configManager.getMap("link.")) {
            String kid = kv.key.substring(5);
            log.log(lvl, "checking kid " + kid);
            unless (dids.has(kid)) {
              log.log(lvl, "deleteing " + kv.key);
              app.configManager.delete(kv.key);
            }
          }
          log.log(lvl, "Done with imap stuff");
      } catch (e) {
        if(def(e)) {
          log.log(lvl, "Exception during imap stuff ");
        }
      }
    }
  }
    
  updateNetAddresses() {
    log.log(lvl, "In doimap");
    any e;
    try {
      WebConnect wc = wcol.o;
      if(def(wc)) {
        log.log(lvl, "In doimap1");
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
        log.log(lvl, "In doimap2");
        String msg = "";
        if (TS.notEmpty(wc.externalLink)) {
          msg += "<p>" + wc.externalLink += "</p>\n<p>" += wc.internalLink += "</p>\n";
        }
        //if (TS.notEmpty(wc.externalCamLink)) {
        //  msg += "<p>" + wc.externalCamLink += "</p>\n<p>" += //wc.internalCamLink += "</p>\n";
        //}
        String payload = Encode:Hex.new().encode(Json:Marshaller.marshall(wc.toMap()));
        msg += "<input type=\"hidden\" name=\"payload\" value=\"" += payload += "\"/>";
        log.log(lvl, "In doimap3");
        Pair sl = self.serviceLinks;
        msg += "<p>Service connections for " += self.deviceName += "</p>";
        msg += sl.first;
        msg += sl.second;
        //for (any kv in wc.extraPortMap) {
        //  msg += "<p>External port " += kv.value += " redirected to internal port " += kv.key += "</p>";
        //}
        log.log(lvl, "In doimap4");
        //msg += "<p>Certificate Thumbprint: " += wc.certificatePrint += "</p>";
        String subjPref = "DeviceLinks " + self.deviceId + " ";
        String subj = subjPref + Time:Interval.now().seconds + " " + self.deviceName;
        log.log(lvl, "In doimap5");
        log.log(lvl, "doing email subj " + subj);
        log.log(lvl, "doing email msg " + msg);
        log.log(lvl, "In doimap6");
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
                  System.out.println("deleting message");
                  messages[i].setFlag(Flag.DELETED, true);
                }
              }
            }            
          }
          
          f.close(true);
          store.close();
        """
        }
        log.log(lvl, "Done with imap stuff");
      }
    } catch (e) {
      if(def(e)) {
        log.log(lvl, "Exception during imap update " + e);
      } else {
        log.log(lvl, "Exception during imap update null");
      }
    }
  }
  
   restartRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        log.log(lvl, "Restarting as requested, will have exit code 3 by login " + app.accountManager.getAccountForRequest(request).user);
        System:Process.exit(3);
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
      app.configManager.put("imapSetOnce", "true");
      bg.uu.clear();
      Map res = Map.new();
      res["action"] = "hideImapResponse";
      return(res);
   }
   
   runCommandRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
      String cmdKey = arg["cmdKey"];
      String user = cmdKey.substring(4, cmdKey.find("!"));
      log.log(lvl, "cmd user " + user + " acct user " + a.user);
      unless (user == a.user) {
        log.log(lvl, "Cmd not for user");
        return(null);
      }
      String cmd = app.configManager.get(cmdKey);
      if (TS.notEmpty(cmd)) {
        log.log(lvl, "running command " + cmd);
        System:Command.new(cmd).run();
      }
      return(null);
   }
   
   restoreConfigRequest(Map arg, request) Map {
     log.log(lvl, "rs request");
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
     log.log(lvl, "upgrade request");
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
       log.log(lvl, "copying " + dirFile.path + " to " + dpath);
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
     String loginBookmark = "/App/IUHub/IUHub.html?loginToken=" + request.getSession("loginToken");
     return(loginBookmark);
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
     Bool internal = false;
     WebConnect wc = wcol.o;
     String cp = TS.commonPrefix(request.remoteAddress, wc.internalAddress);
      if (TS.notEmpty(cp)) {
        LinkedList ll = cp.split(".");
        log.log(lvl, " rint dotsplit size " + ll.size + " ra " + request.remoteAddress + " ia " + wc.internalAddress);
        if (ll.size > 2) {
          internal = true;
        }
      }
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
      for (any kv in wc.getServices()) {
        intsl += "<p>" += kv.value.get("intLink") += "</p>";
        extsl += "<p>" += kv.value.get("extLink") += "</p>";
      }
      return(Pair.new(intsl, extsl));
   }
   
   getDevLinks(Account a, Map arg, request) String {
    String devLinks = String.new();
    Json:Unmarshaller unmar = Json:Unmarshaller.new();
    for (any kv in app.plugin.linksol.o) {
      WebConnect wc = kv.value;
      devLinks += "<p><a href=\"#\" onclick=\"callUI('toggleDevLinks', '" += wc.deviceId += "');callApp('getDevLinksRequest', '" += wc.deviceId += "', '');return false;\"><img style=\"margin-top:0px; margin-bottom:0px;margin-left:0px;margin-right:0px;\" src=\"web-browser.svg\" alt=\"Device Links\"/>Links for  " += wc.deviceName += "</a></p>";
    }
     return(devLinks);
   }
   
   wakeDevRequest(String deviceId, request) {
     Wol wol = Wol.new();
     wol.log = log;
     wol.lvl = lvl;
     WebConnect wc = app.plugin.linksol.o.get(deviceId);
     if (def(wc)) {
       log.log(lvl, "waking " + wc.deviceName);
       for (Int i = 0;i < 3;i++=) {
         for (String mac in wc.internalMacAddresses) {
           if (TS.notEmpty(mac)) {
            log.log(lvl, "wake for mac addr " + mac);
            wol.wakeMacAddr(mac);
           }
         }
       }
     }
   }
   
   getDevLinksRequest(String deviceId, String type, request) Map {
     String devLinks = String.new();
     //common prefix with target . and check for size of 3
     //later can use my netmask TODO
     WebConnect wc = app.plugin.linksol.o.get(deviceId);
     WebConnect mywc = app.plugin.wcol.o;
     if (def(wc)) {
       if (TS.isEmpty(type)) {
        type = "ext";
        String cp = TS.commonPrefix(request.remoteAddress, wc.internalAddress);
        if (TS.notEmpty(cp)) {
          LinkedList ll = cp.split(".");
          log.log(lvl, " rint dotsplit size " + ll.size + " ra " + request.remoteAddress + " ia " + wc.internalAddress);
          if (ll.size > 2) {
            type = "int";
          }
        }
        if (request.remoteAddress == "127.0.0.1") {
          type = "int";
        }
        showWake = false;
        cp = TS.commonPrefix(mywc.internalAddress, wc.internalAddress);
        if (TS.notEmpty(cp)) {
          ll = cp.split(".");
          if (ll.size > 2) {
            showWake = true;
          }
        }
       } else {
        Bool showWake = true;
       }
       if (showWake) {
        devLinks += "<p><a href=\"#\" onclick=\"callApp('wakeDevRequest', '" += wc.deviceId += "');return false;\">Wakeup  " += wc.deviceName += "</a></p>";
        }
       if (type == "ext") {
         if (TS.notEmpty(wc.externalLink)) {
          devLinks += wc.externalLink;
          //if (TS.notEmpty(wc.externalCamLink)) {
          //  devLinks += "<p>" += wc.externalCamLink;
          //}
         }
         devLinks += "<p><a href=\"#\" onclick=\"callApp('getDevLinksRequest', '" += wc.deviceId += "', 'int');return false;\">Or get internal links for  " += wc.deviceName += "...</a></p>";
       } else {
         if (TS.notEmpty(wc.internalLink)) {
          devLinks += wc.internalLink;
          //if (TS.notEmpty(wc.internalCamLink)) {
          //  devLinks += "<p>" += wc.internalCamLink;
          //}
         }
         devLinks += "<p><a href=\"#\" onclick=\"callApp('getDevLinksRequest', '" += wc.deviceId += "', 'ext');return false;\">Or get external links for  " += wc.deviceName += "...</a></p>";
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
   }
   
   loadForwardPortRequest(String port, request) Map {
     String fpl = String.new();
     WebConnect wc = wcol.o;
     Map fp = wc.getServices().get(port);
     for (any kv in fp) {
      log.log(lvl, "fp " + kv.key + " " + kv.value);
     }
     log.log(lvl, "urlPat " + fp.get("urlPat"));
    return(CallBackUI.setElementsValuesResponse(Maps.from("fpName", fp.get("name"), "fpPort", port, "fpExPort", wc.extraPortMap.get(port), "fpPattern", fp.get("urlPat"))));
   }
   
   deleteForwardRequest(String port, request) Map {
     if (app.requestFromAdmin(request)) {
       WebConnect wc = app.plugin.wcol.o;
       //now fpname and urlpat tied to port
       wc.deleteService(port);
       app.configManager.put("wui.webConnect", Json:Marshaller.marshall(wc.toMap()));
       app.plugin.wcol.o = wc;
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
       app.plugin.wcol.o = wc;
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

