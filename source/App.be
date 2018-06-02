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
use Db:Firebird:Database as FbDb;
use Db:KeyValue as KvDb;
use Time:Interval;
use System:Parameters;
use App:RemoteWebApp;

use class App:Alert(Exception) { }

use class App:Paths {

  new(_app) self {
    fields {
      any app = _app;
      String name = app.plugin.name;
      String dataName = name;
    }
    if (app.plugin.can("dataNameGet", 0)) {
      dataName = app.plugin.dataName; 
    }
  }

  dataPathGet() Path {
    ifEmit(platDroid) {
      any app = createInstance("UI:JvAd:WebBrowser");
      dbp = Path.apNew(app.appDataDir).addStep("BeData").addStep(dataName);
    }
    ifNotEmit(platDroid) {
      Path dbp = Path.apNew("Data").addStep(dataName);
    }
    return(dbp);
  }
  
  appPathGet() Path {
    ifEmit(platDroid) {
      any app = createInstance("UI:JvAd:WebBrowser");
      dbp = Path.apNew(app.appDataDir).addStep("BeData").addStep(name);
    }
    ifNotEmit(platDroid) {
      Path dbp = Path.apNew("App").addStep(name);
    }
    return(dbp);
  }

}

use Net:Gateway as Gw;

class Gw {

  default() self {  }
  
  defaultAddressGet() String {
    
    System:Command sc = System:Command.new("netstat -rn").open();
    String res = sc.output.readString();
    sc.close();
    
    //("!!!!!! netstat output " + res).print();
    
    if (System:CurrentPlatform.name == "mswin") {
      Int fz = res.find("0.0.0.0"); //win
    } else {
      fz = 0;
    }
    if (def(fz)) {
      if (System:CurrentPlatform.name == "macos") {
        fz2 = res.find("default", fz + 1);
      } else {
        Int fz2 = res.find("0.0.0.0", fz + 1);
      }
      if (def(fz2)) {
        fz = fz2;
      }
      fz += 7;
      res = res.substring(fz);
      Bool started = false;
      String accum = String.new();
      for (String s in res.biter) {
        if (s == " ") {
          if (started) {
            break;
          }
        } else {
          started = true;
          accum += s;
        }
      }
    }
    //("gw accum " + accum).print();
    return(accum);
  }

}

//logic
use class App:AccountManager {

  new() self {
    fields {
      any kvDb;
      Json:Marshaller mar = Json:Marshaller.new();
      Json:Unmarshaller unmar = Json:Unmarshaller.new();
    }
  }
  
  new(_kvDb) {
    new();
    kvDb = _kvDb;
  }
  
  getLogins() List {
    List logins = List.new();
    for (any kv in kvDb.getMap()) {
      logins.addValue(kv.key);
    }
    return(logins);
  }

  getAccount(String user) {
    if (TS.notEmpty(user)) {
		String aj = kvDb.get(user);
		if (TS.notEmpty(aj)) {
		  Account a = Account.mapNew(unmar.unmarshall(aj));
		}
	}
    return(a);
  }
  
  deleteAccount(Account a) {
    kvDb.delete(a.user);
  }
  
  putAccount(Account a) {
    kvDb.put(a.user, mar.marshall(a.toMap()));
  }
  
  getRequestAccount(request) Account {
    String an = request.getSession("account.name");
    Account a = getAccount(an);
    return(a);
  }

}

use class App:Account {

  new() self {
    fields {
      Set perms = Set.new();
    }
  }

  new(String _user, String _hashPass, String _salt, String _permsString) self {
    new();
    fields {
      String user = _user;
      String pass = _hashPass;
      String salt = _salt;
    }
    self.permsString = _permsString;
  }
  
  mapNew(Map map) self {
    new(map["user"], map["pass"], map["salt"], map["perms"]);
  }
  
  toMap() Map {
    return(Map.new().put("user", user).put("pass", pass).put("salt", salt).put("perms", self.permsString));
  }
  
  toString() String {
    String rs = String.new();
    String ps = self.permsString;
    if (TS.isEmpty(ps)) {
      ps = "";
    }
    rs += " User: " += user += " permsString: " += ps;
    return(rs);
  }
  
  passSet(String _pass) {
    salt = System:Random.getString(16);
    pass = passToHash(_pass, salt);
  }
  
  passToHash(String pass, String salt) String {
    if (TS.isEmpty(salt) || TS.isEmpty(pass)) {
      return(null);
    }
    pass = salt + pass;
    Digest:SHA256 ds = Digest:SHA256.new();
    for (Int i = 0;i < 7;i++=) {
      pass = ds.digest(pass);
    }
    pass = Encode:Hex.encode(pass);
    return(pass);
  }
  
  checkPass(String _pass) Bool {
    _pass = passToHash(_pass, salt);
    if (def(_pass) && _pass == pass) {
      return(true);
    }
    return(false);
  }
  
  permsStringSet(String permsString) {
    perms = Set.new();
    if (TS.notEmpty(permsString)) {
      for (String perm in permsString.split(",")) {
        perms.put(perm);
      }
    }
  }
  
  permsStringGet() String {
    Bool first = true;
    String permsString = "";
    for (String perm in perms) {
      if (first) {
        first = false;
      } else {
        permsString += ",";
      }
      permsString += perm;
    }
    return(permsString);
  }
  
  isAdminGet() Bool {
    if (self.perms.has("admin")) {
      return(true);
    }
    return(false);
  }
  
}

use App:RunMainOnce;

class RunMainOnce {

emit(jv) {
"""
public static volatile boolean haveRun = false;
public synchronized static void runMainOnce() {
  if (!haveRun) {
    String[] margs = new String[0];
    try {
        be.BEX_E.main(margs);
    } catch (Throwable t) {
        System.err.println("Failed in main with " + t.getMessage());
        throw new Error(t.getMessage(), t);
    }
    haveRun = true;
  }
}
"""
}

emit(cs) {
"""
public static volatile bool haveRun = false;
public static volatile Object runMainLock = new Object();
public static void runMainOnce() {
  lock(runMainLock) {
    if (!haveRun) {
      string[] margs = new string[0];
      try {
          be.BEX_E.Main(margs);
      } catch (System.Exception t) {
          Console.Write(t.ToString());
      }
      haveRun = true;
    }
  }
}
"""
}

}

use App:EventHandlers as AppEv;
class AppEv {

  emit(jv) {
  """
  static void handleEvent(String event) {
    try {
        
    bece_BEC_2_3_13_AppEventHandlers_bevs_inst.bem_handleEvent_1(
    new $class/Text:String$(event)
    );
    } catch (Throwable t) {
        System.err.println("failed in handleEvent " + t.getMessage());
        throw new Error(t.getMessage(), t);
    }
  }
  """
  }

  put(String label, any handler) {
    registry.put(label, handler);
  }
  
  get(String label) {
    return(registry.get(label));
  }
  
  default() self {
    fields {
      Map registry = Map.new();
    }
  }
  
  handleEvent(String event) {
    any rc = registry.get(event);
    if (def(rc)) {
      List args = List.new(0);
      rc.invoke(event, args);
    }
  }

}

emit(cs) {
"""
using System.Security.Cryptography;
using System.IO;
using System;
"""
}

emit(jv) {
"""
import java.security.*;
import javax.crypto.*;
import javax.crypto.spec.*;
"""
}
use Crypto:Symmetric as Crypt;
class Crypt {

  new() self {
    fields {
      Int keyLength = 16;
      Int ivLength = 16;
    }
  }
  
  encryptPassToHex(String iv, String pass, String val) String {
    return(Encode:Hex.encode(encryptPass(iv, pass, val)));
  }

  encryptPass(String iv, String pass, String val) String {
    pass = Digest:SHA256.digest(pass);
    return(encrypt(iv, pass, val));
  }
  
  encrypt(String iv, String key, String val) String {
    iv = iv.substring(0, ivLength);
    key = key.substring(0, keyLength);//jv limit
    val = val.substring(0, val.size);
    String res;
    emit(cs) {
    """
    byte[] key = beva_key.bevi_bytes;
    byte[] iv = beva_iv.bevi_bytes;
    byte[] val = beva_val.bevi_bytes;
    RijndaelManaged rijndael = new RijndaelManaged();
    ICryptoTransform enc = rijndael.CreateEncryptor(key, iv);
    byte[] res = enc.TransformFinalBlock(val, 0, val.Length);
    bevl_res = new $class/Text:String$(res);
    """
    }
    emit(jv) {
    """
    byte[] key = beva_key.bevi_bytes;
    byte[] iv = beva_iv.bevi_bytes;
    byte[] val = beva_val.bevi_bytes;
    Cipher aesCipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
    SecretKey secretKey = new SecretKeySpec(key, "AES");
    IvParameterSpec ivParameterSpec = new IvParameterSpec(iv);
    aesCipher.init(Cipher.ENCRYPT_MODE, secretKey, ivParameterSpec);
    byte[] res = aesCipher.doFinal(val);
    bevl_res = new $class/Text:String$(res);
    """
    }
    return(res);
  }
  
