// Copyright 2015 Craig Welch
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

emit(cs) {
"""

using System;
using System.Windows.Forms;
using System.Security.Permissions;

[PermissionSet(SecurityAction.Demand, Name = "FullTrust")]
public class BeWebBrowser : Form
{

    [STAThread]
    static void Main()
    {
        //add to csc /main:be.BeWebBrowser
        be.BEL_4_Base.Main(new string[] {});
    }
    
    public void BeRun() {
      Application.EnableVisualStyles();
      Application.Run(this);
    }

}

"""
}

use UI:WinForm:WebBrowser as WfBr;
class WfBr(WebImp) {

   //wf specific
   emit(cs) {
   """
    public BeWebBrowser bevi_beWebBrowser;
    public WebBrowser bevi_webBrowser;
    
    public string HandleCall(string call) {
      $class/Text:String$ ret = bem_handleWeb_1(new $class/Text:String$(call));
      if (ret != null) {
        return ret.bems_toCsString();
      }
      return null;
    }
    
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

    }
    
    setup() {
      emit(cs) {
      """
      bevi_beWebBrowser = new BeWebBrowser();
      """
      }
      uiSetup();
      emit(cs) {
      """
      bevi_beWebBrowser.BeRun();
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
    
    new() self {
     
     fields {
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
     //bevi_beWebBrowser.ConnectWithScript(bevi_webBrowser, this);//winform or winform handler
     bevi_webBrowser.ObjectForScripting = this;
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

use UI:WebBrowserImpl as WebImp;
use UI:BrowserScriptRequest;
