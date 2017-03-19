// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

emit(jv) {
"""
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.JavascriptInterface;

import android.content.Intent;
import android.net.Uri;
"""
}

/*
//Example of android app component, just extend the activity below

public class MainActivity extends be.BEC_3_2_4_10_UIJvAdWebBrowser.MainActivity {
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

    public static volatile MainActivity mainActivity;
    
    public WebView mWebView;
    
    public String initialUrl;
    
    public static void openExternalBrowserToUrl(String toUrl) {
    
      Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(toUrl));
      browserIntent.setFlags( 
                Intent.FLAG_ACTIVITY_NEW_TASK 
                | Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS); 
      mainActivity.startActivity(browserIntent);
      
    }

    protected void postCreate() {
        mainActivity = this;
        $class/App:RunMainOnce$.runMainOnce();
        $class/App:EventHandlers$.handleEvent("startUi");
        //so things stay in the webview
        mWebView.setWebViewClient(new WebViewClient());
        mWebView.addJavascriptInterface(new WebAppInterface(), "Android");
        WebSettings webSettings = mWebView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        //mWebView.loadUrl("https://some.place");
        mWebView.loadUrl(initialUrl);
    }

    @Override
    public void onBackPressed() {
      //startActivity(new Intent(getApplicationContext(), NextActivity.class));
      //finish();
      System.exit(0);
        /*if(mWebView.canGoBack()) {
            mWebView.goBack();
        } else {
            super.onBackPressed();
        }*/
    }
  }
  
  public static class WebAppInterface {

      @JavascriptInterface
      public String HandleCall(String objstr) {
          try {
          if (objstr == null) {
            System.err.println("got a null obj in HandleCall");
          } else {
            $class/Text:String$ objbes = new $class/Text:String$(objstr);
            $class/UI:JvAd:WebBrowser$ sinst = $class/UI:JvAd:WebBrowser$.bevs_inst;
            $class/Text:String$ resbes = sinst.bem_handleWeb_1(objbes);
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
     fields {
        IO:Log log =@ IO:Logs.get(self);
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
   //MainActivity.mainActivity.mWebView.loadUrl(bevl_loc.bems_toJvString());
   MainActivity.mainActivity.initialUrl = bevl_loc.bems_toJvString();
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
    log.log("in handleWeb, arg " + arg);
    BrowserScriptRequest r = BrowserScriptRequest.new(session);
    r.scriptArgJson = arg;
    webHandler.handleWeb(r);
    String ret = r.scriptReturnJson;
    if (def(ret)) {
      log.log("in handleWeb, ret " + ret);
    }
    return(ret);
  }
  
  appDataDirGet() String {
  String toRet;
  ifEmit(platDroid) {
  emit(jv) {
  """
  String ddir = MainActivity.mainActivity.getApplicationContext().getApplicationInfo().dataDir;
  bevl_toRet = new $class/Text:String$(ddir);
  """
  }
  }
  return(toRet);
  }

}

use UI:WebBrowserImpl as WebImp;
use UI:BrowserScriptRequest;



