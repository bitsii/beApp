/*
 * Copyright (c) 2015-2023, the Brace App Authors.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Licensed under the BSD 2-Clause License (the "License").
 * See the LICENSE file in the project root for more information.
 *
 */

import IO:File:Path;
import IO:File;
import System:Random;
import UI:WebBrowser as WeBr;
import Test:Assertions as Assert;
import Db:Relational:Database as DbDb;
import Db:Relational:Statement as DbSt;
import System:Thread:Lock;
import System:Thread:ContainerLocker as CLocker;
import System:Command as Com;
import Time:Sleep;
import Container:Pair;

import App:Alert;

import App:LocalWebApp;
import App:RemoteWebApp;
import App:WebApp;
import Text:String;
import App:CallBackUI;

import System:Thread:Lock;
import System:Thread:ObjectLocker as OLocker;

import Crypto:Symmetric as Crypt;

import System:Parameters;
import Net:UPnP as Upnp;
import Net:IP;

import class EWC:NetMaker {

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
   
import Db:KeyValue as KvDb;
