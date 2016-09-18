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

class HD {
  default() self {
    
  }
  
  getElementById(String id) {
    return(HE.new(id));
  }
  
  reload() {
    emit(js) {
    """
    location.reload();
    """
    }
  }
}

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
    bevl_res = new be_$class/Text:String$().bems_new(this.bevi_element.value);
    """
    }
    return(res);
  }
  
  checkedSet(Bool val) self {
    emit(js) {
    """
    this.bevi_element.checked = beva_val.bevi_bool;
    """
    }
  }
  
  checkedGet() Bool {
    Bool res;
    emit(js) {
    """
    bevl_res = new be_$class/Logic:Bool$();
    bevl_res.bevi_bool = this.bevi_element.checked;
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
  
  innerHTMLGet() String {
    String res;
    emit(js) {
    """
    bevl_res = new be_$class/Text:String$().bems_new(this.bevi_element.innerHTML);
    """
    }
    return(res);
  }
  
  displaySet(String val) self {
    emit(js) {
    """
    this.bevi_element.style.display = beva_val.bems_toJsString();
    """
    }
  }
  
  displayGet() String {
    String res;
    emit(js) {
    """
    bevl_res = new be_$class/Text:String$().bems_new(this.bevi_element.style.display);
    """
    }
    return(res);
  }
  
}

class HC {

  new(_callback) self {
    fields {
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
    if (typeof(window) !== 'undefined' && typeof(window.external) !== 'undefined'
            && typeof(window.external.HandleCall) !== 'undefined') {
      var res = window.external.HandleCall(bevl_argjs.bems_toJsString());
      //document.getElementById("infotxt").value = res;
      if (res !== null && typeof(res) !== 'undefined') {
        bevl_resjs = new be_$class/Text:String$().bems_new(res);
        //document.getElementById("infotxt").value = bevl_resjs.bems_toJsString();
      }
    } else if (typeof(Android) !== 'undefined') {
      var res = Android.HandleCall(bevl_argjs.bems_toJsString());
      if (res !== null  && typeof(res) !== 'undefined') {
        bevl_resjs = new be_$class/Text:String$().bems_new(res);
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
    if (def(resm)) {
      String mname = resm["action"];
      List rargs = List.new(1);
      rargs[0] = resm;
      if (def(mname) && mname.ends("Response") && callback.can(mname, rargs.length)) {
        callback.invoke(mname, rargs);
      }
    }
  }
}

