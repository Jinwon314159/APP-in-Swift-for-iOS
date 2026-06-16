//
//  CaronSyncViewController.swift
//  InternCard
//
//  Created by idl on 2018. 10. 4..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import UIKit
import CoreBluetooth
import Firebase


struct MotionData {
    var intensity: UInt8!
    var utc: TimeInterval!
}

class CaronSyncViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static var child_no: String! = "0"
    static var mac_address: String! = ""
    static var serial_number: String! = ""

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var labelBattery: UILabel!
    @IBOutlet weak var labelVersion: UILabel!
    @IBOutlet weak var labelSync: UILabel!
    
    // To declare manager and peripheral
    var manager:CBCentralManager!
    var peripheral:CBPeripheral!
    
    var timer: Timer!

    // UUID and service name
    let DEVICE_NAME            = "caron"
    let DEVICE_SERVICE_UUID    = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    let CHARACTERISTIC_WRITE_UUID    = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    let CHARACTERISTIC_READ_UUID    = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
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
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbActivity") as! ActivityViewController
        self.present(nextViewController, animated: false, completion: nil)
        //self.dismiss(animated: true, completion: nil)
    }

    static var device_found: Bool = false
    static var will_terminate: Bool = false
    static var task_completed: Bool = false
    static var dg: DispatchGroup = DispatchGroup()
    
    // scan for devices
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            let services:[CBUUID] = [CBUUID(string: "180A")]
            central.scanForPeripherals(withServices: services, options: nil)
            
            // initialize flags
            CaronSyncViewController.device_found = false
            CaronSyncViewController.will_terminate = false
            CaronSyncViewController.task_completed = false

            self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { (Timer) in
                
                CaronSyncViewController.dg.enter()

                // 시간이 자나도록 device를 찾지 못했으면
                if !CaronSyncViewController.device_found
                {
                    self.manager.stopScan()

                    // exit flag 세팅
                    CaronSyncViewController.will_terminate = true
                    
                    // 알람
                    let alertController = UIAlertController(title: "알림", message: "디바이스가 근처에 있지 않습니다", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
                        // 종료
                        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbActivity") as! ActivityViewController
                        self.present(nextViewController, animated: true, completion: nil)
                    })
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }

                CaronSyncViewController.dg.leave()
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
        
        //print(name)
        
        if name?.contains(DEVICE_NAME) == true {
            
            var arrName = name.split{$0 == "-"}.map(String.init)
            
            if arrName.count == 2 {
                var caron: CaronDevice! = CaronDevice()
                caron.name = arrName[0]
                caron.mac_address = arrName[1]
                caron.serial_number = peripheral.identifier.uuidString
                caron.peripheral = peripheral
                self.devices.append(caron)
                
                if caron.mac_address == CaronSyncViewController.mac_address {
                    
                    CaronSyncViewController.dg.enter()

                    // terminate flag가 false일 때 만 동작
                    if !CaronSyncViewController.will_terminate {
                        self.manager.stopScan()
                        // 디바이스를 찾았다고 세팅
                        CaronSyncViewController.device_found = true

                        self.peripheral = peripheral
                        self.peripheral.delegate = self
                        manager.connect(peripheral, options: nil)
                    }

                    CaronSyncViewController.dg.leave()
                }
            }
        }
    }
    
    // disconnect
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        //central.scanForPeripherals(withServices: nil, options: nil)
        print("did disconnect peripheral")

        self.motion_total = 0
        self.motion_received = 0
        self.motion_data.removeAll()
        
        self.caron_latest_time = 0.0
        self.caron_offset_time = 0.0
        
        CaronSyncViewController.dg.enter()
        if !CaronSyncViewController.task_completed {
            let alertController = UIAlertController(title: "알림", message: "디바이스 접속이 원활하지 않습니다", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbActivity") as! ActivityViewController
                self.present(nextViewController, animated: true, completion: nil)
            })
            alertController.addAction(okAction)

            self.present(alertController, animated: true, completion: nil)
        }
        CaronSyncViewController.dg.leave()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("did fail to connect")
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
                //print("broadcast")
            }
            if characteristic.properties.contains(.read) {
                //print("read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.writeWithoutResponse) {
                //print("writeWithoutResponse")
            }
            if characteristic.properties.contains(.write) {
                //print("write")
                let cmd : [UInt8] = [0x02, 0x0F, 0x03]
                peripheral.writeValue(Data(cmd), for: characteristic, type: .withResponse)
            }
            if characteristic.properties.contains(.notify) {
                //print("notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.properties.contains(.indicate) {
                //print("indicate")
            }
            if characteristic.properties.contains(.authenticatedSignedWrites) {
                //print("authenticatedSignedWrites")
            }
            if characteristic.properties.contains(.extendedProperties) {
                //print("extendedProperties")
            }
            if characteristic.properties.contains(.notifyEncryptionRequired) {
                //print("notifyEncryptionRequired")
            }
            if characteristic.properties.contains(.indicateEncryptionRequired) {
                //print("indicateEncryptionRequired")
            }
        }
    }
    
    
    var rx_state: Int = 0
    var motion_total: Int = 0
    var motion_received: Int = 0
    var motion_data: Data = Data()
    
    var caron_latest_time: TimeInterval = 0.0
    var caron_latest_date: String = ""
    var caron_offset_time: TimeInterval = 0.0
    var caron_offset_date: Date = Date()

    // READ
    // changes are coming
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == CHARACTERISTIC_READ_UUID {

            if characteristic.value![0] == 0x02 {
                
                var str: String!
                var i: Int!
                
                switch characteristic.value![1] {
                    
                case 0xf0: // 0f에 대한 배터리, 버전, 카롱ID
                    
                    var battery = [UInt8](repeating: 0x00, count: 3)
                    battery[0] = characteristic.value![2]
                    battery[1] = characteristic.value![3]
                    battery[2] = characteristic.value![4]
                    str = String(bytes: battery, encoding: .utf8)
                    i = Int(str)
                    self.labelBattery.text = "배터리 " + String(i) + "%"
                    
                    var version = [UInt8](repeating: 0x00, count: 4)
                    version[0] = characteristic.value![6]
                    version[1] = characteristic.value![7]
                    version[2] = characteristic.value![8]
                    version[3] = characteristic.value![9]
                    self.labelVersion.text = "버전 " + String(bytes: version, encoding: .utf8)!

                    break;
                    
                case 0xa0: // 10에 대한 모션 데이터 길이 응답
                    
                    var len = [UInt8](repeating: 0x00, count: 5)
                    len[0] = characteristic.value![2]
                    len[1] = characteristic.value![3]
                    len[2] = characteristic.value![4]
                    len[3] = characteristic.value![5]
                    len[4] = characteristic.value![6]
                    //print(characteristic.properties)

                    break;

                case 0xa1: // 20에 대한 모션 데이터 길이 응답
                    
                    var len = [UInt8](repeating: 0x00, count: 5)
                    len[0] = characteristic.value![2]
                    len[1] = characteristic.value![3]
                    len[2] = characteristic.value![4]
                    len[3] = characteristic.value![5]
                    len[4] = characteristic.value![6]
                    
                    self.motion_total = Int(String(bytes: len, encoding: .utf8)!)!
                    self.motion_received = 0
                    self.motion_data.removeAll()
                    
                    self.caron_latest_time = getCurrentTime()
                    self.caron_offset_time = getOffsetTime(current: self.caron_latest_time, count: motion_total)
                    self.caron_offset_date = Date(timeIntervalSince1970: self.caron_offset_time)
                    
                    let df: DateFormatter = DateFormatter()
                    df.timeZone = TimeZone.current
                    df.dateFormat = "yyyy-MM-dd hh:mm:ss"
                    
                    self.caron_latest_date = df.string(from: Date(timeIntervalSince1970: self.caron_latest_time))

                    break;
                    
                case 0xb0: // 20에 대한 모션 데이터 전송 응답
                    
                    var len: Int = 17 // 주의! 프로토콜이 바뀌면 길이도 바뀌어야 함!
                    let left: Int = self.motion_total - self.motion_received
                    if len > left {
                        len = left
                    }
                    
                    let end: Int = len + 2
                    motion_data.append(characteristic.value![2..<end])
                    
                    self.motion_received = self.motion_received + len
                    
                    let rate: Double = Double(motion_received) / Double(motion_total) *  100.0
                    
                    DispatchQueue.main.async {
                        self.labelSync.text = "동기화 (" + String(Int(rate)) + "%)"
                    }

                    break;
                    
                case 0xc0: // 20에 대한 모션 데이터 전송 완료 응답
                    
                    CaronSyncViewController.dg.enter()
                    CaronSyncViewController.task_completed = true
                    CaronSyncViewController.dg.leave()

                    DispatchQueue.global(qos:.userInteractive).async { self.run() }

                    break;
                
                case 0x90: // 30에 대한 모션 데이터 삭제 완료 응답
                    print("delete")
                    break;
                    
                default:
                    break;
                }
            }
        }
    }
    
    func run() {
        
        /*
        print("[0]: " + String(([UInt8](self.motion_data))[0]))
        print("[1]: " + String(([UInt8](self.motion_data))[1]))
        print("[2]: " + String(([UInt8](self.motion_data))[2]))
        print("[3]: " + String(([UInt8](self.motion_data))[3]))

        print("[39991]: " + String(([UInt8](self.motion_data))[39991]))
        print("[39992]: " + String(([UInt8](self.motion_data))[39992]))
        print("[39993]: " + String(([UInt8](self.motion_data))[39993]))
        print("[39994]: " + String(([UInt8](self.motion_data))[39994]))
        print("[39995]: " + String(([UInt8](self.motion_data))[39995]))
        print("[39996]: " + String(([UInt8](self.motion_data))[39996]))
        print("[39997]: " + String(([UInt8](self.motion_data))[39997]))
        print("[39998]: " + String(([UInt8](self.motion_data))[39998]))
        */

        let cn: String = CaronSyncViewController.child_no
        insertActivityToRemote(child_no: cn)
        insertActivityToLocal(child_no: cn)
        synchronizeHourlySummaryWithRemote(child_no: cn)
        synchronizeDailySummaryWithRemote(child_no: cn)
        
        DispatchQueue.main.async {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbActivity") as! ActivityViewController
            self.present(nextViewController, animated: false, completion: nil)
        }
    }
    
    // 시간 단위 데이터를 서버에 올리기
    func synchronizeHourlySummaryWithRemote(child_no cn: String) {
        let aph = activity_per_hour()
        aph.child_no = cn
        aph.synchronize_with_remote(
            progress_sync: { (i: Int)->() in
                var rate: Double = Double(i) / Double(aph.sync_total) *  100.0
                if rate < 0.0 { rate = 0.0 }
                if rate > 100.0 { rate = 100.0 }
                
                DispatchQueue.main.async {
                    self.labelSync.text = "시간 단위 동기화 (" + String(Int(rate)) + "%)"
                }
            },
            progress_update: { (i: Int)->() in
                var rate: Double = Double(i) / Double(aph.update_total) *  100.0
                if rate < 0.0 { rate = 0.0 }
                if rate > 100.0 { rate = 100.0 }
                
                DispatchQueue.main.async {
                    self.labelSync.text = "시간 단위 동기화 (" + String(Int(rate)) + "%)"
                }
            }
        )
    }
    
    // 일 단위 데이터를 서버에 올리기
    func synchronizeDailySummaryWithRemote(child_no cn: String) {
        let apd = activity_per_day()
        apd.child_no = cn
        apd.synchronize_with_remote(
            progress_sync: { (i: Int)->() in
                var rate: Double = Double(i) / Double(apd.sync_total) *  100.0
                if rate < 0.0 { rate = 0.0 }
                if rate > 100.0 { rate = 100.0 }
                
                DispatchQueue.main.async {
                    self.labelSync.text = "일 단위 업데이트 (" + String(Int(rate)) + "%)"
                }
            },
            progress_update: { (i: Int)->() in
                var rate: Double = Double(i) / Double(apd.update_total) *  100.0
                if rate < 0.0 { rate = 0.0 }
                if rate > 100.0 { rate = 100.0 }
                
                DispatchQueue.main.async {
                    self.labelSync.text = "일 단위 업데이트 (" + String(Int(rate)) + "%)"
                }
            }
        )
    }

    // 활동 RAW 데이터를 요약하여 로컬에 저장
    func insertActivityToLocal(child_no cn: String) {

        // 시간 단위 요약
        let aph = activity_per_hour()
        aph.child_no = cn
        aph.set_utc_range(offset: self.caron_offset_time, latest: self.caron_latest_time)
        aph.summarize_and_insert(caron_data: self.motion_data, caron_total_count: self.motion_total) { (end: TimeInterval)->() in
            var rate: Double = Double(end - aph.offset_utc) / Double(aph.latest_utc - aph.offset_utc) *  100.0
            if rate < 0.0 { rate = 0.0 }
            if rate > 100.0 { rate = 100.0 }

            DispatchQueue.main.async {
                self.labelSync.text = "시간 단위 요약 (" + String(Int(rate)) + "%)"
            }
        }
        
        // 일 단위 요약
        let apd = activity_per_day()
        apd.child_no = cn
        apd.summarize_and_insert() { (end: TimeInterval)->() in
            var rate: Double = Double(end - apd.offset_utc) / Double(aph.latest_utc - apd.offset_utc) *  100.0
            if rate < 0.0 { rate = 0.0 }
            if rate > 100.0 { rate = 100.0 }

            DispatchQueue.main.async {
                self.labelSync.text = "일 단위 요약 (" + String(Int(rate)) + "%)"
            }
        }
        
        print("All summarization processes have been completed.")
    }
    
    func getCurrentTime() -> TimeInterval {
        var date: Date = Date()
        
        let ns: Int = Calendar.current.component(.nanosecond, from: date)
        date = Calendar.current.date(byAdding: .nanosecond, value: -ns, to: date)!
        
        let s: Int = Calendar.current.component(.second, from: date)
        date = Calendar.current.date(byAdding: .second, value: -s, to: date)!
        
        return date.timeIntervalSince1970
    }
    
    func getOffsetTime(current: TimeInterval, count: Int) -> TimeInterval {
        var date: Date = Calendar.current.date(byAdding: .minute, value: -count, to: Date(timeIntervalSince1970: current))!
        
        let ns: Int = Calendar.current.component(.nanosecond, from: date)
        date = Calendar.current.date(byAdding: .nanosecond, value: -ns, to: date)!
        
        let s: Int = Calendar.current.component(.second, from: date)
        date = Calendar.current.date(byAdding: .second, value: -s, to: date)!
        
        return date.timeIntervalSince1970
    }

    
    // 활동 RAW 데이터를 서버에 전송
    func insertActivityToRemote(child_no cn: String)
    {
        // Session
        let defaultSession = URLSession(configuration: .default)
        
        self.caron_latest_date = self.caron_latest_date.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        
        guard let url = URL(string: "http://internkid.com/activity_raw_data.insert.api.php?child_no=" + cn + "&count=" + String(self.motion_total) + "&utc=" + String(Int(self.caron_latest_time)) + "&time=" + self.caron_latest_date) else {
            print("URL is nil")
            return
        }
        
        let str_data: String = "data=" + String(data: self.motion_data.base64EncodedData(), encoding: .utf8)!
        
        // Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = str_data.data(using: .utf8, allowLossyConversion: false)
        
        let dg0: DispatchGroup = DispatchGroup()
        dg0.enter()
        
        // dataTask
        let dataTask = defaultSession.dataTask(with: request) { data, response, error in
            // getting Data Error
            guard error == nil else {
                print("Error occur: \(String(describing: error))")
                dg0.leave()
                return
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                //print("insertActivityToRemote: success")
            } else {
                //print("insertActivityToRemote: failed")
                
                dg0.leave()
                return
            }
            
            dg0.leave()
        }
        dataTask.resume()
        dg0.wait()
        
        //return remote_no
    }
    
    func json(from object:Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }


    // WRITE
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {

        if let error = error {
            print("Writing error", error)
        } else {
            //print("Succeeded")
            //print(characteristic.uuid)
            //print(characteristic.properties)
            //print(characteristic.value?.count ?? "-")

            if characteristic.uuid == CHARACTERISTIC_WRITE_UUID {
                if rx_state == 0 {
                    let cmd : [UInt8] = [0x02, 0x20, 0x03]
                    peripheral.writeValue(Data(cmd), for: characteristic, type: .withResponse)
                    rx_state = 1
                }
            }
        }
    }
}
