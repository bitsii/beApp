
use IUBridge:BridgePlugin;
use IUCam:CamPlugin;

use class IUBridge:CamBridgeStart(IUBridge:BridgeStart) {

getPlugins(Bool bkg) List {
      BridgePlugin hub = BridgePlugin.new();
      hub.runBackground = bkg;
      CamPlugin cam = CamPlugin.new();
      cam.runBackground = bkg;
      IUDoer:DoerPlugin doer = IUDoer:DoerPlugin.new();
      log.log("adding plugins");
      List plugins = List.new();
      plugins += hub;
      plugins += cam;
      plugins += App:AuthPlugin.new();
      plugins += App:ConfigPlugin.new();
      plugins += App:FileManagerPlugin.new();
      plugins += doer;
      return(plugins);
    }
    
}
