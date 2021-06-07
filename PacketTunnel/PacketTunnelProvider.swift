//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by Yu Yang on 2021/6/4.
//

import NetworkExtension
import CocoaLumberjackSwift
import Yaml
import NEKit

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    var interface: TUNInterface!
    var enablePacketProcessing = true
    
    var proxyPort: Int!
    
    var proxyServer: ProxyServer!
    
    var lastPath:NWPath?
    
    var started:Bool = false
    
    /*
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        
        NSLog("PacketTunnelProvider startTunnel 223232324555");
        
        DDLog.removeAllLoggers()
        DDLog.add(DDASLLogger.sharedInstance, with: DDLogLevel.info)
        ObserverFactory.currentFactory = DebugObserverFactory()
        NSLog("-------------")
        
//        guard let conf = (protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration else{
//            NSLog("[ERROR] No ProtocolConfiguration Found")
//            exit(EXIT_FAILURE)
//        }
//        let ss_adder = conf["ss_address"] as! String
//        NSLog(ss_adder)
//
//        let ss_port = conf["ss_port"] as! Int
//        let method = conf["ss_method"] as! String
//        NSLog(method)
//        let password = conf["ss_password"] as!String
        
        
        
//        conf["ss_address"] = "mulberry.dynamic.138576.xyz" as AnyObject?
//        conf["ss_port"] = 16061 as AnyObject?
//        conf["ss_method"] = "RC4MD5" as AnyObject? // 大写 没有横杠 看Extension中的枚举类设定 否则引发fatal error
//        conf["ss_password"] = "8bc01b4447b58ca9" as AnyObject?
        
        let ss_adder = "mulberry.dynamic.138576.xyz"
        let ss_port = 16061
        let method = "RC4MD5"
        let password = "8bc01b4447b58ca9"
        
        // Proxy Adapter
        // SSR Httpsimple
//        let obfuscater = ShadowsocksAdapter.ProtocolObfuscater.HTTPProtocolObfuscater.Factory(hosts:["intl.aliyun.com","cdn.aliyun.com"], customHeader:nil)
        // Origin
        let obfuscater = ShadowsocksAdapter.ProtocolObfuscater.OriginProtocolObfuscater.Factory()
        
        let algorithm:CryptoAlgorithm
        
        switch method{
        case "AES128CFB":algorithm = .AES128CFB
        case "AES192CFB":algorithm = .AES192CFB
        case "AES256CFB":algorithm = .AES256CFB
        case "CHACHA20":algorithm = .CHACHA20
        case "SALSA20":algorithm = .SALSA20
        case "RC4MD5":algorithm = .RC4MD5
        default:
            fatalError("Undefined algorithm!")
        }
        
        let ssAdapterFactory = ShadowsocksAdapterFactory(serverHost: ss_adder, serverPort: ss_port, protocolObfuscaterFactory:obfuscater, cryptorFactory: ShadowsocksAdapter.CryptoStreamProcessor.Factory(password: password, algorithm: algorithm), streamObfuscaterFactory: ShadowsocksAdapter.StreamObfuscater.OriginStreamObfuscater.Factory())
//
        let directAdapterFactory = DirectAdapterFactory()
//
//        //Get lists from conf
//        let yaml_str = getRuleConf()
//        let value = try! Yaml.load(yaml_str)
//
        var UserRules:[Rule] = []
//
//        for each in (value["rule"].array! ){
//            let adapter:AdapterFactory
//            if each["adapter"].string! == "direct"{
//                adapter = directAdapterFactory as AdapterFactory
//            }else{
//                adapter = ssAdapterFactory as AdapterFactory
//            }
//
//            let ruleType = each["type"].string!
//            switch ruleType {
//            case "domainlist":
//                var rule_array : [DomainListRule.MatchCriterion] = []
//                for dom in each["criteria"].array!{
//                    let raw_dom = dom.string!
//                    let index = raw_dom.index(raw_dom.startIndex, offsetBy: 1)
//                    let index2 = raw_dom.index(raw_dom.startIndex, offsetBy: 2)
//                    let typeStr = raw_dom.prefix(upTo: index)
//                        //raw_dom.substring(to: index)
//                    let url = raw_dom.suffix(from: index2)
//                        //raw_dom.substring(from: index2)
//
//                    if typeStr == "s"{
//                        rule_array.append(DomainListRule.MatchCriterion.suffix(String(url)))
//                    }else if typeStr == "k"{
//                        rule_array.append(DomainListRule.MatchCriterion.keyword(String(url)))
//                    }else if typeStr == "p"{
//                        rule_array.append(DomainListRule.MatchCriterion.prefix(String(url)))
//                    }else if typeStr == "r"{
//                        // ToDo:
//                        // shoud be complete
//                    }
//                }
//                UserRules.append(DomainListRule(adapterFactory: adapter, criteria: rule_array))
//
//
//            case "iplist":
//                let ipArray = each["criteria"].array!.map{$0.string!}
//                UserRules.append(try! IPRangeListRule(adapterFactory: adapter, ranges: ipArray))
//            default:
//                break
//            }
//        }
//
//
//        // Rules
//
        let chinaRule = CountryRule(countryCode: "CN", match: true, adapterFactory: directAdapterFactory)
        let unKnowLoc = CountryRule(countryCode: "--", match: true, adapterFactory: directAdapterFactory)
        let dnsFailRule = DNSFailRule(adapterFactory: ssAdapterFactory)
        let allRule = AllRule(adapterFactory: ssAdapterFactory)
//
        UserRules.append(contentsOf: [chinaRule,unKnowLoc,dnsFailRule,allRule])
//
        let manager = RuleManager(fromRules: UserRules, appendDirect: true)
//
        RuleManager.currentManager = manager
        proxyPort =  1080

        RawSocketFactory.TunnelProvider = self
        
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
        proxySettings.httpEnabled = true
        proxySettings.httpServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
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
                DDLogError("Encountered an error setting up the network: \(error.debugDescription)")
                completionHandler(error)
                return
            }
            
            
            if !self.started{
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
                
               // RawSocketFactory.TunnelProvider = self
                
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
    
    */
    
    
    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        
        let ipv4Settings = NEIPv4Settings(addresses: ["192.0.2.1"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "192.0.2.2")
        settings.ipv4Settings = ipv4Settings;
        settings.mtu = 1600
        
        let proxySettings = NEProxySettings()
        let proxyServerPort = 1080
        let proxyServerName = "localhost";
        proxySettings.httpEnabled = true;
        proxySettings.httpServer = NEProxyServer(address: proxyServerName, port: proxyServerPort)
        proxySettings.httpEnabled = true;
        proxySettings.httpServer = NEProxyServer(address: proxyServerName, port: proxyServerPort)
        proxySettings.httpEnabled = true;
        proxySettings.excludeSimpleHostnames = true;
        settings.proxySettings = proxySettings;

        let dnsServers = ["10.10.10.1"]
        let dnsSettings = NEDNSSettings(servers: dnsServers)
        dnsSettings.matchDomains = [""]
        settings.dnsSettings = dnsSettings;

        self.setTunnelNetworkSettings(settings) { error in
            completionHandler(error)
        }
        
        //        NEDNSSettings *dnsSettings = [[NEDNSSettings alloc] initWithServers:dnsServers];
        //        dnsSettings.matchDomains = @[@""];
        //        settings.DNSSettings = dnsSettings;

        
//        NSString *generalConfContent = [NSString stringWithContentsOfURL:[Potatso sharedGeneralConfUrl] encoding:NSUTF8StringEncoding error:nil];
//        NSDictionary *generalConf = [generalConfContent jsonDictionary];
//        NSString *dns = generalConf[@"dns"];
//        NEIPv4Settings *ipv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@"192.0.2.1"] subnetMasks:@[@"255.255.255.0"]];
//        NSArray *dnsServers;
//        if (dns.length) {
//            dnsServers = [dns componentsSeparatedByString:@","];
//            NSLog(@"custom dns servers: %@", dnsServers);
//        }else {
//            dnsServers = [DNSConfig getSystemDnsServers];
//            NSLog(@"system dns servers: %@", dnsServers);
//        }
//        ipv4Settings.includedRoutes = @[[NEIPv4Route defaultRoute]];
//        NEPacketTunnelNetworkSettings *settings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"192.0.2.2"];
//        settings.IPv4Settings = ipv4Settings;
//        settings.MTU = @(TunnelMTU);
//        NEProxySettings* proxySettings = [[NEProxySettings alloc] init];
//        NSInteger proxyServerPort = [ProxyManager sharedManager].httpProxyPort;
//        NSString *proxyServerName = @"localhost";
//
//        proxySettings.HTTPEnabled = YES;
//        proxySettings.HTTPServer = [[NEProxyServer alloc] initWithAddress:proxyServerName port:proxyServerPort];
//        proxySettings.HTTPSEnabled = YES;
//        proxySettings.HTTPSServer = [[NEProxyServer alloc] initWithAddress:proxyServerName port:proxyServerPort];
//        proxySettings.excludeSimpleHostnames = YES;
//        settings.proxySettings = proxySettings;
//        NEDNSSettings *dnsSettings = [[NEDNSSettings alloc] initWithServers:dnsServers];
//        dnsSettings.matchDomains = @[@""];
//        settings.DNSSettings = dnsSettings;
//        [self setTunnelNetworkSettings:settings completionHandler:^(NSError * _Nullable error) {
//            if (error) {
//                if (completionHandler) {
//                    completionHandler(error);
//                }
//            }else{
//                if (completionHandler) {
//                    completionHandler(nil);
//                }
//            }
//        }];
        
        
        
        
//        let ipv4Settings = NEIPv4Settings(addresses: ["127.1.1.1"], subnetMasks: ["172.16.209.5"])
//           let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "8.8.8.8")
//           networkSettings.mtu = 1500
//        networkSettings.ipv4Settings = ipv4Settings
//           setTunnelNetworkSettings(networkSettings) {
//               error in
//               guard error == nil else {
//                   completionHandler(error)
//                   return
//               }
//                   completionHandler(nil)
//           }
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
    
    
    fileprivate func getRuleConf() -> String{
        let Path = Bundle.main.path(forResource: "NEKitRule", ofType: "conf")
        let Data = try? Foundation.Data(contentsOf: URL(fileURLWithPath: Path!))
        let str = String(data: Data!, encoding: String.Encoding.utf8)!
        return str
    }
}
