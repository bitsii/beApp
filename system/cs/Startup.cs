using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using be;

namespace cswa
{
    public class Startup
    {
        public static volatile Object handlerLock = new Object();
        public static volatile BEC_2_3_6_WebServer bevs_webServer;
        public static volatile string[] args;
        public static volatile bool haveRun = false;
    
        // This method gets called by the runtime. Use this method to add services to the container.
        // For more information on how to configure your application, visit https://go.microsoft.com/fwlink/?LinkID=398940
        public void ConfigureServices(IServiceCollection services)
        {
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            /*if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.Run(async (context) =>
            {
                await context.Response.WriteAsync("Hello World!");
            });*/
            
            //Console.WriteLine("Doing Configure");
            lock (handlerLock) {
              //BEC_2_3_11_AppRunMainOnce.runMainOnce(args);
              if (bevs_webServer == null) {
                bevs_webServer = BEC_2_3_6_WebServer.bevs_webServer;
              }
            }
            
            app.Run(async (context) =>
            {
                //Console.WriteLine("In Request");
                //await context.Response.WriteAsync("Hello World!");
                try {
                  bevs_webServer.bems_handleWeb(context);
                } catch ( Exception e ) {
                  Console.WriteLine( "Got exception during handleweb" );
                  Console.WriteLine( e ) ;
                }
            });
            
            
            
        }
    }
}