  decryptPassFromHex(String iv, String pass, String val) String {
    return(decryptPass(iv, pass, Encode:Hex.decode(val)));
  }
  
  decryptPass(String iv, String pass, String val) String {
    pass = Digest:SHA256.digest(pass);
    return(decrypt(iv, pass, val));
  }
  
  decrypt(String iv, String key, String val) String {
    iv = iv.substring(0, ivLength);
    key = key.substring(0, keyLength);//jv limit
    val = val.substring(0, val.size);
    String res;
    emit(cs) {
    """
    byte[] key = beva_key.bevi_bytes;
    byte[] iv = beva_iv.bevi_bytes;
    byte[] val = beva_val.bevi_bytes;
    RijndaelManaged rijndael = new RijndaelManaged();
    ICryptoTransform enc = rijndael.CreateDecryptor(key, iv);
    byte[] res = enc.TransformFinalBlock(val, 0, val.Length);
    bevl_res = new $class/Text:String$(res);
    """
    }
    emit(jv) {
    """
    byte[] key = beva_key.bevi_bytes;
    byte[] iv = beva_iv.bevi_bytes;
    byte[] val = beva_val.bevi_bytes;
    Cipher aesCipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
    SecretKey secretKey = new SecretKeySpec(key, "AES");
    IvParameterSpec ivParameterSpec = new IvParameterSpec(iv);
    aesCipher.init(Cipher.DECRYPT_MODE, secretKey, ivParameterSpec);
    byte[] res = aesCipher.doFinal(val);
    bevl_res = new $class/Text:String$(res);
    """
    }
    return(res);
  }
}

