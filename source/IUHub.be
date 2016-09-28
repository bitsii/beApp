// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use IO:File:Path;
use IO:File;
use System:Random;
use UI:WebBrowser as WeBr;
use Test:Assertions as Assert;
use Db:Relational:Database as DbDb;
use Db:Relational:Statement as DbSt;
use System:Thread:Lock;
use System:Thread:ContainerLocker as CLocker;
use System:Command as Com;
use Time:Sleep;

use App:Alert;

use App:AuthenticatedLocalApp;
use App:AuthenticatedWebApp;
use App:AuthenticatedApp as AuthedApp;
use Text:String;

emit(jv) {
"""
//import java.io.*;
import java.net.*;
"""
}
use class Net:Interface {
 
 new(String _description, String _macAddress, String _name, 
     String _status, 
     String _address) self {
   fields {
     String description = _description;
     String macAddress = _macAddress;
     String name = _name;
     String status = _status;
     String address = _address;
   }
 }
 
 toString() String {
   String res = String.new();
   if (def(description)) {
     res += " description: " += description;
   }
   if (def(macAddress)) {
     res += " macAddress: " += macAddress;
   }
   if (def(name)) {
     res += " name: " += name;
   }
   if (def(status)) {
     res += " status: " += status;
   }
   if (def(address)) {
     res += " address: " += address;
   }
   return(res);
 }
 
 localInterfacesGet() List {
   List res;
   ifEmit(cs) {
     res = localInterfacesGetCs();
   }
   ifEmit(jv) {
     res = localInterfacesGetJv();
   }
   return(res);
 }
 
 localInterfacesGetJv() List {
   
    List interfaces = List.new();
    
    String description;
    String macAddress;
    String name;
    String status;
    String address;
    
     emit(jv) {
  """
  for(NetworkInterface ifc : java.util.Collections.list(NetworkInterface.getNetworkInterfaces())) {
    String status;
    if (ifc.isUp()) {
      status = "Up";
    } else {
      status = "Down";
    }
    String description = ifc.getDisplayName();
    String name = ifc.getName();
    byte[] hwad = ifc.getHardwareAddress();
    String macAddress = null;
    if (hwad != null) {
      StringBuilder sb = new StringBuilder();
      for (int i = 0; i < hwad.length; i++) {
        sb.append(String.format("%02X%s", hwad[i], ""));		
      }
      macAddress = sb.toString();
    }
    for(InetAddress addr : java.util.Collections.list(ifc.getInetAddresses())) {
      int count = 0;
      String address = addr.getHostAddress();
      if (address != null) {
        for (int i = 0;i < address.length();i++) {
          if (address.charAt(i) == '.') {
            count++;
          }
        }
        if (count != 3) {
          continue;
        }
         bevl_address = new $class/Text:String$(address);
      } else {
        continue;
      }
      if (description != null) {
         bevl_description = new $class/Text:String$(description);
      } else {
        bevl_description = null;
      }
      if (name != null) {
         bevl_name = new $class/Text:String$(name);
      } else {
        bevl_name = null;
      }
      if (macAddress != null) {
         bevl_macAddress = new $class/Text:String$(macAddress);
      } else {
        bevl_macAddress = null;
      }
      bevl_status = new $class/Text:String$(status);
      """
      }
      ifEmit(jv) {
        interfaces +=  Interface.new(description, macAddress,
          name, status, address);
      }
      emit(jv) {
      """
    }
  }
  """
  }    
      return(interfaces);
    }
 
 localInterfacesGetCs() List {
   
    List interfaces = List.new();
    
    String description;
    String macAddress;
    String name;
    String status;
    String address;
    emit(cs) {
        """            
        NetworkInterface[] adapters  = NetworkInterface.GetAllNetworkInterfaces();
        for (NetworkInterface adapter in adapters)
        {
            string description = adapter.Description;
            string macAddress = adapter.GetPhysicalAddress().ToString();
            string name = adapter.Name;
            string status = adapter.OperationalStatus.ToString();
            IPInterfaceProperties adapterProperties = adapter.GetIPProperties();
            
            UnicastIPAddressInformationCollection unicastIps = adapterProperties.UnicastAddresses;
            
            /*GatewayIPAddressInformationCollection addresses = adapterProperties.GatewayAddresses;
            string gatewayAddress = null;
            if (addresses.Count >0)
            {
                for (GatewayIPAddressInformation gaddress in addresses)
                {
                  if (gaddress.Address.AddressFamily.ToString().Equals("InterNetwork")) {
                    gatewayAddress = gaddress.Address.ToString();
                  }
                    
                }
            }*/
            string address = null;
            for(UnicastIPAddressInformation unicastIp in unicastIps)
            {
              if (unicastIp.Address.AddressFamily.ToString().Equals("InterNetwork")) {
                    address = unicastIp.Address.ToString();
                    if (description != null) {
                      bevl_description = new $class/Text:String$(description);
                    } else {
                      bevl_description = null;
                    }
                    if (macAddress != null) {
                      bevl_macAddress = new $class/Text:String$(macAddress);
                    } else {
                      bevl_macAddress = null;
                    }
                    if (name != null) {
                      bevl_name = new $class/Text:String$(name);
                    } else {
                      bevl_name = null;
                    }
                    if (status != null) {
                      bevl_status = new $class/Text:String$(status);
                    } else {
                      bevl_status = null;
                    }
                    if (address != null) {
                      bevl_address = new $class/Text:String$(address);
                    } else {
                      bevl_address = null;
                    }
                    """
                    }
                    ifEmit(cs) {
                      interfaces +=  Interface.new(description, macAddress,
                        name, status, address);
                    }
                    emit(cs) {
                    """
              }
            }
        }
        """
        }
        return(interfaces);
    }
    
    score(Interface i) Int {
      Int s = 0;
      if (def(i.status) && i.status == "Up") {
       s++=;
      }
      if (def(i.address)) {
       s++=;
       if (i.address != "127.0.0.1") {
         s++=;
       }
      }
      if (def(i.macAddress)) {
        s++=;
      }
      return(s);
    }
    
    upInterfacesGet() List {
      List ups = List.new();
      for (Interface i in self.localInterfaces) {
        if (TS.notEmpty(i.status) && i.status == "Up" && TS.notEmpty(i.address)) {
          ups += i;
        }
      }
      return(ups);
    }
    
    interfaceForNetwork(String netip) String {
      Int maxSoFar = 0;
      String bestMatch;
      for (Interface i in self.localInterfaces) {
        String iip = i.address;
        if (TS.notEmpty(iip)) {
          String cp = TS.commonPrefix(iip, netip);
          if (def(cp)) {
            Int cps = cp.size;
            if (cps > maxSoFar) {
              maxSoFar = cps;
              bestMatch = iip;
            }
          }
        }
      }
      return(bestMatch);
    }
    
    sortedUpInterfacesGet() List {
      List ups = self.upInterfaces;
      List sups = List.new();
      Map adif = Map.new();
      List ads = List.new();
      for (Interface i in ups) {
        adif.put(i.address, i);
        ads += i.address;
      }
      ads.sort();
      for (String ad in ads) {
        sups += adif.get(ad);
      }
      return(sups);
    }
    
    preferredInterfaceGet() Interface {
      Interface res;
      Int resScore = -1;
      for (Interface i in self.localInterfaces) {
        Int score = score(i);
        if (score > resScore) {
          res = i;
          resScore = score;
        }
      }
      return(res);
    }
 
}

