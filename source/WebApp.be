/*
 * Copyright (c) 2015-2023, the Brace App Authors.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Licensed under the BSD 2-Clause License (the "License").
 * See the LICENSE file in the project root for more information.
 *
 */

import Container:Queue;
import IO:File:Path;
import IO:File;
import System:Random;
import UI:WebBrowser as WeBr;
import Test:Assertions as Assert;
import Db:Relational:Database as DbDb;
import Db:Relational:Statement as DbSt;
import Db:Firebird:Database as FbDb;
import Db:Derby:Database as Derby;
import Db:KeyValue as KvDb;

import App:WebApp;
import App:Account;

import class App:RemoteWebApp(WebApp) {

  new() self {
        fields {
        }
        super.new();
    }
    
    startWeb() {
      dyn e;
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

import System:Thread:Lock;
import System:Thread:ContainerLocker as CLocker;
import System:Command as Com;
import Time:Sleep;
import System:Thread:ObjectLocker as OLocker;
import Db:HSQLDb:Database as HsDb;
