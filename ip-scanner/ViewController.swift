//
//  ViewController.swift
//  ip-scanner
//
//  Created by Алексей Неронов on 10.05.16.
//  Copyright © 2016 Алексей Неронов. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SimplePingDelegate {

    let textResult = UITextView()
    let checkButton = UIButton()
    
    let ghn = GetHostName()

    let size:CGRect = UIScreen.mainScreen().bounds
    var netInfo = NetInfo (ip: "192.168.0.0", netmask: "0.0.0.0", start: "0.0.0.0", end: "0.0.0.0", bitMask: 0)
    
    var pinger: SimplePing?
    var hostName = "192.168.1.0"
    var listIndex = 0
    var sendTimer: NSTimer?
    
    //ip mask
    let maskArray:[String] = ["255.255.255.255","255.255.255.254","255.255.255.252","255.255.255.248","255.255.255.240","255.255.255.224","255.255.255.192","255.255.255.128","255.255.255.0","255.255.254.0","255.255.252.0","255.255.248.0","255.255.240.0","255.255.224.0","255.255.192.0","255.255.128.0","255.255.0.0","255.254.0.0","255.252.0.0","255.248.0.0","255.240.0.0","255.224.0.0","255.192.0.0","255.128.0.0","255.0.0.0","254.0.0.0","252.0.0.0","248.0.0.0","240.0.0.0","224.0.0.0","192.0.0.0","128.0.0.0","0.0.0.0"]
    
    //ip address list
    var addressList:[String] = []
    
    struct NetInfo {
        let ip: String
        let netmask: String
        let start: String
        let end: String
        let bitMask: Int
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        netInfo = getIFAddresses().last!
        putObjects()
        print(netInfo)
        print(ghn.returnHostName("192.168.1.1"))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func putObjects() {
        let startAddress = UITextField()
        let endAddress = UITextField()
        
        textResult.frame=CGRectMake(size.width*0.05, size.height*0.12, size.width*0.9, size.height*0.7)
        textResult.backgroundColor=UIColor.lightGrayColor()
        self.view.addSubview(textResult)
        
        startAddress.frame = CGRectMake(size.width*0.07, size.height*0.05, size.width*0.4, size.height/20)
        startAddress.backgroundColor=UIColor.lightGrayColor()
        startAddress.textColor=UIColor.blackColor()
        startAddress.text = netInfo.start
        self.view.addSubview(startAddress)
        
        endAddress.frame = CGRectMake(size.width*0.53, size.height*0.05, size.width*0.4, size.height/20)
        endAddress.backgroundColor=UIColor.lightGrayColor()
        endAddress.textColor=UIColor.blackColor()
        endAddress.text = netInfo.end
        self.view.addSubview(endAddress)
        
        checkButton.frame = CGRectMake(size.width/2-size.width/4, size.height*0.83, size.width/2, size.height/14)
        checkButton.setTitle("Start", forState: .Normal)
        checkButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        checkButton.backgroundColor=UIColor.blueColor()
        checkButton.addTarget(self, action: #selector(pressed(_:)), forControlEvents: .TouchUpInside)
        self.view.addSubview(checkButton)
    }
    
    func pressed(sender: UIButton!) {
        
        print("Scanning...")
//            self.start(forceIPv4: true, forceIPv6: false)
        assert(self.sendTimer == nil)
        checkButton.enabled = false
        checkButton.backgroundColor=UIColor.grayColor()
        self.sendTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(ViewController.startPing), userInfo: nil, repeats: true)
    }
    
    
    // Get the local ip addresses used by this node
    func getIFAddresses() -> [NetInfo] {
        var addresses = [NetInfo]()
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
        if getifaddrs(&ifaddr) == 0 {
            
            // For each interface ...
            for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
                let flags = Int32(ptr.memory.ifa_flags)
                var addr = ptr.memory.ifa_addr.memory
                
                // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                        
                        // Convert interface address to a human readable string:
                        var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                        if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                            if let address = String.fromCString(hostname) {
                                
                                var net = ptr.memory.ifa_netmask.memory
                                var netmaskName = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                                getnameinfo(&net, socklen_t(net.sa_len), &netmaskName, socklen_t(netmaskName.count),
                                            nil, socklen_t(0), NI_NUMERICHOST) == 0
                                
                                if let netmask = String.fromCString(netmaskName) {
                                    let mask = returnMaskIndex(netmask)
                                    var hostMin:String = ""
                                    var hostMax:String = ""
                                    
                                    let b1 = Int(address.characters.split{$0 == "."}.map(String.init)[0])
                                    let b2 = Int(address.characters.split{$0 == "."}.map(String.init)[1])
                                    let b3 = Int(address.characters.split{$0 == "."}.map(String.init)[2])
                                    let b4 = Int(address.characters.split{$0 == "."}.map(String.init)[3])
                                    let m1 = Int(netmask.characters.split{$0 == "."}.map(String.init)[0])
                                    let m2 = Int(netmask.characters.split{$0 == "."}.map(String.init)[1])
                                    let m3 = Int(netmask.characters.split{$0 == "."}.map(String.init)[2])
                                    let m4 = Int(netmask.characters.split{$0 == "."}.map(String.init)[3])
                                    
                                    let wild1 = 255 - m1!
                                    let wild2 = 255 - m2!
                                    let wild3 = 255 - m3!
                                    let wild4 = 255 - m4!
                                    
                                    
                                    if (mask == 0) {
                                        hostMin = "0.0.0.1"
                                        hostMax = "255.255.255.254"
                                    }
                                    else if (mask > 0 && mask < 8) {
                                        let multiple = b1! / (wild1+1)
                                        let netStart = multiple * (wild1+1)
                                        let netEnd = netStart + wild1
                                        hostMin = String(netStart) + ".0.0.1"
                                        hostMax = String(netEnd) + ".255.255.254"
                                    }
                                    else if (mask > 7 && mask < 16) {
                                        let multiple = b2! / (wild2+1)
                                        let netStart = multiple * (wild2+1)
                                        let netEnd = netStart + wild2
                                        hostMin = String(b1!)+"."+String(netStart)+".0.1"
                                        hostMax = String(b1!)+"."+String(netEnd)+".255.254"
                                    }
                                    else if (mask > 15 && mask < 24) {
                                        let multiple = b3! / (wild3+1);
                                        let netStart = multiple * (wild3+1);
                                        let netEnd = netStart + wild3;
                                        hostMin = String(b1!)+"."+String(b2!)+"."+String(netStart)+".1"
                                        hostMax = String(b1!)+"."+String(b2!)+"."+String(netEnd)+".254"
                                    }
                                    else if (mask > 23 && mask < 31) {
                                        let multiple = b4! / (wild4+1)
                                        let netStart = multiple * (wild4+1)
                                        let netEnd = netStart + wild4
                                        hostMin = String(b1!)+"."+String(b2!)+"."+String(b3!)+"."+String(netStart+1)
                                        hostMax = String(b1!)+"."+String(b2!)+"."+String(b3!)+"."+String(netEnd-1)
                                        
                                        for i in netStart+1...netEnd-1 {
                                            addressList.append(String(b1!)+"."+String(b2!)+"."+String(b3!)+"."+String(i))
                                        }
                                    }
                                    else if (mask == 31) {
                                        hostMin = "-.-.-.-"
                                        hostMax = "-.-.-.-"
                                    }
                                    else if (mask == 32) {
                                        hostMin = "-.-.-.-"
                                        hostMax = "-.-.-.-"
                                    }
                                    
                                    addresses.append(NetInfo(ip: address, netmask: netmask , start: hostMin, end: hostMax, bitMask: mask))
                                }
                            }
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return addresses
    }
    
    func returnMaskIndex (maskStr:NSString) -> Int {
        var result:Int = 0
        for mask in maskArray {
            if (maskStr == mask) { break }
            result += 1
        }
        return 32-result
    }
    
    /// Called by the table view selection delegate callback to start the ping.
    
    func start(forceIPv4 forceIPv4: Bool, forceIPv6: Bool) {
        
        NSLog("start")

        hostName = addressList[listIndex]
        listIndex += 1
        
        let pinger = SimplePing(hostName: self.hostName)
        self.pinger = pinger
        
        // By default we use the first IP address we get back from host resolution (.Any)
        // but these flags let the user override that.
        
        if (forceIPv4 && !forceIPv6) {
            pinger.addressStyle = .ICMPv4
        } else if (forceIPv6 && !forceIPv4) {
            pinger.addressStyle = .ICMPv6
        }
        
        pinger.delegate = self
            pinger.start()

    }
    
    /// Called by the table view selection delegate callback to stop the ping.
    
    func stop() {
        NSLog("stop")
        self.pinger?.stop()
        self.pinger = nil
        
    }
    
    /// Sends a ping.
    ///
    /// Called to send a ping, both directly (as soon as the SimplePing object starts up) and
    /// via a timer (to continue sending pings periodically).
    
    func sendPing() {
        self.pinger!.sendPingWithData(nil)
    }
    
    func startPing() {
        if listIndex >= addressList.count {
            self.sendTimer?.invalidate()
            self.sendTimer = nil
            checkButton.backgroundColor=UIColor.blueColor()
            checkButton.enabled=true
            checkButton.setTitle("Start", forState: .Normal)
            listIndex=0
        } else {
            checkButton.setTitle(String(addressList[listIndex]), forState: .Disabled)
            self.start(forceIPv4: true, forceIPv6: false)
        }
    }
    
    
    // MARK: pinger delegate callback
    
    func simplePing(pinger: SimplePing, didStartWithAddress address: NSData) {
        NSLog("pinging %@", ViewController.displayAddressForAddress(address))
        
        // Send the first ping straight away.
        
        self.sendPing()
        self.pinger!.sendPingWithData(nil)
        
        // And start a timer to send the subsequent pings.
        
        //assert(self.sendTimer == nil)
        //self.sendTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(ViewController.sendPing), userInfo: nil, repeats: true)
    }
    
    func simplePing(pinger: SimplePing, didFailWithError error: NSError) {
        NSLog("failed: %@", ViewController.shortErrorFromError(error))
        textResult.text = textResult.text.stringByAppendingString(hostName+" -> FAIL\n")
        self.stop()
        hostName = addressList[listIndex]
        listIndex += 1
    }
    
    func simplePing(pinger: SimplePing, didSendPacket packet: NSData, sequenceNumber: UInt16) {
        NSLog("#%u sent", sequenceNumber)
    }
    
    func simplePing(pinger: SimplePing, didFailToSendPacket packet: NSData, sequenceNumber: UInt16, error: NSError) {
        NSLog("#%u send failed: %@", sequenceNumber, ViewController.shortErrorFromError(error))
    }
    
    func simplePing(pinger: SimplePing, didReceivePingResponsePacket packet: NSData, sequenceNumber: UInt16) {
        NSLog("#%u received, size=%zu", sequenceNumber, packet.length)
        textResult.text = textResult.text.stringByAppendingString(hostName+" -> OK\n")
        self.stop()
//        self.start(forceIPv4: true, forceIPv6: false)
    }
    
    func simplePing(pinger: SimplePing, didReceiveUnexpectedPacket packet: NSData) {
        NSLog("unexpected packet, size=%zu", packet.length)
    }
    
    
    // MARK: utilities
    
    /// Returns the string representation of the supplied address.
    ///
    /// - parameter address: Contains a `(struct sockaddr)` with the address to render.
    ///
    /// - returns: A string representation of that address.
    
    static func displayAddressForAddress(address: NSData) -> String {
        var hostStr = [Int8](count: Int(NI_MAXHOST), repeatedValue: 0)
        
        let success = getnameinfo(
            UnsafePointer(address.bytes),
            socklen_t(address.length),
            &hostStr,
            socklen_t(hostStr.count),
            nil,
            0,
            NI_NUMERICHOST
            ) == 0
        let result: String
        if success {
            result = String.fromCString(hostStr)!
        } else {
            result = "?"
        }
        return result
    }
    
    /// Returns a short error string for the supplied error.
    ///
    /// - parameter error: The error to render.
    ///
    /// - returns: A short string representing that error.
    
    static func shortErrorFromError(error: NSError) -> String {
        if error.domain == kCFErrorDomainCFNetwork as String && error.code == Int(CFNetworkErrors.CFHostErrorUnknown.rawValue) {
            if let failureObj = error.userInfo[kCFGetAddrInfoFailureKey] {
                if let failureNum = failureObj as? NSNumber {
                    if failureNum.intValue != 0 {
                        let f = gai_strerror(failureNum.intValue)
                        if f != nil {
                            return String.fromCString(f)!
                        }
                    }
                }
            }
        }
        if let result = error.localizedFailureReason {
            return result
        }
        return error.localizedDescription
    }
    
    
}

