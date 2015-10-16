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
use UI:WebBrowser as WeBr;

use class Dz:Lui {

  new() self {
        properties {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
          IO:Log log = IO:Log.new();
          Int lvl = log.info;
        }
    }

    main() {
      Array args = System:Process.new().args;

      Web:Client:CertificateManager.validateHosts = false;

      if (args.length > 0) {
        String mode = args[0]; //ui, svc, both, [absent]
        log.log(lvl, "mode " + mode);
      } else {
        log.log(lvl, "mode empty");
      }
      if (TS.isEmpty(mode)) {
        mode = "ui";
      }
      if (mode == "ui") {
        webr = WeBr.new();
        webr.webHandler = self;
        webr.height = 450;
        webr.width = 320;
        //webr.content = Ve:App.new().readHtml("Dz.html");
        //webr.content = "<html><body><h1>hi</h1></body></html>";
        //put together string from 3 files, middle generated bejs
        String content = IO:File.new("DzA.html").reader.open().readString()
        + IO:File.new("BEL_4_Base.js").reader.open().readString()
        //+ IO:File.new("Dzmid.js").reader.open().readString()
        + IO:File.new("DzB.html").reader.open().readString();
        //content.print();
        webr.content = content;
        //webr.content = IO:File.new("Dz.html").reader.open().readString();
        webr.setup();
      }
   }

   initWeb() {

   }

    handleWeb(request) {
        try {
            Map arg = request.scriptArg;
            String mname = arg.get("action");
            if (undef(mname) || mname.ends("Request")!) {
              throw(Exc.new("Invalid request"));
            }
            String accountName = request.getSession("account.name");
            Array args = Array.new(2);
            args[0] = arg;
            args[1] = request;
            if (self.can(mname, args.length)) {
              var res = self.invoke(mname, args);
            }
            request.scriptReturn = res;
        } catch (var e) {
           arg = Map.new();
           log.log(lvl, "Caught exception during handleWeb B");
           if (def(e)) {
            log.log(lvl, "Error was " + e);
           }
            arg["action"] = "failResponse";
            if (e.sameClass(Alert.new()@)) {
              arg["reason"] = e.description;
            } else {
              arg["reason"] = "Sorry, unable to handle request";
            }
            request.scriptReturn = arg;
        }
    }

    exitRequest(Map arg, request) Map {
      exit();
      return(null);
    }

    exit() {
      webr.close();
      webr.exit();
    }

}

use class Dz:Alert(Exc) { }
