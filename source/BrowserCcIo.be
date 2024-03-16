/*
 * Copyright (c) 2015-2023, the Brace App Authors.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Licensed under the BSD 2-Clause License (the "License").
 * See the LICENSE file in the project root for more information.
 *
 */

import System:Thread:ContainerLocker as CLocker;

import UI:CcIo:InFlight as InFlight;

class InFlight {

   new() {
     fields {
       String allArgs;
       String callbackId;
     }
   }
   
}

import UI:CcIo:WebBrowser as IoBr;
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
   }
   
   startRequest() InFlight {
     InFlight inf = InFlight.new();
     inflight.put(inf);
     return(inf);
   }
   
   endRequest(InFlight inf) {
     inflight.remove(inf);
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
  
  outerHandleWeb(InFlight inf) this {
    var ll = splitAllArgs(inf.allArgs);
    String ress = handleWeb(ll[0], ll[1], ll[2]);
    if (undef(ress)) { ress = ""; }
    //fashion the js to run here
    if (TS.isEmpty(inf.callbackId)) {
      String resjs = "handleCallback(\"" + Json:Marshaller.jsonEscape(ress) + "\");\n";
    } else {
      resjs = "handleNamedCallback(\"" + Json:Marshaller.jsonEscape(ress) + "\", \"" + Json:Marshaller.jsonEscape(inf.callbackId) + "\");\n";
    }
    inf.allArgs = resjs;
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
    } catch (dyn e) {
      log.log(System:Exceptions.toString(e));
    }
    return(ret);
  }
  
}

import UI:WebBrowserImpl as WebImp;
import UI:BrowserScriptRequest;