use Net:UPnP as Upnp;

class Upnp {

  new() self {
    fields {
      String netGw;
      IO:Log log = IO:Log.new();
      Int lvl = log.debug;
    }
  }
  
  new(String _netGw) self {
    new();
    netGw = _netGw;
  }
  
  gatewayAddressGet() String {
    
    System:Command sc = System:Command.new("netstat -rn").open();
    String res = sc.output.readString();
    sc.close();
    
    //log.log(lvl, "netstat output " + res);
    
    if (System:CurrentPlatform.name == "mswin") {
      Int fz = res.find("0.0.0.0"); //win
    } else {
      fz = 0;
    }
    if (def(fz)) {
      Int fz2 = res.find("0.0.0.0", fz + 1);
      if (def(fz2)) {
        fz = fz2;
      }
      fz += 7;
      res = res.substring(fz);
      Bool started = false;
      String accum = String.new();
      for (String s in res.biter) {
        if (s == " ") {
          if (started) {
            break;
          }
        } else {
          started = true;
          accum += s;
        }
      }
    }
    return(accum);
  }
  
  deviceURLGet() String {
    fields {
      String deviceURL;
    }
    if (def(deviceURL)) {
      return(deviceURL);
    }
    any e;
    String discover = "M-SEARCH * HTTP/1.1\r\n" +
            "HOST: 239.255.255.250:1900\r\n" +
            "ST:upnp:rootdevice\r\n" +
            "MAN:\"ssdp:discover\"\r\n" +
            "MX:3\r\n\r\n";
            
    emit(cs) {
    """
    Socket s = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
    s.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.Broadcast, 1);
    byte[] data = Encoding.ASCII.GetBytes(bevl_discover.bems_toCsString());
    IPEndPoint ipe = new IPEndPoint(IPAddress.Broadcast, 1900);
    byte[] buffer = new byte[0x1000];
    int length;
    s.SendTimeout = 500;
    s.ReceiveTimeout = 500;
    """
    }
    String intip = self.internalIP;
    emit(jv) {
    """
    //DatagramSocket s = new DatagramSocket();
    DatagramSocket s = new DatagramSocket(0, InetAddress.getByName(bevl_intip.bems_toJvString()));
    s.setBroadcast(true);
    s.setSoTimeout(500);
    byte[] data = bevl_discover.bems_toJvString().getBytes("UTF-8");
    DatagramPacket spacket = new DatagramPacket(data, data.length, InetAddress.getByName("255.255.255.255"), 1900);
    byte[] buffer = new byte[0x1000];
    """
    }
    
    String received;
    Int endSec = Time:Interval.now().seconds + 5;
    Int nowSec = Time:Interval.now().seconds;
    Int count = 0;
    while (nowSec < endSec) {
      received = null;
      if (count % 7 == 0) {
        any bcast = true;
      } else {
        bcast = null;
      }
      count++=;
      try {
      emit(cs) {
      """
      if (bevl_bcast != null) {
        s.SendTo(data, ipe);
      }
      length = s.Receive(buffer);
      string got = Encoding.ASCII.GetString(buffer, 0, length);
      bevl_received = new $class/Text:String$(got);
      """
      }
      emit(jv) {
      """
      if (bevl_bcast != null) {
        s.send(spacket);
      }
      DatagramPacket rpacket = new DatagramPacket(buffer, buffer.length);
      s.receive(rpacket);
      String got = new String(rpacket.getData(), 0, rpacket.getLength(), "UTF-8");
      bevl_received = new $class/Text:String$(got);
      """
      }
      } catch (e) {
        log.log(lvl, "got except during upnp bcast et all " + e);
      }
      if (def(received)) {
        received.lowerValue();
        log.log(lvl, "deviceURLGet Received " + received);
        if (received.has("upnp:rootdevice")) {
          Int loc = received.find("location:");
          if (def(loc)) {
            loc += 10;
            received = received.substring(loc);
            loc = received.find("\r");
            if (def(loc)) {
              received = received.substring(0, loc);
              if (received.has(netGw)) {
                deviceURL = received;
                return(received);
              }
            }
          }
        }
      }
      nowSec = Time:Interval.now().seconds;
    }
    
    return(null);
    }
    
    dropTrailingPath(String received) String {
      //drop trailing path
      Int mk = received.find("/");
      mk = received.find("/", mk + 1);
      mk = received.find("/", mk + 1);
      if (def(mk)) {
        received = received.substring(0, mk);
      }
      return(received);
    }
    
