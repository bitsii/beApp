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
use Db:Derby:Database as Derby;
use Db:KeyValue as KvDb;

use class App:Alert(Exception) { }

use class App:Paths {

  new(_app) self {
    fields {
      any app = _app;
      String name = app.plugin.name;
    }
  }

  dataPathGet() Path {
    ifEmit(platDroid) {
      any app = createInstance("UI:JvAd:WebBrowser");
      dbp = Path.apNew(app.appDataDir).addStep("BeData").addStep(name);
    }
    ifNotEmit(platDroid) {
      Path dbp = Path.apNew("Data").addStep(name);
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
    
    //log.log(lvl, "netstat output " + res);
    
    if (System:CurrentPlatform.name == "mswin") {
      Int fz = res.find("0.0.0.0"); //win
    } else {
      fz = 0;
    }
    if (def(fz)) {
      Int fz2 = res.find("0.0.0.0", fz + 1);
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
    return(accum);
  }

}

//logic
use class App:AccountManager {

  new() self {
    fields {
      any kvDb;
      String prefix;
      Json:Marshaller mar = Json:Marshaller.new();
      Json:Unmarshaller unmar = Json:Unmarshaller.new();
    }
  }
  
  new(_kvDb, _prefix) {
    new();
    kvDb = _kvDb;
    prefix = _prefix;
  }
  
  getLogins() List {
    List logins = List.new();
    for (any kv in kvDb.getMap(prefix)) {
      logins.addValue(kv.key.substring(prefix.size));
    }
    return(logins);
  }

  getAccount(String user) {
    if (TS.notEmpty(user)) {
		String aj = kvDb.get(prefix + user);
		if (TS.notEmpty(aj)) {
		  Account a = Account.mapNew(unmar.unmarshall(aj));
		}
	}
    return(a);
  }
  
  deleteAccount(Account a) {
    kvDb.delete(prefix + a.user);
  }
  
  putAccount(Account a) {
    kvDb.put(prefix + a.user, mar.marshall(a.toMap()));
  }
  
  getAccountForRequest(request) Account {
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
        be.BEL_4_Base.main(margs);
    } catch (Throwable t) {
        System.err.println("Failed in main with " + t.getMessage());
        throw new Error(t.getMessage(), t);
    }
    haveRun = true;
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
        
    bevs_inst.bem_handleEvent_1(
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

use class App:AuthPlugin {

     new() self {
       fields {
          IO:Log log = IO:Log.new();
          log.level = log.info;
          Int lvl = log.level;
          any app;
          String name = "Auth";
        }
        
     }
     
    clearAllSessionsRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        log.log(lvl, "Clearing all sessions request by login " + app.accountManager.getAccountForRequest(request).user);
        app.sessionManager.sessions.clear();
     }
     return(null);
   }
   
   clearAllTrackingRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        log.log(lvl, "Clearing all tracking requested by login "  + app.accountManager.getAccountForRequest(request).user);
        app.trackingManager.clear();
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
      Account a = app.accountManager.getAccountForRequest(request);
      unless (TS.notEmpty(arg["newPass"]) && a.checkPass(arg["oldPass"])) {
        log.log(lvl, "incorrect old pass");
        throw(Alert.new("Old password incorrect"));
      }
      a.pass = arg["newPass"];
      app.accountManager.putAccount(a);
   }
   
   loadAccountRequest(String accountName, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = app.accountManager.getAccount(accountName);
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
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      String accountLinks = String.new();
      List logins = app.accountManager.getLogins();
      for (String login in logins) {
        accountLinks += "<p><a href=\"#\" onclick=\"callApp('loadAccountRequest', '" += login += "');return false;\">Modify " += login += "</a></p>";
      }
      Map res = Map.new();
      res["action"] = "showAccountAdminResponse";
      res["accountLinks"] = accountLinks;
      return(res);
   }
   
   deleteAccountRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = app.accountManager.getAccount(arg["accountName"]);
      if (def(a)) {
        if (a.user == app.accountManager.getAccountForRequest(request).user) {
          throw(Alert.new("Cannot delete own account"));
        }
      }
      app.accountManager.deleteAccount(a);
      return(showAccountAdminRequest(arg, request));
  }
      
   saveAccountRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = app.accountManager.getAccount(arg["accountName"]);
      if (undef(a)) {
        log.log(lvl, arg["accountName"] + " not found, creating new");
        a = Account.new();
        a.user = arg["accountName"];
      } else {
        if (a.user == app.accountManager.getAccountForRequest(request).user) {
          throw(Alert.new("Cannot change own account"));
        }
        log.log(lvl, arg["accountName"] + " found, use existing");
      }
      if (TS.notEmpty(arg["accountPass"])) {
        log.log(lvl, "pass set, changing");
        a.pass = arg["accountPass"];
      }
      if (arg["admin"]) {
        a.perms.put("admin");
      } else {
        a.perms.delete("admin");
      }
      app.accountManager.putAccount(a);
   }
   
   showSessionsRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
      Map res = Map.new();
      res["action"] = "showSessionsResponse";
      res["sessionsList"] = app.getSessionsForAccount(a);
      return(res);
   }
   
   checkLoggedInRequest(Map arg, request) {
    String accountName = request.getSession("account.name");
    if (TS.notEmpty(accountName)) {
      Account a = app.accountManager.getAccount(accountName);
      if (def(a)) {
        log.log(lvl, "Found logged in account " + accountName);
        Map res = Map.new();
        res["action"] = "loggedInResponse";
        res["name"] = accountName;
        return(app.loggedIn(a, res, arg, request));
      } else {
        log.log(lvl, "No such account " + accountName);
      }
    }
    return(logoutRequest(arg, request));
  }

  loginRequest(Map arg, request) {
    Account a = app.accountManager.getAccount(arg["accountName"]);
    if (def(a) && app.preLoginCheck(request)) {
      log.log(lvl, "Found account " + arg["accountName"]);
      if (a.checkPass(arg["accountPass"])) {
        log.log(lvl, "Login ok");
        request.putSession("account.name", arg["accountName"]);
        request.putSession("ip", request.remoteAddress);
        if (TS.notEmpty(arg["sessionName"])) {
          request.putSession("session.name", arg["sessionName"]);
        }
        Map res = Map.new();
        res["action"] = "loggedInResponse";
        res["name"] = arg["accountName"];
        app.goodLogin(request);
        return(app.loggedIn(a, res, arg, request));
      } else {
        log.log(lvl, "Login notok");
        app.badLogin(request);
      }
    } else {
      log.log(lvl, "No such account " + arg["accountName"]);
      app.badLogin(request);
    }
    return(logoutRequest(arg, request));
  }
  
  logoutRequest(Map arg, request) {
    //log.log(lvl, "logging out");
    request.deleteSession();
    Map res = Map.new();
    res["action"] = "logoutResponse";
    //log.log(lvl, "logged out, returning");
    return(res);
  }
   
}

