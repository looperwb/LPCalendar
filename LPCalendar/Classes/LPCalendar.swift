//
//  LPCalendarCell.swift
//  LPCalendar
//
//  Created by zwb on 16/6/18.
//  Copyright © 2016年 zwb. All rights reserved.
//

import UIKit

var LP_SCREEN_WIDTH: CGFloat { get { return UIScreen.mainScreen().bounds.size.width } }
var LP_SCREEN_HEIGHT: CGFloat { get { return UIScreen.mainScreen().bounds.size.height } }
var LP_ONE_PIXEL: CGFloat { get { return 1.0 / UIScreen.mainScreen().scale } }
var LP_CalendarCellBackgroundColor: UIColor { get { return UIColor(red: 245/255.0, green: 245/255.0, blue: 245/255.0, alpha: 1.0) } }
var LP_TextColor: UIColor { get { return UIColor.blackColor() } }
var LP_WeekdayLabelTextColor: UIColor { get { return UIColor(red: 167/255.0, green: 167/255.0, blue: 167/255.0, alpha: 1.0) } }
var LP_MonthLabelTextColor: UIColor { get { return UIColor(red: 130/255.0, green: 130/255.0, blue: 130/255.0, alpha: 1.0) } }
var LP_NavigationBarColor: UIColor { get { return UIColor(red: 65/255.0, green: 183/255.0, blue: 243/255.0, alpha: 1.0) } }
var LP_TodayCalendarCellBackgroundColor: UIColor { get { return UIColor(red: 60/255.0, green: 60/255.0, blue: 60/255.0, alpha: 1.0) } }
var LP_SelectCalendarCellBackgroundColor: UIColor { get { return UIColor(red: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1.0) } }
var LP_SelectTextColor: UIColor { get { return UIColor.whiteColor() } }
var LP_WeekendTextColor: UIColor { get { return UIColor.redColor() } }
var LP_WeekdayViewHeight: CGFloat { get { return 20 } }
var LP_HeaderViewHeight: CGFloat { get { return 20 } }

func LP_Iphone6Scale(scale: CGFloat) -> CGFloat {
    return scale * LP_SCREEN_WIDTH / 375.0
}

@objc protocol LPCalendarViewControllerDelegate {
    func calendarViewConfirmClickWithStartDate(startDate: Int, endDate: Int)
}

class LPCalendarViewController: UIViewController {
    

    private var startDate = 0
    private var endDate: Int?
    
    private var pickerDate = NSDate() {
        didSet {
           
            /// 如果是同月 不刷新数据
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy年MM月"
            if datePickerFlag == formatter.stringFromDate(pickerDate) {
                return
            }
            
            formatter.dateFormat = "yyyy年MM月dd日"
            let tempDate = formatter.stringFromDate(pickerDate)
            datePickerFlag = tempDate[tempDate.startIndex..<tempDate.startIndex.advancedBy(8)]
            dateLabel.setTitle(tempDate, forState: .Normal)
            dataArray.removeAll()
            initDataSource()
        }
    }
    
    var showAlertView: Bool?
    
    private var datePickerFlag = ""
    private var bottomView: UIView!
    private var datePicker: UIDatePicker!
    private var dateLabel: UIButton!
    
    private var dataArray = [LPCalendarHeaderModel]() {
        didSet {
            collectionView.reloadData()
        }
    }
    private var weekArray = [[LPCalendarModel]]()
    
    private var collectionView: UICollectionView!
    
    weak var delegate: LPCalendarViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initDataSource()
        createUI()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    private func initDataSource() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let manager = LPCalendarManager(startDate: self.pickerDate)
       
