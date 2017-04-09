using System;
using System.Web;
using System.Text;
using be;

namespace csaweb
{
	public class BECS_WebHandler : IHttpHandler
	{
    
    public static volatile Object handlerLock = new Object();
    public static volatile BEC_2_3_6_WebServer bevs_webServer;
    
		public BECS_WebHandler()
		{
      lock (handlerLock) {
        BEC_2_3_11_AppRunMainOnce.runMainOnce();
      //  if (bevs_webServer == null) {
      //    bevs_webServer = BEC_2_3_6_WebServer.bevs_webServer;
      //  }
      }
		}

		public bool IsReusable
		{
			get { return false; }
		}

		public void ProcessRequest(HttpContext context)
		{
      
			var result = "<h1>Yeah</h1>";
			var bytes = Encoding.UTF8.GetBytes(result);

			context.Response.Write(result);
		}
	}
}