use class App:FileManagerPlugin {

     new() self {
       fields {
          IO:Log log = IO:Log.new();
          log.level = log.info;
          Int lvl = log.level;
          any app;
          String name = "FileManager";
        }
        
     }
     
     deleteRequest(Map arg, request) Map {
     log.log(lvl, "del request");
     String path = arg["path"];
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
     if (TS.notEmpty(path)) {
       File dirFile = File.apNew(Encode:Hex.new().decode(path));
       if (dirFile.exists && app.checkWritePath(dirFile.path, request)) {
         log.log(lvl, "deleting " + dirFile.path);
         dirFile.delete();
       }
     }
     return(null);
   }
   
   copyRequest(Map arg, request) Map {
     log.log(lvl, "copy request");
     String path = arg["path"];
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
     if (TS.notEmpty(path)) {
       File dirFile = File.apNew(Encode:Hex.new().decode(path));
       if (TS.notEmpty(arg["toName"]) && dirFile.exists && app.checkWritePath(dirFile.path, request)) {
         any dpath = Path.apNew(arg["toName"]);
         dpath = dirFile.path.parent.copy() + dpath;
         log.log(lvl, "precheck write " + dpath);
         if (app.checkWritePath(dpath, request)) {
           log.log(lvl, "copying " + dirFile.path + " to " + dpath);
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
   
   localBrowseRequest(Map arg, request) Map {
     log.log(lvl, "in local browse req");
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
      Encode:Hex hex = Encode:Hex.new();
      Encode:Url urle = Encode:Url.new();
      Encode:Html htmle = Encode:Html.new();
      Map ret = Map.new();
      String path = arg["path"];
      Account a = app.accountManager.getAccountForRequest(request);
      Bool adminLinks = false;
      if (a.perms.has("admin")) {
        adminLinks = true;
      }
      if (TS.isEmpty(path)) {
        dirFile = app.getHomeDir(request).file;
        if (dirFile.exists!) {
          dirFile.makeDirs();
        }
      } else {
        File dirFile = File.apNew(hex.decode(path));
      }
      String dirListHtml = String.new();
      dirListHtml += "<input type=\"hidden\" id=\"browsingDirId\" value=\"" += hex.encode(dirFile.path.toString()) += "\"/>";
      if (dirFile.exists && app.checkReadPath(dirFile.path, request)) {
        dirListHtml += "<p>Listing for " += htmle.encode(dirFile.path.toString()) += "</p>";
        dirListHtml += "";
        if (adminLinks) {
          if (System:CurrentPlatform.name == "mswin") {
            dirListHtml += "<p>DIR <a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode("\\") += "');return false;\">ROOT</a>";
          } else {
            dirListHtml += "<p>DIR <a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode("/") += "');return false;\">ROOT</a>";
          }
          dirListHtml += "<p>DIR <a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(".") += "');return false;\">APPDIR</a>";
        }
        dirListHtml += "<p>DIR <a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(app.getHomeDir(request).toString()) += "');return false;\">HOME</a>";
        dirListHtml += "<p>DIR <a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(dirFile.path.toString()) += "');return false;\">.  (REFRESH)</a>";
        IO:File:Path parent = dirFile.path.parent;
        if (def(parent) && TS.notEmpty(parent.toString())) {
        dirListHtml += "<p>DIR <a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(parent.toString()) += "');return false;\">.. (UP)</a>";
        }
        if (dirFile.isDir) {
          any dit = dirFile.iterator;
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
              dirListHtml += "<p>";
              dirListHtml += "DIR <a href=" + TS.quote + "#" + TS.quote + " onclick=\"localBrowseRequest('"
          += hex.encode(p.toString()) += "');return false;\">" += htmle.encode(p.name) += "</a>";
              dirListHtml += "";   
            } else {
              if (p.toString().ends(".jpg")) {
                String jscall = " onclick=\"localBrowseRequest('" += hex.encode(p.toString()) += "');return false;\"";
              } else {
                jscall = "";
              }
              dirListHtml += "<p>";
              dirListHtml += "FILE <a href=" += TS.quote += "../../" += urle.encode(p.toString()) += TS.quote + jscall + ">" += htmle.encode(p.name) += "</a> " += entry.size += "";
              dirListHtml += " <input type=\"checkbox\" id=\"FCB"
              += hex.encode(p.toString()) += "\" onclick=\"fileChecked(this);\"\">";
              dirListHtml += "";
            }
          }
          dit.close();
        } elseIf (dirFile.path.toString().ends(".jpg")) {
          Map res = Map.new();
          res["action"] = "updateImageResponse";
          res["imghtm"] = "<img src=\"../../" + dirFile.path.toStringWithSeparator("/") + "?cbust=" + Time:Interval.now().seconds + System:Random.getString(6) + "\" >";
          return(res);
        }
        dirListHtml += "";
      }
      ret.put("action", "localBrowseResponse");
      ret.put("dirListHtml", dirListHtml);
      return(ret);
    }
   
}

use class App:ConfigPlugin {

     new() self {
       fields {
          IO:Log log = IO:Log.new();
          log.level = log.info;
          Int lvl = log.level;
          any app;
          String name = "Conf";
        }
        
     }
   
   showConfigRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
       String conf = String.new();
       Map ecm = app.configManager.getMap();
       if (ecm.isEmpty!) {
         conf += "";
         for (any kv in ecm) {
           unless(kv.value.has("\"")) {
              String ckey = "configKey" + kv.key;
              conf += "<p>" + kv.key + " <input type=\"text\" id=\"" + ckey + "\" value=\"" + kv.value + "\"> <a href=\"#\" onclick=\"ui.bem_deleteConfig_1(new be_BEC_2_4_6_TextString().bems_new('" + kv.key + "'));return false;\">Delete</a> <a href=\"#\" onclick=\"updateConfig('" + kv.key + "', '" + ckey + "');return false;\">Save</a>";
            }
         }
      }
      conf += "<p>Add New: <input type=\"text\" id=\"addConfigKeyId\" value=\"\"> <a href=\"#\" onclick=\"ui.bem_addConfig_0();return false;\">+</a> <input type=\"hidden\" id=\"addConfigValId\" value=\"\">";
      conf += "";
       Map res = Map.new();
      res["action"] = "showConfigResponse";
      res["configs"] = conf;
      return(res);
    }
    return(null);
   }
   
   updateConfigRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
      log.log(lvl, "update for " + arg["configKey"] + " value " + arg["configValue"]);
      app.configManager.put(arg["configKey"], arg["configValue"]);
      return(showConfigRequest(arg, request));
      }
      return(null);
   }
   
   deleteConfigRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
      log.log(lvl, "delete for " + arg["configKey"]);
      app.configManager.delete(arg["configKey"]);
      return(showConfigRequest(arg, request));
      }
      return(null);
   }
    
}

