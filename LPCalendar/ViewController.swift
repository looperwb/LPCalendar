//
//  ViewController.swift
//  LPCalendar
//
//  Created by zwb on 16/6/18.
//  Copyright © 2016年 zwb. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
 
    var startDateLabel: UILabel!
    var endDateLabel:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let btn = UIButton(frame: CGRect(x: 60 , y: LP_SCREEN_HEIGHT / 2 - 50, width: LP_SCREEN_WIDTH - 120 , height: 44))
        btn.layer.cornerRadius = 5
        btn.layer.borderColor = LP_MonthLabelTextColor.CGColor
        btn.layer.borderWidth = 1
        btn.setTitleColor(LP_MonthLabelTextColor, forState: .Normal)
        btn.setTitle("打开日历", forState: UIControlState.Normal)
        btn.addTarget(self, action: #selector(btnClick), forControlEvents: .TouchUpInside)
        view.addSubview(btn)
        
        startDateLabel = UILabel(frame: CGRect(x: 0, y: LP_SCREEN_HEIGHT / 2, width: LP_SCREEN_WIDTH, height: 30))
        startDateLabel.textAlignment = .Center
        view.addSubview(startDateLabel)
        
        endDateLabel = UILabel(frame: CGRect(x: 0, y: LP_SCREEN_HEIGHT / 2 + 30, width: LP_SCREEN_WIDTH, height: 30))
        endDateLabel.textAlignment = .Center
        view.addSubview(endDateLabel)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc private func btnClick() {
        let cvc = LPCalendarViewController()
        cvc.delegate = self
        self.presentViewController(cvc, animated: true, completion: nil)
    }

}

extension ViewController: LPCalendarViewControllerDelegate {
    func calendarViewConfirmClickWithStartDate(startDate: Int, endDate: Int) {
        
        print("startDate\(startDate)")
        print("endDate\(endDate)")
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        startDateLabel.text = "\(formatter.stringFromDate(NSDate(timeIntervalSince1970: Double(startDate))))"
        endDateLabel.text = "\(formatter.stringFromDate(NSDate(timeIntervalSince1970: Double(endDate))))"
    }
}

