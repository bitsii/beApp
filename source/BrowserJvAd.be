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
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.JavascriptInterface;
"""
}

/*
Example of android app component, just extend the activity below

public class MainActivity extends be.BEL_4_Base.BEC_2_4_10_UIJvAdWebBrowser.MainActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        mWebView = (WebView) findViewById(R.id.webView);
        postCreate();
    }
}
*/

use UI:JvAd:WebBrowser as AdBr;
class AdBr(WebImp) {

emit(jv) {
"""
public static class MainActivity extends AppCompatActivity {

    public static MainActivity mainActivity;
    
    public WebView mWebView;

    protected void postCreate() {
        WebSettings webSettings = mWebView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        //so things stay in the webview
        mWebView.setWebViewClient(new WebViewClient());
        mainActivity = this;
        BEC_3_11_AppRunMainOnce.runMainOnce();
        BEC_3_13_AppEventHandlers.handleEvent("startUi");
        mWebView.addJavascriptInterface(new WebAppInterface(), "Android");
        //mWebView.loadUrl("https://some.place");
    }

    @Override
    public void onBackPressed() {
        if(mWebView.canGoBack()) {
            mWebView.goBack();
        } else {
            super.onBackPressed();
        }
    }
  }
  
  public static class WebAppInterface {

      @JavascriptInterface
      public String HandleCall(String objstr) {
          try {
          if (objstr == null) {
            System.err.println("got a null obj in HandleCall");
          } else {
            BEC_4_6_TextString objbes = new BEC_4_6_TextString(objstr);
            BEC_2_4_10_UIJvAdWebBrowser sinst = BEC_2_4_10_UIJvAdWebBrowser.bevs_inst;
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
   initWeb();
   String loc = setupHandler.location;
   emit(jv) {
   """
   MainActivity.mainActivity.mWebView.loadUrl(bevl_loc.bems_toJvString());
   """
   }
     
  }
  
  close() {
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
  
  appDataDirGet() String {
  String toRet;
  ifEmit(platDroid) {
  emit(jv) {
  """
  String ddir = MainActivity.mainActivity.getApplicationContext().getApplicationInfo().dataDir;
  bevl_toRet = new BEC_4_6_TextString(ddir);
  """
  }
  }
  return(toRet);
  }

}

use UI:WebBrowserImpl as WebImp;
use UI:BrowserScriptRequest;



