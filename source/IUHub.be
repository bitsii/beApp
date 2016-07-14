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
use System:Command as Com;
use Time:Sleep;

use App:Alert;

use class IUHub:Lui(Ui) {

  new() self {
        fields {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
        }
        super.new();
        bg.startBackground(); //normally on
    }

    main() {
      webr = WeBr.new();
      webr.webHandler = self;
      webr.height = 450;
      webr.width = 320;
      
      String mypwd = System:Environment.getVariable("MYPWD");
      webr.location = "file:///" + mypwd + "/App/IUHub/IUHub.html";
      
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
use class IUHub:Wui(Ui) {

  emit(jv) {
  """
  static { Security.addProvider(new BouncyCastleProvider());  }
  """
  }

  new() self {
        fields {
        }
        super.new();
        bg.startBackground(); //normally on
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
      //vw.gzipOutput = true;//security issues
      fields {
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
    log.log(lvl, "In handleStartWeb!!");
  }
  
  assureCertJv(Int port) String {
    emit(jv) {
    """
    java.security.cert.Certificate cert;
    """
    }
    Path cerPath = Path.apNew("Data/IUHub/cert");
    String cerPathS = cerPath.toString();
    log.log(lvl, "cerPath " + cerPathS);
    if (cerPath.file.exists) {
      log.log(lvl, "cer exist");
      emit(jv) {
      """
      KeyStore privateKS = KeyStore.getInstance("JKS");
      privateKS.load( new FileInputStream(bevl_cerPathS.bems_toJvString()), "kp".toCharArray());
      cert = privateKS.getCertificate("jetty");
      """
      }
    } else {
      log.log(lvl, "cer not exist");
      log.log(lvl, "Start gencert");
      if (cerPath.parent.file.exists!) {
        cerPath.parent.file.makeDirs();
      }
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
      cert = privateKS.getCertificate("jetty");
      """
      }
      log.log(lvl, "End gencert");
    }
    emit(jv) {
    """
    bevp_certificateThumbprint = new BEC_4_6_TextString(
                 BEC_3_6_18_WebClientCertificateManager.bevs_inst.bems_getThumbprint(((X509Certificate) cert))
              );
    """
    }
    fields {
      String certificateThumbprint;
    }
    log.log(lvl, "certificateThumbprint " + certificateThumbprint);
    return(cerPathS);
  }
  
    main() {
      Array args = System:Process.new().args;

      startWeb();
   }

   initWeb() {

   }
   
   checkWritePath(Path p, request) Bool {
    Account a = self.accountManager.getAccountForRequest(request);
    if (def(a) && a.perms.has("admin")) {
      return(true);
    }
    String accountName = request.getSession("account.name");
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
   
   checkReadPath(Path p, request) Bool {
    Account a = self.accountManager.getAccountForRequest(request);
    if (def(a) && a.perms.has("admin")) {
      return(true);
    }
    String accountName = request.getSession("account.name");
    var e;
    Bool isOk = false;
    if (undef(accountName)) { accountName = ""; }
    try {
      Path pa = p.file.absPath;
      Path adz = Path.apNew("App/IUHub").file.absPath;
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
     unless (checkRequest(request)) {
      return(null);
     }
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
          if (def(a) && preLoginCheck(request)) {
            log.log(lvl, "Found account " + ln);
            if (a.checkPass(lp)) {
              log.log(lvl, "svc login ok");
              request.putSession("account.name", ln);
              request.putSession("ip", request.remoteAddress);
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
     if (undef(arg)) {
       String uri = request.uri;
       log.log(lvl, "uri " + uri);
       File imgfile = File.apNew(Encode:Url.decode(uri.substring(1)));
       if (TS.notEmpty(rmtd) && rmtd == "PUT") {
         if (checkWritePath(imgfile.path, request)) {
           log.log(lvl, "put for " + imgfile.path);
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
       } elif (checkReadPath(imgfile.path, request)) {
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
          IO:Writer outw = request.openOutput();
          IO:Reader inr = imgfile.reader.open();
          inr.copyData(outw);
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
    fields {
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
      var e;
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
      var app;
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
    var e;
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
          foreach (String ep in exPorts.split(",")) {
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
        String deviceId = app.configManager.get("deviceId");
        String intUrl = "https://" += intAddress += ":" += intPort += "/App/IUHub/IUHub.html";
        String extUrl = "https://" += extAddress += ":" += extPort += "/App/IUHub/IUHub.html";
        String intLink = "<a href=\"" + intUrl + "\">" + deviceName + " " + deviceId + " internal Link, use on same network as the device is on.</a>";
        String extLink = "<a href=\"" + extUrl + "\">" + deviceName + " " + deviceId + " external Link, use from the internet or outside the network the device is on.</a>";
        Map jsl = Map.new();
        if (TS.notEmpty(exPorts)) {
          String extraPortsMsg = String.new();
          foreach (ep in exPorts.split(",")) {
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
        app.links.o = jsl;
        app.updateNetAddresses();
      }
    }
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
    
    appIntPort = app.internalPort;
    appExtPort = app.externalPort;
    deviceName = app.deviceName;
    
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
      var app;
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
    myThread = System:Thread.new(self);
    myThread.start();
  }

}

use System:Thread:ObjectLocker as OLocker;
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
use class IUHub:Ui {

  new() self {
      fields {
        IO:Log log = IO:Log.new();
        log.level = log.info;
        Int lvl = log.level;
        Lock lock = Lock.new();
        Background bg = Background.new();
        OLocker links = OLocker.new();
        OLocker lastLoginBad = OLocker.new(false);
        HHandler requestHandler;
      }
      
      requestHandler = HHandler.new();
      requestHandler.log = log;
      requestHandler.lvl = lvl;
      requestHandler.app = self;
      
      bg.log = log;
      bg.lvl = lvl;
      bg.app = self;
      //bg.startBackground();
      
  }
  
  badRequest(request) {
  
  }
  
  checkRequest(request) Bool {
  
    Int maxBad =@ 40;
    Int clearSecs =@ 40;
    Int updateSecs =@ 20;
  
  /*
    Int maxBad =@ 5;
    Int clearSecs =@ 10;
    Int updateSecs =@ 5;
  */
    
    String ip = request.remoteAddress;
    String sip = request.getSession("ip");
    String accountName = request.getSession("account.name");
    if (TS.notEmpty(ip) && TS.notEmpty(sip) && TS.notEmpty(accountName)) {
      if (ip == sip) {
        return(true);
      }
    }
  
    Int ns = Time:Interval.now().seconds;
    
    if (TS.notEmpty(ip)) {
      String ct = self.trackingManager.get("IP." + ip);
      if (TS.notEmpty(ct)) {
        String ltm = self.trackingManager.get("LB." + ip);
        if (TS.notEmpty(ltm)) {
          Int ltmi = Int.new(ltm);
          if (ns - ltmi > clearSecs) {
            log.log(lvl, "clear bad " + ip);
            badcount = 0;
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
    if (badcount > maxBad) {
      log.log(lvl, "toomany bad " + ip);
      if (def(ltmi) && ns - ltmi > updateSecs) {
        log.log(lvl, "lp update");
        self.trackingManager.put("LB." + ip, ns.toString());
      } else {
        log.log(lvl, "no update");
      }
      return(false);
    }
    if (TS.isEmpty(accountName)) {
      log.log(lvl, "upping bad");
      badcount++=;
      self.trackingManager.put("IP." + ip, badcount.toString());
      self.trackingManager.put("LB." + ip, ns.toString());
    } else {
      self.trackingManager.delete("IP." + ip);
      self.trackingManager.delete("LB." + ip);
      //self.trackingManager.clear();
    }
    return(true);
  }
  
  requestFromAdmin(request) Bool {
    Account a = self.accountManager.getAccountForRequest(request);
    if (def(a) && a.perms.has("admin")) {
      return(true);
    }
    badRequest(request);
    return(false);
  }
  
  preLoginCheck(request) Bool {
    if (lastLoginBad.o) {
      Int slptime = System:Random.getInt(Int.new(), 500);
      Time:Sleep.sleepMilliseconds(slptime);
    }
    return(true);
  }
  
  goodLogin(request) {
    lastLoginBad.o = false;
  }
  
  badLogin(request) {
    badRequest(request);
    lastLoginBad.o = true;
  }
  
  updateNetAddresses() {
    log.log(lvl, "In doimap");
    var e;
    try {
      Map jsl = links.o;
      if(def(jsl) && jsl.notEmpty) {
        String prot = self.configManager.get("imap.protocol");
        if (TS.isEmpty(prot)) {
          prot = "imaps";
        }
        String endpoint = self.configManager.get("imap.endpoint");
        String user = self.configManager.get("imap.user");
        String pass = self.configManager.get("imap.pass");
        String subf = self.configManager.get("imap.subFolder");
        if (undef(subf)) {
          subf = "IotUrls";
        } elif (TS.isEmpty(subf)) {
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
        String subjPref = "DeviceLinks " + jsl.get("deviceName") + " " + self.configManager.get("deviceId") + " ";
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
  
  deviceNameGet() String {
    fields {
      String deviceName;
    }
    if (TS.isEmpty(deviceName)) {
      deviceName = self.configManager.get("deviceName");
      if (TS.isEmpty(deviceName)) {
        deviceName = "Device-" + System:Random.getString(4);
        self.configManager.put("deviceName", deviceName);
      }
    }
    return(deviceName);
  }
  
  deviceIdGet() String {
    fields {
      String deviceId;
    }
    if (TS.isEmpty(deviceId)) {
      deviceId = self.configManager.get("deviceId");
      if (TS.isEmpty(deviceId)) {
        deviceId = System:Random.getString(16);
        self.configManager.put("deviceId", deviceId);
      }
    }
    return(deviceId);
  }
  
  internalPortGet() String {
      fields {
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
      fields {
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
    fields {
      App:Paths paths;
    }
    if (undef(paths)) {
      paths = App:Paths.new();
    }
    return(paths);
  }
  
  configManagerGet() CLocker {
    fields {
      CLocker configManager;
    }
    if (undef(configManager)) {
      Path db = self.paths.dataPath.addStep("IUHub").addStep("CONFDB");
      //KvDb configManagerKv = KvDb.new(Derby.pathNew(db), "CONFIG");
      KvDb configManagerKv = KvDb.new(HsDb.pathNew(db), "CONFIG");
      configManagerKv.createOpen();
      configManager = CLocker.new(configManagerKv);
    }
    return(configManager);
  }
  
  sessionManagerGet() Web:SessionManager {
    fields {
      Web:SessionManager sessionDb;
    }
    if (undef(sessionDb)) {
      Path db = self.paths.dataPath.addStep("IUHub").addStep("SESSDB");
      //KvDb sessionDbKv = KvDb.new(Derby.pathNew(db), "SESSIONS");
      KvDb sessionDbKv = KvDb.new(HsDb.pathNew(db), "SESSIONS");
      sessionDbKv.createOpen();
      sessionDb = Web:SessionManager.new(CLocker.new(sessionDbKv), "GsSess" + self.deviceId);
    }
    ("got sessionmanager").print();
    return(sessionDb);
  }
  
  getSessionsForAccount(Account a) String {
    //a.user
    String res = String.new();
    String accountName = a.user;
    Map all = self.sessionManager.sessions.getMap();
    foreach (var kv in all) {
      if (kv.key.ends("account.name") && kv.value == accountName) {
        log.log(lvl, "Found session " + kv.key);
        var kp = kv.key.split(".");
        String sessLabel = String.new();
        String name = self.sessionManager.sessions.get(kp.first + ".session.name");
        if (def(name)) {
          log.log(lvl, "sess name " + name);
          sessLabel += "Session named " += name;
        }
        String ip = self.sessionManager.sessions.get(kp.first + ".ip");
        if (def(ip)) {
          log.log(lvl, "sess ip " + ip);
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
  
  trackingManagerGet() CLocker {
    fields {
      CLocker trackingManager;
    }
    if (undef(trackingManager)) {
      Path db = self.paths.dataPath.addStep("IUHub").addStep("TMDB");
      KvDb trackingManagerKv = KvDb.new(HsDb.pathNew(db), "TRACKING");
      trackingManagerKv.createOpen();
      trackingManager = CLocker.new(trackingManagerKv);
    }
    return(trackingManager);
  }
  
  

  handleWeb(request, Map arg) {
    unless (checkRequest(request)) {
      return(null);
     }
        try {
            String aname = arg.get("action");
            if (undef(aname) || aname.ends("Request")!) {
              throw(Exception.new("Invalid request"));
            }
            String accountName = request.getSession("account.name");
            if (TS.isEmpty(accountName)) {
              unless (aname == "loginRequest") {
                return(null);
              }
            }
            log.log(lvl, "here");
            Array args = Array.new(2);
            args[0] = arg;
            args[1] = request;
            if (requestHandler.can(aname, args.length)) {
              var res = requestHandler.invoke(aname, args);
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
      fields {
        AccountManager am;
      }
      if (undef(am)) {
        am = AccountManager.new(self.configManager, "ACCOUNTS.");
      }
      return(am);
    }
    
    assureVers() {
      fields {
        Int majorVer = 5@;
        Int minorVer = 0@;
      }
    }
    
    majorVerGet() Int {
      assureVers();
      return(majorVer);
    }
    
    minorVerGet() Int {
      assureVers();
      return(minorVer);
    
    }
    
    loggedIn(Account a, Map res, Map arg, request) {
      res["action"] = "updateResponse";
      res["justLoggedIn"] = true;
      res["permsString"] = a.permsString;
      res["cmdLinks"] = requestHandler.cmdLinksForAccount(a);
      res["appVersion"] = self.majorVer.toString() + "." + self.minorVer.toString();
      res["deviceName"] = self.deviceName;
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
        IUHub:Test.new().main();
      }
      if (mode == "cmd") {
        CmdUi.new().main(args);
      }
   }
   
   doUpnp() {
      log.log(lvl, "upnping not");
      
   }

}

use class IUHub:CmdUi(Ui) {

  new() self {
        fields {
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
        log.log(lvl, "listLogins, putAccount, getAccount, setPermsString, setPass, deleteAccount, updateConfig, showConfig, createConfig, deleteConfig");
      }
      if (TS.notEmpty(mode) && mode == "portForward") {
        Net:PortForward pf = Net:PortForward.new(args[2], Int.new(args[3]), args[4], Int.new(args[5]));
        pf.log = log;
        pf.lvl = lvl;
        pf.start();
      }
      if (TS.notEmpty(mode) && mode == "listLogins") {
        foreach (String login in self.accountManager.getLogins()) {
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
        self.accountManager.putAccount(ac);
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
        self.accountManager.putAccount(ac);
        log.log(lvl, "Account " + ac);
      }
      if (TS.notEmpty(mode) && mode == "setPass") {
        user = args[2];
        pass = args[3];
        log.log(lvl, "Set Pass " + user);
        ac = self.accountManager.getAccount(user);
        ac.pass = pass;
        self.accountManager.putAccount(ac);
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

use Crypto:Symmetric as Crypt;
use class IUHub:HHandler {

     new() self {
       fields {
          IO:Log log;
          Int lvl;
          var app;
        }
     }
     
  tryThingRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        app.updateNetAddresses();
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
   
   clearAllSessionsRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        log.log(lvl, "Clearing all sessions request by login " + app.accountManager.getAccountForRequest(request).user);
        app.sessionManager.sessions.clear();
     }
     return(null);
   }
   
   clearAllTrackingRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        log.log(lvl, "Clearing all tracking requested by login "  + app.accountManager.getAccountForRequest(request).user);
        app.trackingManager.clear();
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
      Account a = app.accountManager.getAccountForRequest(request);
      unless (TS.notEmpty(arg["newPass"]) && a.checkPass(arg["oldPass"])) {
        log.log(lvl, "incorrect old pass");
        throw(Alert.new("Old password incorrect"));
      }
      a.pass = arg["newPass"];
      app.accountManager.putAccount(a);
   }
   
   loadAccountRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = app.accountManager.getAccount(arg["accountName"]);
      if (def(a)) {
        Map res = Map.new();
        res["action"] = "loadAccountResponse";
        res["accountName"] = a.user;
        res["admin"] = a.perms.has("admin");
        return(res);
      } elif (true) {
        throw(Alert.new("No such account"));
      }
      return(null);
   }
   
   showAccountAdminRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      String accountLinks = String.new();
      Array logins = app.accountManager.getLogins();
      foreach (String login in logins) {
        accountLinks += "<p><a href=\"#\" onclick=\"loadAccountRequest('" += login += "');return false;\">Modify " += login += "</a></p>";
      }
      Map res = Map.new();
      res["action"] = "showAccountAdminResponse";
      res["accountLinks"] = accountLinks;
      return(res);
   }
   
   deleteAccountRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = app.accountManager.getAccount(arg["accountName"]);
      if (def(a)) {
        if (a.user == app.accountManager.getAccountForRequest(request).user) {
          throw(Alert.new("Cannot delete own account"));
        }
      }
      app.accountManager.deleteAccount(a);
      return(showAccountAdminRequest(arg, request));
  }
      
   
   saveAccountRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = app.accountManager.getAccount(arg["accountName"]);
      if (undef(a)) {
        log.log(lvl, arg["accountName"] + " not found, creating new");
        a = Account.new();
        a.user = arg["accountName"];
      } else {
        if (a.user == app.accountManager.getAccountForRequest(request).user) {
          throw(Alert.new("Cannot change own account"));
        }
        log.log(lvl, arg["accountName"] + " found, use existing");
      }
      if (TS.notEmpty(arg["accountPass"])) {
        log.log(lvl, "pass set, changing");
        a.pass = arg["accountPass"];
      }
      if (arg["admin"]) {
        a.perms.put("admin");
      } else {
        a.perms.delete("admin");
      }
      app.accountManager.putAccount(a);
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
   
   showSessionsRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
      Map res = Map.new();
      res["action"] = "showSessionsResponse";
      res["sessionsList"] = app.getSessionsForAccount(a);
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
   
   deleteRequest(Map arg, request) Map {
     log.log(lvl, "del request");
     String path = arg["path"];
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
     if (TS.notEmpty(path)) {
       File dirFile = File.apNew(Encode:Hex.new().decode(path));
       if (dirFile.exists && app.checkWritePath(dirFile.path, request)) {
         log.log(lvl, "deleting " + dirFile.path);
         dirFile.delete();
       }
     }
     return(null);
   }
   
   copyRequest(Map arg, request) Map {
     log.log(lvl, "copy request");
     String path = arg["path"];
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
     if (TS.notEmpty(path)) {
       File dirFile = File.apNew(Encode:Hex.new().decode(path));
       if (TS.notEmpty(arg["toName"]) && dirFile.exists && app.checkWritePath(dirFile.path, request)) {
         var dpath = Path.apNew(arg["toName"]);
         dpath = dirFile.path.parent.copy() + dpath;
         log.log(lvl, "precheck write " + dpath);
         if (app.checkWritePath(dpath, request)) {
           log.log(lvl, "copying " + dirFile.path + " to " + dpath);
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
       var e;
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
   
   localBrowseRequest(Map arg, request) Map {
     log.log(lvl, "in local browse req");
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
      Encode:Hex hex = Encode:Hex.new();
      Encode:Url urle = Encode:Url.new();
      Encode:Html htmle = Encode:Html.new();
      Map ret = Map.new();
      String path = arg["path"];
      Account a = app.accountManager.getAccountForRequest(request);
      Bool adminLinks = false;
      if (a.perms.has("admin")) {
        adminLinks = true;
      }
      if (TS.isEmpty(path)) {
        dirFile = app.getHomeDir(request).file;
        if (dirFile.exists!) {
          dirFile.makeDirs();
        }
      } else {
        File dirFile = File.apNew(hex.decode(path));
      }
      String dirListHtml = String.new();
      dirListHtml += "<input type=\"hidden\" id=\"browsingDirId\" value=\"" += hex.encode(dirFile.path.toString()) += "\"/>";
      if (dirFile.exists && app.checkReadPath(dirFile.path, request)) {
        dirListHtml += "<p>Listing for " += htmle.encode(dirFile.path.toString()) += "</p>";
        dirListHtml += "<table>";
        if (adminLinks) {
          if (System:CurrentPlatform.name == "mswin") {
            dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode("\\") += "');return false;\">ROOT</a></td></tr>";
          } else {
            dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode("/") += "');return false;\">ROOT</a></td></tr>";
          }
          dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(".") += "');return false;\">APPDIR</a></td></tr>";
        }
        dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(app.getHomeDir(request).toString()) += "');return false;\">HOME</a></td></tr>";
        dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(dirFile.path.toString()) += "');return false;\">.  (REFRESH)</a></td></tr>";
        IO:File:Path parent = dirFile.path.parent;
        if (def(parent) && TS.notEmpty(parent.toString())) {
        dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(parent.toString()) += "');return false;\">.. (UP)</a></td></tr>";
        }
        if (dirFile.isDir) {
          var dit = dirFile.iterator;
          dit.open();
          Array olist = Array.new();
          Map omap = Map.new();
          while (dit.hasNext) {
            File entry = dit.next;
            Path p = entry.path;
            olist += p.steps.last;
            omap.put(p.steps.last, entry);
          }
          olist = olist.sort();
          foreach (String ole in olist) {
            entry = omap.get(ole);
            p = entry.path;
            if (entry.isDirectory) {
              dirListHtml += "<tr>";
              dirListHtml += "<td>DIR</td><td><a href=" + TS.quote + "#" + TS.quote + " onclick=\"localBrowseRequest('"
          += hex.encode(p.toString()) += "');return false;\">" += htmle.encode(p.name) += "</a></td>";
              dirListHtml += "</tr>";   
            } else {
              if (p.toString().ends(".jpg")) {
                String jscall = " onclick=\"localBrowseRequest('" += hex.encode(p.toString()) += "');return false;\"";
              } else {
                jscall = "";
              }
              dirListHtml += "<tr>";
              dirListHtml += "<td>FILE</td><td><a href=" += TS.quote += "../../" += urle.encode(p.toString()) += TS.quote + jscall + ">" += htmle.encode(p.name) += "</a></td><td>" += entry.size += "</td>";
              dirListHtml += "<td><input type=\"checkbox\" id=\"FCB"
              += hex.encode(p.toString()) += "\" onclick=\"fileChecked(this);\"\"></td>";
              dirListHtml += "</tr>";
            }
          }
          dit.close();
        } elif (dirFile.path.toString().ends(".jpg")) {
          Map res = Map.new();
          res["action"] = "updateImageResponse";
          res["imghtm"] = "<img src=\"../../" + dirFile.path.toStringWithSeparator("/") + "?cbust=" + Time:Interval.now().seconds + System:Random.getString(6) + "\" >";
          return(res);
        }
        dirListHtml += "</table>";
      }
      ret.put("action", "localBrowseResponse");
      ret.put("dirListHtml", dirListHtml);
      return(ret);
    }
   
  cmdLinksForAccount(Account a) String {
     String cmdLinks = String.new();
     Map ecm = app.configManager.getMap("CMD." + a.user + "!");
     foreach (var kv in ecm) {
      String key = kv.key;
      key = key.substring(key.find("!") + 1, key.size);
      cmdLinks += "<p><a href=\"#\" onclick=\"eui.bem_runCommand_1(new be_BEL_4_Base_BEC_4_6_TextString().bems_new('" + kv.key + "'));return false;\">" + key + "</a></p>";
     }
     return(cmdLinks);
   }
   
   showDevLinksRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
       //String devLinks = "<p><a href=\"#\" onclick=\"eui.bem_offerDevLink_0();return false;\">Send Link Offer</a></p>";
       Map res = Map.new();
       res["action"] = "showDevLinksResponse";
       //res["devLinks"] = devLinks;
       return(res);
     }
     return(null);
   }
   
   offerLinkRequest(Map arg, request) Map {
     Account a = app.accountManager.getAccountForRequest(request);
     if (app.requestFromAdmin(request)) {
       log.log(lvl, "In offer link request");
       String offerEmail = arg["offerEmail"];
       String offerPass1 = arg["offerPass1"];
       String offerPass2 = arg["offerPass2"];
       if (TS.isEmpty(offerEmail)) {
        throw(Alert.new("offerEmail is required"));
       }
       if (undef(offerPass1)) {
         offerPass1 = "";
       }
       if (undef(offerPass2)) {
         offerPass2 = "";
       }
       if (offerPass1 != offerPass2) {
        throw(Alert.new("offer passwords do not match"));
       }
       String offerPass = offerPass1;
       String linkEmail = offerEmail;
       
       log.log(lvl, "offer link " + offerEmail + " " + offerPass);
       
      /*
      in envelope - subject has action type and device name and link id, from address
      in body - encr seed, link id, how protected (pass, none, ?token), in encr blob [ sender (verif), linkId (verif), cert thumb, shared secret (offer only), token (offer only) ]
      */
       
       Json:Marshaller mar = Json:Marshaller.new();
       
       //from address
       String linkId = System:Random.getString(16);
       String linkToken = System:Random.getString(32);
       String linkSecret = System:Random.getString(32);
       String seed = System:Random.getString(24);
       
       String subj = "GOS LinkOffer " + linkId + " !" + app.deviceName + "!";
       Map inner =  Map.new();
       inner["linkId"] = linkId;
       inner["linkToken"] = linkToken;
       inner["linkSecret"] = linkSecret;
       inner["linkEmail"] = linkEmail;
       
       Map outer = Map.new();
       outer["seed"] = seed;
       outer["linkId"] = linkId;
       outer["protectedBy"] = "password";
       
       //save it to conf
       app.configManager.put("link." + linkId + ".token", linkToken);
       app.configManager.put("link." + linkId + ".secret", linkSecret);
       app.configManager.put("link." + linkId + ".email", linkEmail);
       
       //password protect it
       outer["inner"] = Crypt.new().encryptPassToHex(seed, seed + offerPass, mar.marshall(inner));
       String offerOut = mar.marshall(outer);
       log.log(lvl, "offerOut " + offerOut);
       String offerOutHex = Encode:Hex.encode(offerOut); 
       String msg = "<p>" + offerOutHex + "</p>"
       //email it
       
       
       String user = app.configManager.get("smtp.user");
       if (TS.isEmpty(user)) {
        user = app.configManager.get("imap.user");
       }
       String pass = app.configManager.get("smtp.pass");
       if (TS.isEmpty(pass)) {
        pass = app.configManager.get("imap.pass");
       }
       
       String endpoint = app.configManager.get("smtp.endpoint");
       String port = app.configManager.get("smtp.port");
       String email = app.configManager.get("smtp.fromEmail");
       
       //"smtp.gmail.com"
       //"587"
       
       emit(jv) {
        """
      String user = bevl_user.bems_toJvString();
      String pass = bevl_pass.bems_toJvString();
      
      Properties props = new Properties();
      props.put("mail.smtp.starttls.enable", true);
      props.put("mail.smtp.host", bevl_endpoint.bems_toJvString());
      props.put("mail.smtp.user", user);
      props.put("mail.smtp.password", pass);
      props.put("mail.smtp.port", bevl_port.bems_toJvString());
      props.put("mail.smtp.auth", true);
    
      Session session = Session.getInstance(props,
      new javax.mail.Authenticator() {
          protected javax.mail.PasswordAuthentication  getPasswordAuthentication() {
          return new javax.mail.PasswordAuthentication(
                      user, pass);
                  }
      });

			MimeMessage message = new MimeMessage(session);
			message.setFrom(new InternetAddress(bevl_email.bems_toJvString()));
			message.setRecipients(Message.RecipientType.TO,
				InternetAddress.parse(bevl_email.bems_toJvString()));
			message.setSubject(bevl_subj.bems_toJvString());
			message.setText(bevl_msg.bems_toJvString(), "utf-8", "html");

			Transport.send(message);
        """
        }
        log.log(lvl, "Sent Invite");
     }
     return(null);
   }
   
   showConfigRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
       String conf = String.new();
      conf += "<a href=\"#\" onclick=\"eui.bem_hideConfig_0();return false;\">Hide Configuration</a>";
       Map ecm = app.configManager.getMap();
       if (ecm.isEmpty!) {
         conf += "<table>";
         foreach (var kv in ecm) {
           unless(kv.value.has("\"")) {
              String ckey = "configKey" + kv.key;
              conf += "<tr><td>" + kv.key + "</td><td><input type=\"text\" id=\"" + ckey + "\" value=\"" + kv.value + "\"></td><td><a href=\"#\" onclick=\"eui.bem_deleteConfig_1(new be_BEL_4_Base_BEC_4_6_TextString().bems_new('" + kv.key + "'));return false;\">Delete</a></td><td><a href=\"#\" onclick=\"updateConfig('" + kv.key + "', '" + ckey + "');return false;\">Save</a></td></tr>";
            }
         }
      }
      conf += "<tr><td>Add New:&nbsp;<input type=\"text\" id=\"addConfigKeyId\" value=\"\"></td><td><a href=\"#\" onclick=\"eui.bem_addConfig_0();return false;\">+</a><input type=\"hidden\" id=\"addConfigValId\" value=\"\"></td></tr>";
      conf += "</table>";
       Map res = Map.new();
      res["action"] = "showConfigResponse";
      res["configs"] = conf;
      return(res);
    }
    return(null);
   }
   
   updateConfigRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
      log.log(lvl, "update for " + arg["configKey"] + " value " + arg["configValue"]);
      app.configManager.put(arg["configKey"], arg["configValue"]);
      return(showConfigRequest(arg, request));
      }
      return(null);
   }
   
   deleteConfigRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
      log.log(lvl, "delete for " + arg["configKey"]);
      app.configManager.delete(arg["configKey"]);
      return(showConfigRequest(arg, request));
      }
      return(null);
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
    if (def(a) && app.preLoginCheck(request)) {
      log.log(lvl, "Found account " + arg["accountName"]);
      if (a.checkPass(arg["accountPass"])) {
        log.log(lvl, "Login ok");
        request.putSession("account.name", arg["accountName"]);
        request.putSession("ip", request.remoteAddress);
        if (TS.notEmpty(arg["sessionName"])) {
          request.putSession("session.name", arg["sessionName"]);
        }
        Map res = Map.new();
        res["action"] = "loggedInResponse";
        res["name"] = arg["accountName"];
        app.goodLogin(request);
        return(app.loggedIn(a, res, arg, request));
      } else {
        log.log(lvl, "Login notok");
        app.badLogin(request);
      }
    } else {
      log.log(lvl, "No such account " + arg["accountName"]);
      app.badLogin(request);
    }
    return(logoutRequest(arg, request));
  }
  
  logoutRequest(Map arg, request) {
    //log.log(lvl, "logging out");
    request.deleteSession();
    Map res = Map.new();
    res["action"] = "logoutResponse";
    //log.log(lvl, "logged out, returning");
    return(res);
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

use class IUHub:HHandlerTest(Assert) {
    
  main() {
    "Begin HHandlerTest".print();
    "End HHandlerTest".print();
  }
  
}


use class IUHub:AccountTest(Assert) {
  
  testAccounts() {
    Ui ui = Ui.new();
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

