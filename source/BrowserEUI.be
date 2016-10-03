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

var ui;
var hc;

var uiStartup = function(_ui) {
  ui = _ui;
  ui.bem_new_0();
  ui.bem_main_0();
  hc = new be_$class/UI:HtmlDom:Call$();
  hc = hc.bemc_getInitial();
  hc.bem_new_1(ui);
  ui.bem_startup_0();
}

var handleCallback = function(res) {
    if (res != null) {
      var bevs_resjs = new be_$class/Text:String$().bems_new(res);
      ui.bem_handleCallback_1(bevs_resjs);
    }
}

var convertArgs = function(args) {
  //make bemap
  //make bearray
  //put cname and args into map and return
  
  var alist = (new be_BEC_2_9_4_ContainerList()).bem_new_0();

  for (var i = 0; i < args.length; i++) {
    var ta = args[i];
    //add to array
    if (typeof ta === 'number') {
      //new int
      var aint = (new be_BEC_2_4_3_MathInt()).beml_set_bevi_int(ta);
      alist.bem_addValue_1(aint);
    } else if (typeof ta === 'string') {
      //new string
      var astr = (new be_BEC_2_4_6_TextString()).bems_new(ta);
      alist.bem_addValue_1(astr);
    }
  }
  
  return alist;
  
}

//callApp does invoke on app via a call to ui
var callApp = function() {
  var alist = convertArgs(arguments);
  hc.bem_callApp_1(alist);
}

//callUI does invoke on ui
var callUI = function() {
  var alist = convertArgs(arguments);
  return hc.bem_callUI_1(alist);
}

var getById = function(theId) {

}

"""
}

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

  default() self { }

  new(_callback) self {
    fields {
      Json:Marshaller mar = Json:Marshaller.new();
      Json:Unmarshaller unmar = Json:Unmarshaller.new();
      any callback = _callback;
      String pageToken;
    }
  }
  
  callApp(List args) {
     Map arg = Map.new();
     arg["action"] = args[0];
     args.delete(0);
     arg["args"] = args;
     arg["plugin"] = callback.name;
     call(arg);
   }
   
   callUI(List args) any {
     String aname = args[0];
     args.delete(0);
     if (callback.can(aname, args.length)) {
       return(callback.invoke(aname, args));
     }         
     return(null);
   }

  call(Map arg) {
    if (TS.notEmpty(pageToken)) {
      arg["pageToken"] = pageToken;
    }
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

