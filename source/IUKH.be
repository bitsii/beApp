// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use System:Parameters;
use IO:File;
use IO:File:Path;

class Konnectii:Host {

  new(Parameters _orgParams) self {
    fields {
      IO:Log log =@ IO:Logs.get(self);
      IO:Logs.turnOnAll();
      Parameters orgParams = _orgParams;
    }
  }
  
    main() {
      try {
        Parameters params = Parameters.new(System:Process.new().args);
        self.new(params);
        go();
      } catch (any e) {
        log.log("Exception in innerMain, error is " + e);
      }
    }
    
    getParmsCopy() {
      return(System:Serializer.new().deserialize(System:Serializer.new().serialize(orgParams)));
    }
  
    go() {
      //loop here
      Int count = 0;
      while (count < 1 || orgParams.isTrue("runForever")) {
        count++=;
        Parameters params = getParmsCopy();
        doWifi(params);
        doBridge(params);
        Time:Sleep.sleepSeconds(10);
      }
    }
    
  doWifi(Parameters params) this {
    //log.log("starting doWifi");
    //params for source and dest files
    String moreConf;
    moreConf = params.getFirst("hostConfig");
    if (def(moreConf)) {
      File mcf = File.apNew(moreConf);
      if (mcf.exists) {
        params.addFile(mcf);
      }
    }
    Bool doPostSleep = false;
    // etc/wpa_supplicant/wpa_supplicant.conf
    if (def(params.getFirst("wpaSup"))) {
      if (def(params.getFirst("ssid")) && def(params.getFirst("psk"))) {
         log.log("Will now setup wpaSup");
         String ws = File.apNew(params.getFirst("wpaSup")).reader.open().readStringClose();
         Int pos = ws.find("network={"); //}
         if (def(pos)) {
           ws = ws.substring(0, pos);
         }
         ws += "network={\nssid=\"" += params.getFirst("ssid") += "\"\n";
         ws += "psk=\"" += params.getFirst("psk") += "\"\n}\n";
         //ws.print();
         File.apNew(params.getFirst("wpaSup")).writer.open().writeClose(ws);
         if (params.isTrue("wpaRestart")) {
          System:Command.new("wpa_cli -i wlan0 reconfigure").run();
          if (def(params.getFirst("wpaPostRestartPause"))) {
            Time:Sleep.sleepSeconds(Int.new(params.getFirst("wpaPostRestartPause")));
          }
         }
      }
    }
    if (def(moreConf) && params.isTrue("rmHostConfig")) {
      File wsf = File.apNew(params.getFirst("hostConfig"));
      wsf.delete();
    }
  }
  
  //INIMAPSRV,INIMAPACCT,INIMAPPASS,INDNAME
  
  doBridge(Parameters params) this {
    //log.log("starting doBridge");
    //params for source and dest files
    String moreConf;
    moreConf = params.getFirst("bridgeConfig");
    if (def(moreConf)) {
      File mcf = File.apNew(moreConf);
      if (mcf.exists) {
        params.addFile(mcf);
      }
    }
    
    //def(params.getFirst("bridgePropFile")).print();
    //def(params.get("bridgeProp")).print();
    //params.isTrue("bpHasProps").print();
    
    if (def(params.getFirst("bridgePropFile")) && def(params.get("bridgeProp")) && params.isTrue("bpHasProps")) {
      log.log("Will now setup bridge");
      File bpf = File.apNew(params.getFirst("bridgePropFile"));
      auto bpl = params.get("bridgeProp");
      if (bpf.exists) {
        bpf.delete();
      }
      auto inpw = bpf.writer.open();
      for (String key in bpl) {
        String val = params.getFirst("bp_" + key);
        if (def(val)) {
          inpw.write("export " + key + "=\"" + val + "\"\n");
        }
      }
      inpw.close();
      if (def(params.getFirst("bridgeInstallScript"))) {
        System:Command.new(params.getFirst("bridgeInstallScript")).run();
      }
    }
    if (def(moreConf) && params.isTrue("rmBridgeConfig")) {
      File wsf = File.apNew(params.getFirst("bridgeConfig"));
      wsf.delete();
    }
  }
  
}
