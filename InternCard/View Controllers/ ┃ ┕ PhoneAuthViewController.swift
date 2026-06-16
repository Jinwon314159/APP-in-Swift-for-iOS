//
//  PhoneAuthViewController.swift
//  InternCard
//
//  Created by idl on 2018. 7. 26..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import UIKit
import Firebase


class PhoneAuthViewController : UIViewController {
    
    @IBOutlet weak var tvPhone: UITextField!
    @IBOutlet weak var btnSend: UIButton!
    
    @IBOutlet weak var lbCode: UILabel!
    @IBOutlet weak var tvCode: UITextField!
    @IBOutlet weak var btnAuth: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
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
        backButton.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        self.view.addSubview(backButton)

        
        // Do any additional setup after loading the view.
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PhoneAuthViewController.dismissKeyboard))
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc func buttonClicked(_ sender: AnyObject?) {
        ContentCardsViewController.Constants.signInTriedButCaceled = true
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func btnSend(_ sender: UIButton) {
        view.endEditing(true)
        
        self.btnSend.isEnabled = false
        
        let phoneNumber: String = "+82" + tvPhone.text!
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                self.btnSend.isEnabled = true
                self.tvCode.isEnabled = false
                self.btnAuth.isEnabled = false

                print(error.localizedDescription)
                return
            }
            // Sign in using the verificationID and the code sent to the user
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            // let verificationID = UserDefaults.standard.string(forKey: "authVerificationID")
            
            self.btnSend.isEnabled = false
            self.tvCode.isEnabled = true
            self.btnAuth.isEnabled = true
            
            self.tvCode.becomeFirstResponder()
        }
    }
    
    @IBAction func btnAuth(_ sender: UIButton) {
        view.endEditing(true)
        
        let verificationID = UserDefaults.standard.string(forKey: "authVerificationID")
        let verificationCode: String = tvCode.text!
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID!,
            verificationCode: verificationCode)
        
        Auth.auth().languageCode = "ko"
        
        //Auth.auth().signInAnonymously() { (authResult, error) in
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if let error = error {
                self.btnSend.isEnabled = true
                self.tvCode.isEnabled = false
                self.btnAuth.isEnabled = false

                print(error.localizedDescription)
                return
            }
            
            //////////// get `remote_no` from server
            // Session
            let defaultSession = URLSession(configuration: .default)
            
            guard let url = URL(string: "http://internkid.com/user.insert.api.php?oauth2_provider=firebase_sms&uid=" + (Auth.auth().currentUser?.uid)! + "&client_id=" + (Auth.auth().currentUser?.phoneNumber?.replacingOccurrences(of: "+", with: "%2B"))! + "&levle=0&feature_flags=00000000") else {
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
                    
                    let remote_no: String! = json[0]["no"] as? String
                    
                    // insert into local DB
                    let u = user()
                    u.remote_no = remote_no
                    u.oauth2_provider = "firebase_sms"
                    u.uid = (Auth.auth().currentUser?.uid)!
                    u.client_id = (Auth.auth().currentUser?.phoneNumber)!
                    u.level = "0"
                    u.insert()
                }
                
                dg0.leave()
            }
            dataTask.resume()
            dg0.wait()
            
            self.dismiss(animated: true, completion: nil)
        }
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