    controlURLGet() String {
      any e;
      fields {
        String controlURL;
      }
      if (def(controlURL)) {
        return(controlURL);
      }
      String deviceURL = self.deviceURL;
      //("deviceUrl " + deviceURL).print();
      Web:Client client = Web:Client.new();
      client.url = deviceURL;
      try {
        String received = client.openInput().readString();
      } catch (e) {
        cu = dropTrailingPath(deviceURL);
        controlURL = cu;
        return(cu);
      }
      Int mk = received.find("InternetGatewayDevice");
      if (def(mk)) {
        mk = received.find("WANIPConnection", mk + 1);
        if (def(mk)) {
          mk = received.find("controlURL", mk + 1);
        }
        if (def(mk)) {
          received = received.substring(mk + 11);
          mk = received.find("</controlURL>");
          if (def(mk)) {
            received = received.substring(0, mk);
            String cu = dropTrailingPath(deviceURL);
            cu = cu + received;
            controlURL = cu;
          }
        }
      }
      return(controlURL);
    }
    
    externalIPGet() String {
      String cmd = "upnpc -s";
      String res = System:Command.new(cmd).open().output.readStringClose();
      //log.log(lvl, "res1 " + res);
      if (TS.notEmpty(res)) {
        Int rf = res.find("ExternalIPAddress = ");
        if (def(rf)) {
          rf += 20;
          res = res.substring(rf, res.size);
          //log.log(lvl, "res2 " + res);
          rf = res.find("\n");
          Int rf2 = res.find("\r");
          if (def(rf2) && rf2 < rf) {
            rf = rf2;
          }
          res = res.substring(0, rf);
          log.log(lvl, "res3 extipis " + res);
          return(res);
        }
      }
      return(null);
    }

    externalIPGetOld() String {
      String cu = self.controlURL;
      Web:Client client = Web:Client.new();
      client.url = cu;
      client.outputContentType = "text/xml";
      
      client.outputHeaders.put("SoapAction", "urn:schemas-upnp-org:service:WANIPConnection:1#GetExternalIPAddress");
      
      client.verb = "POST";
      String payload = "<?xml version='1.0' encoding='utf-8'?> <s:Envelope s:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/' xmlns:s='http://schemas.xmlsoap.org/soap/envelope/'> <s:Body> <u:GetExternalIPAddress xmlns:u=\"urn:schemas-upnp-org:service:WANIPConnection:1\" /> </s:Body> </s:Envelope>";
      client.openOutput().write(payload);
      String res = client.openInput().readString();
      if (def(res)) {
        Int start = res.find("<NewExternalIPAddress>");
        Int end = res.find("</NewExternalIPAddress>");
        if (def(start) && def("end")) {
          String ip = res.substring(start + 22, end);
          return(ip);
        }
      }
      
      return(null);
    }
    
    internalIPGet() {
      fields {
        String internalIP;
      }
      if (def(internalIP)) {
        return(internalIP);
      }
      Net:Interface ni = Net:Interface.new();
      log.log(lvl, "getgw " + netGw);
      internalIP = ni.interfaceForNetwork(netGw);
      log.log(lvl, "Got internal ip " + internalIP);
      return(internalIP);
    }
    
    forwardPort(Int duration, Int external, Int internal) Bool {
      return(forwardPort(duration, external, internal, self.internalIP));
    }
    
    forwardPort(Int duration, Int external, Int internal, String internalIP) Bool {
      //upnpc -a 192.168.99.100 5555 9999 TCP
      String cmd = "upnpc -a " + internalIP + " " + internal + " " + external + " TCP";
      String res = System:Command.new(cmd).open().output.readStringClose();
      log.log(lvl, "forwardPort result " + res);
      return(true);
    }
      
    forwardPortOld(Int duration, Int external, Int internal, String internalIP) Bool {
      if (true) { return(true); }
      any e;
      String cu = self.controlURL;
      Web:Client client = Web:Client.new();
      client.url = cu;
      client.outputContentType = "text/xml";
      
      client.outputHeaders.put("SoapAction", "urn:schemas-upnp-org:service:WANIPConnection:1#AddPortMapping");
      
      client.verb = "POST";
      //String payload = "<?xml version='1.0' encoding='utf-8'?> <s:Envelope s:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/' xmlns:s='http://schemas.xmlsoap.org/soap/envelope/'> <s:Body> <u:GetExternalIPAddress xmlns:u=\"urn:schemas-upnp-org:service:WANIPConnection:1\" /> </s:Body> </s:Envelope>";
      
      String payload = "<?xml version='1.0' encoding='utf-8'?> <s:Envelope xmlns:s='http://schemas.xmlsoap.org/soap/envelope/' s:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/'><s:Body><u:AddPortMapping xmlns:u=\"urn:schemas-upnp-org:service:WANIPConnection:1\"><NewRemoteHost></NewRemoteHost> <NewExternalPort>" + external.toString() + "</NewExternalPort><NewProtocol>TCP</NewProtocol> <NewInternalPort>" + internal.toString() + "</NewInternalPort> <NewInternalClient>" + internalIP + "</NewInternalClient> <NewEnabled>1</NewEnabled> <NewPortMappingDescription>node:nat:upnp</NewPortMappingDescription> <NewLeaseDuration>" + duration.toString() + "</NewLeaseDuration> </u:AddPortMapping> </s:Body> </s:Envelope>";
      
      try {
        client.openOutput().write(payload);
        String res = client.openInput().readString();
      } catch (e) {
        return(false);
      }
      if (def(res)) {
        if (res.has("Fault") || res.has("UPnPError")) {
          return(false);
        }
        return(true);
      }
      
      return(false);
    }
            
    

}

