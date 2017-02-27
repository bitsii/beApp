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

use App:AuthenticatedApp as AuthedApp;
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
use class App:AuthenticatedWebApp(AuthedApp) {

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
      String cerPath = assureCert(port);
      //portL.o = port;
      
      Web:Server vw = Web:Server.new(self.sessionManager);
      
      //vwL.o = vw;
      vw.port = port;
      vw.ssl = true;
      vw.sslPath = cerPath;
      vw.app = self;
      vw.gzipOutput = true;
      fields {
        System:Thread myThread = System:Thread.new(vw);
      }
      log.log("Starting Web");
      myThread.start();
    }
    
    
  assureCert(Int port) String {
    ifEmit(jv) {
      return(assureCertJv(port));
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
                 $class/Web:Client:CertificateManager$.bevs_inst.bems_getThumbprint(((X509Certificate) cert))
              );
    """
    }
    log.log("certificateThumbprint " + certificateThumbprint);
    return(cerPathS);
  }
  
    main() {
      List args = System:Process.new().args;
      start();
      startWeb();
   }

   initWeb() {

   }
   
   handleWeb(request) {
     //log.log("in hw");
     unless (checkRequest(request)) {
      return(null);
     }
     String accountName = request.getSession("account.name");
     String rmtd = request.inputMethod;
     //log.log("rmtd is " + rmtd);
     if (TS.isEmpty(rmtd) || rmtd != "PUT") {
        Map arg = request.scriptArg;
     }
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
       log.log("uri " + uri);
       if (TS.isEmpty(uri) || uri == "/") {
        log.log("empty uri going to base page");
        request.outputContent = "<html><head><script>location=\"" + self.plugin.homePage + "\"</script></html>";
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
          String mtype;
          if (uri.ends(".html")) {
            mtype = "text/html";
          } elseIf (uri.ends(".jpg")) {
            mtype = "image/jpeg";
          } elseIf (uri.ends(".svg")) {
            mtype = "image/svg+xml";
          } elseIf (uri.ends(".js")) {
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

}

use System:Thread:Lock;
use System:Thread:ContainerLocker as CLocker;
use System:Command as Com;
use Time:Sleep;
use System:Thread:ObjectLocker as OLocker;
use Db:HSQLDb:Database as HsDb;
