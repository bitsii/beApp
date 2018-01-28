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
  
  saveDraftRequest(String oldSubject, String subject, String body, request) Map {
     log.log("saveDraftRequest called");
     
     if (TS.isEmpty(subject)) {
      throw(Alert.new("Subject cannot be empty..."));
     }
     
     KvDb dm = self.draftManager;
     
     log.log("Draft is subject: " + subject + " body: " + body);
     
     Map dr = Maps.from("subject", subject, "body", body);
     
     String drjs = Json:Marshaller.marshall(dr);
     
     log.log("saving " + subject + " : " + drjs);
     
     dm.put(subject, drjs);
     
     if (TS.notEmpty(oldSubject) && oldSubject != subject) {
       dm.delete(oldSubject);
     }
     
     return(CallBackUI.informResponse("Saved"));
     
     //String emailC = Crypt.encryptPassToHex(veriKey, veriKey.substring(8), email);
      //return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsInnerHTMLResponse(Maps.from("sendLinkMessageDiv", "Verification request sent, please check your email.")), CallBackUI.setElementsDisplaysResponse(Maps.from("sendLinkMessageDiv", "block")))));
      
      //return(null);
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
   
   loadDraftRequest(String subject, request) Map {
      log.log("in load draft");
      Encode:Hex hex = Encode:Hex.new();
      String drjs = self.draftManager.get(hex.decode(subject));
      if (TS.notEmpty(drjs)) {
        Map draft = Json:Unmarshaller.unmarshall(drjs);
      } else {
        throw(Alert.new("Draft missing, may have been renamed, refresh list?"));
      }
      return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsDisplaysResponse(Maps.from("dComposeDiv", "block", "dListDiv", "none")), CallBackUI.setElementsValuesResponse(Maps.from("sdSubject", draft.get("subject"), "sdBody",draft.get("body"), "sdOldSubject",draft.get("subject"))))));
   
   }
   
   getDraftListRequest(String search, request) Map {
     return(doList(search, false, request));
   }
   
   getDraftListRequest(request) Map {
     return(doList(null, false, request));
   }
   
   closeDraftRequest(request) Map {
    return(doList(null, true, request));
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
     draftList += "<p><a href=\"#\" onclick=\"callUI('toggleDisplay','dComposeDiv');callUI('toggleDisplay','dListDiv');document.getElementById('sdOldSubject').value = '';document.getElementById('sdSubject').value = '';document.getElementById('sdBody').value = '';document.getElementById('informDiv').style.display='none';return false;\"><i>New Draft</i></a></p>";
     draftList += "<p><a href=\"#\" onclick=\"callApp('getDraftListRequest');return false;\"><i>Refresh Draft List</i></a></p>";
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
        draftList += "<p><a href=\"#\" onclick=\"callApp('loadDraftRequest', '" += hex.encode(kv.key) += "');return false;\">" += kv.key += "</a></p>";
       }
     }
     if (hadDraft || force) {
      return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsInnerHTMLResponse(Maps.from("dListHDiv",draftList)),CallBackUI.setElementsDisplaysResponse(Maps.from("dComposeDiv", "none", "dListDiv", "block")))));
     } else {
      return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsDisplaysResponse(Maps.from("dComposeDiv", "block")), CallBackUI.setElementsDisplaysResponse(Maps.from("dListDiv", "none")))));
     }
   }
   
}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;

