// Copyright 2015 Craig Welch
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

use Text:String;
use Text:Strings as TS;
use Logic:Bool;
use Math:Int;
use Container:Array;
use Container:Map;
use Container:Set;

emit(cs) {
    """
//for mono ws, prefix Http* with Mono.Net for mono ver, drop (or System.Net) for ms builtin
using Mono.Net;
//for webclient
using System.Net;
//for outputting
using System.IO;
using System;
//for ui
using System.Windows.Forms;
using System.Drawing;
//for embedded http listener and wakeonlan
using System.Net.Sockets;
using System.Text;
// for threading
using System.Threading;
//ssl stuff
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
//for opening browser
using System.Diagnostics;
    """
}

use UI:WebBrowserImpl as WebImp;
class WebImp {

  new() self {
    properties {
      var setupHandler;
      var webHandler;
    }
  }
  
  setup() {
  
  }
  
  close() {
  
  }

}

use UI:WebBrowser as WeBr; 
class UI:WebBrowser {

  new() self {
    vars {
      Bool haveSetup = false;
      String title = "WebBrowser";
      Int height = 500;
      Int width = 500;
      String content;
      String location;
      String browserType;
      var webHandler;
      WebImp webImp;
    }
    ifEmit(cs) {
      browserType = "winform";
    }
    ifEmit(jv) {
      browserType = "jvfx";
    }
    ifEmit(platDroid) {
      browserType = "jvad";
    }
  }

  setup() {
    unless (haveSetup) {
      haveSetup = true;
      if (browserType == "winform") {
        webImp = createInstance("UI:WinForm:WebBrowser");
      }
      if (browserType == "jvfx") {
        webImp = createInstance("UI:JvFx:WebBrowser");
      }
      if (browserType == "jvad") {
        webImp = createInstance("UI:JvAd:WebBrowser");
      }
      webImp.new();
      webImp.setupHandler = self;
      webImp.webHandler = webHandler;
      webImp.setup();
    }
  }
  
  close() {
    webImp.close();
  }
  
  exit() {
    emit(cs) {
    """
    if (System.Windows.Forms.Application.MessageLoop) 
    {
        // WinForms app
        System.Windows.Forms.Application.Exit();
    }
    else
    {
        // Console app
        System.Environment.Exit(1);
    }
    """
    }
    ifEmit(jv) {
      System:Process.exit();
    }
  }
  
}

use UI:WinForm:WebBrowser as WfBr;
class WfBr(WebImp) {

   //wf specific
   emit(cs) {
   """
    public BeWebBrowser bevi_beWebBrowser;
    public WebBrowser bevi_webBrowser;
   """
   }
    
   close() {
     emit(cs) {
     """
     bevi_beWebBrowser.Close();
     """
     }
   }

    default() self {

    }
    
    setup() {
      //I don't actually do anything here
    }
    
    titleGet() String {
      return(setupHandler.title);
    }
    
    heightGet() Int {
      return(setupHandler.height);
    }
    
    widthGet() Int {
      return(setupHandler.width);
    }
    
    contentGet() String {
      return(setupHandler.content);
    }
    
    locationGet() String {
      return(setupHandler.location);
    }
    
    new() self {
     
     properties {
      Map session = Map.new();
      IO:Log log = IO:Log.new();
      Int lvl = log.debug;
     }
   }
   
   uiSetup() {
    webHandler.initWeb();
    setupForm();
    String content = self.content;
    if (def(content)) {
      openLocation("about:blank");
      writePage(content);
    } else {
      String location = self.location;
      if (def(location)) {
        openLocation(location);
      }
    }
  }
   
   setupForm() {
     ifEmit(cs) {
       Int h = self.height;
       Int w = self.width;
     }
     emit(cs) {
     """
     bevi_beWebBrowser.Height = bevl_h.bevi_int;
     bevi_beWebBrowser.Width = bevl_w.bevi_int;
    
     bevi_webBrowser = new WebBrowser();
     bevi_webBrowser.Dock = DockStyle.Fill;
     
     bevi_beWebBrowser.Controls.AddRange(new Control[] {
            bevi_webBrowser });
     bevi_beWebBrowser.ConnectWithScript(bevi_webBrowser, this);//winform or winform handler
     """
     }
   }
   