use class App:AuthPlugin(App:AjaxPlugin) {

     new() self {
       fields {
          log =@ IO:Logs.get(self);
          any app;
          String name = "Auth";
          Set nonAuthedRequests = Set.new();
          OLocker lastLoginBad = OLocker.new(false);
          Set authedUrls = Set.new();
        }
        super.new();
     }
     
     cohostWith(App:AuthPlugin ohp) {
       ohp.accountManager = self.accountManager;
     }
     
     accountManagerGet() AccountManager {
      fields {
        AccountManager accountManager;
      }
      if (undef(accountManager)) {
        accountManager = AccountManager.new(app.getKvDb("ACCOUNTS"));
      }
      return(accountManager);
    }
    
    handleCmd(Parameters params) Bool {
      String mode = params.getFirst("authCmd");
      if (TS.isEmpty(mode)) {
        return(false);
      }
      if (mode == "showAccounts") {
        for (String login in self.accountManager.getLogins()) {
          log.log("Account login " + login);
        }
      }
      if (mode == "putAccount") {
        String user = params.getFirst("user");
        String pass = params.getFirst("pass");
        String perms = params.getFirst("perms");
        log.log("Putting Account " + user);
        Account ac = Account.new();
        ac.user = user;
        ac.pass = pass;
        if (def(perms)) {
          ac.permsString = perms;
        }
        self.accountManager.putAccount(ac);
      }
      if (mode == "setPerms") {
        user = params.getFirst("user");
        perms = params.getFirst("perms");
        log.log("Set Perms " + user);
        ac = self.accountManager.getAccount(user);
        ac.permsString = perms;
        self.accountManager.putAccount(ac);
        log.log("Account " + ac);
      }
      if (mode == "setPass") {
        user = params.getFirst("user");
        pass = params.getFirst("pass");
        perms = params.getFirst("perms");
        log.log("Set Pass " + user);
        ac = self.accountManager.getAccount(user);
        ac.pass = pass;
        self.accountManager.putAccount(ac);
      }
      if (mode == "deleteAccount") {
        user = params.getFirst("user");
        log.log("Deleting Account " + user);
        ac = self.accountManager.getAccount(user);
        if (def(ac)) {
          self.accountManager.deleteAccount(ac);
          log.log("Deleted account " + user);
        } else {
          log.log("No such account for deletion " + user);
        }
      }
      return(true);
    }
    
    getSessionsForAccount(Account a) String {
        //a.user
        String res = String.new();
        String accountName = a.user;
        Map all = app.sessionManager.sessions.getMap();
        for (any kv in all) {
          if (kv.key.ends("account.name") && kv.value == accountName) {
            //log.log("Found session " + kv.key);
            any kp = kv.key.split(".");
            String sessLabel = String.new();
            String name = app.sessionManager.sessions.get(kp.first + ".session.name");
            if (def(name)) {
              log.log("sess name " + name);
              sessLabel += "Session named " += name;
            }
            String ip = app.sessionManager.sessions.get(kp.first + ".ip");
            if (def(ip)) {
              log.log("sess ip " + ip);
              if (TS.notEmpty(sessLabel)) {
                sessLabel += " from ";
              } else {
                sessLabel += "Session from "
              }
              sessLabel += "IP Address " + ip;
            }
            if (TS.notEmpty(sessLabel)) {
              res += "<p>" += sessLabel += " <a href=\"#\" onclick=\"endSession('"
              += kp.first += "');return false;\">End Session (Log it out)</a></p>";
            }
          }
        }
        return(res);
      }
      
     
    clearAllSessionsRequest(Map arg, request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        log.log("Clearing all sessions request by login " + request.context.get("account").user);
        app.sessionManager.sessions.clear();
     }
     return(null);
   }
   
   badRequest(request) {
  
  }
  
  requestFromAdmin(request) Bool {
    Account a = self.accountManager.getRequestAccount(request);
    if (def(a) && a.perms.has("admin")) {
      return(true);
    }
    badRequest(request);
    return(false);
  }
  
  preLoginCheck(request) Bool {
    if (lastLoginBad.o) {
      Int slptime = System:Random.getIntMax(500);
      Time:Sleep.sleepMilliseconds(slptime);
    }
    return(true);
  }
  
  goodLogin(request) {
    lastLoginBad.o = false;
  }
  
  badLogin(request) {
    badRequest(request);
    lastLoginBad.o = true;
  }
  
   
   clearAllTrackingRequest(Map arg, request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        log.log("Clearing all tracking requested by login "  + request.context.get("account").user);
        self.trackingManager.clear();
     }
     return(null);
   }
   
   endSessionRequest(Map arg, request) Map {
     if (TS.notEmpty(arg["sessionKey"])) {
      app.sessionManager.deleteSessionByKey(arg["sessionKey"]);
     }
     return(showSessionsRequest(arg, request));
   }
   
   changePassRequest(Map arg, request) {
      Account a = self.accountManager.getRequestAccount(request);
      unless (TS.notEmpty(arg["newPass"]) && a.checkPass(arg["oldPass"])) {
        log.log("incorrect old pass");
        throw(Alert.new("Old password incorrect"));
      }
      a.pass = arg["newPass"];
      self.accountManager.putAccount(a);
      return(CallBackUI.informResponse("Password Changed"));
   }
   
   loadAccountRequest(String accountName, request) {
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = self.accountManager.getAccount(accountName);
      if (def(a)) {
        Map res = Map.new();
        res["action"] = "loadAccountResponse";
        res["accountName"] = a.user;
        res["admin"] = a.perms.has("admin");
        return(res);
      } elseIf (true) {
        throw(Alert.new("No such account"));
      }
      return(null);
   }
   
   showAccountAdminRequest(Map arg, request) {
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      String accountLinks = String.new();
      List logins = self.accountManager.getLogins();
      for (String login in logins) {
        accountLinks += "<p><a href=\"#\" onclick=\"callApp('loadAccountRequest', '" += login += "');return false;\">Modify Account " += login += "</a></p>";
      }
      Map res = Map.new();
      res["action"] = "showAccountAdminResponse";
      res["accountLinks"] = accountLinks;
      return(res);
   }
   
   deleteAccountRequest(Map arg, request) {
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = self.accountManager.getAccount(arg["accountName"]);
      if (def(a)) {
        if (a.user == self.accountManager.getRequestAccount(request).user) {
          throw(Alert.new("Cannot delete own account"));
        }
      }
      self.accountManager.deleteAccount(a);
      return(showAccountAdminRequest(arg, request));
  }
  
  updateAccount(String name, String pass, Bool isAdmin) {
  
    Account a = self.accountManager.getAccount(name);
      if (undef(a)) {
        log.log(name + " not found, creating new");
        a = Account.new();
        a.user = name;
      } else {
        log.log(name + " found, use existing");
      }
      if (TS.notEmpty(pass)) {
        log.log("pass set, changing");
        a.pass = pass;
      }
      if (isAdmin) {
        a.perms.put("admin");
      } else {
        a.perms.delete("admin");
      }
      self.accountManager.putAccount(a);
  
  }
  
  updateAccountRequest(String name, String pass, Bool isAdmin, request) {
    unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      if (name == self.accountManager.getRequestAccount(request).user) {
        throw(Alert.new("Cannot change own account"));
      }
    
      updateAccount(name, pass, isAdmin);
      
      //return(CallBackUI.informResponse("Account " + name + " saved."));
      //return(showAccountsRequest(request));
      
      return(CallBackUI.multiResponse(Lists.from(CallBackUI.informResponse("Account " + name + " saved."), showAccountsRequest(request)))); 
      
  }
  
  removeAccountRequest(String name, request) {
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = self.accountManager.getAccount(name);
      if (def(a)) {
        if (a.user == self.accountManager.getRequestAccount(request).user) {
          throw(Alert.new("Cannot delete own account"));
        }
      }
      self.accountManager.deleteAccount(a);
      //return(CallBackUI.informResponse("Account " + name + " removed."));
      //return(showAccountsRequest(request));
      
      return(CallBackUI.multiResponse(Lists.from(CallBackUI.informResponse("Account " + name + " removed."), showAccountsRequest(request)))); 
  }
  
  showAccountsRequest(request) {
    unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      String accountLinks = "";
    List logins = self.accountManager.getLogins();
      for (String login in logins) {
        
        Account a = self.accountManager.getAccount(login);
        accountLinks += "<p>Account Name: " += login += " is administrator: " += a.isAdmin;
      }
      return(CallBackUI.setElementsInnerHTMLResponse(Maps.from("accountListDiv", accountLinks)));
  }
      
   saveAccountRequest(Map arg, request) {
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = self.accountManager.getAccount(arg["accountName"]);
      if (undef(a)) {
        log.log(arg["accountName"] + " not found, creating new");
        a = Account.new();
        a.user = arg["accountName"];
      } else {
        if (a.user == self.accountManager.getRequestAccount(request).user) {
          throw(Alert.new("Cannot change own account"));
        }
        log.log(arg["accountName"] + " found, use existing");
      }
      if (TS.notEmpty(arg["accountPass"])) {
        log.log("pass set, changing");
        a.pass = arg["accountPass"];
      }
      if (arg["admin"]) {
        a.perms.put("admin");
      } else {
        a.perms.delete("admin");
      }
      self.accountManager.putAccount(a);
      return(null);
   }
   
   showSessionsRequest(Map arg, request) {
      Account a = self.accountManager.getRequestAccount(request);
      Map res = Map.new();
      res["action"] = "showSessionsResponse";
      res["sessionsList"] = getSessionsForAccount(a);
      return(res);
   }
   
   checkLoggedInRequest(Map arg, request) {
    String accountName = request.getSession("account.name");
    if (TS.isEmpty(accountName) && request.embedded) {
      log.log("checking embeddedLogin");
      String eml = app.configManager.get("auth.embeddedLogin");
      if (TS.notEmpty(eml)) {
        log.log("checking embeddedLogin eml notempty");
        accountName = eml;
      }
    }
    if (TS.notEmpty(accountName)) {
      Account a = self.accountManager.getAccount(accountName);
      if (def(a)) {
        log.log("Found logged in account " + accountName);
        Map sarg = Map.new();
        sarg["accountName"] = accountName;
        setupSession(sarg, request);
        Map res = Map.new();
        res["action"] = "loggedInResponse";
        res["name"] = accountName;
        res = loggedIn(a, res, arg, request);
        res.delete("loginUri");
        return(res);
      } else {
        log.log("No such account " + accountName);
      }
    }
    log.log("doing tologin return");
    return(CallBackUI.toLoginResponse());
  }
  
  setupSession(Map arg, request) {
    request.putSession("account.name", arg["accountName"]);
    if (request.embedded) {
      log.log("putting embeddedLogin");
      app.configManager.put("auth.embeddedLogin", arg["accountName"]);
    }
    request.putSession("ip", request.remoteAddress);
    if (TS.notEmpty(arg["sessionName"])) {
      request.putSession("session.name", arg["sessionName"]);
    }
    String sessionLength = arg["sessionLength"];
    if (TS.isEmpty(sessionLength) || sessionLength.isInteger()!) {
      sessionLength = request.getSession("sessionLength");
      if (TS.isEmpty(sessionLength) || sessionLength.isInteger()!) {
        sessionLength = "30";
      }
    }
    if (request.embedded) {
      sessionLength = "-1";
    }
    Int sessionLengthI = Int.new(sessionLength) * 60;
    if (sessionLengthI < 0) {
      sessionLengthI = -1;
    }
    log.log("sessionLength " + sessionLengthI.toString());
    request.putSession("sessionLength", sessionLengthI.toString());
    if (sessionLengthI < 0) {
      request.putSession("sessionExp", sessionLengthI.toString());
    } else {
      Int snow = Time:Interval.now().seconds;
      Int ssd = snow + sessionLengthI;
      request.putSession("sessionExp", ssd.toString());
      Int ssu = snow + 60;
      request.putSession("sessionUpdate", ssu.toString());
    }
  }
  
  pageTokenRequest(Map arg, request) {
    log.log("in pagetokenrequest");
    if (app.plugin.okForPageToken(request)) {
      Map res = Map.new();
      pageToken = request.getSession("pageToken");
      if (TS.isEmpty(pageToken)) {
        String pageToken = System:Random.getString(32);
        request.putSession("pageToken", pageToken);
      }
      res["pageToken"] = pageToken;
      res["action"] = "pageTokenResponse";
    }
    return(res);
  }

  loginRequest(Map arg, request) {
    Account a = self.accountManager.getAccount(arg["accountName"]);
    if (def(a) && preLoginCheck(request)) {
      log.log("Found account " + arg["accountName"]);
      if (a.checkPass(arg["accountPass"])) {
        log.log("Login ok");
        Map res = Map.new();
        if (arg.has("serviceLogin")) {
          String pageToken = System:Random.getString(32);
          String serviceSessionKey = System:Random.getString(64);
          request.serviceSessionKey = serviceSessionKey;
          request.putSession("pageToken", pageToken);
          res["serviceSessionKey"] = serviceSessionKey;
          res["pageToken"] = pageToken;
        }
        setupSession(arg, request);
        res["action"] = "loggedInResponse";
        res["name"] = arg["accountName"];
        goodLogin(request);
        return(loggedIn(a, res, arg, request));
      } else {
        log.log("Login notok");
        badLogin(request);
      }
    } else {
      log.log("No such account " + arg["accountName"]);
      badLogin(request);
    }
    return(logoutRequest(arg, request));
  }
  
 loggedIn(Account a, Map res, Map arg, request) Map {
    if (app.plugin.can("loggedIn", 4)) {
      res = app.plugin.loggedIn(a, res, arg, request)
    }
    return(res);
  }
  
  logoutRequest(Map arg, request) {
    //request.deleteSession();
    request.putSession("account.name", "");
    if (request.embedded) {
      app.configManager.delete("auth.embeddedLogin");
    }
    Map res = Map.new();
    res["action"] = "logoutResponse";
    return(res);
  }
  
  start() {
    log.log("initting managers auth");
    self.trackingManagerGet();
  }
  
  trackingManagerGet() KvDb {
    return(app.getKvDb("TRACKING"));
  }
  
  check(request) Bool {
  
    Int maxBad =@ 300;
    Int clearSecs =@ 40;
    Int updateSecs =@ 20;
  
  /*
    Int maxBad =@ 5;
    Int clearSecs =@ 10;
    Int updateSecs =@ 5;
  */
  
    /*
    log.log("checking origins");
    String org = request.getInputHeader("origin");
    String ref = request.getInputHeader("referer");
    String uri = request.uri;
    String la = request.localAddress;
    String ra = request.remoteAddress;
    if (true) {
      if (def(org)) {
        log.log("orgin " + org);
      }
      if (def(ref)) {
        log.log("referer " + ref);
      }
      if (def(uri) && def(la) && def(ra)) {
        log.log("uri, la, ra " + uri + " " + la + " " + ra);
      }
    }
    */
    
    if (request.embedded) {
      return(true);
    }
    
    String accountName = request.getSession("account.name");
    if (TS.notEmpty(accountName)) {
        return(true);
    }
    
    String ip = request.remoteAddress;
    String sip = request.getSession("ip");
    
    Int ns = Time:Interval.now().seconds;
    
    if (TS.notEmpty(ip)) {
      String ct = self.trackingManager.get("IP." + ip);
      if (TS.notEmpty(ct)) {
        String ltm = self.trackingManager.get("LB." + ip);
        if (TS.notEmpty(ltm)) {
          Int ltmi = Int.new(ltm);
          if (ns - ltmi > clearSecs) {
            log.log("clear bad " + ip);
            badcount = 0;
          } else {
            badcount = Int.new(ct);
          }
        } else {
          Int badcount = Int.new(ct);
        }
      } else {
        badcount = 0;
      }
    }
    if (badcount > maxBad) {
      log.log("toomany bad " + ip);
      if (def(ltmi) && ns - ltmi > updateSecs) {
        log.log("lp update");
        self.trackingManager.put("LB." + ip, ns.toString());
      } else {
        log.log("no update");
      }
      return(false);
    }
    if (TS.isEmpty(accountName)) {
      log.log("upping bad");
      badcount++=;
      self.trackingManager.put("IP." + ip, badcount.toString());
      self.trackingManager.put("LB." + ip, ns.toString());
    } else {
      self.trackingManager.delete("IP." + ip);
      self.trackingManager.delete("LB." + ip);
      //self.trackingManager.clear();
    }
    return(true);
  }
  
  toLogin(request) this {
    request.scriptReturn = CallBackUI.toLoginResponse();
  }
  
  isCrossSite(request) Bool {
    if (request.embedded) { return(false); }
    String ref = request.getInputHeader("referer");
    String la = request.localAddress;
    if (TS.isEmpty(ref) || TS.isEmpty(la)) {
      //log.log("isCrossSite true empty");
      //if (TS.isEmpty(ref)) { log.log("ref empty"); } else { log.log("la empty"); }
      return(true);
    }
    for (sn in authedUrls) {
      //log.log("al sn is " + sn);
      if (ref.lower().begins(sn.lower())) {
        //log.log("ixs false sitelist");
        return(false);
      }
    }
    //log.log("referer is " + ref);
    String snlist = app.configManager.get("auth.siteNames");
    if (TS.notEmpty(snlist)) {
      //log.log("siteNames " + snlist);
      for (String sn in snlist.split(",")) {
        //log.log("sn is " + sn);
        if (ref.begins(sn)) {
          //log.log("ixs false sitelist");
          return(false);
        }
      }
    }
    la = app.webProto + "://" + la;
    if (ref.begins(la)) {
      //log.log("isCrossSite false begins " + la + " " + ref);
      return(false);
    }
    
    String pref = app.webProto + "://";
    log.log("prefix " + pref);
    String intPort = app.webPort;
    if (ref.begins(pref + "127.0.0.1:" + intPort) || ref.begins(pref + "localhost:" + intPort)) {
      //log.log("icc false localhost");
      return(false);
    }
    

    //log.log("isCrossSite true not begins " + la + " " + ref);
    return(true);
  }
  
  checkRenewSession(request) Bool {
    String sessionExp = request.getSession("sessionExp");
    if (TS.isEmpty(sessionExp)) {
      log.log("no sessionExp");
      return(false);
    }
    log.log("sessionExp " + sessionExp);
    Int sei = Int.new(sessionExp);
    if (sei < 0) {
      log.log("session never expires");
      return(true); //never expires
    }
    Int ns = Time:Interval.now().seconds;
    if (ns > sei) {
      log.log("session expired");
      return(false);
    }
    Int nu = Int.new(request.getSession("sessionUpdate"));
    if (ns > nu) {
      log.log("refreshing sessionUpdate");
      nu = ns + 60;
      request.putSession("sessionUpdate", nu.toString());
      Int ne = Int.new(request.getSession("sessionLength")) + ns;
      request.putSession("sessionExp", ne.toString());
    }
    log.log("checkRenewSession returning true");
    return(true);
  }
  
  handleWeb(request) this {
    prepArgs(request);
    Map arg = request.context["arg"];
    if (request.embedded! && def(arg) && TS.notEmpty(arg["serviceSessionKey"])) {
      request.serviceSessionKey = arg["serviceSessionKey"];
    }
    unless (check(request)) {
      toLogin(request);
      return(self);
     }
     
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
       String ln = request.getParameter("accountName");
       String lp = request.getParameter("accountPass");
       if (TS.notEmpty(ln) && TS.notEmpty(lp)) {
          log.log("doing svc login");
          Account a = self.accountManager.getAccount(ln);
          if (def(a) && preLoginCheck(request)) {
            log.log("Found account " + ln);
            if (a.checkPass(lp)) {
              log.log("svc login ok");
              request.putSession("account.name", ln);
              request.putSession("ip", request.remoteAddress);
              goodLogin(request);
              accountName = ln;
            } else {
              badLogin(request);
            }
          } else {
            badLogin(request);
          }
        }
      }
     
        try {
            if (isCrossSite(request)) {
              log.log("rejecting cross site request");
              toLogin(request);
              return(self);
            }
            if (def(arg) && def(arg.get("action"))) {
              String aname = arg.get("action");
               if (nonAuthedRequests.has(aname)) {
                 log.log("nar has");
                 request.continueHandling = true;
                 return(self);
               } else {
                log.log("nar nohas");
                unless (aname == "pageTokenRequest") {
                  accountName = request.getSession("account.name");
                  if (TS.isEmpty(accountName)) {
                    unless (aname == "loginRequest" || aname == "checkLoggedInRequest") {
                      log.log("ret givelogin");
                      toLogin(request);
                      return(self);
                    }
                  } else {
                  
                    unless (aname == "loginRequest" || checkRenewSession(request)) {
                        log.log("rejecting expired session request");
                        toLogin(request);
                        return(self);
                    }
                  
                    //checkLoggedInRequest is ok
                     
                    String stok = request.getSession("pageToken");
                    String atok = arg["pageToken"];
                    if (TS.isEmpty(stok) || TS.isEmpty(atok)) {
                      log.log("stok or atok emtpy failing due to pageToken");
                      toLogin(request);
                      return(self);
                    }
                    if (stok != atok) {
                      log.log("stok != atok failing due to pageToken");
                      toLogin(request);
                      return(self);
                    }
                  
                    //log.log("pageToken action " + aname);
                    //if (def(arg["pageToken"])) { log.log("pageToken " + //arg["pageToken"]); } else { log.log("no pageToken"); }
                    //if (def(stok)) { log.log("session pageToken " + stok); }
                  }
                }
              } 
              log.log("here");
              request.context.put("account", self.accountManager.getRequestAccount(request));
              super.handleWeb(request);
          } else {
            request.continueHandling = true;
          }
          if (undef(request.getSession("account.name"))) {
            request.continueHandling = false;
          } elseIf (undef(request.context.get("account"))) {
            request.context.put("account", self.accountManager.getRequestAccount(request));
          }
          log.log("auth done continueHandling is " + request.continueHandling);
          return(self);
        } catch (any e) {
           log.log("Caught exception during handleWeb B");
           if (def(e)) {
            log.log("Exception was " + e);
           }
        }
    }
  
   
}

