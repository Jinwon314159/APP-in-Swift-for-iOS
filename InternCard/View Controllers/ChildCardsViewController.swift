//
//  AddChildViewController.swift
//  InternCard
//
//  Created by idl on 2018. 6. 25..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import UIKit

class ChildCardsViewController: UIViewController {
    
    struct Constants {
        
        // card
        static let cardMargin                        : CGFloat = 12.0
        static let cardRadius                        : CGFloat = 9.0
        static let cardWidth                         : CGFloat = ContentCardsViewController.Constants.screenWidth - cardMargin - cardMargin
        static let cardHeight                        : CGFloat  = 210.0
        static let cardShadowOpacity                 : Float = 0.24
        static let cardShadowOffset                  : CGSize = CGSize.zero //CGSize(width: 0, height: 4) //CGSize.zero
        static let cardShadowRadius                  : CGFloat = 2.0
        
        static let cardLogoWidth                     : CGFloat = ContentCardsViewController.Constants.screenWidth / 2
        static let cardLogoHeight                    : CGFloat = 48.0

        static let cardNameOffset                    : CGFloat = cardMargin + cardLogoHeight + 10
        static let cardNameWidth                     : CGFloat = cardLogoWidth
        static let cardNameHeight                    : CGFloat = 24.0

        static let cardBirthOffset                   : CGFloat = cardNameOffset + cardNameHeight + 5
        static let cardBirthWidth                    : CGFloat = cardLogoWidth
        static let cardBirthHeight                   : CGFloat = 24.0
        
        static let cardHeightWeightOffset            : CGFloat = cardBirthOffset + cardBirthHeight + 5
        static let cardHeightWeightWidth             : CGFloat = cardLogoWidth
        static let cardHeightWeightHeight            : CGFloat = 24.0
        
        static let cardDetectedOffset                : CGFloat = cardHeightWeightOffset + cardHeightWeightHeight + 10
        static let cardDetectedWidth                 : CGFloat = cardLogoWidth
        static let cardDetectedHeight                : CGFloat = 24.0

        static let cardPhotoOffsetX                  : CGFloat = cardWidth / 2 + cardMargin
        static let cardPhotoWidth                    : CGFloat = cardWidth / 2 - cardMargin - cardMargin
        static let cardPhotoHeight                   : CGFloat = cardHeight - cardMargin - cardMargin

        static let addChildButtonWidth               : CGFloat = 72.0
        static let addChildButtonHeight              : CGFloat = 72.0

        // Types of tasks
        static let SET_INITIAL_CARD                  : Int = 0  // 실행 초기에 N개의 카드를 업데이트한다.
        static let APPEND_CARD_to_BOTTOM             : Int = 1  // BOTTOM에 N개의 카드를 추가한다.
        static let APPEND_CARD_to_TOP                : Int = 2  // TOP에 N개의 카드를 추가한다.
    }


    
    var scrollView: UIScrollView!
    var cardViews: [UIView] = []

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
        
        scrollView = UIScrollView(frame: CGRect(x: 0, y: ContentCardsViewController.Constants.headerHeight + ContentCardsViewController.Constants.statusBarHeight, width: ContentCardsViewController.Constants.screenWidth, height: ContentCardsViewController.Constants.screenHeight - ContentCardsViewController.Constants.headerHeight - ContentCardsViewController.Constants.statusBarHeight))
        self.view.addSubview(scrollView)

        do {
            let db = try SQLite()
            let sql: String = "SELECT `remote_no`, `name`, `gender`, `birth` FROM `child` ORDER BY `no` ASC"
            
            try db.install(query: sql)
            try db.execute() { stmt in
                let remote_no: String = String(cString: sqlite3_column_text(stmt, 0))
                let name: String = String(cString: sqlite3_column_text(stmt, 1))
                let gender: String = String(cString: sqlite3_column_text(stmt, 2))
                let birth: String = String(cString: sqlite3_column_text(stmt, 3))
                let height: String = self.getHeightByChildNo(child_no: remote_no)
                let weight: String = self.getWeightByChildNo(child_no: remote_no)
                
                let childCard: UIView = self.generateChildCard(remote_no: remote_no, name: name, gender: gender, birth: birth, height: height, weight: weight)
                self.cardViews.append(childCard)
                self.scrollView.addSubview(childCard)
            }
        } catch { print(error) }
        
        let addChildCard: UIView = generateAddChildCard()
        self.cardViews.append(addChildCard)
        self.scrollView.addSubview(addChildCard)
        
