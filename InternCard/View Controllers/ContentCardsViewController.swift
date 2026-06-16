//
//  ViewController.swift
//  InternCard
//
//  Created by idl on 2018. 6. 15..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import UIKit
import Firebase


class ContentCardsViewController: UIViewController, UIScrollViewDelegate {
    
    struct Constants {
        
        static var initialize                        : Bool = true
        static var swipeout                          : Bool = false
        
        static var childCardAdded                    : Bool = false
        static var signInTriedButCaceled             : Bool = false

        // screen
        static var screenWidth                       : CGFloat = UIScreen.main.bounds.width
        static var screenHeight                      : CGFloat = UIScreen.main.bounds.height
        
        // header
        static let headerHeight                      : CGFloat = 42
        static let statusBarHeight                   : CGFloat = 20 //UIApplication.shared.statusBarFrame.height

        // card
        static let cardMargin                        : CGFloat = 9
        static let cardRadius                        : CGFloat = 9
        static let cardImageHeight                   : CGFloat = 240
        static let cardHeight                        : CGFloat  = cardImageHeight + 96
        static let cardShadowOpacity                 : Float = 0.36
        static let cardShadowOffset                  : CGSize = CGSize.zero //CGSize(width: 0, height: 4)
        static let cardShadowRadius                  : CGFloat = 2
        
        // intern weather
        static let cardAnswerHeight                  : CGFloat = 60 + cardMargin + cardMargin
        
        static let cardTextMargin                    : CGFloat = 12
        
        static let cardWeatherTitleOffset            : CGFloat = 24
        static let cardWeatherTitleHeight            : CGFloat = 36
        static let cardWeatherTitleSize              : CGFloat = 32.0
        
        static let cardWeatherDateOffset             : CGFloat = 64
        static let cardWeatherDateHeight             : CGFloat = 40
        static let cardWeatherDateSize               : CGFloat = 24.0
        
        static let cardAdaptiveContentCategoryOffset : CGFloat = 8
        static let cardAdaptiveContentCategoryHeight : CGFloat = 20
        static let cardAdaptiveContentCategorySize   : CGFloat = 12.0

        static let cardAdaptiveContentTitleOffset    : CGFloat = 28
        static let cardAdaptiveContentTitleHeight    : CGFloat = 56
        static let cardAdaptiveContentTitleSize      : CGFloat = 16.0

        static let cardAdaptiveContentSubTextOffset  : CGFloat = 56
        static let cardAdaptiveContentSubTextHeight  : CGFloat = 40
        static let cardAdaptiveContentSubTextSize    : CGFloat = 12.0

        // Types of tasks
        static let SET_INITIAL_CARD                  : Int = 0  // 실행 초기에 N개의 카드를 업데이트한다.
        static let APPEND_CARD_to_BOTTOM             : Int = 1  // BOTTOM에 N개의 카드를 추가한다.
        static let APPEND_CARD_to_TOP                : Int = 2  // TOP에 N개의 카드를 추가한다.
    }
    
    var scrollView: UIScrollView!
    var cardViews: [UIView] = []
    var minRemoteNo: Int64 = 0
    var maxRemoteNo: Int64 = 0
    struct AC_UNIT {
        var no: String!
        var title: String!
        var url: String!
        var categories: String!
        var image_url: String!
        var encodedImageData: String!
        var time: String!
    }

    var usageView: UIView!
    var usageImageView: UIImageView!
    

    var tasks: Queue<Int>!
    var task_dg: DispatchGroup!
    


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Constants.initialize {
            self.initializeSession()
            Constants.initialize = false
        }
        
        if Constants.swipeout {
            self.swipeOut()
            Constants.swipeout = false
        }

        scrollView = UIScrollView(frame: CGRect(x: 0, y: Constants.headerHeight + Constants.statusBarHeight, width: Constants.screenWidth, height: Constants.screenHeight - Constants.headerHeight - Constants.statusBarHeight))
        self.scrollView.delegate = self
        self.view.addSubview(scrollView)

