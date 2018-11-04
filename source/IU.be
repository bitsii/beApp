// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use IO:File:Path;
use IO:File;
use System:Random;
local use IU:WebConnect;

use Net:UPnP as Upnp;
use Net:Wol;
use Net:IP;

emit(jv) {
"""
import java.net.InetAddress;
"""
}

class IU:WebConnect {

  new() self {
    fields {
      IO:Log log =@ IO:Logs.get(self);
      
      String gateway;
      String internalAddress;
      String externalAddress;
      String hostedAddress;
      String konnAddress;
      String konniAddress;
      String internalPort = "";
      String internaliPort = "";
      String externalPort = "";
      String protocol = "https://";
      String internalBase;
      String externalBase;
      String hostedBase;
      String konnBase;
      String konniBase;
      String internalUrl;
      String externalUrl;
      String hostedUrl;
      String konnUrl;
      String konniUrl;
      String internalLink;
      String externalLink;
      String hostedLink;
      String konnLink;
      String konniLink;
      
      String homePage;
      Bool onPublicNet = false;
      Bool doingUpnp = true;
      Bool doingDns = false;
      Bool internalResolve = false;
      
      String certificatePrint = "";
      List internalMacAddresses = List.new();
      String extraPorts;
      Map extraPortMap = Map.new();
      Map servicesConf = Map.new();
      
      String deviceId;
      String deviceName = "";
      
      String sharedLoginToken;
      
      String extNameBase;
      
    }
  }
  
  internalResolveGet() Bool {
    if (undef(internalResolve)) {
      return(false);
    }
    return(internalResolve);
  }
  
  manualForwardGet() Bool {
    Bool mf = false;
    if (def(doingUpnp) && doingUpnp! && TS.isEmpty(hostedAddress)) {
      mf = true;
    }
    return(mf);
  }
  
  webProtoSet(String proto) {
    protocol = proto + "://";
  }
  
  toMap() Map {
    Map res = Maps.fieldsIntoMap(self, Map.new());
    res.delete("log");
    return(res);
  }
  
  fromMap(Map fr) this {
    Maps.mapIntoFields(fr, self);
    log = IO:Logs.get(self);
  }
  
  getAPort() String {
    Int externalPorti = System:Random.getIntMax(30000);
    externalPorti += 3000;
    return(externalPorti.toString());
  }

  updateInternal(String _homePage) self {
    homePage = _homePage;
    Upnp upnp = Upnp.new();
    upnp.netGw = IP.gatewayIP;
    gateway = upnp.netGw;
    internalAddress = upnp.internalIP;
    Net:Interface ni = Net:Interface.new();
    internalMacAddresses.clear();
    internalMacAddresses += ni.interfaceForNetwork(upnp.netGw).macAddress;
    for (ni in ni.localInterfaces) {
      internalMacAddresses += ni.macAddress;
    }
    
      if (TS.notEmpty(internalPort)) {
        String intPort = ":" + internalPort;
      } else {
        intPort = "";
      }
      if (TS.notEmpty(internalAddress)) {
        internalBase = protocol + internalAddress + intPort;
        internalUrl = internalBase + homePage;
        internalLink = "<a href=\"" + internalUrl + "\" target=\"_blank\">Internal " + deviceName + " Edgii Bridge</a> - use on device's network.";
        log.log("Internal url " + internalUrl);
      }
  }
  
