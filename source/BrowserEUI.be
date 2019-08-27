// Copyright 2015 Craig Welch
//
// Licensed under the MIT license. See LICENSE.txt file in the project root 
// for full license information.

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

var uiStartup = function(_uiClassName) {

  var mtdnm = (document.getElementById('beApWkAppStart'))? document.getElementById('beApWkAppStart').value : '';
  var rcm = new be_$class/App:RunClassMethod$();
  var mtdnmbs = new be_$class/Text:String$().bems_new(mtdnm);
  rcm.bem_doWhatsNeeded_1(mtdnmbs);

  var tmpo = new be_$class/System:Object$();
  ui = tmpo.bem_createInstance_1(new be_$class/Text:String$().bems_new(_uiClassName));
  ui.bem_new_0();
  ui.bem_main_0();
  hc = new be_$class/UI:HtmlDom:Call$();
  hc = hc.bemc_getInitial();
  hd = new be_$class/UI:HtmlDom:Document$();
  hd = hd.bemc_getInitial();
  hd.bem_new_0();
  ui.bem_startup_0();
  
}

var readAndRun = function(jsargs) {
  var ras = new be_$class/System:RunAsync$();
  var beargs = new be_$class/Text:String$().bems_new(jsargs);
  ras.bem_readAndRun_1(beargs);
}

var handleCallback = function(res) {
    if (res != null) {
      var bevs_resjs = new be_$class/Text:String$().bems_new(res);
      hc.bem_handleCallback_1(bevs_resjs);
    }
}

var handleNamedCallback = function(res, name) {
    if (res != null) {
      var bevs_resjs = new be_$class/Text:String$().bems_new(res);
      var bevs_namejs = new be_$class/Text:String$().bems_new(name);
      hc.bem_handleNamedCallback_2(bevs_resjs, bevs_namejs);
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
    } else if (typeof ta === 'boolean') {
      var abool = (new be_BEC_2_5_4_LogicBool()).beml_set_bevi_bool(ta);
      alist.bem_addValue_1(abool);
    } else if (ta == null) {
      alist.bem_addValue_1(null);
    }
  }
  
  return alist;
  
}

//callApp does invoke on app via a call to ui
var callApp = function() {
  var alist = convertArgs(arguments);
  hc.bem_callApp_1(alist);
}

var callAppLaterInside = function(myhc, alist) {
  myhc.bem_callApp_1(alist.bem_copy_0());
}

