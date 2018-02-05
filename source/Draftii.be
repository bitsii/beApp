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

emit(jv) {
"""
import javax.activation.DataHandler;
import java.util.Properties;
import javax.mail.Session;
import javax.mail.Store;
import javax.mail.Folder;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.InternetAddress;
import javax.mail.Transport;
import javax.mail.Message;
import javax.activation.FileDataSource;
import javax.mail.Multipart;
import javax.activation.DataSource;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMultipart;
import javax.mail.BodyPart;
import javax.mail.Flags.Flag;
"""
}

use class Draftii:DraftiiPlugin(App:AjaxPlugin) {

     new() self {
       fields {
          any app;
          any oapp;
          String name = "Draftii";
          String homePage = "/App/Draftii/Draftii.html";
          String lastSalt;
          Map passHashes = Map.new();
          App:Background imapSyncer = App:Background.new();
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
      
      lastSalt = app.configManager.get("dr.lastSalt");
      
      imapSyncer.startDelay = Time:Interval.new(3, 0);
      imapSyncer.repeatDelay = Time:Interval.new(180, 0);
      imapSyncer.minimumDelay = Time:Interval.new(120, 0);
      imapSyncer.toInvoke = getInvocation("doImapSync", List.new());
      imapSyncer.start();
    }
    
    doImapSync() this {
      log.log("in imapSync");
      any e;
      try {
    
        String imse = app.configManager.get("dr.imapSyncEnabled");
        if (TS.isEmpty(imse) || imse == "false") {
          log.log("sync disabled");
          return(self);
        }
       
        String imapAccount = app.configManager.get("dr.imapAccount");
        String imapPass = app.configManager.get("dr.imapPass");
        String imapEndpoint = app.configManager.get("dr.imapEndpoint");
        String imapFolder = app.configManager.get("dr.imapFolder");
    
        String prot = "imaps";
        
        log.log("In doimap2");
        
        //Map dr = Maps.from("subject", subject, "body", body, "create", create, "update", update, "seq", seq, "salt", salt, "passHash", pass2);
        
        Map locSubTs = Map.new();
        Map remSubTs = Map.new();
        Set getSubs = Set.new();
        Set putSubs = Set.new();
        
        Map drafts = self.draftManager.getMap();
        
        for (auto kv in drafts) {
          Map draft = Json:Unmarshaller.unmarshall(kv.value);
          unless (locSubTs.has(draft.get("subject")) && locSubTs.get(draft.get("subject")) > draft.get("update")) {
            locSubTs.put(draft.get("subject"), draft.get("update"));
          }
        }
        
        List contents = List.new();
        
        emit(jv) {
        """
        Properties props = new Properties();
        props.setProperty("mail.store.protocol", bevl_prot.bems_toJvString());
        Session session = Session.getDefaultInstance(props, null);
        Store store = session.getStore(bevl_prot.bems_toJvString());
        if (!store.isConnected()) {
          store.connect(bevl_imapEndpoint.bems_toJvString(), bevl_imapAccount.bems_toJvString(), bevl_imapPass.bems_toJvString());
        }
        Folder f = store.getFolder("Inbox");
        if (bevl_imapFolder != null) {
          Folder f2 = f.getFolder(bevl_imapFolder.bems_toJvString());
          if (!f2.exists()) {
            f2.create(Folder.HOLDS_MESSAGES);
          }
          f = f2;
        }
        f.open(Folder.READ_WRITE);
          
        Message[] messages = f.getMessages();
        if (messages != null) {
          for(int i = 0; i < messages.length; i++)
          {
            //String subj = messages[i].getSubject();
            Object con = messages[i].getContent();
            if (con != null) {
              String mc = con.toString();
              if (mc != null) {
                //System.out.println("mc " + mc);
                bevl_contents.bem_addValue_1(new $class/Text:String$(mc));
              }
            }
          }
        }
    """
    }
    log.log("Done with imap read");
    
    //foreach in imsubs split add to remts map
    
    //iterate tsmaps and add to sets
    //Map locSubTs = Map.new();
    //Map remSubTs = Map.new();
    //Set getSubs = Set.new();
    //Set putSubs = Set.new();
    
    for (kv in locSubTs) {
      if (remSubTs.has(kv.key)! || kv.value > remSubTs.get(kv.key)) {
        putSubs += kv.key;
      }
    }
    
    for (kv in remSubTs) {
      if (locSubTs.has(kv.key)! || kv.value > locSubTs.get(kv.key)) {
        getSubs += kv.key;
      }
    }
    
    //load from then send to based on set contents
    
    //load from
    //for delete, can only load when the existing one is 
    
    //send to
    for (String ps in putSubs) {
      log.log("got push subject " + ps);
      
      String draftcnt = Encode:Hex.encode(drafts.get(ps));
      
      draft = Json:Unmarshaller.unmarshall(drafts.get(ps));
      
      unless (draft.get("isDeleted")) {
        Path bodyPath = self.draftPath.copy().addStep(draft.get("bodyId") + ".txt");
        String bodyPathS = bodyPath.toString();
      } else {
        bodyPathS = null;
      }
      
    emit(jv) {
    """
    MimeMessage m = new MimeMessage(session);
    //String cs = bevl_subj.bems_toJvString();
    //m.setSubject(cs);
    MimeBodyPart messageBodyPart = new MimeBodyPart();
    //m.setText(bevl_draftcnt.bems_toJvString(), "utf-8", "plain");
    messageBodyPart.setText(bevl_draftcnt.bems_toJvString(), "utf-8", "plain");
    MimeMultipart multipart = new MimeMultipart();

     multipart.addBodyPart(messageBodyPart);

     messageBodyPart = new MimeBodyPart();
     String filename = bevl_bodyPathS.bems_toJvString();
     DataSource source = new FileDataSource(filename);
     messageBodyPart.setDataHandler(new DataHandler(source));
     messageBodyPart.setFileName(filename);
     multipart.addBodyPart(messageBodyPart);

     m.setContent(multipart);
    
    m.setFlag(Flag.DRAFT, true);
    Message ms[] = {m};
    f.appendMessages(ms);
    """
    }
    
    
    }
    
    
    //delete any duplicates from the remote (get a list of subs not the latest, deletem)
    //two pass
    
    //close up
    emit(jv) {
    """
    f.close(true);
    store.close();
    """
    }
    
    } catch (e) {
      if(def(e)) {
        log.log("Exception during imap update " + e);
      } else {
        log.log("Exception during imap update null");
      }
    }
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
  
  draftPathGet() Path {
    Path confp = Path.apNew(app.paths.dataPath.toString() + "/Drafts/");
    return(confp);
  }
  
  saveDraftRequest(String oldSubject, String subject, String body, String bodyId, String create, String update, String seq, String salt, String passHash, String pass1, String pass2, request) Map {
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
     
     Path dp = self.draftPath;
     if (dp.file.exists!) {
      dp.file.mkdirs();
     }
     
     if (TS.isEmpty(bodyId)) {
       bodyId = System:Random.getString(24);
       Path bodyPath = dp.copy().addStep(bodyId + ".txt");
       while (bodyPath.file.exists) {
         bodyId = System:Random.getString(24);
         bodyPath = dp.copy().addStep(bodyId + ".txt");
       }
     }
     
     log.log("bodyId " + bodyId);
     bodyPath = dp.copy().addStep(bodyId + ".txt");
     
     Map dr = Maps.from("subject", subject, "bodyId", bodyId, "create", create, "update", update, "seq", seq, "salt", salt, "passHash", pass2, "isDeleted", false);
     
     String drjs = Json:Marshaller.marshall(dr);
     
     log.log("saving " + subject + " : " + drjs);
     
     dm.put(subject, drjs);
     
     log.log("writing " + bodyPath);
     
     bodyPath.file.writer.open().writeStringClose(body);
     
     if (TS.notEmpty(oldSubject) && oldSubject != subject) {
       Map drd = Maps.from("subject", oldSubject, "create", now, "update", now, "isDeleted", true);
       dm.put(oldSubject, Json:Marshaller.marshall(drd));
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
     
     String drjs = self.draftManager.get(subject);
     if (TS.notEmpty(drjs)) {
        Map draft = Json:Unmarshaller.unmarshall(drjs);
      } else {
        throw(Alert.new("Draft missing, may have been renamed, refresh list?"));
      }
     
     Path dp = self.draftPath;
     Path bodyPath = dp.copy().addStep(draft.get("bodyId") + ".txt");
     if (bodyPath.file.exists) { bodyPath.file.delete(); }
     
     String now = Time:Interval.now().seconds.toString();
     
     drd = Maps.from("subject", subject, "create", now, "update", now, "isDeleted", true);
     dm.put(subject, Json:Marshaller.marshall(drd));
     
     if (TS.notEmpty(oldSubject) && oldSubject != subject) {
       Map drd = Maps.from("subject", oldSubject, "create", now, "update", now, "isDeleted", true);
       dm.put(oldSubject, Json:Marshaller.marshall(drd));
     }
     
     return(CallBackUI.informResponse("Draft deleted.  Hit \"Save\" to undo, or \"Close\" to exit."));
     
   }
   
   loadDraftRequest(String subject, String pass, request) Map {
      log.log("in load draft");
      Encode:Hex hex = Encode:Hex.new();
      String drjs = self.draftManager.get(hex.decode(subject));
      if (TS.notEmpty(drjs)) {
        Map draft = Json:Unmarshaller.unmarshall(drjs);
        if (draft.get("isDeleted")) {
          throw(Alert.new("Draft appears deleted, refresh list?"));
        }
      } else {
        throw(Alert.new("Draft missing, may have been renamed, refresh list?"));
      }
      
      Path dp = self.draftPath;
      Path bodyPath = dp.copy().addStep(draft.get("bodyId") + ".txt");
      draft.put("body", bodyPath.file.reader.open().readStringClose());
      
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
      return(CallBackUI.multiResponse(Lists.from(CallBackUI.setElementsDisplaysResponse(Maps.from("dComposeDiv", "block", "dListDiv", "none", "informDiv", "none")), CallBackUI.setElementsValuesResponse(Maps.from("sdSubject", draft.get("subject"), "sdBody",draft.get("body"), "sdBodyId", draft.get("bodyId"), "sdOldSubject",draft.get("subject"), "sdCreate", draft.get("create"), "sdUpdate", draft.get("update"), "sdSeq", draft.get("seq"), "sdSalt", draft.get("salt"), "sdPassHash", draft.get("passHash"))))));
   
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
     draftList += "<p><a href=\"#\" onclick=\"callUI('toggleDisplay','dComposeDiv');callUI('toggleDisplay','dListDiv');document.getElementById('sdOldSubject').value = '';document.getElementById('sdSubject').value = '';document.getElementById('sdBody').value = '';document.getElementById('sdBodyId').value = '';document.getElementById('sdCreate').value = '';document.getElementById('sdUpdate').value = '';document.getElementById('sdSeq').value = '';document.getElementById('sdSalt').value = '';document.getElementById('sdPassHash').value = '';document.getElementById('passEnter1').value = '';document.getElementById('passEnter2').value = '';document.getElementById('informDiv').style.display='none';return false;\"><i>New Draft</i></a></p>";
     draftList += "<p><a href=\"#\" onclick=\"callApp('getDraftListRequest', document.getElementById('dlSearch').value);return false;\"><i>Refresh Draft List</i></a></p>";
     Bool hadDraft = false;
     Encode:Hex hex = Encode:Hex.new();
     
     for (auto kv in self.draftManager.getMap()) {
       //todo escape
       
       Map drl = Json:Unmarshaller.unmarshall(kv.value);
       unless (drl.get("isDeleted")) {
       
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

