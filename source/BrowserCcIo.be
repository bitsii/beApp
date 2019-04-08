// Copyright 2015 Craig Welch
//
// Licensed under the MIT license. See LICENSE.txt file in the project root 
// for full license information.

use System:Thread:ContainerLocker as CLocker;

use UI:CcIo:InFlight as InFlight;

class InFlight {

   new() {
     fields {
       String allArgs;
       String callbackId;
     }
   }
   
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
        IO:Log log =@ IO:Logs.get(self);
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
     inflight.delete(inf);
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
    auto ll = splitAllArgs(inf.allArgs);
    String ress = handleWeb(ll[0], ll[1], ll[2]);
    if (undef(ress)) { ress = ""; }
    //fashion the js to run here
    String resjs = "handleCallbackInvId(\"" + Json:Marshaller.jsonEscape(ress) + "\", \"" + Json:Marshaller.jsonEscape(inf.callbackId) + "\");\n";
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
    } catch (any e) {
      log.log(System:Exceptions.toString(e));
    }
    return(ret);
  }
  
}

use UI:WebBrowserImpl as WebImp;
use UI:BrowserScriptRequest;



