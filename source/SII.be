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
use Net:UPnP as Upnp;
use Net:IP;

use EWC:NetMaker;

use class SII:SIIPlugin(App:AjaxPlugin) {

     new() self {
       fields {
          String homePage = "/App/" + self.name + "/SII.html";
          OLocker wcol = OLocker.new();
          Lock wcl = Lock.new();
          any app;
          App:Background fwp = App:Background.new();
        }
        super.new();
        log =@ IO:Logs.get(self);
        //ifEmit(appDebug) {
          IO:Logs.turnOnAll();
        //}
        Web:Client:CertificateManager.validateHosts = false;
     }
     
     start() {
      if (Logic:Bools.fromString(app.configManager.get("logs.turnOnAll"))) {
        IO:Logs.turnOnAll();
      }
      log.log("in ews start");
      fwp.startDelay = Time:Interval.new(1, 0);
      fwp.repeatDelay = Time:Interval.new(2, 0);
      fwp.minimumDelay = Time:Interval.new(3, 0);
      //fwp.toInvoke = getInvocation("", List.new());
      //fwp.start();
    }
    
    saveSecretRequest(String secName, String secAccount, String secPass, , String credName, String credPass, request) {
      log.log("in ssr");
      auto now = Time:Interval.now();
      auto nowSecs = now.seconds.toString();
      auto nowMillis = now.milliseconds.toString();
      Map mentry = Maps.from("secName", secName, "secAccount", secAccount, "secPass", secPass, "updateSecs", nowSecs, "updateMillis", nowMillis);
      String jsentry = Json:Marshaller.marshall(mentry);
      
      log.log("jsentry " + jsentry);
      
      //username and password (name is for salt)
      //  when not known prompt
      //  re-encrypt all option
      //  keep last N in history
      //  offline backup option, only works locally, in case of verybad (maybe  
      //  only need this), recovers last
      
      //auto seckv = app.getKvDb("MYPASSES");
      
      
      return(CallBackUI.informResponse("Secret Saved"));
    }
     
     nameGet() String {
       String name =@ "SII";
       return(name);
     }
     
     handleCmd(Parameters params) Bool {
      String mode = params.getFirst("ewsCmd");
      if (TS.isEmpty(mode)) {
        return(false);
      }
      return(true);
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
      if (pas.begins(adz.toString()) && (pas.ends(".html") || pas.ends(".js") || pas.ends(".svg") || pas.ends(".txt") || pas.ends(".css"))) {
        return(true);
      }
      return(false);
   }
   
   getLoginUri(request) String {
     String loginBookmark = "/App/" + self.name + "/SII.html";
     return(loginBookmark);
   }
   
  resetCertMan(String certPrint) {
    Web:Client:CertificateManager.validateHosts = true;
    Web:Client:CertificateManager.acceptedThumbprints.delete(certPrint);
  }
  
   aboutRequest(request) Map {
     String about = "<p>Edgii WifiSender Version " + self.version + "<p>";
     return(CallBackUI.setElementsInnerHTMLResponse(Maps.from("aboutDivMsg", about)))
   }
   
}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;