            let tempDataArray = manager.getCalendarDataSourceWithLimitMonth()
            dispatch_async(dispatch_get_main_queue(), { 
                self.dataArray = tempDataArray
                if let indexPath = manager.startIndexPath {
                    self.showCollectionViewWithStartIndexPath(indexPath)
                }
            })
        }
    }
    
    private func createUI() {
        
        let navigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: LP_SCREEN_WIDTH, height: 64))
        navigationBar.barTintColor = LP_NavigationBarColor
       
        let navigationBarTitle = UINavigationItem(title: "LPCalendar")
        
        navigationBar.pushNavigationItem(navigationBarTitle, animated: true)
        let item = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(navigationBackButton))
        navigationBarTitle.leftBarButtonItem = item
        navigationBar.setItems([navigationBarTitle], animated: true)
        view.addSubview(navigationBar)

        addWeekdayView()
        
        let width = LP_Iphone6Scale(47)
        let height = LP_Iphone6Scale(47)
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: width, height: height)
        flowLayout.headerReferenceSize = CGSize(width: LP_SCREEN_WIDTH, height: LP_HeaderViewHeight)
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        
        /// iOS9.0以上 sectionHeader可以固定住
        if #available(iOS 9.0, *) {
            flowLayout.sectionHeadersPinToVisibleBounds = true
        } else {
            // Fallback on earlier versions
        }
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 64 + LP_WeekdayViewHeight, width: width * 8, height: LP_SCREEN_HEIGHT - 64 - LP_WeekdayViewHeight - 44), collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.showsVerticalScrollIndicator = false
        view.addSubview(collectionView)
        
        collectionView.registerClass(LPCalendarCell.self, forCellWithReuseIdentifier: "LPCalendarCell")
        collectionView.registerClass(LPCalendarReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "LPCalendarReusableView")
        
        addDatePicker()
    }
    
    private func addWeekdayView() {
        let weekdayView = UIView(frame: CGRect(x: 0, y: 64, width: LP_SCREEN_WIDTH, height: LP_WeekdayViewHeight))
        weekdayView.backgroundColor = UIColor(red: 248/255.0, green: 248/255.0, blue: 248/255.0, alpha: 1.0)
        view.addSubview(weekdayView)
        let weekdayArray = ["周次", "周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        let width = LP_Iphone6Scale(47)
        for i in 0..<8 {
            let weekdayLabel = UILabel(frame: CGRect(x: CGFloat(i) * width, y: 0, width: width, height: LP_WeekdayViewHeight))
            weekdayLabel.text = weekdayArray[i]
            weekdayLabel.font = UIFont.boldSystemFontOfSize(12)
            weekdayLabel.textAlignment = .Center
            weekdayLabel.textColor = LP_WeekdayLabelTextColor
            weekdayView.addSubview(weekdayLabel)
        }
    }
    
    private func addDatePicker() {
        
        bottomView = UIView(frame: CGRect(x: 0, y: LP_SCREEN_HEIGHT - 44, width: LP_SCREEN_WIDTH, height: 44))
    
        bottomView.backgroundColor = LP_CalendarCellBackgroundColor
        let todayButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: bottomView.frame.height))
        todayButton.setTitleColor(UIColor(red: 68/255.0, green: 192/255.0, blue: 255/255.0, alpha: 1.0), forState: .Normal)
        todayButton.setTitle("今天", forState: .Normal)
        todayButton.addTarget(self, action: #selector(todayButtonClick), forControlEvents: .TouchUpInside)
        bottomView.addSubview(todayButton)
        
        dateLabel = UIButton(frame: CGRect(x: 60, y: 0, width: LP_SCREEN_WIDTH - 120, height: bottomView.frame.height))
        dateLabel.setTitle("2016年06月20日", forState: .Normal)
        dateLabel.setTitleColor(LP_WeekendTextColor, forState: .Normal)
        dateLabel.titleLabel?.font = UIFont.boldSystemFontOfSize(18)
        dateLabel.addTarget(self, action: #selector(setDateButtonClick), forControlEvents: .TouchUpInside)
        bottomView.addSubview(dateLabel)
        
        let doneButton = UIButton(frame: CGRect(x: LP_SCREEN_WIDTH - 60, y: 0, width: 60, height: bottomView.frame.height))
        doneButton.setTitleColor(UIColor(red: 68/255.0, green: 192/255.0, blue: 255/255.0, alpha: 1.0), forState: .Normal)
        doneButton.setTitle("完成", forState: .Normal)
        doneButton.addTarget(self, action: #selector(doneButtonClick), forControlEvents: .TouchUpInside)
        bottomView.addSubview(doneButton)
        
        datePicker = UIDatePicker()
        datePicker.backgroundColor = UIColor.whiteColor()
        datePicker.datePickerMode = .Date
        datePicker.date = NSDate()
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), forControlEvents: .ValueChanged)
        datePicker.frame = CGRect(x: 0, y: LP_SCREEN_HEIGHT, width: LP_SCREEN_WIDTH, height: 216)
        view.addSubview(datePicker)
        
        view.addSubview(bottomView)
    }
    
    @objc private func navigationBackButton() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @objc private func datePickerValueChanged(picker: UIDatePicker) {
        pickerDate = picker.date
    }
    
    @objc private func todayButtonClick() {
        pickerDate = NSDate()
        scalingDatePicker(CGPoint(x: 0, y: LP_SCREEN_HEIGHT - 44), datePickerPoint: CGPoint(x: 0, y: LP_SCREEN_HEIGHT))
    }
    
    @objc private func doneButtonClick() {
        scalingDatePicker(CGPoint(x: 0, y: LP_SCREEN_HEIGHT - 44), datePickerPoint: CGPoint(x: 0, y: LP_SCREEN_HEIGHT))
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @objc private func setDateButtonClick() {
        scalingDatePicker(CGPoint(x: 0, y: LP_SCREEN_HEIGHT - 216 - 44), datePickerPoint: CGPoint(x: 0, y: LP_SCREEN_HEIGHT - 216))
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scalingDatePicker(CGPoint(x: 0, y: LP_SCREEN_HEIGHT - 44), datePickerPoint: CGPoint(x: 0, y: LP_SCREEN_HEIGHT))
    }
    
    /// 缩放时间选择器
    private func scalingDatePicker(bottomViewPoint: CGPoint, datePickerPoint: CGPoint) {
        UIView.animateWithDuration(0.2, delay: 0.0, options: [.AllowUserInteraction, .CurveLinear], animations: { () -> Void in
            self.bottomView.frame.origin = bottomViewPoint
            }, completion: { (let finished) -> Void in
        })
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: [.AllowUserInteraction, .CurveLinear], animations: { () -> Void in
            self.datePicker.frame.origin = datePickerPoint
            }, completion: { (let finished) -> Void in
        })
    
    }

    /// 滚动到选中时间的当月
    private func showCollectionViewWithStartIndexPath(startIndexPath: NSIndexPath) {
        collectionView.scrollToItemAtIndexPath(startIndexPath, atScrollPosition: UICollectionViewScrollPosition.Top, animated: false)
        collectionView.contentOffset = CGPoint(x: 0, y: collectionView.contentOffset.y - LP_HeaderViewHeight)
    }
}

