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
        String moreConf;
        moreConf = params.getFirst("hostConfig");
        if (def(moreConf)) {
          File mcf = File.apNew(moreConf);
          if (mcf.exists) {
            params.addFile(mcf);
          }
        }
        doHost(params);
        doBridge(params);
        if (def(moreConf) && params.isTrue("rmHostConfig")) {
          File wsf = File.apNew(params.getFirst("hostConfig"));
          wsf.delete();
        }
        Time:Sleep.sleepSeconds(10);
      }
    }
    
  doHost(Parameters params) this {
    //log.log("starting doHost");
    //params for source and dest files
    Bool doPostSleep = false;
    if (def(params.getFirst("pipass"))) {
      String ppchs = "ppch" + System:Random.getString(4) + ".sh";
      File ppch = File.apNew(ppchs);
      String ppchstr = String.new();
      ppchstr += "echo \"pi:" += params.getFirst("pipass") += "\" | chpasswd\n";
      ppch.writer.open().writeStringClose(ppchstr);
      System:Command.new("chmod +x " + ppchs).run();
      Time:Sleep.sleepSeconds(10);
      System:Command.new("bash -c ./" + ppchs).run();
      Time:Sleep.sleepSeconds(10);
      ppch.delete();
    }
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
         File.apNew(params.getFirst("wpaSup")).writer.open().writeStringClose(ws);
         if (params.isTrue("wpaRestart")) {
          System:Command.new("wpa_cli -i wlan0 reconfigure").run();
          if (def(params.getFirst("wpaPostRestartPause"))) {
            Time:Sleep.sleepSeconds(Int.new(params.getFirst("wpaPostRestartPause")));
          }
         }
      }
    }
    if (params.isTrue("enableSsh")) {
      System:Command.new("systemctl enable ssh");
      System:Command.new("systemctl start ssh");
    }
    if (params.isTrue("disableSsh")) {
      System:Command.new("systemctl disable ssh");
      System:Command.new("systemctl stop ssh");
    }
    if (def(params.getFirst("postHostScript"))) {
      System:Command.new(params.getFirst("postHostScript")).run();
    }
  }
  
  doBridge(Parameters params) this {
    //log.log("starting doBridge");
    
    //def(params.getFirst("bridgePropFile")).print();
    //def(params.get("bridgeProp")).print();
    //params.isTrue("bp_doSetup").print();
    
    if (def(params.getFirst("bridgePropFile")) && def(params.get("bridgeProp")) && params.isTrue("bp_doSetup")) {
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
      if (def(params.getFirst("postBridgeScript"))) {
        System:Command.new(params.getFirst("postBridgeScript")).run();
      }
    }
  }
  
}
