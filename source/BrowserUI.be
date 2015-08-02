
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

emit(jv) {
"""
import javafx.application.Application;
import javafx.scene.Group;
import javafx.scene.Scene;
import javafx.scene.layout.VBox;
import javafx.scene.web.WebEngine;
import javafx.scene.web.WebView;
import javafx.stage.Stage;
import netscape.javascript.JSObject;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.concurrent.Worker.State;
"""
}
use UI:JvFx:WebBrowser as FxBr;
class FxBr {

 emit(jv) {
    """
    
    public Stage stage;
    public static BEC_2_4_10_UIJvFxWebBrowser sinst;
    
    public static class BECS_FxWebBrowser extends Application {
    
        @Override
        public void start(Stage stage) {
        
          try {
            //handler setup happens here
            sinst = BEC_2_4_10_UIJvFxWebBrowser.bevs_inst;
            sinst.bem_initWeb_0();
            sinst.stage = stage;
        
            stage.setTitle(sinst.bem_titleGet_0().bems_toJvString());
            stage.setWidth(sinst.bem_widthGet_0().bevi_int);                 
            stage.setHeight(sinst.bem_heightGet_0().bevi_int);
            Scene scene = new Scene(new Group());
      
            VBox root = new VBox();     
      
            final WebView browser = new WebView();
            final WebEngine webEngine = browser.getEngine();
      
            BEC_4_6_TextString cont = sinst.bem_contentGet_0();
            if (cont != null) {
              webEngine.loadContent(cont.bems_toJvString());
            } else {
              BEC_4_6_TextString loc = sinst.bem_locationGet_0();
              if (loc != null) {
                webEngine.load(loc.bems_toJvString());
              }
            }
            webEngine.getLoadWorker().stateProperty().addListener(
              new ChangeListener<State>() {  
                  @Override
                  public void changed(ObservableValue<? extends State>
                      ov, State oldState, State newState) {
                      if (newState == State.SUCCEEDED
                          || newState == State.FAILED) {
                          JSObject win = (JSObject) 
                          webEngine.executeScript("window");
                          win.setMember("external", sinst);
                          webEngine.executeScript("startup();");
                      }
                  }
              });
            root.getChildren().addAll(browser);
            scene.setRoot(root);
      
            stage.setScene(scene);
            stage.show();
          } catch (Throwable t) {
            throw new RuntimeException(t.getMessage(), t);
          }
        }
     
        public static void main(String[] args) {
            launch(args);
        }
    }
    
    public Object HandleCall(Object obj) {
      try {
        if (obj == null) {
          System.err.println("got a null obj in HandleCall");
        } else {
          //System.out.println("HANDLE CALL GOT " + obj);
          String objstr = obj.toString();
          BEC_4_6_TextString objbes = new BEC_4_6_TextString(objstr);
          BEC_4_6_TextString resbes = sinst.bem_handleWeb_1(objbes);
          if (resbes != null) {
            return resbes.bems_toJvString();
          }
        }
      } catch (Throwable t) {
        //throw new RuntimeException(t.getMessage(), t);
        System.err.println("got exception " + t.getMessage());
        t.printStackTrace();
      }
      return null;
    }
    """
    }

  default() self {
        properties {
            var setupHandler;
            var webHandler;
        }
   }
   
   setupStuff() {
     vars {
        IO:Log log = IO:Log.new();
        //Int lvl = log.debug;
        Int lvl = log.info;
        Map session = Map.new();
     }
   }
   
   initWeb() self {
     setupStuff();
     webHandler.initWeb();
   }
   
   setup() {
    emit(jv) {
    """
    BECS_FxWebBrowser.main(new String[]{});
    """
    }
  }
  
  close() {
    emit(jv) {
    """
    stage.hide();
    """
    }
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
  
  handleWeb(String arg) String {
    log.log(lvl, "in handleWeb, arg " + arg);
    BrowserScriptRequest r = BrowserScriptRequest.new(session);
    r.scriptArgJson = arg;
    webHandler.handleWeb(r);
    String ret = r.scriptReturnJson;
    log.log(lvl, "in handleWeb, ret " + ret);
    return(ret);
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
      //only populated if winform
      WfBr winForm;
      //same for jv
      FxBr fx;
    }
    ifEmit(cs) {
      browserType = "winform";
    }
    ifEmit(jv) {
      browserType = "jvfx";
    }
  }

