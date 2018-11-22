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
      app.pluginsByName.get("Auth").nonAuthedRequests.put("checkAccountsRequest");
      app.pluginsByName.get("Auth").nonAuthedRequests.put("createCredsRequest");
      fwp.startDelay = Time:Interval.new(1, 0);
      fwp.repeatDelay = Time:Interval.new(2, 0);
      fwp.minimumDelay = Time:Interval.new(3, 0);
      //fwp.toInvoke = getInvocation("", List.new());
      //fwp.start();
    }
    
    checkAccountsRequest(request) {
      if (app.pluginsByName.get("Auth").accountManager.getLogins().size < 1) {
        return(CallBackUI.toCreateAccountResponse());
      }
      return(null);
    }
    
    createCredsRequest(String user, String pass, request) {
      if (app.pluginsByName.get("Auth").accountManager.getLogins().size < 1) {
        Account ac = Account.new();
        ac.user = user;
        ac.pass = pass;
        app.pluginsByName.get("Auth").accountManager.putAccount(ac);
        
        Map arg = Map.new();
        arg["action"] = "getCredsRequest";
        arg["accountName"] = user;
        arg["accountPass"] = pass;
        arg["sessionName"] = "";
        arg["sessionLength"] = "60";
        return(getCredsRequest(arg, request));
      }
      return(null);
    }
    
    genCreds(String an, String ap) {
      
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
      
      
      return(Maps.from("iv", iv, "pc", pc, "ivFirst", ivfirst, "pcFirst", pcfirst, "ivSecond", ivsecond, "pcSecond", pcsecond));
    }
    
    getCredsRequest(Map arg, request) {
      Map lres = app.pluginsByName.get("Auth").loginRequest(arg, request);
      if (def(lres) && lres.has("action") && lres["action"] == "loggedInResponse") {
        log.log("get creds ok");
        String an = arg["accountName"];
        String ap = arg["accountPass"];
        
        Map cr = genCreds(an, ap);
        
        lres["ivfirst"] = cr["ivFirst"];
        lres["pcfirst"] = cr["pcFirst"];
        request.putSession("ivsecond", cr["ivSecond"]);
        request.putSession("pcsecond", cr["pcSecond"]);
        
        getList(arg, lres);
        
        return(lres);
      } else {
        log.log("bad creds");
        return(lres);
      }
    }
    
    getList(Map arg, Map lres) {
      String an = arg["accountName"];
      List titles = List.new();
      for (auto kv in app.getKvDb("MYPASSES").getMap(an + "!")) {
        titles += kv.key.split("!").get(1);
      }
      lres["titles"] = titles;
    }
    
    openSecret(String secName, Map creds, Account a) {
      auto seckv = app.getKvDb("MYPASSES");
      
      String outers = seckv.get(a.user + "!" + secName);
      
      if (TS.isEmpty(outers)) {
        throw(Alert.new("Entry not found"));
      }
      Map outer = Json:Unmarshaller.unmarshall(outers);
      
      if (outer["passHash"] != creds["ph"]) {
        throw(Alert.new("Incorrect Password"));
      }
      
      String jsentry = Crypt.decryptPassFromHex(creds["iv"], creds["pc"], outer["secret"]);
      
      Map mentry = Json:Unmarshaller.unmarshall(jsentry);
      return(mentry);
    }
    
    altPassRequest(String secName, String ivFirst, String pcFirst, String altAccount, String altPass, request) {
      log.log("in altPassReq " + secName + " " + altAccount + " " + altPass);
      
      Account a = request.context.get("account");
      Map nc = genCreds(altAccount, altPass);
      Map cr = getCreds(nc["ivFirst"], nc["pcFirst"], nc["ivSecond"], nc["pcSecond"]);
      
      Map sec = openSecret(secName, cr, a);
      Map newCreds = getCreds(ivFirst, pcFirst, request);
      saveSecret(sec["secName"], sec["secAccount"], sec["secPass"], newCreds, a);
      
      return(CallBackUI.informResponse("Entry updated, click <a href=\"#\" onclick=\"callUI('hideInform');callUI('toFind');return false;\">Find</a> to continue"));
    }
    
    openSecretRequest(String secName, String ivFirst, String pcFirst, request) {
      
      //if (true) { return(CallBackUI.openAltPassResponse(secName)); }
      
      if (TS.isEmpty(secName)) {
        return(CallBackUI.informResponse("Title is Requred"));
      }
      Account a = request.context.get("account");
      Map creds = getCreds(ivFirst, pcFirst, request);
      
      try {
        Map mentry = openSecret(secName, creds, a);
      } catch (any e) {
        if (def(e) && e.description.has("Incorrect")) {
          return(CallBackUI.openAltPassResponse(secName));
        }
      }
      
      return(CallBackUI.openSecretResponse(mentry));
      
    }
    
    getCreds(String ivFirst, String pcFirst, request) Map {
      String ivSecond = request.getSession("ivsecond");
      String pcSecond = request.getSession("pcsecond");
      return(getCreds(ivFirst, pcFirst, ivSecond, pcSecond));
    }
    
    getCreds(String ivFirst, String pcFirst, String ivSecond, String pcSecond) Map {
      
      String iv = ivFirst + ivSecond;
      String pc = pcFirst + pcSecond;
      
      String passHash = iv + pc;
      
      Digest:SHA256 ds = Digest:SHA256.new();
      for (Int i = 0;i < 3;i++=) {
        passHash = ds.digest(passHash);
      }
      passHash = Encode:Hex.encode(passHash);
      return(Maps.from("iv", iv, "pc", pc, "ph", passHash));
    }
    
    deleteSecretRequest(String secName, request) {
    
      if (TS.isEmpty(secName)) {
        return(CallBackUI.informResponse("Title is Requred"));
      }
      Account a = request.context.get("account");
      auto seckv = app.getKvDb("MYPASSES");
      seckv.delete(a.user + "!" + secName);
      Map lres = Map.new();
      lres["action"] = "relistSecretsResponse";
      lres["accountName"] = a.user;
      getList(lres, lres);
      return(lres);
    }
    
    changeCredsRequest(Map arg, request) {
      
      Map oldCreds = getCreds(arg["ivFirst"], arg["pcFirst"], request.getSession("ivsecond"), request.getSession("pcsecond"));
      
      //excepts on fail
      app.pluginsByName.get("Auth").changePassRequest(arg, request);
      
      String newpass = arg["newPass"];
      Account a = request.context.get("account");
      
      Map lr = Maps.from("accountName", a.user, "accountPass", newpass);
      Map toRet = getCredsRequest(lr, request);
      
      Map newCreds = getCreds(toRet["ivfirst"], toRet["pcfirst"], request.getSession("ivsecond"), request.getSession("pcsecond"));
      
      for (auto kv in app.getKvDb("MYPASSES").getMap(a.user + "!")) {
        String title = kv.key.split("!").get(1);
        try {
          Map sec = openSecret(title, oldCreds, a);
          saveSecret(sec["secName"], sec["secAccount"], sec["secPass"], newCreds, a);
        } catch (any e) {
          log.log("open /save failed during change, probly wrong password");
        }
      }
      
      return(toRet);
   }
   
   saveSecret(String secName, String secAccount, String secPass, Map creds, Account a) {
    auto now = Time:Interval.now();
    auto nowSecs = now.seconds.toString();
    auto nowMillis = now.milliseconds.toString();
    Map mentry = Maps.from("secName", secName, "secAccount", secAccount, "secPass", secPass, "updateSecs", nowSecs, "updateMillis", nowMillis);
    String jsentry = Json:Marshaller.marshall(mentry);
    
    log.log("jsentry " + jsentry);
    
    //log.log("iv " + iv + " pc " + pc);
    
    jsentry = Crypt.encryptPassToHex(creds["iv"], creds["pc"], jsentry);
    
    String subject = "Entry " + nowSecs + " " + nowMillis + " " + secName;
    Map outer = Maps.from("secret", jsentry, "passHash", creds["ph"], "subject", subject, "secName", secName, "updateSecs", nowSecs, "updateMillis", nowMillis);
    
    String outers = Json:Marshaller.marshall(outer);
     
    auto seckv = app.getKvDb("MYPASSES");
    
    seckv.put(a.user + "!" + secName, outers);
    
    auto sechis = app.getKvDb("PASSHIST");
    
    sechis.put(a.user + "!" + secName + "!" + nowSecs, outers);
    
    shrinkHist(a, secName);
    
   }
   
   showHistoryRequest(request) {
     Account a = request.context.get("account");
     auto sechis = app.getKvDb("PASSHIST");
     String hl = String.new();
     Set seen = Set.new();
     for (auto kv in sechis.getMap(a.user + "!")) {
       Map outer = Json:Unmarshaller.unmarshall(kv.value);
       String subject = outer["secName"];
       unless (seen.has(subject)) {
       hl += "<p><a href=\"#\" onclick=\"callApp('showHistoryEntryRequest', '" += subject += "');return false;\">" += subject += "</a></p>";
       seen.put(subject);
       }
     }
     
     return(CallBackUI.setElementsInnerHTMLResponse(Maps.from("histEntriesDiv", hl)));
   }
   
   showHistoryEntryRequest(String secName, request) {
     Account a = request.context.get("account");
     auto sechis = app.getKvDb("PASSHIST");
     String hl = String.new();
     List secopts = List.new();
     for (auto kv in sechis.getMap(a.user + "!" + secName + "!")) {
       Map outer = Json:Unmarshaller.unmarshall(kv.value);
       String subject = outer["secName"];
       Int nows = Int.new(outer["updateSecs"]);
       secopts += nows;
     }
     secopts = secopts.sort();
     hl += "<p>Available backups for " += secName += ", oldests to newest:</p>";
     Int j = secopts.size.copy();
     for (Int i in secopts) {
      hl += "<p><a href=\"#\" onclick=\"callApp('restoreHistoryEntryRequest', '" += secName += "', " += i += ");return false;\">" += j += ". " += secName += "</a></p>";
      j--=;
     }
     return(CallBackUI.setElementsInnerHTMLResponse(Maps.from("histEntriesDiv", hl)));
   }
   
   restoreHistoryEntryRequest(String secName, Int secs, request) {
     Account a = request.context.get("account");
     auto sechis = app.getKvDb("PASSHIST");
     String outers = sechis.get(a.user + "!" + secName + "!" + secs);
     auto seckv = app.getKvDb("MYPASSES");
     seckv.put(a.user + "!" + secName, outers);
     return(CallBackUI.toFindResponse());
   }
   
   shrinkHist(Account a, String secName) {
     
     auto sechis = app.getKvDb("PASSHIST");
     List hl = List.new();
     
     for (auto kv in sechis.getMap(a.user + "!" + secName + "!")) {
       auto tl = kv.key.split("!");
       String secs = tl.get(tl.size - 1);
       hl += Int.new(secs);
     }
     hl = hl.sort();
     
     if (hl.size > 3) {
       Int todel = hl.size - 3;
       for (Int j = 0; j < todel;j++=) {
         String delt = a.user + "!" + secName + "!" + hl.get(j).toString();
         sechis.delete(delt);
         log.log("deleted " + delt);
       }
     }
     for (Int i in hl) {
       log.log("in sh i " + i);
     }
   }
    
    saveSecretRequest(String secName, String secAccount, String secPass, String ivFirst, String pcFirst, request) {
      log.log("in ssr");
      if (TS.isEmpty(secName)) {
        return(CallBackUI.informResponse("Title is Requred"));
      }
      Account a = request.context.get("account");
      
      Map creds = getCreds(ivFirst, pcFirst, request);
      
      saveSecret(secName, secAccount, secPass, creds, a);
      
      //return(CallBackUI.informResponse("Secret Saved"));
      
      Map lres = Map.new();
      lres["action"] = "relistSecretsResponse";
      lres["accountName"] = a.user;
      getList(lres, lres);
      return(lres);
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
     String about = "<p>Abelii WifiSender Version " + self.version + "<p>";
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