  updateExternal(String _homePage, String _extNameBase, Bool doUpnp, Bool doesIr, Bool _onPublicNet) self {
    homePage = _homePage;
    onPublicNet = _onPublicNet;
    doingUpnp = doUpnp;
    internalResolve = doesIr;
    Upnp upnp = Upnp.new();
    upnp.netGw = IP.gatewayIP;
    gateway = upnp.netGw;
    
    extNameBase = _extNameBase;
    
    externalPort = internalPort;
    
    try {
        if (doUpnp) {
          String ea = upnp.externalIP;
        } else {
          //externalAddress = null; //use to test bridge updates
        }
        if (TS.notEmpty(ea)) {
          externalAddress = ea;
        }
      } catch (any e) {
        //don't change external ip when upnp fails
        log.log("Upnp externalAddress failed");
        if (def(e)) { log.log(e.toString()); }
      }
    
      if (TS.notEmpty(externalPort)) {
        String extPort = ":" + externalPort;
      } else {
        extPort = "";
      }
      if (TS.notEmpty(externalAddress)) {
        if (TS.notEmpty(extNameBase)) {
          externalBase = protocol + extNameBase + extPort;
        } else {
          externalBase = protocol + externalAddress + extPort;  
        }
        externalUrl = externalBase + homePage;
        externalLink = "<a href=\"" + externalUrl + "\" target=\"_blank\">External " + deviceName + " Edgii Bridge</a> - use outside device's network.";
        log.log("External url " + externalUrl);
      }
      if (onPublicNet) {
        externalUrl = "";
        externalLink = "";
        internalUrl = "";
        internalLink = "";
        //hostedAddress = internalAddress;
      }
      updateHosted();
      updateKonniLink();
      updateKonnLink();
  }
  
  updateHosted() {
    if (TS.notEmpty(externalPort)) {
      String extPort = ":" + externalPort;
    } else {
      extPort = "";
    }
    if (TS.notEmpty(hostedAddress)) {
      hostedBase = protocol + hostedAddress + extPort;          
      hostedUrl = hostedBase + homePage;
      hostedLink = "<a href=\"" + hostedUrl + "\" target=\"_blank\">Hosted " + deviceName + " Edgii Bridge</a> - use wherever there's internet.";
      log.log("Hosted url use wherever there's internet." + hostedUrl);
    } else {
      hostedBase = "";
      hostedUrl = ""
      hostedLink = "";
    }
  }
  
  updateExternal() {
    if (TS.notEmpty(externalPort)) {
      String extPort = ":" + externalPort;
    } else {
      extPort = "";
    }
    if (TS.notEmpty(externalAddress)) {
       if (TS.notEmpty(extNameBase)) {
          externalBase = protocol + extNameBase + extPort;
        } else {
          externalBase = protocol + externalAddress + extPort;  
        }
        externalUrl = externalBase + homePage;
        externalLink = "<a href=\"" + externalUrl + "\" target=\"_blank\">External " + deviceName + " Edgii Bridge</a> - use outside device's network.";
        log.log("External url " + externalUrl);
    } else {
      externalBase = "";
      externalUrl = ""
      externalLink = "";
    }
  }
  
  updateKonnLink() {
    if (TS.notEmpty(externalPort)) {
      String extPort = ":" + externalPort;
    } else {
      extPort = "";
    }
    if (TS.notEmpty(konnAddress)) {
        if (TS.notEmpty(konniAddress)) {
          String ua = "use outside device's network.";
        } else {
          ua = "use on internet.";
        }
        konnBase = protocol + konnAddress + extPort;
        konnUrl = konnBase + homePage;
        konnLink = "<a href=\"" + konnUrl + "\" target=\"_blank\">" + deviceName + " Edgii Bridge</a> - " + ua;
        log.log("Virtual DNS url use on internet." + konnUrl);
      } else {
        konnAddress = "";
        konnBase = "";
        konnUrl = ""
        konnLink = "";
      }
  }
  
  updateKonniLink() {
    if (TS.notEmpty(internaliPort)) {
      String extPort = ":" + internaliPort;
    } else {
      extPort = "";
    }
    if (TS.notEmpty(konniAddress)) {
        konniBase = protocol + konniAddress + extPort;
        konniUrl = konniBase + homePage;
        konniLink = "<a href=\"" + konniUrl + "\" target=\"_blank\">" + deviceName + " Edgii Bridge</a> - use on device's network.";
        log.log("Internal DNS url." + konniUrl);
      } else {
        konniAddress = "";
        konniBase = "";
        konniUrl = ""
        konniLink = "";
      }
  }
  
