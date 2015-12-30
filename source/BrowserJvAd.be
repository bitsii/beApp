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
"""
}
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
        String[] margs = new String[0];
        try {
            be.BEL_4_Base.BEL_4_Base.main(margs);
        } catch (Throwable t) {
            System.err.println("Failed in main with " + t.getMessage());
            throw new Error(t.getMessage(), t);
        }
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

"""
}

  default() self {
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

}

use UI:WebBrowserImpl as WebImp;
use UI:BrowserScriptRequest;
