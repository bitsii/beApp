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

var upgradeSelected = function() {
  callUI('upgradeRequest');
  localBrowseRequest(document.getElementById("browsingDirId").value);
}

var restoreSelected = function() {
  callUI('restoreConfigRequest');
  callUI('logoutResponse');
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

use class IUHub:Eui {

  new() self {
        fields {
          String currentlyCheckedId;
          String name = "hub";
          String profile = "hub";
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
   
   toggleDevLinks(String devId) {
     fields {
      String lastDevId;
     }
     if (TS.notEmpty(lastDevId) && lastDevId == devId) {
      HC.toggleDisplay("devLinksDiv");
     }
     lastDevId = devId;
   }
   
   showImapResponse(Map arg) {
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
   
   showDevLinks() {
      Map arg = Map.new();
      arg["action"] = "showDevLinksRequest";
      handleCallOut(arg);
   }
   
   showDevLinksResponse(Map arg) {
     //HD.getElementById("devsDiv").innerHTML = arg["devs"];
     HD.getElementById("offerDevLinkDiv").display = "block";
   }
   
   getDevCredsResponse(String devId, String devName) {
     fields {
      String devIdForCreds = devId;
     }
     HD.getElementById("devCredsNameDiv").innerHTML = devName;
     HC.toggleDisplay("devCredsDiv");
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
      IO:Logs.turnOnAll();
      clearImage();
      Map arg = Map.new();
      arg["action"] = "pageTokenRequest";
      HD.getElementById("accountName").value = "";
      HD.getElementById("accountPass").value = "";
      //log.log("href at startup " + HD.href);
      handleCallOut(arg);
   }
   
   hideNShowOneResponse(String val) {
    hideNShowResponse(Set.new().put(val));
   }
   
   hideNShowListResponse(List toShow) {
    hideNShowResponse(Sets.from(toShow));
   }
    
   hideNShowResponse(Set toShow) {
    List allElems =@ Lists.from("logindiv", "actionLinksDiv", "devLinksListDiv", "devLinksDiv", "passchangediv", "sessionsDiv", "dnamechangediv", "devicelogindiv", "remoteaccessdiv", "forwardPortsDiv", "browseFilesDiv", "accountdiv", "setupDiv", "appsDiv", "aboutDiv");
    for (String el in allElems) {
      if (toShow.has(el)) {
        HD.getElementById(el).display = "block";
      } else {
        HD.getElementById(el).display = "none";
      }
    }
    //HD.getElementById("loginmsgdiv").innerHTML = "";
   }
   
   //initialSetupRequest(String setupToken, String user, String pass, String devName, String konUser, String konPass, request)
   initialSetup() {
     if (TS.isEmpty(HD.getElementById("setupAccountPass").value) || TS.isEmpty(HD.getElementById("setupAccountPass2").value) || HD.getElementById("setupAccountPass").value != HD.getElementById("setupAccountPass2").value) {
      inform("Account password required, Account Password and Repeat Password must match");
     }
     HC.callApp(Lists.from("initialSetupRequest", setupToken, HD.getElementById("setupAccountName").value, HD.getElementById("setupAccountPass").value, HD.getElementById("setupDeviceName").value, HD.getElementById("setupKonnLogin").value, HD.getElementById("setupKonnPass").value));
     
     
   }
   
   initialSetupResponse() {
     String hr = HD.href;
      log.log("href " + hr);
      auto hrll = hr.split("?");
      HD.href = hrll.get(0);
   }
   
   hideNShowMenuResponse(Set toShow) {
    List allElems =@ Lists.from("loginmenudiv", "loggedinmenudiv");
    for (String el in allElems) {
      if (toShow.has(el)) {
        HD.getElementById(el).display = "block";
      } else {
        HD.getElementById(el).display = "none";
      }
    }
    //HD.getElementById("loginmsgdiv").innerHTML = "";
   }
   
   toLoginResponse() {
      hideNShowResponse(Sets.from("logindiv"));
      hideNShowMenuResponse(Sets.from("loginmenudiv"));
   }
   
   checkPrepSetup() Bool {
      //check for setup log.log("href " + HD.href);
      fields {
        String setupToken;
      }
      //only do once
      if (def(setupToken)) {
        return(false);
      }
      String hr = HD.href;
      log.log("href " + hr);
      auto hrll = hr.split("?");
      if (hrll.size > 1) {
        hr = hrll.get(1);
        log.log("hr " + hr);
      }
      if (hr.begins("setupToken=")) {
        hrll = hr.split("=");
        if (hrll.size > 1) {
          hr = hrll.get(1);
          log.log("st " + hr);
          setupToken = hr;
          return(true);
        }
      }
      return(false);
   }
   
   pageTokenResponse(Map arg) {
      hc.pageToken = arg["pageToken"];
      
      if (checkPrepSetup()) {
        toLoginResponse();
        hideNShowResponse(Sets.from("setupDiv"));
      } else {
        Map carg = Map.new();
        carg["action"] = "checkLoggedInRequest";
        //log.log("href at startup " + HD.href);
        handleCallOut(carg);
      }
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
   
   getUpnpResponse(Bool upnpEnabled) {
      HD.getElementById("enableUpnp").checked = upnpEnabled;
   }
   
   getOnPublicNetResponse(Bool upnpEnabled) {
      HD.getElementById("onPublicNet").checked = upnpEnabled;
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
    if (profile == "bridge") {
      HD.title = "Edgii Bridge";
      
      HD.getElementById("browseDevicesME").display = "none";
      //HD.getElementById("linkDevicesME").display = "none";
      
      if (perms.has("admin")!) {
        HD.getElementById("linkDevicesME").display = "none";
        HD.getElementById("remoteListenME").display = "none";
        HD.getElementById("remoteAccessME").display = "none";
        HD.getElementById("restartME").display = "none";
        HD.getElementById("manageAccountsME").display = "none";
        HD.getElementById("setDevicenameME").display = "none";
      }
      
    } elseIf (profile == "router") {
      HD.title = "Edgii Router";
      
      HD.getElementById("setDevicenameME").display = "none";
      HD.getElementById("remoteListenME").display = "none";
      HD.getElementById("remoteAccessME").display = "none";
      HD.getElementById("showServicesME").display = "none";
      HD.getElementById("fileManagerME").display = "none";
      
    }
         
     hideNShowResponse(Sets.from("devLinksListDiv", "actionLinksDiv"));
     hideNShowMenuResponse(Sets.from("loggedinmenudiv"));
     
     
     if (arg.has("justLoggedIn") && arg["justLoggedIn"]) {
      String lmsg = "<p align=\"center\" style=\"font-size: 100%;font-weight: 800;\">" + arg["deviceName"] + "</p>";
      HD.getElementById("loginmsgdiv").innerHTML = lmsg;
    }
    
    if (arg.has("actionLinks")) {
      log.log("setting actionlinks");
      HD.getElementById("actionLinksDiv").innerHTML = arg["actionLinks"];
      HD.getElementById("primaryLinksDiv").display = "block";
      //log.log("actionlinks " + arg["actionLinks"]);
    }
    if (arg.has("devLinksList")) {
      HD.getElementById("devLinksListDiv").innerHTML = arg["devLinksList"];
    } else {
      HD.getElementById("devLinksListDiv").innerHTML = "";
    }
    HD.getElementById("devLinksDiv").innerHTML = "";

    //HC.callAppLater(Lists.from("refreshLinksRequest"), 10000);
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
     /*HD.getElementById("imgdiv").innerHTML = "";
     HD.getElementById("clearPicId").display = "none";
     HD.getElementById("nlink").display = "none";
     HD.getElementById("plink").display = "none";*/
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
     hideNShowOneResponse("browseFilesDiv");
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
   
   backupConfigResponse(Map arg) {
     String configJson = arg["configJson"];
     String name = "HubConfig.json";//TODO add device name
     emit(js) {
     """
     downloadJson(bevl_configJson.bems_toJsString(), bevl_name.bems_toJsString());
     """
     }
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
   
   refreshLinksResponse(String actionLinks, String devLinks) {
     if (TS.notEmpty(actionLinks)) {
      HD.getElementById("actionLinksDiv").innerHTML = actionLinks;
    }
    if (TS.notEmpty(devLinks)) {
      HD.getElementById("devLinksListDiv").innerHTML = devLinks;
    }
   }
   
   restoreConfigRequest() {
      String ci = currentlyCheckedId;
      if (TS.notEmpty(ci)) {
        HD.getElementById(currentlyCheckedId).checked = false;
        currentlyCheckedId = null;
      }
      if (TS.notEmpty(ci)) {
          String path = ci.substring(3);
          Map arg = Map.new();
          arg["action"] = "restoreConfigRequest";
          arg["path"] = path;
          handleCallOut(arg);
      }
   }
   
   localBrowseResponse(Map arg) {
      HD.getElementById("localBrowseListDiv").innerHTML = arg["dirListHtml"];
      HD.getElementById("localBrowseListDiv").display = "block";
   }
   
   fillForwardPort(String forService) {
      if (forService.begins("Secure Shell")) {
        HD.getElementById("fpName").value = "Secure Shell, remote command line";
        HD.getElementById("fpPort").value = "22";
        HD.getElementById("fpExPort").value = "";
        HD.getElementById("fpPattern").value = "$type$ SSH: ssh -p $port$ user@$ip$";
        HD.getElementById("fpDitty").innerHTML = "<p>ssh - <a href=\"https://duckduckgo.com/?q=ssh\">About Secure Shell</a>";
      } elseIf (forService.begins("Let's Encrypt")) {
        HD.getElementById("fpName").value = "Enable Let's Encrypt certificate generation";
        HD.getElementById("fpPort").value = "80";
        HD.getElementById("fpExPort").value = "";
        HD.getElementById("fpPattern").value = "<a href=\"http://$ip$:$port$/\" target=\"_blank\">$type$ Let's Encrypt</a>";
        HD.getElementById("fpDitty").innerHTML = "<p><a href=\"https://letsencrypt.org\">Let's Encrypt</a>";
      } elseIf (forService.begins("Shellinabox")) {
        HD.getElementById("fpName").value = "Shellinabox - remote command line in browser";
        HD.getElementById("fpPort").value = "4200";
        HD.getElementById("fpExPort").value = "";
        HD.getElementById("fpPattern").value = "<a href=\"https://$ip$:$port$/\" target=\"_blank\">$type$ Shellinabox</a>";
        HD.getElementById("fpDitty").innerHTML = "<p><a href=\"https://github.com/shellinabox/shellinabox\">Shellinabox on GitHub</a>";
      } elseIf (forService.begins("IU WebCam")) {
        HD.getElementById("fpName").value = "IU WebCam - webcam with motion";
        HD.getElementById("fpPort").value = "";
        HD.getElementById("fpExPort").value = "";
        HD.getElementById("fpPattern").value = "<a href=\"https://$ip$:$port$/\" target=\"_blank\">$type$ IU WebCam</a>";
        HD.getElementById("fpDitty").innerHTML = "<p><a href=\"https://gitlab.com/abelii/edgii/wikis/home\">IU WebCam on GitLab</a>";
        HC.callApp(Lists.from("setCamPortsRequest"));
      } elseIf (forService.begins("MS Remote")) {
        HD.getElementById("fpName").value = "MS Remote Desktop";
        HD.getElementById("fpPort").value = "3389";
        HD.getElementById("fpExPort").value = "";
        HD.getElementById("fpPattern").value = "$type$ RDP:  $ip$:$port$";
        HD.getElementById("fpDitty").innerHTML = "<p><a href=\"https://support.microsoft.com/en-us/help/17463/windows-7-connect-to-another-computer-remote-desktop-connection\">MS Remote Desktop</a>";
      } elseIf (forService.begins("NoMachine")) {
        HD.getElementById("fpName").value = "NoMachine Remote Desktop";
        HD.getElementById("fpPort").value = "4000";
        HD.getElementById("fpExPort").value = "";
        HD.getElementById("fpPattern").value = "$type$ NoMachine:  $ip$:$port$";
        HD.getElementById("fpDitty").innerHTML = "<p><a href=\"https://www.nomachine.com/\">NoMachine, free cross platform remote desktop</a>";
      } elseIf (forService.begins("VNC")) {
        HD.getElementById("fpName").value = "VNC Remote Desktop";
        HD.getElementById("fpPort").value = "5900";
        HD.getElementById("fpExPort").value = "";
        HD.getElementById("fpPattern").value = "$type$ VNC:  $ip$:$port$";
        HD.getElementById("fpDitty").innerHTML = "<p><a href=\"https://en.wikipedia.org/wiki/Virtual_Network_Computing\">Virtual Network Computing - open source remote desktop (unencrypted)</a>";
      } elseIf (forService.ends("(ard)")) {
        HD.getElementById("fpName").value = "Apple Remote Desktop";
        HD.getElementById("fpPort").value = "5988";
        HD.getElementById("fpExPort").value = "";
        HD.getElementById("fpPattern").value = "$type$ Apple Remote Desktop:  $ip$:$port$";
        HD.getElementById("fpDitty").innerHTML = "<p><a href=\"https://www.apple.com/remotedesktop/\">Apple Remote Desktop</a>";
      } else {
        HD.getElementById("fpName").value = "";
        HD.getElementById("fpPort").value = "";
        HD.getElementById("fpExPort").value = "";
        HD.getElementById("fpPattern").value = "";
        HD.getElementById("fpDitty").innerHTML = "";
      }
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
