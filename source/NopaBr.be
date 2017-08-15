// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use System:Exception as Exc;
use IO:File:Path;
use IO:File;
use System:Random;

use UI:HtmlDom:Document as HD;
use UI:HtmlDom:Element as HE;
use UI:HtmlDom:Call as HC;

emit(js) {
"""

//ui startup
var startup = function() {
  uiStartup(new be_$class/Nopa:Eui$());
}

var endSession = function(forId) {
  callUI('endSessionRequest', forId);
}

var updateConfig = function(forKey, forId) {
  callUI('updateConfig', forKey, forId);
}

var localBrowseRequest = function(forId) {
  callUI('localBrowseRequest', forId);
}

var deleteSelected = function() {
  callUI('deleteRequest');
  localBrowseRequest(document.getElementById("browsingDirId").value);
}

var deleteAccount = function() {
  callUI('deleteAccountRequest', document.getElementById("aadminName").value);
}

var copySelected = function() {
  callUI('copyRequest');
  localBrowseRequest(document.getElementById("browsingDirId").value);
}

  function handleFileSelect(evt) {
    var dpath = callUI('browsingDirGet').bems_toJsString();
    var files = evt.target.files; // FileList object
    for (var i = 0, f; f = files[i]; i++) {
      var req = new XMLHttpRequest();
      req.open("PUT", "/".concat(dpath.concat("/".concat(escape(f.name)))).concat("?pageToken=").concat(pageToken));
      req.setRequestHeader("Content-type", "application/octet-stream");
      req.send(f);
    }
    document.getElementById("files").value = '';
    localBrowseRequest(document.getElementById("browsingDirId").value);
  }
  
function fileChecked(box) {
  if (box.checked) {
    callUI('fileChecked', box.id);
  } else {
    callUI('fileUnchecked', box.id);
  }
  
}

function fpChange(dropdown) {
    var myindex  = dropdown.selectedIndex
    var SelValue = dropdown.options[myindex].value
    callUI('fillForwardPort', SelValue);
}

function imChange(dropdown) {
    var myindex  = dropdown.selectedIndex
    var SelValue = dropdown.options[myindex].value
    callUI('fillImap', SelValue);
}

window.onload = startup;
"""
}

