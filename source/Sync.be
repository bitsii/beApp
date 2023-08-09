// Copyright 2015 The Bennt App Authors. All rights reserved.
// Use of this source code is governed by the BSD-3-Clause
// license that can be found in the LICENSE file.

use IO:File:Path;
use IO:File;
use System:Random;
use UI:WebBrowser as WeBr;
use Test:Assertions as Assert;
use Db:KeyValue as KvDb;
use System:Thread:Lock;
use System:Thread:ContainerLocker as CLocker;
use System:Command as Com;
use Time:Sleep;
use Container:Pair;

use App:Alert;

use System:Exceptions as E;

use App:LocalWebApp;
use App:RemoteWebApp;
use App:WebApp;
use Text:String;
use App:CallBackUI;

use App:Account;

use System:Thread:Lock;
use System:Thread:ObjectLocker as OLocker;

use System:Parameters;

use Bitsii:SyncPlugin(App:AjaxPlugin) {

  new() self {
   fields {
      Lock syncLock = Lock.new();
      any app;
      App:Background yesSync = App:Background.new();
      String appId;
      String dbName;
      String histName;
      String syncersName;
    }
    super.new();
    log = IO:Logs.get(self);
 }
 
 shrinkHist(String auser, String snh, Int keep) {
     
     auto eh = Encode:Hex.new();
     String auh = auser;
     
     auto sechis = app.kvdbs.get(histName);
     List hl = List.new();
     
     for (auto kv in sechis.getMap(auh + "!" + "EntryActive" + "!")) {
       auto tl = kv.key.split("!");
       if (tl.get(2) == snh) {
        String secs = tl.get(3);
        hl += Int.new(secs);
       }
     }
     hl = hl.sort();
     
     if (hl.size > keep) {
       Int todel = hl.size - keep;
       for (Int j = 0; j < todel;j++=) {
         String delt = auh + "!" + "EntryActive" + "!" + snh + "!" + hl.get(j).toString();
         sechis.delete(delt);
         log.log("deleted " + delt);
       }
     }
     for (Int i in hl) {
       log.log("in sh i " + i);
     }
   }
 
  syncStatusRequest(request) {
      String auser = getUser(request);
      String lss = app.configManager.get("sync." + appId + "." + auser + ".lastSuccessSeconds");
      String lastSyncStatus = app.configManager.get("sync." + appId + "." + auser + ".lastStatus");
      if (TS.isEmpty(lastSyncStatus)) {
        lastSyncStatus = "None";
      }
      if (TS.isEmpty(lss)) {
        String lastSyncMsg = "Never, is sync configured?";
      } else {
        lastSyncMsg = String.new();
        Int lt = Int.new(lss);
        Int diff = Time:Interval.now().seconds - lt;
        if (diff > 60) {
          lastSyncMsg += "Last sync was " += (diff / 60).toString() += " minutes and " += (diff % 60).toString() += " seconds ago.";
        } else {
          lastSyncMsg += "Last sync was " += diff.toString() += " seconds ago.";
        }
      }
      Map lres = Map.new();
      lres["action"] = "syncStatusResponse";
      lres["lastSyncStatus"] = lastSyncStatus;
      lres["lastSyncMsg"] = lastSyncMsg;
      return(lres);
    }
 
 nameGet() String {
       String name = "BSync";
       return(name);
     }
 
 saveSyncSecsRequest(String syncSecs, request) {
       if (Int.new(syncSecs) > 5) {
         app.configManager.put("yesSync.repeatDelay", syncSecs);
       }
     }
     
     getSyncSecsRequest(request) {
       String rd = app.configManager.get("yesSync.repeatDelay");
      
        if (TS.isEmpty(rd)) {
          rd = "25";
        }
        
        return(CallBackUI.setElementsValuesResponse(Maps.from("syncSecs", rd)));
        
     }
     
     start() {
       log.log("in sync start");
     }
     
     asyncStart() {
      log.log("in sync asyncStart start");
      app.configManager;
      
      //app.kvdbs.get(syncersName).clear();
      
      String rd = app.configManager.get("yesSync.repeatDelay");
      
      if (TS.isEmpty(rd)) {
        rd = "20";
      }
      
      yesSync.startDelay = Time:Interval.new(0, 500);
      yesSync.repeatDelay = Time:Interval.new(Int.new(rd), 0);
      yesSync.minimumDelay = Time:Interval.new(5, 0);
      yesSync.toInvoke = System:Invocation.new(self, "yesSync", List.new());
      yesSync.main();
    }
    
    yesSync() {
      log.log("in yssync");
      for (String user in getSyncers()) {
        doSync(user);
      }
    }
    
    addSyncer(String us) {
      auto syncers = app.kvdbs.get(syncersName);
      syncers.put(us, Time:Interval.now().seconds.toString());
    }
    
    getSyncers() List {
      auto syncers = app.kvdbs.get(syncersName);
      List toRet = List.new();
      for (auto le in syncers.getMap()) {
        toRet += le.key;
      }
      return(toRet);
    }
    
    getUser(request) {
      if (undef(request) || undef(request.context.get("account"))) {
        return(getAccountUser(null));
      }
      return(getAccountUser(request.context.get("account")));
    }
    
    getAccountUser(Account a) {
      if (undef(a)) {
        log.log("account missing, we'll call him bob");
        us = "bob";
      } else {
        String us = "user-" + a.user;
      }
      us = Encode:Hex.encode(us);
      //log.log("gu user is " + us);
      addSyncer(us);
      return(us);
    }
    
    syncRtrRequest(String account, String pass, request) Map {
    
    String auser = getUser(request);
    
    log.log("getting list of bridges");
    
    String destUrl = "https://www.bitsi.me";
    
    
    log.log("now link " + destUrl);
    
    Map argOut = Map.new();
    argOut["accountName"] = account;
    argOut["accountPass"] = pass;
    argOut["sessionLength"] = "30";
    argOut["action"] = "loginRequest";
    argOut["serviceLogin"] = "yup";
    
    Web:Client client = Web:Client.new();
    client.verb = "POST";
    String payload = Json:Marshaller.marshall(argOut);
    client.outputHeaders.put("referer", destUrl);
    client.url = destUrl;
    
    try {
      client.contentsOut = payload;
      String res = client.contentsIn;
      log.log("GOT SOMETHING BACK!!!");
      client.close();
      if (TS.notEmpty(res)) {
        log.log("res " + res);
        Map resMap = Json:Unmarshaller.unmarshall(res);
        //store stuff
        Map ds = Map.new();
        ds["serviceSessionKey"] = resMap["serviceSessionKey"];
        ds["pageToken"] = resMap["pageToken"];
        ds["destUrl"] = destUrl;
        ds["certificatePrint"] = resMap["certificatePrint"];
        
        
        log.log("getting bridge list");
        argOut = Map.new();
        argOut["action"] = "getSyncBlobsRequest";
        argOut["pageToken"] = ds["pageToken"];
        argOut["serviceSessionKey"] = ds["serviceSessionKey"];
        client = Web:Client.new();
        payload = Json:Marshaller.marshall(argOut);
        //log.log("payload " + payload);
        client.outputHeaders.put("referer", destUrl);
        client.url = destUrl;
        client.verb = "POST";
        client.contentsOut = payload;
        res = client.contentsIn;
        client.close();
        auto eh = Encode:Hex.new();
        if (TS.notEmpty(res)) {
          resMap = Json:Unmarshaller.unmarshall(res);
          log.log("!!! got res from getblobs  " + res);
          //?put in db? think so, one entry per name
          Map blobs = resMap.get("blobs");
          if (def(blobs) && blobs.size > 0) {
            return(CallBackUI.syncRtrResponse(blobs));
          }
          //for (auto kv in blobs) {
          //  if (TS.notEmpty(kv.key) && TS.notEmpty(kv.value)) {
          //    app.configManager.put("sync." + appId + "." + auser + ".syncHost." + eh.encode(kv.key), kv.value);
          //  }
          //}
          //then return in list also, be able to pick from theme
        }
      }
      //resetCertMan(ds["certificatePrint"]);
    } catch(any e) {
      //resetCertMan(ds["certificatePrint"]);
      throw(e);
    }
    return(CallBackUI.informResponse("called for list "));
   }
    
    unsetBridgeSyncRequest(request) {
      String auser = getUser(request);
      log.log("disabling bridge sync");
      app.configManager.delete("sync." + appId + "." + auser + ".bridgeSession");
      app.configManager.delete("sync." + appId + "." + auser + ".bridgeLastUrl");
      app.configManager.delete("sync." + appId + "." + auser + ".bridgeBlob");
    }
    
    setSyncDirRequest(String dir, request) {
      String auser = getUser(request);
      app.configManager.put("sync." + appId + "." + auser + ".dir", dir);
    }
    
    loadSyncDirRequest(request) {
      String auser = getUser(request);
      String dir = app.configManager.get("sync." + appId + "." + auser + ".dir");
      if (undef(dir)) { dir = ""; }
      return(CallBackUI.setElementsValuesResponse(Maps.from("syncDir", dir)));
    }
    
    doSync(String auser) {
      if (TS.notEmpty(auser)) {
      log.log("doing sync for " + Encode:Hex.decode(auser));
      } else {
      log.log("dosync auser empty");
      }
      try {
        syncLock.lock();
        
        String dir = app.configManager.get("sync." + appId + "." + auser + ".dir");
        ifEmit(bnbr) {
          if (TS.notEmpty(auser) && TS.isEmpty(dir)) {
            String au = Encode:Hex.decode(auser);
            Path sd = Path.apNew("Home").addStep(au.substring(5, au.size)).addStep(appId);
            dir = sd.toString();
            log.log("generated dir for sync " + dir);
          }
        }
        
        String blob = app.configManager.get("sync." + appId + "." + auser + ".bridgeBlob");
        String dss = app.configManager.get("sync." + appId + "." + auser + ".bridgeSession");
        String destUrl = app.configManager.get("sync." + appId + "." + auser + ".bridgeLastUrl");
        
        Map decids;
        if (TS.isEmpty(blob) && TS.notEmpty(dir)) {
          log.log("syncing for dir " + dir);
          Path dirp = Path.apNew(dir);
          decids = doSyncInFiles(dirp, auser);
          doSyncOutFiles(dirp, auser, decids);
        }
        
        if (TS.notEmpty(blob) && TS.notEmpty(dss) && TS.notEmpty(destUrl)) {
          log.log("syncing for bridge " + destUrl);
          decids = doSyncInBridge(auser, blob, dss, destUrl);
          destUrl = app.configManager.get("sync." + appId + "." + auser + ".bridgeLastUrl");
          doSyncOutBridge(auser, blob, dss, destUrl, decids);
        }
        
        syncLock.unlock();
      } catch (any e) {
        syncLock.unlock();
        log.log(E.tS(e));
      }
    }
    
    decideIn(String auser, List subs) Map {
      auto unmar = Json:Unmarshaller.new();
      auto eh = Encode:Hex.new();
      auto seckv = app.kvdbs.get(dbName);
      auto sechis = app.kvdbs.get(histName);
      String an = auser;
      String auh = an;
      Map acts = Map.new();
      for (String sub in subs) {
        //log.log("sub " + sub);
        auto sl = sub.split(" ");
        String snh = sl.get(1);
        Int updateSecs = Int.new(sl.get(2));
        String subp = sl.get(0);
        
        String docName = eh.decode(snh);
        
        //log.log("read in " + docName + " " + subp + " " + updateSecs);
        
        String pkap = auh + "!EntryActive!" + snh + "!";
        String pkdp = auh + "!EntryDeleted!" + snh + "!";
        
        Int maxSecs = 0;
        Map cands = seckv.getMap(pkap);
        cands += seckv.getMap(pkdp);
        for (auto kv in cands) {
          //log.log("got cand " + kv.key);
          auto sll = kv.key.split("!");
          Int secs = Int.new(sll.get(3));
          if (secs > maxSecs) {
            maxSecs = secs;
          }
        }
        
        delete = true;
        //log.log("incoming secs for " + docName + " " + updateSecs + " max existing " + maxSecs);
        if (updateSecs > maxSecs) {
          log.log("will import");
          load = true;
        } else {
          //log.log("not import");
          Bool load = false;
          if (updateSecs == maxSecs) {
            Bool delete = false;
          }
        }
        String act = "none";
        if (load) {
          act = "load";
        } elseIf (delete) {
          act = "delete";
        }
        acts.put(sub, act);
      }
      return(acts);
    }
    
    deleteOthers(String pk) {
     log.log("deleteOthers " + pk);
     auto sl = pk.split("!");
     auto seckv = app.kvdbs.get(dbName);
     List todel = List.new();
     Map cands = seckv.getMap(sl.get(0) + "!EntryActive!" + sl.get(2) + "!");
     cands += seckv.getMap(sl.get(0) + "!EntryDeleted!" + sl.get(2) + "!");
     for (auto kv in cands) {
       //log.log("got cand " + kv.key);
       if (kv.key != pk) {
         todel += kv.key;
       }
     }
     for (String ktd in todel) {
       log.log("deleting " + ktd);
       seckv.delete(ktd);
     }
   }
    
    doSyncInBridge(String auser, String blob, String dss, String destUrl) {
      Map ds = Json:Unmarshaller.unmarshall(dss);
      auto eh = Encode:Hex.new();
      Map wcm = Json:Unmarshaller.unmarshall(blob);
      String an = auser;
      String auh = an;
      auto seckv = app.kvdbs.get(dbName);
      auto sechis = app.kvdbs.get(histName);
      auto unmar = Json:Unmarshaller.new();
      
      //hostedUrl, konnUrl, konniUrl, externalUrl, internalUrl
      List destUrls = Lists.from(destUrl, wcm["hostedBase"], wcm["konnBase"], wcm["konniBase"]);
      
      if (TS.isEmpty(appId)) {
        throw(Alert.new("no syncstep"));
      }
      
      for (destUrl in destUrls) {
        if (TS.notEmpty(destUrl)) {
          //log.log("trying destUrl " + destUrl);
          
          try {
            auto argOut = Map.new();
            
            argOut["action"] = "listRequest";
            argOut["pageToken"] = ds["pageToken"];
            argOut["serviceSessionKey"] = ds["serviceSessionKey"];
            argOut["homeRelPath"] = appId;
            auto client = Web:Client.new();
            client.connectTimeoutMillis = 10000;
            client.readTimeoutMillis = 60000;
            auto payload = Json:Marshaller.marshall(argOut);
            client.verb = "POST";
            //log.log("payload " + payload);
            client.outputHeaders.put("referer", destUrl + "/App/SBridge/SBridge.html");
            client.url = destUrl;
            client.contentsOut = payload;
            String res = client.contentsIn;
            client.close();
            if (TS.notEmpty(res)) {
              Map resMap = Json:Unmarshaller.unmarshall(res);
              //log.log("!!! got res from getSip  " + res);
              app.configManager.put("sync." + appId + "." + auser + ".bridgeLastUrl", destUrl);
              app.configManager.put("sync." + appId + "." + auser + ".lastSuccessSeconds", Time:Interval.now().seconds.toString());
              app.configManager.put("sync." + appId + "." + auser + ".lastStatus", "OK");
              break;
            }
         } catch (any e) {
           log.log("list failed");
           app.configManager.put("sync." + appId + "." + auser + ".lastStatus", "Failed");
           if (def(e)) { log.log(e.toString()); }
         }
        }
      }
      
      if (resMap.has("path")) {
        String path = resMap["path"];
        app.configManager.put("sync." + appId + "." + auser + ".bridgeSyncPath", path);
        app.configManager.put("sync." + appId + "." + auser + ".bridgeLastUrl", destUrl);
        if (resMap.has("list")) {
          List list = resMap["list"];
          List sublist = List.new();
          for (String le in list) {
            Path p = Path.apNew(le);
            String fn = p.steps.last;
            if (p.toString().ends(".json")) {
              String n = p.steps.last;
              String sub = eh.decode(n.split(".").get(0));
              sublist += sub;
            }
          }
          Map decids = decideIn(auser, sublist);
          Path dirp = Path.apNew(path);
          for (auto kv in decids) {
            if (kv.value != "none") {
              n = eh.encode(kv.key) + ".json";
              p = dirp.copy().addStep(n);
              if (kv.value == "load") {
              
                auto sl = kv.key.split(" ");
                String snh = sl.get(1);
                Int updateSecs = Int.new(sl.get(2));
                String subp = sl.get(0);
              
                //String outers = p.file.reader.open().readStringClose();
                
                argOut["action"] = "smallGetRequest";
                argOut["pageToken"] = ds["pageToken"];
                argOut["serviceSessionKey"] = ds["serviceSessionKey"];
                argOut["path"] = p.toString();
                client = Web:Client.new();
                client.connectTimeoutMillis = 10000;
                client.readTimeoutMillis = 60000;
                payload = Json:Marshaller.marshall(argOut);
                //log.log("payload " + payload);
                client.outputHeaders.put("referer", destUrl + "/App/SBridge/SBridge.html");
                client.url = destUrl;
                client.verb = "POST";
                client.contentsOut = payload;
                res = client.contentsIn;
                client.close();
                
                if (TS.notEmpty(res)) {
                  Map resm = unmar.unmarshall(res);
                  if (resm.has("content")) {
                    String outers = resm["content"];
                    String pk = auh + "!" + subp + "!" + snh + "!" + updateSecs;
                    seckv.put(pk, outers);
                    deleteOthers(pk);
                    sechis.put(auh + "!" + "EntryActive" + "!" + snh + "!" + updateSecs, outers);
                    shrinkHist(auser, snh, 10);
                  }
                }
              } else {
                if (kv.value == "delete") {
                  log.log("delete");
                  //NEED TO CALL AND DELETE IT this doesn't work
                  //p.file.delete();
                  
                argOut["action"] = "deleteRequest";
                argOut["pageToken"] = ds["pageToken"];
                argOut["serviceSessionKey"] = ds["serviceSessionKey"];
                argOut["path"] = p.toString();
                client = Web:Client.new();
                client.connectTimeoutMillis = 10000;
                client.readTimeoutMillis = 60000;
                payload = Json:Marshaller.marshall(argOut);
                //log.log("payload " + payload);
                client.outputHeaders.put("referer", destUrl + "/App/SBridge/SBridge.html");
                client.url = destUrl;
                client.verb = "POST";
                client.contentsOut = payload;
                res = client.contentsIn;
                client.close();
                  
                } else {
                  log.log("not delete");
                }
              }
            }
          }
          
          return(decids);
        }
      }
      return(Map.new());
    }
    
    doSyncInFiles(Path dirp, String auser) Map {
      if (dirp.file.exists!) { return(Map.new()); }
      app.configManager.put("sync." + appId + "." + auser + ".lastSuccessSeconds", Time:Interval.now().seconds.toString());
      app.configManager.put("sync." + appId + "." + auser + ".lastStatus", "OK");
      String an = auser;
      auto unmar = Json:Unmarshaller.new();
      auto eh = Encode:Hex.new();
      auto seckv = app.kvdbs.get(dbName);
      auto sechis = app.kvdbs.get(histName);
      String auh = an;
      List sublist = List.new();
      for (File f in dirp.file) {
        Path p = f.path;
        log.log("found path " + p);
        if (p.toString().ends(".json")) {
          String n = p.steps.last;
          String sub = eh.decode(n.split(".").get(0));
          log.log("sub " + sub);
          sublist += sub;
        }
      }
      Map decids = decideIn(auser, sublist);
      for (auto kv in decids) {
        try {
          if (kv.value != "none") {
            n = eh.encode(kv.key) + ".json";
            p = dirp.copy().addStep(n);
            if (kv.value == "load") {
            
              auto sl = kv.key.split(" ");
              String snh = sl.get(1);
              Int updateSecs = Int.new(sl.get(2));
              String subp = sl.get(0);
            
              String outers = p.file.reader.open().readStringClose();
              String pk = auh + "!" + subp + "!" + snh + "!" + updateSecs;
              seckv.put(pk, outers);
              deleteOthers(pk);
              sechis.put(auh + "!" + "EntryActive" + "!" + snh + "!" + updateSecs, outers);
              shrinkHist(auser, snh, 10);
            } else {
              if (kv.value == "delete") {
                log.log("delete");
                p.file.delete();
              } else {
                log.log("not delete");
              }
            }
          }
        } catch (any ee) {
          log.elog("except in sync for item", ee);
        }
      }
      return(decids);
    }
    
    doSyncOutFiles(Path dirp, String auser, Map decids) {
      if (dirp.file.exists!) { dirp.file.makeDirs(); }
      auto eh = Encode:Hex.new();
      String auh = auser;
      auto unmar = Json:Unmarshaller.new();
      for (auto kv in app.kvdbs.get(dbName).getMap(auh + "!")) {
        try {
          String outers = kv.value;
          Map outer = unmar.unmarshall(outers);
          String fn = eh.encode(outer["subject"]) + ".json";
          Path fp = dirp.copy().addStep(fn);
          unless (decids.has(outer["subject"])) {
            log.log("outputting for " + outer["subject"]);
            fp.file.writer.open().writeStringClose(outers);
          } else {
            //log.log("not outputting for " + outer["subject"]);
          }
        } catch (any ee) {
          log.elog("except in sync for item", ee);
        }
      }
    }
    
    doSyncOutBridge(String auser, String blob, String dss, String destUrl, Map decids) {
      //if (dirp.file.exists!) { dirp.file.makeDirs(); }
      auto eh = Encode:Hex.new();
      String auh = auser;
      auto unmar = Json:Unmarshaller.new();
      auto mar = Json:Marshaller.new();
      String path = app.configManager.get("sync." + appId + "." + auser + ".bridgeSyncPath");      
      Map ds = unmar.unmarshall(dss);
      Map wcm = unmar.unmarshall(blob);
      Path dirp = Path.apNew(path);
      //log.log("in do sync out bridge for auh " + auh);
      for (auto kv in app.kvdbs.get(dbName).getMap(auh + "!")) {
        //log.log("in do sync out bridge for key " + kv.key);
        String outers = kv.value;
        Map outer = unmar.unmarshall(outers);
        String fn = eh.encode(outer["subject"]) + ".json";
        Path fp = dirp.copy().addStep(fn);
        unless (decids.has(outer["subject"])) {
          log.log("outputting for " + outer["subject"]);
          //fp.file.writer.open().writeStringClose(outers);
      
          if (TS.notEmpty(destUrl)) {
            //log.log("trying destUrl " + destUrl);
            
            try {
              auto argOut = Map.new();
              argOut["action"] = "smallPutRequest";
              argOut["pageToken"] = ds["pageToken"];
              argOut["serviceSessionKey"] = ds["serviceSessionKey"];
              argOut["path"] = fp.toString();
              argOut["content"] = outers;
              auto client = Web:Client.new();
              client.connectTimeoutMillis = 10000;
              client.readTimeoutMillis = 60000;
              auto payload = mar.marshall(argOut);
              log.log("sync write url " + destUrl + " payload " + payload);
              client.outputHeaders.put("referer", destUrl + "/App/SBridge/SBridge.html");
              client.url = destUrl;
              client.verb = "POST";
              client.contentsOut = payload;
              String res = client.contentsIn;
              client.close();
              if (TS.notEmpty(res)) {
                Map resMap = Json:Unmarshaller.unmarshall(res);
                //log.log("!!! got res from getSip  " + res);
              }
           } catch (any e) {
             log.log("put failed");
             if (def(e)) { log.log(e.toString()); }
           }
          }
            
          
        } else {
          //log.log("not outputting for " + outer["subject"]);
        }
      }
    }
    
    setBridgeSyncRequest(String addr, String user, String pass, request) Map {
      String auser = getUser(request);
      List args = Lists.from(addr, user, pass, auser);
      app.runAsync("BSync", "setBridgeSyncRequestInner", args);
      return(null);
    }
    
    setBridgeSyncRequestInner(String addr, String user, String pass, String auser) Map {
      app.plugin.prepBsync();
      if (TS.notEmpty(addr) && addr.begins("https://")!) {
        addr = "https://" + addr;
      }
      if (TS.notEmpty(addr) && TS.notEmpty(user) && TS.notEmpty(pass)) {
        auto ll = addr.split("/");
        //log.log("splits " + ll.size);
        Int si = 0;
        String na = "";
        for (auto s in ll) {
          //log.log("s " + s);
          if (si < 3) {
            na += s;
            if (si < 2) {
              na += "/";
            }
          }
          si++=;
        }
        //log.log("na " + na);
        //return(null);
        addr = na;
        log.log("setBridgeSyncRequest " + addr + " user " + user);
        
        //if (true) { return(null); }
        
        //String auser = getUser(request);
        //app.configManager.put("sync." + appId + "." + auser + ".bridgeBlob", blob);
        //Map wcm = Json:Unmarshaller.unmarshall(blob);
        
        //hostedUrl, konnUrl, konniUrl, externalUrl, internalUrl
        //List destUrls = Lists.from(wcm["hostedUrl"], wcm["konnUrl"], wcm["konniUrl"], wcm["externalUrl"], wcm["internalUrl"]);
        
        //List destUrls = Lists.from(wcm["hostedBase"], wcm["konnBase"], wcm["konniBase"]);
        List destUrls = List.new().addValue(addr);
        
        for (String destUrl in destUrls) {
          if (TS.notEmpty(destUrl)) {
            //log.log("trying destUrl " + destUrl);
            Map argOut = Map.new();
            argOut["accountName"] = user;
            argOut["accountPass"] = pass;
            argOut["sessionLength"] = "-1";
            argOut["action"] = "loginRequest";
            argOut["serviceLogin"] = "yup";
            
            Web:Client client = Web:Client.new();
            client.verb = "POST";
            client.connectTimeoutMillis = 10000;
            client.readTimeoutMillis = 60000;
            String payload = Json:Marshaller.marshall(argOut);
            client.outputHeaders.put("referer", destUrl + "/App/SBridge/SBridge.html");
            client.url = destUrl;
            
            try {
              client.verb = "POST";
              client.contentsOut = payload;
              String res = client.contentsIn;
              log.log("GOT SOMETHING BACK!!!");
              client.close();
              if (TS.notEmpty(res)) {
                log.log("res " + res);
                Map resMap = Json:Unmarshaller.unmarshall(res);
                Map ds = Map.new();
                ds["serviceSessionKey"] = resMap["serviceSessionKey"];
                ds["pageToken"] = resMap["pageToken"];
                
                String dss = Json:Marshaller.marshall(ds);
                log.log("login for sldss " + dss);
                app.configManager.put("sync." + appId + "." + auser + ".bridgeSession", dss);
                app.configManager.put("sync." + appId + "." + auser + ".bridgeLastUrl", destUrl);
                
                client = Web:Client.new();
                client.verb = "POST";
                client.connectTimeoutMillis = 10000;
                client.readTimeoutMillis = 60000;
                payload = Json:Marshaller.marshall(argOut);
                client.outputHeaders.put("referer", destUrl + "/App/SBridge/SBridge.html");
                client.url = destUrl;
                
                argOut = Map.new();
                argOut["action"] = "getSyncBlobRequest";
                argOut["pageToken"] = ds["pageToken"];
                argOut["serviceSessionKey"] = ds["serviceSessionKey"];
                payload = Json:Marshaller.marshall(argOut);
                client.verb = "POST";
                client.contentsOut = payload;
                res = client.contentsIn;
                log.log("GOT SOMETHING BACK AGAIN!!!");
                client.close();
                if (TS.notEmpty(res)) {
                  log.log("res again " + res);
                  resMap = Json:Unmarshaller.unmarshall(res);
                  app.configManager.put("sync." + appId + "." + auser + ".bridgeBlob", resMap.get("blob"));
                }
                //break;
              }
            } catch(any e) {
              log.error("Failure during set bridge sync will try others");
              if (def(e)) {
                log.error("error " + e);
              }
            }
          }
        }
        doSync(auser);
      }
      return(null);
    }

}
