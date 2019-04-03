// Copyright 2015 Craig Welch
//
// Licensed under the MIT license. See LICENSE.txt file in the project root 
// for full license information.

use UI:CcIo:WebBrowser as IoBr;
class IoBr(WebImp) {

  default() self {
   }
   
   setupStuff() {
     fields {
        IO:Log log =@ IO:Logs.get(self);
        Map session = Map.new();
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
  
  outerHandleWeb(String allArgs) String {
    auto ll = splitAllArgs(allArgs);
    return(handleWeb(ll[0], ll[1], ll[2]));  
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