use class App:AuthenticatedLocalApp(AuthedApp) {

  new(_plugins, log, lvl) self {
        fields {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
        }
        super.new(_plugins, log, lvl);
    }

    main() {
      webr = WeBr.new();
      webr.webHandler = self;
      webr.height = 450;
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

   handleWeb(request) {
     
     Map arg = request.scriptArg;
     return(super.handleWeb(request, arg));
   }

}

use App:AuthenticatedApp as AuthedApp;
class AuthedApp {

  new(_plugins, _log, _lvl) self {
      fields {
        List plugins = _plugins;
        any plugin = plugins.first;
        IO:Log log = _log;
        Int lvl = _lvl;
        Lock lock = Lock.new();
        OLocker lastLoginBad = OLocker.new(false);
        String certificateThumbprint;
      }
      
      for (any pl in plugins) {
        pl.app = self;
        pl.log = log;
        pl.lvl = lvl;
        if (pl.can("start", 0)) {
          pl.start();
        }
      }
      
  }
  
  badRequest(request) {
  
  }
  
  checkRequest(request) Bool {
  
    Int maxBad =@ 40;
    Int clearSecs =@ 40;
    Int updateSecs =@ 20;
  
  /*
    Int maxBad =@ 5;
    Int clearSecs =@ 10;
    Int updateSecs =@ 5;
  */
  
    /*
    log.log(lvl, "checking origins");
    String org = request.getInputHeader("origin");
    String ref = request.getInputHeader("referer");
    String uri = request.uri;
    String la = request.localAddress;
    String ra = request.remoteAddress;
    if (true) {
      if (def(org)) {
        log.log(lvl, "orgin " + org);
      }
      if (def(ref)) {
        log.log(lvl, "referer " + ref);
      }
      if (def(uri) && def(la) && def(ra)) {
        log.log(lvl, "uri, la, ra " + uri + " " + la + " " + ra);
      }
    }
    */
    
    String ip = request.remoteAddress;
    String sip = request.getSession("ip");
    String accountName = request.getSession("account.name");
    if (TS.notEmpty(ip) && TS.notEmpty(sip) && TS.notEmpty(accountName)) {
      if (ip == sip) {
        return(true);
      }
    }
    
    Int ns = Time:Interval.now().seconds;
    
    if (TS.notEmpty(ip)) {
      String ct = self.trackingManager.get("IP." + ip);
      if (TS.notEmpty(ct)) {
        String ltm = self.trackingManager.get("LB." + ip);
        if (TS.notEmpty(ltm)) {
          Int ltmi = Int.new(ltm);
          if (ns - ltmi > clearSecs) {
            log.log(lvl, "clear bad " + ip);
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
      log.log(lvl, "toomany bad " + ip);
      if (def(ltmi) && ns - ltmi > updateSecs) {
        log.log(lvl, "lp update");
        self.trackingManager.put("LB." + ip, ns.toString());
      } else {
        log.log(lvl, "no update");
      }
      return(false);
    }
    if (TS.isEmpty(accountName)) {
      log.log(lvl, "upping bad");
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
  
  isCrossSite(request) Bool {
    fields {
      String extUrl;
    }
    String ref = request.getInputHeader("referer");
    String la = request.localAddress;
    if (TS.isEmpty(ref) || TS.isEmpty(la)) {
    //  log.log(lvl, "isCrossSite true empty");
      return(true);
    }
    la = "https://" + la;
    if (ref.begins(la)) {
    //  log.log(lvl, "isCrossSite false begins " + la + " " + ref);
      return(false);
    }
    if (TS.notEmpty(extUrl) && ref.begins(extUrl)) {
    //  log.log(lvl, "isCrossSite false extUrl begins " + extUrl + " " + ref);
      return(false);
    }
    String extAddress = self.configManager.get("upnp.extAddress");
    String extPort = self.configManager.get("wui.extPort");
    if (TS.notEmpty(extAddress) && TS.notEmpty(extPort)) {
      extUrl = "https://" + extAddress + ":" + extPort;
    //  log.log(lvl, "new extUrl " + extUrl);
    } else {
    //  log.log(lvl, "extAddress or extPort empty");
      if (TS.isEmpty(extAddress)) { log.log(lvl, "extAddress empty"); }
      if (TS.isEmpty(extPort)) { log.log(lvl, "extPort empty"); }
    }
    if (TS.notEmpty(extUrl) && ref.begins(extUrl)) {
    //  log.log(lvl, "isCrossSite false new extUrl begins " + extUrl + " " + ref);
      return(false);
    }
    //log.log(lvl, "isCrossSite true not begins " + la + " " + ref);
    return(true);
  }
  
  checkWritePath(Path p, request) Bool {
    if (isCrossSite(request)) {
      return(false);
    }
    Account a = self.accountManager.getAccountForRequest(request);
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
      log.log(lvl, "Path " + p + " accountName " + accountName + " excepted in checkPath " + e);
    }
    //log.log(lvl, "checkPath isOk " + isOk);
    return(isOk);
   }
   
   checkReadPath(Path p, request) Bool {
    Path pa = p.file.absPath;
    String pas = pa.toString();
    if (self.plugin.checkPublicReadPath(pa, request)) {
        return(true);
    }
    if (isCrossSite(request)) {
      return(false);
    }
    Account a = self.accountManager.getAccountForRequest(request);
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
      log.log(lvl, "Path " + p + " accountName " + accountName + " excepted in checkPath " + e);
    }
    //log.log(lvl, "checkPath isOk " + isOk);
    return(isOk);
   }
  
  requestFromAdmin(request) Bool {
    Account a = self.accountManager.getAccountForRequest(request);
    if (def(a) && a.perms.has("admin")) {
      return(true);
    }
    badRequest(request);
    return(false);
  }
  
  preLoginCheck(request) Bool {
    if (lastLoginBad.o) {
      Int slptime = System:Random.getInt(Int.new(), 500);
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
  
  webPortGet() String {
      fields {
        String intPort;
      }
      if (TS.isEmpty(intPort)) {
        intPort = self.configManager.get("wui.port");
        if (TS.isEmpty(intPort)) {
          Int intPorti = System:Random.getInt(Int.new(), 6000);
          intPorti += 3000;
          intPort = intPorti.toString();
          self.configManager.put("wui.port", intPort);
        }
      }
      return(intPort);
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
  
  configManagerGet() CLocker {
    fields {
      CLocker configManager;
    }
    if (undef(configManager)) {
      Path db = self.paths.dataPath.addStep("CONFDB");
      //KvDb configManagerKv = KvDb.new(Derby.pathNew(db), "CONFIG");
      KvDb configManagerKv = KvDb.new(HsDb.pathNew(db), "CONFIG");
      configManagerKv.createOpen();
      configManager = CLocker.new(configManagerKv);
    }
    return(configManager);
  }
  
  sessionManagerGet() Web:SessionManager {
    fields {
      Web:SessionManager sessionDb;
      String sessionId;
    }
    if (undef(sessionId)) {
      sessionId = self.configManager.get("auth.sessionId");
      if (TS.isEmpty(sessionId)) {
        sessionId = System:Random.getString(16);
        self.configManager.put("auth.sessionId", sessionId);
      }
    }
    if (undef(sessionDb)) {
      Path db = self.paths.dataPath.addStep("SESSDB");
      //KvDb sessionDbKv = KvDb.new(Derby.pathNew(db), "SESSIONS");
      KvDb sessionDbKv = KvDb.new(HsDb.pathNew(db), "SESSIONS");
      sessionDbKv.createOpen();
      sessionDb = Web:SessionManager.new(CLocker.new(sessionDbKv), "GsSess" + sessionId);
    }
    ("got sessionmanager").print();
    return(sessionDb);
  }
  
  getSessionsForAccount(Account a) String {
    //a.user
    String res = String.new();
    String accountName = a.user;
    Map all = self.sessionManager.sessions.getMap();
    for (any kv in all) {
      if (kv.key.ends("account.name") && kv.value == accountName) {
        //log.log(lvl, "Found session " + kv.key);
        any kp = kv.key.split(".");
        String sessLabel = String.new();
        String name = self.sessionManager.sessions.get(kp.first + ".session.name");
        if (def(name)) {
          log.log(lvl, "sess name " + name);
          sessLabel += "Session named " += name;
        }
        String ip = self.sessionManager.sessions.get(kp.first + ".ip");
        if (def(ip)) {
          log.log(lvl, "sess ip " + ip);
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
  
  trackingManagerGet() CLocker {
    fields {
      CLocker trackingManager;
    }
    if (undef(trackingManager)) {
      Path db = self.paths.dataPath.addStep("TMDB");
      KvDb trackingManagerKv = KvDb.new(HsDb.pathNew(db), "TRACKING");
      trackingManagerKv.createOpen();
      trackingManager = CLocker.new(trackingManagerKv);
    }
    return(trackingManager);
  }
  
  handleWeb(request, Map arg) {
    unless (checkRequest(request)) {
      return(null);
     }
        try {
            if (isCrossSite(request)) {
              log.log(lvl, "rejecting cross site request");
              return(null);
            }
            String aname = arg.get("action");
            if (undef(aname) || aname.ends("Request")!) {
              throw(Exception.new("Invalid request"));
            }
            String accountName = request.getSession("account.name");
            if (TS.isEmpty(accountName)) {
              unless (aname == "loginRequest") {
                return(null);
              }
            } else {
            
              //checkLoggedInRequest is ok
               
              String stok = request.getSession("pageToken");
              String atok = arg["pageToken"];
              unless (aname == "checkLoggedInRequest" && TS.isEmpty(atok)) {
                if (TS.isEmpty(stok) || TS.isEmpty(atok)) {
                  log.log(lvl, "stok or atok emtpy failing due to pageToken");
                  return(null);
                }
                if (stok != atok) {
                  log.log(lvl, "stok != atok failing due to pageToken");
                  return(null);
                }
              }
            
              //log.log(lvl, "pageToken action " + aname);
              //if (def(arg["pageToken"])) { log.log(lvl, "pageToken " + //arg["pageToken"]); } else { log.log(lvl, "no pageToken"); }
              //if (def(stok)) { log.log(lvl, "session pageToken " + stok); }
            }
            log.log(lvl, "here");
            if (arg.has("args")) {
              //is "standard call"
              args = arg["args"];
              args += request;
              //log.log(lvl, "call type a " + aname + args.length);
            } else {
              List args = List.new(2);
              args[0] = arg;
              args[1] = request;
              //log.log(lvl, "call type b");
            }
            for (any pl in plugins) {
              if (pl.can(aname, args.length)) {
                any res = pl.invoke(aname, args);
                break;
              }
            }
            request.scriptReturn = res;
        } catch (any e) {
           arg = Map.new();
           log.log(lvl, "Caught exception during handleWeb B");
           if (def(e)) {
            log.log(lvl, "Error was " + e);
           }
            arg["action"] = "failResponse";
            if (e.sameClass(Alert.new()@)) {
              arg["reason"] = e.description;
            } else {
              arg["reason"] = "Sorry, unable to handle request";
            }
            request.scriptReturn = arg;
        }
    }
    
    getHomeDir(request) Path {
      String accountName = request.getSession("account.name");
      Path homeDir = Path.apNew("Home/" + accountName);
      return(homeDir);
    }
    
    accountManagerGet() AccountManager {
      fields {
        AccountManager am;
      }
      if (undef(am)) {
        am = AccountManager.new(self.configManager, "ACCOUNTS.");
      }
      return(am);
    }
    
    loggedIn(Account a, Map res, Map arg, request) {
      String pageToken = System:Random.getString(32);
      request.putSession("pageToken", pageToken);
      res["pageToken"] = pageToken;
      return(self.plugin.loggedIn(a, res, arg, request));
    }
    
}

class CallBackUI {

  forwardCall(System:ForwardCall fcall) {
      //fcall.name.print();
      //fcall.args.length.print(); //list
      //make a map, name action, args args
   }

}

use System:Thread:Lock;
use System:Thread:ContainerLocker as CLocker;
use System:Command as Com;
use Time:Sleep;
use System:Thread:ObjectLocker as OLocker;
use Db:HSQLDb:Database as HsDb;

use local App:CallBackUI;