use class App:PublicReadPlugin {

     new() self {
       fields {
          any app;
          String name = "Public";
          IO:Log log =@ IO:Logs.get(self);
        }
     }
     
       
     handleWeb(request) this {
       String rmtd = request.inputMethod;
       log.log("public read rmtd is " + rmtd);
       if (TS.isEmpty(rmtd) || rmtd == "GET") {
         log.log("in rmtd method is get");
         String uri = request.uri;
         log.log("uri " + uri);
         if (TS.isEmpty(uri) || uri == "/") {
          log.log("empty uri going to base page");
          request.outputContent = "<html><head><script>location=\"" + app.plugin.homePage + "\"</script></html>";
          return(self);
         }
         File imgfile = File.apNew(Encode:Url.decode(uri.substring(1)));
         Path pa = imgfile.absPath;
         Bool readOk = false;
         for (any pl in app.plugins) {
          if (pl.can("checkPublicReadPath", 2)) {
            if (pl.checkPublicReadPath(pa, request)) {
              readOk = true;
              break;
            }
          }
         }
         if (readOk) {
            log.log("chkrdp fm true public");
           log.log("imgfile " + imgfile.path);
           if (imgfile.exists) {
            String mtype;
            if (uri.ends(".html")) {
              mtype = "text/html";
            } elseIf (uri.ends(".jpg")) {
              mtype = "image/jpeg";
            } elseIf (uri.ends(".svg")) {
              mtype = "image/svg+xml";
            } elseIf (uri.ends(".js")) {
              mtype = "text/javascript";
            } elseIf (uri.ends(".css")) {
              mtype = "text/css";
            } elseIf (uri.ends(".woff")) {
              mtype = "application/font-woff";
            } elseIf (uri.ends(".eot")) {
              mtype = "application/vnd.ms-fontobject";  
            } elseIf (uri.ends(".eot")) {
              mtype = "application/font-sfnt";
            } else {
              mtype = "application/octet-stream";
            }
            request.outputContentType = mtype;
            IO:Writer outw = request.openOutput();
            IO:Reader inr = imgfile.reader.open();
            inr.copyData(outw);
            request.closeOutputWriter();
            inr.close();
            return(self);
           }
         }
       }
       request.continueHandling = true;
       return(self);
     }
}