use class IUHub:DnsUpdate {

  new() self {
  
    fields {
      String duckDomain;
      String duckToken;
      any app;
      Int lvl;
      IO:Log log;
      Int lastSec = 0;
      Int pollSecs = 3600;
    }
  
  }
  
  updateOnInterval() {
    Int currSec = Time:Interval.now().seconds;
    if (currSec - lastSec > pollSecs) {
      lastSec = currSec;
      doUpdate();
    }
  }
  
  doUpdate() {
    //log.log(lvl, "In doUpdate");
    if (TS.notEmpty(duckDomain) && TS.notEmpty(duckToken)) {
      log.log(lvl, "Hitting Duck");
      String url =  "https://duckdns.org/update/" + duckDomain + "/" + duckToken;
      Web:Client client = Web:Client.new();
      Web:Client:CertificateManager.validateCertificates = false;
      client.verb = "GET";
      client.url = url;
      String res = client.openInput().readString();
      client.close();
      Web:Client:CertificateManager.validateCertificates = true;
      client = null;
    }
  }
  
  init() {
    duckDomain = app.configManager.get("dns.duckDomain");
    duckToken = app.configManager.get("dns.duckToken");
    String pollSecsS = app.configManager.get("dns.pollSecs");
    if (TS.notEmpty(pollSecsS)) {
      pollSecs = Int.new(pollSecsS);
    } else {
      app.configManager.put("dns.pollSecs", pollSecs.toString());
    }
  }

}

use class IUHub:UpnpUpdate {

  new() self {
  
    fields {
      any app;
      Int lvl;
      IO:Log log;
      Int lastPoll = 0;
      Int lastUpdate = 0;
      Int lastFwd = 0;
      Int pollSecs = 1200;//how often to check for ip changes
      Int uupdateSecs = 600;//how often to update upnp fwd
      Int fwdSecs = 7200;//fwd upnp for how long
      Int forceUpdate = 3600;//imap force update
      Bool disable = false;
    }
  
  }
  
  updateOnInterval() {
    Int currSec = Time:Interval.now().seconds;
    if (currSec - lastPoll > pollSecs) {
      lastPoll = currSec;
      doUpdate();
    }
  }
  
  doUpdate() {
    any e;
    log.log(lvl, "In upnp doUpdate");
    unless (disable) {
      log.log(lvl, "upnp doing");
      
      Bool update = false;
      Bool fwd = false;
      
      Int currSec = Time:Interval.now().seconds;
      if (currSec - lastUpdate > forceUpdate) {
        lastUpdate = currSec;
        update = true;
      }
      if (currSec - lastFwd > uupdateSecs) {
        lastFwd = currSec;
        fwd = true;
      }
    
      Bool upnpWorking = true;
      Upnp upnp = Upnp.new();
      upnp.log = log;
      upnp.lvl = lvl;
      upnp.netGw = upnp.gatewayAddress;
      String gwNow = upnp.netGw;
      String iaNow = upnp.internalIP;
      try {
        String eaNow = upnp.externalIP;
      } catch (e) {
        //don't change external ip when upnp fails
        log.log(lvl, "Upnp externalIp failed, will not update external or forward ");
        if (def(e)) { log.log(lvl, e.toString()); }
        upnpWorking = false;
        eaNow = extAddress;
      }
      
      if (TS.notEmpty(gwNow)) {
        if (TS.isEmpty(gw) || gwNow != gw) {
          gw = gwNow;
          app.configManager.put("upnp.gw", gw);
        }
      }
      
      if (TS.notEmpty(iaNow)) {
        if (TS.isEmpty(intAddress) || iaNow != intAddress) {
          intAddress = iaNow;
          app.configManager.put("upnp.intAddress", intAddress);
        }
      }
      
      if (TS.notEmpty(eaNow)) {
        if (TS.isEmpty(extAddress) || eaNow != extAddress) {
          extAddress = eaNow;
          app.configManager.put("upnp.extAddress", extAddress);
        }
      }
      
      if (TS.isEmpty(intPort) || intPort != appIntPort) {
        intPort = appIntPort;
        app.configManager.put("upnp.intPort", intPort);
      }
      
      if (TS.isEmpty(extPort) || extPort != appExtPort) {
        extPort = appExtPort;
        app.configManager.put("upnp.extPort", extPort);
      }
      
      if (fwd && upnpWorking) {
        log.log(lvl, "Forwarding");
        upnp.forwardPort(fwdSecs, Int.new(extPort), Int.new(intPort));
        String exPorts = app.configManager.get("upnp.extraPorts");
        if (TS.notEmpty(exPorts)) {
          for (String ep in exPorts.split(",")) {
            String currPortS = app.configManager.get("upnp.extraPort." + ep + ".externalPort");
            if (TS.isEmpty(currPortS)) {
              Int intPorti = System:Random.getInt(Int.new(), 6000);
              intPorti += 3000;
              currPortS = intPorti.toString();
              app.configManager.put("upnp.extraPort." + ep + ".externalPort", currPortS);
            }
            log.log(lvl, "Forwarding extraport external " + currPortS + " to " + ep);
            upnp.forwardPort(fwdSecs, Int.new(currPortS), Int.new(ep));
          }
        }
      }

      if (update) {
        log.log(lvl, "Updating imap");
        String deviceId = self.app.plugin.deviceId;
        String intUrl = "https://" += intAddress += ":" += intPort += "/App/IUHub/IUHub.html";
        String extUrl = "https://" += extAddress += ":" += extPort += "/App/IUHub/IUHub.html";
        String intLink = "<a href=\"" + intUrl + "\">" + deviceName + " " + deviceId + " internal Link, use on same network as the device is on.</a>";
        String extLink = "<a href=\"" + extUrl + "\">" + deviceName + " " + deviceId + " external Link, use from the internet or outside the network the device is on.</a>";
        Map jsl = Map.new();
        if (TS.notEmpty(exPorts)) {
          String extraPortsMsg = String.new();
          for (ep in exPorts.split(",")) {
            currPortS = app.configManager.get("upnp.extraPort." + ep + ".externalPort");
            String httpsPath = app.configManager.get("upnp.extraPort." + ep + ".httpsPath");
            String appName = app.configManager.get("upnp.extraPort." + ep + ".appName");
            if (TS.notEmpty(currPortS)) {
              if (TS.notEmpty(appName)) {
                extraPortsMsg += "Begin Application " += appName += ":";
                jsl.put("extraPortAppName:" + ep, appName);
              }
              extraPortsMsg += "<p>External ip " += extAddress += " port " += currPortS += " directed to internal ip " += intAddress += " port " += ep += "</p>";
              if (TS.notEmpty(httpsPath)) {
                extraPortsMsg += "<p>External url <a href=\"https://" += extAddress += ":" += currPortS += httpsPath += "\">https://" += extAddress += ":" += currPortS += httpsPath += "</a></p>";
                extraPortsMsg += "<p>Internal url <a href=\"https://" += intAddress += ":" += ep += httpsPath += "\">https://" += intAddress += ":" += ep += httpsPath += "</a></p>";
                jsl.put("extraPortHttpsPath:" + ep, httpsPath);
              }
              if (TS.notEmpty(appName)) {
                extraPortsMsg += "End Application " += appName;
              }
              jsl.put("extraPort:" + ep, currPortS);
            }
          }
          jsl.put("extraPortsMsg", extraPortsMsg);
          jsl.put("extraPorts", exPorts);
        }
        log.log(lvl, "intLink " + intLink);
        log.log(lvl, "extLink " + extLink);
        String ct = app.certificateThumbprint;
        if (TS.notEmpty(ct)) {
          jsl.put("certThumbprint", ct);
          jsl.put("certThumbprintMsg", "<p>Certificate Thumbprint: " + ct + "</p>");
        }
        jsl.put("intAddress", intAddress);
        jsl.put("intPort", intPort);
        jsl.put("extAddress", extAddress);
        jsl.put("extPort", extPort);
        jsl.put("gw", gw);
        jsl.put("deviceName", deviceName);
        jsl.put("deviceId", deviceId)
        jsl.put("intLink", intLink);
        jsl.put("extLink", extLink);
        jsl.put("intUrl", intUrl);
        jsl.put("extUrl", extUrl);
        app.plugin.links.o = jsl;
        app.plugin.updateNetAddresses();
      }
    }
  }
  
    externalPortGet() String {
      if (TS.isEmpty(extPort)) {
        extPort = app.configManager.get("wui.extPort");
        if (TS.isEmpty(extPort)) {
          Int extPorti = System:Random.getInt(Int.new(), 6000);
          extPorti += 3000;
          extPort = extPorti.toString();
          app.configManager.put("wui.extPort", extPort);
        }
      }
      return(extPort);
    }
  
  init() {
    fields {
      String gw;
      String intAddress;
      String extAddress;
      String intPort;
      String extPort;
      String appIntPort;
      String appExtPort;
      String deviceName;
    }
    
    gw = app.configManager.get("upnp.gw");
    intAddress = app.configManager.get("upnp.intAddress");
    extAddress = app.configManager.get("upnp.extAddress");
    intPort = app.configManager.get("upnp.intPort");
    extPort = app.configManager.get("upnp.extPort");
    
    appIntPort = app.webPort;
    appExtPort = self.externalPort;
    deviceName = app.plugin.deviceName;
    
    String disables = app.configManager.get("upnp.disable");
    if (TS.notEmpty(disables) && disables == "true") {
      disable = true;
    }
    
    String pollSecsS = app.configManager.get("upnp.pollSecs");
    if (TS.notEmpty(pollSecsS)) {
      pollSecs = Int.new(pollSecsS);
    } else {
      app.configManager.put("upnp.pollSecs", pollSecs.toString());
    }
    
    String forceUpdateS = app.configManager.get("imap.forceUpdateSecs");
    if (TS.notEmpty(forceUpdateS)) {
      forceUpdate = Int.new(forceUpdateS);
    } else {
      app.configManager.put("upnp.forceUpdateSecs", forceUpdate.toString());
    }
    
    String uupdateSecsS = app.configManager.get("upnp.updateSecs");
    if (TS.notEmpty(uupdateSecsS)) {
      uupdateSecs = Int.new(uupdateSecsS);
    } else {
      app.configManager.put("upnp.updateSecs", uupdateSecs.toString());
    }
    
    String fwdSecsS = app.configManager.get("upnp.fwdSecs");
    if (TS.notEmpty(fwdSecsS)) {
      fwdSecs = Int.new(fwdSecsS);
    } else {
      app.configManager.put("upnp.fwdSecs", fwdSecs.toString());
    }
  }

}

