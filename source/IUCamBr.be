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
  eui = new be_BEL_4_Base_$class/IUCam:Eui$();
  eui.bem_new_0();
  eui.bem_main_0();
  eui.bem_startup_0();
}

var handleCallback = function(res) {
    if (res != null) {
      var bevs_resjs = new be_BEL_4_Base_$class/Text:String$().bems_new(res);
      eui.bem_handleCallback_1(bevs_resjs);
    }
}

var endSession = function(forId) {
  var theId = new be_BEL_4_Base_$class/Text:String$().bems_new(forId);
  eui.bem_endSessionRequest_1(theId);
}

var updateConfig = function(forKey, forId) {
  var theKey = new be_BEL_4_Base_$class/Text:String$().bems_new(forKey);
  var theId = new be_BEL_4_Base_$class/Text:String$().bems_new(forId);
  eui.bem_updateConfig_2(theKey, theId);
}

var localBrowseRequest = function(forId) {
  var theId = new be_BEL_4_Base_$class/Text:String$().bems_new(forId);
  eui.bem_localBrowseRequest_1(theId);
}

var loadAccountRequest = function(forId) {
  var theId = new be_BEL_4_Base_$class/Text:String$().bems_new(forId);
  eui.bem_loadAccountRequest_1(theId);
}

var deleteAccount = function() {
  eui.bem_deleteAccountRequest_1(new be_BEL_4_Base_$class/Text:String$().bems_new(document.getElementById("aadminName").value));
}

window.onload = startup;
"""
}

use class IUCam:Eui {

  new() self {
        fields {
        }
    }
    
    main() {
    
    }
    
    handleCallOut(Map arg) {
      if (def(arg)) {
        arg["plugin"] = "cam";
      }
      HC.new(self).call(arg);
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
      handleCallOut(arg);
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
     handleCallOut(arg);
   }
       
    updateImage(String cam) {
      Map arg = Map.new();
      arg["action"] = "updateImageRequest";
      arg["cam"] = cam;
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
    }
    if (arg.has("actionLinks")) {
      HD.getElementById("actionLinksDiv").innerHTML = arg["actionLinks"];
    }
    if (arg.has("permsString")) {
      String permsString = arg["permsString"];
      if (TS.notEmpty(permsString)) {
        foreach (String perm in permsString.split(",")) {
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
      fail("New passwords don't match");
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
   
   closeFileBrowser() {
     HD.getElementById("browseFilesDiv").display = "none";
   }
   
   localBrowseRequest(String path) {
      Map arg = Map.new();
      arg["action"] = "localBrowseRequest";
      arg["path"] = path;
      handleCallOut(arg);
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
   
   localBrowseResponse(Map arg) {
      HD.getElementById("localBrowseListDiv").innerHTML = arg["dirListHtml"];
      HD.getElementById("localBrowseListDiv").display = "block";
   }
  
}