   handleWeb(String arg) String {
      log.log(lvl, "in handleWeb, arg " + arg);
      BrowserScriptRequest r = BrowserScriptRequest.new(session);
      r.scriptArgJson = arg;
      webHandler.handleWeb(r);
      String ret = r.scriptReturnJson;
      log.log(lvl, "in handleWeb, ret " + ret);
      return(ret);
   }
   
   //webbrowser general
   openLocation(String location) self {
      emit(cs) {
       """
       bevi_webBrowser.Navigate(beva_location.bems_toCsString());
       """
       }
   }
   
   writePage(String content) self {
       //for dev
       emit(cs) {
       """
       HtmlDocument doc = bevi_webBrowser.Document.OpenNew(true);
       doc.Write(string.Empty);
       doc.Write(beva_content.bems_toCsString());
       object[] args = new object[0];
       bevi_webBrowser.Document.InvokeScript("startup", args);
       """
       }
   }

}

emit(jv) {
"""
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.CookieHandler;
import java.net.CookieManager;
import java.net.CookiePolicy;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import java.security.cert.Certificate;
import java.security.cert.X509Certificate;
import java.security.SecureRandom;
import javax.net.ssl.SSLContext;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLSession;
import java.security.MessageDigest;
import javax.net.ssl.TrustManagerFactory;
import java.security.KeyStore;
import java.security.cert.CertificateException;
import java.util.List;
import java.util.Map;
"""
}

use Web:Client:CertificateManager as CM;

class CM {

  emit(cs) {
  """
  public static bool CheckCert(
        object sender,
        X509Certificate cert,
        X509Chain chain,
        SslPolicyErrors sslPolicyErrors)  {
    
    //Console.WriteLine((new X509Certificate2(cert)).Thumbprint);
    BEC_3_6_18_WebClientCertificateManager cm = BEC_3_6_18_WebClientCertificateManager.bevs_inst;
    //if thumbprint in accepted set, ret true
    if (cm.bevp_acceptedThumbprints.bem_has_1(
      new BEC_4_6_TextString((new X509Certificate2(cert)).Thumbprint)).bevi_bool) {
      return true;  
    } else if (cm.bevp_onlyAcceptedThumbprints.bevi_bool) {
      return false;
    }
    //if validating certs and there's an error, return false
    if (
      BEC_3_6_18_WebClientCertificateManager.bevs_inst.bevp_validateCertificates.bevi_bool
      && sslPolicyErrors != System.Net.Security.SslPolicyErrors.None) {
      return false;
    }
    return true;
  }
  """
  }
  emit(jv) {
  """
  public X509TrustManager bevi_defaultTm;
  
  public TrustManager[ ] bems_getTrustManager() {
     TrustManager[ ] certs = new TrustManager[ ] {
          new X509TrustManager() {
             public X509Certificate[ ] getAcceptedIssuers() { 
               return bevi_defaultTm.getAcceptedIssuers(); 
             }
             public void checkClientTrusted(X509Certificate[ ] certs, String org) throws CertificateException { 
               bevi_defaultTm.checkClientTrusted(certs, org);
             }
             public void checkServerTrusted(X509Certificate[ ] certs, String org) throws CertificateException { 
               BEC_3_6_18_WebClientCertificateManager cm = BEC_3_6_18_WebClientCertificateManager.bevs_inst;
                if (certs != null && certs.length > 0) {
                try {
                for (int i = 0;i < certs.length;i++) {
                //if thumbprint in accepted set, ret true
                if (cm.bevp_acceptedThumbprints.bem_has_1(
                  new BEC_4_6_TextString((bems_getThumbprint(certs[i])))).bevi_bool) {
                  return;  
                }
                }
                } catch (Throwable t) { }
                }
                if (cm.bevp_onlyAcceptedThumbprints.bevi_bool) {
                  throw new CertificateException("Not in accepted thumbprints");
                }
                if (
      BEC_3_6_18_WebClientCertificateManager.bevs_inst.bevp_validateCertificates.bevi_bool) {
                bevi_defaultTm.checkServerTrusted(certs, org);
                }
             }
           }
        };
        return certs;
      }
  
      public String bems_getThumbprint(X509Certificate cert) {
    	 try {
          MessageDigest md = MessageDigest.getInstance("SHA-1");
          byte[] der = cert.getEncoded();
          md.update(der);
          byte[] digest = md.digest();
          return bems_encodeHex(digest);
        } catch (Exception e) {
          throw new RuntimeException(e.getMessage(), e);
        }
    	}

    public String bems_encodeHex (byte bytes[]) {
    	char[] hexCodes = {'0', '1', '2', '3', '4', '5', '6', '7', 
    			'8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};
      StringBuilder res = new StringBuilder(bytes.length * 2);
      for (int i = 0; i < bytes.length; ++i) {
        res.append(hexCodes[(bytes[i] & 0xf0) >> 4]);
          res.append(hexCodes[bytes[i] & 0x0f]);
      }
      return res.toString();
    }
  """
  }

