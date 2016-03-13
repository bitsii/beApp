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

var dzeui;
//ui startup
var startup = function() {
  dzeui = new be_BEL_4_Base_BEC_2_3_DzEui();
  dzeui.bem_new_0();
  dzeui.bem_main_0();
  dzeui.bem_startup_0();
}

var handleCallback = function(res) {
    if (res != null) {
      var bevs_resjs = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(res);
      dzeui.bem_handleCallback_1(bevs_resjs);
    }
}

var updateConfig = function(forKey, forId) {
  var theKey = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(forKey);
  var theId = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(forId);
  dzeui.bem_updateConfig_2(theKey, theId);
}

var localBrowseRequest = function(forId) {
  var theId = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(forId);
  dzeui.bem_localBrowseRequest_1(theId);
}

var deleteRequest = function(forId) {
  var theId = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(forId);
  dzeui.bem_deleteRequest_1(theId);
  localBrowseRequest(document.getElementById("browsingDirId").value);
}

var copyRequest = function(forId) {
  var theId = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(forId);
  dzeui.bem_copyRequest_1(theId);
  localBrowseRequest(document.getElementById("browsingDirId").value);
}

  function handleFileSelect(evt) {
    var dpath = dzeui.bem_browsingDirGet_0().bems_toJsString();
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

window.onload = startup;
"""
}

use class Dz:Eui {

  new() self {
        properties {
        }
    }
    
    main() {
    
    }
    
    handleCallback(String res) {
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
      login(HD.getElementById("accountName").value, HD.getElementById("accountPass").value);
   }
   
   login(String loginName, String loginPass) {
      clearImage();
      Map arg = Map.new();
      arg["action"] = "loginRequest";
      arg["accountName"] = loginName;
      arg["accountPass"] = loginPass;
      HD.getElementById("accountName").value = "";
      HD.getElementById("accountPass").value = "";
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
      String lmsg = "Welcome " + arg["name"] + " to " + arg["deviceName"] + " on Version " + arg["appVersion"];
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
   
   deleteRequest(String path) {
      Bool isChecked = HD.getElementById("confirmDeleteId").checked;
      if (isChecked) {
        HD.getElementById("confirmDeleteId").checked = false;
        Map arg = Map.new();
        arg["action"] = "deleteRequest";
        arg["path"] = path;
        HC.new(self).call(arg);
      }
   }
   
   copyRequest(String path) {
      String toName = HD.getElementById("copyNameId").value;
      HD.getElementById("copyNameId").value = "";
      Map arg = Map.new();
      arg["action"] = "copyRequest";
      arg["path"] = path;
      arg["toName"] = toName;
      HC.new(self).call(arg);
   }
   
   localBrowseResponse(Map arg) {
      HD.getElementById("localBrowseListDiv").innerHTML = arg["dirListHtml"];
      HD.getElementById("localBrowseListDiv").display = "block";
   }
  
}
