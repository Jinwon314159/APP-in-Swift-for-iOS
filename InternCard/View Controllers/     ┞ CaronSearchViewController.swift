//
//  CaronSearchViewController.swift
//  InternCard
//
//  Created by idl on 2018. 9. 7..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import UIKit
import CoreBluetooth

struct CaronDevice {
    var name: String!
    var mac_address: String!
    var serial_number: String!
    var battery: String!
    var version: String!
    var peripheral: CBPeripheral!
}

class CaronSearchViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource {
    
    static var child_no: String! = "0"
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableView: UITableView!
    
    // To declare manager and peripheral
    var manager:CBCentralManager!
    var peripheral:CBPeripheral!
    
    var timer: Timer!
    
    // UUID and service name
    let DEVICE_NAME            = "caron"
    let DEVICE_SERVICE_UUID    = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    //let DEVICE_SERVICE_UUID = CBUUID(string: "8e400001-f315-4f60-9fb8-838830daea50")
    //let RX_CHARACTERISTIC_UUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    let CHARACTERISTIC_UUID    = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    //let DEVICE_CHARACTERISTIC_UUID = CBUUID(string: "8e400001-f315-4f60-9fb8-838830daea50")
    //static var deviceInfoServiceUUID = CBUUID(string: "180A")
    
    //var currentRxCharacteristic: Characteristic!
    //var currentCharacteristic: Characteristic!
    
    var devices: [CaronDevice]! = []

