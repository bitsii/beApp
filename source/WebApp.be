// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use Container:Queue;
use IO:File:Path;
use IO:File;
use System:Random;
use UI:WebBrowser as WeBr;
use Test:Assertions as Assert;
use Db:Relational:Database as DbDb;
use Db:Relational:Statement as DbSt;
use Db:Firebird:Database as FbDb;
use Db:Derby:Database as Derby;
use Db:KeyValue as KvDb;

use App:WebApp;
use App:Account;

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
emit(cs) {
"""
// for crypto
using System.Security.Cryptography;
// for ssl certgen
using Mono.Security.Authenticode;
using Mono.Security.X509;
using Mono.Security.X509.Extensions;
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
"""
}
use class App:RemoteWebApp(WebApp) {

  emit(jv) {
  """
  static { Security.addProvider(new BouncyCastleProvider());  }
  """
  }

  new() self {
        fields {
        }
        super.new();
    }
    
    startWeb() {
      any e;
      String ports = self.webPort;
      Int port = Int.new(ports);
      //portL.o = port;
      
      Web:Server vw = Web:Server.new(self.sessionManager);
      
      //vwL.o = vw;
      vw.port = port;
      vw.ssl = self.doSsl;
      ("doSsl = " + vw.ssl).print();
      if (self.doSsl) {
        vw.sslPath = assureCert(port);
      }
      vw.app = self;
      vw.gzipOutput = true;
      ifEmit(cs) {
        vw.gzipOutput = false;
      }
      fields {
        System:Thread myThread;
      }
      log.log("Starting Web");
      ifEmit(jv) {
        myThread = System:Thread.new(vw);
        myThread.start();
      }
      ifEmit(cs) {
        vw.main();
      }
    }
    
  assureCert(Int port) String {
    ifEmit(jv) {
      return(assureCertJv(port));
    }
    ifEmit(cs) {
      return(assureCertCs(port));
    }
  }
  
  handleStartWeb() {
    log.log("In handleStartWeb!!");
  }
  
  assureCertJv(Int port) String {
    emit(jv) {
    """
    java.security.cert.Certificate cert;
    """
    }
    //Path cerPath = Path.apNew("Data/IUHub/cert");
    Path cerPath = self.paths.dataPath.addStep("cert");
    String cerPathS = cerPath.toString();
    log.log("cerPath " + cerPathS);
    if (cerPath.file.exists) {
      log.log("cer exist");
      emit(jv) {
      """
      KeyStore privateKS = KeyStore.getInstance("JKS");
      privateKS.load( new FileInputStream(bevl_cerPathS.bems_toJvString()), "kp".toCharArray());
      cert = privateKS.getCertificate("jetty");
      """
      }
    } else {
      log.log("cer not exist");
      log.log("Start gencert");
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
      v3CertGen.setSignatureAlgorithm("SHA256withRSA"); 
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
      log.log("End gencert");
    }
    emit(jv) {
    """
    bevp_certificateThumbprint = new $class/Text:String$(
                 $class/Web:Client:CertificateManager$.bece_BEC_3_3_6_18_WebClientCertificateManager_bevs_inst.bems_getThumbprint(((X509Certificate) cert))
              );
    """
    }
    log.log("certificateThumbprint " + certificateThumbprint);
    return(cerPathS);
  }
  
  assureCertCs(Int port) String {
    Path certDir = self.paths.appPath.copy();
    certDir.addStep("Application Data").addStep(".mono").addStep("httplistener");
    log.log("certDir is " + certDir);
    IO:File:Path cerPath = certDir.copy().addStep(port.toString() + ".cer");
    IO:File:Path pvkPath = certDir.copy().addStep(port.toString() + ".pvk");
    String cerPathS = cerPath.toString();
    String pvkPathS = pvkPath.toString();
    log.log("cerPath " + cerPathS);
    log.log("pvkPath " + pvkPathS);
    if (cerPath.file.exists && pvkPath.file.exists) {
      log.log("cer and pvk exist");
      return(cerPathS);
    } else {
      log.log("cer and pvk not exist");
      if (certDir.file.exists!) {
        certDir.file.makeDirs();
      }
    }
    log.log("Start gencert");
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
    cb.Hash = "SHA1";//TODO SHA256, line up with jv version
    byte[] rawcert = cb.Sign (subjectKey);

    PrivateKey key = new PrivateKey ();
    key.RSA = subjectKey;
    key.Save (bevl_pvkPathS.bems_toCsString());
    FileStream fs = File.Open (bevl_cerPathS.bems_toCsString(), FileMode.Create, FileAccess.Write);
    fs.Write (rawcert, 0, rawcert.Length);
    fs.Close ();
    """
    }
    log.log("End gencert");
    return(cerPathS);
  }
  
    main() {
      List args = System:Process.new().args;
      start();
      startWeb();
   }

   initWeb() {

   }
   
   handleWeb(request) this {
     //log.log("in hw");
     super.handleWeb(request);
   }

}

use System:Thread:Lock;
use System:Thread:ContainerLocker as CLocker;
use System:Command as Com;
use Time:Sleep;
use System:Thread:ObjectLocker as OLocker;
use Db:HSQLDb:Database as HsDb;