use class App:WebReverseProxyPlugin {

     new() self {
       fields {
          any app;
          String name = "WRProxy";
          String dataName = "KBridge";
          IO:Log log =@ IO:Logs.get(self);
          //String destUrl = "http://127.0.0.1:";
          String destUrl;
          Bool sslValidate;
        }
        IO:Logs.turnOnAll();
     }
     
     start() {
       log.log("later sessionid " + app.configManager.get("auth.sessionId"));
       if (undef(destUrl)) {
        destUrl = app.params.getFirst("proxyDestUrl");
       }
       if (undef(destUrl)) {
        throw(Exception.new("proxyDestUrl parameter undefined"));
       }
       if (undef(sslValidate)) {
         String svs = app.params.getFirst("proxySslValidate");
         if (TS.isEmpty(svs)) {
          svs = "true";
         }
         self.sslValidate = Bool.new(svs);
       }
     }
     
     sslValidateSet(Bool sslv) {
      sslValidate = sslv;
      Web:Client:CertificateManager.validateHosts = sslv;
      Web:Client:CertificateManager.validateCertificates = sslv;
     }
     
     handleWeb(request) this {
            
       String uri = request.uri;
       if (TS.isEmpty(uri)) {
        log.log("uri empty");
        uri = "/";
       }
       log.log("proxy uri " + uri);
       
       String qs = request.queryString;
       if (TS.isEmpty(qs)) {
        log.log("qs empty");
        qs = "";
       } else {
        qs = "?" + qs;
       }
       log.log("qs " + qs);
       
       String destReq = destUrl + uri + qs;
       
       log.log("destReq " + destReq);
       
       String rmtd = request.inputMethod;
       log.log("req mtd " + rmtd);
       
       String accountName = request.getSession("account.name");
       if (TS.isEmpty(accountName)) {
        log.log("no accountname, halting");
        request.outputContent = "<html><head><body><p>Logged out<p>Please log back into Konnectii Bridge to continue</body></html>";
        return(self);
       } else {
        log.log("found account " + accountName);
       }
       
       Web:Client client = Web:Client.new();
       client.followRedirects = false;
       client.url = destReq;
       
       //"User-Agent"
       //Set suppress =@ Sets.from("Server", "Accept", "Connection", "Content-Length", "Content-Type", "Date", "Expect", "Host", "If-Modified-Since", "Range", "Referrer", "Referer", "Transfer-Encoding", "Proxy-Connection");
       
       Set include =@ Sets.from("User-Agent", "Cookie", "Referer", "Set-Cookie");
       
       //headers
       Set hkeys = request.inputHeaderKeys;
       for (String hkey in hkeys) {
        //log.log("inputHeaderKey " + hkey);
        String ihv = request.getInputHeader(hkey);
        //log.log("inputHeaderValue " + ihv);
        if (include.has(hkey)) {
          log.log("sending client header " + hkey + " " + ihv);
          client.outputHeaders.put(hkey, ihv);
        } else {
          log.log("suppressed header " + hkey + " " + ihv);
        }
       }
       
       //cookies SEE IF PART OF HEADERS
       //user agent PART OF HEADERS BUT CHECK
       //body for posts DONE
       if (rmtd == "POST" || rmtd == "PUT") {
         log.log("in put or post");
         client.verb = rmtd;
         client.outputContentType = request.inputContentType;
         outw = client.openOutput();
         inr = request.openInput();
         inr.copyData(outw);
       }
       
       IO:Reader inr = client.openInput();
       
       String ct = client.inputContentType;
       
       if (TS.notEmpty(ct)) {
        log.log("ct " + ct);
        request.outputContentType = ct;
       } else {
        log.log("ct empty");
       }
              
       for (auto kv in client.inputHeaders) {
        if (include.has(kv.key)) {
          log.log("sending response header " + kv.key + " " + kv.value);
          request.setOutputHeader(kv.key, kv.value);
        } else {
          if (kv.key == "Location") {
            log.log("got a location header");
            String loc = kv.value;
            if (loc.has(destUrl)) {
              loc = loc.substring(destUrl.size);
            }
            log.log("final loc, will send " + loc)
            //request.setOutputHeader(kv.key, loc);
            request.outputContent = "<html><head><script>location=\"" + loc + "\"</script></html>";
            return(self);
          }
          log.log("suppressed response header " + kv.key + " " + kv.value);
        }
       }
       
       IO:Writer outw = request.openOutput();
       inr.copyData(outw);
       request.closeOutputWriter();
       inr.close();
       
       
     }
}

