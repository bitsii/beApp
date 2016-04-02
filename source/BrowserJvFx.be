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
class FxBr(WebImp) {

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
   }
   
   setupStuff() {
     properties {
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
    if (def(arg)) {
      log.log(lvl, "in handleWeb, arg " + arg);
    }
    BrowserScriptRequest r = BrowserScriptRequest.new(session);
    r.scriptArgJson = arg;
    webHandler.handleWeb(r);
    String ret = r.scriptReturnJson;
    if (def(ret)) {
      log.log(lvl, "in handleWeb, ret " + ret);
    }
    return(ret);
  }

}

use UI:WebBrowserImpl as WebImp;
use UI:BrowserScriptRequest;