use class IUHub:Background {

  new() self {
    fields {
      any app;
      Int lvl;
      IO:Log log;
      DnsUpdate du = DnsUpdate.new();
      UpnpUpdate uu = UpnpUpdate.new();
    }
  }
  
  runMyTasks() {
    fields {
      Int lastTrackClear;
      Int clearSeconds =@ 7200;
    }
    if (def(lastTrackClear)) {
      Int ns = Time:Interval.now().seconds;
      if (ns - lastTrackClear > clearSeconds) {
        app.trackingManager.clear();
        lastTrackClear = ns;
      }
    } else {
      lastTrackClear = 0;
    }
  }
  
  runTasks() {
    //log.log(lvl, "Running tasks");
    runMyTasks();
    du.updateOnInterval();
    uu.updateOnInterval();
  }
  
  main() {
    any e;
    while (true) {
      try {
        runTasks();
      } catch (e) {
        log.log(lvl, "Caught exception running tasks " + e);
      }
      try {          
        Time:Sleep.sleepMilliseconds(sleepTime);
      } catch (e) {
        log.log(lvl, "Caught exception sleeping " + e);
      }
    }
  }
  
  init() self {
    fields {
      System:Thread myThread;
      Int sleepTime = 500;
    }
    String bkdis = app.configManager.get("bk.disable");
    if (TS.notEmpty(bkdis) && Bool.new(bkdis)) {
      return(self);
    }
    Int _sleepTime = app.configManager.get("bk.sleepTime");
    if (def(_sleepTime) && _sleepTime > 0) {
      sleepTime = _sleepTime;
    }
    du.app = app;
    du.lvl = lvl;
    du.log = log;
    du.init();
    uu.app = app;
    uu.lvl = lvl;
    uu.log = log;
    uu.init();
  }
  
  startBackground() self {
    init();
    myThread = System:Thread.new(self);
    myThread.start();
  }

}

