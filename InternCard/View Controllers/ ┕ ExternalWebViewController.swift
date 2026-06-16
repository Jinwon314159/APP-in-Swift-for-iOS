//
//  ExternalWebViewController.swift
//  InternCard
//
//  Created by idl on 2018. 8. 18..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import UIKit
import Firebase
import WebKit

class ExternalWebViewController : UIViewController, WKNavigationDelegate {
    
    static var url: String! = "http://internkid.com"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webView: WKWebView! = WKWebView(frame: CGRect(x: 0, y: ContentCardsViewController.Constants.headerHeight + ContentCardsViewController.Constants.statusBarHeight, width: ContentCardsViewController.Constants.screenWidth, height: ContentCardsViewController.Constants.screenHeight - ContentCardsViewController.Constants.headerHeight - ContentCardsViewController.Constants.statusBarHeight))
        webView.navigationDelegate = self
        
        let go: URL! = URL(string: ExternalWebViewController.url)
        webView.load(URLRequest(url: go))
        webView.allowsBackForwardNavigationGestures = true
        
        self.view.addSubview(webView)

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
    }
    
    @objc func clickBackButton(_ sender: AnyObject?) {
        self.dismiss(animated: true, completion: nil)
    }

}