extension LPCalendarViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return dataArray.count
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataArray[section].calendarItemArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("LPCalendarCell", forIndexPath: indexPath) as! LPCalendarCell
        let headerItem = dataArray[indexPath.section] 
        let calendarItem = headerItem.calendarItemArray[indexPath.row] 
        
        /// 显示周次
        if indexPath.row % 8 == 0 {
            cell.isSelected = false
            cell.dateLabel.text = String(calendarItem.weekOfYear)
            cell.dateLabel.textColor = LP_TextColor
            cell.dateLabel.font = UIFont.boldSystemFontOfSize(20)
            cell.cellBackgroundView.backgroundColor = LP_CalendarCellBackgroundColor
            cell.userInteractionEnabled = true
        } else if calendarItem.day > 0 {
         
            cell.isSelected = false
            cell.dateLabel.text = String(calendarItem.day)
            cell.dateLabel.font = UIFont.systemFontOfSize(15)
            cell.dateLabel.textColor = LP_TextColor
            cell.cellBackgroundView.backgroundColor = LP_CalendarCellBackgroundColor
            cell.userInteractionEnabled = true
        
            if calendarItem.dateInterval == startDate {
                cell.isSelected = true
                cell.dateLabel.textColor = LP_SelectTextColor
            } else if calendarItem.dateInterval == endDate {
                cell.isSelected = true
                cell.dateLabel.textColor = LP_SelectTextColor
            } else if calendarItem.dateInterval > startDate && calendarItem.dateInterval < endDate {
                cell.isSelected = true
                cell.dateLabel.textColor = LP_SelectTextColor
            } else {
//                if calendarItem.weekday == 7 || calendarItem.weekday == 6 {
//                    cell.dateLabel.textColor = LP_WeekendTextColor
//                }
            }
            
            if calendarItem.type == .TodayType {
                cell.cellBackgroundView.backgroundColor = LP_TodayCalendarCellBackgroundColor
                cell.dateLabel.textColor = LP_SelectTextColor
            }
            
        } else {
            cell.dateLabel.text = ""
            cell.isSelected = false
            cell.cellBackgroundView.backgroundColor = UIColor.whiteColor()
            cell.dateLabel.textColor = LP_TextColor
            cell.userInteractionEnabled = false
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        scalingDatePicker(CGPoint(x: 0, y: LP_SCREEN_HEIGHT - 44), datePickerPoint: CGPoint(x: 0, y: LP_SCREEN_HEIGHT))
        
        let headerItem = dataArray[indexPath.section]
        let calendarItem = headerItem.calendarItemArray[indexPath.row]
        
        /// 根据周次取选择时间段
        if indexPath.row % 8 == 0 {
            var dayOfOneWeekArray = [LPCalendarModel]()
            if calendarItem.weekInMonthType == .First {
                guard indexPath.section != 0 else {
                    return
                }
                let lastMonthCalendarItem = dataArray[indexPath.section - 1]
                dayOfOneWeekArray = addSameWeekArray(lastMonthCalendarItem, item: calendarItem, calendarArray: dayOfOneWeekArray)
                dayOfOneWeekArray = addSameWeekArray(headerItem, item: calendarItem, calendarArray: dayOfOneWeekArray)
            } else if calendarItem.weekInMonthType == .Last {
                guard indexPath.section < dataArray.count - 1 else {
                    return
                }
                let nextMonthCalendarItem = dataArray[indexPath.section + 1]
                dayOfOneWeekArray = addSameWeekArray(headerItem, item: calendarItem, calendarArray: dayOfOneWeekArray)
                dayOfOneWeekArray = addSameWeekArray(nextMonthCalendarItem, item: calendarItem, calendarArray: dayOfOneWeekArray)
            } else {
                dayOfOneWeekArray = addSameWeekArray(headerItem, item: calendarItem, calendarArray: dayOfOneWeekArray)
            }
            
            if weekArray.count == 0 {
                weekArray.append(dayOfOneWeekArray)
            } else {
                let firstObjectWeekArray = weekArray.first
                let lastObjectWeekArray = weekArray.last
                
                /// 取firstObjectWeekArray[1]的原因是:firstObjectWeekArray[0]是用于显示周次的，没有时间戳
                let startDateInWeek = firstObjectWeekArray![1].dateInterval
                let endDateInWeek = lastObjectWeekArray?.last?.dateInterval
                
                let tempStartDate = dayOfOneWeekArray[1].dateInterval
                let tempEndDate = dayOfOneWeekArray.last?.dateInterval
                
                if tempStartDate < startDateInWeek {
                    weekArray.insert(dayOfOneWeekArray, atIndex: 0)
                } else if tempEndDate > endDateInWeek {
                    weekArray.append(dayOfOneWeekArray)
                }
            }
            
            if let tempDate = weekArray.first?[1].dateInterval {
                startDate = tempDate
            }
            
            if let tempDate = weekArray.last?.last?.dateInterval {
                endDate = tempDate
            }
            
            if let nonNilDelegate = delegate {
                nonNilDelegate.calendarViewConfirmClickWithStartDate(startDate, endDate: endDate!)
            }
            
        } else {
            weekArray.removeAll()
        
            /// 根据起始时间和结束时间选择时间段
            if startDate == 0 {
                startDate = calendarItem.dateInterval
            } else if startDate > 0 && endDate > 0 {
                startDate = calendarItem.dateInterval
                endDate = 0
            } else {
                if startDate < calendarItem.dateInterval {
                    endDate = calendarItem.dateInterval
                    if let nonNilDelegate = delegate {
                        nonNilDelegate.calendarViewConfirmClickWithStartDate(startDate, endDate: endDate!)
                    }
                } else {
                    startDate = calendarItem.dateInterval
                }
            }
        }
        
        collectionView.reloadData()
    }
    
    /// 添加header视图
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        var reusableView: UICollectionReusableView!
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "LPCalendarReusableView", forIndexPath: indexPath) as! LPCalendarReusableView
            let headerItem = dataArray[indexPath.section]
            headerView.headerLabel.text = headerItem.headerText
            reusableView = headerView
        }
        return reusableView
    }
    
    private func addSameWeekArray(headerItem: LPCalendarHeaderModel, item: LPCalendarModel, calendarArray:[LPCalendarModel]) -> [LPCalendarModel] {
        var resultArray = calendarArray
        for temp in headerItem.calendarItemArray {
            if temp.weekOfYear == item.weekOfYear {
                resultArray.append(temp)
            }
        }
        return resultArray
    }
}