    override func viewDidDisappear(_ animated: Bool) {
        if self.timer != nil { self.timer.invalidate() }
        if self.manager != nil { self.manager.stopScan() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.timer = Timer()

        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // Do any additional setup after loading the view.
        let headerView: UIView! = UIView(frame: CGRect(x: 0, y: 0, width: ContentCardsViewController.Constants.screenWidth, height: ContentCardsViewController.Constants.statusBarHeight + ContentCardsViewController.Constants.headerHeight))
        headerView.backgroundColor = UIColor(white: 1, alpha: 1)
        headerView.clipsToBounds = false
        headerView.layer.shadowColor = UIColor.black.cgColor
        headerView.layer.shadowOpacity = 0.2
        headerView.layer.shadowOffset = CGSize.zero
        headerView.layer.shadowRadius = 1
        headerView.layer.shadowPath = UIBezierPath(roundedRect: headerView.bounds, cornerRadius:1).cgPath
        self.view.addSubview(headerView)
        
        let labelLogo: UILabel = UILabel(frame: CGRect(x: 0, y: ContentCardsViewController.Constants.statusBarHeight, width: ContentCardsViewController.Constants.screenWidth, height: ContentCardsViewController.Constants.headerHeight))
        labelLogo.text = "INTERNCARD"
        labelLogo.font = UIFont(name: "SteelfishRg-Regular", size: 24.0)
        labelLogo.textAlignment = .center
        self.view.addSubview(labelLogo)
        
        //let back: UIButton! = UIButton(frame: CGRect(x: 10, y: ContentCardsViewController.Constants.statusBarHeight + 10, width: 59, height: 67))
        let backButton: UIButton! = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "back.png"), for: .normal)
        backButton.frame = CGRect(x: 0, y: ContentCardsViewController.Constants.statusBarHeight, width: ContentCardsViewController.Constants.headerHeight, height: ContentCardsViewController.Constants.headerHeight)
        backButton.addTarget(self, action: #selector(clickBackButton), for: .touchUpInside)
        self.view.addSubview(backButton)

        scrollView.frame.origin.y = ContentCardsViewController.Constants.headerHeight
        //scrollView.contentSize.height = ContentCardsViewController.Constants.screenHeight * 1.5
        
        // instantiate manager
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    @objc func clickBackButton(_ sender: AnyObject?) {
        //self.dismiss(animated: true, completion: nil)
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbActivity") as! ActivityViewController
        self.present(nextViewController, animated: false, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let row = indexPath.row
        cell.textLabel?.text = devices[row].name + " (" + devices[row].mac_address + ")"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let row = indexPath.row
        
        let caron: CaronDevice = devices[row]
        
        // 서버에 삽입하고 remote_no 받음 (서버에 동일 디바이스 있는지 확인)
        let remote_no: String! = insertCaronDeviceToRemote(child_no: CaronSearchViewController.child_no, mac_address: caron.mac_address, serial_number: caron.serial_number)
        
        if remote_no == "0" {
            let alertController = UIAlertController(title: "error", message: "서버에 이미 등록된 디바이스가 있습니다", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion: nil)
            
            return
        }
        
        // insert into local DB
        do {
            let db = try SQLite()

            // 로컬도 같은 디바이스가 동일 아동 혹은 다른 아동에 등록되어 있는지 확인
            var exists: Bool = false
            var sql: String! = "SELECT COUNT(*) as `cnt` FROM `caron_device` WHERE `mac_address`='" + caron.mac_address + "';"
            try db.install(query: sql)
            try db.execute() { stmt in
                let cnt: Int32 = sqlite3_column_int(stmt, 0)
                if cnt > 0 {
                    exists = true
                    return
                }
            }

            if exists {
                let alertController = UIAlertController(title: "error", message: "다른 아이에게 등록되어 있습니다", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default)
                alertController.addAction(okAction)
                
                self.present(alertController, animated: true, completion: nil)

                return
            }

            sql = "INSERT INTO `caron_device`(`remote_no`, `child_no`, `mac_address`, `serial_number`) VALUES ('" + remote_no! + "', '" + CaronSearchViewController.child_no! + "', '" + caron.mac_address! + "', '" + caron.serial_number! + "');"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }

        CaronSyncViewController.child_no = CaronSearchViewController.child_no
        CaronSyncViewController.mac_address = caron.mac_address
        CaronSyncViewController.serial_number = caron.serial_number
        
        //self.dismiss(animated: true, completion: nil)
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbCaronSync") as! CaronSyncViewController
        self.present(nextViewController, animated: true, completion: nil)
    }
    
    func insertCaronDeviceToRemote(child_no: String, mac_address: String, serial_number: String) -> String
    {
        var remote_no: String! = "0"
        
        // Session
        let defaultSession = URLSession(configuration: .default)
        let str: String = "http://internkid.com/caron_device.insert.api.php?child_no=" + child_no + "&mac_address=" + mac_address + "&serial_number=" + serial_number
        let encoded: String! = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        guard let url = URL(string: encoded) else {
            print("URL is nil")
            return "0"
        }
        
        // Request
        let request = URLRequest(url: url)
        //request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")  // the request is JSON
        
        let dg0: DispatchGroup! = DispatchGroup()
        dg0.enter()
        
        // dataTask
        let dataTask = defaultSession.dataTask(with: request) { data, response, error in
            // getting Data Error
            guard error == nil else {
                print("Error occur: \(String(describing: error))")
                dg0.leave()
                return
            }
            
            if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [AnyObject] else {
                    print("json to Any Error")
                    dg0.leave()
                    return
                }
                
                if json.count == 0 {
                    dg0.leave()
                    return
                }
                
                let jsonResult = json[0] as! Dictionary<String, String>
                let errorOccurred = jsonResult["error"] != nil
                if !errorOccurred {
                    remote_no = jsonResult["no"]
                }
            } else {
                dg0.leave()
                return
            }
            
            dg0.leave()
        }
        dataTask.resume()
        dg0.wait()
        
        return remote_no
    }

    // scan for devices
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            let services:[CBUUID] = [CBUUID(string: "180A")]
            central.scanForPeripherals(withServices: services, options: nil)
            //central.scanForPeripherals(withServices: nil, options: nil)
            self.timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: { (Timer) in
                //central.scanForPeripherals(withServices: nil, options: nil)
                self.manager.stopScan()
            })
        } else {
            print("Bluetooth not available.")
        }
    }
    
    // list devices
    // connect to a device
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //private func centralManager( central: CBCentralManager, didDiscoverPeripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let name: String! = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? String
        
        print(name)
        
        if name?.contains(DEVICE_NAME) == true {
            
            var arrName = name.split{$0 == "-"}.map(String.init)
            
            if arrName.count == 2 {
                var caron: CaronDevice! = CaronDevice()
                caron.name = arrName[0]
                caron.mac_address = arrName[1]
                caron.serial_number = peripheral.identifier.uuidString
                caron.peripheral = peripheral
                self.devices.append(caron)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
               
                //self.manager.stopScan()
                //self.peripheral = peripheral
                //self.peripheral.delegate = self
                //manager.connect(peripheral, options: nil)
            }
        }
    }
    
    // disconnect and try again
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        //central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    // get services
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    // get characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            let thisService = service as CBService
            
            //print(thisService.uuid)
            
            if thisService.uuid == DEVICE_SERVICE_UUID {
                peripheral.discoverCharacteristics(
                    nil,
                    for: thisService
                )
            }
        }
    }
    
    // setup notifications
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            
            //print(characteristic.uuid)
            //print(characteristic.properties)
            
            //let type: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
            if characteristic.properties.contains(.broadcast) {
                print("broadcast")
            }
            if characteristic.properties.contains(.read) {
                print("read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.writeWithoutResponse) {
                print("writeWithoutResponse")
            }
            if characteristic.properties.contains(.write) {
                print("write")
                let cmd : [UInt8] = [0x02, 0x0F, 0x03]
                peripheral.writeValue(Data(cmd), for: characteristic, type: .withResponse)
            }
            if characteristic.properties.contains(.notify) {
                print("notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.properties.contains(.indicate) {
                print("indicate")
            }
            if characteristic.properties.contains(.authenticatedSignedWrites) {
                print("authenticatedSignedWrites")
            }
            if characteristic.properties.contains(.extendedProperties) {
                print("extendedProperties")
            }
            if characteristic.properties.contains(.notifyEncryptionRequired) {
                print("notifyEncryptionRequired")
            }
            if characteristic.properties.contains(.indicateEncryptionRequired) {
                print("indicateEncryptionRequired")
            }
        }
    }
    
    // changes are coming
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        var bytes = [UInt8](repeating: 0x00, count: 20)
        
        print(characteristic.uuid)
        print(characteristic.value?.count ?? "-")
        
        if characteristic.uuid == CHARACTERISTIC_UUID {
            bytes[0]  = characteristic.value![0]
            bytes[1]  = characteristic.value![1]
            bytes[2]  = characteristic.value![2]
            bytes[3]  = characteristic.value![3]
            bytes[4]  = characteristic.value![4]
            bytes[5]  = characteristic.value![5]
            bytes[6]  = characteristic.value![6]
            bytes[7]  = characteristic.value![7]
            bytes[8]  = characteristic.value![8]
            bytes[9]  = characteristic.value![9]
            bytes[10] = characteristic.value![10]
            bytes[11] = characteristic.value![11]
            bytes[12] = characteristic.value![12]
            bytes[13] = characteristic.value![13]
            bytes[14] = characteristic.value![14]
            bytes[15] = characteristic.value![15]
            bytes[16] = characteristic.value![16]
            bytes[17] = characteristic.value![17]
            bytes[18] = characteristic.value![18]
            bytes[19] = characteristic.value![19]
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Writing error", error)
        } else {
            print("Succeeded")
        }
        
        let cmd : [UInt8] = [0x02, 0x20, 0x03]
        peripheral.writeValue(Data(cmd), for: characteristic, type: .withResponse)
    }

}
