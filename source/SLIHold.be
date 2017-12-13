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

use System:Parameters;

use class SLIHold:SLIHoldPlugin(App:AjaxPlugin) {

     new() self {
       fields {
          any app;
          any oapp;
          String name = "SLIHold";
          String homePage = "/App/SLIHold/SLIHold.html";
        }
        super.new();
        log =@ IO:Logs.get(self);
        ifEmit(iuDebug) {
          IO:Logs.turnOnAll();
        }
     }
               
     cohostWith(SLIHold:SLIHoldPlugin ohp) {
       log.log("in Hub cohostWith");
       oapp = ohp.app;
       ohp.oapp = self.app;
     }
     
     appSet(_app) {
      app = _app;
      oapp = _app;
     }
     
     start() {
      if (Logic:Bools.fromString(app.configManager.get("logs.turnOnAll"))) {
        IO:Logs.turnOnAll();
      }
      log.log("in start");
    }
    
    versionGet() String {
      fields {
        String version =@ "5.8.1";
      }
      return(version);
    }
   
   checkPublicReadPath(Path pa, request) Bool {
      String pas = pa.toString();
      Path adz = Path.apNew("App/" + self.name).file.absPath;
      if (pas.begins(adz.toString()) && (pas.ends(".html") || pas.ends(".js") || pas.ends(".svg") || pas.ends(".txt") || pas.ends(".css") || pas.ends(".jpg"))) {
        return(true);
      }
      return(false);
   }
   
   getLoginUri(request) String {
     String loginBookmark = "/App/IUHub/SLIHold.html";
     return(loginBookmark);
   }
   
   handleWeb(request) this {
       String rmtd = request.inputMethod;
       log.log("san rmtd is " + rmtd);
       if (TS.isEmpty(rmtd) || rmtd == "GET") {
         log.log("method is get");
         String uri = request.uri;
         log.log("san uri " + uri);
         if (uri.begins("/App/SLIHold/Something/")) {
           log.log("got something");
           //doSomething(uri, request);
         }
       } else {
         super.handleWeb(request);
       }
  }
  
   secretManagerGet() KvDb {
    //app.getKvDb("LINKS").drop();
    return(app.getKvDb("SECRETS"));
  }
  
  saveSecretRequest(String label, String user, String pass, request) Map {
     log.log("saveSecretRequest called");
     
     Map sec = Maps.from("label", label, "user", user, "pass", pass);
     
     KvDb sm = self.secretManager;
     
     //don't do here, do in js
     //String emailC = Crypt.encryptPassToHex(veriKey, veriKey.substring(8), email);
      //return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsInnerHTMLResponse(Maps.from("sendLinkMessageDiv", "Verification request sent, please check your email.")), CallBackUI.setElementsDisplaysResponse(Maps.from("sendLinkMessageDiv", "block")))));
      
      return(null);
   }
   
}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;

