//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by Yu Yang on 2021/6/4.
//

import NetworkExtension
//import CocoaLumberjackSwift
//import Yaml
import NEKit
import os.log
//import tun2socks


class PacketTunnelProvider: NEPacketTunnelProvider {
    
    var interface: TUNInterface!
    var enablePacketProcessing = true
    var proxyPort: Int!
    var proxyServer: ProxyServer!
    var lastPath:NWPath?
    var started:Bool = false
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        
//        ObserverFactory.currentFactory = DebugObserverFactory()

        
        proxyPort =  1080

        RawSocketFactory.TunnelProvider = self
//        HTTPAdapterFactory
        // the `tunnelRemoteAddress` is meaningless because we are not creating a tunnel.
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "8.8.8.8")
        networkSettings.mtu = 1500
        
        let ipv4Settings = NEIPv4Settings(addresses: ["192.169.89.1"], subnetMasks: ["255.255.255.0"])
        if enablePacketProcessing {
            ipv4Settings.includedRoutes = [NEIPv4Route.default()]
            ipv4Settings.excludedRoutes = [
                NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
                NEIPv4Route(destinationAddress: "100.64.0.0", subnetMask: "255.192.0.0"),
                NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),
                NEIPv4Route(destinationAddress: "169.254.0.0", subnetMask: "255.255.0.0"),
                NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
                NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
                NEIPv4Route(destinationAddress: "17.0.0.0", subnetMask: "255.0.0.0"),
            ]
        }
        networkSettings.ipv4Settings = ipv4Settings
        
        let proxySettings = NEProxySettings()
        proxySettings.httpsEnabled = true
        proxySettings.httpsServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        proxySettings.excludeSimpleHostnames = true
        // This will match all domains
        proxySettings.matchDomains = [""]
        proxySettings.exceptionList = ["api.smoot.apple.com","configuration.apple.com","xp.apple.com","smp-device-content.apple.com","guzzoni.apple.com","captive.apple.com","*.ess.apple.com","*.push.apple.com","*.push-apple.com.akadns.net"]
        networkSettings.proxySettings = proxySettings
        
        if enablePacketProcessing {
            let DNSSettings = NEDNSSettings(servers: ["172.16.0.1"])
            DNSSettings.matchDomains = [""]
            DNSSettings.matchDomainsNoSearch = false
            networkSettings.dnsSettings = DNSSettings
        }
        
        setTunnelNetworkSettings(networkSettings) {
            error in
            guard error == nil else {
                completionHandler(error)
                return
            }
            
            if !self.started {
                self.proxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: "127.0.0.1"), port: Port(port: UInt16(self.proxyPort)))
                try! self.proxyServer.start()
                
                self.addObserver(self, forKeyPath: "defaultPath", options: .initial, context: nil)
            }else{
                self.proxyServer.stop()
                try! self.proxyServer.start()
            }
            
            completionHandler(nil)
            
            NSLog("-------- before enablePacketProcessing ----------")
            if self.enablePacketProcessing {
                NSLog("-------- enablePacketProcessing ----------")
                if self.started{
                    //self.interface.stop()
                }
                self.interface = TUNInterface(packetFlow: self.packetFlow)
//
//                RawSocketFactory.TunnelProvider = self
//
                let fakeIPPool = try! IPPool(range: IPRange(startIP: IPAddress(fromString: "198.18.1.1")!, endIP: IPAddress(fromString: "198.18.255.255")!))
                let dnsServer = DNSServer(address: IPAddress(fromString: "172.16.0.1")!, port: Port(port: 53), fakeIPPool: fakeIPPool)
                let resolver = UDPDNSResolver(address: IPAddress(fromString: "223.5.5.5")!, port: Port(port: 53))
                dnsServer.registerResolver(resolver)
               
                
                self.interface.register(stack: dnsServer)
                DNSServer.currentServer = dnsServer
                let udpStack = UDPDirectStack()
                self.interface.register(stack: udpStack)
                let tcpStack = TCPStack.stack
                tcpStack.proxyServer = self.proxyServer
                self.interface.register(stack:tcpStack)
                self.interface.start()
            }
            self.started = true
            
        }
        
    }
    
 
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        if enablePacketProcessing {
            interface.stop()
            interface = nil
            DNSServer.currentServer = nil
        }
        
        if(proxyServer != nil){
            proxyServer.stop()
            proxyServer = nil
            RawSocketFactory.TunnelProvider = nil
        }
        completionHandler()
        
        exit(EXIT_SUCCESS)
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Add code here to handle the message.
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up.
    }
    
    
}
 
