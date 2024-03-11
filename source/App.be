/*
 * Copyright (c) 2015-2023, the Brace App Authors.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Licensed under the BSD 2-Clause License (the "License").
 * See the LICENSE file in the project root for more information.
 *
 */

use IO:File:Path;
use IO:File;
use System:Random;
use UI:WebBrowser as WeBr;
use Test:Assertions as Assert;
use Db:KeyValue as KvDb;
use Time:Interval;
use System:Parameters;
use Container:LinkedList;
use Container:LinkedList:Node;
use Db:KeyValueDbs as KvDbs;

use class App:Alert(Exception) { }

emit(jv) {
"""
//import java.io.*;
import java.net.*;
"""
}
emit(cs) {
"""
using System;
using System.Net;
using System.Net.Sockets;
using System.Net.NetworkInformation;
using System.Text;
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
        foreach (NetworkInterface adapter in adapters)
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
            foreach (UnicastIPAddressInformation unicastIp in unicastIps)
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

use Net:Wol;

class Wol {

  default() self {
    fields {
      IO:Log log = IO:Logs.get(self);
    }
  }

  emit(cs) {
"""
private static byte[] StringToByteArray(string hex)
{
  int NumberChars = hex.Length;
  byte[] bytes = new byte[NumberChars / 2];
  for (int i = 0; i < NumberChars; i += 2)
    bytes[i / 2] = Convert.ToByte(hex.Substring(i, 2), 16);
  return bytes;
}
private static void WakeOnLan(string hex)
{
    byte[] mac = StringToByteArray(hex);
    // WOL packet is sent over UDP 255.255.255.0:40000.
    UdpClient client = new UdpClient();
    client.Connect(IPAddress.Broadcast, 40000);

    // WOL packet contains a 6-bytes trailer and 16 times a 6-bytes sequence containing the MAC address.
    byte[] packet = new byte[17*6];

    // Trailer of 6 times 0xFF.
    for (int i = 0; i < 6; i++)
        packet[i] = 0xFF;

    // Body of magic packet contains 16 times the MAC address.
    for (int i = 1; i <= 16; i++)
        for (int j = 0; j < 6; j++)
            packet[i*6 + j] = mac[j];

    // Send WOL packet.
    client.Send(packet, packet.Length);
}
"""
}

emit(jv) {
"""
private static byte[] stringToByteArray(String hex)
{
  int numChars = hex.length();
  byte[] bytes = new byte[numChars / 2];
  for (int i = 0; i < numChars; i += 2)
    bytes[i / 2] = (byte) Integer.parseInt(hex.substring(i, i + 2), 16);
  return bytes;
}
private static void wakeOnLan(String hex) throws Exception
{
    byte[] mac = stringToByteArray(hex);

    // WOL packet contains a 6-bytes trailer and 16 times a 6-bytes sequence containing the MAC address.
    byte[] packet = new byte[17*6];

    // Trailer of 6 times 0xFF.
    for (int i = 0; i < 6; i++)
        packet[i] = (byte) 0xFF;

    // Body of magic packet contains 16 times the MAC address.
    for (int i = 1; i <= 16; i++)
        for (int j = 0; j < 6; j++)
            packet[i*6 + j] = mac[j];

    // Send WOL packet.
    // WOL packet is sent over UDP 255.255.255.0:40000.
    InetAddress address = InetAddress.getByName("255.255.255.255");
    DatagramPacket dpacket = new DatagramPacket(packet, packet.length, address, 40000);
    DatagramSocket socket = new DatagramSocket();
    socket.send(dpacket);
    socket.close();
}
"""
}

  wakeMacAddr(String addr) {
    addr = addr.swap(":", "");
    addr = addr.swap("-", "");
    addr = addr.strip();
    log.log("Waking " + addr);
    emit(cs) {
    """
    WakeOnLan(beva_addr.bems_toCsString());
    """
    }
    emit(jv) {
    """
    wakeOnLan(beva_addr.bems_toJvString());
    """
    }
    return(null);
  }

}

use Net:UPnP as Upnp;

class Upnp {

  new() self {
    fields {
      String netGw;
      IO:Log log = IO:Logs.get(self);
    }
  }
  
  new(String _netGw) self {
    new();
    netGw = _netGw;
  }
  
  deviceURLGet() String {
    fields {
      String deviceURL;
    }
    if (def(deviceURL)) {
      return(deviceURL);
    }
    dyn e;
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
        dyn bcast = true;
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
        log.error("got except during upnp bcast et all " + e);
      }
      if (def(received)) {
        received.lowerValue();
        log.log("deviceURLGet Received " + received);
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
      dyn e;
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
      //log.log("res1 " + res);
      if (TS.notEmpty(res)) {
        Int rf = res.find("ExternalIPAddress = ");
        if (def(rf)) {
          rf += 20;
          res = res.substring(rf, res.size);
          //log.log("res2 " + res);
          rf = res.find("\n");
          Int rf2 = res.find("\r");
          if (def(rf2) && rf2 < rf) {
            rf = rf2;
          }
          res = res.substring(0, rf);
          log.log("res3 extipis " + res);
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
        if (def(start) && def(end)) {
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
      log.log("getgw " + netGw);
      internalIP = ni.interfaceForNetwork(netGw).address;
      log.log("Got internal ip " + internalIP);
      return(internalIP);
    }
    
    forwardPort(Int duration, Int external, Int internal) Bool {
      return(forwardPort(duration, external, internal, self.internalIP));
    }
    
    forwardPort(Int duration, Int external, Int internal, String internalIP) Bool {
    
      String cmd; String res;
      
      //upnpc -a 192.168.99.100 5555 9999 TCP
      cmd = "upnpc -a " + internalIP + " " + internal + " " + external + " TCP";
      res = System:Command.new(cmd).open().output.readStringClose();
      log.log("forwardPort result " + res);
      
      if (res.has("is redirected to")!) {
        throw(System:Exception.new("UPnP port forward failed, verify router settings"));
      }
      if (external != internal) {
        log.log("doing socat");
        //socat tcp-listen:2022,reuseaddr,fork tcp:localhost:22
        cmd = "socat tcp-listen:" + external + ",reuseaddr,fork tcp:localhost:" + internal;
        System:Command.new(cmd).run();
        log.log("local portfwd (socat) started for " + external + " to " + internal);
      }
      
      return(true);
      
    }
      
    forwardPortOld(Int duration, Int external, Int internal, String internalIP) Bool {
      if (true) { return(true); }
      dyn e;
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

use Net:IP;

class IP {

  default() self {
    fields {
      IO:Log log = IO:Logs.get(self);
    }
  }
  
  isIP(String ipback) Bool {
    Bool isIp = true;
    if (TS.isEmpty(ipback)) {
      return(false);
    }
            
    auto llip = ipback.split(".");
    log.log("llip sz " + llip.size);
    if (llip.size != 4) {
      isIp = false;
    } else {
      for (String llipp in llip) {
        log.log("llipp " + llipp);
        if (llipp.isInteger!) {
          isIp = false;
        }
      }
    }
    return(isIp);
  }
  
  IPForName(String name) String {
     String address;
     emit(jv) {
     """
     InetAddress address = InetAddress.getByName(beva_name.bems_toJvString()); 
     bevl_address = new $class/Text:String$(address.getHostAddress().getBytes("UTF-8"));
     """
     }
     return(address);
  }
  
  gatewayIPGet() String {
    
    System:Command sc = System:Command.new("netstat -rn").open();
    String res = sc.output.readString();
    sc.close();
    
    //log.log("netstat output " + res);
    
    if (System:CurrentPlatform.name == "mswin") {
      Int fz = res.find("0.0.0.0"); //win
    } else {
      fz = 0;
    }
    if (def(fz)) {
      if (System:CurrentPlatform.name == "macos") {
        fz2 = res.find("default", fz + 1);
      } else {
        Int fz2 = res.find("0.0.0.0", fz + 1);
      }
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
    //log.log("getgw accum " + accum);
    return(accum);
  }

}

use class App:Paths {

  new(_app) self {
    fields {
      dyn app = _app;
      String name = app.plugin.name;
      String dataName = name;
      IO:Log log = IO:Logs.get(self);
    }
    if (app.plugin.can("dataNameGet", 0)) {
      dataName = app.plugin.dataName; 
    }
  }

  dataPathGet() Path {
    Path dbp;
    ifEmit(platDroid) {
      dyn app = System:Objects.createInstance("UI:JvAd:WebBrowser");
      dbp = Path.apNew(app.secDataDir).addStep("BeData").addStep(dataName);
    }
    ifEmit(ccIsIos) {
    String idd;
emit(cc) {
"""
#ifdef BEDCC_ISIOS

NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
NSString *documentsDirectory = [paths objectAtIndex:0];
//NSLog(@"%@", documentsDirectory);
string ccdd = string([documentsDirectory UTF8String]);
bevl_idd = (new BEC_2_4_6_TextString())->bems_ccsnew(ccdd);
#endif

"""
}
    dbp = Path.apNew(idd).addStep(dataName);
    }
    ifEmit(apwk) {
    log.log("getting datapath apwk");
    //String jspw = Json:Marshaller.marshall(Maps.from("call", "getDocumentsDirectory"));
    String jspw = "getDocumentsDirectory:";
    emit(js) {
    """
    var jsres = prompt(bevl_jspw.bems_toJsString());
    bevl_jspw = new be_$class/Text:String$().bems_new(jsres);
    """
    }
    log.log("jspw " + jspw);
    dbp = Path.apNew(jspw).addStep(dataName);
    }
    ifNotEmit(platDroid) {
      ifNotEmit(ccIsIos) {
        ifNotEmit(apwk) {
          dbp = Path.apNew("Data").addStep(dataName);
        }
      }
    }
    return(dbp);
  }
  
  appPathGet() Path {
    Path dbp;
    ifEmit(platDroid) {
      dyn app = System:Objects.createInstance("UI:JvAd:WebBrowser");
      dbp = Path.apNew(app.appDataDir).addStep("BeData").addStep(name);
    }
    ifNotEmit(platDroid) {
      dbp = Path.apNew("App").addStep(name);
    }
    return(dbp);
  }

}

use Net:Gateway as Gw;

class Gw {

  default() self {  }
  
  defaultAddressGet() String {
    
    System:Command sc = System:Command.new("netstat -rn").open();
    String res = sc.output.readString();
    sc.close();
    
    //("!!!!!! netstat output " + res).print();
    
    if (System:CurrentPlatform.name == "mswin") {
      Int fz = res.find("0.0.0.0"); //win
    } else {
      fz = 0;
    }
    if (def(fz)) {
      if (System:CurrentPlatform.name == "macos") {
        fz2 = res.find("default", fz + 1);
      } else {
        Int fz2 = res.find("0.0.0.0", fz + 1);
      }
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
    //("gw accum " + accum).print();
    return(accum);
  }

}

//logic
use class App:AccountManager {

  new() self {
    fields {
      dyn kvDbs;
    }
  }
  
  new(_kvDbs) {
    new();
    kvDbs = _kvDbs;
  }
  
  getLogins() List {
    List logins = List.new();
    for (dyn kv in kvDbs.get("ACCOUNTS").getMap()) {
      logins.addValue(kv.key);
    }
    return(logins);
  }

  getAccount(String user) {
    if (TS.notEmpty(user)) {
		String aj = kvDbs.get("ACCOUNTS").get(user);
		if (TS.notEmpty(aj)) {
      //("aj " + aj).print();
		  Account a = Account.mapNew(Json:Unmarshaller.unmarshall(aj));
		}
	}
    return(a);
  }
  
  deleteAccount(Account a) {
    kvDbs.get("ACCOUNTS").delete(a.user);
  }
  
  putAccount(Account a) {
    kvDbs.get("ACCOUNTS").put(a.user, Json:Marshaller.marshall(a.toMap()));
  }
  
  getRequestAccount(request) Account {
    String an = request.getSession("account.name");
    Account a = getAccount(an);
    return(a);
  }

}

use class App:Account {

  new() self {
    fields {
      Set perms = Set.new();
    }
  }

  new(String _user, String _hashPass, String _salt, String _permsString) self {
    new();
    fields {
      String user = _user;
      String pass = _hashPass;
      String salt = _salt;
    }
    self.permsString = _permsString;
  }
  
  mapNew(Map map) self {
    new(map["user"], map["pass"], map["salt"], map["perms"]);
  }
  
  toMap() Map {
    return(Map.new().put("user", user).put("pass", pass).put("salt", salt).put("perms", self.permsString));
  }
  
  toString() String {
    String rs = String.new();
    String ps = self.permsString;
    if (TS.isEmpty(ps)) {
      ps = "";
    }
    rs += " User: " += user += " permsString: " += ps;
    return(rs);
  }
  
  passSet(String _pass) {
    salt = System:Random.getString(16);
    pass = passToHash(_pass, salt);
  }
  
  passToHash(String pass, String salt) String {
    if (TS.isEmpty(salt) || TS.isEmpty(pass)) {
      return(null);
    }
    pass = salt + pass;
    Digest:SHA256 ds = Digest:SHA256.new();
    for (Int i = 0;i < 5000;i++=) {
      pass = ds.digest(pass);
    }
    pass = Encode:Hex.encode(pass);
    return(pass);
  }
  
  checkPass(String _pass) Bool {
    _pass = passToHash(_pass, salt);
    if (def(_pass) && _pass == pass) {
      return(true);
    }
    return(false);
  }
  
  permsStringSet(String permsString) {
    perms = Set.new();
    if (TS.notEmpty(permsString)) {
      for (String perm in permsString.split(",")) {
        perms.put(perm);
      }
    }
  }
  
  permsStringGet() String {
    Bool first = true;
    String permsString = "";
    for (String perm in perms) {
      if (first) {
        first = false;
      } else {
        permsString += ",";
      }
      permsString += perm;
    }
    return(permsString);
  }
  
  isAdminGet() Bool {
    if (self.perms.has("admin")) {
      return(true);
    }
    return(false);
  }
  
}

use App:EventHandlers as AppEv;
class AppEv {

  emit(jv) {
  """
  static void handleEvent(String event) {
    try {
        
    bece_BEC_2_3_13_AppEventHandlers_bevs_inst.bem_handleEvent_1(
    new $class/Text:String$(event)
    );
    } catch (Throwable t) {
        System.err.println("failed in handleEvent " + t.getMessage());
        throw new Error(t.getMessage(), t);
    }
  }
  """
  }

  put(String label, dyn handler) {
    registry.put(label, handler);
  }
  
  get(String label) {
    return(registry.get(label));
  }
  
  default() self {
    fields {
      Map registry = Map.new();
    }
  }
  
  handleEvent(String event) {
    dyn rc = registry.get(event);
    if (def(rc)) {
      List args = List.new(0);
      rc.invoke(event, args);
    }
  }

}

emit(cs) {
"""
using System.Security.Cryptography;
using System.IO;
using System;
"""
}

emit(jv) {
"""
import java.security.*;
import javax.crypto.*;
import javax.crypto.spec.*;
"""
}
use Crypto:Symmetric as Crypt;
class Crypt {

  new() self {
    fields {
      Int keyLength = 16;
      Int ivLength = 16;
    }
  }
  
  encryptPassToHex(String iv, String pass, String val) String {
    return(Encode:Hex.encode(encryptPass(iv, pass, val)));
  }

  encryptPass(String iv, String pass, String val) String {
    Digest:SHA256 ds = Digest:SHA256.new();
    for (Int i = 0;i < 5000;i++=) {
      pass = ds.digest(pass);
    }
    return(encrypt(iv, pass, val));
  }
  
  encrypt(String iv, String key, String val) String {
    iv = iv.substring(0, ivLength);
    key = key.substring(0, keyLength);//jv limit
    val = val.substring(0, val.size);
    String res;
    emit(cs) {
    """
    byte[] key = beva_key.bevi_bytes;
    byte[] iv = beva_iv.bevi_bytes;
    byte[] val = beva_val.bevi_bytes;
    RijndaelManaged rijndael = new RijndaelManaged();
    ICryptoTransform enc = rijndael.CreateEncryptor(key, iv);
    byte[] res = enc.TransformFinalBlock(val, 0, val.Length);
    bevl_res = new $class/Text:String$(res);
    """
    }
    emit(jv) {
    """
    byte[] key = beva_key.bevi_bytes;
    byte[] iv = beva_iv.bevi_bytes;
    byte[] val = beva_val.bevi_bytes;
    Cipher aesCipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
    SecretKey secretKey = new SecretKeySpec(key, "AES");
    IvParameterSpec ivParameterSpec = new IvParameterSpec(iv);
    aesCipher.init(Cipher.ENCRYPT_MODE, secretKey, ivParameterSpec);
    byte[] res = aesCipher.doFinal(val);
    bevl_res = new $class/Text:String$(res);
    """
    }
    return(res);
  }
  
  decryptPassFromHex(String iv, String pass, String val) String {
    return(decryptPass(iv, pass, Encode:Hex.decode(val)));
  }
  
  decryptPass(String iv, String pass, String val) String {
    Digest:SHA256 ds = Digest:SHA256.new();
    for (Int i = 0;i < 5000;i++=) {
      pass = ds.digest(pass);
    }
    return(decrypt(iv, pass, val));
  }
  
  decrypt(String iv, String key, String val) String {
    iv = iv.substring(0, ivLength);
    key = key.substring(0, keyLength);//jv limit
    val = val.substring(0, val.size);
    String res;
    emit(cs) {
    """
    byte[] key = beva_key.bevi_bytes;
    byte[] iv = beva_iv.bevi_bytes;
    byte[] val = beva_val.bevi_bytes;
    RijndaelManaged rijndael = new RijndaelManaged();
    ICryptoTransform enc = rijndael.CreateDecryptor(key, iv);
    byte[] res = enc.TransformFinalBlock(val, 0, val.Length);
    bevl_res = new $class/Text:String$(res);
    """
    }
    emit(jv) {
    """
    byte[] key = beva_key.bevi_bytes;
    byte[] iv = beva_iv.bevi_bytes;
    byte[] val = beva_val.bevi_bytes;
    Cipher aesCipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
    SecretKey secretKey = new SecretKeySpec(key, "AES");
    IvParameterSpec ivParameterSpec = new IvParameterSpec(iv);
    aesCipher.init(Cipher.DECRYPT_MODE, secretKey, ivParameterSpec);
    byte[] res = aesCipher.doFinal(val);
    bevl_res = new $class/Text:String$(res);
    """
    }
    return(res);
  }
}

use class App:AuthPlugin(App:AjaxPlugin) {

     new() self {
       fields {
          log = IO:Logs.get(self);
          dyn app;
          String name = "Auth";
          Set nonAuthedRequests = Set.new();
          OLocker lastLoginBad = OLocker.new(false);
          Set authedUrls = Set.new();
          String authedUrlsConfigKey;
        }
        super.new();
     }
     
     accountManagerGet() AccountManager {
      fields {
        AccountManager accountManager;
      }
      if (undef(accountManager)) {
        accountManager = AccountManager.new(app.kvdbs);
      }
      return(accountManager);
    }
    
    handleCmd(Parameters params) Bool {
      String mode = params.getFirst("authCmd");
      if (TS.isEmpty(mode)) {
        return(false);
      }
      IO:Logs.turnOnAll();
      if (mode == "showAccounts") {
        for (String login in self.accountManager.getLogins()) {
          log.log("Account login " + login);
        }
      }
      if (mode == "getAccount") {
        user = params.getFirst("user");
        log.log("Getting Account " + user);
        ac = self.accountManager.getAccount(user);
        if (def(ac)) {
          //log.log(Json:Marshaller.new().marshall(ac.toMap()));
        } else {
          log.log("no such account");
        }
      }
      if (mode == "putAccount") {
        String user = params.getFirst("user");
        String pass = params.getFirst("pass");
        String perms = params.getFirst("perms");
        log.log("Putting Account " + user);
        Account ac = Account.new();
        ac.user = user;
        ac.pass = pass;
        if (def(perms)) {
          ac.permsString = perms;
        }
        self.accountManager.putAccount(ac);
      }
      if (mode == "setPerms") {
        user = params.getFirst("user");
        perms = params.getFirst("perms");
        log.log("Set Perms " + user);
        ac = self.accountManager.getAccount(user);
        ac.permsString = perms;
        self.accountManager.putAccount(ac);
        //log.log("Account " + ac);
      }
      if (mode == "setPass") {
        user = params.getFirst("user");
        pass = params.getFirst("pass");
        perms = params.getFirst("perms");
        log.log("Set Pass " + user);
        ac = self.accountManager.getAccount(user);
        ac.pass = pass;
        self.accountManager.putAccount(ac);
      }
      if (mode == "deleteAccount") {
        user = params.getFirst("user");
        log.log("Deleting Account " + user);
        ac = self.accountManager.getAccount(user);
        if (def(ac)) {
          self.accountManager.deleteAccount(ac);
          log.log("Deleted account " + user);
        } else {
          log.log("No such account for deletion " + user);
        }
      }
      return(true);
    }
    
    getSessionsForAccount(Account a) String {
        //a.user
        String res = String.new();
        String accountName = a.user;
        Map all = app.sessionManager.sessions.get("SESSIONS").getMap();
        for (dyn kv in all) {
          if (kv.key.ends("account.name") && kv.value == accountName) {
            //log.log("Found session " + kv.key);
            dyn kp = kv.key.split(".");
            String sessLabel = String.new();
            String name = app.sessionManager.sessions.get("SESSIONS").get(kp.first + ".session.name");
            if (def(name)) {
              log.log("sess name " + name);
              sessLabel += "Session named " += name;
            }
            String ip = app.sessionManager.sessions.get("SESSIONS").get(kp.first + ".ip");
            if (def(ip)) {
              log.log("sess ip " + ip);
              if (TS.notEmpty(sessLabel)) {
                sessLabel += " from ";
              } else {
                sessLabel += "Session from "
              }
              sessLabel += "IP Address " + ip;
            }
            if (TS.notEmpty(sessLabel)) {
              res += "<p>" += sessLabel += " <a href=\"#\" onclick=\"endSession('"
              += kp.first += "');return false;\">End Session (Log it out)</a></p>";
            }
          }
        }
        return(res);
      }
      
      clearExpired() {
        log.log("in clearExpired");
        dyn sess = app.sessionManager.sessions.get("SESSIONS");
        Map all = sess.getMap();
        Set seen = Set.new();
        Set del = Set.new();
        Int ns = Time:Interval.now().seconds;
        log.log("ns is " + ns);
        for (dyn kv in all) {
          dyn kp = kv.key.split(".");
          String skey = kp.first;
          if (del.has(skey)) {
            //delete it
            sess.delete(kv.key);
          }
          unless (seen.has(skey)) {
            seen.put(skey);
            String se = all.get(skey + ".sessionExp");
            if (TS.notEmpty(se) && Int.new(se) < 0) {
              //log.log("NO delete session " + skey);
            } else {
              if (TS.notEmpty(se)) {
                //log.log("sessionExp " + se);
                String sl = all.get(skey + ".sessionLength");
                if (TS.notEmpty(sl)) {
                  //log.log("sessionLength " + sl);
                }
                Int sei = Int.new(se);
                if (ns > sei) {
                  //log.log("session expired");
                  //log.log("YES delete session " + skey);
                  del.put(skey);
                  //delete it
                  sess.delete(kv.key);
                }
              } else {
                //log.log("YES delete session " + skey);
                del.put(skey);
                //delete it
                sess.delete(kv.key);
              }
            }
          }
        }
      }
      
     
    clearAllSessionsRequest(Map arg, request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        log.log("Clearing all sessions request by login " + request.context.get("account").user);
        app.sessionManager.sessions.get("SESSIONS").clear();
     }
     return(null);
   }
   
  requestFromAdmin(request) Bool {
    Account a = self.accountManager.getRequestAccount(request);
    if (def(a) && a.perms.has("admin")) {
      return(true);
    }
    return(false);
  }
  
  preLoginCheck(request) Bool {
    if (lastLoginBad.o) {
      Int slptime = System:Random.getIntMax(500);
      Time:Sleep.sleepMilliseconds(slptime);
    }
    return(true);
  }
  
  goodLogin(request) {
    lastLoginBad.o = false;
  }
  
  badLogin(request) {
    badRequest(request);
    log.error("bad login");
    if (def(request) && def(request.inputAddress)) {
      log.error("from " + request.inputAddress);
    }
    lastLoginBad.o = true;
  }
  
   
   clearAllTrackingRequest(Map arg, request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        log.log("Clearing all tracking requested by login "  + request.context.get("account").user);
        self.trackingManager.clear();
     }
     return(null);
   }
   
   endSessionRequest(Map arg, request) Map {
     if (TS.notEmpty(arg["sessionKey"])) {
      app.sessionManager.deleteSessionByKey(arg["sessionKey"]);
     }
     return(showSessionsRequest(arg, request));
   }
   
   changePassRequest(Map arg, request) {
      Account a = self.accountManager.getRequestAccount(request);
      unless (TS.notEmpty(arg["newPass"]) && a.checkPass(arg["oldPass"])) {
        log.log("incorrect old pass");
        throw(Alert.new("Old password incorrect"));
      }
      a.pass = arg["newPass"];
      self.accountManager.putAccount(a);
      return(CallBackUI.informResponse("Password Changed"));
   }
   
   loadAccountRequest(String accountName, request) {
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = self.accountManager.getAccount(accountName);
      if (def(a)) {
        Map res = Map.new();
        res["action"] = "loadAccountResponse";
        res["accountName"] = a.user;
        res["admin"] = a.perms.has("admin");
        return(res);
      } elseIf (true) {
        throw(Alert.new("No such account"));
      }
      return(null);
   }
   
   showAccountAdminRequest(Map arg, request) {
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      String accountLinks = String.new();
      List logins = self.accountManager.getLogins();
      for (String login in logins) {
        accountLinks += "<p><a href=\"#\" onclick=\"callApp('loadAccountRequest', '" += login += "');return false;\">Modify Account " += login += "</a></p>";
      }
      Map res = Map.new();
      res["action"] = "showAccountAdminResponse";
      res["accountLinks"] = accountLinks;
      return(res);
   }
   
   deleteAccountRequest(Map arg, request) {
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = self.accountManager.getAccount(arg["accountName"]);
      if (def(a)) {
        if (a.user == self.accountManager.getRequestAccount(request).user) {
          throw(Alert.new("Cannot delete own account"));
        }
      }
      self.accountManager.deleteAccount(a);
      return(showAccountAdminRequest(arg, request));
  }
  
  updateAccount(String name, String pass, Bool isAdmin) {
  
    Account a = self.accountManager.getAccount(name);
      if (undef(a)) {
        log.log(name + " not found, creating new");
        a = Account.new();
        a.user = name;
      } else {
        log.log(name + " found, use existing");
      }
      if (TS.notEmpty(pass)) {
        log.log("pass set, changing");
        a.pass = pass;
      }
      if (isAdmin) {
        a.perms.put("admin");
      } else {
        a.perms.delete("admin");
      }
      self.accountManager.putAccount(a);
  
  }
  
  updateAccountRequest(String name, String pass, Bool isAdmin, request) {
    unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      if (name == self.accountManager.getRequestAccount(request).user) {
        throw(Alert.new("Cannot change own account"));
      }
    
      updateAccount(name, pass, isAdmin);
      
      //return(CallBackUI.informResponse("Account " + name + " saved."));
      //return(showAccountsRequest(request));
      
      return(CallBackUI.multiResponse(Lists.from(CallBackUI.informResponse("Account " + name + " saved."), showAccountsRequest(request)))); 
      
  }
  
  removeAccountRequest(String name, request) {
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = self.accountManager.getAccount(name);
      if (def(a)) {
        if (a.user == self.accountManager.getRequestAccount(request).user) {
          throw(Alert.new("Cannot delete own account"));
        }
      }
      self.accountManager.deleteAccount(a);
      //return(CallBackUI.informResponse("Account " + name + " removed."));
      //return(showAccountsRequest(request));
      
      return(CallBackUI.multiResponse(Lists.from(CallBackUI.informResponse("Account " + name + " removed."), showAccountsRequest(request)))); 
  }
  
  showAccountsRequest(request) {
    unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      String accountLinks = "";
    List logins = self.accountManager.getLogins();
      for (String login in logins) {
        
        Account a = self.accountManager.getAccount(login);
        accountLinks += "<p>Account Name: " += login += " is administrator: " += a.isAdmin;
      }
      return(CallBackUI.setElementsInnerHTMLResponse(Maps.from("accountListDiv", accountLinks)));
  }
      
   saveAccountRequest(Map arg, request) {
      //I think this is unused
      log.log("in app saveAccountRequest");
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = self.accountManager.getAccount(arg["accountName"]);
      if (undef(a)) {
        log.log(arg["accountName"] + " not found, creating new");
        a = Account.new();
        a.user = arg["accountName"];
      } else {
        if (a.user == self.accountManager.getRequestAccount(request).user) {
          throw(Alert.new("Cannot change own account"));
        }
        log.log(arg["accountName"] + " found, use existing");
      }
      if (TS.notEmpty(arg["accountPass"])) {
        log.log("pass set, changing");
        a.pass = arg["accountPass"];
      }
      if (arg["admin"]) {
        a.perms.put("admin");
      } else {
        a.perms.delete("admin");
      }
      self.accountManager.putAccount(a);
      return(null);
   }
   
   showSessionsRequest(Map arg, request) {
      Account a = self.accountManager.getRequestAccount(request);
      Map res = Map.new();
      res["action"] = "showSessionsResponse";
      res["sessionsList"] = getSessionsForAccount(a);
      return(res);
   }
   
   checkLoggedInRequest(Map arg, request) {
    String accountName = request.getSession("account.name");
    if (TS.isEmpty(accountName) && request.embedded) {
      log.log("checking embeddedLogin");
      String eml = app.configManager.get("auth.embeddedLogin");
      if (TS.notEmpty(eml)) {
        log.log("checking embeddedLogin eml notempty");
        accountName = eml;
      }
    }
    if (TS.notEmpty(accountName)) {
      Account a = self.accountManager.getAccount(accountName);
      if (def(a)) {
        log.output("Found logged in account " + accountName);
        if (def(request) && def(request.inputAddress)) {
          log.output("from " + request.inputAddress);
        }
        Map sarg = Map.new();
        sarg["accountName"] = accountName;
        setupSession(sarg, request);
        Map res = Map.new();
        res["action"] = "loggedInResponse";
        res["name"] = accountName;
        res = loggedIn(a, res, arg, request);
        res.delete("loginUri");
        return(res);
      } else {
        log.output("No such account " + accountName);
      }
    }
    log.log("doing tologin return");
    return(CallBackUI.toLoginResponse());
  }
  
  setupSession(Map arg, request) {
    request.putSession("account.name", arg["accountName"]);
    if (request.embedded) {
      log.log("putting embeddedLogin");
      app.configManager.put("auth.embeddedLogin", arg["accountName"]);
    }
    request.putSession("ip", request.inputAddress);
    if (TS.notEmpty(arg["sessionName"])) {
      request.putSession("session.name", arg["sessionName"]);
    }
    String sessionLength = arg["sessionLength"];
    if (TS.isEmpty(sessionLength) || sessionLength.isInteger!) {
      sessionLength = request.getSession("sessionLength");
      if (TS.isEmpty(sessionLength) || sessionLength.isInteger!) {
        sessionLength = "30";
      }
    }
    if (request.embedded) {
      sessionLength = "-1";
    }
    Int sessionLengthI = Int.new(sessionLength);
    log.log("sessionLength " + sessionLengthI.toString());
    request.putSession("sessionLength", sessionLengthI.toString());
    if (sessionLengthI < 0) {
      request.putSession("sessionExp", sessionLengthI.toString());
    } else {
      Int snow = Time:Interval.now().seconds;
      Int ssd = snow + (sessionLengthI * 60);
      request.putSession("sessionExp", ssd.toString());
      Int ssu = snow + 60;
      request.putSession("sessionUpdate", ssu.toString());
    }

    log.log("setup session, sessionLength " + request.getSession("sessionLength") + " sessionExp " + request.getSession("sessionExp"))
  }
  
  pageTokenRequest(Map arg, request) {
    log.log("in pagetokenrequest");
    if (app.plugin.okForPageToken(request)) {
      Map res = Map.new();
      pageToken = request.getSession("pageToken");
      if (TS.isEmpty(pageToken)) {
        String pageToken = System:Random.getString(32);
        request.putSession("pageToken", pageToken);
      }
      res["pageToken"] = pageToken;
      res["action"] = "pageTokenResponse";
    }
    return(res);
  }

  loginRequest(Map arg, request) {
    Account a = self.accountManager.getAccount(arg["accountName"]);
    if (def(a) && preLoginCheck(request)) {
      log.log("Found account " + arg["accountName"]);
      if (a.checkPass(arg["accountPass"])) {
        log.log("Login ok");
        Map res = Map.new();
        if (arg.has("serviceLogin")) {
          String pageToken = System:Random.getString(32);
          String serviceSessionKey = System:Random.getString(64);
          request.serviceSessionKey = serviceSessionKey;
          request.putSession("pageToken", pageToken);
          request.putSession("isServiceSession", "true");
          res["serviceSessionKey"] = serviceSessionKey;
          res["pageToken"] = pageToken;
        }
        if (arg.has("pageToken") && TS.notEmpty(arg["pageToken"])) {
          log.log("in login saving pagetoken");
          request.putSession("pageToken", arg["pageToken"]);
        }
        setupSession(arg, request);
        String ref = request.getInputHeader("referer");
        if (TS.notEmpty(ref)) {
          request.putSession("loginReferer", ref);
        }
        res["action"] = "loggedInResponse";
        res["name"] = arg["accountName"];
        goodLogin(request);
        request.context.put("account", a);
        return(loggedIn(a, res, arg, request));
      } else {
        log.log("Login notok");
        badLogin(request);
      }
    } else {
      log.log("No such account " + arg["accountName"]);
      badLogin(request);
    }
    return(logoutRequest(arg, request));
  }
  
 loggedIn(Account a, Map res, Map arg, request) Map {
    if (app.plugin.can("loggedIn", 4)) {
      res = app.plugin.loggedIn(a, res, arg, request)
    }
    return(res);
  }
  
  logoutRequest(Map arg, request) {
    
    if (def(request) && def(request.inputAddress)) {
      log.output("logout from " + request.inputAddress);
    }
    
    if (TS.notEmpty(request.getSession("account.name"))) {
      log.output("user " + request.getSession("account.name"));
    }
    
    request.putSession("account.name", "");
    
    if (request.embedded) {
      app.configManager.delete("auth.embeddedLogin");
    }
    Map res = Map.new();
    res["action"] = "logoutResponse";
    return(res);
  }
  
  start() {
    log.log("initting managers auth");
    self.trackingManagerGet();
  }
  
  trackingManagerGet() KvDb {
    return(app.kvdbs.get("TRACKING"));
  }
  
  check(request) Bool {
  
  /*
    Int maxBad = 300;
    Int clearSecs = 40;
    Int updateSecs = 20;
  */
  
  
    //Int maxBad = 10;
    Int maxBad = 75;
    Int clearSecs = 50;
    Int updateSecs = 10;
  
    
    if (request.embedded) {
      return(true);
    }
    
    String ip = request.inputAddress;
    String sip = request.getSession("ip");
    
    Int ns = Time:Interval.now().seconds;
    
    if (TS.notEmpty(ip)) {
      String ct = self.trackingManager.get("IP." + ip);
      if (TS.notEmpty(ct)) {
        String ltm = self.trackingManager.get("LB." + ip);
        if (TS.notEmpty(ltm)) {
          Int ltmi = Int.new(ltm);
          if (ns - ltmi > clearSecs) {
            log.log("clear bad " + ip);
            badcount = 0;
            self.trackingManager.delete("IP." + ip);
            self.trackingManager.delete("LB." + ip);
          } else {
            badcount = Int.new(ct);
          }
        } else {
          Int badcount = Int.new(ct);
        }
      } else {
        badcount = 0;
      }
    }
    if (def(request.context.get("unknownSession"))) {
      request.context.delete("unknownSession");
      log.log("upping bad in check");
      badcount++=;
      self.trackingManager.put("IP." + ip, badcount.toString());
      self.trackingManager.put("LB." + ip, ns.toString());
    }
    if (badcount > maxBad) {
      log.log("toomdyn bad " + ip);
      if (def(ltmi) && ns - ltmi > updateSecs) {
        log.log("lp update");
        self.trackingManager.put("LB." + ip, ns.toString());
      } else {
        log.log("no update");
      }
      return(false);
    }
    return(true);
  }
  
  badRequest(request) {
    log.log("upping bad in badRequest");
    String ip = request.inputAddress;
    if (TS.notEmpty(ip)) {
      log.log("br ip not empty " + ip);
      Int ns = Time:Interval.now().seconds;
      String ct = self.trackingManager.get("IP." + ip);
      if (TS.notEmpty(ct)) {
        Int badcount = Int.new(ct);
      } else {
        badcount = 0;
      }
      badcount++=;
      self.trackingManager.put("IP." + ip, badcount.toString());
      self.trackingManager.put("LB." + ip, ns.toString());
    }
  }
  
  toLogin(request) this {
    request.scriptReturn = CallBackUI.toLoginResponse();
  }
  
  isCrossSite(request) Bool {
    if (request.embedded) { return(false); }
    String ref = request.getInputHeader("referer");
    String lref = request.getSession("loginReferer");
    if (TS.notEmpty(ref) && TS.notEmpty(lref)) {
      //log.log("have ref and lref " + ref + " " + lref);
      if (ref.begins(lref) || lref.begins(ref)) {
        //log.log("not crosssite due to loginReferer");
        return(false);
      }
    } else {
      if (TS.isEmpty(ref)) {
        log.log("no ref");
      }
      if (TS.isEmpty(lref)) {
        log.log("no lref");
      }
    }
    //if (true) { return(false); } //tempt to test referrer edition
    String la = request.localAddress;
    if (TS.isEmpty(ref) || TS.isEmpty(la)) {
      log.log("isCrossSite true empty");
      //if (TS.isEmpty(ref)) { log.log("ref empty"); } else { log.log("la empty"); }
      return(true);
    }
    if (def(authedUrlsConfigKey)) {
      String aval = app.configManager.get(authedUrlsConfigKey);
      if (TS.notEmpty(aval)) {
        authedUrls = Sets.fromList(Json:Unmarshaller.unmarshall(aval));
      }
    }
    for (sn in authedUrls) {
      //log.log("authedUrl is " + sn);
      if (ref.lower().begins(sn.lower())) {
        //log.log("ixs false sitelist");
        return(false);
      }
    }
    //log.log("referer is " + ref);
    String snlist = app.configManager.get("auth.siteNames");
    if (TS.notEmpty(snlist)) {
      log.log("siteNames " + snlist);
      for (String sn in snlist.split(",")) {
        log.log("sn is " + sn);
        if (ref.begins(sn)) {
          //log.log("ixs false sitelist");
          return(false);
        }
      }
    }
    la = app.webProto + "://" + la;
    if (ref.begins(la)) {
      //log.log("isCrossSite false begins " + la + " " + ref);
      return(false);
    }
    
    String pref = app.webProto + "://";
    //log.log("prefix " + pref);
    String intPort = app.webPort;
    if (ref.begins(pref + "127.0.0.1:" + intPort) || ref.begins(pref + "localhost:" + intPort)) {
      //log.log("icc false localhost");
      return(false);
    }
    
    pref = "http://";
    //log.log("prefix " + pref);
    intPort = app.appPort;
    if (ref.begins(pref + "127.0.0.1:" + intPort) || ref.begins(pref + "localhost:" + intPort)) {
      //log.log("icc false localhost");
      return(false);
    }
    

    //log.log("isCrossSite true not begins " + la + " " + ref);
    return(true);
  }
  
  checkRenewSession(request) Bool {
    String sessionExp = request.getSession("sessionExp");
    if (TS.isEmpty(sessionExp)) {
      //log.log("no sessionExp");
      return(false);
    }
    //log.log("sessionExp " + sessionExp);
    Int sei = Int.new(sessionExp);
    if (sei < 0) {
      //log.log("session never expires");
      return(true); //never expires
    }
    Int ns = Time:Interval.now().seconds;
    if (ns > sei) {
      log.log("session expired");
      return(false);
    }
    Int nu = Int.new(request.getSession("sessionUpdate"));
    if (ns > nu) {
      log.log("refreshing sessionUpdate");
      nu = ns + 60;
      request.putSession("sessionUpdate", nu.toString());
      Int ne = (Int.new(request.getSession("sessionLength")) * 60) + ns;
      request.putSession("sessionExp", ne.toString());
    }
    //log.log("checkRenewSession returning true");
    return(true);
  }
  
  handleWeb(request) this {
    //log.log("in auth uri " + request.uri);
    
    if (request.uri == "/") {
      //only for ajaxy and embedded calls, ?embedded auth version?
      prepArgs(request);
      Map arg = request.context["arg"];
      if (request.embedded! && def(arg) && TS.notEmpty(arg["serviceSessionKey"])) {
        request.serviceSessionKey = arg["serviceSessionKey"];
      }
    }
    unless (check(request)) {
      toLogin(request);
      return(self);
     }
     
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
       String ln = request.getParameter("accountName");
       String lp = request.getParameter("accountPass");
       if (TS.notEmpty(ln) && TS.notEmpty(lp)) {
          log.log("doing svc login");
          Account a = self.accountManager.getAccount(ln);
          if (def(a) && preLoginCheck(request)) {
            log.log("Found account " + ln);
            if (a.checkPass(lp)) {
              log.log("svc login ok");
              request.putSession("account.name", ln);
              request.putSession("ip", request.inputAddress);
              goodLogin(request);
              accountName = ln;
            } else {
              badLogin(request);
            }
          } else {
            badLogin(request);
          }
        }
      }
     
        try {
            if (def(arg) && def(arg.get("action"))) {
              String aname = arg.get("action");
            }
            if (isCrossSite(request)) {
              unless (aname == "loginRequest" || aname == "pageTokenRequest") {
                log.log("rejecting cross site request");
                toLogin(request);
                return(self);
              }
            }
            if (TS.notEmpty(aname)) {
               if (nonAuthedRequests.has(aname)) {
                 //log.log("nar has");
                 request.continueHandling = true;
                 return(self);
               } else {
                //log.log("nar nohas");
                unless (aname == "pageTokenRequest") {
                  accountName = request.getSession("account.name");
                  if (TS.isEmpty(accountName)) {
                    unless (aname == "loginRequest" || aname == "checkLoggedInRequest") {
                      log.log("ret givelogin");
                      toLogin(request);
                      return(self);
                    }
                  } else {
                  
                    unless (aname == "loginRequest" || checkRenewSession(request)) {
                        log.log("rejecting expired session request");
                        toLogin(request);
                        return(self);
                    }
                  
                    //checkLoggedInRequest is ok
                     
                    String stok = request.getSession("pageToken");
                    String atok = arg["pageToken"];
                    unless (TS.isEmpty(stok) && aname == "loginRequest") {
                      if (TS.isEmpty(stok) || TS.isEmpty(atok)) {
                        log.log("stok or atok emtpy failing due to pageToken");
                        toLogin(request);
                        return(self);
                      }
                      if (stok != atok) {
                        log.log("stok != atok failing due to pageToken");
                        toLogin(request);
                        return(self);
                      }
                    }
                  
                    //log.log("pageToken action " + aname);
                    //if (def(arg["pageToken"])) { log.log("pageToken " + //arg["pageToken"]); } else { log.log("no pageToken"); }
                    //if (def(stok)) { log.log("session pageToken " + stok); }
                  }
                }
              } 
              //log.log("here");
              request.context.put("account", self.accountManager.getRequestAccount(request));
              super.handleWeb(request);
          } else {
            request.continueHandling = true;
          }
          if (undef(request.getSession("account.name"))) {
            request.continueHandling = false;
          } elseIf (undef(request.context.get("account"))) {
            request.context.put("account", self.accountManager.getRequestAccount(request));
          }
          //log.log("auth done continueHandling is " + request.continueHandling);
          return(self);
        } catch (dyn e) {
           log.error("Caught exception during handleWeb B");
           if (def(e)) {
            log.error("Exception was " + e);
           }
        }
    }
  
   
}

use class App:PublicReadPlugin {

     new() self {
       fields {
          dyn app;
          String name = "Public";
          IO:Log log = IO:Logs.get(self);
        }
     }
     
       
     handleWeb(request) this {
       //log.log("in public read plugin");
       String rmtd = request.inputMethod;
       //log.log("public read rmtd is " + rmtd);
       if (TS.isEmpty(rmtd) || rmtd == "GET") {
         //log.log("in rmtd method is get");
         String uri = request.uri;
         //log.log("uri " + uri);
         if (TS.isEmpty(uri) || uri == "/") {
          //log.log("empty uri going to base page");
          request.outputContent = "<html><head><script>location=\"" + app.plugin.homePage + "\"</script></html>";
          return(self);
         }
         File imgfile = File.apNew(Encode:Url.decode(uri.substring(1)));
         Path pa = imgfile.absPath;
         Bool readOk = false;
         for (dyn pl in app.plugins) {
          if (pl.can("checkPublicReadPath", 2)) {
            if (pl.checkPublicReadPath(pa, request)) {
              readOk = true;
              break;
            }
          }
         }
         if (readOk) {
            //log.log("chkrdp fm true public");
           //log.log("imgfile " + imgfile.path);
           if (imgfile.exists) {
            String mtype = Mimes.forUri(uri);
            request.outputContentType = mtype;
            IO:Writer outw = request.openOutput();
            IO:Reader inr = imgfile.reader.open();
            inr.copyData(outw);
            request.closeOutputWriter();
            inr.close();
            return(self);
           }
         }
       }
       request.continueHandling = true;
       return(self);
     }
}

use class App:LocalAccessPlugin {

     new() self {
       fields {
          dyn app;
          String name = "LocalAccess";
          IO:Log log = IO:Logs.get(self);
          String lattok = System:Random.getString(64);
        }
     }
     
     start() {
       String clk = app.configManager.get("localAccess.cookie");
       if (TS.isEmpty(clk)) {
         app.configManager.put("localAccess.cookie", lattok);
       } else {
         lattok = clk;
       }
     }
     
       
     handleWeb(request) this {
       //log.log("in local access plugin");
       String rmtd = request.inputMethod;
       //log.log("la rmtd is " + rmtd);
       if (TS.isEmpty(rmtd) || rmtd == "GET") {
         //log.log("in rmtd method is get");
         String uri = request.uri;
         //log.log("la uri " + uri);
         String lat = request.getParameter("lattok");
         if (TS.isEmpty(lat)) {
           //log.log("lat empty");
         } else {
           //log.log("lat present");
           String clat = app.configManager.get("localAccess.token");
           if (TS.notEmpty(clat) && clat == lat) {
             //log.log("clat eq lattok, set cookie");
             app.configManager.delete("localAccess.token");
             request.setOutputCookie("lattok", lattok, "/", true, false);
             request.outputContent = "<html><head><script>location=\"" + app.plugin.homePage + "\"</script></html>";
             return(self);
           } else {
             //log.log("clat notok, nogood");
           }
         }
       }
       String reqtok = request.getInputCookie("lattok");
       if (TS.notEmpty(reqtok) && reqtok == lattok) {
        //log.log("cookie good, keep going");
        if (request.localAddress == "127.0.0.1" && request.remoteAddress == "127.0.0.1" && request.getInputHeader("referer").begins("http://127.0.0.1")) {
          request.continueHandling = true;
          return(self);
        } else {
          log.log("nogood bad addr");
          log.log("raddr " + request.localAddress);
          log.log("remaddr " + request.remoteAddress);
          log.log("refr " + request.getInputHeader("referer"));
        }
       }
       //log.log("lat failed");
       request.continueHandling = false;
       return(self);
     }
}

use class App:WebReverseProxyPlugin {

     new() self {
       fields {
          dyn app;
          String name = "WRProxy";
          String dataName = "BBridge";
          IO:Log log = IO:Logs.get(self);
          //String destUrl = "http://127.0.0.1:";
          String destUrl;
          Bool sslValidate;
        }
        //IO:Logs.turnOnAll();
     }
     
     start() {
       if (undef(destUrl)) {
        destUrl = app.params.getFirst("proxyDestUrl");
       }
       if (undef(destUrl)) {
        throw(Exception.new("proxyDestUrl parameter undefined"));
       }
       if (undef(sslValidate)) {
         String svs = app.params.getFirst("proxySslValidate");
         if (TS.isEmpty(svs)) {
          svs = "true";
         }
         self.sslValidate = Bool.new(svs);
       }
     }
     
     sslValidateSet(Bool sslv) {
      sslValidate = sslv;
      Web:Client:CertificateManager.validateHosts = sslv;
      Web:Client:CertificateManager.validateCertificates = sslv;
     }
     
     handleWeb(request) this {
            
       String uri = request.uri;
       if (TS.isEmpty(uri)) {
        log.log("uri empty");
        uri = "/";
       }
       log.log("proxy uri " + uri);
       
       String qs = request.queryString;
       if (TS.isEmpty(qs)) {
        log.log("qs empty");
        qs = "";
       } else {
        qs = "?" + qs;
       }
       log.log("qs " + qs);
       
       String destReq = destUrl + uri + qs;
       
       log.log("destReq " + destReq);
       
       String rmtd = request.inputMethod;
       log.log("req mtd " + rmtd);
       
       String accountName = request.getSession("account.name");
       if (TS.isEmpty(accountName)) {
        log.log("no accountname, halting");
        request.outputContent = "<html><head><body><p>Logged out<p>Please log back into Bridge to continue</body></html>";
        return(self);
       } else {
        log.log("found account " + accountName);
       }
       
       Web:Client client = Web:Client.new();
       client.followRedirects = false;
       client.url = destReq;
       
       //"User-Agent"
       //Set suppress = Sets.from("Server", "Accept", "Connection", "Content-Length", "Content-Type", "Date", "Expect", "Host", "If-Modified-Since", "Range", "Referrer", "Referer", "Transfer-Encoding", "Proxy-Connection");
       
       Set include = Sets.from("User-Agent", "Cookie", "Referer", "Set-Cookie");
       
       //headers
       Set hkeys = request.inputHeaderKeys;
       for (String hkey in hkeys) {
        //log.log("inputHeaderKey " + hkey);
        String ihv = request.getInputHeader(hkey);
        //log.log("inputHeaderValue " + ihv);
        if (include.has(hkey)) {
          //log.log("sending client header " + hkey + " " + ihv);
          client.outputHeaders.put(hkey, ihv);
        } else {
          //log.log("suppressed header " + hkey + " " + ihv);
        }
       }
       
       //cookies SEE IF PART OF HEADERS
       //user agent PART OF HEADERS BUT CHECK
       //body for posts DONE
       if (rmtd == "POST" || rmtd == "PUT") {
         log.log("in put or post");
         client.verb = rmtd;
         client.outputContentType = request.inputContentType;
         outw = client.openOutput();
         inr = request.openInput();
         inr.copyData(outw);
       }
       
       IO:Reader inr = client.openInput();
       
       String ct = client.inputContentType;
       
       if (TS.notEmpty(ct)) {
        log.log("ct " + ct);
        request.outputContentType = ct;
       } else {
        log.log("ct empty");
       }
              
       for (auto kv in client.inputHeaders) {
        if (include.has(kv.key)) {
          //log.log("sending response header " + kv.key + " " + kv.value);
          request.setOutputHeader(kv.key, kv.value);
        } else {
          if (kv.key == "Location") {
            log.log("got a location header");
            String loc = kv.value;
            if (loc.has(destUrl)) {
              loc = loc.substring(destUrl.size);
            }
            log.log("final loc, will send " + loc)
            //request.setOutputHeader(kv.key, loc);
            request.outputContent = "<html><head><script>location=\"" + loc + "\"</script></html>";
            return(self);
          }
          //log.log("suppressed response header " + kv.key + " " + kv.value);
        }
       }
       
       IO:Writer outw = request.openOutput();
       inr.copyData(outw);
       request.closeOutputWriter();
       inr.close();
       
       
     }
}

use App:MimeTypes as Mimes;

class Mimes {
  
  default() self {  }
  
  forUri(String uri) String {
    String uril = uri.lower();
    String mtype;
    if (uril.ends(".html") || uril.ends(".htm") || uril.ends(".mhtml")) {
      mtype = "text/html";
    } elseIf (uril.ends(".jpg")) {
      mtype = "image/jpeg";
    } elseIf (uril.ends(".gif")) {
      mtype = "image/gif";
    } elseIf (uril.ends(".svg")) {
      mtype = "image/svg+xml";
    } elseIf (uril.ends(".js")) {
      mtype = "text/javascript";
    } elseIf (uril.ends(".css")) {
      mtype = "text/css";
    } elseIf (uril.ends(".txt")) {
      mtype = "text/plain";
    } elseIf (uril.ends(".pdf")) {
      mtype = "application/pdf";
    } elseIf (uril.ends(".woff")) {
      mtype = "application/font-woff";
    } elseIf (uril.ends(".eot")) {
      mtype = "application/vnd.ms-fontobject";  
    } elseIf (uril.ends(".odt")) {
      mtype = "application/vnd.oasis.opendocument.text";  
    } elseIf (uril.ends(".eot")) {
      mtype = "application/font-sfnt";
    } else {
      mtype = "application/octet-stream";
    }
    return(mtype);
  }
  
}

use class App:FileManagerPlugin(App:AjaxPlugin) {

     new() self {
       fields {
          dyn app;
          String name = "Files";
        }
        super.new();
        log = IO:Logs.get(self);
     }
     
    checkWritePath(Path p, Map arg, request) Bool {
      Account a = request.context.get("account");
      if (def(a) && a.perms.has("admin")) {
        return(true);
      }
      String accountName = request.getSession("account.name");
      dyn e;
      Bool isOk = false;
      if (undef(accountName)) { accountName = ""; }
      try {
        Path pa = p.file.absPath;
        if (TS.notEmpty(accountName)) {
          Path h = Path.apNew("Home/" + accountName).file.absPath;
        }
        String pas = pa.toString();
        if (def(h) && pas.begins(h.toString())) {
          isOk = true;
        }
      } catch (e) {
        log.error("Path " + p + " accountName " + accountName + " excepted in checkPath " + e);
      }
      //log.log("checkPath isOk " + isOk);
      return(isOk);
   }
   
   checkReadPath(Path p, Map arg, request) Bool {
    log.log("in chkrdp fm");
    Path pa = p.file.absPath;
    String pas = pa.toString();
    Account a = request.context.get("account");
    if (def(a) && a.perms.has("admin")) {
      return(true);
    }
    String accountName = request.getSession("account.name");
    dyn e;
    Bool isOk = false;
    if (undef(accountName)) { accountName = ""; }
    try {
      if (TS.notEmpty(accountName)) {
        Path h = Path.apNew("Home/" + accountName).file.absPath;
      }
      if (def(h) && pas.begins(h.toString())) {
        isOk = true;
      }
      Path s = Path.apNew("Shared").file.absPath;
      if (def(s) && pas.begins(s.toString())) {
        isOk = true;
      }
      for (dyn kv in app.configManager.getMap("fileManager.sharedDirs.")) {
        Path fms = Path.apNew(kv.value).file.absPath;
        if (def(fms) && pas.begins(fms.toString())) {
          isOk = true;
        }
      }
      for (kv in app.configManager.getMap("fileManager.accountDirs." + accountName + ".")) {
        fms = Path.apNew(kv.value).file.absPath;
        if (def(fms) && pas.begins(fms.toString())) {
          isOk = true;
        }
      }
    } catch (e) {
      log.error("Path " + p + " accountName " + accountName + " excepted in checkPath " + e);
    }
    //log.log("checkPath isOk " + isOk);
    return(isOk);
   }
  
     handleWeb(request) this {
       String rmtd = request.inputMethod;
       log.log("in filemanager handleweb rmtd is " + rmtd);
       if (TS.isEmpty(rmtd) || rmtd != "PUT") {
          App:AjaxPlugin.new().prepArgs(request);
          Map arg = request.context["arg"];
       }
       if (undef(arg)) {
         log.log("in fm arg undef");
         String uri = request.uri;
         log.log("uri " + uri);
         if (TS.isEmpty(uri) || uri == "/") {
          log.log("empty uri in filemanager");
          return(self);
         }
         File imgfile = File.apNew(Encode:Url.decode(uri.substring(1)));
         if (TS.notEmpty(rmtd) && rmtd == "PUT") {
           if (checkWritePath(imgfile.path, null, request)) {
             log.log("put for " + imgfile.path);
             if (imgfile.path.parent.file.exists!) {
              imgfile.path.parent.file.makeDirs();
             }
             if (imgfile.exists) { imgfile.delete(); }
              outw = imgfile.writer.open();
              inr = request.openInput();
              inr.copyData(outw);
              request.closeInputReader();
              outw.close();
              request.outputContent = "UPLOAD COMPLETE";
           }
         } elseIf (checkReadPath(imgfile.path, arg, request)) {
           log.log("imgfile " + imgfile.path);
           if (imgfile.exists) {
            String mtype = Mimes.forUri(uri);
            request.outputContentType = mtype;
            IO:Writer outw = request.openOutput();
            IO:Reader inr = imgfile.reader.open();
            inr.copyData(outw);
            request.closeOutputWriter();
            inr.close();
           }
         }
        return(self);
       }
       super.handleWeb(request);
       return(self);
     }
     
     deleteRequest(Map arg, request) Map {
     log.log("del request");
     String path = arg["path"];
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
     if (TS.notEmpty(path)) {
       File dirFile = File.apNew(path);
       if (dirFile.exists && checkWritePath(dirFile.path, arg, request)) {
         log.log("deleting " + dirFile.path);
         dirFile.delete();
       }
     }
     return(null);
   }
   
   smallPutRequest(Map arg, request) Map {
     log.log("put request");
     String path = arg["path"];
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
     if (TS.notEmpty(path)) {
       File dirFile = File.apNew(path);
       if (checkWritePath(dirFile.path, arg, request)) {
         log.log("writing " + dirFile.path);
         if (dirFile.exists) { dirFile.delete(); }
         if (dirFile.path.parent.file.exists!) { dirFile.path.parent.file.makeDirs(); }
         dirFile.writer.open().writeStringClose(arg["content"]);
       }
     }
     return(null);
   }
   
   smallGetRequest(Map arg, request) Map {
     log.log("get request");
     String path = arg["path"];
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
     Map res = Map.new();
     res["action"] = "smallGetResponse";
     if (TS.notEmpty(path)) {
       File dirFile = File.apNew(path);
       if (checkReadPath(dirFile.path, arg, request)) {
         log.log("reading " + dirFile.path);
         if (dirFile.exists) {
           log.log("it exists");
           res["content"] = dirFile.reader.open().readStringClose();
         }
       }
     }
     return(res);
   }
   
   homeRequest(Map arg, request) Map {
     log.log("in local browse req");
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
      Path path = getHomeDir(request);
      
      Map ret = Map.new();
      ret.put("action", "getHomeResponse");
      ret.put("path", path.toString());
      return(ret);
    }
   
   listRequest(Map arg, request) Map {
     log.log("in local browse req");
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
      if (arg.has("path")) {
        Path path = Path.new(arg["path"]);
      } elseIf (arg.has("homeRelPath")) {
        path = getHomeDir(request) + Path.new(arg["homeRelPath"]);
        log.log("homeRelPath " + path.toString());
      } else {
        path = getHomeDir(request);
      }
      
      Account a = request.context.get("account");
      List dirList = List.new();
      File dirFile = path.file;
      if (dirFile.exists && checkReadPath(dirFile.path, arg, request)) {
        if (dirFile.isDir) {
          auto dit = dirFile.iterator;
          dit.open();
          List olist = List.new();
          Map omap = Map.new();
          while (dit.hasNext) {
            File entry = dit.next;
            Path p = entry.path;
            dirList += p.toString();
          }
          dit.close();
        }
      }
      Map ret = Map.new();
      ret.put("action", "listResponse");
      ret.put("path", path.toString());
      ret.put("list", dirList);
      return(ret);
    }
   
   copyRequest(Map arg, request) Map {
     log.log("copy request");
     String path = arg["path"];
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
     if (TS.notEmpty(path)) {
       File dirFile = File.apNew(Encode:Hex.new().decode(path));
       if (TS.notEmpty(arg["toName"]) && dirFile.exists && checkWritePath(dirFile.path, arg, request)) {
         dyn dpath = Path.apNew(arg["toName"]);
         dpath = dirFile.path.parent.copy() + dpath;
         log.log("precheck write " + dpath);
         if (checkWritePath(dpath, arg, request)) {
           log.log("copying " + dirFile.path + " to " + dpath);
           if (dpath.parent.file.exists!) {
             dpath.parent.file.makeDirs();
           }
           if (dpath.file.exists) { dpath.file.delete(); }
            IO:Writer outw = dpath.file.writer.open();
            IO:Reader inr = dirFile.reader.open();
            inr.copyData(outw);
            outw.close();
            inr.close();
          }
       }
     }
     return(null);
   }
   
   createDirectoryRequest(Map arg, request) Map {
     log.log("createdir request");
     String inDir = arg["inDir"];
     String dirName = arg["dirName"];
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
     if (TS.notEmpty(inDir) && TS.notEmpty(dirName)) {
       Path dirPath = Path.apNew(Encode:Hex.new().decode(inDir));
       dirPath.addStep(dirName);
       File dirFile = dirPath.file.absPath.file;
       if (dirFile.exists! && checkWritePath(dirFile.path, arg, request)) {
         log.log("creating " + dirFile.path);
         dirFile.makeDirs();
       }
     }
     arg["path"] = arg["inDir"];
     return(localBrowseRequest(arg, request));
   }
   
   getHomeDir(request) Path {
      String accountName = request.getSession("account.name");
      Path homeDir = Path.apNew("Home/" + accountName);
      return(homeDir);
    }
    
   
   getBaseLink(request) String {
     return("<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += Encode:Hex.encode(getHomeDir(request).toString()) += "');return false;\">HOME</a></td></tr>");
   
   }
   
   jscallForPath(Path p) {
    String psl = p.toString().lower();
    if (psl.ends(".jpg")) {
      String jscall = " onclick=\"localBrowseRequest('" += Encode:Hex.encode(p.toString()) += "');return false;\"";
    } elseIf (psl.ends(".gif")) {
      jscall = " onclick=\"localBrowseRequest('" += Encode:Hex.encode(p.toString()) += "');return false;\"";
    } elseIf (psl.ends(".html") || psl.ends(".htm") || psl.ends(".mhtml")) {
      jscall = " onclick = \"return true;\"";
    } else {
      jscall = "";
    }
    return(jscall);
   }
   
   localBrowseRequest(Map arg, request) Map {
     log.log("in local browse req");
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
      Encode:Hex hex = Encode:Hex.new();
      Encode:Url urle = Encode:Url.new();
      Encode:Html htmle = Encode:Html.new();
      Map ret = Map.new();
      String path = arg["path"];
      Account a = request.context.get("account");
      Bool adminLinks = false;
      if (a.perms.has("admin")) {
        adminLinks = true;
      }
      if (TS.isEmpty(path)) {
        dirFile = getHomeDir(request).file;
        if (dirFile.exists!) {
          dirFile.makeDirs();
        }
      } else {
        File dirFile = File.apNew(hex.decode(path));
      }
      String dirListHtml = String.new();
      dirListHtml += "<input type=\"hidden\" id=\"browsingDirId\" value=\"" += hex.encode(dirFile.path.toString()) += "\"/>";
      if (dirFile.exists && checkReadPath(dirFile.path, arg, request)) {
        dirListHtml += "<p>Listing for " += htmle.encode(dirFile.path.toString()) += "</p>";
        dirListHtml += "<table>";
        if (adminLinks) {
          if (System:CurrentPlatform.name == "mswin") {
            dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode("\\") += "');return false;\">ROOT</a></td></tr>";
            String homep = System:Environment.getVariable("USERPROFILE");
          } else {
            dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode("/") += "');return false;\">ROOT</a></td></tr>";
            homep = System:Environment.getVariable("HOME");
          }
          dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(".") += "');return false;\">APPDIR</a></td></tr>";
          dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(homep) += "');return false;\">OSHOME</a></td></tr>";
        }
        dirListHtml += getBaseLink(request); 
        dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(dirFile.path.toString()) += "');return false;\">.  (REFRESH)</a></td></tr>";
        IO:File:Path parent = dirFile.path.parent;
        if (def(parent) && TS.notEmpty(parent.toString())) {
        dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(parent.toString()) += "');return false;\">.. (UP)</a></td></tr>";
        }
        for (dyn kv in app.configManager.getMap("fileManager.sharedDirs.")) {
          dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(kv.value) += "');return false;\">" += kv.key.substring(23, kv.key.size) += "</a></td></tr>";
        }
        for (kv in app.configManager.getMap("fileManager.accountDirs." + accountName + ".")) {
          dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(kv.value) += "');return false;\">" += kv.key.substring(25 + accountName.size, kv.key.size) += "</a></td></tr>";
        }
        if (dirFile.isDir) {
          auto dit = dirFile.iterator;
          dit.open();
          List olist = List.new();
          Map omap = Map.new();
          while (dit.hasNext) {
            File entry = dit.next;
            Path p = entry.path;
            olist += p.steps.last;
            omap.put(p.steps.last, entry);
          }
          olist = olist.sort();
          for (String ole in olist) {
            entry = omap.get(ole);
            p = entry.path;
            if (entry.isDirectory) {
              dirListHtml += "<tr>";
              dirListHtml += "<td>DIR</td><td><a href=" + TS.quote + "#" + TS.quote + " onclick=\"localBrowseRequest('"
          += hex.encode(p.toString()) += "');return false;\">" += htmle.encode(p.name) += "</a></td>";
              dirListHtml += "<td><input type=\"checkbox\" id=\"FCB"
              += hex.encode(p.toString()) += "\" onclick=\"fileChecked(this);\"\"></td>";
              dirListHtml += "</tr>";   
            } else {
              String jscall = jscallForPath(p);
              String psl = p.toString().lower();
              if (psl.ends(".html") || psl.ends(".htm") || psl.ends(".mhtml") || psl.ends(".pdf")) {
                String targ = " target=\"_blank\"";
              } else {
                targ = "";
              }
              dirListHtml += "<tr>";
              dirListHtml += "<td>FILE</td><td><a href=" += TS.quote += "../../" += urle.encode(p.toString()) += "?pageToken=" += request.getSession("pageToken") += TS.quote + jscall + targ + ">" += htmle.encode(p.name) += "</a></td><td>" += entry.size += "</td>";
              dirListHtml += "<td><input type=\"checkbox\" id=\"FCB"
              += hex.encode(p.toString()) += "\" onclick=\"fileChecked(this);\"\"></td>";
              dirListHtml += "</tr>";
            }
          }
          dit.close();
        } elseIf (dirFile.path.toString().ends(".note")) {
          
        } elseIf (dirFile.path.toString().lower().ends(".jpg") || dirFile.path.toString().lower().ends(".gif")) {
          if (dirFile.path.toString().lower().ends(".gif")) {
            Bool isGif = true;
          } else {
            isGif = false;
          }
          //get one before and after for slideshow
          dit = dirFile.path.parent.file.iterator;
          dit.open();
          olist = List.new();
          omap = Map.new();
          while (dit.hasNext) {
            entry = dit.next;
            p = entry.path;
            olist += p.steps.last;
            omap.put(p.steps.last, entry);
          }
          dit.close();
          olist = olist.sort();
          auto pitcs = dirFile.path.toString();
          Bool found = false;
          for (ole in olist) {
            entry = omap.get(ole);
            auto ps = entry.path.toString();
            if (ps == pitcs) {
              found = true;
            } else {
              if (ps.lower().ends(".jpg") || ps.lower().ends(".gif")) {
                if (found) {
                  if (undef(safter)) {
                    auto safter = entry.path;
                  }
                } else {
                  auto sbefore = entry.path;
                }
              }
            }
          }
          
          if (isGif) {
            String cb = "&cb=" + System:Random.getString(8);
          } else {
            cb = "";
          }
          Map res = Map.new();
          res["action"] = "updateImageResponse";
          res["isGif"] = isGif;
          res["imghtm"] = "<img id=\"camImage\" style=\"object-fit: cover; max-width: 100%;\" src=\"../../" + dirFile.path.toStringWithSeparator("/") + "?pageToken=" + request.getSession("pageToken") + cb + "\" >";
          
          if (def(sbefore)) {
            log.log("Got before pic " + sbefore);
            p = sbefore;
            jscall = " onclick=\"localBrowseRequest('" += hex.encode(p.toString()) += "');return false;\"";
            auto plink = "<a id='picBefore' href=" += TS.quote += "../../" += urle.encode(p.toString()) += "?pageToken=" += request.getSession("pageToken") += TS.quote + jscall + " style=\"font-size:3em;\">\<</a>";
            res["plink"] = plink;
            
            jscall = " onclick=\"callUI('keepGoingPY');localBrowseRequest('" += hex.encode(p.toString()) += "');return false;\"";
            plink = "<a href=" += TS.quote += "../../" += urle.encode(p.toString()) += "?pageToken=" += request.getSession("pageToken") += TS.quote + jscall + " style=\"font-size:3em;\">\<\<</a>";
            res["plinkgo"] = plink;
            
            res["plbefore"] = "../../" + sbefore.toStringWithSeparator("/") + "?pageToken=" + request.getSession("pageToken");
          
          }
          
          if (def(safter)) {
            log.log("Got after pic " + safter);
            p = safter;
            jscall = " onclick=\"localBrowseRequest('" += hex.encode(p.toString()) += "');return false;\"";
            auto nlink = "<a id='picAfter' href=" += TS.quote += "../../" += urle.encode(p.toString()) += "?pageToken=" += request.getSession("pageToken") += TS.quote + jscall + " style=\"font-size:3em;\">\></a>";
            res["nlink"] = nlink;
            
            jscall = " onclick=\"callUI('keepGoingNY');localBrowseRequest('" += hex.encode(p.toString()) += "');return false;\"";
            nlink = "<a href=" += TS.quote += "../../" += urle.encode(p.toString()) += "?pageToken=" += request.getSession("pageToken") += TS.quote + jscall + " style=\"font-size:3em;\">\>\></a>";
            res["nlinkgo"] = nlink;
            
            res["plafter"] = "../../" + safter.toStringWithSeparator("/") + "?pageToken=" + request.getSession("pageToken");
            
          }
          
          if (def(sbefore) || def(safter)) {
            log.log("got a pic for slink");
            nlink = "<a href='#' id='slinkhr' onclick=\"callUI('stopGoing');return false;\" style=\"font-size:3em;\">||</a>";
            res["slink"] = nlink;
            
          }
          return(res);
        }
        dirListHtml += "</table>";
      }
      ret.put("action", "localBrowseResponse");
      ret.put("dirListHtml", dirListHtml);
      return(ret);
    }
    
    showSharesRequest(request) {
        unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      String dirListHtml = String.new();
      for (dyn kv in app.configManager.getMap("fileManager.sharedDirs.")) {
        dirListHtml += "<p>" += kv.value += " shared to ALL as " += kv.key.substring(23, kv.key.size) += "</p>";  
      }
      for (kv in app.configManager.getMap("fileManager.accountDirs.")) {
        auto steps = kv.key.split(".");
        dirListHtml += "<p>" += kv.value += " shared with " += steps[2] += " as " += steps[3] += "</p>";
      }
      return(CallBackUI.setElementsInnerHTMLResponse(Maps.from("sharesDiv", dirListHtml)));
    }
    
    unshareSelectedRequest(Map args, request) {
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      if (TS.isEmpty(args["path"])) {
        throw(Alert.new("Must select path to unshare"));
      }
      String path = Encode:Hex.decode(args["path"]);
      log.log("path for unshare " + path);
      Set delKeys = Set.new();
      for (dyn kv in app.configManager.getMap("fileManager.sharedDirs.")) {
        if (kv.value == path) {
          delKeys += kv.key;
        }  
      }
      for (kv in app.configManager.getMap("fileManager.accountDirs.")) {
        if (kv.value == path) {
          delKeys += kv.key;
        } 
      }
      for (dyn delKey in delKeys) {
        app.configManager.delete(delKey);
      }
      return(showSharesRequest(request));
    }
    
    shareAllSelectedRequest(Map args, request) {
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      if (TS.isEmpty(args["path"]) || TS.isEmpty(args["shareName"])) {
        throw(Alert.new("Must select path to share and provide name for share"));
      }
      String path = Encode:Hex.decode(args["path"]);
      log.log("path for all share " + path);
      app.configManager.put("fileManager.sharedDirs." + args["shareName"], path);
      return(showSharesRequest(request));
    }
    
    shareOneSelectedRequest(Map args, request) {
      unless (def(request.context.get("account")) && request.context.get("account").isAdmin) {
        throw(Alert.new("Must be administrator"));
      }
      if (TS.isEmpty(args["path"]) || TS.isEmpty(args["shareName"]) || TS.isEmpty(args["shareAccount"])) {
        throw(Alert.new("Must select path to share and provide name for share and account login to share with"));
      }
      String path = Encode:Hex.decode(args["path"]);
      log.log("path for one share " + path + " account " + args["shareAccount"]);
      app.configManager.put("fileManager.accountDirs." + args["shareAccount"] + "." + args["shareName"], path);
      return(showSharesRequest(request));
    }
    
}

use class App:ConfigPlugin(App:AjaxPlugin) {

     new() self {
       fields {
          dyn app;
          String name = "Conf";
          String kvdb = "CONFIG";
        }
        super.new();
        log = IO:Logs.get(self);
     }
     
     handleCmd(Parameters params) Bool {
      String mode = params.getFirst("confCmd");
      if (TS.isEmpty(mode)) {
        return(false);
      }
      String kvdbov = params.getFirst("kvdb");
      if (TS.notEmpty(kvdbov)) {
        kvdb = kvdbov;
      }
      app.kvdbs.get(kvdb);//warmup
      if (mode == "showConfig") {
        if (TS.notEmpty(params.getFirst("prefix"))) {
          for (kv in app.kvdbs.get(kvdb).getMap(params.getFirst("prefix"))) {
            log.output("Config name " + kv.key + " value " + kv.value);
          }
        } else {
          for (dyn kv in app.kvdbs.get(kvdb).getMap()) {
            log.output("Config name " + kv.key + " value " + kv.value);
          }
        }
      }
      if (mode == "putConfig") {
        String key = params.getFirst("key");
        String value = params.getFirst("value");
        //log.log("Creating config " + key + " " + value);
        app.kvdbs.get(kvdb).put(key, value);
      }
      if (mode == "deleteConfig") {
        key = params.getFirst("key");
        //log.log("Deleting config " + key);
        app.kvdbs.get(kvdb).delete(key);
      }
      if (mode == "getConfig") {
        key = params.getFirst("key");
        //log.log("Getting config " + key);
        String getconf = app.kvdbs.get(kvdb).get(key);
        if (def(getconf)) {
          log.log(getconf);
        } else {
          log.log("conf not found");
        }
      }
      if (mode == "clear") {
        log.log("clearing kvdb");
        app.kvdbs.get(kvdb).clear();
      }
      if (mode == "saveLocalUrl") {
        log.log("saveLocalUrl");
        
        String intPort = app.webPort;
        
        String defadd = Net:Gateway.defaultAddress;
        Net:Interface ni = Net:Interface.new();
        defadd = ni.interfaceForNetwork(defadd).address;
        
        String iurl = app.webProto + "://" + defadd + ":" += intPort;
        File.apNew(params.getFirst("urlFile")).writer.open().write(iurl).close();
      }
      return(true);
    }
    
     changeDeviceNameRequest(String deviceName, request) {
     log.log("changing name");
      if ((def(request.context.get("account")) && request.context.get("account").isAdmin) && TS.notEmpty(name)) {
        app.plugin.deviceName = deviceName;
      }
      app.kvdbs.get(kvdb).put("deviceNameSetOnce", "true");
      //return(CallBackUI.setElementsDisplaysResponse(Maps.from("deviceNameDiv", "none")));
      //return(CallBackUI.reloadResponse());
      return(CallBackUI.reloadResponse());
      }
   
   showConfigRequest(Map arg, request) Map {
     Set noshow = Sets.from("imap.pass", "imap.user");
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
       String conf = String.new();
       Map ecm = app.kvdbs.get(kvdb).getMap();
       if (ecm.isEmpty!) {
         conf += "<table>";
         for (dyn kv in ecm) {
           unless(kv.value.has("\"") || noshow.has(kv.key)) {
              String ckey = "configKey" + kv.key;
              conf += "<tr><td>" + kv.key + "</td><td><input type=\"text\" id=\"" + ckey + "\" value=\"" + kv.value + "\"></td><td><a href=\"#\" onclick=\"callUI('deleteConfig', '" + kv.key + "');return false;\">Delete</a></td><td><a href=\"#\" onclick=\"updateConfig('" + kv.key + "', '" + ckey + "');return false;\">Save</a></td></tr>";
            }
         }
      }
      conf += "<tr><td>Add New:&nbsp;<input type=\"text\" id=\"addConfigKeyId\" value=\"\"></td><td><a href=\"#\" onclick=\"callUI('addConfig');return false;\">+</a><input type=\"hidden\" id=\"addConfigValId\" value=\"\"></td></tr>";
      
      conf += "<tr><td><a href=\"#\" onclick=\"callApp('backupConfigRequest');return false;\">Download Configuration Backup</a></td></tr>";
      
      conf += "</table>";
       Map res = Map.new();
      res["action"] = "showConfigResponse";
      res["configs"] = conf;
      return(res);
    }
    return(null);
   }
   
   backupConfig() String {
     Map ecm = app.kvdbs.get(kvdb).getMap();
     if (ecm.isEmpty) {
       ecm = Map.new();
     }
     return(Json:Marshaller.marshall(ecm));
   }
   
   backupConfig(String path) {
     Path dirPath = Path.apNew(path);
     if (dirPath.parent.file.exists!) {
      dirPath.parent.file.makeDirs();
     }
     dirPath.file.contents = backupConfig();
   }
   
   backupConfigRequest(request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
       Map res = Map.new();
       res["action"] = "backupConfigResponse";
       res["configJson"] = backupConfig();
       //log.log("ret configJson " + res["configJson"]);
       return(res);
     }
     return(null);
   }
   
   updateConfigRequest(Map arg, request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      //log.log("update for " + arg["configKey"] + " value " + arg["configValue"]);
      app.kvdbs.get(kvdb).put(arg["configKey"], arg["configValue"]);
      return(showConfigRequest(arg, request));
      }
      return(null);
   }
   
   deleteConfigRequest(Map arg, request) Map {
     if (def(request.context.get("account")) && request.context.get("account").isAdmin) {
      //log.log("delete for " + arg["configKey"]);
      app.kvdbs.get(kvdb).delete(arg["configKey"]);
      return(showConfigRequest(arg, request));
      }
      return(null);
   }
   
  start() {
    log.log("initting managers conf");
    app.kvdbs.get(kvdb);
  }
    
}

use class App:LocalWebApp(WebApp) {

  new() self {
        fields {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
        }
        super.new();
    }

    main() {
    
      start();
    
      webr = WeBr.new();
      webr.webHandler = self;
      //webr.height = 450;
      //webr.width = 320;
      
      webr.height = 560;
      webr.width = 320;
      
      String mypwd = System:Environment.getVariable("MYPWD");
      ifEmit(platDroid) {
        mypwd = "android_asset";
      }
      ifEmit(ccIsIos) {
        mypwd = "";
      }
      ifEmit(apwk) {
        mypwd = "";
      }
      
      webr.location = "file:///" + mypwd + self.plugin.homePage;
      
      ifEmit(ccIsIos) {
        String wfl = self.plugin.homePage;
        wfl = wfl.substring(1, wfl.size);
        webr.location = wfl;
      }
      
      ifEmit(apwk) {
        String wfl = self.plugin.homePage;
        wfl = wfl.substring(1, wfl.size);
        webr.location = wfl;
      }
      
      webr.setup();
   }

   initWeb() {

   }

}

class App:AppStart {

  new(Parameters _params) self {
    fields {
      IO:Log log = IO:Logs.get(self);
      Parameters params = _params;
    }
  }
  
  invokePlugin(List args) {
    String pln = args.get(0);
    args.delete(0);
    String plmtd = args.get(0);
    args.delete(0);
    Parameters params = Parameters.new(args);
    dyn app = setup(params);
    dyn plugin = app.pluginsByName.get(pln);
    log.log("params invokePlugin " + params.toJson());
    if (params.has("plma")) {
      iar = params.params.get("plma").toList();
    } else {
      List iar = List.new();
    }
    plugin.invoke(plmtd, iar);
  }
  
    main() {
      try {
        String appArgs = System:Environment.getVariable("BEAPPARGS");
        if (TS.notEmpty(appArgs)) {
          params = Parameters.new(appArgs.split(" "));
        } else {
          Parameters params = Parameters.new(System:Process.new().args);
        }
        ifEmit(platDroid) {
          IO:Logs.turnOnAll();
        }
        ifEmit(ccIsIos) {
          IO:Logs.turnOnAll();
        }
        start(params);
      } catch (dyn e) {
        log.elog("fail in appstart main", e);
      }
    }
  
  start(Parameters params) {
    dyn app = setup(params);
    app.main();
  }
  
  start() {
    dyn app = setup();
    app.main();
  }
    
  setupPlugins(WebApp app) {
    auto pluginClasses = params.get("plugin");
    List plugins = List.new();
    for (String pluginClass in pluginClasses) {
      dyn plugin = System:Objects.createInstance(pluginClass);
      plugins += plugin;
    }
    app.plugins = plugins;
  }
  
  setupPlugin(WebApp app) {
    String pln = params.getFirst("appPlugin");
    if (def(pln)) {
      app.plugin = app.pluginsByName[pln];
    } else {
      throw(Exception.new("No app plugin defined"));
    }
  }
  
  setup(Parameters params) {
    self.new(params);
    return(setup());
  }
  
  setup() {
    //ifEmit(apwk) {
      IO:Logs.turnOnAll();
    //}
    log.log("setup app");
    //log.log("params setup " + params.toJson());
    Set bfiles = Set.new();
    if (def(params["runParams"])) {
      for (String istr in params["runParams"]) {
         if (bfiles.has(istr)!) {
            log.log("loading " + istr);
            bfiles.put(istr);
            params.addFile(File.new(istr));
          }
      }
    }
    //log.log("params setup postloads " + params.toJson());
    if (def(params["logSink"])) {
      IO:Log:Sink ls = IO:Log:Sink.new();
      if (def(params["logSinkPrefix"])) {
        ls.prefix = params.getFirst("logSinkPrefix");
      }
      if (def(params["logSinkDir"])) {
        ls.dir = Path.apNew(params.getFirst("logSinkDir"));
        if (ls.dir.file.exists!) {
          ls.dir.file.makeDirs();
        }
      }
      IO:Logs.setAllSinks(ls);
    }
    auto appTypes = Sets.fromList(params.get("appType").toList());
    if (appTypes.has("cmd")) {
      dyn cuiapp = WebApp.new();
      cuiapp.params = params;
      setupPlugins(cuiapp);
      setupPlugin(cuiapp);
      return(cuiapp);
    } elseIf (appTypes.has("browser")) {
      dyn luiapp = System:Objects.createInstance("App:LocalWebApp");
      luiapp.params = params;
      setupPlugins(luiapp);
      setupPlugin(luiapp);
      return(luiapp);
    } elseIf (appTypes.has("server")) {
      dyn wuiapp = System:Objects.createInstance("App:RemoteWebApp");
      wuiapp.params = params;
      setupPlugins(wuiapp);
      setupPlugin(wuiapp);
      return(wuiapp);
    }
    log.log("no appType");
    return(null);
  }
}

use App:WebApp;
class WebApp {

  new() self {
    fields {
      IO:Log log = IO:Logs.get(self);
      Lock lock = Lock.new();
      String certificateThumbprint;
      Map kvDbs = Map.new();
      Parameters params;
      String sessionIdKey = "webApp.sessionId";
    }
  }
  
  webPortGet() String {
    String cval = params.getFirst(self.configPrefix + "web.port");
    if (TS.isEmpty(cval)) {
      cval = self.configManager.get(self.configPrefix + "web.port");
    }
    if (TS.notEmpty(cval)) { return(cval); }
    return(self.appPort);
  }
  
  webPortSet(String _webPort) this {
    self.configManager.put(self.configPrefix + "web.port", _webPort);
  }
  
  webProtoGet() String {
    String cval = params.getFirst(self.configPrefix + "web.proto");
    if (TS.isEmpty(cval)) {
      cval = self.configManager.get(self.configPrefix + "web.proto");
    }
    if (TS.notEmpty(cval)) { return(cval); }
    if (self.appSsl) {
      return("https");
    }
    return("http");
  }
  
  webProtoSet(String _webProto) this {
    self.configManager.put(self.configPrefix + "web.proto", _webProto);
  }
  
  appNameGet() String {
    fields {
      String appName;
    }
    if (undef(appName)) {
      if (def(params)) {
        String an = params.getFirst("appName");
      }
      if (undef(an)) {
        an = "";
      }
      appName = an;
    }
    return(appName);
  }
  
  configPrefixGet() String {
    String an = self.appName;
    if (TS.notEmpty(an)) {
      String cpx = "webApp." + an + ".";
      //log.log("configPrefix " + cpx);
      return(cpx);
    }
    return(an);
  }
  
   appSslGet() Bool {
      fields {
        Bool appSsl;
      }
      if (undef(appSsl)) {
        appSsls = params.getFirst(self.configPrefix + "app.ssl");
        if (TS.isEmpty(appSsls)) {
          String appSsls = self.configManager.get(self.configPrefix + "app.ssl");
          if (TS.isEmpty(appSsls)) {
            appSsls = "false";
            ifEmit(cs) {
              appSsls = "false";
            }
            self.configManager.put(self.configPrefix + "app.ssl", appSsls);
          }
        }
        appSsl = Logic:Bools.fromString(appSsls);
      }
      return(appSsl);
    }
    
    appSslSet(Bool _appSsl) this {
      appSsl = _appSsl;
      self.configManager.put(self.configPrefix + "app.ssl", appSsl.toString());
    }

  pluginsSet(_plugins) {
      fields {
        List plugins = _plugins;
        if (undef(plugin)) {
          dyn plugin = plugins.first;
        }
        Map pluginsByName = Map.new();
      }
      
      for (dyn pl in plugins) {
        pl.app = self;
        if (pl.can("nameGet", 0)) {
          pluginsByName.put(pl.name, pl);
        }
      }
      
  }
  
  kvdbsGet() KvDbs {
    fields {
      KvDbs kvdbs;
    }
    if (undef(kvdbs)) {
      kvdbs = KvDbs.new(params, self.paths.dataPath.addStep("APPDB"));
    }
    return(kvdbs);
  }
  
  start() {
    self.configManagerGet();
    self.sessionManagerGet();
    for (dyn pl in plugins) {
      if (pl.can("start", 0)) {
        pl.start();
      }
    }
  }
  
  stop() {
    for (dyn pl in plugins) {
      if (pl.can("stop", 0)) {
        pl.stop();
      }
    }
    self.kvdbs.close();
  }
  
  appPortGet() String {
      fields {
        String intPort;
      }
      if (TS.isEmpty(intPort)) {
        if (def(params) && def(params.getFirst(self.configPrefix + "app.port"))) {
          return(params.getFirst(self.configPrefix + "app.port"));
        }
        intPort = self.configManager.get(self.configPrefix + "app.port");
        if (TS.isEmpty(intPort)) {
          Int intPorti = System:Random.getIntMax(30000);
          intPorti += 3000;
          intPort = intPorti.toString();
          self.configManager.put(self.configPrefix + "app.port", intPort);
        }
      }
      return(intPort);
    }
    
  appPortSet(String _intPort) this {
    intPort = _intPort;
    self.configManager.put(self.configPrefix + "app.port", intPort);
    }
    
  appBindAddressGet() String {
      fields {
        String appBindAddress;
      }
      if (TS.isEmpty(appBindAddress)) {
        if (def(params) && def(params.getFirst(self.configPrefix + "app.bindAddress"))) {
          return(params.getFirst(self.configPrefix + "app.bindAddress"));
        }
        appBindAddress = self.configManager.get(self.configPrefix + "app.bindAddress");
      }
      return(appBindAddress);
    }
  
  appBindAddressSet(String _appBindAddress) this {
      appBindAddress = _appBindAddress;
      self.configManager.put(self.configPrefix + "app.bindAddress", appBindAddress);
    }
  
  
  pathsGet() App:Paths {
    fields {
      App:Paths paths;
    }
    if (undef(paths)) {
      paths = App:Paths.new(self);
    }
    return(paths);
  }
  
  configManagerGet() KvDb {
    return(self.kvdbs.get("CONFIG"));
  }
  
  sessionManagerGet() Web:SessionManager {
    fields {
      Web:SessionManager sessionManager;
      String sessionId;
    }
    if (undef(sessionId)) {
      sessionId = self.configManager.get(sessionIdKey);
      if (TS.isEmpty(sessionId)) {
        sessionId = System:Random.getString(16);
        self.configManager.put(sessionIdKey, sessionId);
      }
      //log.log("sessionId " + sessionId);
    }
    if (undef(sessionManager)) {
      sessionManager = Web:SessionManager.new(self.kvdbs, "GsSess" + sessionId);
    }
    //("got sessionmanager").print();
    return(sessionManager);
  }
    
    handleWeb(request) this {
     for (dyn pl in plugins) {
       request.continueHandling = false;
       pl.handleWeb(request);
       unless (request.continueHandling) {
        break;
       }
     }
    }
    
    handleCmd() this {
     for (dyn pl in plugins) {
       if (pl.can("handleCmd", 1)) {
        if (pl.handleCmd(params)) {
          break;
        }
      }
     }
     stop();
    }
    
    main() this {
      handleCmd();
      String hcne = params.getFirst("handleCmdNoExit");
      unless (TS.notEmpty(hcne) && hcne == "true") {
        System:Process.exit(0);
      }
    }
    
    runAsync(String plugName, String plugMtd, List plmargs) {
      List appargs = params.initialArgs;
      List pnp = Lists.from(plugName, plugMtd);
      List pnaa = pnp + appargs;
      for (dyn plma in plmargs) {
        pnaa += "--plma";
        pnaa += plma;
      }
      List invargs = List.new();
      invargs[0] = pnaa;
      System:RunAsync.run("App:AppStart", "invokePlugin", invargs);
    }
    
}

use class System:RunAsync {

  new(String _klass, String _toInvoke, List _args) self {
    fields {
      IO:Log log = IO:Logs.get(self);
      String klass = _klass;
      String toInvoke = _toInvoke;
      List args = _args;
         //for app runasync
         //one arg is the startup args for params
         //one arg is the name of the plugin
         //one arg is the name of the method on the plugin
    }
  }
  
  prepAndPush() {
    Map margs = Maps.from("klass", klass, "toInvoke", toInvoke, "args", args);
    String jsargs = Encode:Hex.encode(Json:Marshaller.marshall(margs));
    String jspw = "runAsync:" + jsargs;
    emit(js) {
    """
    var jsres = prompt(bevl_jspw.bems_toJsString());
    //bevl_res = new be_$class/Text:String$().bems_new(jsres);
    """
    }
  }
  
  readAndRun(String jsargs) {
  
    Map margs = Json:Unmarshaller.unmarshall(Encode:Hex.decode(jsargs));
    klass = margs["klass"];
    toInvoke = margs["toInvoke"];
    args = margs["args"];
    main();
    
  }
  
  run(String klass, String toInvoke, List args) self {
    new(klass, toInvoke, args);
    ifNotEmit(apwk) {
      start();
    }
    ifEmit(apwk) {
      prepAndPush();
    }
  }
  
  start() self {
    fields {
      System:Thread myThread;
    }
    myThread = System:Thread.new(self);
    myThread.start();
  }
  
  main() {
    dyn e;
    try {
      dyn inst = System:Objects.createInstance(klass);
      inst.invoke(toInvoke, args);
    } catch (e) {
      log.error("Caught exception running tasks " + e);
    }
  }

}

use class App:Background {

  new() self {
    fields {
      IO:Log log = IO:Logs.get(self);
      Interval startDelay = Interval.new(10, 0);
      Interval repeatDelay = Interval.new(10, 0);
      Interval minimumDelay = Interval.new(5, 0);
      Interval lastRepeat = Interval.new(0, 0);
      System:Invocation toInvoke;
      dyn lastError = null;
      Bool lastWasError = false;
    }
  }
  
  runMyTasks() {
    try {
      Interval now = Interval.now();
      if (now - lastRepeat >= minimumDelay) {
        lastWasError = false;
        lastRepeat = now;
        toInvoke.invoke();
      }
    } catch (dyn e) {
      lastWasError = true;
      lastError = e;
      try {
        log.error("exception in runMyTasks");
        if (def(e)) {
          log.error("runMyTasks exception was " + e);
        }
      } catch (dyn ee) { }
    }
  }
  
  main() {
    dyn e;
    Time:Sleep.sleep(startDelay);
    while (true) {
      try {
        runMyTasks();
      } catch (e) {
        log.error("Caught exception running tasks " + e);
      }
      try {          
        Time:Sleep.sleep(repeatDelay);
      } catch (e) {
        log.error("Caught exception sleeping " + e);
      }
    }
  }
  
  start() self {
    fields {
      System:Thread myThread;
    }
    myThread = System:Thread.new(self);
    myThread.start();
  }

}

class CallBackUI {

  default() self { }

  forwardCall(String name, List args) {
      Map retc = Map.new();
      retc["action"] = name;
      retc["args"] = args;
      return(retc);
   }

}

class App:AjaxPlugin {

   new() self {
    fields {
      dyn plugin = self;
      IO:Log log = IO:Logs.get(self);
    }
   }
   
   new(_plugin) self {
     plugin = _plugin;
     log = IO:Logs.get(self);
   } 
   
   prepArgs(request) {
     Map arg = request.context["arg"];
     List args = request.context["args"];
     if (undef(arg) || undef(args)) {
       String rmtd = request.inputMethod;
       if (TS.isEmpty(rmtd) || rmtd != "PUT") {
         arg = request.scriptArg;
         if (def(arg)) {
           if (arg.has("args")) {
              //is "standard call"
              args = arg["args"];
              args += request;
              //log.log("call type a " + aname + args.length);
            } else {
              //deprecate this
              args = List.new(2);
              args[0] = arg;
              args[1] = request;
              //log.log("call type b");
            }
          }
          request.context["arg"] = arg;
          request.context["args"] = args;
        }
     }
   } 
   
   handleWeb(request) this {
     try {
       prepArgs(request);
       Map arg = request.context["arg"];
       List args = request.context["args"];
       if (def(arg) && def(args)) {
         String aname = arg.get("action");
          if (plugin.can(aname, args.length) && aname.ends("Request")) {
            dyn res = plugin.invoke(aname, args);
            request.scriptReturn = res;
          } else {
            request.continueHandling = true;
          }
        } else {
          request.continueHandling = true;
        }
      } catch (dyn e) {
        log.error("Caught exception handling request");
        if (undef(e)) { log.error("undefined exception") } else { log.error(e.toString()); }
        //if (TS.isEmpty(aname)) { aname = "Unknown Action"; }
        if (System:Classes.sameClass(e, Alert.new())) {
          arg = CallBackUI.informResponse(e.description);
        } else {
          /*String xtrainfo = aname;
          if (def(e)) {
            xtrainfo += e.toString();
          }
          arg = CallBackUI.informResponse(xtrainfo + " Sorry, unable to handle request");*/
          arg = CallBackUI.informResponse("Sorry, unable to handle request");
          //arg = CallBackUI.reloadResponse();
        }
        request.scriptReturn = arg;
      }
    }
}

use System:Thread:Lock;
use System:Thread:ContainerLocker as CLocker;
use System:Command as Com;
use Time:Sleep;
use System:Thread:ObjectLocker as OLocker;
use Db:HSQLDb:Database as HsDb;
use Db:Firebird:Database as FbDb;

use App:CallBackUI;