class LPCalendarCell: UICollectionViewCell {
    
    var dateLabel: UILabel!
    var subLabel: UILabel?
    var imageView: UIImageView?
    var isSelected: Bool? {
        didSet {
            if isSelected! {
                cellBackgroundView.backgroundColor = LP_SelectCalendarCellBackgroundColor
            } else {
                cellBackgroundView.backgroundColor = LP_CalendarCellBackgroundColor
            }
        }
    }
    var cellBackgroundView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createCell() {
        cellBackgroundView = UIView(frame: CGRect(x: 1, y: 1, width: frame.width - 1, height: frame.height - 1))
        contentView.addSubview(cellBackgroundView)
        
        dateLabel = UILabel(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        dateLabel.textAlignment = .Center
        dateLabel.font = UIFont.systemFontOfSize(15)
        contentView.addSubview(dateLabel)
        
//        subLabel = UILabel(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
//        subLabel?.textAlignment = .Center
//        subLabel?.font = UIFont.systemFontOfSize(15)
//        contentView.addSubview(subLabel!)
    }
}

class LPCalendarReusableView: UICollectionReusableView {
    var headerLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createReusableView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createReusableView() {
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        headerView.backgroundColor = UIColor(red: 248/255.0, green: 248/255.0, blue: 248/255.0, alpha: 0.8)
        addSubview(headerView)
        
        headerLabel = UILabel(frame: CGRect(x: 8, y: 0, width: 90, height: frame.height))
        headerLabel.textColor = LP_MonthLabelTextColor
        headerLabel.font = UIFont.boldSystemFontOfSize(12)
        headerLabel.backgroundColor = UIColor.clearColor()
        headerView.addSubview(headerLabel)
    }
}

enum LPCalendarType {
    case TodayType, LastType, NextType, Other
}

/**
 单月中周次的位置
 
 - First:  每月第一周
 - Middle: 每月中间周次
 - Last:   每月最后一周
 */
enum LPWeekInMonthType {
    case First, Middle, Last
}

class LPCalendarHeaderModel: NSObject {
    var headerText: String!
    var calendarItemArray: [LPCalendarModel]!
}

class LPCalendarModel: NSObject {
    var dateInterval: Int = 0
    var year: Int = 0
    var month: Int = 0
    var day: Int = 0
    var weekOfYear: Int = 0
    var weekday: Int = 0
    var weekInMonthType: LPWeekInMonthType = .Middle
    var type: LPCalendarType = .Other
}

class LPCalendarManager: NSObject {
    