  //bevs_inst
  default() self {
    vars {
      Bool checkHosts = true;
      Bool validateCertificates = true;
      Bool validateHosts = true;
      CLocker acceptedThumbprints = CLocker.new(Set.new());
      Bool onlyAcceptedThumbprints = false;
    }
    emit(cs) {
    """
    ServicePointManager.ServerCertificateValidationCallback =
     CheckCert;
    """
    }
    emit(jv) {
    """
    TrustManagerFactory tmFact = TrustManagerFactory
        .getInstance(TrustManagerFactory.getDefaultAlgorithm());
    tmFact.init((KeyStore) null);
    for (TrustManager tm : tmFact.getTrustManagers()) {
        if (tm instanceof X509TrustManager) {
            bevi_defaultTm = (X509TrustManager) tm;
            break;
        }
    }
    
    SSLContext sslContext = SSLContext.getInstance("TLS");
        TrustManager[ ] trustMgr = bems_getTrustManager();
        sslContext.init(null,
                     trustMgr,
                     new SecureRandom());
    HttpsURLConnection.setDefaultSSLSocketFactory(sslContext.getSocketFactory());
    """
    }
  }
}

use class Web:Client {

   emit(cs) {
   """
    public HttpWebRequest bevi_request;
    public HttpWebResponse bevi_response;
   """
   }
   
   emit(jv) {
   """
   public HttpURLConnection bevi_conn;
   """
   }

    new() self {
        properties {
            String outputContentType;
            String method;
            IO:Writer outputWriter;
            IO:Reader inputReader;
            String url;
            String certificateThumbprint;
            Map outputHeaders = Map.new();
        }
    }
    
    open() self {
        //make request
        emit(cs) {
        """
        if (bevi_request != null) {
          return(this);
        }
        """
        }
        emit(jv) {
        """
        if (bevi_conn != null) {
          return(this);
        }
        """
        }
        if (url.begins("https")) {
          var ssl = "yup";//null or not null
        }
        emit(cs) {
        """
        bevi_request = (HttpWebRequest)WebRequest.Create(bevp_url.bems_toCsString());
        if (bevp_outputContentType != null) {
            bevi_request.ContentType = bevp_outputContentType.bems_toCsString();
        }
        """
        }
        emit(jv) {
        """
        CookieManager manager = new CookieManager();
        manager.setCookiePolicy(CookiePolicy.ACCEPT_NONE);
        CookieHandler.setDefault(manager);
        URL obj = new URL(bevp_url.bems_toJvString());
		    bevi_conn = (HttpURLConnection) obj.openConnection();
		    if (bevl_ssl != null &&
      !BEC_3_6_18_WebClientCertificateManager.bevs_inst.bevp_validateHosts.bevi_bool) {
          HttpsURLConnection c = (HttpsURLConnection) bevi_conn;
           c.setHostnameVerifier(new HostnameVerifier() {
                public boolean verify(String host, SSLSession sess) {
                    return true;
                }
            });
        }
		    if (bevp_outputContentType != null) {
		      bevi_conn.setRequestProperty("Content-Type", bevp_outputContentType.bems_toJvString());
        }
        """
        }
        foreach (var kv in outputHeaders) {
          String hk = kv.key;
          String hv = kv.value;
          emit(cs) {
          """
          if (bevl_hv == null) {
             bevi_request.Headers.Add(bevl_hk.bems_toCsString());
          } else {
            bevi_request.Headers[bevl_hk.bems_toCsString()] = bevl_hv.bems_toCsString();
          }
          """
          }
          emit(jv) {
          """
          bevi_conn.setRequestProperty(bevl_hk.bems_toJvString(), bevl_hv.bems_toJvString());
          """
          }
        }
        
    }
    
    openOutput() IO:Writer {
      open();
      certificateThumbprint = null;
      if (url.begins("https")) {
        var ssl = "yup";//null or not null
      }
      outputWriter = IO:Writer.new();
      emit(cs) {
        """
        if (bevp_method != null) {
            bevi_request.Method = bevp_method.bems_toCsString();
        }
        bevp_outputWriter.bevi_os = bevi_request.GetRequestStream();
        if (bevl_ssl != null) {
          X509Certificate cert = bevi_request.ServicePoint.Certificate;
          if (cert != null) {
            bevp_certificateThumbprint = new BEC_4_6_TextString((new X509Certificate2(cert)).Thumbprint);
          }
        }
        """
        }
        emit(jv) {
        """
		    if (bevp_method != null) {
            bevi_conn.setRequestMethod(bevp_method.bems_toJvString());
        }
        bevi_conn.setDoOutput(true);
        bevp_outputWriter.bevi_os = bevi_conn.getOutputStream();
        if (bevl_ssl != null) {
          HttpsURLConnection c = (HttpsURLConnection) bevi_conn;
          Certificate[] certs = c.getServerCertificates();
          if (certs != null && certs.length > 0) {
            Certificate cert = certs[0];
            if (cert instanceof X509Certificate) {
              bevp_certificateThumbprint = new BEC_4_6_TextString(
                 BEC_3_6_18_WebClientCertificateManager.bevs_inst.bems_getThumbprint(((X509Certificate) cert))
              );
            }
          }
        }
        """
        }
        outputWriter.extOpen();
        return(outputWriter);
    }
    
    openInput() IO:Reader {
        vars {
          Map inputHeaders = Map.new();
        }
        String ihkey;
        String ihval;
        
        open();
        inputReader = IO:Reader.new();
        certificateThumbprint = null;
        if (url.begins("https")) {
          var ssl = "yup";//null or not null
        }
        emit(cs) {
        """
        bevi_response = (HttpWebResponse)bevi_request.GetResponse();
        for(int i=0; i < bevi_response.Headers.Count; ++i) {
          if (bevi_response.Headers.Keys[i] != null &&
            bevi_response.Headers[i] != null) {
              bevl_ihkey = new BEC_4_6_TextString(bevi_response.Headers.Keys[i]);
              bevl_ihval = new BEC_4_6_TextString(bevi_response.Headers[i]);
              bevp_inputHeaders.bem_put_2(bevl_ihkey, bevl_ihval);
            }
        }
        bevp_inputReader.bevi_is = bevi_response.GetResponseStream();
        if (bevl_ssl != null) {
          X509Certificate cert = bevi_request.ServicePoint.Certificate;
          if (cert != null) {
            bevp_certificateThumbprint = new BEC_4_6_TextString((new X509Certificate2(cert)).Thumbprint);
          }
        }
        """
        }
        emit(jv) {
        """
        bevp_inputReader.bevi_is = bevi_conn.getInputStream();
        Map<String, List<String>> hdrs = bevi_conn.getHeaderFields();
        for (Map.Entry<String, List<String>> hentry : hdrs.entrySet()) {
          if (hentry.getKey() != null && hentry.getValue() != null &&
            hentry.getValue().size() > 0) {
            bevl_ihkey = new BEC_4_6_TextString(hentry.getKey());
              bevl_ihval = new BEC_4_6_TextString(hentry.getValue().get(0));
              bevp_inputHeaders.bem_put_2(bevl_ihkey, bevl_ihval);
          }
        }
        if (bevl_ssl != null) {
          HttpsURLConnection c = (HttpsURLConnection) bevi_conn;
          Certificate[] certs = c.getServerCertificates();
          if (certs != null && certs.length > 0) {
            Certificate cert = certs[0];
            if (cert instanceof X509Certificate) {
              bevp_certificateThumbprint = new BEC_4_6_TextString(
                 BEC_3_6_18_WebClientCertificateManager.bevs_inst.bems_getThumbprint(((X509Certificate) cert))
              );
            }
          }
        }
        """
        }
        inputReader.extOpen();
        return(inputReader);
    }
    
    closeOutput() self {
        if (def(outputWriter)) {
            outputWriter.close();
            outputWriter = null;
        }
    }
    
    closeInput() self {
        if (def(inputReader)) {
            inputReader.close();
            inputReader = null;
        }
    }
    
    close() self {
        closeOutput();
        closeInput();
        emit(cs) {
        """
        bevi_request = null;
        bevi_response = null;
        """
        }
        emit(jv) {
        """
        bevi_conn = null;
        """
        }
    }

}

