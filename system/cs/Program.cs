using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using be;

namespace cswa
{
    public class Program
    {
        public static void Main(string[] args)
        {
            Startup.args = args;
            lock (Startup.handlerLock) {
              //BEC_2_3_11_AppRunMainOnce.runMainOnce(args);
              if (!Startup.haveRun) {
                //string[] margs = new string[0];
                try {
                    be.BEX_E.bems_relocMain(args);
                } catch (System.Exception t) {
                    Console.Write(t.ToString());
                }
                Startup.haveRun = true;
              }
            }
            string locurl = BEC_2_3_6_WebServer.bevs_webServer.bem_localUrlGet_0().bems_toCsString();
            CreateWebHostBuilder(args).UseUrls(locurl).Build().Run();
        }

        public static IWebHostBuilder CreateWebHostBuilder(string[] args) =>
            WebHost.CreateDefaultBuilder(args)
                .UseStartup<Startup>();
    }
}
