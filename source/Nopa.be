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

use class Nopa:WebStart {

   new() self {
      fields {
          IO:Log log =@ IO:Logs.get(self);
          Bool ownBackground = false;
        }
        ifEmit(iuOwnBackground) {
          ownBackground = true;
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
    
    getPlugins(Bool bkg) List {
      NopaPlugin nopa = NopaPlugin.new();
      nopa.runBackground = bkg;
      log.log("adding plugins");
      List plugins = List.new();
      plugins += nopa;
      plugins += App:AuthPlugin.new();
      plugins += App:ConfigPlugin.new();
      plugins += Nopa:NoteFilePlugin.new();
      return(plugins);
    }
    
    innerMain(List args) {
      ifEmit(iuDebug) {
        IO:Logs.turnOnAll();
      }
      //Web:Client:CertificateManager.validateHosts = false;
      if (args.length > 0) {
        String mode = args[0]; //lui, wui, both, [absent]
        log.log("mode " + mode);
      } else {
        log.log("mode empty");
      }
      if (TS.isEmpty(mode)) {
        mode = "wui";
      }
      log.log("making nopa");
      if (mode == "wui") {
        AuthenticatedWebApp wuiapp = AuthenticatedWebApp.new();
        wuiapp.plugins = getPlugins(ownBackground);
      }
      if (def(wuiapp)) {
        log.log("starting wui");
        wuiapp.main();
      }
      if (mode == "cmd") {
        log.log("running cmd");
        AuthedApp aapp = AuthedApp.new();
        aapp.plugins = getPlugins(false);
        aapp.cmdMain(args);
      }
    }    
}

use class Nopa:NopaPlugin {

     new() self {
       fields {
          IO:Log log =@ IO:Logs.get(self);
          any app;
          any oapp;
          String name = "Nopa";
          String homePage = "/App/Nopa/Nopa.html";
          App:Background trc = App:Background.new();
          App:Background buu = App:Background.new();
          Bool runBackground = false;
          Lock plock = Lock.new();
        }
     }
          
     appSet(_app) {
      app = _app;
      oapp = _app;
     }
     
     clearTracking() {
      log.log("clearing tracking");
      app.trackingManager.clear();
     }
     
     start() {
      if (Logic:Bools.fromString(app.configManager.get("logs.turnOnAll"))) {
        IO:Logs.turnOnAll();
      }
      log.log("in nopaplugin start");
      List acs = app.accountManager.getLogins();
      if (undef(acs) || acs.size < 1) {
        log.log("creating setup account");
        Account ac = Account.new();
        ac.permsString = "admin";
        ac.user = "setup_admin";
        String sapass = System:Random.getString(32);
        ac.pass = sapass;
        app.accountManager.putAccount(ac);
        app.configManager.put("embeddedLogin", ac.user);
        log.log("setup " + sapass);
      }
     
      trc.repeatDelay = Time:Interval.new(7200, 0);
      trc.minimumDelay = Time:Interval.new(7000, 0);
      trc.toInvoke = getInvocation("clearTracking", List.new());
      
      buu.startDelay = Time:Interval.new(10, 0);
      buu.repeatDelay = Time:Interval.new(600, 0);
      buu.minimumDelay = Time:Interval.new(300, 0);
      buu.toInvoke = getInvocation("doUpdate", List.new());
      if (runBackground) {
        trc.start();
        buu.start();
      }
    }
    
    doUpdate() {
    
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
    log.log("in nopa saveAccountRequest");
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
    return("nopa");
  }
  
  loggedIn(Account a, Map res, Map arg, request) {
      res["action"] = "updateResponse";
      res["profile"] = self.profile;
      res["justLoggedIn"] = true;
      res["permsString"] = a.permsString;
      res["actionLinks"] = getActionLinks(a, arg, request);
      res["appVersion"] = self.version;
      res["deviceName"] = self.deviceName;
      res["loginUri"] = self.getLoginUri(request);
      if (request.embedded) {
        res["embedded"] = true;
      } else {
        res["embedded"] = false;
      }
      res["notesDir"] = app.getHomeDir(request).toString() + "/Notes";
      File nd = File.apNew(res["notesDir"]);
      if (nd.exists!) {
        nd.makeDirs();
      }
      /*
      String imso = app.configManager.get("imapSetOnce");
      if (TS.isEmpty(imso) || imso != "true") {
        res["imapSetOnce"] = "false";
      }
      String anso = app.configManager.get("accountSetOnce");
      if (TS.isEmpty(anso) || anso != "true") {
        res["accountSetOnce"] = "false";
      }      
      String dnso = app.configManager.get("deviceNameSetOnce");
      if (TS.isEmpty(dnso) || dnso != "true") {
        res["deviceNameSetOnce"] = "false";
      }
      */
      
      return(res);
    }
    
    versionGet() String {
      fields {
        String version =@ "3.0.0";
      }
      return(version);
    }
    
   restartRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        log.log("Restarting as requested, will have exit code 3 by login " + app.accountManager.getAccountForRequest(request).user);
        System:Process.exit(3);
     }
     return(null);
   }
   
   checkPublicReadPath(Path pa, request) Bool {
      String pas = pa.toString();
      Path adz = Path.apNew("App/" + self.name).file.absPath;
      if (pas.begins(adz.toString()) && (pas.ends(".html") || pas.ends(".js") || pas.ends(".svg") || pas.ends(".txt"))) {
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
     if (ref == "/App/Nopa/Nopa.html") {
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
      
      //if (TS.isEmpty(lastImSo) || lastImSo != "true") {
      //  return(CallBackUI.reloadResponse());
      //}
      
      //app.plugin.updateUrls();
      System:Thread.new(app.plugin.getInvocation("updateUrls", List.new())).start();
      
      Map res = Map.new();
      res["action"] = "hideImapResponse";
      return(res);
   }
   
   getLoginUri(request) String {
     String loginBookmark = "/App/Nopa/Nopa.html";
     return(loginBookmark);
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
   
  updateActionLinks(String actionLinks, Account a, Map arg, request) String {
     return(actionLinks);
   }
   
   aboutRequest(request) Map {
     String about = "<p>Note Passer, Version " + self.version + "<p>";
     return(CallBackUI.setElementsInnerHTMLResponse(Maps.from("aboutDivMsg", about)))
   }
   
}

use class Nopa:NoteFilePlugin(App:FileManagerPlugin) {

  createNoteRequest(Map arg, request) Map {
     log.log("createnote request");
     String inDir = arg["inDir"];
     String noteName = arg["noteName"] + ".note";
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
     if (TS.notEmpty(inDir) && TS.notEmpty(noteName)) {
       Path dirPath = Path.apNew(Encode:Hex.new().decode(inDir));
       dirPath.addStep(noteName);
       File dirFile = dirPath.file.absPath.file;
       if (dirFile.exists! && app.checkWritePath(dirFile.path, arg, request)) {
         log.log("creating " + dirFile.path);
         dirFile.makeFile();
       }
     }
     arg["path"] = arg["inDir"];
     return(localBrowseRequest(arg, request));
   }
   
   openNoteRequest(Map arg, request) Map {
     log.log("openNote request");
     String inDir = arg["inDir"];
     String noteName = arg["noteName"] + ".note";
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
     if (TS.notEmpty(inDir) && TS.notEmpty(noteName)) {
       Path dirPath = Path.apNew(Encode:Hex.new().decode(inDir));
       dirPath.addStep(noteName);
       File dirFile = dirPath.file.absPath.file;
       if (dirFile.exists && app.checkReadPath(dirFile.path, arg, request)) {
         log.log("opening " + dirFile.path);
       }
     }
     arg["path"] = arg["inDir"];
     return(null);
   }
   
   getBaseLink(request) String {
     return("");
   }
   
   jscallForPath(Path p) {
    if (p.toString().ends(".note")) {
      String jscall = " onclick=\"callUI('openNote','" += Encode:Hex.encode(p.toString()) += "');return false;\"";
    } else {
      jscall = super.jscallForPath(p);
    }
    return(jscall);
   }
   
}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;
