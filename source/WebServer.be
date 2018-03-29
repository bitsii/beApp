// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
emit(cs) {
    """
using System;
//using System.Net;
using System.Threading;
using System.Web;
    """
}
use class Web:Server {
  
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
          $class/Web:ScriptRequest$ wr = new $class/Web:ScriptRequest$(request, response);
          wr.bem_new_0();
          bem_handleWeb_1(wr);
       } catch (Throwable t) { 
          t.printStackTrace();
       }
    }
    }
  """
  }
  
  emit(cs) {
  """
  public static volatile BEC_2_3_6_WebServer bevs_webServer;
  public void bems_handleWeb(HttpContext context)  {
    $class/Web:ScriptRequest$ request = new $class/Web:ScriptRequest$(context);
    request.bem_new_0();
    bem_handleWeb_1(request);
  }
  """
  }
  
  init() {
    fields {
      Int port = 8080;
      any app;
      Bool ssl = false;
      String sslPath;
      any sessionManager;
      IO:Log log =@ IO:Logs.get(self);
      Bool gzipOutput = false;
    }
  }
  
  new() self {
    init();
    sessionManager = Web:SessionManager.new();
  }
  
  new(_sessionManager) self {
    init();
    sessionManager = _sessionManager;
  }
  
  handleStartWeb() {
    if (app.can("handleStartWeb", 0)) {
      app.handleStartWeb();
    }
  }
  
  handleWeb(request) {
    any e;
    try {
      request.gzipOutput = gzipOutput;
      request.sessionManager = sessionManager;
      app.handleWeb(request);
    } catch (e) {
      ("got exception " + e).print();
      try {
        log.log("Caught exception handling request");
        if (log.will()) { log.log(e.toString()); }
      } catch (e) {
      }
    }
  }
  
  main() {
    start();
  }
  
  stop() {
    app.stop();
    emit(jv) {
    """
    server.stop();
    """
    }
  }

  start() {
    
    any ussl;
    if (ssl) {
      ussl = "notnull";
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
      contextFactory.setKeyStorePath(bevp_sslPath.bems_toJvString());
      contextFactory.setKeyStorePassword("kp");
      
      SslConnectionFactory sslConnectionFactory = new SslConnectionFactory(contextFactory, org.eclipse.jetty.http.HttpVersion.HTTP_1_1.toString());
      
      HttpConfiguration config = new HttpConfiguration();
      config.setSecureScheme("https");
      config.setSecurePort(bevp_port.bevi_int);
      
      HttpConfiguration sslConfiguration = new HttpConfiguration(config);
      //sslConfiguration.addCustomizer(new SecureRequestCustomizer());
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
    
    emit(cs) {
    """
    BEC_2_3_6_WebServer.bevs_webServer = this;
    """
    }
    
    return(null);
  }

}

//script request should eventually inherit from a Request which doesn't have the json stuff

use class Web:ScriptRequest {

  emit(cs) {
  """
  public HttpContext bevi_context;
  public HttpRequest bevi_req;
  public HttpResponse bevi_res;
  
  public $class/Web:ScriptRequest$(HttpContext bevi_context) {
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
    
    public $class/Web:ScriptRequest$(javax.servlet.http.HttpServletRequest bevi_req, javax.servlet.http.HttpServletResponse bevi_res) {
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
     string url = bevi_req.RawUrl; //includes query string, ?HttpRequest.Url.OriginalString
     if (url != null) {
       bevl_uri = new $class/Text:String$(url);
     }
     """
     }
     emit(jv) {
     """
     String url = bevi_req.getRequestURI();
     if (url != null) {
       bevl_uri = new $class/Text:String$(url);
     }
     """
     }
     return(uri);
   }
   
   queryStringGet() String {
     String qs;
     emit(jv) {
     """
     String qs = bevi_req.getQueryString();
     if (qs != null) {
       bevl_qs = new $class/Text:String$(qs);
     }
     """
     }
     return(qs);
   }
   
   embeddedGet() {
    return(false);
   }
   
   inputMethodGet() String {
     String val;
     emit(jv) {
     """
     String val = bevi_req.getMethod();
     if (val != null) {
       bevl_val = new $class/Text:String$(val);
     }
     """
     }
     return(val);
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
       string emaddr = bevi_req.ServerVariables["LOCAL_ADDR"];
       bevl_res = new $class/Text:String$(emaddr);
     }
     """
     }
     emit(jv) {
     """
     if (bevi_req != null) {
      bevl_res = new $class/Text:String$(bevi_req.getLocalAddr());
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
       string emaddr = bevi_req.UserHostAddress;
       bevl_res = new $class/Text:String$(emaddr);
     }
     """
     }
     emit(jv) {
     """
     if (bevi_req != null) {
       String emaddr = bevi_req.getRemoteAddr();
       bevl_res = new $class/Text:String$(emaddr);
     }
     """
     }
     return(res);
   }
   
   setOutputCookie(String name, String value, String path) {
     setOutputCookie(name, value, path, true, false);
   }
   
   setOutputCookie(String name, String value, String path, Bool httpOnly, Bool longTerm) {
     emit(cs) {
     """
     HttpCookie toAdd = new HttpCookie(beva_name.bems_toCsString(), beva_value.bems_toCsString());
     bevi_res.Cookies.Add(toAdd);
     """
     }
     emit(jv) {
     """
     Cookie toAdd = new Cookie(beva_name.bems_toJvString(), beva_value.bems_toJvString());
     if (beva_path != null) {
       toAdd.setPath(beva_path.bems_toJvString());
     }
     toAdd.setHttpOnly(beva_httpOnly.bevi_bool);
     if (beva_longTerm.bevi_bool) {
       toAdd.setMaxAge(157680000);//5 years
     }
     bevi_res.addCookie(toAdd);
     """
     }
   }
   
   getInputCookie(String name) String {
     emit(cs) {
     """
     string csname = beva_name.bems_toCsString();
     HttpCookie cook = bevi_req.Cookies.Get(csname);
     if (cook != null) {
       return new $class/Text:String$(cook.Value);
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
              return(new $class/Text:String$(cookie.getValue()));
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
     string[] vals = bevi_req.Headers.GetValues(beva_name.bems_toCsString());
     if (vals != null && vals.Length > 0) {
        bevl_val = new $class/Text:String$(vals[0]);
     }
     """
     }
     emit(jv) {
     """
     String emval = bevi_req.getHeader(beva_name.bems_toJvString());
     if (emval != null) {
       bevl_val = new $class/Text:String$(emval);
     }
     """
     }
     return(val);
   }
      
   inputHeaderKeysGet() Set {
     Set res = Set.new();
     String val;
     emit(jv) {
     """
     java.util.Enumeration<java.lang.String> emvals = bevi_req.getHeaderNames();
     if (emvals != null) {
        while (emvals.hasMoreElements()) {
         String emval = emvals.nextElement();
         if (emval != null) {
           bevl_val = new $class/Text:String$(emval);
           bevl_res.bem_addValue_1(bevl_val);
         }
       }
     }
     """
     }
     return(res);
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
     IO:Logs.get(self).log("In scriptArgGet, inputContent " + ic);
     return(unmar.unmarshall(ic));
   }
   
   scriptReturnSet(ret) {
     String oc = mar.marshall(ret);
     IO:Logs.get(self).log("In scriptReturnSet, outputContent " + oc);
     self.outputContentType =@ "application/json";
     self.outputContent = oc;
   }
   
   getParameter(String name) String {
       String value;
       emit(cs) {
       """
       string[] vals = bevi_req.QueryString.GetValues(beva_name.bems_toCsString());
       if (vals != null && vals.Length > 0) {
          bevl_value = new $class/Text:String$(vals[0]);
       }
       """
       }
       emit(jv) {
       """
       Object val = bevi_req.getParameter(beva_name.bems_toJvString());
       if (val != null) {
          bevl_value = new $class/Text:String$(val.toString());
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
     fields {
       any sessionManager;
       String serviceSessionKey;
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
        fields {
            IO:Writer outputWriter;
            String outputContentType =@ "text/html"; //sensible default
            Bool outputOpened = false;
            Json:Marshaller mar = Json:Marshaller.new();
            Json:Unmarshaller unmar = Json:Unmarshaller.new();
            Map context = Map.new();
            Bool continueHandling = true;
        }
    }
    
    inputContentTypeGet() String {
      return(self.getInputHeader("Content-Type"));
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
            if (self.shouldGzipOutput) {
              Bool gzo = true;
            }
            //("SETTING CONTENT TYPE " + outputContentType).print();
            emit(cs) {
            """
            bevi_res.ContentType = bevp_outputContentType.bems_toCsString();
            """
            }
            emit(jv) {
            """
            if (bevl_gzo != null) {
              bevi_res.setHeader("Content-Encoding", "gzip");
            }
            bevi_res.setContentType(bevp_outputContentType.bems_toJvString());
            """
            }
        }
    }
    
    shouldGzipOutputGet() Bool {
      fields {
        Bool gzipOutput;
      }
      if (def(gzipOutput) && gzipOutput) {
        return(self.canGzipOutput);
      }
      return(false);
    }
    
    canGzipOutputGet() Bool {
      String ac = getInputHeader("accept-encoding");
      if (def(ac) && ac.has("gzip")) {
        return(true);
      }
      return(false);
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
      fields {
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
            //("can gzip " + self.canGzipOutput).print();
            if (self.shouldGzipOutput) {
              Bool gzo = true;
            }
            outputWriter = IO:Writer.new();
            emit(cs) {
            """
            bevp_outputWriter.bevi_os = bevi_res.OutputStream;
            """
            }
            emit(jv) {
            """
            if (bevl_gzo != null) {
              bevp_outputWriter.bevi_os = new java.util.zip.GZIPOutputStream(bevi_res.getOutputStream());
            } else {
              bevp_outputWriter.bevi_os = bevi_res.getOutputStream();
            }
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

use Net:Socket:Listener;
use Net:Socket;
use Net:Socket:Reader as SocketReader;
use Net:Socket:Writer as SocketWriter;

class Net:PortForward {
   
   new(String _localHost, Int _localPort, String _remoteHost, Int _remotePort) self {
     fields {
      String localHost = _localHost;
      Int localPort = _localPort;
      String remoteHost = _remoteHost;
      Int remotePort = _remotePort;
      IO:Log log =@ IO:Logs.get(self);
     }
   }
   
   start() self {
     log.log("Listening on " + localHost + ":" + localPort + " forwarding to " + remoteHost + ":" + remotePort);
     Listener l = Listener.new(localHost, localPort);
     l.bind();
     while (true) {
      Socket loc = l.accept();
      log.log("Received connection");
      Socket rem = Socket.new(remoteHost, remotePort);
      log.log("Connected Remotely");
      ThinThread a = ThinThread.new(DataCopy.new(loc.reader, rem.writer));
      ThinThread b = ThinThread.new(DataCopy.new(rem.reader, loc.writer));
      log.log("Starting Threads");
      a.start();
      b.start();
      log.log("Threads Started");
     }
   }
   
}

use System:ThinThread;

use Net:PortForward:DataCopy;

class DataCopy {

  new(IO:Reader _input, IO:Writer _output) self {
    fields {
      IO:Reader input = _input;
      IO:Writer output = _output;
    }
  }
  
  main() {
    input.copyData(output);
  }

}


