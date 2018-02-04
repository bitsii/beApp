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
use Text:String;
use App:CallBackUI;

use System:Thread:Lock;
use System:Thread:ObjectLocker as OLocker;

use Crypto:Symmetric as Crypt;

use System:Parameters;

use class Draftii:DraftiiPlugin(App:AjaxPlugin) {

     new() self {
       fields {
          any app;
          any oapp;
          String name = "Draftii";
          String homePage = "/App/Draftii/Draftii.html";
          String lastSalt;
          Map passHashes = Map.new();
        }
        super.new();
        log =@ IO:Logs.get(self);
        ifEmit(iuDebug) {
          IO:Logs.turnOnAll();
        }
     }
               
     cohostWith(Draftii:DraftiiPlugin ohp) {
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
      lastSalt = app.configManager.get("dr.lastSalt");
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
      if (pas.begins(adz.toString()) && (pas.ends(".html") || pas.ends(".js") || pas.ends(".svg") || pas.ends(".txt") || pas.ends(".css") || pas.ends(".jpg") || pas.ends(".eot") || pas.ends(".ttf") || pas.ends("woff"))) {
        return(true);
      }
      return(false);
   }
   
   getLoginUri(request) String {
     String loginBookmark = "/App/IUHub/Draftii.html";
     return(loginBookmark);
   }
   
   handleWeb(request) this {
       String rmtd = request.inputMethod;
       log.log("san rmtd is " + rmtd);
       if (TS.isEmpty(rmtd) || rmtd == "GET") {
         log.log("method is get");
         String uri = request.uri;
         log.log("san uri " + uri);
         if (uri.begins("/App/Draftii/Something/")) {
           log.log("got something");
           //doSomething(uri, request);
         }
       } else {
         super.handleWeb(request);
       }
  }
  
   draftManagerGet() KvDb {
    return(app.getKvDb("DRAFTS"));
  }
  
  catManagerGet() KvDb {
    //app.getKvDb("SECRETS").drop();
    return(app.getKvDb("CATS"));
  }
  
  getPass1(String salt, String pass1) {
    Digest:SHA256 ds = Digest:SHA256.new();
    pass1 = salt + pass1;
    for (Int i = 0;i < 3;i++=) {
      pass1 = ds.digest(pass1);
    }
    pass1 = Encode:Hex.encode(pass1);
    return(pass1);
  }
  
  getPass2(String pass1) {
    Digest:SHA256 ds = Digest:SHA256.new();
    String pass2 = pass1;
    for (Int i = 0;i < 3;i++=) {
      pass2 = ds.digest(pass2);
    }
    pass2 = Encode:Hex.encode(pass2);
    return(pass2);
  }
  
  saveDraftRequest(String oldSubject, String subject, String body, String create, String update, String seq, String salt, String passHash, String pass1, String pass2, request) Map {
     log.log("saveDraftRequest called");
     
     if (TS.isEmpty(subject)) {
      throw(Alert.new("Subject cannot be empty..."));
     }
     
     KvDb dm = self.draftManager;
     
     log.log("Draft is subject: " + subject + " body: " + body);
     
     String now = Time:Interval.now().seconds.toString();
     
     if (TS.isEmpty(create)) {
      create = now;
     }
     update = now;
     if (TS.isEmpty(seq)) {
      seq = "0";
     } else {
      seq = (Int.new(seq) + 1).toString();
     }
     
     if (TS.notEmpty(passHash) || TS.notEmpty(pass1)) {
      if (TS.notEmpty(pass1) || TS.isEmpty(salt)) {
        salt = lastSalt;
        if (TS.isEmpty(salt)) {
          salt = System:Random.getString(16);
          lastSalt = salt;
          app.configManager.put("dr.lastSalt", lastSalt);
        }
      }
      if (TS.notEmpty(pass1)) {
        if (TS.isEmpty(pass2) || pass1 != pass2) {
          throw(Alert.new("Passwords don't match"));
        }
        pass1 = getPass1(salt, pass1);
        pass2 = getPass2(pass1);
        passHashes.put(pass2, pass1);
      } else {
        pass2 = passHash;
        pass1 = passHashes.get(pass2);
        if (TS.isEmpty(pass1)) {
          throw(Alert.new("No ph to use"));
        }
      }
      body = Crypt.encryptPassToHex(pass1, pass1.substring(8), body);
     }
     
     Map dr = Maps.from("subject", subject, "body", body, "create", create, "update", update, "seq", seq, "salt", salt, "passHash", pass2);
     
     String drjs = Json:Marshaller.marshall(dr);
     
     log.log("saving " + subject + " : " + drjs);
     
     dm.put(subject, drjs);
     
     if (TS.notEmpty(oldSubject) && oldSubject != subject) {
       dm.delete(oldSubject);
     }
     
     return(CallBackUI.informResponse("Saved"));
     
   }
   
   deleteDraftRequest(String oldSubject, String subject, request) Map {
     log.log("deleteDraftRequest called");
     
     if (TS.isEmpty(subject)) {
      throw(Alert.new("Subject cannot be empty..."));
     }
     
     KvDb dm = self.draftManager;
     
     log.log("Draft is subject: " + subject);
     
     if (TS.notEmpty(oldSubject) && oldSubject != subject) {
       dm.delete(oldSubject);
     }
     dm.delete(subject);
     
     return(CallBackUI.informResponse("Draft deleted.  Hit \"Save\" to undo, or \"Close\" to exit."));
     
   }
   
   loadDraftRequest(String subject, String pass, request) Map {
      log.log("in load draft");
      Encode:Hex hex = Encode:Hex.new();
      String drjs = self.draftManager.get(hex.decode(subject));
      if (TS.notEmpty(drjs)) {
        Map draft = Json:Unmarshaller.unmarshall(drjs);
      } else {
        throw(Alert.new("Draft missing, may have been renamed, refresh list?"));
      }
      
      if (TS.notEmpty(draft.get("passHash"))) {
        log.log("have a passHash in load");
        String pass1 = passHashes.get(draft.get("passHash"));
        if (TS.isEmpty(pass1)) {
          log.log("need to look for pass in request, and if not there prompt for pass");
          if (TS.notEmpty(pass)) {
            pass1 = getPass1(draft.get("salt"), pass);
            String pass2 = getPass2(pass1);
            if (pass2 != draft.get("passHash")) {
              log.log("pass looks bad from passHash");
              throw(Alert.new("Password Incorrect"));
              //pass1 = null;
            } else {
              passHashes.put(pass2, pass1);
            }
          }
        }
        if (TS.isEmpty(pass1)) {
          return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsDisplaysResponse(Maps.from("loadPassDiv", "block")),CallBackUI.setElementsValuesResponse(Maps.from("loadSubject", subject)))));
        }
        if (TS.notEmpty(draft.get("body"))) {
          draft.put("body", Crypt.decryptPassFromHex(pass1, pass1.substring(8), draft.get("body")));
        }
      }
      return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsDisplaysResponse(Maps.from("dComposeDiv", "block", "dListDiv", "none", "informDiv", "none")), CallBackUI.setElementsValuesResponse(Maps.from("sdSubject", draft.get("subject"), "sdBody",draft.get("body"), "sdOldSubject",draft.get("subject"), "sdCreate", draft.get("create"), "sdUpdate", draft.get("update"), "sdSeq", draft.get("seq"), "sdSalt", draft.get("salt"), "sdPassHash", draft.get("passHash"))))));
   
   }
   
   getDraftListRequest(String search, request) Map {
     return(doList(search, false, request));
   }
   
   getDraftListRequest(request) Map {
     return(doList(null, false, request));
   }
   
   closeDraftRequest(String search, request) Map {
    return(doList(search, true, request));
   }
   
   doList(String search, Bool force, request) Map {
     log.log("in getDraftListRequest");
     
     if (TS.notEmpty(search)) {
       Bool doSearch = true;
       search = search.upper();
     } else {
       doSearch = false;
     }
     
     String draftList = String.new();
     draftList += "<p><a href=\"#\" onclick=\"callUI('toggleDisplay','dComposeDiv');callUI('toggleDisplay','dListDiv');document.getElementById('sdOldSubject').value = '';document.getElementById('sdSubject').value = '';document.getElementById('sdBody').value = '';document.getElementById('sdCreate').value = '';document.getElementById('sdUpdate').value = '';document.getElementById('sdSeq').value = '';document.getElementById('sdSalt').value = '';document.getElementById('sdPassHash').value = '';document.getElementById('passEnter1').value = '';document.getElementById('passEnter2').value = '';document.getElementById('informDiv').style.display='none';return false;\"><i>New Draft</i></a></p>";
     draftList += "<p><a href=\"#\" onclick=\"callApp('getDraftListRequest', document.getElementById('dlSearch').value);return false;\"><i>Refresh Draft List</i></a></p>";
     Bool hadDraft = false;
     Encode:Hex hex = Encode:Hex.new();
     
     for (auto kv in self.draftManager.getMap()) {
       //todo escape
       hadDraft = true;
       Bool include = true;
       if (doSearch) {
         unless (kv.key.upper().has(search)) {
           include = false;
         }
       }
       if (include) {
        draftList += "<p><a href=\"#\" onclick=\"document.getElementById('loadPassDiv').style.display = 'none';callApp('loadDraftRequest', '" += hex.encode(kv.key) += "', document.getElementById('loadPassEnter').value);document.getElementById('loadPassEnter').value = '';document.getElementById('loadSubject').value = '';return false;\">" += kv.key += "</a></p>";
       }
     }
     if (hadDraft || force) {
      return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsInnerHTMLResponse(Maps.from("dListHDiv",draftList)),CallBackUI.setElementsDisplaysResponse(Maps.from("dComposeDiv", "none", "dListDiv", "block", "informDiv", "none")))));
     } else {
      return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsDisplaysResponse(Maps.from("dComposeDiv", "block")), CallBackUI.setElementsDisplaysResponse(Maps.from("dListDiv", "none", "informDiv", "none")))));
     }
   }
   
   saveImapSettingsRequest(String imapChosen, String imapAccount, String imapPass1, String imapPass2, String imapEndpoint, String imapFolder, request) Map {
     if (TS.notEmpty(imapChosen) && imapChosen.ends("Disable")) {
      app.configManager.put("dr.imapSyncEnabled", "false");
      app.configManager.put("dr.imapChosen", imapChosen);
     } else {
   
       if (TS.isEmpty(imapPass1) || TS.isEmpty(imapPass2) || imapPass1 != imapPass2) {
        throw(Alert.new("Passwords missing or do not match"));
       }
       if (TS.isEmpty(imapAccount) || TS.isEmpty(imapEndpoint) || TS.isEmpty(imapFolder)) {
        throw(Alert.new("Email, endpoint, and folder are required"));
       }
       
       app.configManager.put("dr.imapSyncEnabled", "true");
       
       app.configManager.put("dr.imapChosen", imapChosen);
       app.configManager.put("dr.imapAccount", imapAccount);
       app.configManager.put("dr.imapPass", imapPass1);
       app.configManager.put("dr.imapEndpoint", imapEndpoint);
       app.configManager.put("dr.imapFolder", imapFolder);
       
       
     }
     
     return(CallBackUI.toggleDivCIResponse("imapSettingsDiv"));
   }
   
}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;

