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

use App:Alert;

use App:AuthenticatedLocalApp;
use App:AuthenticatedWebApp;
use App:AuthenticatedApp as AuthedApp;
use IUHub:HubPlugin;
use IUCam:CamPlugin;

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
      BridgePlugin hub = BridgePlugin.new();
      hub.runBackground = bkg;
      CamPlugin cam = CamPlugin.new();
      cam.runBackground = bkg;
      log.log("adding plugins");
      List plugins = List.new();
      plugins += hub;
      plugins += cam;
      plugins += App:AuthPlugin.new();
      plugins += App:ConfigPlugin.new();
      plugins += App:FileManagerPlugin.new();
      return(plugins);
    }
    
    innerMain(List args) {
      //IO:Logs.turnOnAll();
      Web:Client:CertificateManager.validateHosts = false;
      if (args.length > 0) {
        String mode = args[0]; //lui, wui, both, [absent]
        log.log("mode " + mode);
      } else {
        log.log("mode empty");
      }
      if (TS.isEmpty(mode)) {
        mode = "wui";
      }
      if (mode == "lwui" || mode == "lui" || mode == "wui" || mode == "cmd") {
        log.log("making hub");
        if (mode != "cmd") {
          if (mode == "lui" || mode == "lwui") {
            AuthenticatedLocalApp luiapp = AuthenticatedLocalApp.new();
            luiapp.plugins = getPlugins(true);
          }
          if (mode == "wui" || mode == "lwui") {
            AuthenticatedWebApp wuiapp = AuthenticatedWebApp.new();
            wuiapp.plugins = getPlugins(true);
          }  
          if (mode == "lwui") {
            luiapp.cohostWith(wuiapp);
          }
          if (def(wuiapp)) {
            log.log("starting wui");
            wuiapp.main();
          }
          if (def(luiapp)) {
            log.log("starting lui");
            luiapp.main();
          }
        }   
        if (mode == "cmd") {
          cmdMain(args, getPlugins(false));
        }
      }
      if (mode == "test") {
        IUHub:Test.new().main();
      }
    }

    cmdMain(List args, plugins) {
      IO:Logs.turnOnAll();
      AuthedApp ui = AuthedApp.new();
      ui.plugins = getPlugins(false);
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
      if (TS.notEmpty(mode) && mode == "getIntUrl") {
        log.log("getIntUrl");
        ui.plugin.bg.init().uu.doUpdate();
        log.log("int url is " + ui.plugin.wcol.o.internalUrl);
      }
      if (TS.notEmpty(mode) && mode == "saveSetupUrl") {
        log.log("saveSetupUrl");
        String olt = System:Random.getString(64);
        ui.configManager.put("OnceToken." + olt, "setup_admin");
        
        Int intPorti = System:Random.getInt(Int.new(), 6000);
        intPorti += 3000;
        String intPort = intPorti.toString();
        ui.configManager.put("wui.port", intPort);
        
        String iurl = "https://127.0.0.1:" += intPort += "/App/IUHub/IU.html?onceToken=" += olt;
        //log.log("int url is " + iurl);
        File.apNew(args[2]).writer.open().write(iurl).close();
        File.apNew(args[3]).writer.open().write("#!/bin/bash\nx-www-browser " + iurl + "\n").close();
      }
      ui.configManager.close();
    }


}

use System:Thread:ObjectLocker as OLocker;

use Crypto:Symmetric as Crypt;
use class IUBridge:BridgePlugin(HubPlugin) {

    
    loggedIn(Account a, Map res, Map arg, request) {
      res["action"] = "updateResponse";
      res["justLoggedIn"] = true;
      res["permsString"] = a.permsString;
      res["actionLinks"] = getActionLinks(a, arg, request);
      res["devLinksList"] = getDevLinks(a, arg, request);
      res["appVersion"] = self.version;
      res["deviceName"] = self.deviceName;
      res["loginUri"] = self.getLoginUri(request);
      String dnso = app.configManager.get("deviceNameSetOnce");
      if (TS.isEmpty(dnso) || dnso != "true") {
        res["deviceNameSetOnce"] = "false";
      }
      String imso = app.configManager.get("imapSetOnce");
      if (TS.isEmpty(imso) || imso != "true") {
        res["imapSetOnce"] = "false";
      }
      String anso = app.configManager.get("accountSetOnce");
      if (TS.isEmpty(anso) || anso != "true") {
        res["accountSetOnce"] = "false";
      }
      return(res);
    }
   
   getActionLinks(Account a, Map arg, request) String {
     return(self.cam.getActionLinks(a, arg, request) + super.getActionLinks(a, arg, request));
   }
    
    camGet() CamPlugin {
      return(app.plugins[1]);
    }
     
   
}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;
