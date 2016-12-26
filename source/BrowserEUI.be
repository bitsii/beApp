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
var hd;
var pageToken;

var uiStartup = function(_ui) {
  ui = _ui;
  ui.bem_new_0();
  ui.bem_main_0();
  hc = new be_$class/UI:HtmlDom:Call$();
  hc = hc.bemc_getInitial();
  hc.bem_new_1(ui);
  hd = new be_$class/UI:HtmlDom:Document$();
  hd = hd.bemc_getInitial();
  hd.bem_new_0();
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

//callHD does invoke on hd
var callHD = function() {
  var alist = convertArgs(arguments);
  return hd.bem_call_1(alist);
}

var downloadJson = function(jsonData, fileName) {
  var dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(jsonData);
  var downloadJsonElem = document.getElementById('downloadJsonElem');
  downloadJsonElem.setAttribute("href", dataStr );
  downloadJsonElem.setAttribute("download", fileName);
  downloadJsonElem.click();
}

"""
}

class HD {
  default() self {
    fields {
      IO:Log log = IO:Logs.get(self);
    }
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
  
  hrefSet(String url) {
    emit(js) {
    """
      location = beva_url.bems_toJsString();
    """
    }
  }
  
  call(List args) any {
     String aname = args[0];
     args.delete(0);
     if (self.can(aname, args.length)) {
       return(self.invoke(aname, args));
     }         
     return(null);
   }
   
   hrefGet() String {
     String res;
      emit(js) {
      """
      bevl_res = new be_$class/Text:String$().bems_new(window.location.href);
      """
      }
      return(res);     
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
  
  hrefSet(String val) self {
    emit(js) {
    """
    this.bevi_element.href = beva_val.bems_toJsString();
    """
    }
  }
  
  hrefGet() String {
    String res;
    emit(js) {
    """
    bevl_res = new be_$class/Text:String$().bems_new(this.bevi_element.href);
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
  
  pageTokenSet(String _pageToken) this {
    pageToken = _pageToken;
    emit(js) {
    """
    pageToken = beva__pageToken.bems_toJsString();
    """
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
     } elseIf (self.can(aname, args.length)) {
       return(self.invoke(aname, args));
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
              //location.reload();
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
        handleCallbackMap(resm);
    }
  }
    
  handleCallbackMap(Map resm) {
      String mname = resm["action"];
      if (def(mname) && mname.ends("Response")) {
        if (resm.has("args")) {
          rargs = resm["args"];
        } else {
          List rargs = List.new(1);
          rargs[0] = resm;
        }
        String show = rargs.size.toString();
        if (callback.can(mname, rargs.length)) {
          callback.invoke(mname, rargs);
        } elseIf(self.can(mname, rargs.length)) {
          self.invoke(mname, rargs); 
        }
      }
    }
  
   toggleDisplay(String id) {
     HE he = HD.getElementById(id);
     if (he.display == "block") {
      he.display = "none";
     } else {
      he.display = "block";
     }
   }
   
   multiResponse(List res) {
     for (Map resm in res) {
        handleCallbackMap(resm);
     }
   }
   
   setElementsValuesResponse(Map idvals) {
     for (any kv in idvals) {
      HD.getElementById(kv.key).value = kv.value;
     }
   }
   
   setElementsDisplaysResponse(Map idvals) {
     for (any kv in idvals) {
      HD.getElementById(kv.key).display = kv.value;
     }
   }
   
   setElementsInnerHTMLResponse(Map idvals) {
     for (any kv in idvals) {
      HD.getElementById(kv.key).innerHTML = kv.value;
     }
   }
   
   reloadResponse() {
     HD.reload();
   }
   
}

