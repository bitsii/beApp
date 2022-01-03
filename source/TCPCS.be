// Copyright 2015 The BraceApp Authors. All rights reserved.
// Use of this source code is governed by the BSD-3-Clause
// license that can be found in the LICENSE file.

emit(java) {
"""
import java.io.*;                                                               
import java.net.*;  
"""
}

class App:TCPServer {

   emit(java) {
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
    emit(java) {
    """
    server = new ServerSocket(bevp_port.bevi_int);
    """
    }
  }
  
  checkGetClient() App:TCPClient {
    App:TCPClient res;
    emit(java) {
    """
    Socket client = server.accept();
    """
    }
    res = App:TCPClient.new();
    res.opened = true;
    emit(java) {
    """
    bevl_res.client = client;
    """
    }
    return(res);
  }
  
}

class App:TCPClient {

emit(java) {
"""

public Socket client;
public InputStream input;
public OutputStream output;

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
    emit(java) {
    """
    if (outputStream == null) {
      outputStream = client.getOutputStream();
    }
    outputStream.write(beva_line.bevi_bytes, 0, len.bevi_int);
    """
    }
  }
  
  checkGetPayload() String {
    return(checkGetPayload(null));
  }
  
  checkGetPayload(String endmark) String {
    String payload = String.new();
    Int chari = Int.new();
    String chars = String.new(1);
    chars.setCodeUnchecked(0, 32);
    chars.size.setValue(1);
    Int zero = 0;
    emit(java) {
    """      
      if (inputStream == null) {
        inputStream = client.getInputStream();
      }
      while (inputStream.available() > 0) {     
          int c = inputStream.read(); 
          //Serial.write(c);  
          bevl_chari.bevi_int = c;
          """
          }
          //("got int " + chari).print();
          chars.setCodeUnchecked(zero, chari);
          ("got char").print();
          chars.print();
          payload += chars;
          if (def(endmark) && payload.ends(endmark)) {
            "got endmark".print();
            payload.print();
            return(payload);
          }
emit(java) {
"""        
        }
    }
    """
    }
    if (TS.notEmpty(payload)) {
    "got request, payload".print();
    payload.print();
    }
    return(payload);
  }
  
  close() {
    emit(java) {
    """ 
    client.close();
    """
    }
    opened = false;
  }

}