  setup() {
    unless (haveSetup) {
      haveSetup = true;
      if (browserType == "winform") {
        winForm = WfBr.new();
        winForm.setupHandler = self;
        winForm.webHandler = webHandler;
        winForm.setup();
      }
      if (browserType == "jvfx") {
        fx = FxBr.new();
        fx.setupHandler = self;
        fx.webHandler = webHandler;
        fx.setup();
      }
    }
  }
  
  close() {
    if (browserType == "winform") {
      winForm.close();
    } elif (browserType == "jvfx") {
      fx.close();
    }
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
class WfBr {

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
        properties {
            var setupHandler;
            var webHandler;
        }
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

emit(jv) {
"""
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.ServletException;
import javax.servlet.http.Cookie;
 
import java.io.IOException;
 
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.Request;
import org.eclipse.jetty.server.handler.AbstractHandler;

//ssl
import org.eclipse.jetty.util.ssl.SslContextFactory;
import org.eclipse.jetty.server.*;
"""
}
use class Web:Server {

  emit(cs) {
  """
  public volatile Mono.Net.HttpListener bevi_listener = new Mono.Net.HttpListener();
  public void bems_handleWeb(object o)  {
    Mono.Net.HttpListenerContext context = o as Mono.Net.HttpListenerContext;
    BEC_3_13_WebScriptRequest request = new BEC_3_13_WebScriptRequest(context);
    request.bem_new_0();
    bem_handleWeb_1(request);
  }
  """
  }
  
  emit(jv) {
  """
  public Server server;
  public class BECS_WebHandler extends AbstractHandler
  {
    public void handle(String target,
                       Request baseRequest,
                       HttpServletRequest request,
                       HttpServletResponse response) 
        throws IOException, ServletException
    {
      try {
          BEC_3_13_WebScriptRequest wr = new BEC_3_13_WebScriptRequest(request, response);
          wr.bem_new_0();
          bem_handleWeb_1(wr);
       } catch (Throwable t) { 
          t.printStackTrace();
       }
    }
    }
  """
  }
  
  new() self {
    vars {
      Int port = 8080;
      var app;
      Bool ssl = false;
      String sslPath;
      var sessionManager = Web:SessionManager.new();
      IO:Log log = IO:Log.new();
      Int lvl = log.debug;
    }
  }
  
  handleStartWeb() {
    if (app.can("handleStartWeb", 0)) {
      app.handleStartWeb();
    }
  }
  
  handleWeb(request) {
    var e;
    try {
      request.sessionManager = sessionManager;
      app.handleWeb(request);
    } catch (e) {
      try {
        log.log(lvl, "Caught exception handling request");
        if (log.will(lvl)) { log.log(lvl, e.toString()); }
      } catch (e) {
      }
    }
  }
  
  main() {
    start();
  }
  
  stop() {
    emit(cs) {
    """
    bevi_listener.Prefixes.Remove(bevp_listenerPrefix.bems_toCsString());
    bevi_listener.Stop();
    """
    }
    emit(jv) {
    """
    server.stop();
    """
    }
  }

  start() {
    emit(cs) {
    """
    if (!Mono.Net.HttpListener.IsSupported)
    {
        throw new Exception("Mono.Net.HttpListener is not supported.");
    }
    """
    }
    
    var ussl;
    if (ssl) {
      ussl = "notnull";
    }
    
    ifEmit(cs) {
      if (ssl) {
        String bt = "https://+:" += port.toString() + "/";
      } else {
        bt = "http://+:" += port.toString() + "/";
      }
      vars {
        String listenerPrefix = bt;
      }
    }
    emit(cs) {
    """
    bevi_listener.Prefixes.Add(bevl_bt.bems_toCsString());
    """
    }
    
    emit(cs) {
    """
    bevi_listener.Start();
    //Won't get here if start failed, port in use, etc
    bem_handleStartWeb_0();
    while(true) {
      try {
        ThreadPool.QueueUserWorkItem(bems_handleWeb, bevi_listener.GetContext());  
      } catch (Mono.Net.HttpListenerException hle) {
        //should indicate shutdown
        break;
      }
    }
    """
    }
    
    emit(jv) {
    """
    if (bevl_ussl == null) {
      //for http
      server = new Server(bevp_port.bevi_int);
    } else {
      //for https
      server = new Server();
  
      SslContextFactory contextFactory = new SslContextFactory();
      //contextFactory.setKeyStorePath("keystore");
      //contextFactory.setKeyStorePassword("boohiss");
      contextFactory.setKeyStorePath(bevp_sslPath.bems_toJvString());
      contextFactory.setKeyStorePassword("kp");
      SslConnectionFactory sslConnectionFactory = new SslConnectionFactory(contextFactory, org.eclipse.jetty.http.HttpVersion.HTTP_1_1.toString());
      
      HttpConfiguration config = new HttpConfiguration();
      config.setSecureScheme("https");
      config.setSecurePort(bevp_port.bevi_int);
      HttpConfiguration sslConfiguration = new HttpConfiguration(config);
      sslConfiguration.addCustomizer(new SecureRequestCustomizer());
      HttpConnectionFactory httpConnectionFactory = new HttpConnectionFactory(sslConfiguration);
      
      ServerConnector connector = new ServerConnector(server, sslConnectionFactory, httpConnectionFactory);
      connector.setPort(bevp_port.bevi_int);
      server.addConnector(connector);
    }
    server.setHandler(new BECS_WebHandler());

    server.start();
    //Won't get here if start failed, port in use, etc
    bem_handleStartWeb_0();
    server.join();
    """
    }
    
    return(null);
  }

}

use System:Thread:ContainerLocker as CLocker;

use class Web:SessionManager {

  new() self {
    vars {
      CLocker sessions = CLocker.new(Map.new());
      String keyName = "sesskey";
      Int keyLen = 16;
    }
  }
  
  getSession(request) {
    
    String sk = request.getInputHeader(keyName);
    if (TS.isEmpty(sk)) {
      sk = request.getInputCookie(keyName);
    }
    if (TS.notEmpty(sk)) {
      CLocker s = sessions.get(sk);
      //to make it harder to probe for sessions
      if (undef(s)) {
        s = sessions.getOrPut(sk, CLocker.new(Map.new()));
      }
      request.setOutputHeader(keyName, sk);
    } else {
      s = CLocker.new(Map.new());
      sk = System:Random.getString(keyLen);
      until (sessions.putIfAbsent(sk, s)) {
        sk = System:Random.getString(keyLen);
      }
      request.setOutputCookie(keyName, sk);
      request.setOutputHeader(keyName, sk);
    }
    return(s);
  }
  
  deleteSession(request) {
    String sk = request.getInputCookie(keyName);
    if (TS.notEmpty(sk)) {
      sessions.delete(sk);
    }
    request.setOutputCookie(keyName, "");
  }
  
  getSession(request, String name) String {
    return(getSession(request).get(name));
  }
  
  putSession(request, String name, String value) {
    getSession(request).put(name, value);
  }

}

//script request should eventually inherit from a Request which doesn't have the json stuff

use class Web:ScriptRequest {

  emit(cs) {
  """
  public Mono.Net.HttpListenerContext bevi_context;
  public Mono.Net.HttpListenerRequest bevi_req;
  public Mono.Net.HttpListenerResponse bevi_res;
  
  public BEC_3_13_WebScriptRequest(Mono.Net.HttpListenerContext bevi_context) {
      this.bevi_context = bevi_context;
      this.bevi_req = bevi_context.Request;
      this.bevi_res = bevi_context.Response;
      bem_new_0();
  }
  """
  }
  
  emit(jv) {
   """
    public javax.servlet.http.HttpServletRequest bevi_req;
    public javax.servlet.http.HttpServletResponse bevi_res;
    
    public BEC_3_13_WebScriptRequest(javax.servlet.http.HttpServletRequest bevi_req, javax.servlet.http.HttpServletResponse bevi_res) {
        this.bevi_req = bevi_req;
        this.bevi_res = bevi_res;
        try {
        bem_new_0();
        } catch (Throwable t) { }
    }
    
   """
   }
   
   uriGet() String {
     String uri;
     emit(cs) {
     """
     string url = bevi_req.RawUrl;
     if (url != null) {
       bevl_uri = new BEC_4_6_TextString(url);
     }
     """
     }
     emit(jv) {
     """
     String url = bevi_req.getRequestURI();
     if (url != null) {
       bevl_uri = new BEC_4_6_TextString(url);
     }
     """
     }
     return(uri);
   }
   
   inputAddressGet() String {
     String addr = getInputHeader("X-Forwarded-For");
      if (TS.isEmpty(addr) || addr.lower() == "unknown") {
          addr = getInputHeader("WL-Proxy-Client-IP");
      }
      if (TS.isEmpty(addr) || addr.lower() == "unknown") {  
          addr = getInputHeader("Proxy-Client-IP");
      }
      if (TS.isEmpty(addr) || addr.lower() == "unknown") {  
          addr = getInputHeader("HTTP_CLIENT_IP");
      }
      if (TS.isEmpty(addr) || addr.lower() == "unknown") {  
          addr = getInputHeader("HTTP_X_FORWARDED_FOR");
      }
      if (TS.isEmpty(addr) || addr.lower() == "unknown") {  
          addr = self.remoteAddress;
      }
      return(addr);
   }
   
   localAddressGet() String {
     String res;
     emit(cs) {
     """
     if (bevi_req != null) {
       string emaddr = bevi_req.LocalEndPoint.Address.ToString();
       bevl_res = new BEC_4_6_TextString(emaddr);
     }
     """
     }
     emit(jv) {
     """
     if (bevi_req != null) {
      bevl_res = new BEC_4_6_TextString(bevi_req.getLocalAddr());
     }
     """
     }
     return(res);
   }
   
   //inputAddressGet does the header check
   remoteAddressGet() String {
     String res;
     emit(cs) {
     """
     if (bevi_req != null) {
       string emaddr = bevi_req.RemoteEndPoint.Address.ToString();
       bevl_res = new BEC_4_6_TextString(emaddr);
     }
     """
     }
     emit(jv) {
     """
     if (bevi_req != null) {
       String emaddr = bevi_req.getRemoteAddr();
       bevl_res = new BEC_4_6_TextString(emaddr);
     }
     """
     }
     return(res);
   }
   
   setOutputCookie(String name, String value) {
     emit(cs) {
     """
     Cookie toAdd = new Cookie(beva_name.bems_toCsString(), beva_value.bems_toCsString());
     bevi_res.Cookies.Add(toAdd);
     """
     }
     emit(jv) {
     """
     Cookie toAdd = new Cookie(beva_name.bems_toJvString(), beva_value.bems_toJvString());
     bevi_res.addCookie(toAdd);
     """
     }
   }
   
   getInputCookie(String name) String {
     emit(cs) {
     """
     string csname = beva_name.bems_toCsString();
     foreach (Cookie cook in bevi_req.Cookies) {
       if (cook.Name == csname) {
         return(new BEC_4_6_TextString(cook.Value));
       }
     }
     """
     }
     emit(jv) {
     """
      String jvname = beva_name.bems_toJvString();
      Cookie[] cookies = bevi_req.getCookies();
      if (cookies != null) 
      {
          for(int i=0; i<cookies.length; i++) 
          {
            Cookie cookie = cookies[i];
            if (jvname.equals(cookie.getName())) {
              return(new BEC_4_6_TextString(cookie.getValue()));
            }
          }
      }
     """
     }
     return(null);
   }
   
   getInputHeader(String name) String {
     String val;
     emit(cs) {
     """
     String[] vals = bevi_req.Headers.GetValues(beva_name.bems_toCsString());
     if (vals != null && vals.Length > 0) {
        bevl_val = new BEC_4_6_TextString(vals[0]);
     }
     """
     }
     emit(jv) {
     """
     String emval = bevi_req.getHeader(beva_name.bems_toJvString());
     if (emval != null) {
       bevl_val = new BEC_4_6_TextString(emval);
     }
     """
     }
     return(val);
   }
   
   setOutputHeader(String name, String value) {
     String val;
     emit(cs) {
     """
     bevi_res.AddHeader(beva_name.bems_toCsString(),
       beva_value.bems_toCsString());
     """
     }
     emit(jv) {
     """
     bevi_res.addHeader(beva_name.bems_toJvString(),
       beva_value.bems_toJvString());
     """
     }
     return(val);
   }
   
   inputContentGet() String {
      //arrange to work for multiple goes
      String ret = openInput().readString();
      closeInputReader();
      return(ret);
   }
   
   outputContentSet(String content) {
      openOutput().write(content);
      closeOutputWriter();
   }
   
   scriptArgGet() {
     String ic = self.inputContent;
     IO:Log.log(IO:Log.debug, "In scriptArgGet, inputContent " + ic);
     return(unmar.unmarshall(ic));
   }
   
   scriptReturnSet(ret) {
     String oc = mar.marshall(ret);
     IO:Log.log(IO:Log.debug, "In scriptReturnSet, outputContent " + oc);
     self.outputContentType =@ "application/json";
     self.outputContent = oc;
   }
   
   getParameter(String name) String {
       String value;
       emit(cs) {
       """
       String[] vals = bevi_req.QueryString.GetValues(beva_name.bems_toCsString());
       if (vals != null && vals.Length > 0) {
          bevl_value = new BEC_4_6_TextString(vals[0]);
       }
       """
       }
       emit(jv) {
       """
       Object val = bevi_req.getParameter(beva_name.bems_toJvString());
       if (val != null) {
          bevl_value = new BEC_4_6_TextString(val.toString());
       }
       """
       }
       return(value);
   }
   
   deleteSession()  {
     if (def(sessionManager)) {
       return(sessionManager.deleteSession(self));
     }
     return(null);
   }
   
   getSession(String name) String {
     vars {
       var sessionManager;
     }
     if (def(sessionManager)) {
       return(sessionManager.getSession(self, name));
     }
     return(null);
   }
   
   putSession(String name, String value) self {
     if (def(sessionManager)) {
       sessionManager.putSession(self, name, value);
     }
   }

    new() self {
        properties {
            IO:Writer outputWriter;
            String outputContentType =@ "text/html"; //sensible default
            Bool outputOpened = false;
            Json:Marshaller mar = Json:Marshaller.new();
            Json:Unmarshaller unmar = Json:Unmarshaller.new();
        }
    }
    
    openOutput() IO:Writer {
        if (outputOpened!) {
            //do all the onetime things, content type, cookies, etc
            sendContentType();
            //open the writer last
            openOutputWriter();
        }
        return(outputWriter);
    }
    
    sendContentType() {
        if (def(outputContentType)) {
            emit(cs) {
            """
            bevi_res.ContentType = bevp_outputContentType.bems_toCsString();
            """
            }
            emit(jv) {
            """
            bevi_res.setContentType(bevp_outputContentType.bems_toJvString());
            """
            }
        }
    }
    
    closeOutput() self {
        if (outputOpened) {
            closeOutputWriter();
            outputOpened = false;
        }
    }
    
    openInput() IO:Reader {
      //later ? check for already opened, etc?
      return(openInputReader());
    }
    
    openInputReader() IO:Reader {
      properties {
        IO:Reader inputReader;
      }
      inputReader = IO:Reader.new();
        emit(cs) {
        """
        bevp_inputReader.bevi_is = bevi_req.InputStream;
        """
        }
        emit(jv) {
        """
        bevp_inputReader.bevi_is = bevi_req.getInputStream();
        """
        }
        inputReader.extOpen();
      return(inputReader);
    }
    
    closeInputReader() self {
      if (def(inputReader)) {
          inputReader.close();
          inputReader = null;
      }
    }
    
    openOutputWriter() IO:Writer {
        if (undef(outputWriter)) {
            outputWriter = IO:Writer.new();
            emit(cs) {
            """
            bevp_outputWriter.bevi_os = bevi_res.OutputStream;
            """
            }
            emit(jv) {
            """
            bevp_outputWriter.bevi_os = bevi_res.getOutputStream();
            """
            }
            outputWriter.extOpen();
        }
        return(outputWriter);
    }
    
    closeOutputWriter() self {
        if (def(outputWriter)) {
            outputWriter.close();
            outputWriter = null;
        }
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
    
    emit(jv) {
    """
    java.awt.Desktop desktop = java.awt.Desktop.getDesktop();
    desktop.browse(new java.net.URI(beva_url.bems_toJvString()));
    """
    }
  
  }

}

