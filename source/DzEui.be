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

emit(js) {
"""

var dzeui;
//ui startup
var startup = function() {
  dzeui = new be_BEL_4_Base_BEC_2_3_DzEui();
  dzeui.bem_new_0();
  dzeui.bem_main_0();
}

var playSound = function() {
  dzeui.bem_playSound_0();
}

var updateImage = function() {
  dzeui.bem_updateImage_0();
}

var login = function() {
  dzeui.bem_login_0();
}

var logout = function() {
  dzeui.bem_logout_0();
}

var clearImage = function() {
  dzeui.bem_clearImage_0();
}

var handleCallback = function(res) {
    if (res != null) {
      var bevs_resjs = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(res);
      dzeui.bem_handleCallback_1(bevs_resjs);
    }
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
    
    updateImage() {
      Map arg = Map.new();
      arg["module"] = "MediaIO";
      arg["action"] = "updateImageRequest";
      HC.new(self).call(arg);
   }
   
   playSound() {
      Map arg = Map.new();
      arg["module"] = "MediaIO";
      arg["action"] = "playSoundRequest";
      HC.new(self).call(arg);
   }
   
   
   login() {
      Map arg = Map.new();
      arg["module"] = "Accounts";
      arg["action"] = "loginRequest";
      arg["loginName"] = HD.getElementById("loginName").value;
      arg["loginPass"] = HD.getElementById("loginPass").value;
      HD.getElementById("loginName").value = "";
      HD.getElementById("loginPass").value = "";
      HC.new(self).call(arg);
   }
   
   logout() {
      clearImage();
      Map arg = Map.new();
      arg["module"] = "Accounts";
      arg["action"] = "logoutRequest";
      HC.new(self).call(arg);
   }
   
   updateImageResponse(Map arg) {
     HD.getElementById("imgdiv").innerHTML = arg["imghtm"];
   }
   
   clearImage() {
     HD.getElementById("imgdiv").innerHTML = "";
   }
}

use UI:HtmlDom:Document as HD;

class HD {
  default() self {
    
  }
  
  getElementById(String id) {
    return(HE.new(id));
  }
}

use UI:HtmlDom:Element as HE;

class HE {
  new(String id) self {
    emit(js) {
    """
    this.bevi_element = document.getElementById(beva_id.bems_toJsString());
    """
    }
  }
  
  valueSet(String val) self {
    emit(js) {
    """
    this.bevi_element.value = beva_val.bems_toJsString();
    """
    }
  }
  
  valueGet() String {
    String res;
    emit(js) {
    """
    bevl_res = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(this.bevi_element.value);
    """
    }
    return(res);
  }
  
  innerHTMLSet(String val) self {
    emit(js) {
    """
    this.bevi_element.innerHTML = beva_val.bems_toJsString();
    """
    }
  }
  
}

use UI:HtmlDom:Call as HC;

class HC {

  new(_callback) self {
    vars {
      Json:Marshaller mar = Json:Marshaller.new();
      Json:Unmarshaller unmar = Json:Unmarshaller.new();
      var callback = _callback;
    }
  }

  call(Map arg) {
    String argjs = mar.marshall(arg);
    String resjs;
    emit(js) {
    """
    if (typeof(window.external) !== 'undefined'
            && typeof(window.external.HandleCall) !== 'undefined') {
    var res = window.external.HandleCall(bevl_argjs.bems_toJsString());
    //document.getElementById("infotxt").value = res;
    if (res !== null) {
      bevl_resjs = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(res);
      //document.getElementById("infotxt").value = bevl_resjs.bems_toJsString();
    }
    } else {
      var req;
      if (window.XMLHttpRequest) {
        req = new XMLHttpRequest();
      } else if (window.ActiveXObject) {
        try {
          req = new ActiveXObject("Msxml2.XMLHTTP");
        } 
        catch (e) {
          try {
            req = new ActiveXObject("Microsoft.XMLHTTP");
          } 
          catch (e) {}
        }
      }
      var data = bevl_argjs.bems_toJsString();
      req.open('POST', '/', true);
      req.setRequestHeader("Content-type", "application/json");
      //req.setRequestHeader("Connection", "close");
      req.onreadystatechange = function(){
          if (req.readyState != 4) return;
          if (req.status != 200 && req.status != 304) {
              //logmsg('HTTP error ' + req.status);
              return;
          }
          //logmsg(req.responseText);
          handleCallback(req.responseText);
      }
      req.send(data);
    }
    """
    }
    if (def(resjs)) {
      handleCallback(resjs);
    }
  }
  
  handleCallback(String resjs) {
    Map resm = unmar.unmarshall(resjs);
    String mname = resm["action"];
    Array rargs = Array.new(1);
    rargs[0] = resm;
    if (def(mname) && mname.ends("Response") && callback.can(mname, rargs.length)) {
      callback.invoke(mname, rargs);
    }
  }
}

