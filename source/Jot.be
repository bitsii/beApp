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
use Db:DirStore;
use Text:Strings as TS;


emit(cs) {
    """
//for outputting
using System.IO;
using System;
//for ui and sleep and hib
using System.Windows.Forms;
//for cs db
using System.Data.Common;
//for firebird
using FirebirdSql.Data.FirebirdClient;
//for collections (for firebird)
using System.Collections;
//for embedded http listener and wakeonlan
using System.Net;
using System.Net.Sockets;
using System.Text;
//for network info
using System.Net.NetworkInformation;
// for threading
using System.Threading;
// for crypto
using System.Security.Cryptography;
// for ssl certgen
using Mono.Security.Authenticode;
using Mono.Security.X509;
using Mono.Security.X509.Extensions;
//for task mgmt
using Microsoft.Win32.TaskScheduler;
//for elevation
using System.Diagnostics;
    """
}

use System:Thread:Lock;

use System:Thread:ContainerLocker as CLocker;
use System:Thread:ObjectLocker as OLocker;

use Db:RowStore as RS;
class RS {

  //needs a notion of timeout/staleness for non-embedded cases
  //(keep a "last used" time for all ops)
  
  new(_db, String _tableName, Array _cols) self {
    vars {
      var db = _db;
      String tableName = _tableName;
      Array cols = _cols;
    }
  }
  
  putMany(Array lvals) {
    db.begin();
    foreach (Array vals in lvals) {
      try {
        putInner(vals);
      } catch (var e) {
        db.rollback();
        throw(e);
      }
    }
    db.commit();
  }
  
  putOne(Array vals) {
    db.begin();
    try {
      putInner(vals);
    } catch (var e) {
      db.rollback();
      throw(e);
    }
    db.commit();
  }
  
  putInner(Array vals) {
    Int csize = cols.size;
    if (vals.size != csize) {
      throw(Exception.new("putInner failed, vals size " + vals.size + " not equal cols size " + cols.size));
    }
    
    Int dwsize = csize - 1;
    String dw = String.new();
    String ic = String.new();
    String iv = String.new();
    
    for (Int i = 0;i < csize;i++=) {
      if (i < dwsize) {
        if (i > 0) {
          dw += " AND ";
        }
        dw += cols[i] += "='" += vals[i] += "'";
      }
      if (i > 0) {
        ic += ",";
        iv += ",";
      }
      ic += cols[i];
      iv += "'" += vals[i] += "'";
    }
    String delst = "DELETE FROM " + tableName + " WHERE " + dw;
    String insst = "INSERT INTO " + tableName + "( " + ic + " ) VALUES ( " + iv + " )";
    //("delst " + delst).print();
    //("insst " + insst).print();
    db.execute(delst);
    db.execute(insst);
  }
    
  getMany(Array vals) Array {
      db.begin();
      try {
        Array res = getInner(vals);
      } catch (var e) {
        db.rollback();
        throw(e);
      }
      db.commit();
      return(res);
    }
  
  getInner(Array vals) Array {
    Int vsize = vals.size;
    Int csize = cols.size;
    if (vsize > csize) {
      throw(Exception.new("getInner failed, vals size " + vals.size + " greater than cols size " + cols.size));
    }
    
    String sw = String.new();
    String sc = String.new();
    
    for (Int i = 0;i < csize;i++=) {
      if (i < vsize) {
        if (i > 0) {
          sw += " AND ";
        }
        sw += cols[i] += "='" += vals[i] += "'";
      } else {
        if (i > vsize) {
          sc += ",";
        }
        sc += cols[i];
      }
    }
    String selst = "SELECT " + sc + " FROM " + tableName;
    if (TS.notEmpty(sw)) {
      selst += " WHERE " += sw;
    }
    ("selst " + selst).print();
    Array res = Array.new();
    Int rcount = 0;
    foreach (var row in db.executeQuery(selst)) {
      Array rrow = Array.new(csize);
      for (i = 0;i < csize;i++=) {
        if (i < vsize) {
          rrow[i] = vals[i];
        } else {
          rrow[i] = row.getString(i - vsize);
        }
      }
      res[rcount] = rrow;
      rcount++=;
    }
    return(res);
  }
  
    delete() {
      db.begin();
      try {
        deleteInner();
      } catch (var e) {
        db.rollback();
        throw(e);
      }
      db.commit();
    }
    
    deleteInner() {
      db.execute("DELETE FROM " + tableName);
    }
    
    delete(String p) {
      db.begin();
      try {
        deleteInner(p);
      } catch (var e) {
        db.rollback();
        throw(e);
      }
      db.commit();
    }
    
    deleteInner(String p) {
      if (TS.notEmpty(p)) {
        db.execute("DELETE FROM " + tableName + " WHERE P='" + p + "'");
      }
    }
    
    delete(String p, String k) {
      db.begin();
      try {
        deleteInner(p, k);
      } catch (var e) {
        db.rollback();
        throw(e);
      }
      db.commit();
    }
    
    deleteInner(String p, String k) {
      if (TS.notEmpty(p)) {
        db.execute("DELETE FROM " + tableName + " WHERE P='" + p + "' AND K='" + k + "'");
      }
    }
    
    close() {
      if (def(db)) {
        var _db = db;
        db = null;
        _db.close();
      }
    }

}

use Net:UPnP as Upnp;

class Upnp {

