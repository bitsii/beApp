// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use Text:String;
use Logic:Bool;
use Math:Int;
use System:Exception;
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
use Test:Assertions as Assert;
use Db:Relational:Database as DbDb;
use Db:Relational:Statement as DbSt;
use Db:Derby:Database as Derby;
use Db:HSQLDb:Database as HsDb;
use System:Thread:Lock;
use System:Thread:ContainerLocker as CLocker;

use App:Alert;

use class Dz:Lui(Ui) {

  new() self {
        properties {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
        }
        super.new();
        bg.startBackground();
    }

    main() {
      webr = WeBr.new();
      webr.webHandler = self;
      webr.height = 450;
      webr.width = 320;
      
      String mypwd = System:Environment.getVariable("MYPWD");
      webr.location = "file:///" + mypwd + "/App/Dz/Dz.html";
      
      webr.setup();
   }

   initWeb() {

   }

   handleWeb(request) {
     
     Map arg = request.scriptArg;
     return(super.handleWeb(request, arg));
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

emit(jv) {
"""
import java.security.*;
import javax.crypto.*;
import javax.crypto.spec.*;
import java.io.*;
import java.sql.*;
import org.bouncycastle.x509.*;
import java.math.BigInteger;
import java.security.cert.X509Certificate;
import org.bouncycastle.jce.X509Principal;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
"""
}
use class Dz:Wui(Ui) {

  emit(jv) {
  """
  static { Security.addProvider(new BouncyCastleProvider());  }
  """
  }

  new() self {
        properties {
        }
        super.new();
        bg.startBackground();
    }
    
    startWeb() {
      var e;
      String ports = self.internalPort;
      Int port = Int.new(ports);
      String cerPath = assureCert(port);
      //portL.o = port;
      
      Web:Server vw = Web:Server.new(self.sessionManager);
      
      //vwL.o = vw;
      vw.port = port;
      vw.ssl = true;
      vw.sslPath = cerPath;
      vw.app = self;
      vw.gzipOutput = true;
      vars {
        System:Thread myThread = System:Thread.new(vw);
      }
      log.log(lvl, "Starting Web");
      myThread.start();
    }
    
    
  assureCert(Int port) String {
    ifEmit(jv) {
      return(assureCertJv(port));
    }
  }
  
  handleStartWeb() {
    log.log(lvl, "In handleStartWeb");
  }
  
  assureCertJv(Int port) String {
    Path cerPath = Path.apNew("Data/Dz/cert");
    String cerPathS = cerPath.toString();
    log.log(lvl, "cerPath " + cerPathS);
    if (cerPath.file.exists) {
      log.log(lvl, "cer exist");
      return(cerPathS);
    } else {
      log.log(lvl, "cer not exist");
    }
    log.log(lvl, "Start gencert");
    emit(jv) {
    """ 
    String domainName = "test";
    KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
    keyPairGenerator.initialize(1024);
    KeyPair KPair = keyPairGenerator.generateKeyPair();
    X509V3CertificateGenerator v3CertGen = new X509V3CertificateGenerator();
    v3CertGen.setSerialNumber(BigInteger.valueOf(new SecureRandom().nextInt(Integer.MAX_VALUE)));
        v3CertGen.setIssuerDN(new X509Principal("CN=" + domainName + ", OU=None, O=None L=None, C=None"));
        v3CertGen.setNotBefore(new Date(System.currentTimeMillis() - 1000L * 60 * 60 * 24 * 30));
        v3CertGen.setNotAfter(new Date(System.currentTimeMillis() + (1000L * 60 * 60 * 24 * 365*10)));
        v3CertGen.setSubjectDN(new X509Principal("CN=" + domainName + ", OU=None, O=None L=None, C=None"));
    v3CertGen.setPublicKey(KPair.getPublic());
    v3CertGen.setSignatureAlgorithm("MD5WithRSAEncryption"); 
    X509Certificate PKCertificate = v3CertGen.generateX509Certificate(KPair.getPrivate());
    
    KeyStore privateKS = KeyStore.getInstance("JKS");
    privateKS.load(null);
    privateKS.setKeyEntry("jetty", KPair.getPrivate(),
                   //new char[]{'e', 'n', 't', 'r', 'y', 'p', 'a', 's', 's'},
                   "kp".toCharArray(),
                   new java.security.cert.Certificate[]{PKCertificate});
    privateKS.store( new FileOutputStream(bevl_cerPathS.bems_toJvString()), "kp".toCharArray());

    """
    }
    log.log(lvl, "End gencert");
    return(cerPathS);
  }
  
    main() {
      Array args = System:Process.new().args;

      startWeb();
   }

   initWeb() {

   }
   
   checkWritePath(Path p, String accountName) Bool {
    var e;
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
      log.log(lvl, "Path " + p + " accountName " + accountName + " excepted in checkPath " + e);
    }
    //log.log(lvl, "checkPath isOk " + isOk);
    return(isOk);
   }
   
   checkReadPath(Path p, String accountName) Bool {
    var e;
    Bool isOk = false;
    if (undef(accountName)) { accountName = ""; }
    try {
      Path pa = p.file.absPath;
      Path adz = Path.apNew("App/Dz").file.absPath;
      if (TS.notEmpty(accountName)) {
        Path h = Path.apNew("Home/" + accountName).file.absPath;
      }
      String pas = pa.toString();
      if (pas.begins(adz.toString()) && (pas.ends(".html") || pas.ends(".js"))) {
        isOk = true;
      } elif (def(h) && pas.begins(h.toString())) {
        isOk = true;
      }
    } catch (e) {
      log.log(lvl, "Path " + p + " accountName " + accountName + " excepted in checkPath " + e);
    }
    //log.log(lvl, "checkPath isOk " + isOk);
    return(isOk);
   }

   handleWeb(request) {
     //log.log(lvl, "in hw");
     String accountName = request.getSession("account.name");
     String rmtd = request.inputMethod;
     //log.log(lvl, "rmtd is " + rmtd);
     if (TS.isEmpty(rmtd) || rmtd != "PUT") {
        Map arg = request.scriptArg;
     }
     if (TS.isEmpty(accountName)) {
       String ln = request.getParameter("accountName");
       String lp = request.getParameter("accountPass");
       if (TS.notEmpty(ln) && TS.notEmpty(lp)) {
          log.log(lvl, "doing svc login");
          Account a = self.accountManager.getAccount(ln);
          if (def(a)) {
            log.log(lvl, "Found account " + ln);
            if (a.checkPass(lp)) {
              log.log(lvl, "svc login ok");
              request.putSession("account.name", ln);
              accountName = ln;
            }
          }
        }
     }
     if (undef(arg)) {
       String uri = request.uri;
       log.log(lvl, "uri " + uri);
       File imgfile = File.apNew(uri.substring(1));
       if (TS.notEmpty(rmtd) && rmtd == "PUT") {
         if (checkWritePath(imgfile.path, accountName)) {
           log.log(lvl, "put for " + imgfile.path);
            String rwbuf1 = String.new(4096);
            String rwbuf2 = String.new(4096);
            String accum = String.new(8192);
            outw = imgfile.writer.open();
            inr = request.openInput();
            String firstLine = inr.readBufferLine();
            String firstChar = firstLine.substring(0,1);
            //log.log(lvl, "first char |" + firstChar + "|");
            String line = firstLine;
            firstLine = firstLine.substring(0, firstLine.size - 2);
            //log.log(lvl, "first line " + firstLine.size + " " + firstLine);
            while (def(line) && line != "\n" && line != "\r\n") {
              line = inr.readBufferLine();
            }
            Bool found = false;
            while (found! && inr.readIntoBuffer(rwbuf2) > 0) {
              pos = null;
              if (rwbuf1.has(firstChar) || rwbuf2.has(firstLine)) {
                accum.clear();
                accum += rwbuf1;
                accum += rwbuf2;
                Int pos = accum.find(firstLine);
              }
              if (def(pos)) {
                //log.log(lvl, "foundFirst");
                found = true;
                accum = accum.substring(0, pos);
                outw.write(rwbuf1);
              } else {
                outw.write(rwbuf1);
                String tb = rwbuf1;
                rwbuf1 = rwbuf2;
                rwbuf2 = tb;
                rwbuf2.clear();
              }
            }
            request.closeInputReader();
            outw.close();
            request.outputContent = "UPLOAD COMPLETE";
         }
       } elif (checkReadPath(imgfile.path, accountName)) {
         log.log(lvl, "imgfile " + imgfile.path);
         if (imgfile.exists) {
          String mtype;
          if (uri.ends(".html")) {
            mtype = "text/html";
          } elif (uri.ends(".jpg")) {
            mtype = "image/jpeg";
          } elif (uri.ends(".js")) {
            mtype = "text/javascript";
          } else {
            mtype = "application/octet-stream";
          }
          request.outputContentType = mtype;
          String rwbuf = String.new(4096);
          IO:Writer outw = request.openOutput();
          IO:Reader inr = imgfile.reader.open();
          while (inr.readIntoBuffer(rwbuf) > 0) {
            outw.write(rwbuf);
          }
          request.closeOutputWriter();
          inr.close();
         }
       }
      return(null);
     }
     return(super.handleWeb(request, arg));
   }
   
    exitRequest(Map arg, request) Map {
      exit();
      return(null);
    }

    exit() {
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
   properties {
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
 
 localInterfacesGet() Array {
   Array res;
   ifEmit(cs) {
     res = localInterfacesGetCs();
   }
   ifEmit(jv) {
     res = localInterfacesGetJv();
   }
   return(res);
 }
 
 localInterfacesGetJv() Array {
   
    Array interfaces = Array.new();
    
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
         bevl_address = new BEC_4_6_TextString(address);
      } else {
        continue;
      }
      if (description != null) {
         bevl_description = new BEC_4_6_TextString(description);
      } else {
        bevl_description = null;
      }
      if (name != null) {
         bevl_name = new BEC_4_6_TextString(name);
      } else {
        bevl_name = null;
      }
      if (macAddress != null) {
         bevl_macAddress = new BEC_4_6_TextString(macAddress);
      } else {
        bevl_macAddress = null;
      }
      bevl_status = new BEC_4_6_TextString(status);
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
 
 localInterfacesGetCs() Array {
   
    Array interfaces = Array.new();
    
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
                foreach (GatewayIPAddressInformation gaddress in addresses)
                {
                  if (gaddress.Address.AddressFamily.ToString().Equals("InterNetwork")) {
                    gatewayAddress = gaddress.Address.ToString();
                  }
                    
                }
            }*/
            string address = null;
            foreach(UnicastIPAddressInformation unicastIp in unicastIps)
            {
              if (unicastIp.Address.AddressFamily.ToString().Equals("InterNetwork")) {
                    address = unicastIp.Address.ToString();
                    if (description != null) {
                      bevl_description = new BEC_4_6_TextString(description);
                    } else {
                      bevl_description = null;
                    }
                    if (macAddress != null) {
                      bevl_macAddress = new BEC_4_6_TextString(macAddress);
                    } else {
                      bevl_macAddress = null;
                    }
                    if (name != null) {
                      bevl_name = new BEC_4_6_TextString(name);
                    } else {
                      bevl_name = null;
                    }
                    if (status != null) {
                      bevl_status = new BEC_4_6_TextString(status);
                    } else {
                      bevl_status = null;
                    }
                    if (address != null) {
                      bevl_address = new BEC_4_6_TextString(address);
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
    
    upInterfacesGet() Array {
      Array ups = Array.new();
      foreach (Interface i in self.localInterfaces) {
        if (TS.notEmpty(i.status) && i.status == "Up" && TS.notEmpty(i.address)) {
          ups += i;
        }
      }
      return(ups);
    }
    
    interfaceForNetwork(String netip) String {
      Int maxSoFar = 0;
      String bestMatch;
      foreach (Interface i in self.localInterfaces) {
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
    
    sortedUpInterfacesGet() Array {
      Array ups = self.upInterfaces;
      Array sups = Array.new();
      Map adif = Map.new();
      Array ads = Array.new();
      foreach (Interface i in ups) {
        adif.put(i.address, i);
        ads += i.address;
      }
      ads.sort();
      foreach (String ad in ads) {
        sups += adif.get(ad);
      }
      return(sups);
    }
    
    preferredInterfaceGet() Interface {
      Interface res;
      Int resScore = -1;
      foreach (Interface i in self.localInterfaces) {
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
    new(self.gatewayAddress);
  }
  
  new(String _netGw) self {
    vars {
      String netGw = _netGw;
      IO:Log log = IO:Log.new();
      Int lvl = log.debug;
    }
  }
  
  gatewayAddressGet() String {
    
    System:Command sc = System:Command.new("netstat -rn").open();
    String res = sc.output.readString();
    sc.close();
    
    Int fz = res.find("0.0.0.0"); //win
    if (def(fz)) {
      Int fz2 = res.find("0.0.0.0", fz + 1);
      if (def(fz2)) {
        fz = fz2;
      }
      fz += 7;
      res = res.substring(fz);
      Bool started = false;
      String accum = String.new();
      foreach (String s in res.biter) {
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
    vars {
      String deviceURL;
    }
    if (def(deviceURL)) {
      return(deviceURL);
    }
    var e;
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
        var bcast = true;
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
      bevl_received = new BEC_4_6_TextString(got);
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
      bevl_received = new BEC_4_6_TextString(got);
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
      var e;
      vars {
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
      String cu = self.controlURL;
      Web:Client client = Web:Client.new();
      client.url = cu;
      client.outputContentType = "text/xml";
      
      client.outputHeaders.put("SoapAction", "urn:schemas-upnp-org:service:WANIPConnection:1#GetExternalIPAddress");
      
      client.method = "POST";
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
      vars {
        String internalIP;
      }
      if (def(internalIP)) {
        return(internalIP);
      }
      Net:Interface ni = Net:Interface.new();
      internalIP = ni.interfaceForNetwork(netGw);
      return(internalIP);
    }
    
    forwardPort(Int duration, Int external, Int internal) Bool {
      return(forwardPort(duration, external, internal, self.internalIP));
    }
    
    forwardPort(Int duration, Int external, Int internal, String internalIP) Bool {
      var e;
      String cu = self.controlURL;
      Web:Client client = Web:Client.new();
      client.url = cu;
      client.outputContentType = "text/xml";
      
      client.outputHeaders.put("SoapAction", "urn:schemas-upnp-org:service:WANIPConnection:1#AddPortMapping");
      
      client.method = "POST";
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

use class Dz:DnsUpdate {

  new() self {
  
    vars {
      String duckDomain;
      String duckToken;
      var app;
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
      client.method = "GET";
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

use class Dz:UpnpUpdate {

  new() self {
  
    vars {
      var app;
      Int lvl;
      IO:Log log;
      Int lastPoll = 0;
      Int lastUpdate = 0;
      Int pollSecs = 1200;//10 mins
      Int forceUpdate = 43200;//12 hrs
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
    log.log(lvl, "In upnp doUpdate");
    unless (disable) {
      log.log(lvl, "upnp doing");
      
      Bool changed = false;
      
      Int currSec = Time:Interval.now().seconds;
      if (currSec - lastUpdate > forceUpdate) {
        lastUpdate = currSec;
        changed = true;
      }
    
      Upnp upnp = Upnp.new();
      upnp.lvl = lvl;
      String gwNow = upnp.netGw;
      String iaNow = upnp.internalIP;
      String eaNow = upnp.externalIP;
      
      if (TS.notEmpty(gwNow)) {
        if (TS.isEmpty(gw) || gwNow != gw) {
          changed = true;
          gw = gwNow;
          app.configManager.put("upnp.gw", gw);
        }
      }
      
      if (TS.notEmpty(iaNow)) {
        if (TS.isEmpty(intAddress) || iaNow != intAddress) {
          changed = true;
          intAddress = iaNow;
          app.configManager.put("upnp.intAddress", intAddress);
        }
      }
      
      if (TS.notEmpty(eaNow)) {
        if (TS.isEmpty(extAddress) || eaNow != extAddress) {
          changed = true;
          extAddress = eaNow;
          app.configManager.put("upnp.extAddress", extAddress);
        }
      }
      
      if (TS.isEmpty(intPort) || intPort != appIntPort) {
        changed = true;
        intPort = appIntPort;
        app.configManager.put("upnp.intPort", intPort);
      }
      
      if (TS.isEmpty(extPort) || extPort != appExtPort) {
        changed = true;
        extPort = appExtPort;
        app.configManager.put("upnp.extPort", extPort);
      }

      if (changed) {
        log.log(lvl, "Changed, forwarding");
        upnp.forwardPort(forceUpdate * 2, Int.new(extPort), Int.new(intPort));
      }
    }
  }
  
  init() {
    vars {
      String gw;
      String intAddress;
      String extAddress;
      String intPort;
      String extPort;
      String appIntPort;
      String appExtPort;
    }
    
    gw = app.configManager.get("upnp.gw");
    intAddress = app.configManager.get("upnp.intAddress");
    extAddress = app.configManager.get("upnp.extAddress");
    intPort = app.configManager.get("upnp.intPort");
    extPort = app.configManager.get("upnp.extPort");
    
    appIntPort = app.internalPort;
    appExtPort = app.externalPort;
    
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
    
    String forceUpdateS = app.configManager.get("upnp.forceUpdateSecs");
    if (TS.notEmpty(forceUpdateS)) {
      forceUpdate = Int.new(forceUpdateS);
    } else {
      app.configManager.put("upnp.forceUpdateSecs", forceUpdate.toString());
    }
  }

}

use class Dz:Background {

  new() self {
    vars {
      var app;
      Int lvl;
      IO:Log log;
      DnsUpdate du = DnsUpdate.new();
      UpnpUpdate uu = UpnpUpdate.new();
    }
  }
  
  runTasks() {
    //log.log(lvl, "Running tasks");
    du.updateOnInterval();
    uu.updateOnInterval();
  }
  
  main() {
    var e;
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
  
  startBackground() {
    vars {
      System:Thread myThread;
      Int sleepTime = 500;
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
    myThread = System:Thread.new(self);
    myThread.start();
  }

}

use class Dz:Ui {

  new() self {
      properties {
        IO:Log log = IO:Log.new();
        log.level = log.info;
        Int lvl = log.level;
        Map modules = Map.new();
        Lock lock = Lock.new();
        Background bg = Background.new();
      }
      
      Hello h = Hello.new();
      h.log = log;
      h.lvl = lvl;
      modules["Hello"] = h;
      
      MediaIO i = MediaIO.new();
      i.log = log;
      i.lvl = lvl;
      i.app = self;
      modules["MediaIO"] = i;
      
      Accounts a = Accounts.new();
      a.log = log;
      a.lvl = lvl;
      a.app = self;
      modules["Accounts"] = a;
      
      bg.log = log;
      bg.lvl = lvl;
      bg.app = self;
      //bg.startBackground();
      
  }
  
  internalPortGet() String {
      vars {
        String intPort;
      }
      if (TS.isEmpty(intPort)) {
        intPort = self.configManager.get("wui.port");
        if (TS.isEmpty(intPort)) {
          Int intPorti = System:Random.getInt(Int.new(), 6000);
          intPorti += 3000;
          intPort = intPorti.toString();
          self.configManager.put("wui.port", intPort);
        }
      }
      return(intPort);
    }
    
    externalPortGet() String {
      vars {
        String extPort;
      }
      if (TS.isEmpty(extPort)) {
        extPort = self.configManager.get("wui.extPort");
        if (TS.isEmpty(extPort)) {
          Int extPorti = System:Random.getInt(Int.new(), 6000);
          extPorti += 3000;
          extPort = extPorti.toString();
          self.configManager.put("wui.extPort", extPort);
        }
      }
      return(extPort);
    }
  
  pathsGet() App:Paths {
    vars {
      App:Paths paths;
    }
    if (undef(paths)) {
      paths = App:Paths.new();
    }
    return(paths);
  }
  
  configManagerGet() CLocker {
    vars {
      CLocker configManager;
    }
    if (undef(configManager)) {
      Path db = self.paths.dataPath.addStep("Dz").addStep("DDZDB");
      //KvDb configManagerKv = KvDb.new(Derby.pathNew(db), "CONFIG");
      KvDb configManagerKv = KvDb.new(HsDb.pathNew(db), "CONFIG");
      configManagerKv.createOpen();
      configManager = CLocker.new(configManagerKv);
    }
    return(configManager);
  }
  
  sessionManagerGet() Web:SessionManager {
    vars {
      Web:SessionManager sessionDb;
    }
    if (undef(sessionDb)) {
      Path db = self.paths.dataPath.addStep("Dz").addStep("SESSDB");
      //KvDb sessionDbKv = KvDb.new(Derby.pathNew(db), "SESSIONS");
      KvDb sessionDbKv = KvDb.new(HsDb.pathNew(db), "SESSIONS");
      sessionDbKv.createOpen();
      sessionDb = Web:SessionManager.new(CLocker.new(sessionDbKv));
    }
    ("got sessionmanager").print();
    return(sessionDb);
  }
  

  handleWeb(request, Map arg) {
        try {
            String mname = arg.get("module");
            String aname = arg.get("action");
            if (undef(aname) || aname.ends("Request")! || undef(mname) || modules.has(mname)!) {
              throw(Exception.new("Invalid request"));
            }
            String accountName = request.getSession("account.name");
            if (TS.isEmpty(accountName)) {
              unless (mname == "Accounts" && aname == "loginRequest") {
                return(null);
              }
            }
            log.log(lvl, "here");
            Array args = Array.new(2);
            args[0] = arg;
            args[1] = request;
            var module = modules.get(mname);
            if (module.can(aname, args.length)) {
              var res = module.invoke(aname, args);
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
    
    getHomeDir(request) Path {
      String accountName = request.getSession("account.name");
      Path homeDir = Path.apNew("Home/" + accountName);
      return(homeDir);
    }
    
    accountManagerGet() AccountManager {
      properties {
        AccountManager am;
      }
      if (undef(am)) {
        am = AccountManager.new(self.configManager, "ACCOUNTS.");
      }
      return(am);
    }
    
    loggedIn(Account a, Map res, Map arg, request) {
      res["action"] = "updateResponse";
      res["justLoggedIn"] = true;
      res["permsString"] = a.permsString;
      res["camLinks"] = modules.get("MediaIO").camLinksForAccount(a);
      log.log(lvl, "CamLinks " + res["camLinks"]);
      return(res);
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
        mode = "wui";
      }
      if (mode == "lui") {
        Lui.new().main();
      }
      if (mode == "wui") {
        Wui.new().main();
      }
      if (mode == "test") {
        Dz:Test.new().main();
      }
      if (mode == "cmd") {
        CmdUi.new().main(args);
      }
   }
   
   doUpnp() {
      log.log(lvl, "upnping not");
      
   }

}

use class Dz:CmdUi(Ui) {

  new() self {
        properties {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
        }
        super.new();
    }
    
    main() {
      main(System:Process.new().args);
    }
    
    main(Array args) {
      outerMain(System:Process.new().args);
      try {
        self.configManager.close();
      } catch (var e) {
        log.log(lvl, "Exception closing db in CmdUi, error is " + e);
      }
    }
    
    outerMain(Array args) {
      try {
        innerMain(System:Process.new().args);
      } catch (var e) {
        log.log(lvl, "Exception in CmdUi, error is " + e);
      }
    }

    innerMain(Array args) {
      if (args.length > 1) {
        String mode = args[1]; //ui, svc, both, [absent]
        log.log(lvl, "cmd " + mode);
      } else {
        log.log(lvl, "cmd empty");
      }
      if (TS.isEmpty(mode) || mode == "help") {
        log.log(lvl, "Help");
        log.log(lvl, "listLogins, createAccount, getAccount, setPermsString, setPass, deleteAccount, updateConfig, showConfig, createConfig, deleteConfig");
      }
      if (TS.notEmpty(mode) && mode == "listLogins") {
        foreach (String login in self.accountManager.getLogins()) {
          log.log(lvl, "Account login " + login);
        }
      }
      if (TS.notEmpty(mode) && mode == "createAccount") {
        String user = args[2];
        String pass = args[3];
        log.log(lvl, "Creating Account " + user);
        Account ac = Account.new();
        ac.user = user;
        ac.pass = pass;
        if (args.length > 4) {
          ac.permsString = args[4];
        }
        self.accountManager.createAccount(ac);
      }
      if (TS.notEmpty(mode) && mode == "getAccount") {
        user = args[2];
        log.log(lvl, "Get Account " + user);
        ac = self.accountManager.getAccount(user);
        log.log(lvl, "Account " + ac);
      }
      if (TS.notEmpty(mode) && mode == "setPermsString") {
        user = args[2];
        String ps = args[3];
        log.log(lvl, "Set Perms " + user);
        ac = self.accountManager.getAccount(user);
        ac.permsString = ps;
        self.accountManager.updateAccount(ac);
        log.log(lvl, "Account " + ac);
      }
      if (TS.notEmpty(mode) && mode == "setPass") {
        user = args[2];
        pass = args[3];
        log.log(lvl, "Set Pass " + user);
        ac = self.accountManager.getAccount(user);
        ac.pass = pass;
        self.accountManager.updateAccount(ac);
      }
      if (TS.notEmpty(mode) && mode == "deleteAccount") {
        user = args[2];
        log.log(lvl, "Deleting Account " + user);
        ac = self.accountManager.getAccount(user);
        if (def(ac)) {
          self.accountManager.deleteAccount(ac);
          log.log(lvl, "Deleted account " + user);
        } else {
          log.log(lvl, "No such account for deletion " + user);
        }
      }
      if (TS.notEmpty(mode) && mode == "updateConfig") {
        String key = args[2];
        String value = args[3];
        log.log(lvl, "Updating config " + key + " " + value);
        self.configManager.put(key, value);
      }
      if (TS.notEmpty(mode) && mode == "showConfig") {
        foreach (var kv in self.configManager.getMap()) {
          log.log(lvl, "Config name " + kv.key + " value " + kv.value);
        }
      }
      if (TS.notEmpty(mode) && mode == "createConfig") {
        key = args[2];
        value = args[3];
        log.log(lvl, "Creating config " + key + " " + value);
        self.configManager.put(key, value);
      }
      if (TS.notEmpty(mode) && mode == "deleteConfig") {
        key = args[2];
        log.log(lvl, "Deleting config " + key);
        self.configManager.delete(key);
      }
    }
}

use class Dz:Hello {

     new() self {
       properties {
          IO:Log log;
          Int lvl;
        }
     }

     sayHelloRequest(Map arg, request) {
      "in say hello".print();
      log.log(lvl, "In say hello");
      Map res = Map.new();
      res["action"] = "sayHelloResponse";
      res["msg"] = "hello";
      return(res);
   }

}

use class Dz:MediaIO {

     new() self {
       properties {
          IO:Log log;
          Int lvl;
          var app;
        }
     }

     updateImageRequest(Map arg, request) {
      Path pp = app.getHomeDir(request).addStep("WebCam");
      String cam = arg["cam"];
      Account a = app.accountManager.getAccountForRequest(request);
      String an = a.user;
      unless (camOkForAccount(cam, a)) {
        throw(Exception.new("Account " + an + " not authorized for cam " + cam));
      }
      if (pp.file.exists!) {
        pp.file.makeDirs();
      }
      String countKey = "image.count." + cam + "." + an;
      String c = app.configManager.get(countKey);
      if (def(c)) {
        log.log(lvl, "count def " + c);
        count = Int.new(c);
      } else {
        log.log(lvl, "count undef");
        Int count = 0;
        app.configManager.put(countKey, count.toString());
      }
      String rv = app.configManager.get("cam." + cam + ".label");
      if (undef(rv)) {
        rv = System:Random.getString(6);
      }
      String myhn = System:Environment.getVariable("MYHN");
      String picBaseName = "Pic-" + myhn + "-" + rv + "-";
      Int tries = 5;
      Int maxPics = 4;
      Bool updatedCount = false;
      while (tries > 0 && updatedCount!) {
        count = Int.new(app.configManager.get(countKey));
        tries--=;
        Int nxcount = count++;
        if (nxcount > maxPics) {
          nxcount = 0;
        }
        updatedCount = app.configManager.testAndPut(countKey, count.toString(), nxcount.toString());
      }
      if (tries <= 0) {
        throw(System:Exception.new("Unable to get a count option"));
      }
      String picName = picBaseName + count + ".jpg";
      File picFile = pp.copy().addStep(picName).file;
      picFile.delete();
      if (System:CurrentPlatform.name == "mswin") {
        String piccmd = "App\\Dz\\uppic.bat";
      } else {
        piccmd = "App/Dz/uppic.sh";
      }
      log.log(lvl, "pic path " + picFile.path);
      System:Command.new(piccmd + " " + cam + " " + picFile.path).run();
      tries = 60;
      while (picFile.exists! && tries > 0) {
        Time:Sleep.sleepMilliseconds(500);
        tries--=;
      }
      Time:Sleep.sleepMilliseconds(500);
      log.log(lvl, "In load image");
      Map res = Map.new();
      res["action"] = "updateImageResponse";
      //res["imghtm"] = "<img src=\"" + picFile.path.toStringWithSeparator("/") + "\" >";
      res["imghtm"] = "<img src=\"../../" + picFile.path.toStringWithSeparator("/") + "?cbust=" + Time:Interval.now().seconds + System:Random.getString(6) + "\" >";
      return(res);
   }
   
   playSoundRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
      unless (a.perms.has("admin")) {
        log.log(lvl, "Account not admin, not playing sound");
        return(null);
      }
      log.log(lvl, "playing sound");
      System:Command.new("playsound.sh").run();
      return(null);
   }
   
   upnpRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
      unless (a.perms.has("admin")) {
        log.log(lvl, "Account not admin, not upnping");
        return(null);
      }
      app.doUpnp();
      return(null);
   }
   
   runCommandRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
      unless (a.perms.has("admin")) {
        log.log(lvl, "Account not admin, not running command");
        return(null);
      }
      String cmd = arg["cmd"];
      log.log(lvl, "running command " + cmd);
      System:Command.new(cmd).run();
      return(null);
   }
   
   detectCamsRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
      unless (a.perms.has("admin")) {
        log.log(lvl, "Account not admin, not detecting cams");
        return(null);
      }
      //TODO for real, ls /dev/video* with a script into a file
      updateCams();
      Map res = Map.new();
      res["action"] = "updateResponse";
      res["camLinks"] = app.modules.get("MediaIO").camLinksForAccount(a);
      return(res);
   }
   
   updateCams() {
     updateCams("/dev/video0,/dev/video1");
   }
   
   getCams() Set {
      Set ecm = Set.new();
      String ecps = app.configManager.get("cam.paths");
      if (def(ecps)) {
        foreach (String cp in ecps.split(",")) {
          ecm.put(cp);
        }
      }
      return(ecm);
   }
   
   updateCams(String dcs) {
      Set ecm = getCams();
      if (TS.notEmpty(dcs)) {
        foreach (String cp in dcs.split(",")) {
          if (ecm.has(cp)!) {
            app.configManager.delete("cam." + cp + ".label");
            app.configManager.put("cam." + cp + ".label", Path.apNew(cp).steps.last);
          }
        }
      }
      app.configManager.delete("cam.paths");
      app.configManager.put("cam.paths", dcs);
   }
   
   camOkForAccount(String c, Account a) {
    if (a.perms.has("admin") || a.perms.has("allcam") || 
        a.perms.has("cam." + c)) {
      return(true);
    }
    return(false);
   }
   
   camLinksForAccount(Account a) String {
     String camLinks = String.new();
     Set ecm = getCams();
     foreach (String c in ecm) {
       if (camOkForAccount(c, a)) {
          String clabel = app.configManager.get("cam." + c + ".label");
          camLinks += "<p><a href=\"#\" onclick=\"dzeui.bem_updateImage_1(new be_BEL_4_Base_BEC_4_6_TextString().bems_new('" + c + "'));return false;\">Take Picture with " + clabel + "</a></p>";
        }
     }
     return(camLinks);
   }
   
   showConfigRequest(Map arg, request) Map {
     Account a = app.accountManager.getAccountForRequest(request);
     if (def(a) && a.perms.has("admin")) {
       String conf = String.new();
       Map ecm = app.configManager.getMap();
       if (ecm.isEmpty!) {
         conf += "<table>";
         foreach (var kv in ecm) {
           unless(kv.value.has("\"")) {
              String ckey = "configKey" + kv.key;
              conf += "<tr><td>" + kv.key + "</td><td><input type=\"text\" onchange=\"updateConfig('" + kv.key + "', '" + ckey + "')\" id=\"" + ckey + "\" value=\"" + kv.value + "\"></td><td><a href=\"#\" onclick=\"dzeui.bem_deleteConfig_1(new be_BEL_4_Base_BEC_4_6_TextString().bems_new('" + kv.key + "'));return false;\">x</a></td></tr>";
            }
         }
      }
      conf += "<tr><td>Add New:&nbsp;<input type=\"text\" onchange=\"dzeui.bem_addConfig_0()\" id=\"addConfigKeyId\" value=\"\"></td><td><a href=\"#\" onclick=\"return false;\">+</a><input type=\"hidden\" id=\"addConfigValId\" value=\"\"></td></tr>";
      conf += "</table>";
      conf += "<a href=\"#\" onclick=\"dzeui.bem_hideConfig_0();return false;\">Hide Configuration</a>";
       Map res = Map.new();
      res["action"] = "showConfigResponse";
      res["configs"] = conf;
      return(res);
    }
    return(null);
   }
   
   updateConfigRequest(Map arg, request) Map {
     Account a = app.accountManager.getAccountForRequest(request);
     if (def(a) && a.perms.has("admin")) {
      log.log(lvl, "update for " + arg["configKey"] + " value " + arg["configValue"]);
      app.configManager.put(arg["configKey"], arg["configValue"]);
      return(showConfigRequest(arg, request));
      }
      return(null);
   }
   
   deleteConfigRequest(Map arg, request) Map {
     Account a = app.accountManager.getAccountForRequest(request);
     if (def(a) && a.perms.has("admin")) {
      log.log(lvl, "delete for " + arg["configKey"]);
      app.configManager.delete(arg["configKey"]);
      return(showConfigRequest(arg, request));
      }
      return(null);
   }


}

use App:Account;
use App:AccountManager;

//web thing
use class Dz:Accounts {

  new() self {
     properties {
        IO:Log log;
        Int lvl;
        var app;
      }
   }
   
   checkLoggedInRequest(Map arg, request) {
    String accountName = request.getSession("account.name");
    if (TS.notEmpty(accountName)) {
      Account a = app.accountManager.getAccount(accountName);
      if (def(a)) {
        log.log(lvl, "Found logged in account " + accountName);
        Map res = Map.new();
        res["action"] = "loggedInResponse";
        res["name"] = accountName;
        return(app.loggedIn(a, res, arg, request));
      } else {
        log.log(lvl, "No such account " + accountName);
      }
    }
    return(logoutRequest(arg, request));
  }

  loginRequest(Map arg, request) {
    Account a = app.accountManager.getAccount(arg["accountName"]);
    if (def(a)) {
      log.log(lvl, "Found account " + arg["accountName"]);
      if (a.checkPass(arg["accountPass"])) {
        log.log(lvl, "Login ok");
        request.putSession("account.name", arg["accountName"]);
        Map res = Map.new();
        res["action"] = "loggedInResponse";
        res["name"] = arg["accountName"];
        return(app.loggedIn(a, res, arg, request));
      } else {
        log.log(lvl, "Login notok");
      }
    } else {
      log.log(lvl, "No such account " + arg["accountName"]);
    }
    return(logoutRequest(arg, request));
  }
  
  logoutRequest(Map arg, request) {
    request.putSession("account.name", "");
    Map res = Map.new();
    res["action"] = "logoutResponse";
    return(res);
  }
  
}



use Db:KeyValue as KvDb;

use class Dz:ConfigTest(Assert) {
  
  testConfig() {
    Ui ui = Ui.new();
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

use class Dz:MediaIOTest(Assert) {
  
  testCamUpdate() {
  
    Ui app = Ui.new();
    app.configManager.delete("cam.paths");
    app.configManager.delete("cam./dev/video0.label");
    app.configManager.delete("cam./dev/video1.label");
    MediaIO mio = app.modules["MediaIO"];
    mio.updateCams();
    assertEqual(app.configManager.get("cam.paths"), "/dev/video0,/dev/video1");
    assertEqual(app.configManager.get("cam./dev/video0.label"), "video0");
    
    mio.updateCams();
    assertEqual(app.configManager.get("cam.paths"), "/dev/video0,/dev/video1");
    assertEqual(app.configManager.get("cam./dev/video1.label"), "video1");
    
  }
  
  main() {
    "Begin MediaIOTest".print();
    testCamUpdate();
    "End MediaIOTest".print();
  }
  
}


use class Dz:AccountTest(Assert) {
  
  testAccounts() {
    Ui ui = Ui.new();
    Account atest = Account.new();
    atest.user = "test";
    atest.pass = "pass";
    AccountManager am = ui.accountManager;
    am.deleteAccount(atest);
    Account a = am.getAccount(atest.user);
    assertNull(a);
    am.createAccount(atest);
    a = am.getAccount(atest.user);
    assertNotNull(a);
    assertFalse(a.perms.has("admin"));
    assertTrue(a.checkPass("pass"));
    assertFalse(a.checkPass("notpass"));
    a.pass = "yo";
    assertTrue(a.checkPass("yo"));
    a.perms.put("admin");
    am.updateAccount(a);
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