        let headerView: UIView! = UIView(frame: CGRect(x: 0, y: 0, width: Constants.screenWidth, height: Constants.statusBarHeight + Constants.headerHeight))
        headerView.backgroundColor = UIColor(white: 1, alpha: 1)
        headerView.clipsToBounds = false
        headerView.layer.shadowColor = UIColor.black.cgColor
        headerView.layer.shadowOpacity = 0.2
        headerView.layer.shadowOffset = CGSize.zero
        headerView.layer.shadowRadius = 1
        headerView.layer.shadowPath = UIBezierPath(roundedRect: headerView.bounds, cornerRadius:1).cgPath
        self.view.addSubview(headerView)
        
        let labelLogo: UILabel = UILabel(frame: CGRect(x: 0, y: Constants.statusBarHeight, width: Constants.screenWidth, height: Constants.headerHeight))
        labelLogo.text = "INTERNCARD"
        labelLogo.font = UIFont(name: "SteelfishRg-Regular", size: 24.0)
        labelLogo.textAlignment = .center
        self.view.addSubview(labelLogo)

        let cf = config()
        cf.key = "usage"
        cf.select_by_key()
        
        if cf.value == "0" {
            self.usageView = UIView(frame: self.view.bounds)
            self.usageView.frame = CGRect(x: 0, y: 0, width: Constants.screenWidth, height: Constants.screenHeight)
            self.usageView.backgroundColor = UIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 0.86)
            self.view.addSubview(self.usageView)
            
