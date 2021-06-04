//
//  ViewController.swift
//  NEKitTest
//
//  Created by Yu Yang on 2021/6/3.
//

/**

 ./carthage.sh update --platform ios
 
 */

import UIKit
import NEKit
import NetworkExtension

class ViewController: UIViewController {
    
    @IBOutlet var connectButton: UIButton!
    
    
    var status: VPNStatus {
        didSet(o) {
            updateConnectButton()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.status = .off
        super.init(coder: aDecoder)
        NotificationCenter.default.addObserver(self, selector: #selector(onVPNStatusChanged), name: NSNotification.Name(rawValue: kProxyServiceVPNStatusNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let request = URLRequest(url:URL(string: "http://www.sohu.com")!)
        let session = URLSession.shared
        let task = session.dataTask(with: request)
        task.resume()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.status = VpnManager.shared.vpnStatus
    }
    
    @objc func onVPNStatusChanged(){
        self.status = VpnManager.shared.vpnStatus
    }
    
    func updateConnectButton(){
        switch status {
        case .connecting:
            connectButton.setTitle("connecting", for: .normal)
        case .disconnecting:
            connectButton.setTitle("disconnect", for: .normal)
        case .on:
            connectButton.setTitle("Disconnect", for: .normal)
        case .off:
            connectButton.setTitle("Connect", for: .normal)
        }
        
        connectButton.isEnabled = [VPNStatus.on,VPNStatus.off].contains(VpnManager.shared.vpnStatus)

        
    }
    
    @IBAction func connectTap(_ sender: AnyObject) {
        print("connect tap")
//
//        if(VpnManager.shared.vpnStatus == .off){
//            VpnManager.shared.connect()
//        }else{
//            VpnManager.shared.disconnect()
//        }
        
        
        
    }
}

