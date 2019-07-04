// Copyright 2015 Craig Welch
//
// Licensed under the MIT license. See LICENSE.txt file in the project root 
// for full license information.

use System:Parameters;

emit(cs) {
    """
//for mono ws, prefix Http* with Mono.Net for mono ver, drop (or System.Net) for ms builtin
//using Mono.Net;
//for webclient
using System.Net;
//for outputting
using System.IO;
using System;
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
  
  setup() {
    fields {
      any setupHandler;
      any webHandler;
    }
  }
  
  close() {
  
  }
  
  splitAllArgs(String allArgs) List {
    //("in splitallargs").print();
    List allArgsL = List.new(3);
    Int fc = allArgs.find(":");
    String arls = allArgs.substring(0, fc);
    Int sc = allArgs.find(":", fc + 1);
    String urls = allArgs.substring(fc + 1, sc);
    Int tc = allArgs.find(":", sc + 1);
    String ctls = allArgs.substring(sc + 1, tc);
    
    if (arls != "N") {
      Int argsend = Int.new(arls) + tc + 1;
      String ar = allArgs.substring(tc + 1, argsend);
      //("|" + ar + "|").print();
    } else {
      argsend = tc + 1;
    }
    if (urls != "N") {
      Int urlsend = Int.new(urls) + argsend;
      String ur = allArgs.substring(argsend, urlsend);
      //("|" + ur + "|").print();
    } else {
      urlsend = argsend;
    }
    if (ctls != "N") {
      Int ctend = Int.new(ctls) + urlsend;
      String ct = allArgs.substring(urlsend, ctend);
      //("|" + ct + "|").print();
    } else {
      ctend = urlsend;
    }
    allArgsL.put(0, ar);
    allArgsL.put(1, ur);
    allArgsL.put(2, ct);
    return(allArgsL);
  }

}

use UI:WebBrowser as WeBr; 
class UI:WebBrowser {

  new() self {
    fields {
      Bool haveSetup = false;
      String title = "WebBrowser";
      Int height = 500;
      Int width = 500;
      String content;
      String location;
      String browserType;
      any webHandler;
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
    ifEmit(cc) {
       browserType = "ccio";
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
      if (browserType == "ccio") {
        webImp = createInstance("UI:CcIo:WebBrowser");
        any wi = webImp;
        webImp = wi.getMe();
      }
      "making webbr".print();
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
    //if (System.Windows.Forms.Application.MessageLoop) 
    //{
        // WinForms app
    //    System.Windows.Forms.Application.Exit();
    //}
    //else
    //{
        // Console app
        System.Environment.Exit(1);
    //}
    """
    }
    ifEmit(jv) {
      System:Process.exit();
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
    $class/Web:Client:CertificateManager$ cm = $class/Web:Client:CertificateManager$.bece_BEC_3_3_6_18_WebClientCertificateManager_bevs_inst;
    //if thumbprint in accepted set, ret true
    if (cm.bevp_acceptedThumbprints.bem_has_1(
      new $class/Text:String$((new X509Certificate2(cert)).Thumbprint)).bevi_bool) {
      return true;  
    } else if (cm.bevp_onlyAcceptedThumbprints.bevi_bool) {
      return false;
    }
    //if validating certs and there's an error, return false
    if (
      $class/Web:Client:CertificateManager$.bece_BEC_3_3_6_18_WebClientCertificateManager_bevs_inst.bevp_validateCertificates.bevi_bool
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
               $class/Web:Client:CertificateManager$ cm = $class/Web:Client:CertificateManager$.bece_BEC_3_3_6_18_WebClientCertificateManager_bevs_inst;
                if (certs != null && certs.length > 0) {
                try {
                for (int i = 0;i < certs.length;i++) {
                //if thumbprint in accepted set, ret true
                if (cm.bevp_acceptedThumbprints.bem_has_1(
                  new $class/Text:String$((bems_getThumbprint(certs[i])))).bevi_bool) {
                  return;  
                }
                }
                } catch (Throwable t) { }
                }
                if (cm.bevp_onlyAcceptedThumbprints.bevi_bool) {
                  throw new CertificateException("Not in accepted thumbprints");
                }
                if (
      $class/Web:Client:CertificateManager$.bece_BEC_3_3_6_18_WebClientCertificateManager_bevs_inst.bevp_validateCertificates.bevi_bool) {
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

  //bece_BEC_3_3_6_18_WebClientCertificateManager_bevs_inst
  default() self {
    fields {
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
        fields {
            String outputContentType;
            String verb;
            IO:Writer outputWriter;
            IO:Reader inputReader;
            String url;
            String certificateThumbprint;
            Map outputHeaders = Map.new(); //really is just a map, multi value is comma separated string
            Bool followRedirects = true;
            Int connectTimeoutMillis;
            Int readTimeoutMillis;
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
          any ssl = "yup";//null or not null
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
        if (bevp_connectTimeoutMillis != null) {
          bevi_conn.setConnectTimeout(bevp_connectTimeoutMillis.bevi_int);
        }
        if (bevp_readTimeoutMillis != null) {
          bevi_conn.setReadTimeout(bevp_readTimeoutMillis.bevi_int);
        }
		    if (bevl_ssl != null &&
      !$class/Web:Client:CertificateManager$.bece_BEC_3_3_6_18_WebClientCertificateManager_bevs_inst.bevp_validateHosts.bevi_bool) {
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
        for (auto kv in outputHeaders) {
          String hk = kv.key;
          String hv = kv.value;
          if (def(hv)) {
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
          bevi_conn.setInstanceFollowRedirects(bevp_followRedirects.bevi_bool);
          """
          }
          }
        }
        
    }
    
    openOutput() IO:Writer {
      open();
      certificateThumbprint = null;
      if (url.begins("https")) {
        any ssl = "yup";//null or not null
      }
      outputWriter = IO:Writer.new();
      emit(cs) {
        """
        if (bevp_verb != null) {
            bevi_request.Method = bevp_verb.bems_toCsString();
        }
        bevp_outputWriter.bevi_os = bevi_request.GetRequestStream();
        if (bevl_ssl != null) {
          X509Certificate cert = bevi_request.ServicePoint.Certificate;
          if (cert != null) {
            bevp_certificateThumbprint = new $class/Text:String$((new X509Certificate2(cert)).Thumbprint);
          }
        }
        """
        }
        emit(jv) {
        """
		    if (bevp_verb != null) {
            bevi_conn.setRequestMethod(bevp_verb.bems_toJvString());
        }
        bevi_conn.setDoOutput(true);
        bevp_outputWriter.bevi_os = bevi_conn.getOutputStream();
        if (bevl_ssl != null) {
          HttpsURLConnection c = (HttpsURLConnection) bevi_conn;
          Certificate[] certs = c.getServerCertificates();
          if (certs != null && certs.length > 0) {
            Certificate cert = certs[0];
            if (cert instanceof X509Certificate) {
              bevp_certificateThumbprint = new $class/Text:String$(
                 $class/Web:Client:CertificateManager$.bece_BEC_3_3_6_18_WebClientCertificateManager_bevs_inst.bems_getThumbprint(((X509Certificate) cert))
              );
            }
          }
        }
        """
        }
        outputWriter.extOpen();
        return(outputWriter);
    }
    
    contentsOutSet(String payload) self {
      fields {
        String ccin;
      }
      ifNotEmit(ccIsIos) {
        openOutput().write(payload);
      }
      ifEmit(ccIsIos) {
        emit(cc) {
        """
#ifdef BEDCC_ISIOS
        string res = bevp_url->bems_toCcString();
        const char* resC = res.c_str();
        NSString *nsurls = [NSString stringWithCString:resC encoding:NSUTF8StringEncoding];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:nsurls]];
        NSLog(@"did make url");
        request.HTTPMethod = @"POST";
        
#endif
        """
        }
        for (auto kv in outputHeaders) {
          String hk = kv.key;
          String hv = kv.value;
          ("setting header " + hk + " " + hv).print();
          if (def(hv)) {
        emit(cc) {
        """
#ifdef BEDCC_ISIOS

        string hkcs = bevl_hk->bems_toCcString();
        const char* hkcc = hkcs.c_str();
        NSString *hkos = [NSString stringWithCString:hkcc encoding:NSUTF8StringEncoding];
        
        string hvcs = bevl_hv->bems_toCcString();
        const char* hvcc = hvcs.c_str();
        NSString *hvos = [NSString stringWithCString:hvcc encoding:NSUTF8StringEncoding];
        
        [request setValue:hvos forHTTPHeaderField:hkos];
#endif
          """
          }
          }
        }
        //a
        emit(cc) {
        """
#ifdef BEDCC_ISIOS
        
string pays = beva_payload->bems_toCcString();
const char* payc = pays.c_str();
NSString *payos = [NSString stringWithCString:payc encoding:NSUTF8StringEncoding];
        
NSData *requestBodyData = [payos dataUsingEncoding:NSUTF8StringEncoding];
request.HTTPBody = requestBodyData;

NSError *err = nil;
NSHTTPURLResponse *ress = nil;
NSData *retData = [NSURLConnection sendSynchronousRequest:request returningResponse:&ress error:&err];
if (retData != nil) {
  NSString* newStr = [[NSString alloc] initWithBytes:(char *)retData.bytes length:retData.length encoding:NSUTF8StringEncoding];

  NSLog(@"after request");
  NSLog(newStr);
  string cppMessage = string([newStr UTF8String]);
  bevp_ccin = new BEC_2_4_6_TextString(cppMessage);
  
}

#endif
        """
        }
      }
      return(self);
    }
    
    contentsInGet() String {
      ifNotEmit(ccIsIos) {
        return(openInput().readString());
      }
      ifEmit(ccIsIos) {
        if (def(ccin)) {
          return(ccin);
        }
        return(null);
      }
    }
    
    openInput() IO:Reader {
        fields {
          Map inputHeaders = Map.new(); //really is just a map, multi value is comma sep string
        }
        String ihkey;
        String ihval;
        
        open();
        inputReader = IO:Reader.new();
        certificateThumbprint = null;
        if (url.begins("https")) {
          any ssl = "yup";//null or not null
        }
        emit(cs) {
        """
        bevi_response = (HttpWebResponse)bevi_request.GetResponse();
        for(int i=0; i < bevi_response.Headers.Count; ++i) {
          if (bevi_response.Headers.Keys[i] != null &&
            bevi_response.Headers[i] != null) {
              bevl_ihkey = new $class/Text:String$(bevi_response.Headers.Keys[i]);
              bevl_ihval = new $class/Text:String$(bevi_response.Headers[i]);
              bevp_inputHeaders.bem_put_2(bevl_ihkey, bevl_ihval);
            }
        }
        bevp_inputReader.bevi_is = bevi_response.GetResponseStream();
        if (bevl_ssl != null) {
          X509Certificate cert = bevi_request.ServicePoint.Certificate;
          if (cert != null) {
            bevp_certificateThumbprint = new $class/Text:String$((new X509Certificate2(cert)).Thumbprint);
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
            bevl_ihkey = new $class/Text:String$(hentry.getKey());
              bevl_ihval = new $class/Text:String$(hentry.getValue().get(0));
              bevp_inputHeaders.bem_put_2(bevl_ihkey, bevl_ihval);
          }
        }
        if (bevl_ssl != null) {
          HttpsURLConnection c = (HttpsURLConnection) bevi_conn;
          Certificate[] certs = c.getServerCertificates();
          if (certs != null && certs.length > 0) {
            Certificate cert = certs[0];
            if (cert instanceof X509Certificate) {
              bevp_certificateThumbprint = new $class/Text:String$(
                 $class/Web:Client:CertificateManager$.bece_BEC_3_3_6_18_WebClientCertificateManager_bevs_inst.bems_getThumbprint(((X509Certificate) cert))
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
    
    inputContentTypeGet() String {
      return(self.inputHeaders.get("Content-Type"));
    }

}

use class UI:BrowserScriptRequest {

    new(Map _session) self {
        fields {
            Map session = _session;
            String contentIn;
            String contentOut;
            String inputAddress;
            Bool embedded = true;
            Map context = Map.new();
            Bool continueHandling = true;
            String inputMethod = "EMBEDDED";
            Map parameters = Map.new();
            String uri;
            String inputContentType;
            String outputContentType;
        }
    }
    
    inputContentGet() String {
      return(scriptArgJson);
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
     fields {
       String scriptArgJson = arg;
     }
   }
   
   scriptReturnJsonGet() String {
     return(scriptReturnJson);
   }
   
   scriptArgGet() {
     return(Json:Unmarshaller.unmarshall(scriptArgJson));
   }
   
   outputContentSet(String oc) {
     scriptReturnJson = oc;
   }
   
   scriptReturnSet(ret) {
     fields {
       String scriptReturnJson;
     }
     scriptReturnJson = Json:Marshaller.marshall(ret);
   }
   
   deleteSession() {
     session.clear();
   }
   
   remoteAddressGet() String {
    return("");
   }
   
   getParameter(String name) String {
     return(parameters.get(name));
   }
   
   putParameter(String name, String value) this {
     parameters.put(name, value);
   }
    
}

use System:Thread:ContainerLocker as CLocker;

use class Web:SessionManager {

  new() self {
    new(CLocker.new(Map.new()));
  }
  
  new(_sessions) self {
    new(_sessions, "sesskey");
  }
  
  new(_sessions, String _keyName) self {
    fields {
      any sessions = _sessions;
      String keyName = _keyName;
      Int keyLen = 64;
    }
  }
  
  hashKey(String pass) String {
    Digest:SHA256 ds = Digest:SHA256.new();
    pass = ds.digestToHex(pass);
    return(pass);
  }
  
  getSessionKey(request) String {
    String sk;
    //sk = request.getInputHeader(keyName);
    sk = request.serviceSessionKey;
    if (TS.isEmpty(sk)) {
      sk = request.getInputCookie(keyName);
    }
    if (TS.notEmpty(sk)) {
      if (sessions.get("SESSIONS").getMap(hashKey(sk) + ".").isEmpty) {
        //could be probing for sessions, let them have this but will be upping bad
        request.context.put("unknownSession", "unknownSession");
        sessions.get("SESSIONS").put(hashKey(sk) + ".", "");
      }
    } else {
      sk = System:Random.getString(keyLen);
      until (sessions.get("SESSIONS").getMap(hashKey(sk) + ".").isEmpty) {
        sk = System:Random.getString(keyLen);
      }
      sessions.get("SESSIONS").put(hashKey(sk) + ".", "");
    }
    request.setOutputCookie(keyName, sk, "/", true, true);
    //request.setOutputHeader(keyName, sk);
    //request.context.put("rawSessionKey", sk);
    String sko = hashKey(sk);
    //("sko for sk " + sko + " " + sk).print();
    return(sko);
  }
  
  deleteSession(request) {
    String sk = request.getInputCookie(keyName);
    if (TS.notEmpty(sk)) {
      deleteSessionByKey(getSessionKey(request));
    }
    request.setOutputCookie(keyName, "", "/", true, true);
  }
  
  deleteSessionByKey(String key) {
    if (TS.notEmpty(key)) {
      Map toDel = sessions.get("SESSIONS").getMap(key + ".");
      for (any x in toDel) {
        //("deleting session key " + x.key).print(); 
        sessions.get("SESSIONS").delete(x.key);
      }
    }
  }
  
  getSession(request, String name) String {
    if (TS.isEmpty(name)) {
      return(null);
    }
    return(sessions.get("SESSIONS").get(getSessionKey(request) + "." + name));
  }
  
  putSession(request, String name, String value) {
    unless (TS.isEmpty(name)) {
      sessions.get("SESSIONS").put(getSessionKey(request) + "." + name, value);
    }
  }

}

use class UI:ExternalBrowser {

  openToUrl(String url) {
  
    emit(cs) {
    """
    //Process p = new Process();
    //p.StartInfo.FileName = beva_url.bems_toCsString();
    //p.StartInfo.CreateNoWindow = true;
    ////p.StartInfo.UseShellExecute = false;
    //p.Start();
    """
    }
    
    ifNotEmit(platDroid) {
    emit(jv) {
    """
    //java.awt.Desktop desktop = java.awt.Desktop.getDesktop();
    //desktop.browse(new java.net.URI(beva_url.bems_toJvString()));
    """
    }
    //("try to open from cmd").print();
     if (System:CurrentPlatform.name == "mswin") {
       System:Command.new("cmd /c start " + url).run();
    } elseIf (System:CurrentPlatform.name == "macos") {
       System:Command.new("open " + url).run();
     } else {
       System:Command.new("xdg-open " + url).run();
     }
    }
    
    ifEmit(platDroid) {
    emit(jv) {
   """
be.$class/UI:JvAd:WebBrowser$.MainActivity.openExternalBrowserToUrl(beva_url.bems_toJvString());
    """
    }
    }
  
  }

}

