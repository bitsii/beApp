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
use Db:Relational:Database as DbDb;
use Db:Relational:Statement as DbSt;
use System:Thread:Lock;
use System:Thread:ContainerLocker as CLocker;
use System:Command as Com;
use Time:Sleep;
use Container:Pair;

use App:Alert;

use App:LocalWebApp;
use App:RemoteWebApp;
use App:WebApp;
use Text:String;
use App:CallBackUI;

use System:Thread:Lock;
use System:Thread:ObjectLocker as OLocker;

use Crypto:Symmetric as Crypt;

use System:Parameters;
use Net:UPnP as Upnp;
use Net:IP;

use class EWC:NetMaker {

     new() self {
       fields {
          var log = IO:Logs.get(self);
        }
        IO:Logs.turnOnAll();
     }

     giveNet(String ssid, String pass, String code) {
       log.log("in givenet " + ssid + " pass " + pass + " code " + code);
       Map dcodes = passFromCode(code);
       
       //crypt is with last - 1
       //net is last substring 8
       
       //encrypted json map with all the stuff including the code
       
       String nets = Json:Marshaller.marshall(Maps.from("ssid", ssid, "pass", pass, "code", code));
       
       String gnpass = dcodes["crypt"];
       String gnid = dcodes["id"];
       String daddr = "192.168.5.1";
       String dport = "20080";
       
       String netsc = Crypt.encryptPassToHex(gnpass, gnpass.substring(8), nets);
       
       log.log("nets " + nets);
       log.log("netsc " + netsc);
       log.log("gnid " + gnid);
       log.log("daddr " + daddr);
       log.log("dport " + dport);
       
       //connect to gnid
       log.log("connect to gnid and send netsc to daddr dport");
       
     }
     
     passFromCode(String code) Map {
     
       String dcode = code;
       for (Int i = 0;i < 2;i++=) {
         dcode = Digest:SHA256.digest(dcode);
       }
       dcode = Encode:Hex.encode(dcode);
       
       String dcode2 = Encode:Hex.encode(Digest:SHA256.digest(dcode));
       
       return(Maps.from("crypt", dcode, "id", dcode2.substring(0, 8)));
       
     }
   
}
   
use Db:KeyValue as KvDb;