use class UI:BrowserScriptRequest {

    new(Map _session) self {
        properties {
            Map session = _session;
            String contentIn;
            String contentOut;
            Json:Marshaller mar = Json:Marshaller.new();
            Json:Unmarshaller unmar = Json:Unmarshaller.new();
            String inputAddress;
        }
    }
    
    new() self {
      new(Map.new());
    }
    
    getSession(String name) String {
       return(session.get(name));
   }
   
   putSession(String name, String value) self {
        session.put(name, value);
   }
   
   scriptArgJsonSet(String arg) {
     properties {
       String scriptArgJson = arg;
     }
   }
   
   scriptReturnJsonGet() String {
     return(scriptReturnJson);
   }
   
   scriptArgGet() {
     return(unmar.unmarshall(scriptArgJson));
   }
   
   scriptReturnSet(ret) {
     properties {
       String scriptReturnJson;
     }
     scriptReturnJson = mar.marshall(ret);
   }
   
   deleteSession() {
     session.clear();
   }
    
}

use System:Thread:ContainerLocker as CLocker;

use class Web:SessionManager {

  new(_sessions) self {
    vars {
      var sessions = _sessions;
      String keyName = "sesskey";
      Int keyLen = 16;
    }
  }
  
  new() self {
    new(CLocker.new(Map.new()));
  }
  
  getSessionKey(request) String {
    String sk = request.getInputHeader(keyName);
    if (TS.isEmpty(sk)) {
      sk = request.getInputCookie(keyName);
    }
    if (TS.notEmpty(sk)) {
      //to make it harder to probe for sessions
      request.setOutputHeader(keyName, sk);
    } else {
      sk = System:Random.getString(keyLen);
      until (sessions.getMap(sk + ".").isEmpty) {
        sk = System:Random.getString(keyLen);
      }
      request.setOutputCookie(keyName, sk, "/");
      request.setOutputHeader(keyName, sk);
    }
    return(sk);
  }
  
  deleteSession(request) {
    String sk = request.getInputCookie(keyName);
    if (TS.notEmpty(sk)) {
      Map toDel = sessions.getMap(getSessionKey(request) + ".");
      foreach (var x in toDel) {
        sessions.delete(x.key);
      }
    }
    request.setOutputCookie(keyName, "", "/");
  }
  
  getSession(request, String name) String {
    return(sessions.get(getSessionKey(request) + "." + name));
  }
  
  putSession(request, String name, String value) {
    sessions.put(getSessionKey(request) + "." + name, value);
  }

}

use class UI:ExternalBrowser {

  openToUrl(String url) {
  
    emit(cs) {
    """
    Process p = new Process();
    p.StartInfo.FileName = beva_url.bems_toCsString();
    p.StartInfo.CreateNoWindow = true;
    //p.StartInfo.UseShellExecute = false;
    p.Start();
    """
    }
    
    ifNotEmit(platDroid) {
    emit(jv) {
    """
    java.awt.Desktop desktop = java.awt.Desktop.getDesktop();
    desktop.browse(new java.net.URI(beva_url.bems_toJvString()));
    """
    }
    }
  
  }

}