use class IUHub:HubStart {

   new() self {
      fields {
          IO:Log log = IO:Log.new();
          log.level = log.info;
          Int lvl = log.level;
        }
    }

  main() {
      main(System:Process.new().args);
    }
    
    main(List args) {
      outerMain(System:Process.new().args);
      /*try {
        app.configManager.close();
      } catch (any e) {
        log.log(lvl, "Exception closing db in CmdUI, error is " + e);
      }*/
    }
    
    outerMain(List args) {
      try {
        innerMain(System:Process.new().args);
      } catch (any e) {
        log.log(lvl, "Exception in CmdUI, error is " + e);
      }
    }
    
    innerMain(List args) {

      Web:Client:CertificateManager.validateHosts = false;

      if (args.length > 0) {
        String mode = args[0]; //ui, svc, both, [absent]
        log.log(lvl, "mode " + mode);
      } else {
        log.log(lvl, "mode empty");
      }
      if (TS.isEmpty(mode)) {
        mode = "wui";
      }
      if (mode == "lui" || mode == "wui" || mode == "cmd") {
        log.log(lvl, "making hub");
        HubPlugin hub = HubPlugin.new();
        if (mode == "cmd") {
          hub.runBackground = false;
        }
        hub.log = log;
        hub.lvl = lvl;
        log.log(lvl, "adding plugins");
        List plugins = List.new();
        plugins += hub;
        plugins += App:AuthPlugin.new();
        plugins += App:ConfigPlugin.new();
        plugins += App:FileManagerPlugin.new();
        if (mode == "lui") {
          AuthenticatedLocalApp.new(plugins, log, lvl).main();
        }
        if (mode == "wui") {
          AuthenticatedWebApp.new(plugins, log, lvl).main();
        }        
        if (mode == "cmd") {
          cmdMain(args, plugins);
        }
      }
      if (mode == "test") {
        IUHub:Test.new().main();
      }
    }

    cmdMain(List args, plugins) {
      AuthedApp ui = AuthedApp.new(plugins, log, lvl);
      
      if (args.length > 1) {
        String mode = args[1]; //ui, svc, both, [absent]
        log.log(lvl, "cmd " + mode);
      } 
      if (TS.isEmpty(mode)) {
        log.log(lvl, "cmd empty");
      }
      if (mode == "help") {
        log.log(lvl, "Help");
        log.log(lvl, "listLogins, putAccount, getAccount, setPermsString, setPass, deleteAccount, updateConfig, showConfig, createConfig, deleteConfig");
      }
      if (TS.notEmpty(mode) && mode == "portForward") {
        Net:PortForward pf = Net:PortForward.new(args[2], Int.new(args[3]), args[4], Int.new(args[5]));
        pf.log = log;
        pf.lvl = lvl;
        pf.start();
      }
      if (TS.notEmpty(mode) && mode == "listLogins") {
        for (String login in ui.accountManager.getLogins()) {
          log.log(lvl, "Account login " + login);
        }
      }
      if (TS.notEmpty(mode) && (mode == "putAccount" || mode == "createAccount")) {
        String user = args[2];
        String pass = args[3];
        log.log(lvl, "Putting Account " + user);
        Account ac = Account.new();
        ac.user = user;
        ac.pass = pass;
        if (args.length > 4) {
          ac.permsString = args[4];
        }
        ui.accountManager.putAccount(ac);
      }
      if (TS.notEmpty(mode) && mode == "getAccount") {
        user = args[2];
        log.log(lvl, "Get Account " + user);
        ac = ui.accountManager.getAccount(user);
        log.log(lvl, "Account " + ac);
      }
      if (TS.notEmpty(mode) && mode == "setPermsString") {
        user = args[2];
        String ps = args[3];
        log.log(lvl, "Set Perms " + user);
        ac = ui.accountManager.getAccount(user);
        ac.permsString = ps;
        ui.accountManager.putAccount(ac);
        log.log(lvl, "Account " + ac);
      }
      if (TS.notEmpty(mode) && mode == "setPass") {
        user = args[2];
        pass = args[3];
        log.log(lvl, "Set Pass " + user);
        ac = ui.accountManager.getAccount(user);
        ac.pass = pass;
        ui.accountManager.putAccount(ac);
      }
      if (TS.notEmpty(mode) && mode == "deleteAccount") {
        user = args[2];
        log.log(lvl, "Deleting Account " + user);
        ac = ui.accountManager.getAccount(user);
        if (def(ac)) {
          ui.accountManager.deleteAccount(ac);
          log.log(lvl, "Deleted account " + user);
        } else {
          log.log(lvl, "No such account for deletion " + user);
        }
      }
      if (TS.notEmpty(mode) && mode == "updateConfig") {
        String key = args[2];
        String value = args[3];
        log.log(lvl, "Updating config " + key + " " + value);
        ui.configManager.put(key, value);
      }
      if (TS.notEmpty(mode) && mode == "showConfig") {
        for (any kv in ui.configManager.getMap()) {
          log.log(lvl, "Config name " + kv.key + " value " + kv.value);
        }
      }
      if (TS.notEmpty(mode) && mode == "createConfig") {
        key = args[2];
        value = args[3];
        log.log(lvl, "Creating config " + key + " " + value);
        ui.configManager.put(key, value);
      }
      if (TS.notEmpty(mode) && mode == "deleteConfig") {
        key = args[2];
        log.log(lvl, "Deleting config " + key);
        ui.configManager.delete(key);
      }
      if (TS.notEmpty(mode) && mode == "saveIntUrl") {
        log.log(lvl, "saveIntUrl");
        ui.plugin.bg.init().uu.doUpdate();
        log.log(lvl, "int url is " + ui.plugin.links.o.get("intUrl"));
        File.apNew(args[2]).writer.open().write(ui.plugin.links.o.get("intUrl")).close();
        File.apNew(args[3]).writer.open().write("#!/bin/bash\nx-www-browser " + ui.plugin.links.o.get("intUrl") + "\n").close();
      }
      ui.configManager.close();
    }

}


use System:Thread:ObjectLocker as OLocker;