        self.updateScrollViewContentSize()
    }
    
    
    func getHeightByChildNo(child_no: String) -> String {
        var height: String = "0"
        
        do {
            let db = try SQLite()
            let sql: String = "SELECT `height` FROM `height` WHERE `child_no`=" + child_no + " ORDER BY `no` DESC LIMIT 0, 1;"
            
            try db.install(query: sql)
            try db.execute() { stmt in
                height = String(cString: sqlite3_column_text(stmt, 0))
            }
        } catch { print(error) }
        
        return height
    }
    
    func getWeightByChildNo(child_no: String) -> String {
        var weight: String = "0"
        
        do {
            let db = try SQLite()
            let sql: String = "SELECT `weight` FROM `weight` WHERE `child_no`=" + child_no + " ORDER BY `no` DESC LIMIT 0, 1;"
            
            try db.install(query: sql)
            try db.execute() { stmt in
                weight = String(cString: sqlite3_column_text(stmt, 0))
            }
        } catch { print(error) }

        return weight
    }


    func generateChildCard(remote_no: String, name: String, gender: String, birth: String, height: String, weight: String) -> UIView {
        let cardView = UIView(frame: CGRect(x: Constants.cardMargin, y: self.getScrollViewContentHeight(), width: ContentCardsViewController.Constants.screenWidth - Constants.cardMargin - Constants.cardMargin, height: Constants.cardHeight))
        cardView.clipsToBounds = false
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = Constants.cardShadowOpacity
        cardView.layer.shadowOffset = Constants.cardShadowOffset
        cardView.layer.shadowRadius = Constants.cardShadowRadius
        cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.bounds, cornerRadius: Constants.cardRadius).cgPath
        
        let card = UIView(frame: CGRect(x: 0, y: 0, width: ContentCardsViewController.Constants.screenWidth - Constants.cardMargin - Constants.cardMargin, height: Constants.cardHeight))
        card.backgroundColor = UIColor.white
        card.clipsToBounds = true
        card.layer.cornerRadius = Constants.cardRadius
        
        let lbRemoteNo: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        lbRemoteNo.text = remote_no
        lbRemoteNo.isHidden = true
        card.addSubview(lbRemoteNo)

        var descriptor: UIFontDescriptor!
        
        let lbLogo: UILabel = UILabel(frame: CGRect(x: Constants.cardMargin, y: Constants.cardMargin, width: Constants.cardLogoWidth, height: Constants.cardLogoHeight))
        lbLogo.text = "INTERNCARD"
        lbLogo.font = UIFont(name: "SteelfishRg-Regular", size: 48.0)
        lbLogo.textAlignment = .left
        card.addSubview(lbLogo)
        
        let lbName: UILabel = UILabel(frame: CGRect(x: Constants.cardMargin, y: Constants.cardNameOffset, width: Constants.cardNameWidth, height: Constants.cardNameHeight))
        lbName.text = name
        descriptor = UIFontDescriptor(name: "Noto Sans CJK KR", size: 24.0)
        descriptor = descriptor.addingAttributes([UIFontDescriptor.AttributeName.traits : [UIFontDescriptor.TraitKey.weight : UIFont.Weight.bold]])
        lbName.font = UIFont(descriptor: descriptor, size: 24.0)
        lbName.textAlignment = .left
        lbName.textColor = .gray
        card.addSubview(lbName)
        
        let lbBirth: UILabel = UILabel(frame: CGRect(x: Constants.cardMargin, y: Constants.cardBirthOffset, width: Constants.cardBirthWidth, height: Constants.cardBirthHeight))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-M-d"
        guard let date = dateFormatter.date(from: birth)else {
            fatalError("ERROR: Date conversion failed due to mismatched format.")
        }
        dateFormatter.dateFormat = "yyyy.MM"
        lbBirth.text = dateFormatter.string(from: date)
        descriptor = UIFontDescriptor(name: "Dinreg", size: 24.0)
        lbBirth.font = UIFont(descriptor: descriptor, size: 24.0)
        lbBirth.textAlignment = .left
        lbBirth.textColor = .gray
        card.addSubview(lbBirth)
        
        let lbHeightWeight = UILabel(frame: CGRect(x: Constants.cardMargin, y: Constants.cardHeightWeightOffset, width: Constants.cardHeightWeightWidth, height: Constants.cardHeightWeightHeight))
        descriptor = UIFontDescriptor(name: "Noto Sans CJK KR", size: 16.0)
        descriptor = descriptor.addingAttributes([UIFontDescriptor.AttributeName.traits : [UIFontDescriptor.TraitKey.weight : UIFont.Weight.bold]])
        lbHeightWeight.font = UIFont(descriptor: descriptor, size: 16.0)
        lbHeightWeight.text = height + "cm / " + weight + "kg"
        lbHeightWeight.textAlignment = .left
        lbHeightWeight.textColor = .gray
        card.addSubview(lbHeightWeight)
        
        let lbDetected: UILabel = UILabel(frame: CGRect(x: Constants.cardMargin, y: Constants.cardDetectedOffset, width: Constants.cardDetectedWidth, height: Constants.cardDetectedHeight))
        descriptor = UIFontDescriptor(name: "Noto Sans CJK KR", size: 12.0)
        descriptor = descriptor.addingAttributes([UIFontDescriptor.AttributeName.traits : [UIFontDescriptor.TraitKey.weight : UIFont.Weight.bold]])
        lbDetected.font = UIFont(descriptor: descriptor, size: 12.0)
        lbDetected.text = "2시간 동안 보호자 미감지"
        lbDetected.textColor = .red
        card.addSubview(lbDetected)
        
        let photoView: UIImageView! = UIImageView(image: UIImage(named: "card_empty_photo"))
        photoView.frame = CGRect(x: Constants.cardPhotoOffsetX, y: Constants.cardMargin, width: Constants.cardPhotoWidth, height: Constants.cardPhotoHeight)
        photoView.contentMode = .scaleAspectFit
        photoView.layer.cornerRadius = Constants.cardShadowRadius
        card.addSubview(photoView)

        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.clickChildCard (_:)))
        card.addGestureRecognizer(gesture)

        cardView.addSubview(card)
        
        return cardView
    }
    
    @objc func clickChildCard(_ sender:UITapGestureRecognizer) {
        let lbRemoteNo:UILabel = sender.view?.subviews[0] as! UILabel
        ActivityViewController.remote_no = lbRemoteNo.text!
        let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbActivity") as! ActivityViewController
        self.present(nextViewController, animated: true, completion: nil)
    }

    func generateAddChildCard() -> UIView {
        let cardView = UIView(frame: CGRect(x: Constants.cardMargin, y: self.getScrollViewContentHeight(), width: ContentCardsViewController.Constants.screenWidth - Constants.cardMargin - Constants.cardMargin, height: Constants.cardHeight))
        cardView.clipsToBounds = false
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = Constants.cardShadowOpacity
        cardView.layer.shadowOffset = Constants.cardShadowOffset
        cardView.layer.shadowRadius = Constants.cardShadowRadius
        cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.bounds, cornerRadius: Constants.cardRadius).cgPath
        
        let card = UIView(frame: CGRect(x: 0, y: 0, width: ContentCardsViewController.Constants.screenWidth - Constants.cardMargin - Constants.cardMargin, height: Constants.cardHeight))
        card.backgroundColor = UIColor.white
        card.clipsToBounds = true
        card.layer.cornerRadius = Constants.cardRadius
        
        let addChildImage = UIImage(named: "add_child_card")
        let addChildButton: UIButton! = UIButton(frame: CGRect(x: Constants.cardWidth/2 - Constants.addChildButtonWidth/2, y: Constants.cardHeight/2 - Constants.addChildButtonHeight/2, width: Constants.addChildButtonWidth, height: Constants.addChildButtonHeight))
        addChildButton.setImage(addChildImage, for: .normal)
        addChildButton.addTarget(self, action: #selector(clickAddChildCard), for: .touchUpInside)
        card.addSubview(addChildButton)
        
        cardView.addSubview(card)
        
        return cardView
    }

    
    func updateScrollViewContentSize() {
        var contentRect = CGRect.zero
        
        for view in self.scrollView.subviews {
            contentRect = contentRect.union(view.frame)
        }
        
        contentRect.size.height = contentRect.size.height + Constants.cardMargin
        
        self.scrollView.contentSize = contentRect.size
    }
    
    func getScrollViewContentHeight() -> CGFloat {
        return Constants.cardMargin + (Constants.cardHeight + Constants.cardMargin) * CGFloat(self.cardViews.count)
    }

    
    @objc func clickAddChildCard(sender: UIButton!) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbAddChildForm") as! AddChildFormViewController
        self.present(nextViewController, animated: true, completion: nil)
        
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
