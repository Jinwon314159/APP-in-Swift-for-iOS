//
//  InternWeatherViewController.swift
//  InternCard
//
//  Created by idl on 2018. 10. 25..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import UIKit

class InternWeatherViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        let offset: CGFloat = 120
        let w: CGFloat = 312
        let h: CGFloat = 64
        let margin: CGFloat = 24
        
        let btnMom0: UIButton! = UIButton(type: .custom)
        btnMom0.setImage(UIImage(named: "mom0.btn.png"), for: .normal)
        btnMom0.frame = CGRect(x: ContentCardsViewController.Constants.screenWidth / 2 - w / 2, y: offset, width: w, height: h)
        btnMom0.addTarget(self, action: #selector(clickMom0Button(_:)), for: .touchUpInside)
        self.view.addSubview(btnMom0)
        
        let btnMom1: UIButton! = UIButton(type: .custom)
        btnMom1.setImage(UIImage(named: "mom1.btn.png"), for: .normal)
        btnMom1.frame = CGRect(x: ContentCardsViewController.Constants.screenWidth / 2 - w / 2, y: offset + h + margin, width: w, height: h)
        btnMom1.addTarget(self, action: #selector(clickMom1Button(_:)), for: .touchUpInside)
        self.view.addSubview(btnMom1)
        
        let btnMom2: UIButton! = UIButton(type: .custom)
        btnMom2.setImage(UIImage(named: "mom2.btn.png"), for: .normal)
        btnMom2.frame = CGRect(x: ContentCardsViewController.Constants.screenWidth / 2 - w / 2, y: offset + 2 * (h + margin), width: w, height: h)
        btnMom2.addTarget(self, action: #selector(clickMom2Button(_:)), for: .touchUpInside)
        self.view.addSubview(btnMom2)
        
        let btnMom3: UIButton! = UIButton(type: .custom)
        btnMom3.setImage(UIImage(named: "mom3.btn.png"), for: .normal)
        btnMom3.frame = CGRect(x: ContentCardsViewController.Constants.screenWidth / 2 - w / 2, y: offset + 3 * (h + margin), width: w, height: h)
        btnMom3.addTarget(self, action: #selector(clickMom3Button(_:)), for: .touchUpInside)
        self.view.addSubview(btnMom3)
        
        let btnMom4: UIButton! = UIButton(type: .custom)
        btnMom4.setImage(UIImage(named: "mom4.btn.png"), for: .normal)
        btnMom4.frame = CGRect(x: ContentCardsViewController.Constants.screenWidth / 2 - w / 2, y: offset + 4 * (h + margin), width: w, height: h)
        btnMom4.addTarget(self, action: #selector(clickMom4Button(_:)), for: .touchUpInside)
        self.view.addSubview(btnMom4)
    }
    
    @objc func clickMom0Button(_ sender: AnyObject?) {
        insertInternWeather(tears: "1")
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func clickMom1Button(_ sender: AnyObject?) {
        insertInternWeather(tears: "2")
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func clickMom2Button(_ sender: AnyObject?) {
        insertInternWeather(tears: "3")
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func clickMom3Button(_ sender: AnyObject?) {
        insertInternWeather(tears: "4")
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func clickMom4Button(_ sender: AnyObject?) {
        insertInternWeather(tears: "5")
        self.dismiss(animated: true, completion: nil)
    }

    @objc func clickBackButton(_ sender: AnyObject?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func insertInternWeather(tears: String)
    {
        var result: Bool = false
        
        var user_no: String = "0"
        
        let u = user()
        let iw = intern_weather()

        if u.select_last() {
            user_no = u.remote_no
        }

        result = iw.insert_remote(user_no: user_no, tears: tears)
        if !result {
            // 알람
            let alertController = UIAlertController(title: "알림", message: "네트워크가 원활하지 않습니다", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
        
        if result {
            // 로컬에도 입력 (하루에 몇 번 입력하는 것이 좋을까? 새벽 4시를 기준으로 하루를 나누는 것이 좋을까?)
            iw.user_no = user_no
            iw.tears = tears
            iw.insert()
        }
    }
}
