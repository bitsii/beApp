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
use class IUHub:BigHubStart {

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
      } catch (var e) {
        log.log(lvl, "Exception closing db in CmdUI, error is " + e);
      }*/
    }
    
    outerMain(List args) {
      try {
        innerMain(System:Process.new().args);
      } catch (var e) {
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
        BigHubPlugin hub = BigHubPlugin.new();
        if (mode == "cmd") {
          hub.runBackground = false;
        }
        hub.log = log;
        hub.lvl = lvl;
        CamPlugin cam = CamPlugin.new();
        if (mode == "cmd") {
          cam.runBackground = false;
        }
        cam.log = log;
        cam.lvl = lvl;
        log.log(lvl, "adding plugins");
        List plugins = List.new();
        plugins += hub;
        plugins += cam;
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
        foreach (String login in ui.accountManager.getLogins()) {
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
        foreach (var kv in ui.configManager.getMap()) {
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
      if (TS.notEmpty(mode) && mode == "saveIntUrl") {
        log.log(lvl, "saveIntUrl");
        ui.plugin.bg.init().uu.doUpdate();
        log.log(lvl, "int url is " + ui.plugin.links.o.get("intUrl"));
        File.apNew(args[2]).writer.open().write(ui.plugin.links.o.get("intUrl")).close();
        File.apNew(args[3]).writer.open().write("#!/bin/bash\nx-www-browser " + ui.plugin.links.o.get("intUrl") + "\n").close();
      }
      ui.configManager.close();
    }


}

use System:Thread:ObjectLocker as OLocker;

use Crypto:Symmetric as Crypt;
use class IUHub:BigHubPlugin(HubPlugin) {

    
    loggedIn(Account a, Map res, Map arg, request) {
      res["action"] = "updateResponse";
      res["justLoggedIn"] = true;
      res["permsString"] = a.permsString;
      res["actionLinks"] = getActionLinks(a, arg, request);
      res["appVersion"] = self.version;
      res["deviceName"] = self.deviceName;
      return(res);
    }
    
    getActionLinks(Account a, Map arg, request) String {
     if (TS.notEmpty(arg["plugin"]) && arg["plugin"] == "cam") {
      return(self.cam.getActionLinks(a, arg, request));
     }
     return(super.getActionLinks(a, arg, request));
   }
    
    camGet() CamPlugin {
      return(app.plugins[1]);
    }
     
   
}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;
