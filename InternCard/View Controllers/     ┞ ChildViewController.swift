//
//  ChildViewController.swift
//  InternCard
//
//  Created by idl on 2018. 9. 3..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import UIKit
import CoreBluetooth
import Charts

class ChildViewController: UIViewController, UITextFieldDelegate {
    
    static var remote_no: String! = "0"

    struct Constants {
        
        // card
        static let cardMargin                        : CGFloat = 48.0
        static let cardRadius                        : CGFloat = 9.0
        static let cardWidth                         : CGFloat = ContentCardsViewController.Constants.screenWidth - cardMargin - cardMargin
        static let cardHeight                        : CGFloat  = 210.0
        static let cardShadowOpacity                 : Float = 0.24
        static let cardShadowOffset                  : CGSize = CGSize.zero //CGSize(width: 0, height: 4) //CGSize.zero
        static let cardShadowRadius                  : CGFloat = 2.0
        
        static let cardY                             : CGFloat = 580.0
    }

    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var ivPhoto: UIImageView!
    @IBOutlet weak var tfName: UITextField!
    @IBOutlet weak var tbMan: UIButton!
    @IBOutlet weak var tbWoman: UIButton!
    @IBOutlet weak var tfBirthYear: UITextField!
    @IBOutlet weak var tfBirthMonth: UITextField!
    @IBOutlet weak var tfHeight: UITextField!
    @IBOutlet weak var tfWeight: UITextField!
    @IBOutlet weak var lbCaronInfo: UILabel!

    let genderDg: DispatchGroup! = DispatchGroup()
    let imgManEnabled = UIImage(named: "man_enabled")
    let imgManDisabled = UIImage(named: "man_disabled")
    let imgWomanEnabled = UIImage(named: "woman_enabled")
    let imgWomanDisabled = UIImage(named: "woman_disabled")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tfName.setBottomBorder()
        tfName.delegate = self
        tfBirthYear.setBottomBorder()
        tfBirthYear.delegate = self
        tfBirthMonth.setBottomBorder()
        tfBirthMonth.delegate = self
        tfHeight.setBottomBorder()
        tfHeight.delegate = self
        tfWeight.setBottomBorder()
        tfWeight.delegate = self
        
        loadChild()
        
        checkCaron()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
        
        
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
        backButton.addTarget(self, action: #selector(clickBackButton(_:)), for: .touchUpInside)
        self.view.addSubview(backButton)
        
        scrollView.contentSize.height = ContentCardsViewController.Constants.screenHeight // + 180 + Constants.cardMargin + Constants.cardHeight
    }
    
    func loadChild() {
        let c = child()
        c.remote_no = ActivityViewController.remote_no
        c.select_by_remote_no()
        
        let h = height()
        h.child_no = ActivityViewController.remote_no
        h.select_by_child_no()
        
        let w = weight()
        w.child_no = ActivityViewController.remote_no
        w.select_by_child_no()
        
        self.tfName.text = c.name
        if c.gender == "M" {
            self.tbMan.setImage(self.imgManEnabled, for: .normal)
            self.tbWoman.setImage(self.imgWomanDisabled, for: .normal)
        } else {
            self.tbMan.setImage(self.imgManDisabled, for: .normal)
            self.tbWoman.setImage(self.imgWomanEnabled, for: .normal)
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: c.birth)
        dateFormatter.dateFormat = "yyyy";
        self.tfBirthYear.text = dateFormatter.string(from: date!)
        dateFormatter.dateFormat = "M";
        self.tfBirthMonth.text = dateFormatter.string(from: date!)
        
        self.tfHeight.text =  h.height
        self.tfWeight.text = w.weight
    }
    
    @objc func clickBackButton(_ sender: AnyObject?) {
        ActivityViewController.remote_no = ChildViewController.remote_no
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbActivity") as! ActivityViewController
        self.present(nextViewController, animated: false, completion: nil)
    }