use class App:FileManagerPlugin(App:AjaxPlugin) {

     new() self {
       fields {
          any app;
          String name = "Files";
        }
        super.new();
        log =@ IO:Logs.get(self);
     }
     
    checkWritePath(Path p, Map arg, request) Bool {
      Account a = request.context.get("account");
      if (def(a) && a.perms.has("admin")) {
        return(true);
      }
      String accountName = request.getSession("account.name");
      any e;
      Bool isOk = false;
      if (undef(accountName)) { accountName = ""; }
      try {
        Path pa = p.file.absPath;
        if (TS.notEmpty(accountName)) {
          Path h = Path.apNew("Home/" + accountName).file.absPath;
        }
        String pas = pa.toString();
        if (def(h) && pas.begins(h.toString())) {
          isOk = true;
        }
      } catch (e) {
        log.log("Path " + p + " accountName " + accountName + " excepted in checkPath " + e);
      }
      //log.log("checkPath isOk " + isOk);
      return(isOk);
   }
   
   checkReadPath(Path p, Map arg, request) Bool {
    log.log("in chkrdp fm");
    Path pa = p.file.absPath;
    String pas = pa.toString();
    Account a = request.context.get("account");
    if (def(a) && a.perms.has("admin")) {
      return(true);
    }
    String accountName = request.getSession("account.name");
    any e;
    Bool isOk = false;
    if (undef(accountName)) { accountName = ""; }
    try {
      if (TS.notEmpty(accountName)) {
        Path h = Path.apNew("Home/" + accountName).file.absPath;
      }
      if (def(h) && pas.begins(h.toString())) {
        isOk = true;
      }
    } catch (e) {
      log.log("Path " + p + " accountName " + accountName + " excepted in checkPath " + e);
    }
    //log.log("checkPath isOk " + isOk);
    return(isOk);
   }
  
     handleWeb(request) this {
       String rmtd = request.inputMethod;
       log.log("in filemanager handleweb rmtd is " + rmtd);
       if (TS.isEmpty(rmtd) || rmtd != "PUT") {
          App:AjaxPlugin.new().prepArgs(request);
          Map arg = request.context["arg"];
       }
       if (undef(arg)) {
         log.log("in fm arg undef");
         String uri = request.uri;
         log.log("uri " + uri);
         if (TS.isEmpty(uri) || uri == "/") {
          log.log("empty uri in filemanager");
          return(self);
         }
         File imgfile = File.apNew(Encode:Url.decode(uri.substring(1)));
         if (TS.notEmpty(rmtd) && rmtd == "PUT") {
           if (checkWritePath(imgfile.path, null, request)) {
             log.log("put for " + imgfile.path);
             if (imgfile.path.parent.file.exists!) {
              imgfile.path.parent.file.makeDirs();
             }
             if (imgfile.exists) { imgfile.delete(); }
              outw = imgfile.writer.open();
              inr = request.openInput();
              inr.copyData(outw);
              request.closeInputReader();
              outw.close();
              request.outputContent = "UPLOAD COMPLETE";
           }
         } elseIf (checkReadPath(imgfile.path, arg, request)) {
           log.log("imgfile " + imgfile.path);
           if (imgfile.exists) {
            String mtype;
            if (uri.ends(".html")) {
              mtype = "text/html";
            } elseIf (uri.ends(".jpg")) {
              mtype = "image/jpeg";
            } elseIf (uri.ends(".svg")) {
              mtype = "image/svg+xml";
            } elseIf (uri.ends(".js")) {
              mtype = "text/javascript";
            } elseIf (uri.ends(".css")) {
              mtype = "text/css";
            } else {
              mtype = "application/octet-stream";
            }
            request.outputContentType = mtype;
            IO:Writer outw = request.openOutput();
            IO:Reader inr = imgfile.reader.open();
            inr.copyData(outw);
            request.closeOutputWriter();
            inr.close();
           }
         }
        return(self);
       }
       super.handleWeb(request);
       return(self);
     }
     
     deleteRequest(Map arg, request) Map {
     log.log("del request");
     String path = arg["path"];
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
     if (TS.notEmpty(path)) {
       File dirFile = File.apNew(Encode:Hex.new().decode(path));
       if (dirFile.exists && checkWritePath(dirFile.path, arg, request)) {
         log.log("deleting " + dirFile.path);
         dirFile.delete();
       }
     }
     return(null);
   }
   
   copyRequest(Map arg, request) Map {
     log.log("copy request");
     String path = arg["path"];
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
     if (TS.notEmpty(path)) {
       File dirFile = File.apNew(Encode:Hex.new().decode(path));
       if (TS.notEmpty(arg["toName"]) && dirFile.exists && checkWritePath(dirFile.path, arg, request)) {
         any dpath = Path.apNew(arg["toName"]);
         dpath = dirFile.path.parent.copy() + dpath;
         log.log("precheck write " + dpath);
         if (checkWritePath(dpath, arg, request)) {
           log.log("copying " + dirFile.path + " to " + dpath);
           if (dpath.parent.file.exists!) {
             dpath.parent.file.makeDirs();
           }
           if (dpath.file.exists) { dpath.file.delete(); }
            IO:Writer outw = dpath.file.writer.open();
            IO:Reader inr = dirFile.reader.open();
            inr.copyData(outw);
            outw.close();
            inr.close();
          }
       }
     }
     return(null);
   }
   
   createDirectoryRequest(Map arg, request) Map {
     log.log("createdir request");
     String inDir = arg["inDir"];
     String dirName = arg["dirName"];
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
     if (TS.notEmpty(inDir) && TS.notEmpty(dirName)) {
       Path dirPath = Path.apNew(Encode:Hex.new().decode(inDir));
       dirPath.addStep(dirName);
       File dirFile = dirPath.file.absPath.file;
       if (dirFile.exists! && checkWritePath(dirFile.path, arg, request)) {
         log.log("creating " + dirFile.path);
         dirFile.makeDirs();
       }
     }
     arg["path"] = arg["inDir"];
     return(localBrowseRequest(arg, request));
   }
   
   getHomeDir(request) Path {
      String accountName = request.getSession("account.name");
      Path homeDir = Path.apNew("Home/" + accountName);
      return(homeDir);
    }
    
   
   getBaseLink(request) String {
     return("<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += Encode:Hex.encode(getHomeDir(request).toString()) += "');return false;\">HOME</a></td></tr>");
   
   }
   
   jscallForPath(Path p) {
    if (p.toString().ends(".jpg")) {
      String jscall = " onclick=\"localBrowseRequest('" += Encode:Hex.encode(p.toString()) += "');return false;\"";
    } elseIf (p.toString().ends(".html") || p.toString().ends(".htm")) {
      jscall = " onclick = \"return false;\"";
    } else {
      jscall = "";
    }
    return(jscall);
   }
   
   localBrowseRequest(Map arg, request) Map {
     log.log("in local browse req");
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
      Encode:Hex hex = Encode:Hex.new();
      Encode:Url urle = Encode:Url.new();
      Encode:Html htmle = Encode:Html.new();
      Map ret = Map.new();
      String path = arg["path"];
      Account a = request.context.get("account");
      Bool adminLinks = false;
      if (a.perms.has("admin")) {
        adminLinks = true;
      }
      if (TS.isEmpty(path)) {
        dirFile = getHomeDir(request).file;
        if (dirFile.exists!) {
          dirFile.makeDirs();
        }
      } else {
        File dirFile = File.apNew(hex.decode(path));
      }
      String dirListHtml = String.new();
      dirListHtml += "<input type=\"hidden\" id=\"browsingDirId\" value=\"" += hex.encode(dirFile.path.toString()) += "\"/>";
      if (dirFile.exists && checkReadPath(dirFile.path, arg, request)) {
        dirListHtml += "<p>Listing 3 for " += htmle.encode(dirFile.path.toString()) += "</p>";
        dirListHtml += "<table>";
        if (adminLinks) {
          if (System:CurrentPlatform.name == "mswin") {
            dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode("\\") += "');return false;\">ROOT</a></td></tr>";
          } else {
            dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode("/") += "');return false;\">ROOT</a></td></tr>";
          }
          dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(".") += "');return false;\">APPDIR</a></td></tr>";
        }
        dirListHtml += getBaseLink(request); 
        dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(dirFile.path.toString()) += "');return false;\">.  (REFRESH)</a></td></tr>";
        IO:File:Path parent = dirFile.path.parent;
        if (def(parent) && TS.notEmpty(parent.toString())) {
        dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(parent.toString()) += "');return false;\">.. (UP)</a></td></tr>";
        }
        if (dirFile.isDir) {
          auto dit = dirFile.iterator;
          dit.open();
          List olist = List.new();
          Map omap = Map.new();
          while (dit.hasNext) {
            File entry = dit.next;
            Path p = entry.path;
            olist += p.steps.last;
            omap.put(p.steps.last, entry);
          }
          olist = olist.sort();
          for (String ole in olist) {
            entry = omap.get(ole);
            p = entry.path;
            if (entry.isDirectory) {
              dirListHtml += "<tr>";
              dirListHtml += "<td>DIR</td><td><a href=" + TS.quote + "#" + TS.quote + " onclick=\"localBrowseRequest('"
          += hex.encode(p.toString()) += "');return false;\">" += htmle.encode(p.name) += "</a></td>";
              dirListHtml += "<td><input type=\"checkbox\" id=\"FCB"
              += hex.encode(p.toString()) += "\" onclick=\"fileChecked(this);\"\"></td>";
              dirListHtml += "</tr>";   
            } else {
              String jscall = jscallForPath(p);
              dirListHtml += "<tr>";
              dirListHtml += "<td>FILE</td><td><a href=" += TS.quote += "../../" += urle.encode(p.toString()) += "?pageToken=" += request.getSession("pageToken") += TS.quote + jscall + ">" += htmle.encode(p.name) += "</a></td><td>" += entry.size += "</td>";
              dirListHtml += "<td><input type=\"checkbox\" id=\"FCB"
              += hex.encode(p.toString()) += "\" onclick=\"fileChecked(this);\"\"></td>";
              dirListHtml += "</tr>";
            }
          }
          dit.close();
        } elseIf (dirFile.path.toString().ends(".note")) {
          
        } elseIf (dirFile.path.toString().ends(".jpg")) {
          //get one before and after for slideshow
          dit = dirFile.path.parent.file.iterator;
          dit.open();
          olist = List.new();
          omap = Map.new();
          while (dit.hasNext) {
            entry = dit.next;
            p = entry.path;
            olist += p.steps.last;
            omap.put(p.steps.last, entry);
          }
          dit.close();
          olist = olist.sort();
          auto pitcs = dirFile.path.toString();
          Bool found = false;
          for (ole in olist) {
            entry = omap.get(ole);
            auto ps = entry.path.toString();
            if (ps == pitcs) {
              found = true;
            } else {
              if (ps.ends(".jpg")) {
                if (found) {
                  if (undef(safter)) {
                    auto safter = entry.path;
                  }
                } else {
                  auto sbefore = entry.path;
                }
              }
            }
          }
          Map res = Map.new();
          res["action"] = "updateImageResponse";
          res["imghtm"] = "<img src=\"../../" + dirFile.path.toStringWithSeparator("/") + "?pageToken=" + request.getSession("pageToken") + "&cbust=" + Time:Interval.now().seconds + System:Random.getString(6) + "\" >";
          if (def(sbefore)) {
            log.log("Got before pic " + sbefore);
            p = sbefore;
            jscall = " onclick=\"localBrowseRequest('" += hex.encode(p.toString()) += "');return false;\"";
            auto plink = "<a href=" += TS.quote += "../../" += urle.encode(p.toString()) += "?pageToken=" += request.getSession("pageToken") += TS.quote + jscall + ">Prior Pic</a>";
            res["plink"] = plink;
          
          }
          if (def(safter)) {
            log.log("Got after pic " + safter);
            p = safter;
            jscall = " onclick=\"localBrowseRequest('" += hex.encode(p.toString()) += "');return false;\"";
            auto nlink = "<a href=" += TS.quote += "../../" += urle.encode(p.toString()) += "?pageToken=" += request.getSession("pageToken") += TS.quote + jscall + ">Next Pic</a>";
            res["nlink"] = nlink;
          }
          return(res);
        }
        dirListHtml += "</table>";
      }
      ret.put("action", "localBrowseResponse");
      ret.put("dirListHtml", dirListHtml);
      return(ret);
    }
   
}

use class App:ConfigPlugin(App:AjaxPlugin) {

     new() self {
       fields {
          any app;
          String name = "Conf";
          String kvdb = "CONFIG";
        }
        super.new();
        log =@ IO:Logs.get(self);
     }
     
     handleCmd(Parameters params) Bool {
      String mode = params.getFirst("confCmd");
      if (TS.isEmpty(mode)) {
        return(false);
      }
      String kvdbov = params.getFirst("kvdb");
      if (TS.notEmpty(kvdbov)) {
        kvdb = kvdbov;
      }
      app.getKvDb(kvdb);//warmup
      if (mode == "showConfig") {
        if (TS.notEmpty(params.getFirst("prefix"))) {
          for (kv in app.getKvDb(kvdb).getMap(params.getFirst("prefix"))) {
            log.log("Config name " + kv.key + " value " + kv.value);
          }
        } else {
          for (any kv in app.getKvDb(kvdb).getMap()) {
            log.log("Config name " + kv.key + " value " + kv.value);
          }
        }
      }
      if (mode == "putConfig") {
        String key = params.getFirst("key");
        String value = params.getFirst("value");
        log.log("Creating config " + key + " " + value);
        app.getKvDb(kvdb).put(key, value);
      }
      if (mode == "deleteConfig") {
        key = params.getFirst("key");
        log.log("Deleting config " + key);
        app.getKvDb(kvdb).delete(key);
      }
      if (mode == "saveLocalUrl") {
        log.log("saveLocalUrl");
        
        String intPort = app.webPort;
        
        String defadd = Net:Gateway.defaultAddress;
        Net:Interface ni = Net:Interface.new();
        defadd = ni.interfaceForNetwork(defadd).address;
        
        String iurl = app.webProto + "://" + defadd + ":" += intPort;
        File.apNew(params.getFirst("urlFile")).writer.open().write(iurl).close();
      }
      return(true);
    }
    
     changeDeviceNameRequest(String deviceName, request) {
     log.log("changing name");
      if ((def(request.context.get("account")) && request.context.get("account").isAdmin) && TS.notEmpty(name)) {
        app.plugin.deviceName = deviceName;
      }
      app.getKvDb(kvdb).put("deviceNameSetOnce", "true");
      //return(CallBackUI.setElementsDisplaysResponse(Maps.from("deviceNameDiv", "none")));
      //return(CallBackUI.reloadResponse());
      return(CallBackUI.reloadResponse());
      }
   
   showConfigRequest(Map arg, request) Map {
     Set noshow =@ Sets.from("imap.pass", "auth.sessionId", "imap.user");
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
       String conf = String.new();
       Map ecm = app.getKvDb(kvdb).getMap();
       if (ecm.isEmpty!) {
         conf += "<table>";
         for (any kv in ecm) {
           unless(kv.value.has("\"") || noshow.has(kv.key)) {
              String ckey = "configKey" + kv.key;
              conf += "<tr><td>" + kv.key + "</td><td><input type=\"text\" id=\"" + ckey + "\" value=\"" + kv.value + "\"></td><td><a href=\"#\" onclick=\"callUI('deleteConfig', '" + kv.key + "');return false;\">Delete</a></td><td><a href=\"#\" onclick=\"updateConfig('" + kv.key + "', '" + ckey + "');return false;\">Save</a></td></tr>";
            }
         }
      }
      conf += "<tr><td>Add New:&nbsp;<input type=\"text\" id=\"addConfigKeyId\" value=\"\"></td><td><a href=\"#\" onclick=\"callUI('addConfig');return false;\">+</a><input type=\"hidden\" id=\"addConfigValId\" value=\"\"></td></tr>";
      
      conf += "<tr><td><a href=\"#\" onclick=\"callApp('backupConfigRequest');return false;\">Download Configuration Backup</a></td></tr>";
      
      conf += "</table>";
       Map res = Map.new();
      res["action"] = "showConfigResponse";
      res["configs"] = conf;
      return(res);
    }
    return(null);
   }
   
   backupConfig() String {
     Map ecm = app.getKvDb(kvdb).getMap();
     if (ecm.isEmpty) {
       ecm = Map.new();
     }
     return(Json:Marshaller.marshall(ecm));
   }
   
   backupConfig(String path) {
     Path dirPath = Path.apNew(path);
     if (dirPath.parent.file.exists!) {
      dirPath.parent.file.makeDirs();
     }
     dirPath.file.contents = backupConfig();
   }
   
   backupConfigRequest(request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
       Map res = Map.new();
       res["action"] = "backupConfigResponse";
       res["configJson"] = backupConfig();
       log.log("ret configJson " + res["configJson"]);
       return(res);
     }
     return(null);
   }
   
   updateConfigRequest(Map arg, request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      log.log("update for " + arg["configKey"] + " value " + arg["configValue"]);
      app.getKvDb(kvdb).put(arg["configKey"], arg["configValue"]);
      return(showConfigRequest(arg, request));
      }
      return(null);
   }
   
   deleteConfigRequest(Map arg, request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      log.log("delete for " + arg["configKey"]);
      app.getKvDb(kvdb).delete(arg["configKey"]);
      return(showConfigRequest(arg, request));
      }
      return(null);
   }
   
  start() {
    log.log("initting managers conf");
    app.getKvDb(kvdb);
  }
    
}

