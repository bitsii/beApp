// Copyright 2015 The BraceApp Authors. All rights reserved.
// Use of this source code is governed by the BSD-3-Clause
// license that can be found in the LICENSE file.

use System:Thread:ContainerLocker as CLocker;

use UI:CcIo:InFlight as InFlight;

emit(js) {
"""

var jsis;

var setupStuffJs = function() {
  jsis = new be_$class/UI:CcIo:WebBrowser$();
  jsis = jsis.bemc_getInitial();
}

"""
}

use UI:CcIo:WebBrowser as IoBr;
class IoBr(WebImp) {

  getMe() self {
    return(IoBr.new());
  }
  
  default() self {
   }
   
   setupStuff() {
     fields {
        IO:Log log = IO:Logs.get(self);
        Map session = Map.new();
        CLocker inflight = CLocker.new(Set.new());
     }
     UI:HtmlDom:Call.apwkHandlerSet(self);
     emit(js) {
      """
      setupStuffJs()
      """
      }
   }
   
   initWeb() self {
     setupStuff();
     webHandler.initWeb();
   }
   
   setup() {
   initWeb();
     
  }
  
  close() {
  }
  
  titleGet() String {
    return(setupHandler.title);
  }
  
  heightGet() Int {
    return(setupHandler.height);
  }
  
  widthGet() Int {
    return(setupHandler.width);
  }
  
  contentGet() String {
    return(setupHandler.content);
  }
  
  locationGet() String {
    return(setupHandler.location);
  }
  
  outerHandleWebJs(String allArgs, String callbackId) String {
    auto ll = splitAllArgs(allArgs);
    
    String ress = handleWeb(ll[0], ll[1], ll[2]);
    if (undef(ress)) { ress = ""; }
    //fashion the js to run here
    if (TS.isEmpty(callbackId)) {
      String resjs = "handleCallback(\"" + Json:Marshaller.jsonEscape(ress) + "\");\n";
    } else {
      resjs = "handleNamedCallback(\"" + Json:Marshaller.jsonEscape(ress) + "\", \"" + Json:Marshaller.jsonEscape(callbackId) + "\");\n";
    }
    return(resjs);
  }
  
  handleWeb(String arg, String uri, String ctype) String {
    log.log("in handleWeb, arg " + arg);
    try {
      BrowserScriptRequest r = BrowserScriptRequest.new(session);
      r.scriptArgJson = arg;
      r.uri = uri;
      r.inputContentType = ctype;
      webHandler.handleWeb(r);
      String ret = r.scriptReturnJson;
      if (def(ret)) {
        log.log("in handleWeb, ret " + ret);
      }
    } catch (any e) {
      log.log(System:Exceptions.toString(e));
    }
    return(ret);
  }
  
}

use UI:WebBrowserImpl as WebImp;
use UI:BrowserScriptRequest;