use class Nopa:Eui {

  new() self {
        fields {
          String currentlyCheckedId;
          String name = "nopa";
          String profile = "nopa";
          IO:Log log =@ IO:Logs.get(self);
          List callbacks = Lists.from(self); //plugins
          HC hc = HC.new(callbacks);
          String notesDir = "";
        }
    }
    
    handleCallOut(Map arg) {
      hc.call(arg);
    }
    
    fileChecked(String id) {
      if (TS.notEmpty(id)) {
        if (TS.notEmpty(currentlyCheckedId)) {
          HD.getElementById(currentlyCheckedId).checked = false;
        }
        currentlyCheckedId = id;
      }
    }
    
    fileUnchecked(String id) {
      if (TS.notEmpty(id)) {
        HD.getElementById(currentlyCheckedId).checked = false;
        currentlyCheckedId = null;
      }
    }
    
    main() {
    
    }
    
    handleCallback(String res) {
      hideInform();
      hc.handleCallback(res);
    }
    
    browseNotes() {
     if (HD.getElementById("browseFilesDiv").display == "block") {
      closeFileBrowser();
     } else {
      HD.getElementById("browseFilesDiv").display = "block";
      localBrowseRequest(Encode:Hex.encode(notesDir));
     }
   }
   
   restart() {
      Map arg = Map.new();
      arg["action"] = "restartRequest";
      handleCallOut(arg);
   }
   
   clearAllSessions() {
      Map arg = Map.new();
      arg["action"] = "clearAllSessionsRequest";
      handleCallOut(arg);
   }
   
   clearAllTracking() {
      Map arg = Map.new();
      arg["action"] = "clearAllTrackingRequest";
      handleCallOut(arg);
   }

   showAccountAdminRequest() {
     if (HD.getElementById("accountAdminDiv").display == "block") {
       hideAccountAdmin();
     } else {
       Map arg = Map.new();
       arg["action"] = "showAccountAdminRequest";
       handleCallOut(arg);
     }
   }
   
   deleteAccountRequest(String accountName) {
     unless (HD.getElementById("confirmAccountDelete").checked) {
      return(inform("Must confirm account deletion"));
     }
     HD.getElementById("confirmAccountDelete").checked = false;
     Map arg = Map.new();
     arg["action"] = "deleteAccountRequest";
     arg["accountName"] = accountName;
     hideAccountAdmin();
     handleCallOut(arg);
   }
   
   showAccountAdminResponse(Map arg) {
     HD.getElementById("accountAdminDiv").display = "block";
     HD.getElementById("accountLinksDiv").innerHTML = arg["accountLinks"];
   }
   
   clearAccountAdmin() {
     HD.getElementById("aadminName").value = "";
     HD.getElementById("aadminPass").value = "";
     HD.getElementById("aadminPass2").value = "";
     HD.getElementById("aadminIsAdmin").checked = false;
   }
   
   hideAccountAdmin() {
     HD.getElementById("accountAdminDiv").display = "none";
     clearAccountAdmin();
   }
   
   loadAccountResponse(Map arg) {
     clearAccountAdmin();
     HD.getElementById("aadminName").value = arg["accountName"];
     HD.getElementById("aadminIsAdmin").checked = arg["admin"];
   }
   
   saveAccountRequest() {
     Map arg = Map.new();
     arg["action"] = "saveAccountRequest";
     arg["accountName"] = HD.getElementById("aadminName").value;
     arg["admin"] = HD.getElementById("aadminIsAdmin").checked;
     String pass = HD.getElementById("aadminPass").value;
     if (TS.notEmpty(pass)) {
       String pass2 = HD.getElementById("aadminPass2").value;
       if (pass != pass2) {
        return(inform("Account Admin passwords don't match"));
       }
       arg["accountPass"] = pass;
     }
     clearAccountAdmin();
     handleCallOut(arg);
   }
   
   showImapRequest() {
     if (HD.getElementById("imapSettingsDiv").display == "block") {
      HD.getElementById("imapSettingsDiv").display = "none";
     } else {
      Map arg = Map.new();
      arg["action"] = "showImapRequest";
      handleCallOut(arg);
     }
   }
   
   showImapResponse(Map arg) {
     if (arg.has("imapEndpoint")) {
      HD.getElementById("imapEndpoint").value = arg["imapEndpoint"];
     }
     if (arg.has("imapAccount")) {
      HD.getElementById("imapAccount").value = arg["imapAccount"];
     }
     if (arg.has("imapFolder")) {
      HD.getElementById("imapFolder").value = arg["imapFolder"];
     }
     if (TS.isEmpty(arg["imapFolder"])) {
      HD.getElementById("imapFolder").value = "IotUrls";
     }
     HD.getElementById("imapSettingsDiv").display = "block";
   }
   
   hideImapResponse(Map arg) {
     HD.getElementById("imapSettingsDiv").display = "none";
     HC.callAppLater(Lists.from("refreshLinksRequest"), 10000);
     hideInform();
   }
   
   showConfig() {
      if (TS.notEmpty(HD.getElementById("configsDiv").innerHTML)) {
        hideConfig();
      } else {
        Map arg = Map.new();
        arg["action"] = "showConfigRequest";
        handleCallOut(arg);
      }
   }
   
   showConfigResponse(Map arg) {
     HD.getElementById("configsDiv").innerHTML = arg["configs"];
   }
   
   hideConfig() {
     HD.getElementById("configsDiv").innerHTML = "";
   }
   
   browsingDirGet() {
     return(Encode:Hex.decode(HD.getElementById("browsingDirId").value));
   }
   
   updateConfig(String theKey, String theId) {
      Map arg = Map.new();
      arg["action"] = "updateConfigRequest";
      arg["configKey"] = theKey;
      arg["configValue"] = HD.getElementById(theId).value;
      handleCallOut(arg);
   }
   
   deleteConfig(String theKey) {
      Map arg = Map.new();
      arg["action"] = "deleteConfigRequest";
      arg["configKey"] = theKey;
      handleCallOut(arg);
   }
   
   endSessionRequest(String theKey) {
      Map arg = Map.new();
      arg["action"] = "endSessionRequest";
      arg["sessionKey"] = theKey;
      handleCallOut(arg);
   }
   
   addConfig() {
      updateConfig(HD.getElementById("addConfigKeyId").value, "addConfigValId");
   }
   
   startup() {
      IO:Logs.turnOnAll();
      Map arg = Map.new();
      arg["action"] = "pageTokenRequest";
      HD.getElementById("accountName").value = "";
      HD.getElementById("accountPass").value = "";
      //log.log("href at startup " + HD.href);
      handleCallOut(arg);
   }
   
   toLoginResponse() {
      HD.getElementById("logindiv").display = "block";
      HD.getElementById("loggedindiv").display = "none";
      HD.getElementById("spinnerdiv").display = "none";
      HD.getElementById("loginmsgdiv").innerHTML = "";
   }
   
   pageTokenResponse(Map arg) {
      hc.pageToken = arg["pageToken"];
      Map carg = Map.new();
      carg["action"] = "checkLoggedInRequest";
      String ot = HD.href;
      if (ot.has("?onceToken=") && ot.has("&")!) {
        ot = ot.substring(ot.find("=") + 1, ot.size);
        carg["onceToken"] = ot;
      }
      //log.log("href at startup " + HD.href);
      handleCallOut(carg);
   }
   
   login() {
      Map arg = Map.new();
      arg["action"] = "loginRequest";
      arg["accountName"] = HD.getElementById("accountName").value;
      arg["accountPass"] = HD.getElementById("accountPass").value;
      arg["sessionName"] = HD.getElementById("sessionName").value;
      arg["sessionLength"] = HD.getElementById("sessionLength").value;
      if (HD.getElementById("sessionNeverExpires").checked) {
        arg["sessionLength"] = "-1";
        //log.log("set sel neg");
      } else {
         //log.log("set sel neg not");
      }
      HD.getElementById("accountName").value = "";
      HD.getElementById("accountPass").value = "";
      HD.getElementById("sessionName").value = "";
      handleCallOut(arg);
   }
   
   logout() {
      Map arg = Map.new();
      arg["action"] = "logoutRequest";
      handleCallOut(arg);
   }
   
   updateResponse(Map arg) {
     fields {
       Set perms = Set.new();
     }
     if (arg.has("justLoggedIn") && arg["justLoggedIn"]) {
      //String lmsg = "Welcome " + arg["name"] + " to " + arg["deviceName"] + " on Version " + arg["appVersion"];
      String lmsg = "<p align=\"center\" style=\"font-size: 100%;font-weight: 800;\">" + arg["deviceName"] + "</p>";
      //HD.getElementById("loginmsgdiv").innerHTML = lmsg;
      HD.getElementById("logindiv").display = "none";
      HD.getElementById("loggedindiv").display = "block";
      HD.getElementById("spinnerdiv").display = "none";
      if (TS.notEmpty(arg["notesDir"])) {
        notesDir = arg["notesDir"];
      }
      //if (TS.notEmpty(arg["loginUri"])) {
        //String li = arg["loginUri"];
        //HD.getElementById("liLink").href = li;
        //if (HD.href.has(li)!) {
        //  HD.href = li;
        //}
      //}
      //log.log("updateResponse2 just logged in");
    }
    if (arg.has("profile")) {
      profile = arg["profile"];
    }
    if (arg.has("actionLinks")) {
      HD.getElementById("actionLinksDiv").innerHTML = arg["actionLinks"];
    }
    if (arg.has("permsString")) {
      String permsString = arg["permsString"];
      if (TS.notEmpty(permsString)) {
        for (String perm in permsString.split(",")) {
          perms.put(perm);
        }
      }
    }
    String oinf = "";
    if (TS.notEmpty(arg["accountSetOnce"]) && arg["accountSetOnce"] == "false") {
      HC.toggleDisplay("accountAdminDiv");
      oinf += "Please create an account.  ";
    }
    if (TS.notEmpty(arg["deviceNameSetOnce"]) && arg["deviceNameSetOnce"] == "false") {
      HC.toggleDisplay("deviceNameDiv");
      oinf += "Please provide a name for the device.  ";
    }
    if (TS.notEmpty(arg["imapSetOnce"]) && arg["imapSetOnce"] == "false") {
      HC.toggleDisplay("imapSettingsDiv");
      HD.getElementById("imapFolder").value = "IotUrls";
      oinf += "Please connect the device to an email account.  ";
    }
    if (def(arg["embedded"]) && arg["embedded"]) {
      HD.getElementById("logoutTopDiv").display = "none";
      HD.getElementById("logoutConfigDiv").display = "inline-block";
    } else {
      HD.getElementById("logoutTopDiv").display = "inline-block";
      HD.getElementById("logoutConfigDiv").display = "none";
    }
    if (TS.notEmpty(oinf)) {
      inform(oinf);
    }
   }
   
   logoutResponse(Map arg) {
     HD.reload();
   }
   
   changePassRequest() {
    String op = HD.getElementById("changePassOld").value;
    String np = HD.getElementById("changePassNew").value;
    String np2 = HD.getElementById("changePassNew2").value;
    HD.getElementById("changePassOld").value = "";
    HD.getElementById("changePassNew").value = "";
    HD.getElementById("changePassNew2").value = "";
    if (np == np2) {
    Map arg = Map.new();
    arg["action"] = "changePassRequest";
    arg["oldPass"] = op;
    arg["newPass"] = np;
    handleCallOut(arg);
    } else {
      inform("New passwords don't match");
    }
   }
   
   showSessionsRequest() {
    if (HD.getElementById("sessionsListDiv").display == "block") {
      HD.getElementById("sessionsListDiv").display = "none";
    } else {
      Map arg = Map.new();
      arg["action"] = "showSessionsRequest";
      handleCallOut(arg);
    }
   }
   
   showSessionsResponse(Map arg) {
    if (TS.notEmpty(arg["sessionsList"])) {
      HD.getElementById("sessionsListDiv").innerHTML = arg["sessionsList"];
      HD.getElementById("sessionsListDiv").display = "block";
    }
   }
   
   imapSettingsRequest() {
    String iac = HD.getElementById("imapAccount").value;
    String iep = HD.getElementById("imapEndpoint").value;
    String isf = HD.getElementById("imapFolder").value;
    String ip = HD.getElementById("imapPass").value;
    String ip2 = HD.getElementById("imapPass2").value;
    HD.getElementById("imapPass").value = "";
    HD.getElementById("imapPass2").value = "";
    if (ip == ip2) {
    Map arg = Map.new();
    arg["action"] = "imapSettingsRequest";
    arg["imapAccount"] = iac;
    arg["imapEndpoint"] = iep;
    arg["imapFolder"] = isf;
    arg["imapPass"] = ip;
    handleCallOut(arg);
    } else {
      inform("Passwords don't match");
    }
   }
   
   localBrowseRequest() {
     if (HD.getElementById("browseFilesDiv").display == "block") {
      closeFileBrowser();
     } else {
      HD.getElementById("browseFilesDiv").display = "block";
      localBrowseRequest("");
     }
   }
   
   closeFileBrowser() {
     HD.getElementById("browseFilesDiv").display = "none";
   }
   
   localBrowseRequest(String path) {
      Map arg = Map.new();
      arg["action"] = "localBrowseRequest";
      arg["path"] = path;
      handleCallOut(arg);
   }
   
   createFolder() {
      Map arg = Map.new();
      arg["action"] = "createDirectoryRequest";
      arg["inDir"] = HD.getElementById("browsingDirId").value;
      arg["dirName"] = HD.getElementById("createFolderId").value;
      HD.getElementById("createFolderId").value = "";
      handleCallOut(arg);
   }
   
   createNote() {
      Map arg = Map.new();
      arg["action"] = "createNoteRequest";
      arg["inDir"] = HD.getElementById("browsingDirId").value;
      arg["noteName"] = HD.getElementById("noteNameId").value;
      HD.getElementById("noteNameId").value = "";
      handleCallOut(arg);
   }
   
   openNote(String name) {
      Map arg = Map.new();
      arg["action"] = "openNoteRequest";
      arg["inDir"] = HD.getElementById("browsingDirId").value;
      arg["noteName"] = name;
      handleCallOut(arg);
   }
   
   deleteRequest() {
      Bool isChecked = HD.getElementById("confirmDeleteId").checked;
      HD.getElementById("confirmDeleteId").checked = false;
      String ci = currentlyCheckedId;
      if (TS.notEmpty(ci)) {
        HD.getElementById(currentlyCheckedId).checked = false;
        currentlyCheckedId = null;
      }
      if (isChecked) {
        if (TS.notEmpty(ci)) {
          String path = ci.substring(3);
          Map arg = Map.new();
          arg["action"] = "deleteRequest";
          arg["path"] = path;
          handleCallOut(arg);
        }
      }
   }
   
   informResponse(String info) {
    inform(info);
   }
   
   inform(String r) {
     if (TS.notEmpty(r)) {
      HD.getElementById("informMessageDiv").innerHTML = r;
      HD.getElementById("informDiv").display = "block";
     }
   }
   
   hideInform() {
     HD.getElementById("informDiv").display = "none";
   }
   
   copyRequest() {
      String toName = HD.getElementById("copyNameId").value;
      HD.getElementById("copyNameId").value = "";
      String ci = currentlyCheckedId;
      if (TS.notEmpty(ci)) {
        HD.getElementById(currentlyCheckedId).checked = false;
        currentlyCheckedId = null;
      }
      if (TS.notEmpty(ci)) {
          String path = ci.substring(3);
          Map arg = Map.new();
          arg["action"] = "copyRequest";
          arg["path"] = path;
          arg["toName"] = toName;
          handleCallOut(arg);
      }
   }
   
   localBrowseResponse(Map arg) {
      HD.getElementById("localBrowseListDiv").innerHTML = arg["dirListHtml"];
      HD.getElementById("localBrowseListDiv").display = "block";
   }
   
   fillImap(String forService) {
      if (forService.ends("GMail")) {
        HD.getElementById("imapEndpoint").value = "imap.gmail.com";
        HD.getElementById("imDitty").innerHTML = "<p>Use full email address as account name.  A dedicated account is recommended, you can create one here, <a href='https://accounts.google.com/SignUp?service=mail'>GMail Signup</a>";
      } elseIf (forService.ends("GMX Mail")) {
        HD.getElementById("imapEndpoint").value = "imap.gmx.com";
        HD.getElementById("imDitty").innerHTML = "<p>Use full email address as account name.  A dedicated account is recommended, you can create one here, <a href='https://service.gmx.com/registration.html'>GMX Signup</a>";
      } elseIf (forService.ends("Yahoo Mail")) {
        HD.getElementById("imapEndpoint").value = "imap.mail.yahoo.com";
        HD.getElementById("imDitty").innerHTML = "<p>Use full email address as account name.  A dedicated account is recommended, you can create one here, <a href='https://login.yahoo.com/account/create'>Yahoo Signup</a>";
      } else {
        HD.getElementById("imapEndpoint").value = "";
        HD.getElementById("imDitty").innerHTML = "";
      }
   }
  
}