use class App:LocalWebApp(WebApp) {

  new() self {
        fields {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
        }
        super.new();
    }

    main() {
    
      start();
    
      webr = WeBr.new();
      webr.webHandler = self;
      //webr.height = 450;
      //webr.width = 320;
      
      webr.height = 560;
      webr.width = 320;
      
      String mypwd = System:Environment.getVariable("MYPWD");
      ifEmit(platDroid) {
        mypwd = "android_asset";
      }
      webr.location = "file:///" + mypwd + self.plugin.homePage;
      
      webr.setup();
   }

   initWeb() {

   }

}

class App:AppStart {

  new(Parameters _params) self {
    fields {
      IO:Log log =@ IO:Logs.get(self);
      Parameters params = _params;
    }
  }
  
    main() {
      try {
        Parameters params = Parameters.new(System:Process.new().args);
        start(params);
      } catch (any e) {
        log.log("Exception in innerMain, error is " + e);
      }
    }
  
    start(Parameters params) {
      self.new(params);
      start();
    }
    
  setupPlugins(WebApp app) {
    auto pluginClasses = params.get("plugin");
    List plugins = List.new();
    for (String pluginClass in pluginClasses) {
      any plugin = createInstance(pluginClass);
      plugins += plugin;
    }
    app.plugins = plugins;
  }
  
  setupPlugin(WebApp app) {
    String pln = params.getFirst("appPlugin");
    if (def(pln)) {
      app.plugin = app.pluginsByName[pln];
    } else {
      String plc = params.getFirst("appPluginClass");
      if (undef(plc)) {
        throw(Exception.new("No app plugin defined"));
      }
      app.plugin = app.pluginsByClassName[plc];
    }
  }
  
  start() this {
    log.log("starting app");
    auto appTypes = Sets.from(params.get("appType").toList());
    if (appTypes.has("cmd")) {
      WebApp cuiapp = WebApp.new();
      cuiapp.params = params;
      setupPlugins(cuiapp);
      setupPlugin(cuiapp);
      cuiapp.main();
      cuiapp.stop();
    } else {
      if (appTypes.has("browser")) {
        LocalWebApp luiapp = LocalWebApp.new();
        luiapp.params = params;
        setupPlugins(luiapp);
        setupPlugin(luiapp);
        unless (appTypes.has("server")) {
          log.log("starting browser app");
          luiapp.main();
        }
      }
      if (appTypes.has("server")) {
        RemoteWebApp wuiapp = RemoteWebApp.new();
        wuiapp.params = params;
        setupPlugins(wuiapp);
        setupPlugin(wuiapp);
        if (appTypes.has("browser")) {
          log.log("cohosting apps");
          wuiapp.cohostWith(luiapp);
          log.log("starting server app");
          wuiapp.main();
          log.log("starting browser app");
          luiapp.main();
        } else {
          log.log("starting server app");
          wuiapp.main();
        }
      }
    }
  }
}


use App:WebApp;
class WebApp {

  new() self {
    fields {
      IO:Log log =@ IO:Logs.get(self);
      Lock lock = Lock.new();
      String certificateThumbprint;
      Map kvDbs = Map.new();
      Lock dblock = Lock.new();
      Parameters params;
    }
  }
  
  webProtoGet() String {
    if (self.doSsl) {
      return("https");
    }
    return("http");
  }
  
  appNameGet() String {
    fields {
      String appName;
    }
    if (undef(appName)) {
      if (def(params)) {
        String an = params.getFirst("appName");
      }
      if (undef(an)) {
        an = "";
      }
      appName = an;
    }
    return(appName);
  }
  
  configPrefixGet() String {
    String an = self.appName;
    if (TS.notEmpty(an)) {
      return("webApp." + an + ".");
    }
    return(an);
  }
  
