// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use IO:File:Path;
use IO:File;
use System:Random;
local use IU:WebConnect;

class IU:WebConnect {

  new() self {
    fields {
      Int lvl;
      IO:Log log;
      
      String gateway;
      String internalAddress;
      String externalAddress;
      String internalPort = "";
      String externalPort = "";
      String protocol = "https://";
      String internalBase;
      String externalBase;
      String path = "";
      String internalUrl;
      String externalUrl;
      String internalLink;
      String externalLink;
      String certificatePrint = "";
      String internalMacAddress;
      String extraPorts;
      Map extraPortMap = Map.new();
      
      String deviceId;
      String deviceName;
      
    }
    log = IO:Log.new();
    lvl = log.level;
  }
  
  toMap() Map {
    Map res = Maps.fieldsIntoMap(self, Map.new());
    res.delete("log");
    res.delete("lvl");
    return(res);
  }
  
  fromMap(Map fr) this {
    Maps.mapIntoFields(fr, self);
  }
  
  getAPort() String {
    Int externalPorti = System:Random.getInt(Int.new(), 6000);
    externalPorti += 3000;
    return(externalPorti.toString());
  }

  update() self {
    Upnp upnp = Upnp.new();
    upnp.log = log;
    upnp.lvl = lvl;
    upnp.netGw = upnp.gatewayAddress;
    gateway = upnp.netGw;
    internalAddress = upnp.internalIP;
    Net:Interface ni = Net:Interface.new();
    internalMacAddress = ni.interfaceForNetwork(upnp.netGw).macAddress;
    
    if (TS.isEmpty(externalPort)) {
      externalPort = getAPort();
    }
    
    try {
        String ea = upnp.externalIP;
        if (TS.notEmpty(ea)) {
          externalAddress = ea;
        }
      } catch (any e) {
        //don't change external ip when upnp fails
        log.log(lvl, "Upnp externalAddress failed");
        if (def(e)) { log.log(lvl, e.toString()); }
      }
    
      if (TS.notEmpty(internalPort)) {
        String intPort = ":" + internalPort;
      } else {
        intPort = "";
      }
      if (TS.notEmpty(externalPort)) {
        String extPort = ":" + externalPort;
      } else {
        extPort = "";
      }
      internalBase = protocol + internalAddress + intPort + "/";
      externalBase = protocol + externalAddress + extPort + "/";
      internalUrl = internalBase + path;
      externalUrl = externalBase + path;
      
      internalLink = "<a href=\"" + internalUrl + "\">Internal Link - use on same network as the device is on.</a>";
      externalLink = "<a href=\"" + externalUrl + "\">External Link - use from the internet, outside the network the device is on.</a>";
      
  }
  
  forwardPorts() {
      if (TS.notEmpty(externalAddress)) {
        log.log(lvl, "Forwarding");
        Int fwdSecs = 7200;//fwd upnp for how long
        Upnp upnp = Upnp.new();
        upnp.log = log;
        upnp.lvl = lvl;
        upnp.netGw = upnp.gatewayAddress;
        upnp.forwardPort(fwdSecs, Int.new(externalPort), Int.new(internalPort));
        if (TS.notEmpty(extraPorts)) {
          for (String ep in extraPorts.split(",")) {
            String currPortS = extraPortMap.get(ep);
            if (TS.isEmpty(currPortS)) {
              currPortS = getAPort();
              extraPortMap.put(ep, currPortS);
            }
            log.log(lvl, "Forwarding extraport external " + currPortS + " to " + ep);
            upnp.forwardPort(fwdSecs, Int.new(currPortS), Int.new(ep));
          }
        }
      }
    }
    
}

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
    
    interfaceForNetwork(String netip) Interface {
      Int maxSoFar = 0;
      String bestMatch;
      Interface bestMatchI;
      for (Interface i in self.localInterfaces) {
        String iip = i.address;
        if (TS.notEmpty(iip)) {
          String cp = TS.commonPrefix(iip, netip);
          if (def(cp)) {
            Int cps = cp.size;
            if (cps > maxSoFar) {
              maxSoFar = cps;
              bestMatch = iip;
              bestMatchI = i;
            }
          }
        }
      }
      return(bestMatchI);
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
      internalIP = ni.interfaceForNetwork(netGw).address;
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