    var startIndexPath: NSIndexPath?
    private var todayDate: NSDate!
    private var todayCompontents: NSDateComponents!
    private var greCalendar: NSCalendar!
    private var dateFormatter: NSDateFormatter!
    private var startDate: Int!
    private var pickerDate: NSDate!
    
    init(startDate: NSDate) {
        super.init()
        greCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        greCalendar.firstWeekday = 2
        todayDate = NSDate()
        todayCompontents = dateToComponents(todayDate)
        dateFormatter = NSDateFormatter()
        pickerDate = startDate
        self.startDate = dateToInterval(componentsToDate(dateToComponents(startDate)))
    }
    
    /**
     计算每一天数据
     
     - parameter limitMonth: 月的长度
     
     - returns: 返回所有月的数据
     */
    
    func getCalendarDataSourceWithLimitMonth() -> [LPCalendarHeaderModel] {
        var resultArray = [LPCalendarHeaderModel]()
        let components = dateToComponents(pickerDate)
        /// 限制月份 设置当前日期前后可以查到的月份
        let limitMonth = 12 * 20
        
        components.day = 1
        components.month -= (limitMonth + 1) / 2
        
        for item in 0..<limitMonth {
            components.month += 1
            let headerItem = LPCalendarHeaderModel()
            let date = componentsToDate(components)
            dateFormatter.dateFormat = "yyyy年MM月"
            let dateString = dateFormatter.stringFromDate(date)
            headerItem.headerText = dateString
            headerItem.calendarItemArray = getCalendarItemArrayWithDate(date, section: item)
            resultArray.append(headerItem)
        }
        return resultArray
    }
    
    /**
     计算单月每一天数据
     
     - parameter date:    每一月的第一天
     - parameter section: 第几个月
     
     - returns: 返回单个月所有天数的数组
     */
    
