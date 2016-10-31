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
  uiStartup(new be_$class/IUHub:Eui$());
}

var endSession = function(forId) {
  var theId = new be_$class/Text:String$().bems_new(forId);
  ui.bem_endSessionRequest_1(theId);
}

var updateConfig = function(forKey, forId) {
  var theKey = new be_$class/Text:String$().bems_new(forKey);
  var theId = new be_$class/Text:String$().bems_new(forId);
  ui.bem_updateConfig_2(theKey, theId);
}

var localBrowseRequest = function(forId) {
  var theId = new be_$class/Text:String$().bems_new(forId);
  ui.bem_localBrowseRequest_1(theId);
}

var deleteSelected = function() {
  ui.bem_deleteRequest_0();
  localBrowseRequest(document.getElementById("browsingDirId").value);
}

var deleteAccount = function() {
  ui.bem_deleteAccountRequest_1(new be_$class/Text:String$().bems_new(document.getElementById("aadminName").value));
}

var copySelected = function() {
  ui.bem_copyRequest_0();
  localBrowseRequest(document.getElementById("browsingDirId").value);
}

var upgradeSelected = function() {
  ui.bem_upgradeRequest_0();
  localBrowseRequest(document.getElementById("browsingDirId").value);
}

  function handleFileSelect(evt) {
    var dpath = ui.bem_browsingDirGet_0().bems_toJsString();
    var files = evt.target.files; // FileList object
    for (var i = 0, f; f = files[i]; i++) {
      var req = new XMLHttpRequest();
      req.open("PUT", "/".concat(dpath.concat("/".concat(escape(f.name)))));
      req.setRequestHeader("Content-type", "application/octet-stream");
      req.send(f);
    }
    document.getElementById("files").value = '';
    localBrowseRequest(document.getElementById("browsingDirId").value);
  }
  
function fileChecked(box) {
  var theId = new be_$class/Text:String$().bems_new(box.id);
  if (box.checked) {
    ui.bem_fileChecked_1(theId);
    //alert("checked ".concat(box.id));
  } else {
    ui.bem_fileUnchecked_1(theId);
    //alert("unchecked ".concat(box.id));
  }
  
}

