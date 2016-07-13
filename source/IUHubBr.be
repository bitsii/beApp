// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use Text:String;
use Logic:Bool;
use Math:Int;
use System:Exception as Exc;
use Container:Array;
use Container:Map;
use Container:Set;
use Container:LinkedList;
use Container:Queue;
use IO:File:Path;
use IO:File;
use System:Random;
use Text:Strings as TS;

use UI:HtmlDom:Document as HD;
use UI:HtmlDom:Element as HE;
use UI:HtmlDom:Call as HC;

emit(js) {
"""

var eui;
//ui startup
var startup = function() {
  eui = new be_BEL_4_Base_BEC_5_3_IUHubEui();
  eui.bem_new_0();
  eui.bem_main_0();
  eui.bem_startup_0();
}

var handleCallback = function(res) {
    if (res != null) {
      var bevs_resjs = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(res);
      eui.bem_handleCallback_1(bevs_resjs);
    }
}

var endSession = function(forId) {
  var theId = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(forId);
  eui.bem_endSessionRequest_1(theId);
}

var updateConfig = function(forKey, forId) {
  var theKey = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(forKey);
  var theId = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(forId);
  eui.bem_updateConfig_2(theKey, theId);
}

var localBrowseRequest = function(forId) {
  var theId = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(forId);
  eui.bem_localBrowseRequest_1(theId);
}

var loadAccountRequest = function(forId) {
  var theId = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(forId);
  eui.bem_loadAccountRequest_1(theId);
}

var deleteSelected = function() {
  eui.bem_deleteRequest_0();
  localBrowseRequest(document.getElementById("browsingDirId").value);
}

var deleteAccount = function() {
  eui.bem_deleteAccountRequest_1(new be_BEL_4_Base_BEC_4_6_TextString().bems_new(document.getElementById("aadminName").value));
}

var copySelected = function() {
  eui.bem_copyRequest_0();
  localBrowseRequest(document.getElementById("browsingDirId").value);
}

var upgradeSelected = function() {
  eui.bem_upgradeRequest_0();
  localBrowseRequest(document.getElementById("browsingDirId").value);
}

  function handleFileSelect(evt) {
    var dpath = eui.bem_browsingDirGet_0().bems_toJsString();
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
  var theId = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(box.id);
  if (box.checked) {
    eui.bem_fileChecked_1(theId);
    //alert("checked ".concat(box.id));
  } else {
    eui.bem_fileUnchecked_1(theId);
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
        }
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
      HC.new(self).call(arg);
   }
   
   restart() {
      Map arg = Map.new();
      arg["action"] = "restartRequest";
      HC.new(self).call(arg);
   }
   
   clearAllSessions() {
      Map arg = Map.new();
      arg["action"] = "clearAllSessionsRequest";
      HC.new(self).call(arg);
   }
   
   clearAllTracking() {
      Map arg = Map.new();
      arg["action"] = "clearAllTrackingRequest";
      HC.new(self).call(arg);
   }
   
   showAccountSettings() {
     HD.getElementById("accountSettingsDiv").display = "block";
   }
   
   hideAccountSettings() {
     HD.getElementById("accountSettingsDiv").display = "none";
     HD.getElementById("sessionsListDiv").display = "none";
   }

   showAccountAdminRequest() {
     Map arg = Map.new();
     arg["action"] = "showAccountAdminRequest";
     HC.new(self).call(arg);
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
     HC.new(self).call(arg);
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
     HD.getElementById("aadminIsWebcam").checked = false;
   }
   
   hideAccountAdmin() {
     HD.getElementById("accountAdminDiv").display = "none";
     clearAccountAdmin();
   }
   
   loadAccountRequest(String accountName) {
      clearAccountAdmin();
      Map arg = Map.new();
      arg["accountName"] = accountName;
      arg["action"] = "loadAccountRequest";
      HC.new(self).call(arg);
   }
   
   loadAccountResponse(Map arg) {
     HD.getElementById("aadminName").value = arg["accountName"];
     HD.getElementById("aadminIsAdmin").checked = arg["admin"];
     HD.getElementById("aadminIsWebcam").checked = arg["allcam"];
   }
   
   saveAccountRequest() {
     Map arg = Map.new();
     arg["action"] = "saveAccountRequest";
     arg["accountName"] = HD.getElementById("aadminName").value;
     arg["admin"] = HD.getElementById("aadminIsAdmin").checked;
     arg["allcam"] = HD.getElementById("aadminIsWebcam").checked;
     String pass = HD.getElementById("aadminPass").value;
     if (TS.notEmpty(pass)) {
       String pass2 = HD.getElementById("aadminPass2").value;
       if (pass != pass2) {
        return(fail("Account Admin passwords don't match"));
       }
       arg["accountPass"] = pass;
     }
     clearAccountAdmin();
     HC.new(self).call(arg);
   }
   
   showImapRequest() {
      Map arg = Map.new();
      arg["action"] = "showImapRequest";
      HC.new(self).call(arg);
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
   
    
    updateImage(String cam) {
      Map arg = Map.new();
      arg["action"] = "updateImageRequest";
      arg["cam"] = cam;
      HC.new(self).call(arg);
   }
   
   showConfig() {
      Map arg = Map.new();
      arg["action"] = "showConfigRequest";
      HC.new(self).call(arg);
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
      HC.new(self).call(arg);
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
    HC.new(self).call(arg);
   }
   
   runCommand(String key) {
      Map arg = Map.new();
      arg["action"] = "runCommandRequest";
      arg["cmdKey"] = key;
      HC.new(self).call(arg);
   }
   
   updateConfig(String theKey, String theId) {
      Map arg = Map.new();
      arg["action"] = "updateConfigRequest";
      arg["configKey"] = theKey;
      arg["configValue"] = HD.getElementById(theId).value;
      HC.new(self).call(arg);
   }
   
   deleteConfig(String theKey) {
      Map arg = Map.new();
      arg["action"] = "deleteConfigRequest";
      arg["configKey"] = theKey;
      HC.new(self).call(arg);
   }
   
   endSessionRequest(String theKey) {
      Map arg = Map.new();
      arg["action"] = "endSessionRequest";
      arg["sessionKey"] = theKey;
      HC.new(self).call(arg);
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
      HC.new(self).call(arg);
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
      HC.new(self).call(arg);
   }
   
   logout() {
      clearImage();
      Map arg = Map.new();
      arg["action"] = "logoutRequest";
      HC.new(self).call(arg);
   }
   
   updateImageResponse(Map arg) {
     HD.getElementById("clearPicId").display = "block";
     HD.getElementById("imgdiv").innerHTML = arg["imghtm"];
   }
   
   updateResponse(Map arg) {
     if (arg.has("justLoggedIn") && arg["justLoggedIn"]) {
      //String lmsg = "Welcome " + arg["name"] + " to " + arg["deviceName"] + " on Version " + arg["appVersion"];
      String lmsg = "Welcome to " + arg["deviceName"] + " on Version " + arg["appVersion"];
      HD.getElementById("loginmsgdiv").innerHTML = lmsg;
      HD.getElementById("logindiv").display = "none";
      HD.getElementById("loggedindiv").display = "block";
    }
    if (arg.has("camLinks")) {
      HD.getElementById("camLinksDiv").innerHTML = arg["camLinks"];
    }
    if (arg.has("cmdLinks")) {
      HD.getElementById("cmdLinksDiv").innerHTML = arg["cmdLinks"];
    }
    if (arg.has("permsString")) {
      String permsString = arg["permsString"];
      Set perms = Set.new();
      if (TS.notEmpty(permsString)) {
        foreach (String perm in permsString.split(",")) {
          perms.put(perm);
        }
      }
      HD.getElementById("showAdminId").display = "none";
      HD.getElementById("admindiv").display = "none";
      if (perms.has("admin")) {
        HD.getElementById("showAdminId").display = "block";
      }
    }
   }
   
   logoutResponse(Map arg) {
     HD.getElementById("loginmsgdiv").innerHTML = "";
     HD.getElementById("logindiv").display = "block";
     HD.getElementById("loggedindiv").display = "none";
     hideAccountSettings();
     hideAccountAdmin();
     hideConfig();
     hideAdmin();
     hideFail();
     HD.reload();
   }
   
   clearImage() {
     HD.getElementById("imgdiv").innerHTML = "";
     HD.getElementById("clearPicId").display = "none";
   }
   
   showAdmin() { 
     HD.getElementById("admindiv").display = "block";
     HD.getElementById("showAdminId").display = "none";
   }
   
   hideAdmin() {
     HD.getElementById("admindiv").display = "none";
     HD.getElementById("showAdminId").display = "block";
   }
   
   detectCams() {
      Map arg = Map.new();
      arg["action"] = "detectCamsRequest";
      HC.new(self).call(arg);
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
    HC.new(self).call(arg);
    } else {
      fail("New passwords don't match");
    }
   }
   
   showSessionsRequest() {
    Map arg = Map.new();
    arg["action"] = "showSessionsRequest";
    HC.new(self).call(arg);
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
    HC.new(self).call(arg);
    } else {
      fail("Passwords don't match");
    }
   }
   
   localBrowseRequest() {
     HD.getElementById("browseFilesDiv").display = "block";
     localBrowseRequest("");
   }
   
   closeFileBrowser() {
     HD.getElementById("browseFilesDiv").display = "none";
   }
   
   localBrowseRequest(String path) {
      Map arg = Map.new();
      arg["action"] = "localBrowseRequest";
      arg["path"] = path;
      HC.new(self).call(arg);
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
          HC.new(self).call(arg);
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
          HC.new(self).call(arg);
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
          HC.new(self).call(arg);
      }
   }
   
   localBrowseResponse(Map arg) {
      HD.getElementById("localBrowseListDiv").innerHTML = arg["dirListHtml"];
      HD.getElementById("localBrowseListDiv").display = "block";
   }
  
}