            let usageImage = UIImage(named: "usage")
            self.usageImageView = UIImageView(image: usageImage!)
            self.usageImageView.frame = CGRect(x: Constants.screenWidth / 2 - 120, y: Constants.screenHeight / 2 - 130, width: 240, height: 257.5)
            self.usageView.addSubview(self.usageImageView)
            
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ContentCardsViewController.closeUsageView))
            self.view.addGestureRecognizer(tap)
        }
        
        self.task_dg = DispatchGroup()
        tasks = Queue<Int>()
        DispatchQueue.global(qos:.userInteractive).async { self.run() }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        search_top_and_bottom()
    }
    
    func search_top_and_bottom() {
        //print(scrollView.subviews.count)
        if scrollView.subviews.count < 4 {
            tasks.enqueue(Constants.SET_INITIAL_CARD)
            tasks.enqueue(Constants.APPEND_CARD_to_BOTTOM)
        }
    }
    
    var update_flag: Bool = false
    
    func run() {
        while true {
            
            self.task_dg.wait()
            self.task_dg.enter()

            if !tasks.isEmpty {
                
                switch tasks.dequeue() {
                    
                case Constants.SET_INITIAL_CARD:
                    setInitialCard()
                    break;
                    
                case Constants.APPEND_CARD_to_BOTTOM:
                    for _:Int64 in 1...8 {
                        appendCardToBottom(target_no: self.minRemoteNo - 1)
                    }
                    break;
                    
                case Constants.APPEND_CARD_to_TOP:
                    break;
                    
                default:
                    break;
                }
            }

            self.task_dg.leave()

            usleep(250000)
        }
    }
    
    
    func setInitialCard() {
        
//        print("scrollView.subviews.count: " + String(scrollView.subviews.count))
//        let cardViews = scrollView.subviews.filter{$0 is UIView}
//        print("cardViews.count: " + String(cardViews.count))
//        for v in cardViews {
//            v.removeFromSuperview()
//        }
        
        
        // Session
        let defaultSession = URLSession(configuration: .default)
        
        guard let url = URL(string: "http://internkid.com/intern_weather_24.api.php") else {
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
                
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject] else {
                    print("json to Any Error")
                    dg0.leave()
                    return
                }
                
                //let no = json["no"] as? String
                let total_tears: Double = Double(json["total_tears"] as! String)!
                let user_count: Double = Double(json["user_count"] as! String)!
                //let time = json["time"] as? String
                

                let dg1: DispatchGroup! = DispatchGroup()
                dg1.enter()
                DispatchQueue.main.async() {
                    
                    let cardView = self.generateWeatherCard(total_tears, user_count)
                    self.cardViews.append(cardView)
                    self.scrollView.addSubview(cardView)
                    self.updateScrollViewContentSize()
                    dg1.leave()
                    
                }
                dg1.wait()
            }
            dg0.leave()
        }
        dataTask.resume()
        dg0.wait()
        
        
        // adaptive content
        self.minRemoteNo = getLastRemoteNo()
        self.maxRemoteNo = self.minRemoteNo
        appendCardToBottom(target_no: self.minRemoteNo)
    }
    
    func generateWeatherCard(_ total_tears: Double, _ user_count: Double) -> UIView {

        let cardView = UIView(frame: CGRect(x: Constants.cardMargin, y: self.getScrollViewContentHeight(), width: Constants.screenWidth - Constants.cardMargin - Constants.cardMargin, height: Constants.cardHeight))
        cardView.clipsToBounds = false
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = Constants.cardShadowOpacity
        cardView.layer.shadowOffset = Constants.cardShadowOffset
        cardView.layer.shadowRadius = Constants.cardShadowRadius
        cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.bounds, cornerRadius: Constants.cardRadius).cgPath

        /*
        // 일단 `intern_weather`에서 오늘 날짜의 데이터가 있는지 확인합니다.
        // 하루를 넘기는 기준은 새벽 4시로 일단 정합니다. (다음에 고칠 수 있도록 해두기)
        let iw = intern_weather()
        let start: TimeInterval = iw.getStartTime(date: Date())
        //let end: TimeInterval = start + 86400.0
        
        iw.select_last()
        if iw.time == "" || Double(iw.time)! < start {
            
            let card = UIView(frame: CGRect(x: 0, y: 0, width: cardView.bounds.width, height: cardView.bounds.height))
            card.backgroundColor = UIColor.red // 0xF0F0F0
            card.clipsToBounds = true
            card.layer.cornerRadius = Constants.cardRadius

            
            let answer0View = UIView(frame: CGRect(x: Constants.cardMargin, y: Constants.cardMargin, width: Constants.screenWidth - (4 * Constants.cardMargin), height: Constants.cardAnswerHeight))
            answer0View.clipsToBounds = false
            answer0View.layer.shadowColor = UIColor.black.cgColor
            answer0View.layer.shadowOpacity = Constants.cardShadowOpacity
            answer0View.layer.shadowOffset = Constants.cardShadowOffset
            answer0View.layer.shadowRadius = Constants.cardShadowRadius
            answer0View.layer.shadowPath = UIBezierPath(roundedRect: answer0View.bounds, cornerRadius: Constants.cardRadius).cgPath
            
            let answer0 = UIView(frame: CGRect(x: 0, y: 0, width: answer0View.bounds.width, height: answer0View.bounds.height))
            card.backgroundColor = UIColor.white
            card.clipsToBounds = true
            card.layer.cornerRadius = Constants.cardRadius


            let answer1View = UIView(frame: CGRect(x: Constants.cardMargin, y: 2 * Constants.cardMargin + Constants.cardAnswerHeight, width: Constants.screenWidth - (4 * Constants.cardMargin), height: Constants.cardAnswerHeight))
            let answer2View = UIView(frame: CGRect(x: Constants.cardMargin, y: 3 * Constants.cardMargin + 2 * Constants.cardAnswerHeight, width: Constants.screenWidth - (4 * Constants.cardMargin), height: Constants.cardAnswerHeight))
            let answer3View = UIView(frame: CGRect(x: Constants.cardMargin, y: 4 * Constants.cardMargin + 3 * Constants.cardAnswerHeight, width: Constants.screenWidth - (4 * Constants.cardMargin), height: Constants.cardAnswerHeight))
            let answer4View = UIView(frame: CGRect(x: Constants.cardMargin, y: 5 * Constants.cardMargin + 4 * Constants.cardAnswerHeight, width: Constants.screenWidth - (4 * Constants.cardMargin), height: Constants.cardAnswerHeight))

            let mom0: UIImage = UIImage(named: "mom0.png")!
            let mom1: UIImage = UIImage(named: "mom1.png")!
            let mom2: UIImage = UIImage(named: "mom2.png")!
            let mom3: UIImage = UIImage(named: "mom3.png")!
            let mom4: UIImage = UIImage(named: "mom4.png")!
            
            let mom0View: UIImageView = UIImageView(image: mom0)
            mom0View.frame = CGRect(x: Constants.cardMargin, y: Constants.cardMargin, width: 60, height: 60)
            mom0View.contentMode = .scaleAspectFill

            answer0.addSubview(mom0View)

            answer0View.addSubview(answer0)

            card.addSubview(answer0View)
            
            cardView.addSubview(card)

        } else {
        */
        var img: UIImage!
        let ratio: Double = total_tears / user_count

        if user_count <= 0.0 || ratio < 1.5 {
            //self.label(txt: "맑음")
            img = UIImage(named: "weather0.png")
        } else if ratio < 2.5 {
            //self.label(txt: "구름")
            img = UIImage(named: "weather1.png")
        } else if ratio < 3.5 {
            //self.label(txt: "보슬비")
            img = UIImage(named: "weather2.png")
        } else if ratio < 4.5 {
            //self.label(txt: "장대비")
            img = UIImage(named: "weather3.png")
        } else {
            //self.label(txt: "천둥/번개")
            img = UIImage(named: "weather4.png")
        }
    
        let imageView = UIImageView(image: img)
        imageView.frame = cardView.bounds
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Constants.cardRadius
        cardView.addSubview(imageView)
        
        let titleLabel: UILabel = UILabel(frame: CGRect(x:0, y: Constants.cardWeatherTitleOffset, width: Constants.screenWidth - 2 * Constants.cardMargin, height: Constants.cardWeatherTitleHeight))
        var descriptor = UIFontDescriptor(name: "Noto Sans CJK KR", size: Constants.cardWeatherTitleSize)
        descriptor = descriptor.addingAttributes([UIFontDescriptor.AttributeName.traits : [UIFontDescriptor.TraitKey.weight : UIFont.Weight.bold]])
        titleLabel.font = UIFont(descriptor: descriptor, size: Constants.cardWeatherTitleSize)
        titleLabel.textAlignment = .center
        titleLabel.text = "오늘의 전국 육아날씨"
        cardView.addSubview(titleLabel)
        
        let dateLabel: UILabel = UILabel(frame: CGRect(x: 0 , y: Constants.cardWeatherDateOffset, width: Constants.screenWidth - 2 * Constants.cardMargin, height: Constants.cardWeatherDateHeight))
        dateLabel.font = UIFont(name: "DIN-Medium", size: Constants.cardWeatherDateSize)
        dateLabel.textAlignment = .center
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        dateLabel.text = formatter.string(from: Date())
        cardView.addSubview(dateLabel)
        //}
        
        let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.goInternWeather(_:)))
        cardView.addGestureRecognizer(gesture)

        
        return cardView
    }
    
    @objc func goInternWeather(_ sender: UITapGestureRecognizer) {
        // handle touch down and touch up events separately
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbInternWeather") as! InternWeatherViewController
        self.present(nextViewController, animated: true, completion: nil)
        
    }

    func generateAdaptiveContentCard(no: String, title: String, url: String, categories: String, image: UIImage) -> UIView {
        let cardView = UIView(frame: CGRect(x: Constants.cardMargin, y: self.getScrollViewContentHeight(), width: Constants.screenWidth - Constants.cardMargin - Constants.cardMargin, height: Constants.cardHeight))
        cardView.clipsToBounds = false
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = Constants.cardShadowOpacity
        cardView.layer.shadowOffset = Constants.cardShadowOffset
        cardView.layer.shadowRadius = Constants.cardShadowRadius
        cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.bounds, cornerRadius: Constants.cardRadius).cgPath
        
        let lbNo: UILabel = UILabel(frame: CGRect(x: 0, y: -100, width: 0, height: 0))
        lbNo.text = no
        lbNo.isHidden = true
        cardView.addSubview(lbNo)

        let lbUrl: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        lbUrl.text = url
        lbUrl.isHidden = true
        cardView.addSubview(lbUrl)

        let card = UIView(frame: CGRect(x: 0, y: 0, width: Constants.screenWidth - Constants.cardMargin - Constants.cardMargin, height: Constants.cardHeight))
        card.backgroundColor = UIColor.white
        card.clipsToBounds = true
        card.layer.cornerRadius = Constants.cardRadius
        
        let imageView = UIImageView(image: image)
        imageView.frame = cardView.bounds
        imageView.frame.size.height = Constants.cardImageHeight
        imageView.contentMode = .scaleAspectFill
        card.addSubview(imageView)
        
        let titleView: UIView = UIView(frame: CGRect(x: 0, y: Constants.cardImageHeight, width: Constants.screenWidth - Constants.cardMargin - Constants.cardMargin, height: Constants.cardHeight - Constants.cardImageHeight))
        titleView.backgroundColor = UIColor.white
        titleView.layer.zPosition = 0.5
        
        let categoryLabel: UILabel = UILabel(frame: CGRect(x: Constants.cardTextMargin, y: Constants.cardAdaptiveContentCategoryOffset, width: Constants.screenWidth - 2 * Constants.cardMargin, height: Constants.cardAdaptiveContentCategoryHeight))
        var categoryDescriptor = UIFontDescriptor(name: "Noto Sans CJK KR", size: Constants.cardAdaptiveContentCategorySize)
        categoryDescriptor = categoryDescriptor.addingAttributes([UIFontDescriptor.AttributeName.traits : [UIFontDescriptor.TraitKey.weight : UIFont.Weight.medium]])
        categoryLabel.font = UIFont(descriptor: categoryDescriptor, size: Constants.cardAdaptiveContentCategorySize)
        categoryLabel.textColor = UIColor.lightGray
        categoryLabel.text = categories // "테라피 스튜디오"
        titleView.addSubview(categoryLabel)

        let titleLabel: UILabel = UILabel(frame: CGRect(x: Constants.cardTextMargin, y: Constants.cardAdaptiveContentTitleOffset, width: Constants.screenWidth - 2 * Constants.cardMargin - 2 * Constants.cardTextMargin, height: Constants.cardAdaptiveContentTitleHeight))
        var titleDescriptor = UIFontDescriptor(name: "Noto Sans CJK KR", size: Constants.cardAdaptiveContentTitleSize)
        titleDescriptor = titleDescriptor.addingAttributes([UIFontDescriptor.AttributeName.traits : [UIFontDescriptor.TraitKey.weight : UIFont.Weight.medium]])
        titleLabel.font = UIFont(descriptor: titleDescriptor, size: Constants.cardAdaptiveContentTitleSize)

        let attrString = NSMutableAttributedString(string: title) // "신체 발달을 위한 어린이 마사지"
        //let style = NSMutableParagraphStyle()
        //style.lineSpacing = 24 // change line spacing between paragraph like 36 or 48
        //style.minimumLineHeight = 20 // change line spacing between each line like 30 or 40
        //attrString.addAttribute(NSAttributedStringKey.paragraphStyle, value: style, range: NSRange(location: 0, length: stringValue.count))
        //attrString.addAttribute(NSAttributedStringKey.strikethroughStyle, value: 2, range: NSMakeRange(0, attrString.length))
        attrString.addAttribute(NSAttributedString.Key.kern, value: -1, range: NSMakeRange(0, attrString.length))
        titleLabel.attributedText = attrString
        
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 2
        titleLabel.sizeToFit()
        titleView.addSubview(titleLabel)

        let subtext: UILabel = UILabel(frame: CGRect(x: Constants.cardTextMargin, y: Constants.cardAdaptiveContentSubTextOffset, width: Constants.screenWidth - 2 * Constants.cardMargin - 2 * Constants.cardTextMargin, height: Constants.cardAdaptiveContentSubTextHeight))
        var subtextDescriptor = UIFontDescriptor(name: "Noto Sans CJK KR", size: Constants.cardAdaptiveContentSubTextSize)
        subtextDescriptor = subtextDescriptor.addingAttributes([UIFontDescriptor.AttributeName.traits : [UIFontDescriptor.TraitKey.weight : UIFont.Weight.light]])
        subtext.font = UIFont(descriptor: titleDescriptor, size: Constants.cardAdaptiveContentSubTextSize)
        subtext.textColor = UIColor.gray
        subtext.text = " 물리치료 마사지, 성장 마사지, 근육 이완 마사지"
        
        //titleView.addSubview(subtext)

        card.addSubview(titleView)

        cardView.addSubview(card)
        
        return cardView
    }

    
    func appendCardToBottom(target_no: Int64)
    {
        if target_no <= 0 { return }

        //var flag: Bool = false
        
        /*
        // 1. check local DB if there is a previously downloaded one
        let ac = adaptive_content()
        ac.remote_no = String(target_no)
        flag = ac.select_by_remote_no() { ()->() in
            self.minRemoteNo = Int64(ac.remote_no)!
            
            let dg2: DispatchGroup! = DispatchGroup()
            dg2.enter()
            DispatchQueue.main.async() {
                
                let opt: NSData.Base64DecodingOptions! = NSData.Base64DecodingOptions(rawValue: 1)
                let decodedImageData:NSData = NSData(base64Encoded: ac.image, options: opt!)!
                let decodedImage:UIImage = UIImage(data: decodedImageData as Data)!
                
         let cardView = self.generateAdaptiveContentCard(no: ac.no, title: ac.title, url: ac.url, image: decodedImage)
                
                let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.goUrl(_:)))
                cardView.addGestureRecognizer(gesture)
                
                self.cardViews.append(cardView)
                self.scrollView.addSubview(cardView)
                self.updateScrollViewContentSize()
                
                dg2.leave()
            }
            dg2.wait()

        }
        */
        
        // 2. unless it exists, check remote DB
        //if !flag {
            // Session
            let defaultSession = URLSession(configuration: .default)
            
            var str_url: String = "http://internkid.com/adaptive_content.api.php?no=" + String(target_no)
            
            let u = user()
            if u.select_last() {
                str_url = str_url + "&user_no=" + u.remote_no
            }
        
            // 알람
//            let alertController = UIAlertController(title: "URL", message: str_url, preferredStyle: .alert)
//            let okAction = UIAlertAction(title: "OK", style: .default)
//            alertController.addAction(okAction)
//            self.present(alertController, animated: true, completion: nil)

            
            guard let url = URL(string: str_url) else {
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
                    
                    var unit: AC_UNIT! = AC_UNIT()
                    unit.no = json[0]["no"] as? String
                    unit.title = json[0]["title"] as? String
                    unit.url = json[0]["url"] as? String
                    unit.categories = json[0]["categories"] as? String
                    unit.image_url = json[0]["image_url"] as? String
                    unit.time = json[0]["time"] as? String
                    let image: UIImage! = UIImage(data: Data(base64Encoded: (json[0]["image_data"] as? String)!)!)
                    
                    /*
                    // download a image
                    if (unit.image_url == "") {
                        let pngData: NSData! = UIImage(named: "no_image.png")!.pngData()! as NSData
                        unit.encodedImageData = pngData.base64EncodedString(options: .lineLength64Characters)
                    } else {
                        let imageDefaultSession = URLSession(configuration: .default)
                        let imageRequest = URLRequest(url: URL(string: unit.image_url)!)
                        
                        let dg1: DispatchGroup! = DispatchGroup()
                        dg1.enter()
                        let imageDataTask = imageDefaultSession.dataTask(with: imageRequest) { imageData, imageResponse, imageError in
                            guard imageError == nil else {
                                print("Error occur: \(String(describing: imageError))")
                                dg1.leave()
                                return
                            }
                            
                            if let imageData = imageData, let imageResponse = imageResponse as? HTTPURLResponse, imageResponse.statusCode == 200 {
                                if imageResponse.mimeType?.hasPrefix("image") == true {
                                    image = UIImage(data: imageData)
                                    let jpegData: NSData! = image!.jpegData(compressionQuality: 1.0)! as NSData
                                    unit.encodedImageData = jpegData.base64EncodedString(options: .lineLength64Characters)
                                } else {
                                    image = UIImage(named: "no_image.png")
                                    let pngData: NSData! = image!.pngData()! as NSData
                                    unit.encodedImageData = pngData.base64EncodedString(options: .lineLength64Characters)
                                }
                            }
                            
                            dg1.leave()
                        }
                        imageDataTask.resume()
                        dg1.wait()
                    }
                    */

                    /*
                    // insert into local DB
                    do {
                        let db = try SQLite()
                        let sql: String = "INSERT INTO `adaptive_content`(`remote_no`, `title`, `url`, `image`, `time`) VALUES ('" + unit.no! + "', '" + (unit.title!).replacingOccurrences(of: "'", with: "''") + "', '" + unit.url! + "', '" + unit.encodedImageData! + "', '" + unit.time! + "');"
                        print(unit.no)
                        try db.install(query: sql)
                        try db.execute()
                    } catch {
                        print(error)
                    }
                    */
                    

                    if image != nil
                    {
                        // updates UIs
                        let dg1: DispatchGroup! = DispatchGroup()
                        dg1.enter()
                        DispatchQueue.main.async() {
                            // add to scrollView
                            let cardView = self.generateAdaptiveContentCard(no: unit.no, title: unit.title, url: unit.url, categories: unit.categories, image: image)

                            let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.goUrl(_:)))
                            cardView.addGestureRecognizer(gesture)
                            
                            self.cardViews.append(cardView)
                            
                            self.scrollView.addSubview(cardView)
                            
                            self.update_flag = true

                            dg1.leave()
                        }
                        dg1.wait()
                    }
                    
                    self.minRemoteNo = Int64(unit.no)!
                }
                
                dg0.leave()
            }
            dataTask.resume()
            dg0.wait()

        //}
    }
    
    
    func getLastRemoteNo() -> Int64 {
        
        var ret: Int64! = 0
        
        // Session
        let defaultSession = URLSession(configuration: .default)
        
        guard let url = URL(string: "http://internkid.com/adaptive_content.api.php?offset=0&count=1") else {
            print("URL is nil")
            return 0
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
                ret = Int64(json[0]["no"] as! String)
            }
            
            dg0.leave()
        }
        dataTask.resume()
        dg0.wait()
        
        return ret
    }
    
    
    //Calls this function when the tap is recognized.
    @objc func closeUsageView() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        usageView.removeFromSuperview()
        
        // usage를 봤으므로 다음에는 생략할 수 있도록 `config` 테이블을 만들고 그중에 한 필드를 `usage`로 해서 기록. 1이 봄. 0이 안봄.
        let cf = config()
        cf.key = "usage"
        cf.value = "1"
        cf.update()
    }
    

    @objc func goUrl(_ sender: UITapGestureRecognizer) {
        // handle touch down and touch up events separately
        //let labels: [UIView]! = sender.view!.subviews
        //let labels: [UILabel]! = sender.view?.subviews[0].subviews.compactMap { $0 as? UILabel }
        let lbUrl: UILabel = sender.view?.subviews[0] as! UILabel
        ExternalWebViewController.url = lbUrl.text
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbExternalWeb") as! ExternalWebViewController
        self.present(nextViewController, animated: true, completion: nil)
    }

    private var lastContentOffset: CGFloat = 0
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollViewHeight = scrollView.frame.size.height
        let scrollContentSizeHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        
        if scrollOffset <= 0 {
            //print("we are at the top")
            // make new thread to get latest adaptive contents from server
        } else

        if (scrollOffset + scrollViewHeight) > (scrollContentSizeHeight - 8 * Constants.cardHeight) {
            // make new thread to get previous adaptive contents from server
            //self.task_dg.wait()
            self.task_dg.enter()
            if self.tasks.count == 0 {
                tasks.enqueue(Constants.APPEND_CARD_to_BOTTOM)
                print("we are at the bottom")
            }
            self.task_dg.leave()
        }
        
        if scrollOffset > 0 && self.lastContentOffset < scrollView.contentOffset.y {
            // move down
            self.task_dg.enter()
            if self.update_flag {
                self.updateScrollViewContentSize()
                self.update_flag = false
            }
            self.task_dg.leave()
        }
        
        self.lastContentOffset = scrollView.contentOffset.y
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    
    func initializeSession() {
        
        // `config` table
        let cf = config()
        if !(SQLite.isTableExist(table: "config")) {
            do { try Auth.auth().signOut() } catch { }
            cf.create()
            cf.key = "usage"
            cf.value = "0"
            cf.insert()
        }
        
        // `user` table
        let u = user()
        if !(SQLite.isTableExist(table: "user")) {
            u.create()
        }
        
        // `intern_weather` table
        let iw = intern_weather()
        if !(SQLite.isTableExist(table: "intern_weather")) {
            iw.create()
        }
        
        // `child` table
        let c = child()
        if !(SQLite.isTableExist(table: "child")) {
            c.create()
        }
        
        // `height` table
        let h = height()
        if !(SQLite.isTableExist(table: "height")) {
            h.create()
        }
        
        // `weight` table
        let w = weight()
        if !(SQLite.isTableExist(table: "weight")) {
            w.create()
        }
        
        // `caron_device` table
        let cd = caron_device()
        if !(SQLite.isTableExist(table: "caron_device")) {
            cd.create()
        }
        
        // `activity_per_hour` table
        let aph = activity_per_hour()
        if !(SQLite.isTableExist(table: "activity_per_hour")) {
            aph.create()
        }
        
        // `activity_per_day` table
        let apd = activity_per_day()
        if !(SQLite.isTableExist(table: "activity_per_day")) {
            apd.create()
        }
    }
    
    func swipeOut() {
        
        do { try Auth.auth().signOut() } catch { }
        
        // `config` table
        let cf = config()
        if (SQLite.isTableExist(table: "config")) {
            cf.drop()
        }
        cf.create()
        cf.key = "usage"
        cf.value = "0"
        cf.insert()
        
        // `user` table
        let u = user()
        if (SQLite.isTableExist(table: "user")) {
            u.drop()
        }
        u.create()
        
        // `intern_weather` table
        let iw = intern_weather()
        if (SQLite.isTableExist(table: "intern_weather")) {
            iw.drop()
        }
        iw.create()
        
        // `child` table
        let c = child()
        if (SQLite.isTableExist(table: "child")) {
            c.drop()
        }
        c.create()
        
        // `height` table
        let h = height()
        if (SQLite.isTableExist(table: "height")) {
            h.drop()
        }
        h.create()
        
        // `weight` table
        let w = weight()
        if (SQLite.isTableExist(table: "weight")) {
            w.drop()
        }
        w.create()
        
        // `caron_device` table
        let cd = caron_device()
        if (SQLite.isTableExist(table: "caron_device")) {
            cd.drop()
        }
        cd.create()
        
        // `activity_per_hour` table
        let aph = activity_per_hour()
        if (SQLite.isTableExist(table: "activity_per_hour")) {
            aph.drop()
        }
        aph.create()
        
        // `activity_per_day` table
        let apd = activity_per_day()
        if (SQLite.isTableExist(table: "activity_per_day")) {
            apd.drop()
        }
        apd.create()
    }
}

