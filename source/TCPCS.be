// Copyright 2015 The BraceApp Authors. All rights reserved.
// Use of this source code is governed by the BSD-3-Clause
// license that can be found in the LICENSE file.

emit(jv) {
"""
import java.io.*;                                                               
import java.net.*;  
"""
}

class App:TCPServer {

   emit(jv) {
   """
   public ServerSocket server;
   """
   }
  
  new(Int _port) self {
    fields {
      Int port = _port; //light 55443
    }
  }
  
  start() {
    emit(jv) {
    """
    server = new ServerSocket(bevp_port.bevi_int);
    """
    }
  }
  
  checkGetClient() App:TCPClient {
    App:TCPClient res;
    emit(jv) {
    """
    Socket client = server.accept();
    """
    }
    res = App:TCPClient.new();
    res.opened = true;
    emit(jv) {
    """
    bevl_res.client = client;
    """
    }
    return(res);
  }
  
}

class App:TCPClient {

emit(jv) {
"""

public Socket client;
public InputStream inputStream;
public OutputStream outputStream;

"""
}

  new() self {
    fields {
      String host;
      Int port;
      Bool opened;
    }
  }
  
  new(String _host, Int _port) {
    host = _host;
    port = _port;
    opened = false;
  }
  
  open() self {
    opened = true;
    return(self);
  }
  
  write(String line) self {
    Int len = line.size;
    emit(jv) {
    """
    if (outputStream == null) {
      outputStream = client.getOutputStream();
    }
    outputStream.write(beva_line.bevi_bytes, 0, bevl_len.bevi_int);
    """
    }
  }
  
  getPayload(String endmark) String {
    String payload = String.new();
    Int chari = Int.new();
    String chars = String.new(1);
    chars.setCodeUnchecked(0, 32);
    chars.size.setValue(1);
    Int zero = 0;
    emit(jv) {
    """      
      if (inputStream == null) {
        inputStream = client.getInputStream();
      }
      while (client.isConnected()) {    
          int c = inputStream.read(); 
          //Serial.write(c);  
          bevl_chari.bevi_int = c;
          """
          }
          //("got int " + chari).print();
          chars.setCodeUnchecked(zero, chari);
          //("got char").print();
          //chars.print();
          payload += chars;
          if (def(endmark) && payload.ends(endmark)) {
            //"got endmark".print();
            //payload.print();
            return(payload);
          }
emit(jv) {
"""        
    }
    """
    }
    //if (TS.notEmpty(payload)) {
    //"got request, payload".print();
    //payload.print();
    //}
    return(payload);
  }
  
  connectedGet() Bool {
    emit(jv) {
    """
    if (client != null && client.isConnected()) {
    """
    }
    return(true);
    emit(jv) {
    """
    }
    """
    }
    return(false);
  }
  
  close() {
    emit(jv) {
    """ 
    client.close();
    """
    }
    opened = false;
  }

}
