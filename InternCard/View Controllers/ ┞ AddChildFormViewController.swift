//
//  AddChildFormViewController.swift
//  InternCard
//
//  Created by idl on 2018. 7. 26..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import UIKit
import Firebase

extension UITextField {
    func setBottomBorder() {
        self.borderStyle = .none
        self.layer.backgroundColor = UIColor.white.cgColor
        
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
    }
}

class AddChildFormViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var ivAddPhoto: UIImageView!
    @IBOutlet weak var lbAddName: UILabel!
    @IBOutlet weak var tfAddName: UITextField!
    @IBOutlet weak var lbAddGender: UILabel!
    @IBOutlet weak var tbAddMan: UIButton!
    @IBOutlet weak var tbAddWoman: UIButton!
    @IBOutlet weak var lbAddBirth: UILabel!
    @IBOutlet weak var tfAddBirthYear: UITextField!
    @IBOutlet weak var tfAddBirthMonth: UITextField!
    @IBOutlet weak var tfAddHeight: UITextField!
    @IBOutlet weak var tfAddWeight: UITextField!
    @IBOutlet weak var btnAddChild: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var activeTextField = UITextField()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnAddChild.isEnabled = false
        
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
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        
        tfAddName.setBottomBorder()
        tfAddName.delegate = self
        tfAddBirthYear.setBottomBorder()
        tfAddBirthYear.delegate = self
        tfAddBirthMonth.setBottomBorder()
        tfAddBirthMonth.delegate = self
        tfAddHeight.setBottomBorder()
        tfAddHeight.delegate = self
        tfAddWeight.setBottomBorder()
        tfAddWeight.delegate = self
        
        
        gender = "M"
        tbAddMan.setImage(imgManEnabled, for: .normal)
        tbAddWoman.setImage(imgWomanDisabled, for: .normal)


        scrollView.contentSize.height = ContentCardsViewController.Constants.screenHeight
    }

    let genderDg: DispatchGroup! = DispatchGroup()
    var gender: String = "M"  // M: Man, W: Woman
    let imgManEnabled = UIImage(named: "man_enabled")
    let imgManDisabled = UIImage(named: "man_disabled")
    let imgWomanEnabled = UIImage(named: "woman_enabled")
    let imgWomanDisabled = UIImage(named: "woman_disabled")

    @IBAction func manTouchDown(_ sender: Any) {
        genderDg.wait()
        genderDg.enter()
        gender = "M"
        tbAddMan.setImage(imgManEnabled, for: .normal)
        tbAddWoman.setImage(imgWomanDisabled, for: .normal)
        genderDg.leave()
    }
    
    @IBAction func womanTouchDown(_ sender: Any) {
        genderDg.wait()
        genderDg.enter()
        gender = "W"
        tbAddMan.setImage(imgManDisabled, for: .normal)
        tbAddWoman.setImage(imgWomanEnabled, for: .normal)
        genderDg.leave()
    }

    // Assign the newly active text field to your activeTextField variable
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //self.scrollView.contentOffset.y = textField.frame.origin.x
        var y: CGFloat = textField.frame.origin.y - ContentCardsViewController.Constants.screenHeight / 2 - ContentCardsViewController.Constants.headerHeight
        if y < 0 { y = -ContentCardsViewController.Constants.statusBarHeight }
        self.scrollView.setContentOffset(CGPoint(x: 0, y: y), animated: true)
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
        tfAddName.resignFirstResponder()
        tfAddBirthYear.resignFirstResponder()
        tfAddBirthMonth.resignFirstResponder()
        tfAddHeight.resignFirstResponder()
        tfAddWeight.resignFirstResponder()
    }
    
    @objc func clickBackButton(_ sender: AnyObject?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let user = Auth.auth().currentUser
        if user != nil {
            // User is signed in.
            // print(user?.phoneNumber);
            btnAddChild.isEnabled = true
        } else {
            // User is not signed in
            if ContentCardsViewController.Constants.signInTriedButCaceled {
                ContentCardsViewController.Constants.signInTriedButCaceled = false
                self.dismiss(animated: true, completion: nil)
            } else {
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbPhoneAuth") as! PhoneAuthViewController
                self.present(nextViewController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func addChild(_ sender: Any) {
  
        let name: String! = tfAddName.text
        if name.isEmpty {
            tfAddName.becomeFirstResponder()
            return
        }
        let gender: String! = self.gender
        
        let birthYear: String! = tfAddBirthYear.text
        if birthYear.isEmpty {
            tfAddBirthYear.becomeFirstResponder()
            return
        }
        let birthMonth: String! = tfAddBirthMonth.text
        if birthMonth.isEmpty {
            tfAddBirthMonth.becomeFirstResponder()
            return
        }
        let birth: String! = tfAddBirthYear.text! + "-" + tfAddBirthMonth.text! + "-1"
        let strHeight: String! = tfAddHeight.text
        if strHeight.isEmpty {
            tfAddHeight.becomeFirstResponder()
            return
        }
        let strWeight: String! = tfAddWeight.text
        if strWeight.isEmpty {
            tfAddWeight.becomeFirstResponder()
            return
        }

        // to get user_no
        let u = user()
        var user_no: String = ""
        if u.select_last() {
            user_no = u.remote_no
        }

        //////////// Insert `child` data and get `remote_no` from server
        let child_no: String! = insertChildToRemote(name: name, gender: gender, birth: birth, user_no: user_no)
        
        insertHeightToRemote(child_no: child_no, height: strHeight)
        insertWeightToRemote(child_no: child_no, weight: strWeight)

        if child_no != "0" {
            // insert into local DB
            let c = child()
            c.remote_no = child_no
            c.name = name
            c.gender = gender
            c.birth = birth
            c.user_no = user_no
            c.insert()
            
            let h = height()
            h.child_no = child_no
            h.height = strHeight
            h.insert()
            
            let w = weight()
            w.child_no = child_no
            w.weight = strWeight
            w.insert()
        }
        
        ContentCardsViewController.Constants.childCardAdded = true
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbMain") as! PageViewController
        self.present(nextViewController, animated: true, completion: nil)
    }

    func insertChildToRemote(name: String, gender: String, birth: String, user_no: String) -> String
    {
        var remote_no: String! = "0"
        
        // Session
        let defaultSession = URLSession(configuration: .default)
        let str: String = "http://internkid.com/child.insert.api.php?name=" + name + "&gender=" + gender + "&birth=" + birth + "&user_no=" + user_no
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
                
                let jsonResult = json[0] as! Dictionary<String, Any>
                remote_no = jsonResult["no"] as? String
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
    
    func insertHeightToRemote(child_no: String, height: String)
    {
        //var remote_no: String! = "0"
        // Session
        let defaultSession = URLSession(configuration: .default)
        
        guard let url = URL(string: "http://internkid.com/height.insert.api.php?child_no=" + child_no + "&height=" + height) else {
            print("URL is nil")
            return
        }
        
        // Request
        let request = URLRequest(url: url)
        
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
                
                //remote_no = json[0]["no"] as? String
                
            } else {
                dg0.leave()
                return
            }
            
            dg0.leave()
        }
        dataTask.resume()
        dg0.wait()
        
        //return remote_no
    }
    
    func insertWeightToRemote(child_no: String, weight: String)
    {
        //var remote_no : String! = "0"
        // Session
        let defaultSession = URLSession(configuration: .default)
        
        guard let url = URL(string: "http://internkid.com/weight.insert.api.php?child_no=" + child_no + "&weight=" + weight) else {
            print("URL is nil")
            return
        }
        
        // Request
        let request = URLRequest(url: url)
        
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
                
                //remote_no = json[0]["no"] as? String
                
            } else {
                dg0.leave()
                return
            }
            
            dg0.leave()
        }
        dataTask.resume()
        dg0.wait()
        
        //return remote_no
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}
