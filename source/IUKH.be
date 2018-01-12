// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use System:Parameters;
use IO:File;
use IO:File:Path;

class Konnectii:Host {

  new(Parameters _params) self {
    fields {
      IO:Log log =@ IO:Logs.get(self);
      Parameters params = _params;
    }
  }
  
    main() {
      try {
        Parameters params = Parameters.new(System:Process.new().args);
        start(params);
      } catch (any e) {
        log.log("Exception in innerMain, error is " + e);
      }
    }
  
    start(Parameters params) {
      self.new(params);
      start();
    }
    
  start() this {
    log.log("starting kh");
    //params for source and dest files
    String moreConf;
    moreConf = params.getFirst("hostConfig");
    if (def(moreConf)) {
      params.addFile(File.apNew(moreConf));
    }
    moreConf = params.getFirst("bridgeConfig");
    if (def(moreConf)) {
      params.addFile(File.apNew(moreConf));
    }
  }
}
