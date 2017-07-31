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

use IUHub:HubPlugin;

use class IUHub:HubWebStart {

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
      HubPlugin hub = HubPlugin.new();
      hub.runBackground = bkg;
      IUDoer:DoerPlugin doer = IUDoer:DoerPlugin.new();
      log.log("adding plugins");
      List plugins = List.new();
      plugins += hub;
      plugins += App:AuthPlugin.new();
      plugins += App:ConfigPlugin.new();
      plugins += App:FileManagerPlugin.new();
      plugins += doer;
      return(plugins);
    }
    
    innerMain(List args) {
      ifEmit(iuDebug) {
        IO:Logs.turnOnAll();
      }
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
      if (mode == "wui") {
        log.log("making hub");
        if (mode == "wui") {
          AuthenticatedWebApp wuiapp = AuthenticatedWebApp.new();
          wuiapp.plugins = getPlugins(ownBackground);
        }
        if (def(wuiapp)) {
          log.log("starting wui");
          wuiapp.main();
        }
      }
    }    
}