  new(String _netGw) self {
    vars {
      String netGw = _netGw;
      IO:Log log = IO:Log.new();
      Int lvl = log.debug;
    }
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
    
    emit(jv) {
    """
    DatagramSocket s = new DatagramSocket();
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
      if (count % 3 == 0) {
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
        log.log(lvl, "got except during upnp bcast et all");
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

use Net:Multicast as NetMulti;
class NetMulti {

  emit(cs) {
  """
  public UdpClient client;
  public IPEndPoint senderEp;
  public IPEndPoint mcastEp;
  """
  }
  emit(jv) {
  """
  InetAddress multicastAddress;
  MulticastSocket socket;
  """
  }

  new() self {
    vars {
      Int timeout = 500;
      Int port = 3000;
      String group = "239.192.100.100";
      String remoteAddress;
    }
  }
  
  open() self {
    emit(cs) {
    """
    client = new UdpClient();
    client.Client.SendTimeout = bevp_timeout.bevi_int;
    client.Client.ReceiveTimeout = bevp_timeout.bevi_int;
 
    client.Client.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, true);
    client.ExclusiveAddressUse = false;
 
    senderEp = new IPEndPoint(IPAddress.Any, bevp_port.bevi_int);
    client.Client.Bind(senderEp);
    
    IPAddress multicastaddress = IPAddress.Parse(bevp_group.bems_toCsString());
    client.JoinMulticastGroup(multicastaddress);
    mcastEp = new IPEndPoint(multicastaddress, 1968);
    """
    }
    emit(jv) {
    """
    try {
      multicastAddress = InetAddress.getByName(bevp_group.bems_toJvString());
      final int port = 1968;
      socket = new MulticastSocket(port);
      socket.setReuseAddress(true);
      socket.setSoTimeout(bevp_timeout.bevi_int);
      //socket.setTimeToLive(200);
      socket.joinGroup(multicastAddress);
    } catch (Throwable t) {
    }
    """
    }
  }
  
  close() self {
    emit(cs) {
    """
    client.Close();
    client = null;
    senderEp = null;
    mcastEp = null;
    """
    }
    emit(jv) {
    """
    try {
      //multicastAddress = null;
      //socket.close();
      //socket = null;
    } catch (Throwable t) {
    }
    """
    }
    remoteAddress = null;
  }
  
  outputContentSet(String send) {
    emit(cs) {
    """
    Byte[] buffer = System.Text.Encoding.UTF8.GetBytes(beva_send.bems_toCsString());
    client.Send(buffer, buffer.Length, mcastEp);
    """
    }
    emit(jv) {
    """
    try {
      final int port = 1968;
      byte[] requestMessage = beva_send.bems_toJvString().getBytes("UTF-8");
      DatagramPacket datagramPacket = new DatagramPacket(requestMessage,
        requestMessage.length, multicastAddress, port);
      socket.send(datagramPacket);
    } catch (Throwable t) {
    }
    """
    }
  }
  
  inputContentGet() String {
    String res;
    emit(cs) {
    """
    try {
        Byte[] data = client.Receive(ref senderEp);
        string strData = System.Text.Encoding.UTF8.GetString(data, 0, data.Length);
        bevl_res = new BEC_4_6_TextString(strData);
        bevp_remoteAddress = new BEC_4_6_TextString(senderEp.Address.ToString());
    } catch { }
    """
    }
    emit(jv) {
    """
    try {
      byte[] rxbuf = new byte[8192];
      DatagramPacket packet = new DatagramPacket(rxbuf, rxbuf.length);
      socket.receive(packet);
      InetAddress addr = packet.getAddress();
      ByteArrayInputStream in = new ByteArrayInputStream(packet.getData(), 0,
                      packet.getLength());
      
      java.util.Scanner s = new java.util.Scanner(in).useDelimiter("\\A");
      String result = s.hasNext() ? s.next() : "";
      bevl_res = new BEC_4_6_TextString(result);
      bevp_remoteAddress = new BEC_4_6_TextString(addr.getHostAddress().toString());
    } catch (Throwable t) {
    }
    """
    }
    return(res);
  }
  
  inputAddressGet() String {
    return(self.remoteAddress);
  }
  
}

emit(jv) {
"""
import org.bouncycastle.x509.*;
import java.math.BigInteger;
import java.security.cert.X509Certificate;
import org.bouncycastle.jce.X509Principal;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
"""
}
class Ve:App {

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

  startBackground() {
    ifEmit(cs) {
      startBackgroundCs();
    }
  }
  
  startBackgroundCs() {
    String workDir = System:Process.new().execPath.copy().parent.toString();
    emit(cs) {
    """
    using (TaskService ts = new TaskService())
      {
         // Create a new task definition and assign properties
         TaskDefinition td = ts.NewTask();
         
         td.RegistrationInfo.Description = "Start Ve Reg";
         //td.RegistrationInfo.Description = "Test bootsetup";
         
         td.Settings.DisallowStartIfOnBatteries = false;
         td.Settings.StopIfGoingOnBatteries = false;
         td.Principal.LogonType = TaskLogonType.S4U;
         //td.Settings.ExecutionTimeLimit = new TimeSpan(42949672950000);
         td.Settings.ExecutionTimeLimit = TimeSpan.Zero;
         
         //DailyTrigger dt = new DailyTrigger { DaysInterval = 1 };
         //dt.Repetition.Duration = TimeSpan.FromDays(1);
         //dt.Repetition.Interval = TimeSpan.FromMinutes(480);
         //td.Triggers.Add(dt);
         td.Triggers.Add(new RegistrationTrigger());
         //td.Triggers.Add(new BootTrigger());

         td.Actions.Add(new ExecAction(Application.ExecutablePath.ToString(), "svc", bevl_workDir.bems_toCsString()));

         // Register the task in the root folder
         
         ts.RootFolder.RegisterTaskDefinition(@"StartVeReg", td);
         //ts.RootFolder.RegisterTaskDefinition(@"TestBootSetup", td);

         // Remove the task we just created
         //ts.RootFolder.DeleteTask("StartVeBoot");
         
      }
    """
    }
  }
  
  printLinks() {
    String port = configs.get("web", "port");
    String pad = self.primaryAddress;
    if (def(port) && def(pad)) {
      String locUrl = "https//" + pad + ":" + port;
    }
    if (def(locUrl)) {
      ("You can connect to this device using your web browser").print();
      ("with these addresses:").print();
      "".print();
      ("On the same network as the device:").print();
      locUrl.print();
      "".print();
      ("This address may change, if you install the app and link a device to this one it will be able to provide you with an up-to-date address.").print();
      "".print();
      Map forward = self.forward;
      if (def(forward) && TS.notEmpty(forward["extIP"]) && TS.notEmpty(forward["extPort"])) {
        String extUrl = "https://" + forward["extIP"] + ":" + forward["extPort"];
        ("From the internet:").print();
        extUrl.print();
        "".print();
        ("This address may change, you should use a gateway name service to configure a named address, login and click Gateway for more").print();
      } else {
        ("External forwarding not configured, login to the above url and setup forwarding to get access to this device from the internet").print();
      }
    } else {
      ("Setup incomplete, please try setup again").print();
    }
    
    
  }

  enableBootTask() {
    ifEmit(cs) {
      enableBootTaskCs();
    }
  }
  
  enableBootTaskCs() {
    String workDir = System:Process.new().execPath.copy().parent.toString();
    emit(cs) {
    """
    using (TaskService ts = new TaskService())
      {
         // Create a new task definition and assign properties
         TaskDefinition td = ts.NewTask();
         
         td.RegistrationInfo.Description = "Start Ve Boot";
         //td.RegistrationInfo.Description = "Test bootsetup";
         
         td.Settings.DisallowStartIfOnBatteries = false;
         td.Settings.StopIfGoingOnBatteries = false;
         td.Principal.LogonType = TaskLogonType.S4U;
         //td.Settings.ExecutionTimeLimit = new TimeSpan(42949672950000);
         td.Settings.ExecutionTimeLimit = TimeSpan.Zero;
         
         DailyTrigger dt = new DailyTrigger { DaysInterval = 1 };
         dt.Repetition.Duration = TimeSpan.FromDays(1);
         dt.Repetition.Interval = TimeSpan.FromMinutes(480);
         td.Triggers.Add(dt);
         td.Triggers.Add(new RegistrationTrigger());
         td.Triggers.Add(new BootTrigger());

         td.Actions.Add(new ExecAction(Application.ExecutablePath.ToString(), "boot", bevl_workDir.bems_toCsString()));

         // Register the task in the root folder
         
         ts.RootFolder.RegisterTaskDefinition(@"StartVeBoot", td);
         //ts.RootFolder.RegisterTaskDefinition(@"TestBootSetup", td);

         // Remove the task we just created
         //ts.RootFolder.DeleteTask("StartVeBoot");
         
      }
    """
    }
  }
  
  elevateRunSelf(String tname) {
    emit(cs) {
    """
    ProcessStartInfo proc = new ProcessStartInfo();
    proc.UseShellExecute = true;
    
    //will these keep the windows from showing up?
    proc.WindowStyle = ProcessWindowStyle.Hidden;
    
    proc.WorkingDirectory = Environment.CurrentDirectory;
    proc.FileName = Application.ExecutablePath;
    proc.Verb = "runas";
    proc.Arguments = beva_tname.bems_toCsString();

    try
    {
        Process.Start(proc);
    }
    catch
    {
        // The user refused the elevation.
        // Do nothing and return directly ...
        //return;
    }
    //Application.Exit();  // Quit itself
    """
    }
    }

  checkWebLuiUp() Bool {
    Bool res = checkWebLuiUpInner1();
    return(res);
  }
  
  checkWebLuiUpInner1() Bool {
    var e;
    Bool res = false;
    String port = configs.get("web", "port");
    String print = configs.get("web", "print");
    if (TS.notEmpty(port) && TS.notEmpty(print)) {
      try {
        Web:Client:CertificateManager.acceptedThumbprints.put(print);
        res = checkWebLuiUpInner2(port, print);
        Web:Client:CertificateManager.acceptedThumbprints.delete(print);
      } catch (e) {
        Web:Client:CertificateManager.acceptedThumbprints.delete(print);
        res = false;
      }
    }
    return(res);
  }
  
  checkWebLuiUpInner2(String port, String print) Bool {
    Bool upRes = false;
    Web:Client client = Web:Client.new();
    client.url = "https://127.0.0.1:" + port + "/";
    client.method = "POST";
    client.outputContentType =@ "application/json";
    String payload = Json:Marshaller.new().marshall(self.codeRequest);
    client.openOutput().write(payload).close();
    String res = client.openInput().readString();
    client.close();
    Map resMap = Json:Unmarshaller.new().unmarshall(res);
    if (TS.notEmpty(resMap["action"]) && resMap["action"] == "deviceCodeSuccessResponse") {
      String gotPrint = client.certificateThumbprint;
      if (TS.notEmpty(gotPrint)
          && gotPrint == print) {
        log.log(lvl, "Got res in checkServerUp");
        upRes = true;
      }
      log.log(lvl, "checkWebUpInner2 prints wanted " + print + " got " + gotPrint + " overall res");
    }
    return(upRes);
  }
  
  codeRequestGet() Map {
    String deviceCode = configs.get("device", "deviceCode");
    if (undef(deviceCode)) {
      deviceCode = "na";
    }
    Map req = Map.new();
    req["action"] = "deviceCodeRequest";
    req["deviceCode"] = deviceCode;
    return(req);
  }
  
  checkAuth(Map arg) Bool {
    var e;
    String accountName = arg["accountName"];
    if (TS.notEmpty(accountName)) {
      Map account = accounts.get(accountName);
    }
    if (def(account) && account.isEmpty!) {
      String ph = passToHash(account["accountPassSalt"], arg["accountPass"]);
      String phCheck = account["accountPassHash"];
      if (phCheck == ph) {
        return(true);
      }
    }
    return(false);
  }

  wakeMacAddr(String addr) {
    addr = addr.swap(":", "");
    addr = addr.swap("-", "");
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
  
  assureCert(Int port) String {
    ifEmit(cs) {
      return(assureCertCs(port));
    }
    ifEmit(jv) {
      return(assureCertJv(port));
    }
  }
  
  assureCertJv(Int port) String {
    IO:File:Path certDir = self.configDir.copy();
    log.log(lvl, "certDir is " + certDir);
    IO:File:Path cerPath = certDir.copy().addStep("veks");
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
  
  assureCertCs(Int port) String {
  
    IO:File:Path certDir = self.homeDir.copy();
    certDir.addStep("Application Data").addStep(".mono").addStep("httplistener");
    log.log(lvl, "certDir is " + certDir);
    IO:File:Path cerPath = certDir.copy().addStep(port.toString() + ".cer");
    IO:File:Path pvkPath = certDir.copy().addStep(port.toString() + ".pvk");
    String cerPathS = cerPath.toString();
    String pvkPathS = pvkPath.toString();
    log.log(lvl, "cerPath " + cerPathS);
    log.log(lvl, "pvkPath " + pvkPathS);
    if (cerPath.file.exists && pvkPath.file.exists) {
      log.log(lvl, "cer and pvk exist");
      return(cerPathS);
    } else {
      log.log(lvl, "cer and pvk not exist");
    }
    log.log(lvl, "Start gencert");
    emit(cs) {
    """
    X509CertificateBuilder cb = new X509CertificateBuilder (3);
    //makecert -r -n "CN=test" -sv test.pvk test.cer
    DateTime notBefore = DateTime.Now;
    DateTime notAfter = new DateTime (643445675990000000); // 12/31/2039 23:59:59Z
    RSA subjectKey = (RSA)RSA.Create ();
    cb.SerialNumber = Guid.NewGuid ().ToByteArray ();
    cb.IssuerName = "CN=test"; //pre ff fix
    //cb.IssuerName = "CN=test, OU=None, O=None, L=None, C=None";
    cb.NotBefore = notBefore;
    cb.NotAfter = notAfter;
    cb.SubjectName = "CN=test"; //pre ff fix
    //cb.SubjectName = "CN=test, OU=None, O=None, L=None, C=None";
    cb.SubjectPublicKey = subjectKey;
    // signature
    cb.Hash = "SHA1";
    byte[] rawcert = cb.Sign (subjectKey);

    PrivateKey key = new PrivateKey ();
    key.RSA = subjectKey;
    key.Save (bevl_pvkPathS.bems_toCsString());
    FileStream fs = File.Open (bevl_cerPathS.bems_toCsString(), FileMode.Create, FileAccess.Write);
    fs.Write (rawcert, 0, rawcert.Length);
    fs.Close ();
    """
    }
    log.log(lvl, "End gencert");
    return(cerPathS);
  }
  
  forwardGet() Map {
    Map forward = configs.get("forward");
    String ports = configs.get("web", "port");
    forward.put("intPort", ports);
    return(forward);
  }
  
  clearForward() {
    configs.delete("forward");
  }
  
  saveForward(Map forward) {
    configs.put("forward", forward);
  }
  
  getSetupForward() Map {
    var e;
    vars {
      Int nextGwTry;
    }
    try {
      Map forward = self.forward;
      String gatewayEnabled = configs.get("gateway", "enabled");
      if (TS.notEmpty(gatewayEnabled) && gatewayEnabled == "true") {
        if (undef(nextGwTry)) {
          nextGwTry = 443;
        } else {
          nextGwTry += 1000;
        }
        if (nextGwTry < 20000) {
          forward["extPort"] = nextGwTry.toString();
        } else {
          nextGwTry = 30000;
        }
      }
      forward = forwardPort(forward);
    } catch(e) {
      clearForward();
      throw(e);
    }
    return(forward);
  }
  
  upnpGet() Upnp {
    if (def(self.luiL) && def(self.luiL.o)) {
      String gwad = self.luiL.o.useGateway;
    }
    if (TS.isEmpty(gwad)) {
      gwad = self.gatewayAddress;
    }
    Upnp up = Upnp.new(gwad);
    return(up);
  }
  
  forwardPort(Map forward) Map {
    //Int lvl = log.info;
    String extPort = forward["extPort"];
    if (TS.isEmpty(extPort)) {
      Int port = System:Random.getInt(Int.new(), 30000);
      port += 10000;
      extPort = port.toString();
      forward["extPort"] = extPort;
    }
    String intPort = forward["intPort"];
    log.log(lvl, "forwardPort using extPort " + extPort + " intPort " + intPort);
    Upnp up = self.upnp;
    String extIP = up.externalIP;
    forward["extIP"] = extIP;
    String intIP = up.internalIP;
    forward["intIP"] = intIP;
    String oextIP = self.getExternalIP();
    if (extIP != oextIP) {
      log.log(lvl, "IP MISMATCH");
      throw(Exception.new("upnp and external ip mismatch"));
    }
    Bool success = up.forwardPort(3600, Int.new(extPort), Int.new(intPort));
    log.log(lvl, "forward success " + success);
    unless(success) {
      throw(Exception.new("Failed forwarding port"));
    }
    log.log(lvl, "saving forward");
    if (log.will(lvl)) {
      foreach (var me in forward) {
        log.log(lvl, "forward kvpair : " + me.key + " = " + me.value);
      }
    }
    saveForward(forward);
    return(forward);
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
  
  primaryAddressGet() String {
    
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
      Int count = 0;
      foreach (String s in res.biter) {
        count++=;
        if (s == " ") {
          if (started) {
            break;
          }
        } else {
          started = true;
        }
      }
      res = res.substring(count);
      started = false;
      foreach (s in res.biter) {
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
  
  getExternalIP() String {
    //later, break up into upnp and no upnp approach
    //(this one no upnp)
    var e;
    try {
      Web:Client client = Web:Client.new();
      client.method = "GET";
      client.url = "http://checkip.dyndns.org/";
      String res = client.openInput().readString();
      client.close();
      client = null;
      //log.log(lvl, "GetExtIp Res");
      if (TS.notEmpty(res)) {
        //log.log(lvl, res.toString());
        res = res.substring(res.find("<body>"));
        res = res.substring(0, res.find("</body>"));
        //log.log(lvl, "body res |" + res + "|");
        res = res.substring(res.find(":") + 2);
        //log.log(lvl, "ip res |" + res + "|");
      } else {
        //log.log(lvl, "res empty");
      }
    } catch (e) {
      if (def(client)) {
        client.close();
        client = null;
      }
      throw(e);
    }
    return(res);
    }
  
  new() self {
    Array _cols = Array.new(3);
    _cols.put(0, "P");
    _cols.put(1, "K");
    _cols.put(2, "V");
    vars {
      OLocker webLuiL = OLocker.new();
      OLocker luiL = OLocker.new();
      OLocker disLuiL = OLocker.new();
      OLocker nanLuiL = OLocker.new();
      IO:File:Path configDir;
      Lock linkLock = Lock.new();
      Set linkIps = Set.new();
      Set linkSecrets = Set.new();
      String linkSecret;
      Bool linkSecretReturned = false;
      Bool prod = false;              
      CRS configs = CRS.new(self, "CONFIGS", _cols);
      CRS drafts = CRS.new(self, "DRAFTS", _cols);
      CRS accounts = CRS.new(self, "ACCOUNTS", _cols);
      CRS links = CRS.new(self, "LINKS", _cols);
      CRS gateways = CRS.new(self, "GATEWAYS", _cols);
      OLocker clearExternalIpUpdate = OLocker.new(false);
      OLocker webStarted = OLocker.new(false);
      OLocker webStartChecked = OLocker.new(false);
      Int linkTTL = 600;//300? 600?  seconds for ttl
      //Bool prod = true;
      IO:Log log = IO:Log.new();
      Int shlvl = log.info;
      Int lvl = shlvl;
      log.level = log.info;
    }
  }
    
  passToHash(String salt, String pass) String {
    if (TS.isEmpty(salt) || TS.isEmpty(pass)) {
      return(null);
    }
    pass = salt + pass;
    Digest:SHA256 ds = Digest:SHA256.new();
    for (Int i = 0;i < 7;i++=) {
      pass = ds.digest(pass);
    }
    pass = Encode:Hex.encode(pass);
    return(pass);
  }
  
  passToHash(String pass) String {
    if (TS.isEmpty(pass)) {
      return(null);
    }
    Digest:SHA256 ds = Digest:SHA256.new();
    for (Int i = 0;i < 7;i++=) {
      pass = ds.digest(pass);
    }
    pass = Encode:Hex.encode(pass);
    return(pass);
  }
  
  saveJot(Map arg) Map {
    Encode:Hex hexe = Encode:Hex.new();
    Encode:Url urle = Encode:Url.new();
    Encode:Html htmle = Encode:Html.new();
    var e;
    if (def(arg)) {
      if (TS.notEmpty(arg["draftCategory"]) &&
      TS.notEmpty(arg["draftName"])) {
        if (TS.isEmpty(arg["draftContent"])) {
          arg["draftContent"] = "";
        }
        drafts.put(
          urle.encode(arg["draftCategory"]), 
          urle.encode(arg["draftName"]), 
          hexe.encode(arg["draftContent"]));
        log.log(lvl, "Saved " + arg["draftCategory"] + " " + arg["draftName"]);
        Map res = Map.new();
        res["action"] = "draftMessageResponse";
        res["message"] = htmle.encodeText(arg["draftName"]) + " Saved.";
        return(res);
      } else {
        throw(Alert.new("Jot Category and Name required"));
      }
    }
    return(null);
   }
   
   loadJot(Map arg) Map {
    Encode:Hex hexe = Encode:Hex.new();
    Encode:Url urle = Encode:Url.new();
    Encode:Html htmle = Encode:Html.new();
    var e;
    if (def(arg)) {
      if (TS.notEmpty(arg["draftCategory"]) &&
      TS.notEmpty(arg["draftName"])) {
        Map res = Map.new();
        res += arg;
        res["action"] = "loadJotResponse";
        res["draftContent"] =
          hexe.decode(drafts.get(urle.encode(arg["draftCategory"]),
          urle.encode(arg["draftName"])));
        log.log(lvl, "Loaded " + arg["draftCategory"] + " " + arg["draftName"]);
        res["message"] = htmle.encodeText(arg["draftName"]) + " Loaded.";
        return(res);
      } else {
        throw(Alert.new("Jot Category and Name required"));
      }
    }
    return(null);
   }
    
    setup(Map arg) {
      var e;
      if (def(arg) && TS.notEmpty(arg["startupEnabled"])) {
        configs.put("startup", "enabled", arg["startupEnabled"]);
      }
      if (def(arg) && TS.notEmpty(arg["deviceName"])) {
        if (TS.notEmpty(arg["devicePort"])) {
          String port = configs.get("web", "port");
          if (undef(port) || port != arg["devicePort"]) {
            configs.put("web", "port", arg["devicePort"]);
            configs.delete("web", "print");
          }
        }
        configs.put("device", "deviceName", arg["deviceName"]);
        String deviceCode = configs.get("device", "deviceCode");
        if (TS.isEmpty(deviceCode)) {
          deviceCode = System:Random.getString(16);
          configs.put("device", "deviceCode", deviceCode);
        }
        if (TS.notEmpty(arg["originUI"]) && arg["originUI"] == "lui") {
          //elevateRunSelf("bootsetup"); //TODO scheduling
        }
      } else {
        throw(Alert.new("Device name required"));
      }
    }
    
  getSubAccounts(String accountName) {
    Array subs = Array.new();
    if (TS.notEmpty(accountName)) {
      Map account = accounts.get(accountName);
      if (def(account) && account.isEmpty!) {
        foreach (var kv in account) {
          if (kv.key.begins("SUB-")) {
            subs += kv.value;
          }
        }
      }
    }
    return(subs);
  }
  
  crudAccount(Map arg) {
      var e;
      if (undef(arg)) {
        throw(Exception.new("crudAccount arg undef"));
      }
      String accountName = arg["accountName"];
      if (TS.isEmpty(accountName)) {
        throw(Alert.new("Account name is required"));
      }
      if (TS.isEmpty(arg["accountAction"])) {
        throw(Exception.new("crudAccount accountAction missing"));
      }
      String superAccountName = arg["superAccountName"];
      if (TS.notEmpty(superAccountName)) {
        Map superAccount = accounts.get(superAccountName);
      }
      Map currentAccount = accounts.get(accountName);
      unless (arg["accountAction"] == "update" && arg["preAuthed"] == "true") {
        if (arg["accountAction"] == "delete" || arg["accountAction"] == "update") {
          if (undef(superAccount) || superAccount.has("SUB-" + accountName)!) {
            throw(Exception.new("is not superaccount, can't"));
          }
        }
      }
      if (arg["accountAction"] == "delete") {
        foreach (var dkv in currentAccount) {
          if (dkv.key.begins("SUB-")) {
            throw(Alert.new("Cannot delete account with subaccounts, pls have parent (or new console account) take subaccounts first"));
          }
        }
        accounts.delete(accountName);
        accounts.delete(superAccountName, "SUB-" + accountName);
        log.log(lvl, "Deleted subaccount " + accountName);
        return(self);
      }
      String accountPass = arg["accountPass"];
      if (arg["accountAction"] == "update") {
        accounts.put(accountName, "isAdmin", arg["isAdmin"]);
        if (TS.isEmpty(accountPass)) {
          return(self);
        }
      }
      if (TS.notEmpty(accountName) && TS.notEmpty(accountPass)) {
        if (TS.isEmpty(arg["accountPass2"]) || arg["accountPass"] !=
          arg["accountPass2"]) {
          throw(Alert.new("Password and Confirm Password must match"));  
        }
        if (accountName.size < 2) {
          throw(Alert.new("Account names must be at least 2 letters long"));
        }
        String passMsg =@ "Account passwords must be at least 3 letters long and must also contain a number or one of !, @, #, $ or &";
        Bool hasInteger = false;
        foreach (String v in accountPass) {
          if (v.isInteger()) {
            hasInteger = true;
            break;
          }
        }
        if (accountPass.size < 3) {
          throw(Alert.new(passMsg));
        }
        unless (hasInteger || accountPass.has("!") ||
          accountPass.has("@") || accountPass.has("#") || 
          accountPass.has("$") || accountPass.has("&")) {
            throw(Alert.new(passMsg));
        } 
        String accountPassSalt = System:Random.getString(16);
        String accountPassHash = passToHash(accountPassSalt, accountPass);
        if (arg["accountAction"] == "update") {
          accounts.put(accountName, "accountPassHash", accountPassHash);
          accounts.put(accountName, "accountPassSalt", accountPassSalt);
          return(self);
        }
        Bool isAdmin = Bool.new(arg["isAdmin"]);
        Map account = Map.new();
        account.put("accountName", accountName);
        account.put("accountPassHash", accountPassHash);
        account.put("accountPassSalt", accountPassSalt);
        account.put("isAdmin", isAdmin.toString());
        if (TS.notEmpty(superAccountName)) {
          if (def(superAccount)) {
            String san = superAccount.get("isAdmin");
          }
          if (TS.notEmpty(san) && san == "true") {
            account.put("superAccountName", superAccountName);
            accounts.put(superAccountName, "SUB-" + accountName, accountName);
            account.put("SUP-" + superAccountName, superAccountName);
          } else {
            throw(Alert.new("Account not authorized to create new accounts"));
          }
        }
        accounts.put(accountName, account);
       } else {
         throw(Exception.new("Missing account name or password"));
       }
    }
  
  readHtml(String fname) String {
       String en = System:Process.execName;
       if (undef(en)) {
         log.log(lvl, "en null");
       } else {
        log.log(lvl, "en " + en);
       }
       if (def(en)) {
         IO:File:Path hp = IO:File:Path.apNew(en);
         hp = hp.parent;
         hp.addStep(fname);
       } else {
         hp = IO:File:Path.apNew("../apprun/jo/" + fname);
       }
        String html = hp.file.reader.open().readString();
        hp.file.reader.close();
        //log.log(lvl, "html is " + html);
        return(html);
   }
  
  encrypt(Map rlink, Map lidReq) String {
    String lidJson = Json:Marshaller.new().marshall(lidReq);
    String fullSecret = rlink["secret"];
    String iv = fullSecret.substring(0, 16);
    String pass = fullSecret.substring(16);
    log.log(lvl, "fullSecret " + fullSecret);
    log.log(lvl, " iv|" + iv + "| pass | " + pass + "|");
    Crypt crypt = Crypt.new();
    String lrs = crypt.encryptPassToHex(iv, pass, lidJson);
    return(lrs);
  }
  
  decrypt(Map link, String clink) Map {
    String fullSecret = link["secret"];
    String iv = fullSecret.substring(0, 16);
    String pass = fullSecret.substring(16);
    log.log(lvl, "fullSecret " + fullSecret);
    log.log(lvl, " iv|" + iv + "| pass | " + pass + "|");
    Crypt crypt = Crypt.new();
    String lrs = crypt.decryptPassFromHex(iv, pass, clink);
    Map lidRes = Json:Unmarshaller.new().unmarshall(lrs);
    return(lidRes);
  }
  
  configDirGet() IO:File:Path {
        if (undef(configDir)) {
            IO:File:Path cd = self.appDir;
            cd = cd.copy().addStep("Config");
            configDir = cd;
        }
        return(configDir);
   }
   
   homeDirGet() IO:File:Path {
       String home;
       home = System:Environment.getVariable("USERPROFILE");
       if (undef(home)) {
         home = System:Environment.getVariable("HOME");
       }
       if (undef(home)) {
          String wp = System:Environment.getVariable("HOMEPATH");
          String wd = System:Environment.getVariable("HOMEDRIVE");
          if (def(wd) && def(wp)) {
            home = wd + wp;
          }
       }
       if (def(home)) {
         return(IO:File:Path.apNew(home));
       }
       return(null)
   }
   
   appDirGet() IO:File:Path {
    properties {
      IO:File:Path appDir;
    }
    if (undef(appDir)) {
       String appData = System:Environment.getVariable("APPDATA");
       if (def(appData)) {
         appDir = IO:File:Path.apNew(appData);
       } else {
         appDir = self.homeDir.copy();
       }
       appDir.addStep("Ve");
       unless (prod) {
         String appDirS = System:Environment.getVariable("TEST_APPDATA");
         if (def(appDirS)) {
          appDir = IO:File:Path.apNew(appDirS);
         }
       }
     }
     return(appDir);
   }
   
   dbPathGet() IO:File:Path {
      properties {
        IO:File:Path dbPath;
      }
      if (undef(dbPath)) {
        dbPath = self.configDir.copy();
        ifEmit(cs) {
          dbPath.addStep("Fb").addStep("VECONF.DB");
        }
        ifEmit(jv) {
          //dbPath.addStep("De").addStep("VECONF");//derby
          dbPath.addStep("Sl").addStep("VECONF");//sqlite
        }
      }
      return(dbPath);    
    }
    
    dbGet() DbDb {
        DbDb db;
        IO:File:Path dbfp = self.dbPath;
        if (dbfp.file.exists!) {
          Bool createDb = true;
          if (dbfp.parent.file.exists!) {
            dbfp.parent.file.makeDirs();
          }
        } else {
          createDb = false;
        }
        String dbAddr;
        ifEmit(cs) {
          dbAddr = "ServerType=1;User=SYSDBA;" + 
          "Password=masterkey;Dialect=3;Database=" + dbfp.toString("\\");
          //log.log(lvl, "new db dbAddr " + dbAddr);
          db = FbDb.new(dbAddr);
          if (createDb) {
            db.createDatabase();
          }
          db.open();
        }
        ifEmit(jv) {
          //dbAddr = "jdbc:derby:" + dbfp.toString() + ";create=true";
          //db = DbDb.new(dbAddr);
          //db.driverOpen("org.apache.derby.jdbc.EmbeddedDriver");
          
          dbAddr = "jdbc:sqlite:" + dbfp.toString();
          db = DbDb.new(dbAddr);
          db.driverOpen("org.sqlite.JDBC");
        }
        if (createDb) {
          db.begin();
          db.execute("CREATE TABLE CONFIGS( P VARCHAR(110), K VARCHAR(110), V VARCHAR(500),"
         + " constraint CONFIGS_k primary key (P,K) )");
          db.execute("CREATE TABLE DRAFTS( P VARCHAR(110), K VARCHAR(110), V VARCHAR(500),"
         + " constraint DRAFTS_k primary key (P,K) )");
          db.execute("CREATE TABLE ACCOUNTS( P VARCHAR(110), K VARCHAR(110), V VARCHAR(500),"
         + " constraint ACCOUNTS_k primary key (P,K) )");
         db.execute("CREATE TABLE LINKS( P VARCHAR(110), K VARCHAR(110), V VARCHAR(500),"
         + " constraint LINKS_k primary key (P,K) )");
         db.execute("CREATE TABLE GATEWAYS( P VARCHAR(110), K VARCHAR(110), V VARCHAR(500),"
         + " constraint GATEWAYS_k primary key (P,K) )");
          db.commit();
        }
        return(db);
    }
  
  ifacesGet() Array {
    Net:Interface ni = Net:Interface.new();
    Array ifaces = Array.new();
    foreach (Interface i in ni.sortedUpInterfaces) {
      if (i.address != "127.0.0.1") {
        ifaces += i.address;
      }
    }
    if (ifaces.length < 1) {
      ifaces += "127.0.0.1"; //?only in dev/not prod?
    }
    return(ifaces);
  }
  
  getMacForInterfaceIp(String ip) {
    String mac;
    Net:Interface ni = Net:Interface.new();
    Array ifaces = Array.new();
    foreach (Interface i in ni.sortedUpInterfaces) {
      if (def(i.macAddress)) {
        log.log(lvl, "mac is " + i.macAddress);
      } else {
        log.log(lvl, "mac undef");
      }
      if (i.address == ip && undef(mac)) {
        mac = i.macAddress;
        log.log(lvl, "found mac " + mac);
      }
    }
    return(mac);
  }
  
  textsForLinkId(Array lid) Array {
    if (lid.length < 5 || TS.anyEmpty(lid)) {
      throw(Exception.new("Invalid link id"));
    }
    Array txts = Array.new();
    String dname = lid[1];
    String payload = Json:Marshaller.new().marshall(lid);
    String sha = Encode:Hex.encode(Digest:SHA256.digest(payload));
    String txt = dname + "-" + sha.substring(0, 4);
    txts += txt;
    txts += sha;
    String fname = dname + "-" + sha;
    txts += fname;
    return(txts);
  }
  
  exit() {
    var e;
    if (def(nanLuiL) && def(nanLuiL.o)) {
      try { nanLuiL.o.exit(); } catch (e) { }
    }
    if (def(luiL) && def(luiL.o)) {
      try { luiL.o.exit(); } catch (e) { }
    }
    if (def(webLuiL) && def(webLuiL.o)) {
      try { webLuiL.o.exit(); } catch (e) { }
    }
    if (def(disLuiL) && def(disLuiL.o)) {
      try { disLuiL.o.exit(); } catch (e) { }
    }
    if (def(configs)) {
      try { configs.close() } catch (e) { }
    }
    if (def(accounts)) {
      try { accounts.close() } catch (e) { }
    }
    if (def(links)) {
      try { links.close() } catch (e) { }
    }
    if (def(luiL) && def(luiL.o)) {
      try { luiL.o.processExit(); } catch (e) { }
    } else {
      System:Process.exit();
    }
  }
}

use Db:ConcurrentRowStore as CRS;

class CRS {

  new() self {
    vars {
      var dbProvider;
      String tableName;
      Array cols;
      OLocker storeLocker = OLocker.new();
      IO:Log log = IO:Log.new();
      Int lvl = log.debug;
    }
  }
  
  new(_dbProvider, String _tableName, Array _cols) self {
    new();
    dbProvider = _dbProvider;
    tableName = _tableName;
    cols = _cols;
  }
  
  delete(String fkey, String skey) {
    var e;
    try {
      RS store = self.store;
      store.delete(fkey, skey);
      self.store = store;
      store = null;
    } catch (e) {
      if (def(store)) {
        store.close();
        store = null;
      }
      throw(e);
    }
  }
  
  delete(String fkey) {
    var e;
    try {
      RS store = self.store;
      store.delete(fkey);
      self.store = store;
      store = null;
    } catch (e) {
      if (def(store)) {
        store.close();
        store = null;
      }
      throw(e);
    }
  }
  
  close() {
    RS store = storeLocker.getAndClear();
    if (def(store)) {
      store.close();
    }
  }
    
  storeGet() RS {
    log.log(lvl, "Getting store");
    RS store = storeLocker.getAndClear();
    if (undef(store)) {
      store = RS.new(dbProvider.db, tableName, cols);
    }
    return (store);
  }
  
  storeSet(RS store) {
    unless (storeLocker.setIfClear(store)) {
      store.close();
    }
  }
  
  //COUNT SPECIFIC
  
  get() Map {
    var e;
    try {
      RS store = self.store;
      Map val = getFromStore(store);
      self.store = store;
      store = null;
    } catch (e) {
      if (def(store)) {
        store.close();
        store = null;
      }
      throw(e);
    }
    return(val);
  }
  
  getFromStore(RS store) Map {
    Array vals = Array.new(0);
    Array res = store.getMany(vals);
    Map pkv = Map.new();
    foreach (Array row in res) {
      Map kv = pkv.get(row.get(0));
      if (undef(kv)) {
        kv = Map.new();
        pkv.put(row.get(0), kv);
      }
      kv.put(row.get(1), row.get(2));
    }
    return(pkv);
  }
  
  get(String fkey) Map {
    var e;
    try {
      RS store = self.store;
      Map val = getFromStore(store, fkey);
      self.store = store;
      store = null;
    } catch (e) {
      if (def(store)) {
        store.close();
        store = null;
      }
      throw(e);
    }
    return(val);
  }
  
  getFromStore(RS store, String p) Map {
    Array vals = Array.new(1);
    vals[0] = p;
    Array res = store.getMany(vals);
    Map kv = Map.new();
    foreach (Array row in res) {
      kv.put(row.get(1), row.get(2));
    }
    return(kv);
  }
  
  get(String fkey, String skey) String {
    var e;
    try {
      RS store = self.store;
      String val = getFromStore(store, fkey, skey);
      self.store = store;
      store = null;
    } catch (e) {
      if (def(store)) {
        store.close();
        store = null;
      }
      throw(e);
    }
    return(val);
  }
  
  getFromStore(RS store, String p, String k) String {
    Array vals = Array.new(2);
    vals[0] = p;
    vals[1] = k;
    Array res = store.getMany(vals);
    Array v;
    if (res.size > 0) {
      v = res[0];
      return(v[2]);
    }
    return(null);
  }
  
  put(String fkey, Map value) {
    var e;
    
    try {
      
      Array lvals = Array.new(value.size);
      Int pos = 0;
      foreach (var kve in value) {
        Array vals = Array.new(3);
        vals[0] = fkey;
        vals[1] = kve.key;
        vals[2] = kve.value;
        lvals.put(pos, vals);
        pos++=;
      }
      
      RS store = self.store;
      store.putMany(lvals);
      self.store = store;
      store = null;
    } catch (e) {
      if (def(store)) {
        store.close();
        store = null;
      }
      throw(e);
    }
  }
  
  put(String fkey, String skey, String value) {
    var e;
    
    try {
      Array vals = Array.new(3);
      vals[0] = fkey;
      vals[1] = skey;
      vals[2] = value;
      
      RS store = self.store;
      store.putOne(vals);
      self.store = store;
      store = null;
      
    } catch (e) {
      if (def(store)) {
        store.close();
        store = null;
      }
      throw(e);
    }
  }
  
}

//for user visible failures
use Ve:AlertException as Alert;

class Alert(Exception) {

}

class Encode:Html {

  create() { }
    
  default() self { }

  encodeText(String txt) String {
    String etxt = String.new(txt.size);
    foreach (String c in txt) {
      if (c == "<") {
        etxt += "&lt;";
      } elif (c == ">") {
        etxt += "&gt;";
      } elif (c == "&") {
        etxt += "&amp;";
      } else {
        etxt += c;
      }
    }
    return(etxt);
  }

}

use class Ve:WebLui {

  new(Ve:App _app) {
    vars {
      Ve:App app = _app;
      OLocker vwL = OLocker.new();
      OLocker portL = OLocker.new();
      IO:Log log = app.log;
      Int lvl = app.shlvl;
    }
    //startWeb();
  }
  
  offerLinkRequest(Map arg, request) {
    Map account = app.accounts.get(request.getSession("account.name"));
    if (undef(account) || account.isEmpty) {
      throw(Alert.new("Must be logged in to link"));
    }
    if (TS.isEmpty(arg["offerName"]) || TS.isEmpty(arg["offerPassword"])
      || TS.isEmpty(arg["offerPassword2"])) {
        throw(Alert.new("Link name, Password, and Confirm Password required"));
      }
    if (arg["offerPassword"] != arg["offerPassword2"]) {
       throw(Alert.new("Password and Confirm Password do not match"));
    }
    if (arg["offerPassword"].size < 4) {
       throw(Alert.new("Password must be at least 4 characters long."));
    }
    if (account.has("LINK-" + arg["offerName"])) {
      throw(Alert.new("Link with this name already exists, please provide a unique name, or delete old link if relinking"));
    }
    String linkId = System:Random.getString(16);
    log.log(lvl, "start exlink check");
    Map exlink = app.links.get(linkId);
    while (def(exlink) && exlink.isEmpty!) {
      linkId = System:Random.getString(16);
      exlink = app.links.get(linkId);
    }
    log.log(lvl, "end exlink check");
    String gatewayEnabled = app.configs.get("gateway", "enabled");
    Map offer = Map.new();
    Map link = Map.new();
    String secret = System:Random.getString(32);
    String iv = System:Random.getString(16);
    String pass = arg["offerPassword"];
    link["id"] = linkId;
    link["name"] = arg["offerName"];
    link["secret"] = secret;
    link["accountName"] = account["accountName"];
    if (TS.notEmpty(gatewayEnabled) && gatewayEnabled == "true") {
      offer["isGateway"] = "true";
    } else {
      offer["isGateway"] = "false";
    }
    offer["id"] = linkId;
    offer["name"] = arg["offerName"];
    offer["secret"] = secret;
    String offers = Json:Marshaller.new().marshall(offer);
    Crypt crypt = Crypt.new();
    String cryptedOffer = crypt.encryptPassToHex(iv, pass, offers);
    Map off = Map.new();
    off["name"] = arg["offerName"];
    off["iv"] = iv;
    off["offer"] = cryptedOffer;
    String offs = Encode:Hex.new().encode(Json:Marshaller.new().marshall(off));
    app.links.put(link["id"], link);
    app.accounts.put(account["accountName"], "LINK-" + link["name"], link["id"]);
    Map res = Map.new();
    res["action"] = "offerLinkResponse";
    res["linkOffer"] = offs;
    return(res);
  }
  
  acceptLinkRequest(Map arg, request) {
    var e;
    Map account = app.accounts.get(request.getSession("account.name"));
    if (undef(account) || account.isEmpty) {
      throw(Alert.new("Must be logged in to link"));
    }
    if (TS.isEmpty(arg["acceptPassword"]) || TS.isEmpty(arg["acceptText"])) {
      throw(Alert.new("Link Password and Link Offer are required"));
    }
    Map off = Json:Unmarshaller.new().unmarshall(Encode:Hex.new().decode(arg["acceptText"]));
    log.log(lvl, "crypt ins " + off["iv"] + " " + off["offer"] + " " + arg["acceptPassword"]);
    Crypt crypt = Crypt.new();
    try {
      String offers = crypt.decryptPassFromHex(off["iv"], arg["acceptPassword"], off["offer"]);
    } catch (e) {
      throw(Alert.new("Link password incorrect, pls confirm and try again"));
    }
    Map offer = Json:Unmarshaller.new().unmarshall(offers);
    if (TS.isEmpty(offer["id"]) || TS.isEmpty(offer["name"]) || TS.isEmpty(offer["secret"])) {
      throw(Alert.new("Malformed link offer"));
    }
    log.log(lvl, "Got offer " + offer["id"] + " " + offer["name"] + " " + offer["secret"]);
    if (account.has("LINK-" + offer["name"])) {
      throw(Alert.new("Link with this name already exists, please request and offer with a unique name, or delete old link if relinking"));
    }
    Map exlink = app.links.get(offer["id"]);
    if (def(exlink) && exlink.isEmpty!) {
      throw(Alert.new("Link with this id already exists, please request a new link offer."));
    }
    offer["accountName"] = account["accountName"];
    app.links.put(offer["id"], offer);
    app.accounts.put(account["accountName"], "LINK-" + offer["name"], offer["id"]);
  }
  
  setupRequest(Map arg, request) {
    if (TS.isEmpty(arg["originUI"]) || arg["originUI"] != "lui") {
      Map account = app.accounts.get(request.getSession("account.name"));
      if (undef(account) || account.has("isAdmin")! || account["isAdmin"] != "true") {
          throw(Alert.new("Not authorized, only admin accounts can modify settings"));
        }
    }
    app.setup(arg);
    return(loadStateRequest(arg, request));
  }
  
  saveJotRequest(Map arg, request) {
    if (TS.isEmpty(arg["originUI"]) || arg["originUI"] != "lui") {
      Map account = app.accounts.get(request.getSession("account.name"));
      if (undef(account)) {
          throw(Alert.new("Must login to Save."));
        }
    }
    return(app.saveJot(arg));
  }
  
  loadJotECRequest(Map arg, request) {
    if (TS.notEmpty(arg["draftCategory"]) && TS.notEmpty(arg["draftName"])) {
      Encode:Hex hex = Encode:Hex.new();
      arg["draftCategory"] = hex.decode(arg["draftCategory"]);
      arg["draftName"] = hex.decode(arg["draftName"]);
    }
    return(loadJotRequest(arg, request));
  }
  
  loadJotRequest(Map arg, request) {
    if (TS.isEmpty(arg["originUI"]) || arg["originUI"] != "lui") {
      Map account = app.accounts.get(request.getSession("account.name"));
      if (undef(account)) {
          throw(Alert.new("Must login to Revert."));
        }
    }
    return(app.loadJot(arg));
  }
  
     
   categoryRequest(Map arg, request) Map {
      Encode:Hex hexe = Encode:Hex.new();
      Encode:Url urle = Encode:Url.new();
      Encode:Html htmle = Encode:Html.new();
      Map ret = Map.new();
      String path = arg["path"];
      String dirListHtml = String.new();
      if (TS.isEmpty(path)) {
        Map ents = app.drafts.get();
      } else {
        String dcpath = hexe.decode(path);
        dirListHtml += "<p>Listing for " += dcpath += "</p>";
        ents = app.drafts.get(urle.encode(dcpath));
      }
      unless (undef(ents) || ents.isEmpty) {
          var dit = ents.iterator;
          while (dit.hasNext) {
            var entry = dit.next;
            String p = urle.decode(entry.key);
            if (undef(entry.value) || entry.value.sameType(ents)) {
              String fdurl = TS.quote + "#" + TS.quote;
              String jsCall = "categoryRequest('"
                += hexe.encode(p) += "')";
                String fd = "CAT  ";
            } else {
              fdurl = TS.quote + "#" + TS.quote;
              jsCall = "jotRequest('"
                += path += "','"
                += hexe.encode(p) += "')";
                fd = "JOT  ";
            }
            dirListHtml += "<p><a href=" + fdurl + " onclick=\"return " += jsCall += ";\">" += fd += htmle.encodeText(p) += "</a></p>";
        }
      }
      ret.put("action", "categoryResponse");
      ret.put("categoryListHtml", dirListHtml);
      return(ret);
    }
  
  createSubAccountRequest(Map arg, request) {
    String cu = request.getSession("account.name");
    if (TS.isEmpty(cu)) {
      throw(Alert.new("Must be logged in to create account"));
    }
    arg["superAccountName"] = cu;
    arg["isAdmin"] = "false";
    arg["accountAction"] = "create";
    arg["preAuthed"] = "false";
    app.crudAccount(arg);
    return(openAccountRequest(arg, request));
  }
  
  deleteSubAccountRequest(Map arg, request) {
    if (arg["confirmDelete"] != "true") {
      throw(Alert.new("Must check box to confirm account deletion"));
    }
    String cu = request.getSession("account.name");
    if (TS.isEmpty(cu)) {
      throw(Alert.new("Must be logged in to delete account"));
    }
    arg["superAccountName"] = cu;
    arg["accountAction"] = "delete";
    arg["preAuthed"] = "false";
    app.crudAccount(arg);
    Map res = loadStateRequest(arg, request);
    res["postLoadAction"] = "openAccountsResponse";
    return(res);
  }
  
  takeSubAccountsRequest(Map arg, request) {
    String cu = request.getSession("account.name");
    if (TS.isEmpty(cu)) {
      throw(Alert.new("Must be logged in to take subaccounts"));
    }
    Map account = app.accounts.get(arg["accountName"]);
    if (undef(account) || account.isEmpty) {
      throw(Exception.new("no such subaccount"));
    }
    unless (account.has("SUP-" + cu)) {
      throw(Exception.new("is not super account to this account"));
    }
    Array subs = Array.new(); 
    foreach (var akv in account) {
      if (akv.key.begins("SUB-")) {
        subs += akv.value;
      }
    }
    foreach (String sa in subs) {
      app.accounts.put(cu, "SUB-" + sa, sa);
      app.accounts.delete(account["accountName"], "SUB-" + sa);
      app.accounts.put(sa, "SUP-" + cu, cu);
    }
    Map res = loadStateRequest(arg, request);
    res["postLoadAction"] = "openAccountsResponse";
    return(res);
  }
  
  updateSubAccountRequest(Map arg, request) {
    String cu = request.getSession("account.name");
    if (TS.isEmpty(cu)) {
      throw(Alert.new("Must be logged in to update account"));
    }
    arg["superAccountName"] = cu;
    arg["accountAction"] = "update";
    arg["preAuthed"] = "false";
    app.crudAccount(arg);
    Map res = loadStateRequest(arg, request);
    res["postLoadAction"] = "openAccountsResponse";
    return(res);
  }
  
  gnsRegisterRequest(Map arg, request) Map {
    unless (app.checkAuth(arg)) {
      throw(Exception.new("Auth failed during gnsRegisterRequest"));
    }
    String gnsEnabled = app.configs.get("gns", "enabled");
    if (TS.isEmpty(gnsEnabled) || gnsEnabled != "true") {
      throw(Exception.new("GNS not enabled"));
    }
    System:Random r = System:Random.new();
    String gwId = r.getString(32);
    String gwReadKey = r.getString(32);
    String gwWriteKey = r.getString(32);
    Map gw = Map.new();
    Map gwdb = Map.new();
    gw.put("id", gwId);
    gwdb.put("id", gwId);
    gw.put("readKey", gwReadKey);
    gwdb.put("readKey", app.passToHash(gwReadKey));
    gw.put("writeKey", gwWriteKey);
    gwdb.put("writeKey", app.passToHash(gwWriteKey));
    gwdb.put("accountName", arg["accountName"]);
    gwdb.put("deviceName", arg["deviceName"]);
    app.gateways.put(gwId, gwdb);
    app.accounts.put(arg["accountName"], "GW-" + gwId, gwId);
    gw.put("action", "gnsRegisterSuccessResponse");
    return(gw);
  }
  
  gnsUpdateRequest(Map arg, request) Map {
    if (TS.isEmpty(arg["id"]) || TS.isEmpty(arg["writeKey"]) || TS.isEmpty(arg["url"])) {
      throw(Exception.new("Missing id, wkey, or url"));
    }
    String gnsEnabled = app.configs.get("gns", "enabled");
    if (TS.isEmpty(gnsEnabled) || gnsEnabled != "true") {
      throw(Exception.new("GNS not enabled"));
    }
    Map gw = app.gateways.get(arg["id"]);
    if (undef(gw) || gw.isEmpty) {
      throw(Exception.new("No such gw"));
    }
    if (app.passToHash(arg["writeKey"]) != gw["writeKey"]) {
      throw(Exception.new("wk auth failed"));
    }
    app.gateways.put(arg["id"], "url", arg["url"]);
    Map res = Map.new();
    res.put("action", "gnsUpdateSuccessResponse");
    return(res);
  }
  
  gnsGetRequest(Map arg, request) {
    if (TS.isEmpty(arg["id"]) || TS.isEmpty(arg["readKey"])) {
      throw(Exception.new("Missing id, wkey"));
    }
    Map gw = app.gateways.get(arg["id"]);
    if (undef(gw) || gw.isEmpty) {
      throw(Exception.new("No such gw"));
    }
    if (app.passToHash(arg["readKey"]) != gw["readKey"]) {
      throw(Exception.new("rd auth failed"));
    }
    Map res = Map.new();
    if (TS.notEmpty(gw["url"])) {
      res["url"] = gw["url"];
      res["action"] = "gnsGetSuccessResponse";
    } else {
      res["action"] = "gnsGetFailNoUrlResponse";
    }
    return(res);
  }
  
  deviceCodeRequest(Map arg, request) {
    String action = "deviceCodeFailResponse";
    String raddr = request.remoteAddress;
    if (def(arg) && TS.notEmpty(arg["deviceCode"]) && def(raddr) && raddr == "127.0.0.1") {
      String deviceCode = app.configs.get("device", "deviceCode");
      if (TS.notEmpty(deviceCode) && deviceCode == arg["deviceCode"]) {
        action = "deviceCodeSuccessResponse";
        if (TS.notEmpty(arg["clearCaches"]) && arg["clearCaches"] == "true") {
          //app.configs.clearCache();
          //app.accounts.clearCache();
          //app.links.clearCache();
          //app.gateways.clearCache();
        }
      }
    }
    Map res = Map.new();
    res["action"] = action;
    return(res);
  }
  
  updateMyAccountRequest(Map arg, request) {
    String cu = request.getSession("account.name");
    if (TS.isEmpty(cu)) {
      throw(Alert.new("Must be logged in to update account"));
    }
    Map ca = Map.new();
    ca["accountName"] = cu;
    ca["accountPass"] = arg["oldAccountPass"];
    unless (app.checkAuth(ca)) {
      throw(Alert.new("Old password incorrect."));
    }
    Map account = app.accounts.get(cu);
    foreach (var akv in account) {
      if (akv.key.begins("SUP-")) {
        arg["superAccountName"] = akv.value;
      }
    }
    arg["accountName"] = cu;
    arg["isAdmin"] = account["isAdmin"];
    arg["accountAction"] = "update";
    arg["preAuthed"] = "true";
    app.crudAccount(arg);
    Map res = loadStateRequest(arg, request);
    return(res);
  }
  
  shutdownRequest(Map arg, request) Map {
    app.exit();
    return(null);
  }
  
  exit() {
    stopWeb();
  }
  
  stopWeb() {
    if (def(app)) {
      app.webLuiL.o = null;
      app.webStarted.o = false;                
      app.webStartChecked.o = false;
    }
    if (def(vwL.o)) {
      portL.o = null;
      var vw = vwL.o;
      vwL.o = null;
      vw.stop();
    }
  }
  
  handleStartWeb() {
    log.log(lvl, "In handleStartWeb");
    if (def(app)) {
      app.webStarted.o = true;
    } else {
      log.log(lvl, "app is null in handleStartWeb");
    }
  }
  
  checkWeb() {
    String ports = app.configs.get("web", "port");
    if (def(ports)) {
      Int port = Int.new(ports);
      Int oldPort = portL.o;
      if (def(oldPort) && oldPort != port) {
        stopWeb();
      }
    }
  
  }

  startWeb() {
    var e;
    log.log(lvl, "get port");
    String ports = app.configs.get("web", "port");
    if (def(ports)) {
      log.log(lvl, "Port from db " + ports);
      Int port = Int.new(ports);
    } else {
      //do some auto thing
      port = 10000;
      log.log(lvl, "No port from db, " + port);
      app.configs.put("web", "port", port.toString());
    }
    String cerPath = app.assureCert(port);
    portL.o = port;
    Web:Server vw = Web:Server.new();
    vwL.o = vw;
    vw.port = port;
    vw.ssl = true;
    vw.sslPath = cerPath;
    vw.app = self;
    vars {
      System:Thread myThread = System:Thread.new(vw);
    }
    log.log(lvl, "Starting Web");
    myThread.start();
  }
  
  checkGatewayRequest(Map arg, request) {
    log.log(lvl, "In checkGatewayRequest");
    var e;
    Int chkTry = arg["checkGatewayTries"];
    log.log(lvl, "chkTry " + chkTry);
    try {
      app.getSetupForward();
      log.log(lvl, "app.getSetupForward() succeeded");
      //if it's ok, return a it's ok
      Map ret = Map.new();
      ret["action"] = "checkGatewayResponse";
      ret["gatewayMessage"] = "<p>Good news, network appears to be supported, <a href=\"#\">click here for additional verification steps and other information</a></p></p>";
      return(ret);
    } catch (e) {
      log.log(lvl, "app.getSetupForward() failed");
      //if > some number of tries, return a giveup
      if (chkTry > 5) {
        ret = Map.new();
        ret["action"] = "checkGatewayResponse";
        ret["gatewayMessage"] = "<p>Unfortunately, automatic configuration for this network is not supported, <a href=\"#\">it may be possible to configure manually, click here for more information</a></p>";
        return(ret);
      }
    }
    return(null);
  }
  
  linkRequest(Map arg, request) {
    Map ret = Map.new();
    String remoteAddress = request.remoteAddress;
    String secret = arg["secret"];
    Bool ipOk = false;
    app.linkLock.lock();
    try {
      if (app.linkIps.has(remoteAddress)) {
        app.linkSecrets.put(secret);
        ipOk = true;
      }
      app.linkLock.unlock();
    } catch (var e) {
      app.linkLock.unlock();
    }
    if (ipOk) {
      log.log(lvl, "ipOk");
      ret["action"] = "linkResponse";
      ret["test"] = 1 + arg["test"];
      String localAddress = request.localAddress;
      log.log(lvl, "LocalAddress " + localAddress);
      ret["ip"] = localAddress;
      String mac = app.getMacForInterfaceIp(localAddress);
      if (TS.isEmpty(mac)) {
        mac = "unknown";
      }
      Map forward = app.forward;
      if (def(forward)) {
        if (TS.notEmpty(forward["extPort"])) {
          ret["extPort"] = forward["extPort"];
        }
        if (TS.notEmpty(forward["extIP"])) {
          ret["extIP"] = forward["extIP"];
        }
      }
      ret["mac"] = mac;
    } else {
      log.log(lvl, "ipNotOk");
      ret["action"] = "fail";
    }
    return(ret);
  }
  
  linkSecretsRequest(Map arg, request) {
    Map ret = Map.new();
    String remoteAddress = request.remoteAddress;
    var secrets = arg["secrets"];
    Set sset = Set.new();
    foreach (var s in secrets) {
      sset.put(s);
    }
    Bool allOk = false;
    app.linkLock.lock();
    try {
      if (app.linkIps.has(remoteAddress)
        && sset.has(app.linkSecret)) {
        allOk = true;
        app.linkSecretReturned = true;
      }
      app.linkLock.unlock();
    } catch (var e) {
      app.linkLock.unlock();
    }
    if (allOk) {
      log.log(lvl, "allOk");
      ret["action"] = "linkSecretsResponse";
      ret["secret"] = app.linkSecret;
    } else {
      log.log(lvl, "allNotOk");
      ret["action"] = "fail";
    }
    return(ret);
  }
  
  handleCheckLink(request) {
    var e;
    log.log(lvl, "get did header");
    String linkId = request.getInputHeader("linkId");
    Map link = app.links.get(linkId);
    Map send = app.decrypt(link,  request.getInputHeader("send"));
    Map sendBack = Map.new();
    sendBack["sendBackTest"] = send.get("sendTest") + 1;
    Int nowts = Time:Interval.now().seconds;
    Int rlts = send["sendTs"];
    if (nowts - 300 > rlts || nowts + 300 < rlts) {
      throw(Exception.new("sendTs outofrange"));
    }
    sendBack.put("sendBackIp", request.localAddress);
    String remoteAddress = request.remoteAddress;
    Bool foundAddr = false;
    foreach (String ifc in send["ifaces"]) {
      if (remoteAddress == ifc) {
        foundAddr = true;
        break;
      }
    }
    unless(foundAddr) {
      throw(Exception.new("addr notfound"));
    }
    Map forward = app.forward;
    if (def(forward)) {
      if (TS.notEmpty(forward["extPort"])) {
        sendBack["extPort"] = forward["extPort"];
      }
      if (TS.notEmpty(forward["extIP"])) {
        sendBack["extIP"] = forward["extIP"];
      }
    }
    log.log(lvl, "open input");
    IO:Reader reader = request.openInput();
    String buf = String.new(4096);
    Int read = reader.readIntoBuffer(buf);
    while (read > 0) {
      read = reader.readIntoBuffer(buf);
    }
    request.closeInputReader();
    sendBack["sendBackTs"] = Time:Interval.now().seconds;
    request.outputContentType =@ "application/octet-stream";
    request.outputContent = app.encrypt(link, sendBack);
    return(self);
  }
  
    /* SendFile
    String fileName = send["sendFileName"];
    IO:File:Path writePath = app.homeDir.copy();
    writePath.addStep("Ve").addStep(linkName).addStep(fileName);
    if (writePath.file.exists) { writePath.file.delete(); }
    writePath.parent.file.makeDirs();
    log.log(lvl, "open input");
    IO:Reader reader = request.openInput();
    IO:Writer writer = writePath.file.writer.open();
    String buf = String.new(4096);
    Int read = reader.readIntoBuffer(buf);
    while (read > 0) {
      writer.write(buf);
      read = reader.readIntoBuffer(buf);
    }
    request.closeInputReader();
    writer.close();
    */
  
  logoutRequest(Map arg, request) {
    request.deleteSession();
    Map res = Map.new();
    res["action"] = "openAuthResponse";
    String dname = app.configs.get("device", "deviceName");
    if (TS.isEmpty(dname)) {
      dname = "<a></a>";
    } else {
      dname = "<a>" + dname + "-Home</a>";
    }
    res["devMenuHtml"] = dname;
    return(res);
  }
  
  wakeAddrRequest(Map arg, request) Map {
    var e;
    String wakeAddr = arg["wakeAddr"];
    if (TS.notEmpty(wakeAddr)) {
      app.wakeMacAddr(wakeAddr);
    }
    return(null);
  }
  
  authRequest(Map arg, request) Map {
    var e;
    if (app.checkAuth(arg)) {
      request.putSession("account.name", arg["accountName"]);
      Map res = loadStateRequest(arg, request);
    }
    unless(def(res)) {
      res = Map.new();
      res["action"] = "openAuthResponse";
      String dname = app.configs.get("device", "deviceName");
      if (TS.isEmpty(dname)) {
        dname = "<a></a>";
      } else {
        dname = "<a>" + dname + "</a>";
      }
      res["devMenuHtml"] = dname;
    }
    return(res);
  }
  
  handleUpload(request) {
      IO:Reader reader = request.openInput();
      String fline = reader.readBufferLine();
      log.log(lvl, "First line is " + fline);
      log.log(lvl, "last code first line is " + fline.getCode(fline.size - 1));
      log.log(lvl, "second last code first line is " + fline.getCode(fline.size - 2));
      
      log.log(lvl, "last char first line is " + fline.substring(fline.size - 1));
      log.log(lvl, "second last char first line is " + fline.substring(fline.size - 2, fline.size - 1));
      
      log.log(lvl, "upload reader got " + reader.readString());
      request.outputContent = "<html><body>Upload complete, <a href=\"/\">Return to Home</a></body></html>";
      return(null);
  }
  
  
     
     proxyCall(arg, request) Map {
      var e;
      String lurl = request.getSession("proxy.url");
      String pprint = request.getSession("proxy.print");
      String sesskey = request.getSession("proxy.sesskey");
      Web:Client:CertificateManager.acceptedThumbprints.put(pprint);
      try {
        Web:Client client = Web:Client.new();
        client.url = lurl;
        if (TS.notEmpty(sesskey)) {
          log.log(lvl, "using output sesskey " + sesskey);
          client.outputHeaders.put("sesskey", sesskey);
        }
        client.method = "POST";
        client.outputContentType =@ "application/json";
        String payload = Json:Marshaller.new().marshall(arg);
        log.log(lvl, "proxy payload is " + payload);
        for (Int i = 0;i < 3;i++=) {
          IO:Writer writer = client.openOutput();
          String gp = client.certificateThumbprint; //prime -retry on fail
          if (TS.notEmpty(gp)) {
            log.log(lvl, "Got thumprint proxy out " + gp);
          } else {
            log.log(lvl, "No thumprint proxy out");
          }
          if (TS.isEmpty(gp) || gp != pprint) {
            log.log(lvl, "thumbprint mismatch for proxy");
            Map prime = Map.new();
            prime["action"] = "primeRequest";
            String primeLoad = Json:Marshaller.new().marshall(prime);
            writer.write(primeLoad).close();
            res = client.openInput().readString();
            client.close();
            log.log(lvl, "prime complete");
          } else {
            writer.write(payload).close();
            log.log(lvl, "success sending payload");
            break;
          }
        }
        if (i >= 3) {
          client.close();
          log.log(lvl, "proxy failed after retries, alerting");
          throw(Alert.new("Proxy request to remote device failed"));
        }
        
        log.log(lvl, "proxy result");
        String res = client.openInput().readString();
        if (TS.isEmpty(sesskey)) {
          sesskey = client.inputHeaders.get("sesskey");
          log.log(lvl, "sesskey not used in request");
          if (def(sesskey)) {
            log.log(lvl, "put new sesskey into session " + sesskey);
            request.putSession("proxy.sesskey", sesskey);
          }
        }
        log.log(lvl, res);
        client.close();
        
        //foreach (var kv in client.inputHeaders) {
        //  log.log(lvl, "Got inputheader " + kv.key + " " + kv.value);
        //}
        
        Map resm = Json:Unmarshaller.new().unmarshall(res);
        
        Web:Client:CertificateManager.acceptedThumbprints.delete(pprint);
        } catch (e) {
          Web:Client:CertificateManager.acceptedThumbprints.delete(pprint);       
        }
       return(resm);
     }
  
  handleWeb(request) {
    try {
      /*
      String cookie = request.getInputCookie("testcookie");
      request.setOutputCookie("testcookie", "testcval");
      */
      /*String sessval = request.getSession("testsess");
      request.putSession("testsess", "testsessval");*/
      String accountName = request.getSession("account.name");
      String mname = arg.get("action");
      if (TS.isEmpty(accountName)) {
        unless (def(mname) && (mname == "linkRequest" || mname == "linkSecretsRequest" || mname == "macRequest" || mname == "primeRequest" || mname == "gnsRegisterRequest" || mname == "gnsUpdateRequest" || mname == "gnsGetRequest" || mname == "deviceCodeRequest")) {
          request.scriptReturn = authRequest(arg, request);
          return(null);
        }
      }
      //if (def(accountName)) {
        String haction = request.getInputHeader("action");
        if (def(haction) && haction == "checkLink") {
          log.log(lvl, "Got haction checkLink");
          return(handleCheckLink(request));
        }
        /*if (def(haction) && haction == "sendFile") {
          return(handleSendFile(request));
        }*/
      //}
      if (def(accountName)) {
        if (request.uri.ends("upload")) {
          log.log(lvl, "is upload");
          return(handleUpload(request));
        }
        String gp = request.getParameter("getPath");
        if (def(gp)) {
          gp = Encode:Hex.decode(gp);
          log.log(lvl, "got gp" + gp);
          IO:File:Path fpath = IO:File:Path.apNew(gp);
          if (fpath.file.exists) {
            request.outputContentType =@ "application/octet-stream";
            IO:Writer writer = request.openOutput();
            IO:Reader reader = fpath.file.reader.open();
            String buf = String.new(4096);
            Int read = reader.readIntoBuffer(buf);
            while (read > 0) {
              writer.write(buf);
              read = reader.readIntoBuffer(buf);
            }
            request.closeOutputWriter();
            reader.close();
            return(null);
          }
        }
      }
      Map arg = request.scriptArg;
      if (undef(arg)) {
        request.outputContent = app.readHtml("JotUi.html");
        return(null);
      }
      if (undef(mname) || mname.ends("Request")!) {
        throw(Exception.new("Invalid request"));
      }
      Array args = Array.new(2);
      args[0] = arg;
      args[1] = request;
      String purl = request.getSession("proxy.url");
      if (TS.notEmpty(purl) && mname != "proxyEndRequest") {
        log.log(lvl, "In proxy " + purl);
        res = proxyCall(arg, request);
      } else {
        arg["originUI"] = "wui";
        var res = self.invoke(mname, args);
      }
      request.scriptReturn = res;
    } catch (var e) {
      arg = Map.new();
      unless (app.prod) {
        log.log(lvl, "Caught exception during handleWeb");
        if (def(e) && log.will(lvl)) {
          log.log(lvl, "Error was " + e);
        }
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
  
  primeRequest(Map arg, request) {
    Map ret = Map.new();
    ret["action"] = "primeResponse";
    return(ret);
  }
  
    clearLinking() {
      log.log(lvl, "clearLinking");
      app.linkLock.lock();
      try {
        app.linkIps.clear();
        app.linkSecrets.clear();
        app.linkSecret = null;
        app.linkSecretReturned = false;
        app.linkLock.unlock();
      } catch (var eeee) {
        app.linkLock.unlock();
      }
    }
    
    fail(String reason) Map {
      Map res = Map.new();
      res["action"] = "failResponse";
      res["reason"] = reason;
      return(res);
    }
    
    gatewayRequest(Map arg, request) Map {
      var e;
      Map account = app.accounts.get(request.getSession("account.name"));
      if (undef(account) || account.has("isAdmin")! || account["isAdmin"] != "true") {
        throw(Alert.new("Not authorized, only admin accounts can modify gateway settings"));
      }
      if (def(arg) && TS.notEmpty(arg["gatewayEnabled"])) {
        app.configs.put("gateway", "enabled", arg["gatewayEnabled"]);
        app.configs.put("inetListen", "enabled", arg["inetListenEnabled"]);
        if (TS.notEmpty(arg["gnsUrl"]) && TS.notEmpty(arg["gnsName"])
          && TS.notEmpty(arg["gnsPassword"])) {
          Map gnsReg = Map.new();
          gnsReg.put("action", "gnsRegisterRequest");
          gnsReg.put("accountName", arg["gnsName"]);
          gnsReg.put("accountPass", arg["gnsPassword"]);
          gnsReg.put("deviceName", app.configs.get("device", "deviceName"));
          try {
            Web:Client:CertificateManager.validateCertificates = false;
            Web:Client client = Web:Client.new();
            client.url = arg["gnsUrl"];
            client.method = "POST";
            client.outputContentType =@ "application/json";
            String payload = Json:Marshaller.new().marshall(gnsReg);
            client.openOutput().write(payload).close();
            String res = client.openInput().readString();
            client.close();
            Map resMap = Json:Unmarshaller.new().unmarshall(res);
            if (resMap["action"] != "gnsRegisterSuccessResponse") {
              throw(Alert.new("GNS Registration failed"));
            }
            //id, readKey, writeKey
            app.configs.put("gateway", "id", resMap["id"]);
            app.configs.put("gateway", "readKey", resMap["readKey"]);
            app.configs.put("gateway", "writeKey", resMap["writeKey"]);
            Web:Client:CertificateManager.validateCertificates = true;
          } catch (e) {
            Web:Client:CertificateManager.validateCertificates = true;
            throw(e);
          }
          app.configs.put("gateway", "gnsUrl", arg["gnsUrl"]);
          app.clearExternalIpUpdate.o = true;
        }
      }
      if (def(arg) && TS.notEmpty(arg["inetListenEnabled"])) {
        app.configs.put("inetListen", "enabled", arg["inetListenEnabled"]);
      }
      return(loadStateRequest(arg, request));
    }
    
    gnsRequest(Map arg, request) Map {
      Map account = app.accounts.get(request.getSession("account.name"));
      if (undef(account) || account.has("isAdmin")! || account["isAdmin"] != "true") {
        throw(Alert.new("Not authorized, only admin accounts can modify gns settings"));
      }
      if (def(arg) && TS.notEmpty(arg["gnsEnabled"]) && TS.notEmpty(arg["gnsEnabled2"])) {
        if (arg["gnsEnabled"] != arg["gnsEnabled2"]) {
          throw(Alert.new("GNS Enable and Confirm GNS Enable must both be checked or both be unchecked to change setting"))
        }
        app.configs.put("gns", "enabled", arg["gnsEnabled"]);
      }
      return(loadStateRequest(arg, request));
    }
    
    loadStateRequest(Map arg, request) Map {
      Map state = loadState(arg, request);
      state.put("action", "openMenuNamesResponse");
      return(state);
    }
    
    updateStateRequest(Map arg, request) Map {
      Map state = loadState(arg, request);
      return(state);
    }
    
    loadState(Map arg, request) Map {
      var e;
      Map state = Map.new();
      state["linkListHtml"] = "";
      state["hasLinks"] = "false";
      String deviceName = app.configs.get("device", "deviceName");
      String port = app.configs.get("web", "port");
      String gatewayEnabled = app.configs.get("gateway", "enabled");
      String inetListenEnabled = app.configs.get("inetListen", "enabled");
      String gnsEnabled = app.configs.get("gns", "enabled");
      String gnsUrl = app.configs.get("gateway", "gnsUrl");
      
      if (TS.notEmpty(gatewayEnabled)) {
        state["gatewayEnabled"] = gatewayEnabled;
      } else {
        state["gatewayEnabled"] = "false";
      }
      
      if (TS.notEmpty(inetListenEnabled)) {
        state["inetListenEnabled"] = inetListenEnabled;
      } else {
        state["inetListenEnabled"] = "false";
      }
      
      if (TS.notEmpty(gnsEnabled)) {
        state["gnsEnabled"] = gnsEnabled;
      } else {
        state["gnsEnabled"] = "false";
      }
           
      if (TS.notEmpty(gnsUrl)) {
        state["gnsUrl"] = gnsUrl;
      } else {
        state["gnsUrl"] = "";
      }
      
      String cu = request.getSession("account.name");
      if (TS.notEmpty(deviceName)) {
        state["deviceName"] = deviceName;
        if (TS.notEmpty(port)) {
          state["devicePort"] = port;
        } else {
          state["devicePort"] = "";
        }
        state.put("localUrl", "");
        String devMenuHtml = "<a href=\"#\" onclick=\"loadStateRequest();return false;\">" + deviceName + "-Home</a>";
      } else {
        devMenuHtml = "<a href=\"#\" onclick=\"loadStateRequest();return false;\">Home</a>";
      }
      if (TS.notEmpty(cu)) {
        devMenuHtml += "&nbsp;<a href=\"#\" onclick=\"myAccount();return false;\">My Account</a>";
        devMenuHtml += "&nbsp;<a href=\"#\" onclick=\"logoutRequest();return false;\">Logout</a>";
        Map account = app.accounts.get(cu);
        Map allLinks = Map.new();
        foreach (var akv in account) {
          if (akv.key.begins("LINK-")) {
            allLinks.put(akv.key.substring(5), akv.value);
          }
        }
        try {
          String linkListHtml = String.new();
          if (allLinks.isEmpty!) {
            state["hasLinks"] = "true";
            linkListHtml += "<p>Click on a link below to access it.</p>";
            //linkListHtml += "<ul>";
            foreach (var lkv in allLinks) {
              String lil = "<a href=\"#\" onclick=\"openLinkRequest('";
                lil += lkv.value += "');return false;\">" += lkv.key += "</a>";
                //linkListHtml += "<li>" += lil += "</li>";
                linkListHtml += "<p>" += lil += "</p>";
            }
            //linkListHtml += "</ul>";
            state["linkListHtml"] = linkListHtml;
          }
        } catch (e) {
          log.log(lvl, "Failed in linkRequest links");
        }
      }
      state.put("devMenuHtml", devMenuHtml);
      try {
        Array subAccounts = app.getSubAccounts(request.getSession("account.name"));
        String accountsHtml = String.new();
        if (subAccounts.isEmpty!) {
          state["hasAccounts"] = "true";
          accountsHtml += "<p>Click on an account below to manage it.</p>";
          foreach (var ac in subAccounts) {
            String al = "<a href=\"#\" onclick=\"openAccountRequest('";
              al += ac += "');return false;\">" += ac += "</a>";
              accountsHtml += "<p>" += al += "</p>";
          }
          state["accountsHtml"] = accountsHtml;
        } else {
          state["hasAccounts"] = false;
          state["accountsHtml"] = "";
        }
      } catch (e) {
        log.log(lvl, "Failed in accountsHtml");
      }
      return(state);
    }
    
    openAccountRequest(Map arg, request) Map {
      Map res = Map.new();
      res["action"] = "openAccountResponse";
      res["accountNameHtml"] = "<p><b>" + arg["accountName"] + "</b></p>";
      Map account = app.accounts.get(arg["accountName"]);
      unless (account.has("SUP-" + request.getSession("account.name"))) {
        throw(Alert.new("This account cannot be managed by the currently logged in user"));
      }
      res["accountName"] = arg["accountName"];
      res["isAdmin"] = account["isAdmin"];
      //check account exists and current login can manage
      return(res);
    }
    
    openLinkRequest(Map arg, request) Map {
      String linkId = arg["linkId"];
      Map link = app.links.get(linkId);
      String accountName = request.getSession("account.name");
      if (TS.isEmpty(accountName) || link["accountName"] != accountName) {
        throw(Exception.new("link not owned by account"));
      }
      String linkName = link["name"];
      Map res = Map.new();
      if (def(link) && link.has("mac")) {
        String mac = link["mac"];
      } else {
        mac = "unknown";
      }
      String linkWake = "<a href=\"#\" onclick=\"wakeMac('" + mac + "');return false;\">Wakeup " + linkName + "</a>";
      res.put("linkWakeHtml", linkWake);
      res.put("linkName", linkName);
      res.put("linkId", linkId);
      res.put("linkNameHtml", "<p>" + linkName + "</p>");
      res.put("action", "openLinkResponse");
      String linkGoTo = "<p><a href=\"#\" onclick=\"goToLink('" + linkId + "');return false;\">Open " + linkName + "</a></p>";
      res.put("linkGoToHtml", linkGoTo);
      String cancelLinkGoTo = "<p><a href=\"#\" onclick=\"goToLink('" + linkId + "');return false;\">Cancel go to " + linkName + "</a></p>";
      res.put("cancelLinkGoToHtml", cancelLinkGoTo);
      return(res);
    }
    
    deleteLinkRequest(Map arg, request) Map {
      var e;
      String linkId = arg["linkId"];
      String linkName = arg["linkName"];
      if (def(linkId) && def(linkName)) { 
        Map account = app.accounts.get(request.getSession("account.name"));
        String lkey = "LINK-" + linkName;
        if (def(account) && account.has(lkey) && account.get(lkey) == linkId) {
          app.links.delete(linkId);
          app.accounts.delete(account["accountName"], lkey);
        }
      }
      return(loadStateRequest(arg, request));
    }
    
    relink(Map link) {
      log.log(lvl, "DOING RELINK");
      Map lidReq = Map.new();
      lidReq.put("rtype", "relinkrq");
      lidReq.put("linkId", link["id"]);
      String lidJson = Json:Marshaller.new().marshall(lidReq);
      NetMulti nm = NetMulti.new();
      nm.port = 1968;
      nm.group = "239.192.98.99";
      nm.open();
      nm.outputContent = lidJson;
      nm.outputContent = lidJson;
      nm.close();
    }
    
    goToLinkRequest(Map arg, request) Map {
      var e;
      Map res;
      String linkId = arg["linkId"];
      Map link = app.links.get(linkId);
      if (undef(link) || link.isEmpty) {
        throw(Exception.new("no such link"));
      }
      if (link["accountName"] != request.getSession("account.name")) {
        throw(Exception.new("bad account for link"));
      }
      try {
        res = goToLinkRequestInner(link, arg, request);
      } catch (e) {
          relink(link);
          //Time:Sleep.sleepMilliseconds(100);
      }
      link = app.links.get(linkId);
      return(res);
    }
    
    goToLinkRequestInner(Map link, Map arg, request) Map {
      var e;
      String linkId = arg["linkId"];
      log.log(lvl, "goToLinkRequestInner " + linkId);
      String ip = link["ip"];
      String port = link["port"];
      String print = link["print"];
      if (TS.isEmpty(ip) || TS.isEmpty(port) || TS.isEmpty(print)) {
        throw(Exception.new("Missing ip, port, or print in gotolink"));
      }
      String surl = "https://" + ip + ":" + port;
      Web:Client:CertificateManager.acceptedThumbprints.put(print);
      try {
        Web:Client client = Web:Client.new();
        client.url = surl;
        client.outputHeaders["action"] = "checkLink";
        client.outputHeaders["linkId"] = linkId;
        Map send = Map.new();
        send.put("sendTest", System:Random.getInt(Int.new(), 2000000000));
        send.put("sendTs", Time:Interval.now().seconds);
        send.put("ifaces", app.ifaces);
        client.outputHeaders["send"] = app.encrypt(link, send);
        client.method = "POST";
        client.outputContentType =@ "application/octet-stream";
        
        try {
          IO:Writer writer = client.openOutput();
          writer.write("hola");
          client.closeOutput();
        } catch (e) {
          log.log(lvl, "Failed during sendfile");
          if (def(client) && def(writer)) {
            client.closeOutput();
          }
          throw(e);
        }
        
        log.log(lvl, "result");
        String res = client.openInput().readString();
        log.log(lvl, res);
        Map sendBack = app.decrypt(link ,res);
        if (sendBack["sendBackTest"] != send.get("sendTest") + 1) {
          throw(Exception.new("sendBack badincr"));
        }
        Int rlts = sendBack["sendBackTs"];
        Int nowts = Time:Interval.now().seconds;
        if (nowts - 300 > rlts || nowts + 300 < rlts) {
          throw(Exception.new("sendBack badsbts"));
        }
        if (client.certificateThumbprint != print) {
          throw(Exception.new("sendBack bad print"));
        }
        client.close();
        client = null;
        Web:Client:CertificateManager.acceptedThumbprints.delete(print);
        //upd link here
        if (TS.notEmpty(sendBack["extPort"]) &&
            TS.notEmpty(sendBack["extIP"])) {
          if (TS.isEmpty(link["extPort"]) || sendBack.get("extPort")
              != link.get("extPort")) {
            link.put("extPort", sendBack["extPort"]);
            app.links.put(linkId, "extPort", sendBack["extPort"]);
          }
          if (TS.isEmpty(link["extIP"]) || sendBack.get("extIP")
              != link.get("extIP")) {
            link.put("extIP", sendBack["extIP"]);
            app.links.put(linkId, "extIP", sendBack["extIP"]);
          }
        }
      } catch (e) {
        Web:Client:CertificateManager.acceptedThumbprints.delete(print);
        if (client != null) {
          client.close();
          client = null;
        }
        throw(e);
      }
      request.putSession("proxy.url", surl);
      request.putSession("proxy.print", print);
      Map resp = Map.new();
      resp["action"] = "proxyStartResponse";
      return(resp);
    }
    
    proxyEndRequest(Map arg, request) Map {
      request.putSession("proxy.url", "");
      request.putSession("proxy.print", "");
      request.putSession("proxy.sesskey", "");
      Map resp = Map.new();
      resp["action"] = "proxyEndResponse";
      return(resp);
    }
    
    localBrowseRequest(Map arg, request) Map {
      Encode:Hex hex = Encode:Hex.new();
      Map ret = Map.new();
      String path = arg["path"];
      if (TS.isEmpty(path)) {
        dirFile = app.homeDir.file;
      } else {
        File dirFile = File.apNew(hex.decode(path));
      }
      String dirListHtml = String.new();
      if (dirFile.exists) {
        dirListHtml += "<p>Listing for " += dirFile.path.toString() += "</p>";
        IO:File:Path parent = dirFile.path.parent;
        if (def(parent) && TS.notEmpty(parent.toString())) {
        dirListHtml += "<p><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(parent.toString()) += "');return false;\">DIR  .. </a></p>";
        }
        if (dirFile.isDir) {
          var dit = dirFile.iterator;
          dit.open();
          while (dit.hasNext) {
            File entry = dit.next;
            Path p = entry.path;
            if (entry.isDirectory) {
              String fdurl = TS.quote + "#" + TS.quote;
              String jsCall = "localBrowseRequest";
              String fd = "DIR  ";
            } else {
              fdurl = TS.quote + p.name + "?getPath=" + Encode:Hex.encode(p.toString()) + TS.quote;
              jsCall = "setPathToSend";
              fd = "FILE ";
            }
            dirListHtml += "<p><a href=" + fdurl + " onclick=\"return " += jsCall += "('"
          += hex.encode(p.toString()) += "');\">" += fd += p.name += "</a></p>";
          }
          dit.close();
        }
      }
      ret.put("action", "localBrowseResponse");
      ret.put("dirListHtml", dirListHtml);
      return(ret);
    }
    
}

use class Ve:DisLui {
  new(Ve:App _app) self {
    vars {
      Ve:App app = _app;
      System:Thread myThread;
      OLocker run = OLocker.new(true);
      Map found = Map.new();
      NetMulti nm;
      IO:Log log = app.log;
      Int lvl = app.shlvl;
    }
    myThread = System:Thread.new(self);
    myThread.start();
  }
  
  main() {
    var e;
    while (run.o) {
      try {
        innerMain();
      } catch (e) {
        log.log(lvl, "DisLui main Caught exception");
        if (def(e)) {
          log.log(lvl, "Error was " + e);
        }
        if (def(nm)) {
          try { nm.close(); } catch (e) { }
          nm = null;
        }
        try {
          Time:Sleep.sleepMilliseconds(500);
        } catch (e) { }
      }
    }
  }
  
  exit() {
    run.o = false;
  }
  
  updateNameService() {
    var e;
    try {
      String gatewayEnabled = app.configs.get("gateway", "enabled");
      //gnsUpdate goes here
      String duckDomain = "";
      String duckToken = "";
      if (TS.notEmpty(gatewayEnabled) && gatewayEnabled == "true") {
        if (TS.notEmpty(duckDomain) && TS.notEmpty(duckToken)) {
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
        String gwid = app.configs.get("gateway", "id");
        String gwkey = app.configs.get("gateway", "writeKey");
        String gwurl = app.configs.get("gateway", "gnsUrl");
        Map forward = app.forward;
        if (TS.notEmpty(gwid) && TS.notEmpty(gwkey) && TS.notEmpty(gwurl) && def(forward) && TS.notEmpty(forward["extIP"]) && TS.notEmpty(forward["extPort"])) {
          String extUrl = "https://" + forward["extIP"] + ":" + forward["extPort"];
          Map gnsReq = Map.new();
          gnsReq.put("action", "gnsUpdateRequest");
          gnsReq.put("id", gwid);
          gnsReq.put("writeKey", gwkey);
          gnsReq.put("url", extUrl);
          try {
            Web:Client:CertificateManager.validateCertificates = false;
            client = Web:Client.new();
            client.url = gwurl;
            client.method = "POST";
            client.outputContentType =@ "application/json";
            String payload = Json:Marshaller.new().marshall(gnsReq);
            client.openOutput().write(payload).close();
            res = client.openInput().readString();
            client.close();
            Map resMap = Json:Unmarshaller.new().unmarshall(res);
            if (resMap["action"] != "gnsUpdateSuccessResponse") {
              log.log(lvl, "gns update failed");
              throw(Exception.new("GNS Update failed"));
            }
            log.log(lvl, "gns update success");
            Web:Client:CertificateManager.validateCertificates = true;
          } catch (e) {
            Web:Client:CertificateManager.validateCertificates = true;
            throw(e);
          }
        }
      }
    } catch (e) {
      if (def(client)) {
        Web:Client:CertificateManager.validateCertificates = true;
        client.close();
        client = null;
      }
      throw(e);
    }
  }
  
  updateExternalAccess() {
    var e;
    vars {
      String lastIp;
      Int checkInterval = 1200;
      //Int checkInterval = 10;
      Int lastCheck;
    }
    if (app.clearExternalIpUpdate.o) {
      lastIp = null;
      lastCheck = null;
      app.clearExternalIpUpdate.o = false;
    }
    try {
      Int nowts = Time:Interval.now().seconds;
      if (undef(lastCheck) || nowts - lastCheck > checkInterval) {
        String externalIp = app.getExternalIP();
        lastCheck = nowts;
        if (TS.notEmpty(externalIp)) {
          lastIp = externalIp;
          try {
            app.getSetupForward();
          } catch (e) {
            e = Exception.new("failed fwd");
          }
          try {
            updateNameService();
          } catch (e) {
            e = Exception.new("failed uns");
          }
        } else {
        }
      } else {
      }
    } catch (e) {
      e = Exception.new("failed outer");
    }
    if (def(e)) {
      log.log(lvl, "Caught except during updateExternalAccess, is " + e.toString());
      checkInterval = 20;
    }
  }
  
  checkWebPrint() {
    unless (app.webStarted.o) {
      return(null);
    }
    if (app.webStartChecked.o) {
      return(null);
    }
    log.log(lvl, "Doing checkWebPrint");
    var e;
    //RETRY
    try {
      Web:Client:CertificateManager.validateCertificates = false;
      String print = app.configs.get("web", "print");
      String port = app.configs.get("web", "port");
      Web:Client client = Web:Client.new();
      client.url = "https://127.0.0.1:" + port + "/";
      client.method = "POST";
      client.outputContentType =@ "application/json";
      String payload = Json:Marshaller.new().marshall(app.codeRequest);
      log.log(lvl, "payload is " + payload);
      client.openOutput().write(payload).close();
      
      log.log(lvl, "result");
      String res = client.openInput().readString();
      String gotPrint = client.certificateThumbprint;
      client.close();
      client = null;
      Map resMap = Json:Unmarshaller.new().unmarshall(res);
      if (TS.isEmpty(resMap["action"]) || resMap["action"] != "deviceCodeSuccessResponse") {
        throw(Exception.new("bad code in startWebInner"));
      }
      Web:Client:CertificateManager.validateCertificates = true;
      if (TS.isEmpty(gotPrint) || TS.isEmpty(res)) {
        throw(Exception.new("Got empty res or print in startWebInner"));
      }
      ("Succeeded in handleStartWeb").print();
      app.webStartChecked.o = true;
    } catch (e) {
      Web:Client:CertificateManager.validateCertificates = true;
      if (def(client)) {
        client.close();
        client = null;
      }
      log.log(lvl, "got exception in handleStartWeb ");
      try { Time:Sleep.sleepSeconds(1); } catch (e) { }
    }
    if (TS.notEmpty(gotPrint) && (TS.isEmpty(print) || 
         print != gotPrint)) {
      log.log(lvl, "New Cert thumbprint " + gotPrint);
      app.configs.put("web", "print", gotPrint);
    } else {
      log.log(lvl, "Existing Cert thumbprint correct " + print);
    }
  }
  
  innerMain() {
    checkWebPrint();
    String inetListenEnabled = app.configs.get("inetListen", "enabled");
    if (TS.notEmpty(inetListenEnabled) && inetListenEnabled == "true") {
      updateExternalAccess();
    } else {
      //app.clearForward();
    }
    if (undef(nm)) {
      nm = NetMulti.new();
      nm.port = 1968;
      nm.group = "239.192.98.99";
      nm.timeout = 2000;
      nm.open();
    }
    Int disTTL = 30;
    Int lastSec = Time:Interval.now().seconds;
    if (undef(lastGCSec) || 
        Time:Interval.now().seconds - lastGCSec >= disTTL) {
      vars {
        Int lastGCSec = lastSec;
      }
      for (iter = found.iterator;iter.hasNext;;) {
        kv = iter.next;
        fips = kv.value;
        for (var fiter = fips.iterator;fiter.hasNext;;) {
          var fipkv = fiter.next;
          if (lastSec - fipkv.value > disTTL) {
            fiter.delete();
          }
        }
        if (fips.isEmpty) {
          iter.delete();
        }
      }
    }
    String res = nm.inputContent;
    String inaddr = nm.inputAddress;
    if (def(res) && def(inaddr)) {
      Map fips = found.get(res);
      if (undef(fips)) {
        fips = Map.new();
        found.put(res, fips);
      }
      fips.put(inaddr, lastSec);
    } else {
      if (Time:Interval.now().seconds - lastSec < 1) {
       //? did not make it to timeout, but also did not find anything
       //sleep a bit to avoid vicious cycling
       Time:Sleep.sleepMilliseconds(500);
      }
    }
    String print = app.configs.get("web", "print");
    String port = app.configs.get("web", "port");
    for (var iter = found.iterator;iter.hasNext;;) {
      var kv = iter.next;
      try {
        Map lidRes = Json:Unmarshaller.new().unmarshall(kv.key);
        fips = kv.value;
        if (def(lidRes["rtype"])) {
          if (lidRes["rtype"] == "relinkrq") {
            log.log(lvl, "in relinkrq");
            String linkId = lidRes["linkId"];
            Map rlink = app.links.get(linkId);
            if (def(rlink) && rlink.isEmpty!) {
              Map lidReq = Map.new();
              lidReq.put("print", print);
              lidReq.put("port", port);
              lidReq.put("linkId", linkId);
              lidReq.put("relinkTs", Time:Interval.now().seconds);
              String lrs = app.encrypt(rlink, lidReq);
              lidReq = Map.new();
              lidReq.put("linkId", linkId);
              lidReq.put("link", lrs);
              lidReq.put("rtype", "relinkrs");
              String lidJson = Json:Marshaller.new().marshall(lidReq);
              nm.outputContent = lidJson;
              nm.outputContent = lidJson;
            }
            iter.delete();
          } elif (lidRes["rtype"] == "relinkrs") {
            log.log(lvl, "in relinkrs");
            linkId = lidRes["linkId"];
            Map link = app.links.get(linkId);
            if (def(link) && link.isEmpty!) {
              Map inRes = app.decrypt(link, lidRes["link"]);
              linkId = inRes["linkId"];
              Int rlts = inRes["relinkTs"];
              Int nowts = Time:Interval.now().seconds;
              if (nowts - 300 > rlts || nowts + 300 < rlts) {
                throw(Exception.new("relinkTs bad"));
              }
              String useIp;
              foreach (fipkv in fips) {
                useIp = fipkv.key;
              }
              if (inRes["print"] != print) { //to avoid updating myself
                app.links.put(linkId, "ip", useIp);
                app.links.put(linkId, "port", inRes["port"]);
                app.links.put(linkId, "print", inRes["print"]);
              }
            }
            iter.delete()
          }
        }
      } catch (var e) { 
        log.log(lvl, "Got exception during dislui innermain " + e);
        iter.delete();  
      }
    }
  }
}

use class Ve:NanLui {
  new(Ve:App _app) self {
    vars {
      Ve:App app = _app;
      System:Thread myThread;
      OLocker run = OLocker.new(true);
      Int wuiStarts = 0;
      IO:Log log = app.log;
      Int lvl = app.shlvl;
    }
    myThread = System:Thread.new(self);
    myThread.start();
  }
  
  main() {
    var e;
    while (run.o) {
      try {
        innerMain();
        try {
          Time:Sleep.sleepMilliseconds(500);
        } catch (e) { }
      } catch (e) {
        log.log(lvl, "NanLui main Caught exception");
        if (def(e)) {
          log.log(lvl, "Error was " + e);
        }
        try {
          Time:Sleep.sleepMilliseconds(500);
        } catch (e) { }
      }
    }
  }
  
  exit() {
    run.o = false;
  }
  
  incPort() {
    
    String ports = app.configs.get("web", "port");
    if (undef(ports)) {
      ports = "10000";
    }
    Int port = Int.new(ports);
    port += 2;
    app.configs.put("web", "port", port.toString());
    app.configs.delete("web", "print");
  
  }
  
  handleStartGet() Bool {
    Bool startRes = false;
    String dn = app.configs.get("device", "deviceName");
    String se = app.configs.get("startup", "enabled");
    if (TS.isEmpty(se)) {
      Bool doStart = false;
    } else {
      doStart = Bool.new(se);
    }
    if (TS.isEmpty(dn)) {
      dn = "Machine Name";
      app.configs.put("device", "deviceName", dn);
    }
    if (doStart) {
      //check if already running, if so, do exit (just ui does not get here)
      //if doing lui, set the startSvcs to no
      //if not doing ui (no lui), exit if there is no configuration
      Bool res = app.checkWebLuiUp();
      if (res) {
        startRes = false;
        run.o = false;
        if (def(app.luiL) && def(app.luiL.o)) {
          log.log(lvl, "Doing ui, just setting startServices");
          app.luiL.o.startSvcs.o = false;
          if (def(app.disLuiL) && def(app.disLuiL.o) 
              && def(app.disLuiL.o.run)) {
            app.disLuiL.o.run.o = false;
          }
        } else {
          log.log(lvl, "No lui, exiting");
          app.exit();
        }
      } else {
        startRes = true;
      }
    }
    return(startRes);
  }
  
  innerMain() {
    if (undef(app.webLuiL.o) || (def(app.webLuiL.o.myThread) &&
      app.webLuiL.o.myThread.started.o && app.webLuiL.o.myThread.finished.o)) {
      if (run.o) {
         if (undef(handleStart)) {
          Bool handleStart = self.handleStart;
         }
         if (handleStart) {
           wuiStarts++=;
           if (wuiStarts > 5) {
             wuiStarts.setValue(0);
             incPort();
           }
          log.log(lvl, "Start webLui");
          app.webLuiL.o = Ve:WebLui.new(app);
          app.webLuiL.o.startWeb();
        }
      }
    }
    if (undef(app.disLuiL.o) || (def(app.disLuiL.o.myThread) &&
      app.disLuiL.o.myThread.started.o && app.disLuiL.o.myThread.finished.o)) {
        if (run.o) {
           if (undef(handleStart)) {
            handleStart = self.handleStart;
           }
           if (handleStart) {
             log.log(lvl, "Start disLui");
             app.disLuiL.o = Ve:DisLui.new(app);
           }
        }
     }
     if (def(app.webLuiL.o)) {
      app.webLuiL.o.checkWeb();
    }
  }
}

use class Ve:Lui {

  new() self {
        properties {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
          Ve:App app;
          IO:Log log = IO:Log.new();
          Int lvl = log.info;
        }
    }
    
    main() {
      Array args = System:Process.new().args;
      
      //basic, common seutp stuff
      Web:Client:CertificateManager.validateHosts = false;
      
      if (args.length > 0) {
        String mode = args[0]; //ui, svc, both, [absent]
        log.log(lvl, "mode " + mode);
      } else {
        log.log(lvl, "mode empty");
      }
      //mode = "test";
      vars {
        OLocker startSvcs = OLocker.new(true);
        String startMode = mode;
      }
      if (TS.isEmpty(mode) || mode == "ui" || mode == "all") {
        if (TS.isEmpty(mode) || mode == "ui") {
          startSvcs.o = false;
        }
        if (args.length > 1) {
          vars {
            String useGateway = args[1]; //only not prod
          }
        }
        webr = WeBr.new();
        webr.webHandler = self;
        webr.height = 450;
        webr.width = 320;
        webr.content = Ve:App.new().readHtml("JotUi.html");
        webr.setup();
      } elif (TS.notEmpty(mode) && mode == "test") {
        Ve:LuiTest.new().main(); //only not prod
      } elif (TS.notEmpty(mode) && mode == "bootsetup") {
        app = Ve:App.new();
        app.enableBootTask();
        app.exit();
      } elif (TS.notEmpty(mode) && mode == "setup") {
        app = Ve:App.new();
        if (TS.isEmpty(args[1])) {
          ("DeviceName required").print();
          app.exit();
        }
        if (TS.isEmpty(args[2])) {
          ("AccountName required").print();
          app.exit();
        }
        if (TS.isEmpty(args[3])) {
          ("Account Password required").print();
          app.exit();
        }
        if (TS.isEmpty(args[4]) || args[3] != args[4]) {
          ("Confirm Password required, and must match Account Password").print();
          app.exit();
        }
        Map conf = Map.new();
        conf["deviceName"] = args[1];
        conf["accountName"] = args[2];
        conf["accountPass"] = args[3];
        conf["originUI"] = "lui";
        app.setup(conf);
        app.exit();
      } elif (TS.notEmpty(mode) && mode == "links") {
        app = Ve:App.new();
        app.printLinks();
        app.exit();
      } elif (TS.notEmpty(mode) && mode == "noop") {
      } else {
        //is svc
        checkStartApp();
      }
    }
    
    checkStartApp() {
      if (undef(app)) {
         app = Ve:App.new();
         //prime the db, if it's the first run, make sure the db is made here
         //before other threads start
         app.configs.get("boo","hiss");
         app.luiL.o = self;
         log = app.log;
         lvl = app.shlvl;
         vars {
           Ve:WebLui webLui = Ve:WebLui.new(app); //my instance, for shared
           //ui logic
         }
         if (startSvcs.o) {
           log.log(lvl, "Start nanLui");
           app.nanLuiL.o = Ve:NanLui.new(app);
         } else {
           //log.log(lvl, "Doing startBackground");
           //app.startBackground();  //TODO scheduling
           log.log(lvl, "Not Doing startBackground");
         }
       }
     }
     
     initWeb() {
       log.log(lvl, "In initWeb");
       checkStartApp();
     }
      
    handleWeb(request) {
        try {
            Map arg = request.scriptArg;
            String mname = arg.get("action");
            if (undef(mname) || mname.ends("Request")!) {
              throw(Exception.new("Invalid request"));
            }
            String accountName = request.getSession("account.name");
            if (TS.isEmpty(accountName)) {
              unless (def(mname) && (mname == "linkRequest" || mname == "linkSecretsRequest" || mname == "macRequest" || mname == "primeRequest" || mname == "gnsRegisterRequest" || mname == "gnsUpdateRequest" || mname == "gnsGetRequest" || mname == "deviceCodeRequest")) {
                Map accts = app.accounts.get();
                if (undef(accts) || accts.isEmpty) {
                  if (TS.notEmpty(mname) && mname == "createSubAccountRequest") {
                    arg.delete("superAccountName");
                    arg["isAdmin"] = "true";
                    arg["accountAction"] = "create";
                    arg["preAuthed"] = "false";
                    app.crudAccount(arg);
                    //will auth it, as user/acct is what was passed
                    request.scriptReturn = webLui.authRequest(arg, request);
                  } else {
                    res = Map.new();
                    res["action"] = "openAccountsResponse";
                    request.scriptReturn = res;
                  }
                  return(null);
                } else {
                  request.scriptReturn = webLui.authRequest(arg, request);
                }
                return(null);
              }
            }
            Array args = Array.new(2);
            args[0] = arg;
            args[1] = request;
            String purl = request.getSession("proxy.url");
            if (TS.notEmpty(purl) && mname != "proxyEndRequest") {
              log.log(lvl, "In proxy " + purl);
              res = webLui.proxyCall(arg, request);
            } else {
              arg["originUI"] = "lui";
              if (self.can(mname, args.length)) {
                var res = self.invoke(mname, args);
              } else {
                res = webLui.invoke(mname, args);
              }
            }
            request.scriptReturn = res;
        } catch (var e) {
           arg = Map.new(); 
           unless (app.prod) {
              log.log(lvl, "Caught exception during handleWeb");
              if (def(e)) {
                log.log(lvl, "Error was " + e);
              }
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
      app.exit();
      //var e;
      //if (def(app.luiL) && def(app.luiL.o)) {
      //  try { app.luiL.o.exit(); } catch (e) { }
      //}
      return(null);
    }
    
    exit() {
      webr.close();
    }
    
    processExit() {
      webr.exit();
    }
   
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

use Db:Firebird:Database as FbDb;
class Db:Firebird:Database(DbDb) {

  new(String _db) self {
    super.new(_db);
    emit(cs) {
    """
      bevi_conn = new FbConnection(bevp_db.bems_toCsString());
    """
    }
  }

  createDatabase() self {
    emit(cs) {
      """
      FbConnection.CreateDatabase(bevp_db.bems_toCsString());
      """
    }
  }
  
  getStatement(String _stmt) DbSt {
    DbSt st = super.getStatement(_stmt);
    emit(cs) {
    """
    if (bevi_trans == null) {
      bevl_st.bevi_cmd = new FbCommand(
        beva__stmt.bems_toCsString(),
        (FbConnection)bevi_conn
        );
     } else {
       bevl_st.bevi_cmd = new FbCommand(
        beva__stmt.bems_toCsString(),
        (FbConnection)bevi_conn,
        (FbTransaction)bevi_trans
        );
     }
     """
     }
     return(st);
   }

}


use Db:Maria:Database as MyDb;
final class Db:Maria:Database(DbDb) {

  open() self {
    ifEmit(jv) {
      driverOpen("org.mariadb.jdbc.Driver");
    }
  }
  
}

emit(jv) {
"""
import java.sql.*;
"""
}
use Db:Relational:Database as DbDb;
class Db:Relational:Database {

emit(cs) {
"""
public DbConnection bevi_conn = null;
public DbTransaction bevi_trans = null;
"""
}
emit(jv) {
"""
public Connection bevi_conn = null;
public Connection bevi_trans = null;
"""
}

  new(String _db) self {
    properties {
      String db = _db;
    }
  }
  
  createDatabase() self {
    if (true) {
      throw(Exception.new("No Capability to create database"));
    }
    return(self);
  }
  
  open() self {
    emit(cs) {
    """
      bevi_conn.Open();
    """
    }
    emit(jv) {
    """
      bevi_conn = DriverManager.getConnection(
        bevp_db.bems_toJvString()
        );
    """
    }
  }
  
  driverOpen(String driver) self {
    ifEmit(cs) {
      open();
    }
    emit(jv) {
    """
      Class.forName(beva_driver.bems_toJvString());
      bevi_conn = DriverManager.getConnection(
        bevp_db.bems_toJvString()
        );
    """
    }
  }

  begin() self {
    emit(cs) {
    """
    if (bevi_trans != null) {
    """
    }
    emit(jv) {
    """
    if (bevi_trans != null) {
    """
    }
    ifEmit(cs) {
    throw(Exception.new("Transaction in progress, cannot begin until " +
      "existing transaction is committed or rolled back"));
    }
    ifEmit(jv) {
    throw(Exception.new("Transaction in progress, cannot begin until " +
      "existing transaction is committed or rolled back"));
    }
    emit(cs) {
    """
    }
    bevi_trans = bevi_conn.BeginTransaction();
    """
    }
    emit(jv) {
    """
    }
    bevi_conn.setAutoCommit(false);
    bevi_trans = bevi_conn;
    """
    }
    }
    
    commit() self {
      emit(cs) {
      """
      try {
      bevi_trans.Commit();
      } finally {
      bevi_trans = null;
      }
      """
      }
      emit(jv) {
      """
      try {
      bevi_conn.commit();
      } finally {
      bevi_trans = null;
      bevi_conn.setAutoCommit(false);
      }
      """
      }
    }
    
    rollback() self {
      emit(cs) {
      """
      try {
      bevi_trans.Rollback();
      } finally {
      bevi_trans = null;
      }
      """
      }
      emit(jv) {
      """
      try {
      bevi_conn.rollback();
      } finally {
      bevi_trans = null;
      }
      """
      }
    }
  
  close() self {
    emit(cs) {
    """
      bevi_conn.Close();
    """
    }
    emit(jv) {
    """
      bevi_conn.close();
    """
    }
  }
  
  getStatement(String _stmt) DbSt {
    DbSt st = DbSt.new(_stmt, self);
    emit(jv) {
    """
    bevl_st.bevi_stmt = bevi_conn.createStatement();
    """
    }
    return(st);
  }
  
  execute(String stmt) DbSt {
    DbSt fbstmt = getStatement(stmt);
    return(fbstmt.execute());
  }
  
  executeQuery(String stmt) DbSt {
    DbSt fbstmt = getStatement(stmt);
    return(fbstmt.executeQuery());
  }

}

use Db:Relational:Statement as DbSt;
class Db:Relational:Statement {

emit(cs) {
"""
public DbCommand bevi_cmd = null;
public DbDataReader bevi_reader = null;
"""
}

emit(jv) {
"""
public Statement bevi_stmt = null;
public ResultSet bevi_res = null;
"""
}
  
   new(String _stmt, DbDb _db) self {
     properties {
        String stmt = _stmt;
        DbDb db = _db;
        Bool nextWaiting = false;
      }
   }
        
   execute() self {
     emit(cs) {
     """
     bevi_cmd.ExecuteNonQuery();
     """
     }
     emit(jv) {
     """
     bevi_stmt.executeUpdate(bevp_stmt.bems_toJvString());
     """
     }
   }
   
   executeQuery() self {
     emit(cs) {
     """
     bevi_reader = bevi_cmd.ExecuteReader();
     """
     }
     emit(jv) {
     """
     bevi_res = bevi_stmt.executeQuery(bevp_stmt.bems_toJvString());
     """
     }
   }
   
   hasNextGet() Bool {
     if (nextWaiting) {
      return(true);
     }
     emit(cs) {
     """
     if (bevi_reader.Read()) {
     """
     }
     emit(jv) {
     """
     if (bevi_res.next()) {
     """
     }
     nextWaiting = true;
     emit(cs) {
     """
     }
     """
     }
     emit(jv) {
     """
     }
     """
     }
     return(nextWaiting);
   }
   
   nextGet() self {
     if (nextWaiting) {
       nextWaiting = false;
       return(self);
     }
     if (self.hasNext) {
      return(self);
     }
     return(null);
   }
   
   //get col as string for current row
   getString(Int col) String {
      String res;
      emit(cs) {
      """
      bevl_res = new BEC_4_6_TextString(bevi_reader[beva_col.bevi_int].ToString());
      """
      }
      emit(jv) {
      """
      bevl_res = new BEC_4_6_TextString(bevi_res.getString(beva_col.bevi_int + 1));
      """
      }
      return(res);
   }
   
   getInt(Int col) Int {
      Int res;
      emit(cs) {
      """
      bevl_res = new BEC_4_3_MathInt((int)bevi_reader[beva_col.bevi_int]);
      """
      }
      emit(jv) {
      """
      bevl_res = new BEC_4_3_MathInt(bevi_res.getInt(beva_col.bevi_int + 1));
      """
      }
      return(res);
   }
   
   iteratorGet() {
    //to support foreach
    return(self);
   }
}

emit(jv) {
"""
import java.io.*;
import java.net.*;
"""
}
class Ve:WebTest(Test:Assertions) {

  main() {
      //discoverTest();
      //testWebServer();
  } 
  
  testWebServer() {
    Web:Server vw = Web:Server.new();
    vw.port = 10000;
    vw.ssl = true;
    vw.app = TestWeb.new();
    System:Thread vwt = System:Thread.new(vw);
    vwt.start();
  }
  
  discoverTest() {
    
      emit(jv) {
      """
      
      String MY_DISCOVER = "NAME PORT JV";
                        

      InetAddress multicastAddress = InetAddress.getByName("239.192.98.99");
      final int port = 1968;
      MulticastSocket socket = new MulticastSocket(port);
      socket.setReuseAddress(true);
      socket.setSoTimeout(130000);
      socket.joinGroup(multicastAddress);
      byte[] requestMessage = MY_DISCOVER.getBytes("UTF-8");
      DatagramPacket datagramPacket = new DatagramPacket(requestMessage,
                      requestMessage.length, multicastAddress, port);
      socket.send(datagramPacket);
      
      socket.setSoTimeout(5000);
      try {
        do {
                byte[] rxbuf = new byte[8192];
                DatagramPacket packet = new DatagramPacket(rxbuf, rxbuf.length);
                socket.receive(packet);
                InetAddress addr = packet.getAddress();
                ByteArrayInputStream in = new ByteArrayInputStream(packet.getData(), 0,
                                packet.getLength());
                
                java.util.Scanner s = new java.util.Scanner(in).useDelimiter("\\A");
                String result = s.hasNext() ? s.next() : "";
                if (false) break;
        } while (true);
        } catch (Exception e) { }
      
      """
      }
      
  }
  
}

use class Ve:TestWeb {

  handleWeb(request) {
    String someparam = request.getParameter("someparam");
    request.getParameter("notthere");
    request.outputContent = "<html><body>yo</body></html>";
  }

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
    vars {
      Int keyLength = 16;
      Int ivLength = 16;
    }
  }
  
  encryptPassToHex(String iv, String pass, String val) String {
    return(Encode:Hex.encode(encryptPass(iv, pass, val)));
  }

  encryptPass(String iv, String pass, String val) String {
    pass = Digest:SHA256.digest(pass);
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
    bevl_res = new BEC_4_6_TextString(res);
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
    bevl_res = new BEC_4_6_TextString(res);
    """
    }
    return(res);
  }
  
  decryptPassFromHex(String iv, String pass, String val) String {
    return(decryptPass(iv, pass, Encode:Hex.decode(val)));
  }
  
  decryptPass(String iv, String pass, String val) String {
    pass = Digest:SHA256.digest(pass);
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
    bevl_res = new BEC_4_6_TextString(res);
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
    bevl_res = new BEC_4_6_TextString(res);
    """
    }
    return(res);
  }
}

use UI:WebBrowser as WeBr;

class Ve:LuiTest(Test:Assertions) {

  emit(jv) {
  """
  static { Security.addProvider(new BouncyCastleProvider());  }
  """
  }
  
  main() {
    try {
      innerMain();
    } catch (var e) {
      ("Caught exception").print();
      if (def(e)) {
        ("Error was " + e).print();
      }
    }
  }
  
  innerMain() {
      "start main".print();
      
      ifEmit(cs) {      
        //dbOpen();
        //fdbTest();
        //pkvTest();
        //dbClose();
        //webrTest();
        //ifaceTest();
        //cryptTest();
        //upnpTest();
        //testTask();
        testExecPath();
      }
      
      ifEmit(jv) {
        //mydbTest();
        //jvdbTest();
        //webrTest();
        //ifaceTest();
        //cryptTest();
        //gencertjv();
      }
      
      //cacheTest();
      //mtcacheTest();
      
      //testWebServer();
      
      //testKeyGen();
      
      //testFromArgs();

      //testGw();
      
      //writeThing();
      
      testEx();
      
      "end main".print();
  }
  
  testEx() {
    var e;
    try {
      testEx2();
    } catch (e) {
      ("caught ex").print();
      e.print();
    }
  }
  
  testEx2() {
    if (true) {
    throw(Exception.new("Got Except"));
    }
  }
  
  testExecPath() {
    ("Sys execpath" + System:Process.new().execPath.copy().parent.toString()).print();
  }
  
  testTask() {
    emit(cs) {
    """
    using (TaskService ts = new TaskService())
      {
         // Create a new task definition and assign properties
         TaskDefinition td = ts.NewTask();
         td.RegistrationInfo.Description = "Start Ve";
         td.Settings.DisallowStartIfOnBatteries = false;
         td.Settings.StopIfGoingOnBatteries = false;
         td.Principal.LogonType = TaskLogonType.S4U;
         //td.Settings.ExecutionTimeLimit = new TimeSpan(42949672950000);
         td.Settings.ExecutionTimeLimit = TimeSpan.Zero;
         
         DailyTrigger dt = new DailyTrigger { DaysInterval = 1 };
         dt.Repetition.Duration = TimeSpan.FromDays(1);
         dt.Repetition.Interval = TimeSpan.FromMinutes(480);
         td.Triggers.Add(dt);
         td.Triggers.Add(new RegistrationTrigger());
         //td.Triggers.Add(new BootTrigger());

         // Create a trigger that will fire the task at this time every other day
         //td.Triggers.Add(new DailyTrigger { DaysInterval = 1 });
         //td.Triggers.Add(new RegistrationTrigger());
         //td.Triggers.Add(new BootTrigger());

         // Create an action that will launch Notepad whenever the trigger fires
         //td.Actions.Add(new ExecAction("notepad.exe", "c:\\test.log", null));
         td.Actions.Add(new ExecAction(Application.ExecutablePath.ToString(), "svc", null));

         // Register the task in the root folder
         ts.RootFolder.RegisterTaskDefinition(@"StartVe", td);

         // Remove the task we just created
         //ts.RootFolder.DeleteTask("StartVe");
      }
    """
    }
  }
  
  writeThing() {
    File.apNew("C:\\devel\\tstput\\hi").contents = "hi";
  }
  
  upnpTest() {
    Ve:App va = Ve:App.new();
    ("primaryAddress " + va.primaryAddress).print();
    ("gatewayAddress " + va.gatewayAddress).print();
    
    String agw = "192.168.233.3";
    //String agw = va.gatewayAddress;
    ("Using agw " + agw).print();
    
    Upnp up = Upnp.new(agw);
    String du = up.deviceURL;
    ("Upnp got deviceURL " + du).print();
    
    String cu = up.controlURL;
    ("Upnp got controlURL " + cu).print();
    
    String extIp = up.externalIP;
    ("Upnp got extIp " + extIp).print();
    
    Bool success = up.forwardPort(600, 12000, 12001);
    ("fwp success1 " + success).print();
    
    success = up.forwardPort(600, 12000, 12002);
    ("fwp success2 " + success).print();
  }
  
  testGw() {
    //Net:Interface ni = Net:Interface.new();
    //String gwa = ni.gatewayAddress;
  }
  
  cryptTest() {
  
    String iv = "123456789123456789";
    String pass = "shh";
    String val = "yo dawg";
    Crypt crypt = Crypt.new();
    String enced = crypt.encryptPass(iv, pass, val);
    String deced = crypt.decryptPass(iv, pass, enced);
    ("Got deced " + deced).print();
    IO:File:Path encedp = IO:File:Path.apNew("test/tmp/enced");
    if (encedp.file.exists) {
      String eps = encedp.file.contents;
      deced = crypt.decryptPass(iv, pass, eps);
      ("Got deced file " + deced).print();
    }
    encedp.file.contents = enced;
    //asserts
  }
  
  webrTest() {
    WeBr webr = WeBr.new();
    webr.content = "<html><body>Hi</body></html>";
    webr.setup();
  }
  
  testFromArgs() {
  
    Array args = System:Process.new().args;
    ("args len " + args.length).print();
    if (args.length > 0) {
      if (args[0] == "ws") {
        testWebServer(args);
      } elif (args[0] == "wc") {
        testWebClient();
      }
    }
   
  }
  
  testWebClient() {
        Web:Client:CertificateManager.validateCertificates = false;
        //Web:Client:CertificateManager.acceptedThumbprints.put("4A83F55DAF9997C9C04693C91447FF8E473FDE05"); 
        Web:Client client = Web:Client.new();
        client.url = "https://127.0.0.1:10000/vk/Vk";
        //client.url = "http://google.com:8080/vk/Vk";
        client.method = "POST";
        client.outputContentType =@ "application/json";
        String payload = Json:Marshaller.new().marshall("hai");
        ("payload is " + payload).print();
        client.openOutput().write(payload).close();
        
        ("result").print();
        String res = client.openInput().readString();
        res.print();
        client.close();
        if (def(client.certificateThumbprint)) {
          ("Cert thumbprint " + client.certificateThumbprint).print();
        }
        
  }
  
  testWebServer(Array args) {
    Web:Server vw = Web:Server.new();
    if (args.length > 1) {
      vw.port = Int.new(args[1]);
    } else {
      vw.port = 10000;
    }
    ("WS starting on port " + vw.port).print();
    vw.ssl = true;
    vw.app = TestWeb.new();
    System:Thread vwt = System:Thread.new(vw);
    vwt.start();
  }
  
  testKeyGen() {
  emit(cs) {
  """
  /*CryptoApiRandomGenerator randomGenerator = new CryptoApiRandomGenerator();
   SecureRandom secureRandom = new SecureRandom(randomGenerator);
   var keyGenerationParameters = new KeyGenerationParameters(secureRandom, RsaKeySize);

   var keyPairGenerator = new RsaKeyPairGenerator();
   keyPairGenerator.Init(keyGenerationParameters);
   AsymmetricCipherKeyPair kp = keyPairGenerator.GenerateKeyPair();*/
  """
  }
  }
  
  ifaceTest() {
    Net:Interface ni = Net:Interface.new();
    foreach (Interface i in ni.localInterfaces) {
      i.print();
    }
    ("Preferred iface " + ni.preferredInterface).print();
  }
  
  dbOpen() {
    self.db.open();
  }
  
  dbClose() {
    if (def(pdb)) {
      pdb.close();
      pdb = null;
    }
  }
  
  dbGet() DbDb {
    vars {
      DbDb pdb;
    }
    if (def(pdb)) {
      return(pdb);
    }
    IO:File dbf = IO:File:Path.apNew("TESTDB.FDB").file;
      if (dbf.exists) {
        dbf.delete();
      }
      FbDb db = FbDb.new("ServerType=1;User=SYSDBA;" + 
               "Password=masterkey;Dialect=3;Database=TESTDB.FDB");
      db.createDatabase();
      pdb = db;
      return(db);
  }
  
  /*pkvTest() {
    ("start pkvtest").print();
    DbDb db = self.db;
    db.execute("CREATE TABLE RS( P VARCHAR(110), K VARCHAR(110), V VARCHAR(500),"
             + " constraint pk_k primary key (P,K) )");
    RS pkv = RS.new(db, "RS");
    pkv.put("hi", "there", "bob");
    assertEqual(pkv.get("hi", "there"), "bob");
    Map put = Map.new();
    put.put("yo", "dawg");
    put.put("hasta", "lavista");
    pkv.put("mmm", put);
    Map got = pkv.get("mmm");
    assertEqual(got["yo"], "dawg");
    assertEqual(got["hasta"], "lavista");
    ("end pkvtest").print();
  }*/
  
  fdbTest() {
      ("begin At:Test:fdbTest").print();
      DbDb db = self.db;
      //begin, commit, rollback
      db.execute("CREATE TABLE t1( ID INTEGER NOT NULL, NAME VARCHAR(500) NOT NULL )");
      db.begin();
      db.execute("INSERT INTO t1 ( ID, NAME ) VALUES ( 0, 'Bob' )");
      foreach (var row in db.executeQuery("Select * From t1")) {
        ("Result " + row.getInt(0) + " " + row.getString(1)).print();
      }
      db.commit();
      db.close();
      ("end At:Test:fdbTest").print();
  }
  
  jvdbTest() {
    DbDb db = DbDb.new("jdbc:derby:firstdb;create=true");
    db.driverOpen("org.apache.derby.jdbc.EmbeddedDriver");
    db.close();
  }
  
    mydbTest() {
  
    MyDb db = MyDb.new("jdbc:mysql://127.0.0.1:3306/betest?user=root&password=rootpw");
    db.open();
    db.begin();
    db.execute("insert into betest.t1 values (5, 'there')");
    db.commit();
    //db.rollback();
    foreach (var row in db.executeQuery("Select * From t1")) {
        ("Result " + row.getInt(0) + " " + row.getString(1)).print();
      }
     db.close();
  }
    
}