    putService(String name, String port, String iport, String exPort, String urlPat) {
      log.log("adding service");
      String extPort = self.extraPorts;
      if (TS.notEmpty(port)) {
       Bool present = false;
       if (TS.notEmpty(extPort)) {
         //see if present
         any eps = extPort.split(",");
         for (String ep in eps) {
          if (ep == port) {
            present = true;
          }
         }       
       }
       unless (present) {
        log.log("extport notpresent");
        if (TS.notEmpty(extPort)) {
          extPort = extPort + "," + port;//no +=, effect existing svc
        } else {
          extPort = port.copy();
        }
        //det the port now
        if (TS.isEmpty(exPort)) {
          exPort = getAPort();
        }
        extraPortMap.put(port, exPort);
        extraPorts = extPort;
       } else {
         log.log("extport present");
         if (TS.notEmpty(exPort)) {
          //port selected
          extraPortMap.put(port, exPort);
         }
       }
       log.log("urlPat " + urlPat);
       if (TS.isEmpty(iport)) {
        iport = getAPort();
      }
       Map epConf = Maps.from("name", name, "urlPat", urlPat, "iport", iport);
       if (undef(servicesConf)) {
        servicesConf = Map.new();
       }
       servicesConf.put(port, epConf);
       log.log("added");
      }
    }
    
    deleteService(String port) {
      log.log("deleting service");
      String newPorts = "";
      String extPort = self.extraPorts;
      if (TS.notEmpty(port)) {
       if (TS.notEmpty(extPort)) {
         any eps = extPort.split(",");
         for (String ep in eps) {
          if (ep != port) {
            if (TS.notEmpty(newPorts)) {
              newPorts += ",";
            }
            newPorts += ep;
          }
         }       
       }
       extraPortMap.delete(port);
       extraPorts = newPorts;
       servicesConf.delete(port);
       log.log("deleted");
      }
    }
    
    getServices() Map {
      Map services = Map.new();
      //intPort->{extPort, name, intUrl, extUrl}
      for (any kv in servicesConf) {
        String intPort = kv.key;
        Map conf = kv.value;
        Map service = Map.new();
        services.put(intPort, service);
        service.put("intPort", extraPortMap.get(intPort));
        service.put("name", conf.get("name"));
        service.put("urlPat", conf.get("urlPat"));
        service.put("iport", conf.get("iport"));
        String intUrl = conf.get("urlPat").copy();
        log.log("intUrl " + intUrl);
        if (TS.notEmpty(intUrl) && TS.notEmpty(internalAddress)) {
          intUrl = intUrl.swap("$ip$", internalAddress);
          intUrl = intUrl.swap("$port$", intPort);
          intUrl = intUrl.swap("$type$", "Internal");
          service.put("intLink", intUrl + " - use on device's network.")
        }
        String extUrl = conf.get("urlPat").copy();
        if (TS.notEmpty(extUrl) && TS.notEmpty(externalAddress)) {
          if (TS.notEmpty(extNameBase)) {
            extUrl = extUrl.swap("$ip$", extNameBase);
          } else {
            extUrl = extUrl.swap("$ip$", externalAddress);
          }
          extUrl = extUrl.swap("$port$", service.get("intPort"));
          extUrl = extUrl.swap("$type$", "External");
          service.put("extLink", extUrl + " - use outside device's network.");
        }
        String hstUrl = conf.get("urlPat").copy();
        if (TS.notEmpty(hstUrl) && TS.notEmpty(hostedAddress)) {
          hstUrl = hstUrl.swap("$ip$", hostedAddress);
          hstUrl = hstUrl.swap("$port$", service.get("intPort"));
          hstUrl = hstUrl.swap("$type$", "Hosted");
          service.put("hstLink", hstUrl + " - use wherever there's internet.");
        }
        String konnUrl = conf.get("urlPat").copy();
        if (TS.notEmpty(konnUrl) && TS.notEmpty(konnAddress)) {
          konnUrl = konnUrl.swap("$ip$", konnAddress);
          konnUrl = konnUrl.swap("$port$", service.get("intPort"));
          konnUrl = konnUrl.swap("$type$ ", "");
          if (TS.notEmpty(konniAddress)) {
            service.put("konnLink", konnUrl + " - use outside device's network.");
          } else {
            service.put("konnLink", konnUrl + " - use on internet.");
          }
        }
        String konniUrl = conf.get("urlPat").copy();
        if (TS.notEmpty(konniUrl) && TS.notEmpty(konniAddress) && TS.notEmpty(service.get("iport"))) {
          konniUrl = konniUrl.swap("$ip$", konniAddress);
          konniUrl = konniUrl.swap("$port$", service.get("iport"));
          konniUrl = konniUrl.swap("$type$ ", "");
          service.put("konniLink", konniUrl + " - use on device's network.");
        }
      }
      return(services);
    }
    
}