window.onload = startup;
"""
}

use class IUHub:Eui {

  new() self {
        fields {
          String currentlyCheckedId;
          String name = "hub";
        }
    }
    
    handleCallOut(Map arg) {
      if (def(arg)) {
        arg["plugin"] = name;
      }
      HC.new(self).call(arg);
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
      hideFail();
      HC.new(self).handleCallback(res);
    }
    
    tryThing() {
      Map arg = Map.new();
      arg["action"] = "tryThingRequest";
      handleCallOut(arg);
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
   
   showAccountSettings() {
     if (HD.getElementById("accountSettingsDiv").display == "block") {
       hideAccountSettings();
     } else {
       HD.getElementById("accountSettingsDiv").display = "block";
       if (def(perms) && perms.has("admin")) {
        showAdmin();
       }
     }
   }
   
   hideAccountSettings() {
     HD.getElementById("accountSettingsDiv").display = "none";
     HD.getElementById("sessionsListDiv").display = "none";
     if (def(perms) && perms.has("admin")) {
      hideAdmin();
     }
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
      return(fail("Must confirm account deletion"));
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
        return(fail("Account Admin passwords don't match"));
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
     HD.getElementById("imapSettingsDiv").display = "block";
   }
   
   hideImapResponse(Map arg) {
     HD.getElementById("imapSettingsDiv").display = "none";
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
   
   showDevLinks() {
      Map arg = Map.new();
      arg["action"] = "showDevLinksRequest";
      handleCallOut(arg);
   }
   
   showDevLinksResponse(Map arg) {
     //HD.getElementById("devsDiv").innerHTML = arg["devs"];
     HD.getElementById("offerDevLinkDiv").display = "block";
   }
   
   hideDevLinks() {
     HD.getElementById("offerDevLinkDiv").display = "none";
   }
   
   browsingDirGet() {
     return(Encode:Hex.decode(HD.getElementById("browsingDirId").value));
   }
   
   offerLink() {
    //HD.getElementById("devsDiv").innerHTML = arg["devs"];
    //HD.getElementById("offerDevLinkDiv").display = "block";
    Map arg = Map.new();
    arg["action"] = "offerLinkRequest";
    arg["offerEmail"] = HD.getElementById("offerEmail").value;
    arg["offerPass1"] = HD.getElementById("offerPass1").value;
    arg["offerPass2"] = HD.getElementById("offerPass2").value;
    handleCallOut(arg);
   }
   
   runCommand(String key) {
      Map arg = Map.new();
      arg["action"] = "runCommandRequest";
      arg["cmdKey"] = key;
      handleCallOut(arg);
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
      clearImage();
      Map arg = Map.new();
      arg["action"] = "checkLoggedInRequest";
      HD.getElementById("accountName").value = "";
      HD.getElementById("accountPass").value = "";
      handleCallOut(arg);
   }
   
   login() {
      clearImage();
      Map arg = Map.new();
      arg["action"] = "loginRequest";
      arg["accountName"] = HD.getElementById("accountName").value;
      arg["accountPass"] = HD.getElementById("accountPass").value;
      arg["sessionName"] = HD.getElementById("sessionName").value;
      HD.getElementById("accountName").value = "";
      HD.getElementById("accountPass").value = "";
      HD.getElementById("sessionName").value = "";
      handleCallOut(arg);
   }
   
   logout() {
      clearImage();
      Map arg = Map.new();
      arg["action"] = "logoutRequest";
      handleCallOut(arg);
   }
   
   updateImageResponse(Map arg) {
     HD.getElementById("clearPicId").display = "block";
     HD.getElementById("imgdiv").innerHTML = arg["imghtm"];
   }
   
   updateResponse(Map arg) {
     fields {
       Set perms = Set.new();
     }
     if (arg.has("justLoggedIn") && arg["justLoggedIn"]) {
      //String lmsg = "Welcome " + arg["name"] + " to " + arg["deviceName"] + " on Version " + arg["appVersion"];
      String lmsg = "Welcome to " + arg["deviceName"] + " on Version " + arg["appVersion"];
      HD.getElementById("loginmsgdiv").innerHTML = lmsg;
      HD.getElementById("logindiv").display = "none";
      HD.getElementById("loggedindiv").display = "block";
      HC.new(self).pageToken = arg["pageToken"];
    }
    if (arg.has("actionLinks")) {
      HD.getElementById("actionLinksDiv").innerHTML = arg["actionLinks"];
    }
    if (arg.has("devLinksList")) {
      HD.getElementById("devLinksListDiv").innerHTML = arg["devLinksList"];
    } else {
      HD.getElementById("devLinksListDiv").innerHTML = "";
    }
    HD.getElementById("devLinksDiv").innerHTML = "";
    if (arg.has("permsString")) {
      String permsString = arg["permsString"];
      if (TS.notEmpty(permsString)) {
        for (String perm in permsString.split(",")) {
          perms.put(perm);
        }
      }
      HD.getElementById("admindiv").display = "none";
    }
   }
   
   logoutResponse(Map arg) {
     HD.reload();
   }
   
   clearImage() {
     HD.getElementById("imgdiv").innerHTML = "";
     HD.getElementById("clearPicId").display = "none";
   }
   
   showAdmin() { 
     HD.getElementById("admindiv").display = "block";
   }
   
   hideAdmin() {
     HD.getElementById("admindiv").display = "none";
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
      fail("New passwords don't match");
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
    String ip = HD.getElementById("imapPass").value;
    String ip2 = HD.getElementById("imapPass2").value;
    HD.getElementById("imapPass").value = "";
    HD.getElementById("imapPass2").value = "";
    if (ip == ip2) {
    Map arg = Map.new();
    arg["action"] = "imapSettingsRequest";
    arg["imapAccount"] = iac;
    arg["imapEndpoint"] = iep;
    arg["imapPass"] = ip;
    handleCallOut(arg);
    } else {
      fail("Passwords don't match");
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
   
   failResponse(Map arg) {
    fail(arg["reason"]);
   }
   
   fail(String r) {
     if (TS.notEmpty(r)) {
      HD.getElementById("failMessageDiv").innerHTML = r;
      HD.getElementById("failDiv").display = "block";
     }
   }
   
   hideFail() {
     HD.getElementById("failDiv").display = "none";
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
   
   upgradeRequest() {
      String ci = currentlyCheckedId;
      if (TS.notEmpty(ci)) {
        HD.getElementById(currentlyCheckedId).checked = false;
        currentlyCheckedId = null;
      }
      if (TS.notEmpty(ci)) {
          String path = ci.substring(3);
          Map arg = Map.new();
          arg["action"] = "upgradeRequest";
          arg["path"] = path;
          handleCallOut(arg);
      }
   }
   
   localBrowseResponse(Map arg) {
      HD.getElementById("localBrowseListDiv").innerHTML = arg["dirListHtml"];
      HD.getElementById("localBrowseListDiv").display = "block";
   }
  
}
