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

emit(jv) {
"""
//import java.io.*;
//import java.net.*;
"""
}

use class RLBeacon:Background {

  new() self {
    fields {
      any app;
      Int lvl;
      IO:Log log;
    }
  }
  
  runMyTasks() {
    fields {
      Int lastTrackClear;
      Int clearSeconds =@ 7200;
      
      Int lastHubUpdate;
      Int hubUpdateSeconds =@ 7200;
    }
    Pair tickres = tick(lastTrackClear, clearSeconds);
    lastTrackClear = tickres.second;
    if (tickres.first) {
      app.trackingManager.clear();
    }
    tickres = tick(lastHubUpdate, hubUpdateSeconds);
    lastHubUpdate = tickres.second;
    if (tickres.first) {
      //update wc
    }
  }
  
  tick(Int last, Int period) Pair {
    if (undef(last)) {
      last = 0;
    }
    Int ns = Time:Interval.now().seconds;
    if (ns - last > period) {
      return(Pair.new(true, ns));
    }
    return(Pair.new(false, last));
  }
  
  runTasks() {
    //log.log(lvl, "Running tasks");
    runMyTasks();
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
  
  startBackground() {
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
    myThread = System:Thread.new(self);
    myThread.start();
  }

}

use App:AuthenticatedLocalApp;
use App:AuthenticatedWebApp;
use App:AuthenticatedApp as AuthedApp;

use class RLBeacon:SiteStart {

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
        log.log(lvl, "making cam");
        CamPlugin cam = CamPlugin.new();
        if (mode == "cmd") {
          cam.runBackground = false;
        }
        cam.log = log;
        cam.lvl = lvl;
        log.log(lvl, "adding plugins");
        List plugins = List.new();
        plugins += cam;
        plugins += App:AuthPlugin.new();
        plugins += App:ConfigPlugin.new();
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
      ui.configManager.close();
    }

}

use System:Thread:ObjectLocker as OLocker;

use Crypto:Symmetric as Crypt;
use class RLBeacon:CamPlugin {

     new() self {
       fields {
          IO:Log log = IO:Log.new();
          log.level = log.info;
          Int lvl = log.level;
          any app;
          String name = "RLBeacon";
          String homePage = "/App/RLBeacon/RLBeacon.html";
          Background bg = Background.new();
          Bool runBackground = true;
          OLocker links = OLocker.new();
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
      res["appVersion"] = self.version;
      res["deviceName"] = self.deviceName;
      return(res);
    }
    
    versionGet() String {
      fields {
        String version =@ "5.4.7";
      }
      return(version);
    }
    
    checkPublicReadPath(Path pa, request) Bool {
      String pas = pa.toString();
      Path adz = Path.apNew("App/" + self.name).file.absPath;
      if (pas.begins(adz.toString()) && (pas.ends(".html") || pas.ends(".js"))) {
        return(true);
      }
      return(false);
   }
   
   getActionLinks(Account a, Map arg, request) String {
     String actionLinks = String.new();
     return(actionLinks);
   }
   
   addLinkRequest(String token, request) {
      //check num beacons TODO
      log.log(lvl, "add link");
      log.log(lvl, "token " + token);
      Account a = app.accountManager.getAccountForRequest(request);
      if (def(a) && TS.notEmpty(token)) {
          //wc to/from token
          Map tok = Json:Unmarshaller.unmarshall(token);
          //this is "direct" (name or ip based, name extra element), later will check against svc for updates to url (?not cert?)
          
          app.configManager.put("link!" + a.user + "!" + tok.get("deviceId") + "!" + tok.get("linkName"), token);
          
          //iu call update hub for link, sends it all over (addr, mac, etc - ?wc?)
          //send json of connection and of content, get back json of content back
          //also on bkgrnd schedule
          
        }
        return(null);
   }
   
}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;

