// Copyright 2015 The BraceApp Authors. All rights reserved.
// Use of this source code is governed by the BSD-3-Clause
// license that can be found in the LICENSE file.

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
import android.content.Context;
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
    
    public static volatile Context appContext;
    
    public WebView mWebView;
    
    public String initialUrl;
    
    public static void openExternalBrowserToUrl(String toUrl) {
    
      Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(toUrl));
      browserIntent.setFlags( 
                Intent.FLAG_ACTIVITY_NEW_TASK 
                | Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS); 
      mainActivity.startActivity(browserIntent);
      
    }
    
    public String[] getStartupArgs() {
      return new String[] {};
    }

    protected void postCreate() {
        mainActivity = this;
        appContext = getApplicationContext();
        $class/App:RunMainOnce$.runMain(getStartupArgs());
        $class/App:EventHandlers$.handleEvent("startUi");
        //so things stay in the webview
        mWebView.setWebViewClient(new WebViewClient());
        mWebView.addJavascriptInterface(new WebAppInterface(), "Android");
        WebSettings webSettings = mWebView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setAppCacheEnabled(true);
        webSettings.setDatabaseEnabled(true);
        webSettings.setAllowFileAccessFromFileURLs(true);
        webSettings.setAllowUniversalAccessFromFileURLs(true);
        //mWebView.loadUrl("");
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
            //System.err.println("doing a handlecall");
            $class/Text:String$ objbes = new $class/Text:String$(objstr);
            $class/UI:JvAd:WebBrowser$ sinst = $class/UI:JvAd:WebBrowser$.bece_BEC_3_2_4_10_UIJvAdWebBrowser_bevs_inst;
            $class/Text:String$ resbes = sinst.bem_outerHandleWeb_1(objbes);
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
  
  outerHandleWeb(String allArgs) String {
    auto ll = splitAllArgs(allArgs);
    return(handleWeb(ll[0], ll[1], ll[2]));  
  }
  
  handleWeb(String arg, String uri, String ctype) String {
    log.log("in handleWeb, arg " + arg);
    try {
      BrowserScriptRequest r = BrowserScriptRequest.new(session);
      r.scriptArgJson = arg;
      r.uri = uri;
      r.inputContentType = ctype;
      webHandler.handleWeb(r);
      String ret = r.scriptReturnJson;
      if (def(ret)) {
        log.log("in handleWeb, ret " + ret);
      }
    } catch (any e) {
      log.log(System:Exceptions.toString(e));
    }
    return(ret);
  }
  
  appDataDirGet() String {
  String toRet;
  ifEmit(platDroid) {
  emit(jv) {
  """
  //main activity is null in jobservice
  String ddir = MainActivity.appContext.getApplicationInfo().dataDir;
  bevl_toRet = new $class/Text:String$(ddir);
  """
  }
  }
  return(toRet);
  }

}

use UI:WebBrowserImpl as WebImp;
use UI:BrowserScriptRequest;



