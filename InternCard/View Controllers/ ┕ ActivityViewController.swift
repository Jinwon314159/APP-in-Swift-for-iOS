//
//  ActivityViewController.swift
//  InternCard
//
//  Created by idl on 2018. 10. 29..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import UIKit
import Charts

class ActivityViewController: UIViewController {
    
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
        
        static let btnCaronAdd                       : Int = 0 // 0: caron 추가, 1: caron 동기화
        static let btnCaronSync                      : Int = 1 // 0: caron 추가, 1: caron 동기화
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var lbNameGender: UILabel!
    @IBOutlet weak var lbBirthYear: UILabel!
    @IBOutlet weak var lbBirthMonth: UILabel!
    @IBOutlet weak var lbHeight: UILabel!
    @IBOutlet weak var lbWeight: UILabel!
    
    @IBOutlet weak var graphActivityDuration: UIView!
    @IBOutlet weak var graphActivityTotal: UIView!
    
    @IBOutlet weak var btnSync: UIButton!
    @IBOutlet weak var btnUnlink: UIButton!
    
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
        
        let btnBack: UIButton! = UIButton(type: .custom)
        btnBack.setImage(UIImage(named: "back.png"), for: .normal)
        btnBack.frame = CGRect(x: 0, y: ContentCardsViewController.Constants.statusBarHeight, width: ContentCardsViewController.Constants.headerHeight, height: ContentCardsViewController.Constants.headerHeight)
        btnBack.addTarget(self, action: #selector(clickBackButton(_:)), for: .touchUpInside)
        self.view.addSubview(btnBack)

        let margin: CGFloat = 8
        let w: CGFloat = ContentCardsViewController.Constants.headerHeight - 2.0 * margin;
        let h: CGFloat = ContentCardsViewController.Constants.headerHeight - 2.0 * margin;
        let btnEdit: UIButton = UIButton(type: .custom)
        btnEdit.setImage(UIImage(named: "edit.png"), for: .normal)
        btnEdit.frame = CGRect(x: ContentCardsViewController.Constants.screenWidth - w - 2.0 * margin, y:ContentCardsViewController.Constants.statusBarHeight + margin, width: w, height: h)
        btnEdit.addTarget(self, action: #selector(clickEditButton(_:)), for: .touchUpInside)
        self.view.addSubview(btnEdit)

        let offset: CGFloat = ContentCardsViewController.Constants.statusBarHeight + ContentCardsViewController.Constants.headerHeight
        scrollView.frame = CGRect(x: 0, y: offset, width: ContentCardsViewController.Constants.screenWidth, height: ContentCardsViewController.Constants.screenHeight - offset)
        scrollView.contentSize.height = ContentCardsViewController.Constants.screenHeight + 48 // - ContentCardsViewController.Constants.headerHeight
        
        self.loadChild()
        self.generateDurationCard()
        self.generateDailyTotalCard()
    }

    @objc func clickBackButton(_ sender: AnyObject?)
    {
        ContentCardsViewController.Constants.childCardAdded = true
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbMain") as! PageViewController
        self.present(nextViewController, animated: false, completion: nil)
    }

    @objc func clickEditButton(_ sender: AnyObject?)
    {
        ChildViewController.remote_no = ActivityViewController.remote_no

        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbChild") as! ChildViewController
        self.present(nextViewController, animated: true, completion: nil)
    }
    
    @IBAction func clickSyncButton(_ sender: UIButton) {
        if self.checkCaron() {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbCaronSync") as! CaronSyncViewController
            self.present(nextViewController, animated: true, completion: nil)
        } else {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "sbCaronSearch") as! CaronSearchViewController
            self.present(nextViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func clickUnlinkButton(_ sender: UIButton) {
    }
    
    // 아이에게 카롱 디바이스가 할당되어 있는지 체크하고 변수를 설정
    func checkCaron() -> Bool {
        let cd = caron_device()
        cd.child_no = ActivityViewController.remote_no
        
        let found: Bool = cd.select_by_child_no()
        if found {
            CaronSyncViewController.child_no = ActivityViewController.remote_no
            CaronSyncViewController.mac_address = cd.mac_address
            CaronSyncViewController.serial_number = cd.serial_number
        } else {
            CaronSearchViewController.child_no = ActivityViewController.remote_no
        }
        
        return found
    }
    
    func loadChild()
    {
        let c = child()
        c.remote_no = ActivityViewController.remote_no
        c.select_by_remote_no()
        
        let h = height()
        h.child_no = ActivityViewController.remote_no
        h.select_by_child_no()
        
        let w = weight()
        w.child_no = ActivityViewController.remote_no
        w.select_by_child_no()
        
        self.lbNameGender.text = c.name
        if c.gender == "M" {
            self.lbNameGender.text = self.lbNameGender.text! + " (남)"
        } else {
            self.lbNameGender.text = self.lbNameGender.text! + " (여)"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: c.birth)
        dateFormatter.dateFormat = "yyyy";
        self.lbBirthYear.text = dateFormatter.string(from: date!)
        dateFormatter.dateFormat = "M";
        self.lbBirthMonth.text = dateFormatter.string(from: date!)
        
        self.lbHeight.text =  h.height
        self.lbWeight.text = w.weight
    }
    
    func generateDurationCard() {
        
        let card = BarChartView(frame: CGRect(x: 0, y: 0, width: self.graphActivityDuration.frame.width, height: self.graphActivityDuration.frame.height))
        //card.backgroundColor = UIColor.white
        
        self.graphActivityDuration.addSubview(card)
        
        let today: Date = Date()
        let start = getStartTime(from: today)
        
        var action1Entry = [BarChartDataEntry]()
        var action2Entry = [BarChartDataEntry]()
        var action3Entry = [BarChartDataEntry]()
        var dataSet: BarChartDataSet
        var dataSets = [BarChartDataSet]()
        
        let xAxisValueFormatter = DayValueFormatter()
        card.xAxis.valueFormatter = xAxisValueFormatter
        card.xAxis.labelPosition = .bottom
        card.xAxis.drawGridLinesEnabled = false

        for i in (0..<7)
        {
            xAxisValueFormatter.label_x[i] = start + (Double(i) * 86400.0)
            
            // ChildViewController.label_x[i]의 시간에 해당하는 데이터를 activity_per_day에서 가져온다.
            let apd = activity_per_day()
            apd.child_no = ActivityViewController.remote_no
            let intensity_summary: [String:Int64]? = apd.get_summary_by_start(xAxisValueFormatter.label_x[i])
            if intensity_summary != nil {
                action3Entry.append(BarChartDataEntry(x: Double(i) - 0.2, y: Double(intensity_summary!["Action3"]!) / 60.0))
                action2Entry.append(BarChartDataEntry(x: Double(i)      , y: Double(intensity_summary!["Action2"]!) / 60.0))
                action1Entry.append(BarChartDataEntry(x: Double(i) + 0.2, y: Double(intensity_summary!["Action1"]!) / 60.0))
            } else {
                action3Entry.append(BarChartDataEntry(x: Double(i) - 0.2, y: 0.0))
                action2Entry.append(BarChartDataEntry(x: Double(i)      , y: 0.0))
                action1Entry.append(BarChartDataEntry(x: Double(i) + 0.2, y: 0.0))
            }
        }
        
        dataSet = BarChartDataSet(values: action3Entry, label: "Action3")
        dataSet.setColors(UIColor(rgb: 0xFF8D8C))
        dataSet.drawValuesEnabled = false
        dataSets.append(dataSet)
        
        dataSet = BarChartDataSet(values: action2Entry, label: "Action2")
        dataSet.setColors(UIColor(rgb: 0xEEB24B))
        dataSet.drawValuesEnabled = false
        dataSets.append(dataSet)
        
        dataSet = BarChartDataSet(values: action1Entry, label: "Action1")
        dataSet.setColors(UIColor(rgb: 0x60C5D4))
        dataSet.drawValuesEnabled = false
        dataSets.append(dataSet)
        
        let data = BarChartData(dataSets: dataSets)
        data.highlightEnabled = false
        
        card.data = data
        card.barData?.barWidth = 0.2
        card.chartDescription?.text = ""
        
        let yAxisValueFormatter = HourValueFormatter()
        card.leftAxis.valueFormatter = yAxisValueFormatter
        card.leftAxis.granularity = 1.0
        card.leftAxis.axisMinimum = 0.0
        card.rightAxis.valueFormatter = yAxisValueFormatter
        card.rightAxis.granularity = 1.0
        card.rightAxis.axisMinimum = 0.0
        card.rightAxis.drawAxisLineEnabled = false
        card.rightAxis.drawZeroLineEnabled = false
        card.rightAxis.drawTopYLabelEntryEnabled = true
        card.rightAxis.drawGridLinesEnabled = false
        card.rightAxis.drawBottomYLabelEntryEnabled = true
        card.rightAxis.drawLimitLinesBehindDataEnabled = false
        card.rightAxis.drawLabelsEnabled = false
        
        card.legend.verticalAlignment = .top
        card.legend.horizontalAlignment = .right
        card.legend.formToTextSpace = 2
        card.setExtraOffsets(left: 0.0, top: -20.0, right: 0.0, bottom: 0.0)
        
        card.isMultipleTouchEnabled = false
        card.dragEnabled = false
        card.pinchZoomEnabled = false
        
        card.notifyDataSetChanged()
    }
    
    func generateDailyTotalCard() {
        
        let card = LineChartView(frame: CGRect(x: 0, y: 0, width: self.graphActivityDuration.frame.width, height: self.graphActivityDuration.frame.height))
        //card.backgroundColor = UIColor.white
        
        self.graphActivityTotal.addSubview(card)
        
        let today: Date = Date()
        let start = getStartTime(from: today)
        
        var lineChartEntry = [ChartDataEntry]()
        
        let xAxisValueFormatter = DayValueFormatter()
        card.xAxis.valueFormatter = xAxisValueFormatter
        card.xAxis.labelPosition = .bottom
        card.xAxis.drawGridLinesEnabled = false

        for i in (0..<7)
        {
            xAxisValueFormatter.label_x[i] = start + (Double(i) * 86400.0)
            
            let apd = activity_per_day()
            apd.child_no = ActivityViewController.remote_no
            let total: Double = apd.get_total_by_start(xAxisValueFormatter.label_x[i])
            
            let point = ChartDataEntry(x: Double(i), y: total / 100.0) // 일단 100으로 나눠줌. 나중에 칼로리로 계산
            lineChartEntry.append(point)
        }
        
        let line = LineChartDataSet(values: lineChartEntry, label: "Daily")
        line.colors = [UIColor.gray]
        line.circleRadius = 3
        line.circleColors = [UIColor.gray]
        line.circleHoleRadius = 2
        line.circleHoleColor = UIColor(rgb: 0xF0F0F0)
        line.drawValuesEnabled = false

        let data = LineChartData()
        data.addDataSet(line)
        
        card.data = data
        card.chartDescription?.text = ""
        
        //let yAxisValueFormatter = HourValueFormatter()
        //card.leftAxis.valueFormatter = yAxisValueFormatter
        card.leftAxis.granularity = 1.0
        card.leftAxis.axisMinimum = 0.0
        //card.rightAxis.valueFormatter = yAxisValueFormatter
        card.rightAxis.granularity = 1.0
        card.rightAxis.axisMinimum = 0.0
        card.rightAxis.drawAxisLineEnabled = false
        card.rightAxis.drawZeroLineEnabled = false
        card.rightAxis.drawTopYLabelEntryEnabled = true
        card.rightAxis.drawGridLinesEnabled = false
        card.rightAxis.drawBottomYLabelEntryEnabled = true
        card.rightAxis.drawLimitLinesBehindDataEnabled = false
        card.rightAxis.drawLabelsEnabled = false
        
        card.legend.verticalAlignment = .top
        card.legend.horizontalAlignment = .right
        card.legend.formSize = 0
        card.legend.formToTextSpace = 2
        card.setExtraOffsets(left: 0.0, top: -20.0, right: 0.0, bottom: 0.0)
        
        card.isMultipleTouchEnabled = false
        card.dragEnabled = false
        card.pinchZoomEnabled = false

        card.notifyDataSetChanged()
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
}
