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
        //ifEmit(iuDebug) {
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
      if (mode == "assurePorts") {
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
          intPort = app.configManager.get("web.port");
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
    for (any kv in app.configManager.getMap(key)) {
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
    log.log("starting wc update");
    //fwd was here
    log.log("setting links");
    wc.updateInternal(homePage);
    app.plugin.wcol.o = wc;
    oapp.plugin.wcol.o = wc;
    log.log("updating addresses");
    //app.plugin.updateNetAddresses();
    app.plugin.updateUrls();
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
      trc.toInvoke = getInvocation("clearTracking", List.new());
      
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
          
          emit(cs) {
          """
          var client = new ImapClient();
          // accept all SSL certificates (TODO comment and try)
          client.ServerCertificateValidationCallback = (s,c,h,e) => true;
          client.Connect(bevl_endpoint.bems_toCsString(), 993, true);
          client.AuthenticationMechanisms.Remove ("XOAUTH2");
          client.Authenticate (bevl_user.bems_toCsString(), bevl_pass.bems_toCsString());
          var inbox = client.Inbox;
          if (bevl_subf != null) {
            var subfcs = bevl_subf.bems_toCsString();
            foreach (var folder in inbox.GetSubfolders (false)) {
              if (folder.Name == subfcs) {
                inbox = folder;
              }
            }
          }
          inbox.Open (FolderAccess.ReadOnly);
          for (int i = 0; i < inbox.Count; i++) {
            var message = inbox.GetMessage (i);
            var mc = message.HtmlBody;
            //Console.WriteLine ("Subject: {0}", message.Subject);
            bevl_contents.bem_addValue_1(new $class/Text:String$(mc));
          }
          //Console.WriteLine ("Total messages: {0}", inbox.Count);
          //Console.WriteLine ("Recent messages: {0}", inbox.Recent);
          client.Disconnect (true);
          """
          }
          
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
          //app.plugin.linksol.o = links;
          //oapp.plugin.linksol.o = links;
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
      
      //app.plugin.updateUrls();
      System:Thread.new(app.plugin.getInvocation("updateUrls", List.new())).start();
      
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
  
  getEadns(Map accountLinks) Map {
    log.log("getting eadns");
    Map eadn = Map.new();
    /*for (auto kv in accountLinks) {
       WebConnect wc = kv.value;
       if (def(wc)) {
         if (def(wc.doingDns) && wc.doingDns && TS.notEmpty(wc.externalAddress) && TS.notEmpty(wc.gateway)) {
          log.log("got an eadn");
          eadn.put(wc.externalAddress, wc);
         }
       }
    }*/
    return(eadn);
    
    //if (TS.notEmpty(wc.gateway) && TS.notEmpty(mywc.gateway) && TS.notEmpty(wc.externalAddress) && //TS.notEmpty(mywc.externalAddress) && wc.gateway == mywc.gateway && wc.externalAddress == mywc.externalAddress) {}
  }
   
  getDevLinks(Account a, Map arg, request) String {
    String outerLinks = String.new();
    String devLinks = String.new();
     Map accountLinks = getLinks(a);
     if (accountLinks.isEmpty) {
       outerLinks += "<p>No device links found.";
     }
     outerLinks += "<p>Use Link to Edgii on device to add it to your Edgii account.";
     Map eadns = getEadns(accountLinks);
     for (auto kv in accountLinks) {
       Pair links = Pair.new();
       WebConnect wc = kv.value;
       if (def(wc)) {
         Bool internal = fromSameNet(wc, request);
         //TODO check by pinging links also, possibly in background at login (or from time to time)
         //remember which last worked, only do occasionally, async, with a refresh
         //specifically just to filter out external
         if (internal) {
          links.first = wc.internalLink;
          links.second = wc.externalLink;
         } else {
          links.second = wc.internalLink;
          links.first = wc.externalLink;
         }
         //add way for bridge to say it is handling dns
         //ahead of time find any of those, for any device here
         //check to see if it has same internet address as something that
         //says it's handling dns
         
         if (TS.notEmpty(wc.externalAddress)) {
          WebConnect dnwc = eadns.get(wc.externalAddress);
         } else {
          dnwc = null;
         }
         if (def(dnwc) && TS.notEmpty(wc.gateway) && dnwc.gateway == wc.gateway) {
           dlUse = devLinks;
           outerLinks += "<p>" += wc.konnLink += "</p>";
         } elseIf (wc.manualForward || (TS.notEmpty(wc.konnLink) && TS.notEmpty(wc.hostedLink))) {
           String dlUse = devLinks;
           outerLinks += "<p>" += wc.konnLink += "</p>";
         } else {
           dlUse = outerLinks;
           if (TS.notEmpty(links.first)) {
             outerLinks += "<p>" += links.first += "</p>";
           }
         }
         if (TS.notEmpty(wc.konnLink)) {
           dlUse += "<p>" += wc.konnLink += "</p>";
         }
         if (TS.notEmpty(wc.hostedLink)) {
          dlUse += "<p>" += wc.hostedLink += "</p>";
         }
         if (TS.notEmpty(links.first)) {
          devLinks += "<p>" += links.first += "</p>";
         }
         if (TS.notEmpty(links.second)) {
          dlUse += "<p>" += links.second += "</p>";
         }
         if (undef(a)) {
           devLinks += "<p><a href=\"#\" onclick=\"callApp('wakeDevRequest', '" + wc.deviceId + "');return false;\">Wakeup " += wc.deviceName += "</a> - using Wake on Lan</p>";
         }
         if (TS.notEmpty(wc.certificatePrint)) {
           devLinks += "<p>Certificate Thumbprint for " += wc.deviceName += ": " += wc.certificatePrint += "</p>";
         }
      }
    }
    String actionLinks = String.new();
    actionLinks += "<div id=\"outerLinksDiv\">";
    actionLinks += outerLinks;
    if (TS.notEmpty(devLinks)) {
    actionLinks += "<a href=\"#\" onclick=\"callUI('toggleDisplay', 'innerLinksDiv');return false;\">Show/Hide more connection options.</a>";
    actionLinks += "<div id=\"innerLinksDiv\" style=\"display: none;\">";
    actionLinks += devLinks;
    actionLinks += "</div>";
    }
    return(actionLinks);
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
        Map svcs = wc.getServices();
        if (def(svcs)) {
        
             log.log("checking eadns in svcs");
           Map accountLinks = getLinks(null);
          Map eadns = getEadns(accountLinks);
          for (any kv in svcs) {
            if (TS.notEmpty(wc.externalAddress)) {
              WebConnect dnwc = eadns.get(wc.externalAddress);
             } else {
              dnwc = null;
             }
             if (def(dnwc) && TS.notEmpty(wc.gateway) && dnwc.gateway == wc.gateway) {
               log.log("doing dnwc");
               dlUse = innerLinks;
              outerLinks += "<p>" += kv.value.get("konnLink") += "</p>";
             }
            elseIf (wc.manualForward || (TS.notEmpty(kv.value.get("hstLink")) && TS.notEmpty(kv.value.get("konnLink")))) {
              String dlUse = innerLinks;
              if (TS.notEmpty(kv.value.get("konnLink"))) {
                outerLinks += "<p>" += kv.value.get("konnLink") += "</p>";
              }
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