use Crypto:Symmetric as Crypt;
emit(jv) {
"""
import java.util.Properties;
import javax.mail.Session;
import javax.mail.Store;
import javax.mail.Folder;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.InternetAddress;
import javax.mail.Transport;
import javax.mail.Message;
import javax.mail.Flags.Flag;
"""
}
use class IUHub:HubPlugin {

     new() self {
       fields {
          IO:Log log;
          Int lvl;
          any app;
          String name = "IUHub";
          String homePage = "/App/IUHub/IUHub.html";
          OLocker links = OLocker.new();
          Background bg = Background.new();
          Bool runBackground = true;
        }
     }
     
     start() {
      bg.log = log;
      bg.lvl = lvl;
      bg.app = app;
      if (runBackground) {
      bg.startBackground();
      }
    }
     
  deviceNameGet() String {
    fields {
      String deviceName;
    }
    if (TS.isEmpty(deviceName)) {
      deviceName = app.configManager.get("deviceName");
      if (TS.isEmpty(deviceName)) {
        deviceName = "Device-" + System:Random.getString(4);
        app.configManager.put("deviceName", deviceName);
      }
    }
    return(deviceName);
  }
  
  deviceIdGet() String {
    fields {
      String deviceId;
    }
    if (TS.isEmpty(deviceId)) {
      deviceId = app.configManager.get("deviceId");
      if (TS.isEmpty(deviceId)) {
        deviceId = System:Random.getString(16);
        app.configManager.put("deviceId", deviceId);
      }
    }
    return(deviceId);
  }
  
  loggedIn(Account a, Map res, Map arg, request) {
      res["action"] = "updateResponse";
      res["justLoggedIn"] = true;
      res["permsString"] = a.permsString;
      res["actionLinks"] = getActionLinks(a, arg, request);
      res["appVersion"] = self.version;
      res["deviceName"] = self.deviceName;
      return(res);
    }
    
    versionGet() String {
      fields {
        String version =@ "5.3.1";
      }
      return(version);
    }
    
  updateNetAddresses() {
    log.log(lvl, "In doimap");
    any e;
    try {
      Map jsl = links.o;
      if(def(jsl) && jsl.notEmpty) {
        String prot = app.configManager.get("imap.protocol");
        if (TS.isEmpty(prot)) {
          prot = "imaps";
        }
        String endpoint = app.configManager.get("imap.endpoint");
        String user = app.configManager.get("imap.user");
        String pass = app.configManager.get("imap.pass");
        String subf = app.configManager.get("imap.subFolder");
        if (undef(subf)) {
          subf = "IotUrls";
        } elseIf (TS.isEmpty(subf)) {
          subf = null;
        }
        if (TS.isEmpty(endpoint) || TS.isEmpty(user) || TS.isEmpty(pass)) {
          return(null);
        }
        Json:Marshaller mar = Json:Marshaller.new();
        String json = mar.marshall(jsl);
        log.log(lvl, "links json " + json);
        String msg = "<p>" + jsl.get("extLink") + "</p>\n<p>" + jsl.get("intLink") + "</p>\n";
        msg += "<p>External (Internet) address " += jsl.get("extAddress") += ", web user interface on external port " += jsl.get("extPort") += "</p>";
        msg += "<p>Internal address " += jsl.get("intAddress") += ", web user interface on internal port " += jsl.get("intPort") += "</p>";
        if (TS.notEmpty(jsl.get("extraPortsMsg"))) {
          msg += jsl.get("extraPortsMsg");
        }
        if (TS.notEmpty(jsl.get("certThumbprintMsg"))) {
          msg += jsl.get("certThumbprintMsg");
        }
        msg += "<p><input type=\"hidden\" value=\"" += Encode:Hex.encode(json) += "\"/></p>\n";
        String subjPref = "DeviceLinks " + jsl.get("deviceName") + " " + app.configManager.get("deviceId") + " ";
        String subj = subjPref + Time:Interval.now().seconds;
        emit(jv) {
        """
        Properties props = new Properties();
        props.setProperty("mail.store.protocol", bevl_prot.bems_toJvString());
          Session session = Session.getDefaultInstance(props, null);
          Store store = session.getStore(bevl_prot.bems_toJvString());
          if (!store.isConnected()) {
            store.connect(bevl_endpoint.bems_toJvString(), bevl_user.bems_toJvString(), bevl_pass.bems_toJvString());
          }
          Folder f = store.getFolder("Inbox");
          if (bevl_subf != null) {
            Folder f2 = f.getFolder(bevl_subf.bems_toJvString());
            if (!f2.exists()) {
              f2.create(Folder.HOLDS_MESSAGES);
            }
            f = f2;
          }
          f.open(Folder.READ_WRITE);
          
          MimeMessage m = new MimeMessage(session);
          //m.setFrom(new InternetAddress(from));
          //m.addRecipient(Message.RecipientType.TO, new InternetAddress(to));
       
          String cs = bevl_subj.bems_toJvString();
          
          m.setSubject(cs);
          //m.setText(bevl_msg.bems_toJvString());
          m.setText(bevl_msg.bems_toJvString(), "utf-8", "html");

          
          m.setFlag(Flag.DRAFT, true);
          Message ms[] = {m};
          f.appendMessages(ms);
          
          if (bevl_subjPref != null) {
          
            String ls = bevl_subjPref.bems_toJvString();
            
            Message[] messages = f.getMessages();
            if (messages != null) {
              for(int i = 0; i < messages.length; i++)
              {
                String subj = messages[i].getSubject();
                if (subj != null && subj.startsWith(ls) && !subj.equals(cs)) {
                  System.out.println("deleting message");
                  messages[i].setFlag(Flag.DELETED, true);
                }
              }
            }            
          }
          
          f.close(true);
          store.close();
        """
        }
        log.log(lvl, "Done with imap stuff");
      }
    } catch (e) {
      if(def(e)) {
        ("Exception during imap update " + e);
      }
    }
  }
  
  tryThingRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        updateNetAddresses();
     }
     return(null);
   }
   
   restartRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        log.log(lvl, "Restarting as requested, will have exit code 3 by login " + app.accountManager.getAccountForRequest(request).user);
        System:Process.exit(3);
     }
     return(null);
   }
   
   checkPublicReadPath(Path pa, request) Bool {
      String pas = pa.toString();
      Path adz = Path.apNew("App/" + self.name).file.absPath;
      if (pas.begins(adz.toString()) && (pas.ends(".html") || pas.ends(".js"))) {
        return(true);
      }
      return(false);
   }
   
   showImapRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      Map res = Map.new();
      res["action"] = "showImapResponse";
      String user = app.configManager.get("imap.user");
      if (TS.notEmpty(user)) {
        res["imapAccount"] = user;
      }
      String ep = app.configManager.get("imap.endpoint");
      if (TS.notEmpty(ep)) {
        res["imapEndpoint"] = ep;
      }
      return(res);
   }
   
   imapSettingsRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      app.configManager.put("imap.user", arg["imapAccount"]);
      app.configManager.put("imap.endpoint", arg["imapEndpoint"]);
      app.configManager.put("imap.pass", arg["imapPass"]);
      Map res = Map.new();
      res["action"] = "hideImapResponse";
      return(res);
   }
   
   runCommandRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
      String cmdKey = arg["cmdKey"];
      String user = cmdKey.substring(4, cmdKey.find("!"));
      log.log(lvl, "cmd user " + user + " acct user " + a.user);
      unless (user == a.user) {
        log.log(lvl, "Cmd not for user");
        return(null);
      }
      String cmd = app.configManager.get(cmdKey);
      if (TS.notEmpty(cmd)) {
        log.log(lvl, "running command " + cmd);
        System:Command.new(cmd).run();
      }
      return(null);
   }
   
   upgradeRequest(Map arg, request) Map {
     log.log(lvl, "upgrade request");
     String path = arg["path"];
     Account a = app.accountManager.getAccountForRequest(request);
     unless (app.requestFromAdmin(request)) {
      throw(Alert.new("must be admin"));
     }
     if (TS.notEmpty(path)) {
       Path dpath = Path.apNew("App/IUHub.zip");
       File dirFile = File.apNew(Encode:Hex.new().decode(path));
       any e;
       try {
       app.lock.lock();
       log.log(lvl, "copying " + dirFile.path + " to " + dpath);
       if (dpath.file.exists) { dpath.file.delete(); }
        IO:Writer outw = dpath.file.writer.open();
        IO:Reader inr = dirFile.reader.open();
        inr.copyData(outw);
        outw.close();
        inr.close();
        app.lock.unlock();
        } catch (e) {
          app.lock.unlock();
        }
        if (System:CurrentPlatform.name == "mswin") {
          String piccmd = "App\\IUHub\\upgrade.bat";
        } else {
          piccmd = "App/IUHub/upgrade.sh";
        }
        try {
        app.lock.lock();
        Time:Sleep.sleepSeconds(1);
        System:Command.new(piccmd).run();
        app.lock.unlock();
        } catch (e) {
			app.lock.unlock();
        }
        try {
        app.lock.lock();
        Time:Sleep.sleepSeconds(10);
        System:Process.exit(4);
        app.lock.unlock();
        } catch (e) {
			app.lock.unlock();
        }
     }
     return(null);
   }
   
  getActionLinks(Account a, Map arg, request) String {
     String actionLinks = String.new();
     Map ecm = app.configManager.getMap("CMD." + a.user + "!");
     for (any kv in ecm) {
      String key = kv.key;
      key = key.substring(key.find("!") + 1, key.size);
      actionLinks += "<p><a href=\"#\" onclick=\"app.bem_runCommand_1(new be_BEC_2_4_6_TextString().bems_new('" + kv.key + "'));return false;\">" + key + "</a></p>";
     }
     String showCam = app.configManager.get("PLUGIN.cam");
     if (TS.notEmpty(showCam) && showCam == "enabled") {
       actionLinks += "<p><a href=\"IUCam.html\">Go to IUCam</a></p>";
     }
     return(actionLinks);
   }
   
   showDevLinksRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
       //String devLinks = "<p><a href=\"#\" onclick=\"app.bem_offerDevLink_0();return false;\">Send Link Offer</a></p>";
       Map res = Map.new();
       res["action"] = "showDevLinksResponse";
       //res["devLinks"] = devLinks;
       return(res);
     }
     return(null);
   }
   
}