    private func getCalendarItemArrayWithDate(date: NSDate, section: Int) -> [LPCalendarModel] {
        var resultArray = [LPCalendarModel]()
        let tatalDay = numberOfDaysInCurrentMonth(date)
        let firstDay = startDayOfWeek(date)
        
        let components = dateToComponents(date)
        /// 一年的总周数
        let tempWeekOfYear = greCalendar.rangeOfUnit(NSCalendarUnit.WeekOfYear, inUnit: NSCalendarUnit.Year, forDate: date).length
        
        ///  判断日历每月多少列
        let tempDay = tatalDay + firstDay - 8
        var column = 0
        if tempDay % 7 == 0 {
            column = tempDay / 7 + 1
        } else {
            column = tempDay / 7 + 2
        }
        
        components.day = 0
        for i in 0..<column {
            for j in 0..<8 {
                let calendarItem = LPCalendarModel()
                let tempValue = components.weekOfYear + i
                if j == 0 {
                    //MARK: - 这里还有问题
                    /// 将年末没有满星期的周次设置为来年的第一周
                    if tempValue == tempWeekOfYear {
                        calendarItem.weekOfYear = 1
                    } else {
                        calendarItem.weekOfYear = tempValue
                    }
                    
                    switch i {
                    case 0:
                        calendarItem.weekInMonthType = .First
                    case column - 1:
                        calendarItem.weekInMonthType = .Last
                    default:
                        calendarItem.weekInMonthType = .Middle
                    }
                    
                    resultArray.append(calendarItem)
                    continue
                } else if i == 0 && j < firstDay {
                    calendarItem.year = 0
                    calendarItem.month = 0
                    calendarItem.day = 0
                    calendarItem.weekday = -1
                    calendarItem.dateInterval = -1
                    resultArray.append(calendarItem)
                    continue
                } else {
                    components.day += 1
                    if components.day == tatalDay + 1 {
                        /// 结束外层循环
                        i == column
                        break
                    }
                    
                    if components.year == todayCompontents.year && components.month == todayCompontents.month && components.day == todayCompontents.day {
                        calendarItem.type = .TodayType
                    }
                    calendarItem.year = components.year
                    calendarItem.month = components.month
                    calendarItem.day = components.day
                    calendarItem.weekday = j
                    
                    if tempValue == tempWeekOfYear {
                        /// 当年的最后一周是完整的一周周次为当年的最后一周，否则算来年的第一周
                        if calendarItem.weekday == 7 {
                            calendarItem.weekOfYear = tempValue
                            for index in resultArray.count - 7..<resultArray.count {
                                resultArray[index].weekOfYear = tempValue
                            }
                        } else {
                            calendarItem.weekOfYear = 1
                        }
                    } else {
                        calendarItem.weekOfYear = tempValue
                    }
                    
                    let date = componentsToDate(components)
                    calendarItem.dateInterval = dateToInterval(date)
                    
                    if startDate == calendarItem.dateInterval {
                        startIndexPath = NSIndexPath(forRow: 0, inSection: section)
                    }
                    
                    resultArray.append(calendarItem)
                }
            }
        }
        return resultArray
    }
    
    private func dateToComponents(date: NSDate) -> NSDateComponents {
//        let unitFlags: NSCalendarUnit = [.Year, .Month, .Day, .WeekOfYear, .Weekday, .Hour, .Minute, .Second]
//        let components = NSCalendar.currentCalendar().components(unitFlags, fromDate: date)
//        return components
        return greCalendar.components([.Year, .Month, .Day, .WeekOfYear, .Weekday, .Hour, .Minute, .Second], fromDate: date)
    }
    
    /// 计算一个月多少天
    private func numberOfDaysInCurrentMonth(date: NSDate) -> Int {
        return greCalendar.rangeOfUnit(NSCalendarUnit.Day, inUnit: NSCalendarUnit.Month, forDate: date).length
    }
    
    /// 计算这个月的第一天星期几
    private func startDayOfWeek(date: NSDate) -> Int {
        var startDate: NSDate? = nil
        let result: Bool = greCalendar.rangeOfUnit(NSCalendarUnit.Month, startDate: &startDate, interval: nil, forDate: date)
        if result {
            return greCalendar.ordinalityOfUnit(NSCalendarUnit.Day, inUnit: NSCalendarUnit.WeekOfYear, forDate: startDate!)
        }
        return 0
    }
    
    func dateToInterval(date: NSDate) -> Int {
        return Int(date.timeIntervalSince1970)
    }
    
    private func componentsToDate(components: NSDateComponents) -> NSDate {
        /// 不区分时分秒
        components.hour = 0
        components.minute = 0
        components.second = 0
        return greCalendar.dateFromComponents(components)!
    }
}