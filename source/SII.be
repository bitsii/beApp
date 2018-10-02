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
      app.pluginsByName.get("Auth").nonAuthedRequests.put("getCredsRequest");
      fwp.startDelay = Time:Interval.new(1, 0);
      fwp.repeatDelay = Time:Interval.new(2, 0);
      fwp.minimumDelay = Time:Interval.new(3, 0);
      //fwp.toInvoke = getInvocation("", List.new());
      //fwp.start();
    }
    
    getCredsRequest(Map arg, request) {
      Map lres = app.pluginsByName.get("Auth").loginRequest(arg, request);
      if (def(lres) && lres.has("action") && lres["action"] == "loggedInResponse") {
        log.log("get creds ok");
        String an = arg["accountName"];
        String ap = arg["accountPass"];
        //log.log("ap " + ap + " an " + an);
        
        String pass = an + ap;
        Digest:SHA256 ds = Digest:SHA256.new();
        for (Int i = 0;i < 2;i++=) {
          pass = ds.digest(pass);
        }
        String passHex = Encode:Hex.encode(pass);
        String pc = passHex.substring(0, 20);
        
        ds = Digest:SHA256.new();
        for (i = 0;i < 2;i++=) {
          pass = ds.digest(pass);
        }
        passHex = Encode:Hex.encode(pass);
        String iv = passHex.substring(0, 20);
        
        Int ivfe = iv.size / 2;
        String ivfirst = iv.substring(0, ivfe);
        String ivsecond = iv.substring(ivfe);
        Int pcfe = pc.size / 2;
        String pcfirst = pc.substring(0, pcfe);
        String pcsecond = pc.substring(pcfe);
        
        //log.log("iv " + iv + " ivfirst " + ivfirst + " ivsecond " + ivsecond);
        //log.log("pc " + pc + " pcfirst " + pcfirst + " pcsecond " + pcsecond);
        
        lres["ivfirst"] = ivfirst;
        lres["pcfirst"] = pcfirst;
        request.putSession("ivsecond", ivsecond);
        request.putSession("pcsecond", pcsecond);
        
        return(lres);
      } else {
        log.log("bad creds");
        return(lres);
      }
    }
    
    saveSecretRequest(String secName, String secAccount, String secPass, String ivFirst, String pcFirst, request) {
      log.log("in ssr");
      auto now = Time:Interval.now();
      auto nowSecs = now.seconds.toString();
      auto nowMillis = now.milliseconds.toString();
      Map mentry = Maps.from("secName", secName, "secAccount", secAccount, "secPass", secPass, "updateSecs", nowSecs, "updateMillis", nowMillis);
      String jsentry = Json:Marshaller.marshall(mentry);
      
      log.log("jsentry " + jsentry);
      
      String ivSecond = request.getSession("ivsecond");
      String pcSecond = request.getSession("pcsecond");
      
      String iv = ivFirst + ivSecond;
      String pc = pcFirst + pcSecond;
      
      String passHash = iv + pc;
      
      Digest:SHA256 ds = Digest:SHA256.new();
      for (Int i = 0;i < 3;i++=) {
        passHash = ds.digest(passHash);
      }
      passHash = Encode:Hex.encode(passHash);
      
      //log.log("iv " + iv + " pc " + pc);
      
      jsentry = Crypt.encryptPassToHex(iv, pc, jsentry);
      
      String subject = "Entry " + nowSecs + " " + nowMillis + " " + secName;
      Map outer = Maps.from("secret", jsentry, "passHash", passHash, "subject", subject);
      
      String outers = Json:Marshaller.marshall(outer);
      
      auto seckv = app.getKvDb("MYPASSES");
      
      seckv.put(secName, outers);
      
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
     if (ref == pref + "/SII.html") {
      return(true);
     }
     return(false);
   }
   
}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;
