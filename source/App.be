// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use Text:String;
use Logic:Bool;
use Math:Int;
use System:Exception;
use Container:Array;
use Container:Map;
use Container:Set;
use Container:LinkedList;
use Container:Queue;
use IO:File:Path;
use IO:File;
use System:Random;
use Text:Strings as TS;
use UI:WebBrowser as WeBr;
use Test:Assertions as Assert;
use Db:Relational:Database as DbDb;
use Db:Relational:Statement as DbSt;
use Db:Firebird:Database as FbDb;
use Db:Derby:Database as Derby;
use Db:KeyValue as KvDb;

use class App:Alert(Exception) { }

use class App:Paths {

  dataPathGet() Path {
    ifEmit(platDroid) {
      var app = createInstance("UI:JvAd:WebBrowser");
      dbp = Path.apNew(app.appDataDir).addStep("BeData");
    }
    ifNotEmit(platDroid) {
      Path dbp = Path.apNew("Data");
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
      foreach (String s in res.biter) {
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
      var kvDb;
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
  
  getLogins() Array {
    Array logins = Array.new();
    foreach (var kv in kvDb.getMap(prefix)) {
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
      foreach (String perm in permsString.split(",")) {
        perms.put(perm);
      }
    }
  }
  
  permsStringGet() String {
    Bool first = true;
    String permsString = "";
    foreach (String perm in perms) {
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
        be.BEL_4_Base.BEL_4_Base.main(margs);
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
    new BEC_4_6_TextString(event)
    );
    } catch (Throwable t) {
        System.err.println("failed in handleEvent " + t.getMessage());
        throw new Error(t.getMessage(), t);
    }
  }
  """
  }

  put(String label, var handler) {
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
    var rc = registry.get(event);
    if (def(rc)) {
      Array args = Array.new(0);
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
    bevl_res = new BEC_4_6_TextString(res);
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
    bevl_res = new BEC_4_6_TextString(res);
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
    bevl_res = new BEC_4_6_TextString(res);
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
    bevl_res = new BEC_4_6_TextString(res);
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
          var app;
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
   
   loadAccountRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = app.accountManager.getAccount(arg["accountName"]);
      if (def(a)) {
        Map res = Map.new();
        res["action"] = "loadAccountResponse";
        res["accountName"] = a.user;
        res["admin"] = a.perms.has("admin");
        return(res);
      } elif (true) {
        throw(Alert.new("No such account"));
      }
      return(null);
   }
   
   showAccountAdminRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      String accountLinks = String.new();
      Array logins = app.accountManager.getLogins();
      foreach (String login in logins) {
        accountLinks += "<p><a href=\"#\" onclick=\"loadAccountRequest('" += login += "');return false;\">Modify " += login += "</a></p>";
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
          var app;
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
         var dpath = Path.apNew(arg["toName"]);
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
        dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(app.getHomeDir(request).toString()) += "');return false;\">HOME</a></td></tr>";
        dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(dirFile.path.toString()) += "');return false;\">.  (REFRESH)</a></td></tr>";
        IO:File:Path parent = dirFile.path.parent;
        if (def(parent) && TS.notEmpty(parent.toString())) {
        dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(parent.toString()) += "');return false;\">.. (UP)</a></td></tr>";
        }
        if (dirFile.isDir) {
          var dit = dirFile.iterator;
          dit.open();
          Array olist = Array.new();
          Map omap = Map.new();
          while (dit.hasNext) {
            File entry = dit.next;
            Path p = entry.path;
            olist += p.steps.last;
            omap.put(p.steps.last, entry);
          }
          olist = olist.sort();
          foreach (String ole in olist) {
            entry = omap.get(ole);
            p = entry.path;
            if (entry.isDirectory) {
              dirListHtml += "<tr>";
              dirListHtml += "<td>DIR</td><td><a href=" + TS.quote + "#" + TS.quote + " onclick=\"localBrowseRequest('"
          += hex.encode(p.toString()) += "');return false;\">" += htmle.encode(p.name) += "</a></td>";
              dirListHtml += "</tr>";   
            } else {
              if (p.toString().ends(".jpg")) {
                String jscall = " onclick=\"localBrowseRequest('" += hex.encode(p.toString()) += "');return false;\"";
              } else {
                jscall = "";
              }
              dirListHtml += "<tr>";
              dirListHtml += "<td>FILE</td><td><a href=" += TS.quote += "../../" += urle.encode(p.toString()) += TS.quote + jscall + ">" += htmle.encode(p.name) += "</a></td><td>" += entry.size += "</td>";
              dirListHtml += "<td><input type=\"checkbox\" id=\"FCB"
              += hex.encode(p.toString()) += "\" onclick=\"fileChecked(this);\"\"></td>";
              dirListHtml += "</tr>";
            }
          }
          dit.close();
        } elif (dirFile.path.toString().ends(".jpg")) {
          Map res = Map.new();
          res["action"] = "updateImageResponse";
          res["imghtm"] = "<img src=\"../../" + dirFile.path.toStringWithSeparator("/") + "?cbust=" + Time:Interval.now().seconds + System:Random.getString(6) + "\" >";
          return(res);
        }
        dirListHtml += "</table>";
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
          var app;
          String name = "Conf";
        }
        
     }
   
   showConfigRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
       String conf = String.new();
       Map ecm = app.configManager.getMap();
       if (ecm.isEmpty!) {
         conf += "<table>";
         foreach (var kv in ecm) {
           unless(kv.value.has("\"")) {
              String ckey = "configKey" + kv.key;
              conf += "<tr><td>" + kv.key + "</td><td><input type=\"text\" id=\"" + ckey + "\" value=\"" + kv.value + "\"></td><td><a href=\"#\" onclick=\"eui.bem_deleteConfig_1(new be_BEL_4_Base_BEC_4_6_TextString().bems_new('" + kv.key + "'));return false;\">Delete</a></td><td><a href=\"#\" onclick=\"updateConfig('" + kv.key + "', '" + ckey + "');return false;\">Save</a></td></tr>";
            }
         }
      }
      conf += "<tr><td>Add New:&nbsp;<input type=\"text\" id=\"addConfigKeyId\" value=\"\"></td><td><a href=\"#\" onclick=\"eui.bem_addConfig_0();return false;\">+</a><input type=\"hidden\" id=\"addConfigValId\" value=\"\"></td></tr>";
      conf += "</table>";
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