use Email:Imap;

class Imap {

  new() self {
  
  }

}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;

use class IUHub:ConfigTest(Assert) {
  
  testConfig() {
    AuthedApp ui = AuthedApp.new();
    KvDb cm = ui.configManager.container;
    cm.delete("test.blarg");
    assertNull(cm.get("test.blarg"));
    cm.insert("test.blarg", "test");
    assertEqual(cm.get("test.blarg"), "test");
    cm.update("test.blarg", "foo");
    assertEqual(cm.get("test.blarg"), "foo");
    assertFalse(cm.testAndPut("test.blarg", "test", "la"));
    assertNotEqual(cm.get("test.blarg"), "la");
    assertTrue(cm.testAndPut("test.blarg", "foo", "la"));
    assertEqual(cm.get("test.blarg"), "la");
  }
  
  main() {
    "Begin ConfigTest".print();
    testConfig();
    "End ConfigTest".print();
  }
  
}

use class IUHub:HubPluginTest(Assert) {
    
  main() {
    "Begin HubPluginTest".print();
    "End HubPluginTest".print();
  }
  
}


use class IUHub:AccountTest(Assert) {
  
  testAccounts() {
    AuthedApp ui = AuthedApp.new();
    Account atest = Account.new();
    atest.user = "test";
    atest.pass = "pass";
    AccountManager am = ui.accountManager;
    am.deleteAccount(atest);
    Account a = am.getAccount(atest.user);
    assertNull(a);
    am.putAccount(atest);
    a = am.getAccount(atest.user);
    assertNotNull(a);
    assertFalse(a.perms.has("admin"));
    assertTrue(a.checkPass("pass"));
    assertFalse(a.checkPass("notpass"));
    a.pass = "yo";
    assertTrue(a.checkPass("yo"));
    a.perms.put("admin");
    am.putAccount(a);
    a = am.getAccount(a.user);
    assertEqual(a.user, "test");
    assertTrue(a.checkPass("yo"));
    //assertTrue(a.perms.has("admin"));
    am.deleteAccount(atest);
  }
  
  main() {
    "Begin AccountTest".print();
    testAccounts();
    "End AccountTest".print();
  }
  
}

