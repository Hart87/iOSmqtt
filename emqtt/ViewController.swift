//
//  ViewController.swift
//  emqtt
//
//  Created by James Hart on 5/10/19.
//  Copyright © 2019 James Hart. All rights reserved.
//

import UIKit
import MQTTClient

class ViewController: UIViewController {

    //properties
    var mqttButton = UIButton()
    let screenSize: CGRect = UIScreen.main.bounds
    
    //mqtt
    //DOX - https://github.com/leedowthwaite/LD-MQTT-iOS
    let MQTT_HOST = "test.mosquitto.org" // or IP address e.g. "192.168.0.194"
    let MQTT_PORT = 1883
    private var transport = MQTTCFSocketTransport()
    fileprivate var session = MQTTSession()
    fileprivate var completion: (()->())? //on complete closure
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //UIButton
        mqttButton = UIButton(frame: CGRect(x: screenSize.width / 5, y: 235, width: 225, height: 45))
        mqttButton.backgroundColor = .blue
        mqttButton.setTitle("FIRE MQTT", for: .normal)
        mqttButton.addTarget(self, action: #selector(Publish), for: .touchUpInside)
        mqttButton.tintColor = UIColor.white
        mqttButton.titleLabel?.font =  UIFont(name: "menlo", size: 16)
        self.view.addSubview(mqttButton)
        
        //mqtt setup
        self.session?.delegate = self
        self.transport.host = MQTT_HOST
        self.transport.port = UInt16(MQTT_PORT)
        session?.transport = transport
        
        GetConnectionStatus(for: self.session?.status ?? .created)
        session?.connect() { error in
            print("connection completed with status \(String(describing: error))")
            if error != nil {
                self.GetConnectionStatus(for: self.session?.status ?? .created)
            } else {
                self.GetConnectionStatus(for: self.session?.status ?? .error)
            }
        }
        
    }
    
    private func GetConnectionStatus(for clientStatus: MQTTSessionStatus) {
        DispatchQueue.main.async {
            switch clientStatus {
            case .connected:
                print("Connected")
                self.SubscribeToSomething(topic: "CoreHart/reply")
            case .connecting,
                 .created:
                print("Trying to connect...")
            default:
                print("Connection Failed")
            }
        }
    }
    
    //Publish a message logic ....
    private func publishMessage(_ message: String, onTopic topic: String) {
        session?.publishData(message.data(using: .utf8, allowLossyConversion: false), onTopic: topic, retain: false, qos: .exactlyOnce)
    }
    
//    private func subscribe() {
//        self.session?.subscribe(toTopic: "test/message", at: .exactlyOnce) { error, result in
//            print("subscribe result error \(String(describing: error)) result \(result!)")
//        }
//    }
    
    @objc func Publish(sender: UIButton!) {
        publishMessage("yes", onTopic: "CoreHart/test")
        print("Published to CoreHart/Test...")
    }
    
    func SubscribeToSomething(topic: String) {
        self.session?.subscribeTopic(topic)
        print("Subscribed...")
    }
    
    
    //  ****** THIS IS EVENTUALLY WHERE SUBSCRIBE WILL GO ********


}

extension ViewController: MQTTSessionManagerDelegate, MQTTSessionDelegate {
    func handleMessage(_ data: Data!, onTopic topic: String!, retained: Bool) {
        print("Delegate methods firing off")
    }
    
    
    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        if let msg = String(data: data, encoding: .utf8) {
            print("topic \(topic!), msg \(msg)")
        }
    }
    
    func messageDelivered(_ session: MQTTSession, msgID msgId: UInt16) {
        print("delivered")
        DispatchQueue.main.async {
            self.completion?()
        }
    }
}