var callUILaterInside = function(myhc, alist) {
  myhc.bem_callUI_1(alist.bem_copy_0());
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

//ui startup
var startup = function() {
  uiStartup(document.getElementById("beUiMain").value);
}

if (typeof(window) !== 'undefined') {
  window.onload = startup;
}

"""
}

class HD {
  default() self {
    fields {
      IO:Log log =@ IO:Logs.get(self);
    }
  }
  
  copyField(String name) {
     emit(js) {
     """
     var fld = document.getElementById(beva_name.bems_toJsString());
     if (fld.type == "password") {
       var waspass = 1;
       fld.type = "text";
     }
     fld.focus();
     fld.select();
     document.execCommand('copy');
     if (waspass == 1) {
       fld.type = "password";
     }
     """
     }
   }
   
   pasteField(String name) {
     emit(js) {
     """
     var fld = document.getElementById(beva_name.bems_toJsString());
     if (fld.type == "password") {
       var waspass = 1;
       fld.type = "text";
     }
     fld.focus();
     fld.select();
     document.execCommand('paste');
     if (waspass == 1) {
       fld.type = "password";
     }
     """
     }
   }
   
   getElementsByName(String name) List {
     List elements = List.new();
     emit(js) {
     """
     var x = document.getElementsByName(beva_name.bems_toJsString());
      var i;
      for (i = 0; i < x.length; i++) {
        """
      }
      HE he = HE.new();
      elements += he;
      emit(js) {
        """
          bevl_he.bevi_element = x[i];
      } 
     """
     }
     return(elements);
   }
  
  getElementById(String id) {
    return(HE.new(id));
  }
  
  getEle(String id) {
    return(HE.new(id));
  }
  
  setDis(String id, String dis) {
    HE.new(id).display = dis;
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
   
   titleSet(String title) self {
    emit(js) {
    """
    document.title = beva_title.bems_toJsString();
    """
    }
   }
   
   titleGet() String {
     String res;
      emit(js) {
      """
      bevl_res = new be_$class/Text:String$().bems_new(document.title);
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
  
  click() self {
    emit(js) {
    """
    this.bevi_element.click();
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
  
  typeSet(String val) self {
    emit(js) {
    """
    this.bevi_element.type = beva_val.bems_toJsString();
    """
    }
  }
  
  typeGet() String {
    String res;
    emit(js) {
    """
    bevl_res = new be_$class/Text:String$().bems_new(this.bevi_element.type);
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
  
  existsGet() Bool {
    
    emit(js) {
    """
      if (this.bevi_element !== null && typeof(this.bevi_element) !== 'undefined') { //}
    """
    }
    return(true);
    emit(js) {
    """
    //{
    }
    """
    }
    return(false);
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
  
  styleSet(String val) self {
    emit(js) {
    """
    this.bevi_element.style = beva_val.bems_toJsString();
    """
    }
  }
  
  styleGet() String {
    String res;
    emit(js) {
    """
    bevl_res = new be_$class/Text:String$().bems_new(this.bevi_element.style);
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

  default() self {
    fields {
      IO:Log log =@ IO:Logs.get(self);
      any apwkHandler;
    }
  }

  new(_callbacks) self {
    fields {
      List callbacks = _callbacks.copy().addValue(self);
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
     call(arg);
   }
   
   callUI(List args) any {
     String aname = args[0];
     args.delete(0);
     for (any callback in callbacks) {
       if (callback.can(aname, args.length)) {
         return(callback.invoke(aname, args));
       }
     }
     for (callback in callbacks) {
       if (callback.can(aname, 1)) {
         List ca = List.new();
         ca.put(0, args);
         return(callback.invoke(aname, ca));
       }
     }       
     return(null);
   }
   
   callAppLater(List args, Int waitHowLong) {
     emit(js) {
     """
     setTimeout(function(){callAppLaterInside(hc, beva_args)}, beva_waitHowLong.bevi_int);
     """
     }
   }
   
   callUILater(List args, Int waitHowLong) {
     emit(js) {
     """
     setTimeout(function(){callUILaterInside(hc, beva_args)}, beva_waitHowLong.bevi_int);
     """
     }
   }
   
   pollApp(List args, Int waitHowLong) {
     emit(js) {
     """
     setInterval(function(){callAppLaterInside(hc, beva_args)}, beva_waitHowLong.bevi_int);
     """
     }
   }
   
   pollUI(List args, Int waitHowLong) {
     emit(js) {
     """
     setInterval(function(){callUILaterInside(hc, beva_args)}, beva_waitHowLong.bevi_int);
     """
     }
   }
   
   combineArgs(String argjs, String url, String ctype) String {
     String comba = String.new();
     if (undef(argjs)) {
       comba += "N:"
     } else {
       comba += argjs.size += ":";
     } 
     if (undef(url)) {
       comba += "N:"
     } else {
       comba += url.size += ":";
     }
     if (undef(ctype)) {
       comba += "N:";
     } else {
       comba += ctype.size += ":";
     }
     if (def(argjs)) {
      comba += argjs;
     }
     if (def(url)) {
       comba += url;
     }
     if (def(ctype)) {
       comba += ctype;
     }
     return(comba);
   }
   
   send(String _argjs, String url, String contentType, String name) this {
     String argjs = _argjs;
     String resjs;
     emit(js) {
    """
    if (typeof(Android) !== 'undefined') { //}
    """
    }
    String comboargs = combineArgs(argjs, url, contentType);
    //log.log("android will send comboargs " + comboargs);
    emit(js) {
    """
      var res = Android.HandleCall(bevl_comboargs.bems_toJsString());
      if (res !== null  && typeof(res) !== 'undefined') {
        bevl_resjs = new be_$class/Text:String$().bems_new(res);
        //document.getElementById("infotxt").value = bevl_resjs.bems_toJsString();
      }
      //{
    } else { //}
    """
    }
    ifEmit(apwkui) {
      resjs = apwkHandler.handleWeb(argjs, url, contentType);
    }
    ifNotEmit(apwkui) {
    emit(js) {
    """
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
      req.open('POST', beva_url.bems_toJsString(), true);
      req.setRequestHeader("Content-type", beva_contentType.bems_toJsString());
      //req.setRequestHeader("Connection", "close");
      req.onreadystatechange = function(){
          if (req.readyState != 4) return;
          if (req.status != 200 && req.status != 304) {
              //logmsg('HTTP error ' + req.status);
              //location.reload();
              return;
          }
          //logmsg(req.responseText);
          if (beva_name != null) {
            handleNamedCallback(req.responseText, beva_name.bems_toJsString());
          } else {
            handleCallback(req.responseText);
          }
      }
      req.send(data);
    """
    }
    }
    emit(js) {
    """
      //{
    }
    """
    }
    if (def(resjs)) {
      if (def(name)) {
        handleNamedCallback(resjs, name);
      } else {
        handleCallback(resjs);
      }
    }
    return(self);
   }

  call(Map arg) {
    if (TS.notEmpty(pageToken)) {
      arg["pageToken"] = pageToken;
    }
    String argjs = Json:Marshaller.marshall(arg);
    send(argjs, "/", "application/json", null);
  }
  
  handleCallback(String resjs) {
    Map resm = Json:Unmarshaller.unmarshall(resjs);
    if (def(resm)) {
        handleCallbackMap(resm);
    }
  }
  
  handleNamedCallback(String res, String name) {
      if (def(name) && name.ends("Response")) {
        List rargs = List.new(1);
        rargs[0] = res;
        String show = rargs.size.toString();
        for (any callback in callbacks) {
          if (callback.can(name, rargs.length)) {
            callback.invoke(name, rargs);
            break;
          } 
        }
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
        for (any callback in callbacks) {
          if (callback.can(mname, rargs.length)) {
            callback.invoke(mname, rargs);
            break;
          } 
        }
      }
    }
  
   toggleDisplay(String id) Bool {
     //returns true if was opened by this action, false else
     Bool didOpen = false;
     HE he = HD.getElementById(id);
     if (he.display == "block") {
      he.display = "none";
     } else {
      he.display = "block";
      didOpen = true;
     }
     return(didOpen);
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
   
   setValResponse(Map idvals) {
    setElementsValuesResponse(idvals);
   }
   
   setElementsDisplaysResponse(Map idvals) {
     for (any kv in idvals) {
       HD.getElementById(kv.key).display = kv.value;
     }
   }
   
   setDisResponse(Map idvals) {
    setElementsDisplaysResponse(idvals);
   }
   
   setElementsInnerHTMLResponse(Map idvals) {
     for (any kv in idvals) {
      HD.getElementById(kv.key).innerHTML = kv.value;
     }
   }
   
   reloadResponse() {
     HD.reload();
   }
   
   clearOptionsResponse(String selectId) {
     emit(js) {
     """
          var select = document.getElementById(beva_selectId.bems_toJsString());
          var i;
          for(i = select.options.length - 1 ; i >= 0 ; i--)
          {
              select.remove(i);
          }
     """
     }
   }
   
   addOptionsResponse(String selectId, Map textVals) {
     emit(js) {
     """
       var select = document.getElementById(beva_selectId.bems_toJsString());
     """
     }
     
     for (auto kv in textVals) {
       String val = kv.value;
       String txt = kv.key;
       emit(js) {
       """
         var opt = document.createElement("option");
         opt.value = bevl_val.bems_toJsString();
         opt.textContent = bevl_txt.bems_toJsString();
         select.appendChild(opt);
       """
       }
     }
   }
   
   setSelectedOptionResponse(String selectId, String text) {
   
     emit(js) {
     """
       var dd = document.getElementById(beva_selectId.bems_toJsString());
       var textToFind = beva_text.bems_toJsString();
       for (var i = 0; i < dd.options.length; i++) {
        if (dd.options[i].text === textToFind) {
            dd.selectedIndex = i;
            break;
        }
       }
     """
     }
   }
   
   setOptionsSelectedResponse(String selectId, Map textVals, String text) {
     clearOptionsResponse(selectId);
     addOptionsResponse(selectId, textVals);
     if (TS.notEmpty(text)) {
      setSelectedOptionResponse(selectId, text);
     }
   }
   
   setOptionsResponse(String selectId, Map textVals) {
     clearOptionsResponse(selectId);
     addOptionsResponse(selectId, textVals);
   }
   
}
