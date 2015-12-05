//
//  ViewController.swift
//  Smove
//
//  Created by tai on 15/12/4.
//  Copyright © 2015年 台. All rights reserved.
//

import UIKit



class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clearColor()
        let time: NSTimeInterval = 2.0
        
        let delay = dispatch_time(DISPATCH_TIME_NOW,
            
            Int64(time * Double(NSEC_PER_SEC)))
        
        dispatch_after(delay, dispatch_get_main_queue()) {
            
            //延时执行的代码        
            self.presentViewController(self.vc, animated: true, completion: nil)

        }

        
    }
    
    
    

    var vc = PlayerViewController()
    
}

