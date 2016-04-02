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

//logic
use class App:AccountManager {

  new() self {
    properties {
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
    String aj = kvDb.get(prefix + user);
    if (TS.notEmpty(aj)) {
      Account a = Account.mapNew(unmar.unmarshall(aj));
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
    properties {
      Set perms = Set.new();
    }
  }

  new(String _user, String _hashPass, String _salt, String _permsString) self {
    new();
    properties {
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
    if (_pass == pass) {
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
  
  default() {
    properties {
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
    properties {
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