   doSslGet() Bool {
      fields {
        Bool doSsl;
      }
      if (undef(doSsl)) {
        doSsls = params.getFirst("webDoSsl");
        if (TS.isEmpty(doSsls)) {
          String doSsls = self.configManager.get(self.configPrefix + "web.ssl");
          if (TS.isEmpty(doSsls)) {
            doSsls = "true";
            ifEmit(cs) {
              doSsls = "false";
            }
            self.configManager.put(self.configPrefix + "web.ssl", doSsls);
          }
        }
        doSsl = Logic:Bools.fromString(doSsls);
      }
      return(doSsl);
    }

  pluginsSet(_plugins) {
      fields {
        List plugins = _plugins;
        if (undef(plugin)) {
          any plugin = plugins.first;
        }
        Map pluginsByClassName = Map.new();
        Map pluginsByName = Map.new();
      }
      
      for (any pl in plugins) {
        pl.app = self;
        pluginsByClassName.put(pl.className, pl);
        if (pl.can("nameGet", 0)) {
          pluginsByName.put(pl.name, pl);
        }
        //("PUT PLUGIN " + pl.className).print();
      }
      
  }
  
  start() {
    self.configManagerGet();
    self.sessionManagerGet();
    for (any pl in plugins) {
      if (pl.can("start", 0)) {
        pl.start();
      }
    }
  }
  
  stop() {
    for (any pl in plugins) {
      if (pl.can("stop", 0)) {
        pl.stop();
      }
    }
    if (def(appDb)) {
      appDb.close();
      kvDbs = Map.new();
    }
  }
  
  webPortGet() String {
      fields {
        String intPort;
      }
      if (TS.isEmpty(intPort)) {
        if (def(params) && def(params.getFirst("webPort"))) {
          return(params.getFirst("webPort"));
        }
        intPort = self.configManager.get(self.configPrefix + "web.port");
        if (TS.isEmpty(intPort)) {
          Int intPorti = System:Random.getIntMax(30000);
          intPorti += 3000;
          intPort = intPorti.toString();
          self.configManager.put(self.configPrefix + "web.port", intPort);
        }
      }
      return(intPort);
    }
    
  httpBindAddressGet() String {
      fields {
        String httpBindAddress;
      }
      if (TS.isEmpty(httpBindAddress)) {
        if (def(params) && def(params.getFirst("httpBindAddress"))) {
          return(params.getFirst("httpBindAddress"));
        }
        httpBindAddress = self.configManager.get(self.configPrefix + "web.httpBindAddress");
      }
      return(httpBindAddress);
    }
  
  pathsGet() App:Paths {
    fields {
      App:Paths paths;
    }
    if (undef(paths)) {
      paths = App:Paths.new(self);
    }
    return(paths);
  }
  
  cohostWith(WebApp other) {
    other.lock = self.lock;
    other.dblock = self.dblock;
    other.kvDbs = self.kvDbs;
    other.appDb = self.appDb;
    
    other.sessionManager = self.sessionManager;
    
    for (any pl in plugins) {
      if (pl.can("cohostWith", 1)) {
        any opl = other.pluginsByName.get(pl.name);
        if (def(opl)) {
          pl.cohostWith(opl);
        }
      }
    }
  }
  
  configManagerGet() KvDb {
    return(self.getKvDb("CONFIG"));
  }
  
  appDbGet() DbDb {
    fields {
      DbDb appDb;
    }
    unless (def(appDb)) {
      Path appDbPath = self.paths.dataPath.addStep("APPDB");
      appDb = createInstance("Db:SQLite:Database");
      appDb.pathNew(appDbPath);
      appDb.open();
    }
    return(appDb);
  }
  
  getKvDb(String name) KvDb {
    try {
      lock.lock();
      KvDb kdb = kvDbs.get(name);
      if (undef(kdb)) {
        kdb = KvDb.new(self.appDb, name);
        kdb.lock = dblock;
        //kdb.open();
        kdb.create();
        kvDbs.put(name, kdb);
      }
      lock.unlock();
    } catch (any e) {
      lock.unlock();
      log.log("exception during getKvDb");
      if (def(e)) { log.log("ex " + e); }
    }
    return(kdb);
  }
  
  sessionManagerGet() Web:SessionManager {
    fields {
      Web:SessionManager sessionManager;
      String sessionId;
    }
    if (undef(sessionId)) {
      sessionId = self.configManager.get("auth.sessionId");
      if (TS.isEmpty(sessionId)) {
        sessionId = System:Random.getString(16);
        self.configManager.put("auth.sessionId", sessionId);
      }
      //log.log("sessionId " + sessionId);
    }
    if (undef(sessionManager)) {
      sessionManager = Web:SessionManager.new(self.getKvDb("SESSIONS"), "GsSess" + sessionId);
    }
    ("got sessionmanager").print();
    return(sessionManager);
  }
    
    handleWeb(request) this {
     for (any pl in plugins) {
       request.continueHandling = false;
       pl.handleWeb(request);
       unless (request.continueHandling) {
        break;
       }
     }
    }
    
    handleCmd() this {
     for (any pl in plugins) {
       if (pl.can("handleCmd", 1)) {
        if (pl.handleCmd(params)) {
          break;
        }
      }
     }
    }
    
    main() this {
      handleCmd();
      System:Process.exit(0);
    }
    
}

use class App:Background {

  new() self {
    fields {
      IO:Log log =@ IO:Logs.get(self);
      Interval startDelay = Interval.new(10, 0);
      Interval repeatDelay = Interval.new(10, 0);
      Interval minimumDelay = Interval.new(5, 0);
      Interval lastRepeat = Interval.new(0, 0);
      System:Invocation toInvoke;
      any lastError = null;
      Bool lastWasError = false;
    }
  }
  
  runMyTasks() {
    try {
      Interval now = Interval.now();
      if (now - lastRepeat >= minimumDelay) {
        lastWasError = false;
        lastRepeat = now;
        toInvoke.invoke();
      }
    } catch (any e) {
      lastWasError = true;
      lastError = e;
      try {
        log.log("exception in runMyTasks");
        if (def(e)) {
          log.log("runMyTasks exception was " + e);
        }
      } catch (any ee) { }
    }
  }
  
  main() {
    any e;
    Time:Sleep.sleep(startDelay);
    while (true) {
      try {
        runMyTasks();
      } catch (e) {
        log.log("Caught exception running tasks " + e);
      }
      try {          
        Time:Sleep.sleep(repeatDelay);
      } catch (e) {
        log.log("Caught exception sleeping " + e);
      }
    }
  }
  
  start() self {
    fields {
      System:Thread myThread;
    }
    myThread = System:Thread.new(self);
    myThread.start();
  }

}

class CallBackUI {

  default() self { }

  forwardCall(String name, List args) {
      Map retc = Map.new();
      retc["action"] = name;
      retc["args"] = args;
      return(retc);
   }

}

class App:AjaxPlugin {

   new() self {
    fields {
      any plugin = self;
      IO:Log log =@ IO:Logs.get(self);
    }
   }
   
   new(_plugin) self {
     plugin = _plugin;
     log =@ IO:Logs.get(self);
   } 
   
   prepArgs(request) {
     Map arg = request.context["arg"];
     List args = request.context["args"];
     if (undef(arg) || undef(args)) {
       String rmtd = request.inputMethod;
       if (TS.isEmpty(rmtd) || rmtd != "PUT") {
         arg = request.scriptArg;
         if (def(arg)) {
           if (arg.has("args")) {
              //is "standard call"
              args = arg["args"];
              args += request;
              //log.log("call type a " + aname + args.length);
            } else {
              //deprecate this
              args = List.new(2);
              args[0] = arg;
              args[1] = request;
              //log.log("call type b");
            }
          }
          request.context["arg"] = arg;
          request.context["args"] = args;
        }
     }
   } 
   
   handleWeb(request) this {
     try {
       prepArgs(request);
       Map arg = request.context["arg"];
       List args = request.context["args"];
       if (def(arg) && def(args)) {
         String aname = arg.get("action");
          if (plugin.can(aname, args.length) && aname.ends("Request")) {
            any res = plugin.invoke(aname, args);
            request.scriptReturn = res;
          } else {
            request.continueHandling = true;
          }
        }
      } catch (any e) {
        log.log("Caught exception handling request");
        if (log.will()) { if (undef(e)) { log.log("undefined exception") } else { log.log(e.toString()); } }
        if (e.sameClass(Alert.new()@)) {
          arg = CallBackUI.informResponse(e.description);
        } else {
          arg = CallBackUI.informResponse("Sorry, unable to handle request");
        }
        request.scriptReturn = arg;
      }
    }
}

use System:Thread:Lock;
use System:Thread:ContainerLocker as CLocker;
use System:Command as Com;
use Time:Sleep;
use System:Thread:ObjectLocker as OLocker;
use Db:HSQLDb:Database as HsDb;
use Db:Firebird:Database as FbDb;

use App:CallBackUI;
