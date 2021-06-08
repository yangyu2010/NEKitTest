//
//  ViewController.swift
//  NEKitTest
//
//  Created by Yu Yang on 2021/6/3.
//

/**

 ./carthage.sh update --platform ios
 
 carthage update --no-use-binaries --platform ios

 carthage update --no-use-binaries --platform mac,ios
 */

import UIKit

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
            connectButton.setTitle("connecting", for: UIControl.State())
        case .disconnecting:
            connectButton.setTitle("disconnect", for: UIControl.State())
        case .on:
            connectButton.setTitle("Disconnect", for: UIControl.State())
        case .off:
            connectButton.setTitle("Connect", for: UIControl.State())

        }
        connectButton.isEnabled = [VPNStatus.on,VPNStatus.off].contains(VpnManager.shared.vpnStatus)

        
    }
    
    @IBAction func connectTap(_ sender: AnyObject) {
        print("connect tap")
        if(VpnManager.shared.vpnStatus == .off){
            VpnManager.shared.connect()
        }else{
            VpnManager.shared.disconnect()
        }
    }
}

