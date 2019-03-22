// Copyright 2015 Craig Welch
//
// Licensed under the MIT license. See LICENSE.txt file in the project root 
// for full license information.

use Container:Queue;
use IO:File:Path;
use IO:File;
use System:Random;
use UI:WebBrowser as WeBr;
use Test:Assertions as Assert;
use Db:Relational:Database as DbDb;
use Db:Relational:Statement as DbSt;
use Db:Firebird:Database as FbDb;
use Db:Derby:Database as Derby;
use Db:KeyValue as KvDb;

use App:WebApp;
use App:Account;

use class App:RemoteWebApp(WebApp) {

  new() self {
        fields {
        }
        super.new();
    }
    
    startWeb() {
      any e;
      String ports = self.appPort;
      Int port = Int.new(ports);
      //portL.o = port;
      
      Web:Server vw = Web:Server.new(self.sessionManager);
      
      //vwL.o = vw;
      vw.port = port;
      vw.ssl = self.appSsl;
      //("appSsl = " + vw.ssl).print();
      if(TS.notEmpty(self.appBindAddress)) {
        vw.appBindAddress = self.appBindAddress;
        log.log("set appBindAddress " + vw.appBindAddress);
      }
      vw.app = self;
      vw.gzipOutput = true;
      ifEmit(cs) {
        vw.gzipOutput = false;
      }
      fields {
        System:Thread myThread;
      }
      log.log("Starting Web");
      ifEmit(jv) {
        myThread = System:Thread.new(vw);
        myThread.start();
      }
      ifEmit(cs) {
        vw.main();
      }
    }
  
  handleStartWeb() {
    log.log("In handleStartWeb!!");
  }
    main() {
      List args = System:Process.new().args;
      start();
      startWeb();
   }

   initWeb() {

   }
   
   handleWeb(request) this {
     //log.log("in hw");
     super.handleWeb(request);
   }

}

use System:Thread:Lock;
use System:Thread:ContainerLocker as CLocker;
use System:Command as Com;
use Time:Sleep;
use System:Thread:ObjectLocker as OLocker;
use Db:HSQLDb:Database as HsDb;
