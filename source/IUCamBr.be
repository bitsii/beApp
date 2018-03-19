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
  uiStartup(new be_$class/IUCam:Eui$());
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

window.onload = startup;
"""
}

use class IUCam:Eui {

  new() self {
        fields {
          String currentlyCheckedId;
          String name = "cam";
          String profile = "cam";
          IO:Log log =@ IO:Logs.get(self);
          List callbacks = Lists.from(self, CamUI.new()); //plugins
          HC hc = HC.new(callbacks);
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
      clearImage();
      Map arg = Map.new();
      arg["action"] = "pageTokenRequest";
      HD.getElementById("accountName").value = "";
      HD.getElementById("accountPass").value = "";
      //log.log("href at startup " + HD.href);
      handleCallOut(arg);
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
      clearImage();
      Map arg = Map.new();
      arg["action"] = "loginRequest";
      arg["accountName"] = HD.getElementById("accountName").value;
      arg["accountPass"] = HD.getElementById("accountPass").value;
      arg["sessionName"] = HD.getElementById("sessionName").value;
      //arg["sessionLength"] = HD.getElementById("sessionLength").value;
      if (HD.getElementById("sessionNeverExpires").checked) {
        arg["sessionLength"] = "-1";
        //log.log("set sel neg");
      } else {
         arg["sessionLength"] = "60";
         //log.log("set sel neg not");
      }
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
     if(arg.has("plink")) {
      HD.getElementById("plink").innerHTML = arg["plink"];
      HD.getElementById("plink").display = "block";
     } else {
      HD.getElementById("plink").display = "none";
     }
     if(arg.has("nlink")) {
      HD.getElementById("nlink").innerHTML = arg["nlink"];
      HD.getElementById("nlink").display = "block";
     } else {
      HD.getElementById("nlink").display = "none";
     }
   }
   
   updateResponse(Map arg) {
     fields {
       Set perms = Set.new();
     }
     //profile - security - menu setup
    
    if (arg.has("permsString")) {
      String permsString = arg["permsString"];
      if (TS.notEmpty(permsString)) {
        for (String perm in permsString.split(",")) {
          perms.put(perm);
        }
      }
    }
    
    profile = arg["profile"];
    log.log("profile " + profile);
    if (profile == "cam") {
      HD.title = "IOTurl Cam";
      
    }
    
    if (arg.has("actionLinks")) {
      HD.getElementById("actionLinksDiv").innerHTML = arg["actionLinks"];
    }
    
    if (arg.has("justLoggedIn") && arg["justLoggedIn"]) {
      HD.getElementById("logindiv").display = "none";
      HD.getElementById("loggedindiv").display = "block";
    }
    
   }
   
   toLoginResponse() {
      HD.getElementById("logindiv").display = "block";
      HD.getElementById("loggedindiv").display = "none";
   }
   
   detectCams() {
      Map arg = Map.new();
      arg["action"] = "detectCamsRequest";
      handleCallOut(arg);
   }
   
   logoutResponse(Map arg) {
     HD.reload();
   }
   
   clearImage() {
     HD.getElementById("imgdiv").innerHTML = "";
     HD.getElementById("clearPicId").display = "none";
     HD.getElementById("nlink").display = "none";
     HD.getElementById("plink").display = "none";
   }
   
   showSessionsRequest() {
      Map arg = Map.new();
      arg["action"] = "showSessionsRequest";
      handleCallOut(arg);
   }
   
   showSessionsResponse(Map arg) {
    if (TS.notEmpty(arg["sessionsList"])) {
      HD.getElementById("sessionsListDiv").innerHTML = arg["sessionsList"];
      HD.getElementById("sessionsListDiv").display = "block";
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
   
}

use class IUCam:CamUI {

  new() self {
        fields {
          String name = "Cam";
          HC hc = HC.new();
        }
    }
    
    main() {
    
    }
    
    handleCallOut(Map arg) {
      hc.call(arg);
    }
    
    handleCallback(String res) {
      hideInform();
      hc.handleCallback(res);
    }
       
    updateImage(String cam) {
      Map arg = Map.new();
      arg["action"] = "updateImageRequest";
      arg["cam"] = cam;
      handleCallOut(arg);
   }
   
   toggleMotion(String cam) {
      Map arg = Map.new();
      arg["action"] = "toggleMotionRequest";
      arg["cam"] = cam;
      handleCallOut(arg);
   }
   
   toggleCamSettings() {
     if (HD.getElementById("camSettingsDiv").display == "block") {
       HD.getElementById("camSettingsDiv").display = "none";
     } else {
       HD.getElementById("camSettingsDiv").display = "block";
     }
   }
   
   startup() {
      IO:Logs.turnOnAll();
      clearImage();
      Map arg = Map.new();
      arg["action"] = "pageTokenRequest";
      HD.getElementById("accountName").value = "";
      HD.getElementById("accountPass").value = "";
      handleCallOut(arg);
   }
   
   updateImageResponse(Map arg) {
     HD.getElementById("clearPicId").display = "block";
     HD.getElementById("imgdiv").innerHTML = arg["imghtm"];
     if(arg.has("plink")) {
      HD.getElementById("plink").innerHTML = arg["plink"];
      HD.getElementById("plink").display = "block";
     } else {
      HD.getElementById("plink").display = "none";
     }
     if(arg.has("nlink")) {
      HD.getElementById("nlink").innerHTML = arg["nlink"];
      HD.getElementById("nlink").display = "block";
     } else {
      HD.getElementById("nlink").display = "none";
     }
   }
   
   clearImage() {
     HD.getElementById("imgdiv").innerHTML = "";
     HD.getElementById("clearPicId").display = "none";
     HD.getElementById("nlink").display = "none";
     HD.getElementById("plink").display = "none";
   }
   
   detectCams() {
      Map arg = Map.new();
      arg["action"] = "detectCamsRequest";
      handleCallOut(arg);
   }
   
   browseWebCam() {
     if (HD.getElementById("browseFilesDiv").display == "block") {
      closeFileBrowser();
     } else {
      HD.getElementById("browseFilesDiv").display = "block";
      localBrowseRequest(Encode:Hex.encode("./Shared/WebCam"));
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
   
   inform(String r) {
     if (TS.notEmpty(r)) {
      HD.getElementById("informMessageDiv").innerHTML = r;
      HD.getElementById("informDiv").display = "block";
     }
   }
   
   hideInform() {
     HD.getElementById("informDiv").display = "none";
   }
   
}