    @IBAction func updateName(_ sender: Any) {
        let name: String! = (sender as! UITextField).text
        do {
            let db = try SQLite()
            let sql:String! = "UPDATE `child` SET `name`='" + name  + "' WHERE `remote_no`='" + ChildViewController.remote_no + "'"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }
    
    func updateGender(_ gender: String) {
        do {
            let db = try SQLite()
            let sql:String! = "UPDATE `child` SET `gender`='" + gender  + "' WHERE `remote_no`='" + ChildViewController.remote_no + "'"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }
    
    @IBAction func manTouchDown(_ sender: Any) {
        genderDg.wait()
        genderDg.enter()
        tbMan.setImage(imgManEnabled, for: .normal)
        tbWoman.setImage(imgWomanDisabled, for: .normal)
        genderDg.leave()

        updateGender("M")
    }
    
    @IBAction func womanTouchDown(_ sender: Any) {
        genderDg.wait()
        genderDg.enter()
        tbMan.setImage(imgManDisabled, for: .normal)
        tbWoman.setImage(imgWomanEnabled, for: .normal)
        genderDg.leave()

        updateGender("W")
    }
    
    @IBAction func updateBirthYear(_ sender: Any) {
        let birthYear: String! = (sender as! UITextField).text
        let birth: String! = birthYear! + "-" + self.tfBirthMonth.text! + "-1"
        do {
            let db = try SQLite()
            let sql:String! = "UPDATE `child` SET `birth`='" + birth  + "' WHERE `remote_no`='" + ChildViewController.remote_no + "'"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }
    
    @IBAction func updateBirthMonth(_ sender: Any) {
        let birthMonth: String! = (sender as! UITextField).text
        let birth: String! = self.tfBirthYear.text! + "-" + birthMonth! + "-1"
        do {
            let db = try SQLite()
            let sql:String! = "UPDATE `child` SET `birth`='" + birth  + "' WHERE `remote_no`='" + ChildViewController.remote_no + "'"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }
    
    @IBAction func updateHeight(_ sender: Any) {
        let height: String! = (sender as! UITextField).text
        do {
            let db = try SQLite()
            let sql:String! = "INSERT INTO `height` (`child_no`, `height`) VALUES ('" + ChildViewController.remote_no + "', '" + height  + "')"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }
    
    @IBAction func updateWeight(_ sender: Any) {
        let weight: String! = (sender as! UITextField).text
        do {
            let db = try SQLite()
            let sql:String! = "INSERT INTO `weight` (`child_no`, `weight`) VALUES ('" + ChildViewController.remote_no + "', '" + weight  + "')"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }
    
    @objc func clickAddCaron(_ sender: AnyObject?) {
        CaronSearchViewController.child_no = ChildViewController.remote_no
        let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbCaronSearch") as! CaronSearchViewController
        self.present(nextViewController, animated: true, completion: nil)
    }

    @objc func clickSyncCaron(_ sender: AnyObject?) {
        CaronSyncViewController.child_no = ChildViewController.remote_no
        let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbCaronSync") as! CaronSyncViewController
        self.present(nextViewController, animated: true, completion: nil)
    }

    func checkCaron() {
        let cd = caron_device()
        cd.child_no = ChildViewController.remote_no
        let found: Bool = cd.select_by_child_no()
        CaronSyncViewController.mac_address = cd.mac_address
        CaronSyncViewController.serial_number = cd.serial_number
        
        if found {
            self.lbCaronInfo.text = cd.mac_address + "\n" + cd.serial_number
        }
    }
    
    // get start time of the week from now
    func getStartTime(from today: Date) -> TimeInterval {
        var date = Calendar.current.date(byAdding: .day, value: -6, to: today)!
        
        let ns: Int = Calendar.current.component(.nanosecond, from: date)
        date = Calendar.current.date(byAdding: .nanosecond, value: -ns, to: date)!
        
        let s: Int = Calendar.current.component(.second, from: date)
        date = Calendar.current.date(byAdding: .second, value: -s, to: date)!
        
        let m: Int = Calendar.current.component(.minute, from: date)
        date = Calendar.current.date(byAdding: .minute, value: -m, to: date)!
        
        let h: Int = Calendar.current.component(.hour, from: date)
        date = Calendar.current.date(byAdding: .hour, value: -h, to: date)!

        return date.timeIntervalSince1970
    }
    
    func getEndTime(from today: Date) -> TimeInterval {
        var date = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let ns: Int = Calendar.current.component(.nanosecond, from: date)
        date = Calendar.current.date(byAdding: .nanosecond, value: -ns, to: date)!
        
        let s: Int = Calendar.current.component(.second, from: date)
        date = Calendar.current.date(byAdding: .second, value: -s, to: date)!
        
        let m: Int = Calendar.current.component(.minute, from: date)
        date = Calendar.current.date(byAdding: .minute, value: -m, to: date)!
        
        let h: Int = Calendar.current.component(.hour, from: date)
        date = Calendar.current.date(byAdding: .hour, value: -h, to: date)!
        
        return date.timeIntervalSince1970
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
        tfName.resignFirstResponder()
        tfBirthYear.resignFirstResponder()
        tfBirthMonth.resignFirstResponder()
        tfHeight.resignFirstResponder()
        tfWeight.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
