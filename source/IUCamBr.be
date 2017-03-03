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

var deleteAccount = function() {
  ui.bem_deleteAccountRequest_1(new be_$class/Text:String$().bems_new(document.getElementById("aadminName").value));
}

window.onload = startup;
"""
}

use class IUCam:Eui {

  new() self {
        fields {
          String name = "cam";
          List callbacks = Lists.from(self); //plugins
        }
    }
    
    main() {
    
    }
    
    handleCallOut(Map arg) {
      HC.new(callbacks).call(arg);
    }
    
    handleCallback(String res) {
      hideInform();
      HC.new(callbacks).handleCallback(res);
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
     HD.getElementById("aadminIsWebcam").checked = false;
   }
   
   hideAccountAdmin() {
     HD.getElementById("accountAdminDiv").display = "none";
     clearAccountAdmin();
   }
   
   loadAccountResponse(Map arg) {
     clearAccountAdmin();
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
        return(inform("Account Admin passwords don't match"));
       }
       arg["accountPass"] = pass;
     }
     clearAccountAdmin();
     handleCallOut(arg);
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
      handleCallOut(arg);
   }
   
   toLoginResponse() {
      HD.getElementById("logindiv").display = "block";
      HD.getElementById("loggedindiv").display = "none";
      HD.getElementById("spinnerdiv").display = "none";
      HD.getElementById("loginmsgdiv").innerHTML = "";
   }
   
   pageTokenResponse(Map arg) {
      HC.new(callbacks).pageToken = arg["pageToken"];
      Map carg = Map.new();
      carg["action"] = "checkLoggedInRequest";
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
      arg["sessionLength"] = HD.getElementById("sessionLength").value;
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
      String lmsg = "<p align=\"center\" style=\"font-size: 100%;font-weight: 800;\">" + arg["deviceName"] + "</p>";
      HD.getElementById("loginmsgdiv").innerHTML = lmsg;
      HD.getElementById("logindiv").display = "none";
      HD.getElementById("loggedindiv").display = "block";
      HD.getElementById("spinnerdiv").display = "none";
    }
    if (arg.has("actionLinks")) {
      HD.getElementById("actionLinksDiv").innerHTML = arg["actionLinks"];
    }
    HD.getElementById("hubLink").href = "IU.html";
    if (arg.has("permsString")) {
      String permsString = arg["permsString"];
      if (TS.notEmpty(permsString)) {
        for (String perm in permsString.split(",")) {
          perms.put(perm);
        }
      }
      //HD.getElementById("admindiv").display = "none";
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
   
   detectCams() {
      Map arg = Map.new();
      arg["action"] = "detectCamsRequest";
      handleCallOut(arg);
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
     HD.getElementById("browseFilesDiv").display = "block";
     localBrowseRequest("");
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
   
   informResponse(Map arg) {
    inform(arg["reason"]);
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
   
   localBrowseResponse(Map arg) {
      HD.getElementById("localBrowseListDiv").innerHTML = arg["dirListHtml"];
      HD.getElementById("localBrowseListDiv").display = "block";
   }
  
}