use class IU:IUPlugin(App:AjaxPlugin) {

  restartRequest(Map arg, request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        log.log("Restarting as requested, will have exit code 3 by login " + request.context.get("account").user);
        restart();
     }
     return(null);
   }
   
   restart() {
     log.log("doing restart/exit");
     System:Process.exit(3);
   }
   
   fielder() {
    fields {
      any app;
    }
   
   }
   
   prepCamReverseProxy() {
     String ecpr = "webApp.Cam.";
     String icpr = "webApp.Cam.int.";
     String ecp = app.configManager.get("webApp.Cam.web.port");
     String icp = app.configManager.get("webApp.Cam.int.web.port");
     String acp = app.configManager.get("webApp.Cam.app.port");
     prepReverseProxy(acp, ecp, ecpr, "cert.pem");
     prepReverseProxy(acp, icp, icpr, "certi.pem");
   }
   
   prepDomoReverseProxy() {
     String ecpr = "webApp.Domo.";
     String icpr = "webApp.Domo.int.";
     String ecp = app.configManager.get("webApp.Domo.web.port");
     String icp = app.configManager.get("webApp.Domo.int.web.port");
     String acp = "10010";
     prepReverseProxy(acp, ecp, ecpr, "cert.pem");
     prepReverseProxy(acp, icp, icpr, "certi.pem");
   }
   
   prepNxcReverseProxy() {
     String ecpr = "webApp.Nxc.";
     String icpr = "webApp.Nxc.int.";
     String ecp = app.configManager.get("webApp.Nxc.web.port");
     String icp = app.configManager.get("webApp.Nxc.int.web.port");
     String acp = "80";
     prepReverseProxy(acp, ecp, ecpr, "cert.pem");
     prepReverseProxy(acp, icp, icpr, "certi.pem");
   }
   
   prepReverseProxy() {
      app.appSsl = false;
      app.webProto = "https";
      
      app.appBindAddress = "127.0.0.1";
      
      String ap = app.appPort;
      String wp = app.webPort;
      
      Int portI;
      
      if (wp == ap) { //need to differ for proxy
        portI = System:Random.getIntMax(30000);
        portI += 3000;
        wp = portI.toString();
        app.webPort = wp;
      }
      
      prepReverseProxy(ap, wp, app.configPrefix, "cert.pem");
      //app.configPrefix + "int." + "web.port";
      String icp = app.configPrefix + "int.";
      String portikey = icp + "web.port";
      String wporti = app.configManager.get(portikey);
      if (TS.isEmpty(wporti)) {
        portI = System:Random.getIntMax(30000);
        portI += 3000;
        wporti = portI.toString();
        app.configManager.put(portikey, wporti);
      }
      
      prepReverseProxy(ap, wporti, icp, "certi.pem");
      
    }
    
    prepReverseProxy(String ap, String wp, String appPref, String certname) {
      
      Path adp = app.paths.dataPath.addStep(appPref + "haproxy");
      if (adp.file.exists!) {
        adp.file.makeDirs();
      }
      
      Path apa = app.paths.appPath;
      Path hpt = apa.copy().addStep("haproxy.cfg");
      String hpts = hpt.file.reader.open().readStringClose();
      hpts = hpts.swap("WPORT", wp);
      hpts = hpts.swap("APORT", ap);
      hpts = hpts.swap("CERTNAME", certname);
      
      Path hpc = adp.copy().addStep("haproxy.cfg");
      if (hpc.file.exists) { hpc.file.delete(); }
      hpc.file.writer.open().writeStringClose(hpts);
      
      String hcmd = "App/KBridge/starthap.sh " + adp.toString() + " " + certname;
      log.log("starting proxy " + hcmd);
      System:Command.new(hcmd).run();
      
    }

}
