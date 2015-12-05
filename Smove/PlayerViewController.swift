//
//  PlayerViewController.swift
//  Smove
//
//  Created by tai on 15/12/5.
//  Copyright © 2015年 台. All rights reserved.
//

import UIKit



enum TTBoxTypeAcross {
    case left
    case right
}

enum TTBoxTypeVertical {
    case Up
    case Down
}

let ID = "collectCell"


class PlayerViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]

        // 加载用户账户信息
        userAccount = NSKeyedUnarchiver.unarchiveObjectWithFile((path as NSString).stringByAppendingPathComponent("account.plist")) as? UserAccount
        
        //第一次进来不让变换颜色有动画,所以不调用下面的变颜色方法
        let max: UInt32 = 200//最大,不让其显示白色底色
        let min: UInt32 = 50//最小,不让其显示黑色底色
        
            let color = UIColor(red: CGFloat(arc4random_uniform(max - min) + min)/256, green: CGFloat(arc4random_uniform(max - min) + min)/256, blue: CGFloat(arc4random_uniform(max - min) + min)/256, alpha: 1.0)
            UIApplication.sharedApplication().keyWindow?.backgroundColor = color
            self.view.backgroundColor = color
        //------------------

        //添加collectionView -------------------
        centerCollectFlowLayout.itemSize = CGSizeMake((125 - 3) / 3, (125 - 3) / 3)//每个格子的大小,为什么要减三呢,因为要留出分割线的位置,不然它会通过自动布局,根据整体大小来去放置小格子的位置,这不是我们所需要的做法.
        centerCollectFlowLayout.minimumInteritemSpacing = 1
        centerCollectFlowLayout.minimumLineSpacing = 1
        
        centerCollectView = UICollectionView(frame: CGRectMake(0, 0, 125, 125), collectionViewLayout: centerCollectFlowLayout)
        centerCollectView!.delegate = self
        centerCollectView!.dataSource = self
        centerCollectView!.scrollEnabled = false
        centerCollectView!.layer.masksToBounds = true
        centerCollectView!.layer.cornerRadius = 25
        centerCollectView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: ID)
        centerCollectView!.center = view.center
        view.addSubview(centerCollectView!)
        //------------------
        
        //添加食物和食物timer ------------------
        footTimer = NSTimer(timeInterval: 1.5, target: self, selector: "showFoot", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(footTimer!, forMode: NSRunLoopCommonModes)
        footView = UIView(frame: CGRectMake(0,0,15,15))
        centerCollectView?.addSubview(footView!)
        footView!.backgroundColor = UIColor.lightGrayColor()
        footView!.hidden = true
        let anim = CABasicAnimation(keyPath: "transform.rotation")
        
        anim.toValue = 2 * -M_PI
        anim.repeatCount = MAXFLOAT
        anim.duration = 3
        
        //通常应用在循环播放的动画,会和视图绑定,不会在后期被销毁,视图销毁动画跟着销毁
        anim.removedOnCompletion = false
        
        footView!.layer.addAnimation(anim, forKey: nil)
        //------------------
        
        //添加手势 ------------------
        pan.addTarget(self, action: "panMove:")
        pan.delegate = self
        view.addGestureRecognizer(pan)
        //------------------
        
        //添加分数标签 ------------------
        view.addSubview(markLabel)
        markLabel.textColor = UIColor.blackColor()
        markLabel.text = "0      LV 1   最高分数: \(Int(userAccount?.userMarkNum == nil ? 0 : userAccount!.userMarkNum! ))"
        markLabel.textAlignment = .Center
        markLabel.font = UIFont.systemFontOfSize(25)
        //------------------
        

        //添加隐身按钮 ------------------
        let btn = UIButton(frame: CGRectMake(0,UIScreen.mainScreen().bounds.height - 150,150,150))
        btn.setTitle("隐身", forState: .Normal)
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 75
        btn.backgroundColor = UIColor.magentaColor()
        btn.addTarget(self, action: "makeInvisible:", forControlEvents: .TouchUpInside)
        view.addSubview(btn)
        //------------------

    }
    
    //隐身的方法
    func makeInvisible(btn: UIButton) {
        btn.selected = !btn.selected
        if btn.selected {
            isInvisible = true
            ball.alpha = 0.3
        } else {
            isInvisible = false
            ball.alpha = 1
        }
    }
    
    //手势移动调用方法,不做处理,因为会调用多次
    func panMove(pan: UIPanGestureRecognizer) { }
    
    //秀出食物
    func showFoot() {
        if markNum % 10 == 0 && markNum != 0 && !isRead{//LV + 1
            self.isShowAddLV = true
            isRead = true
            var i = 0
            
            for var ball in ballArr {
                let ballI = ball["\(i)"] as! UIView

                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    ballI.alpha = 0
                    }, completion: { (_) -> Void in
                        ballI.removeFromSuperview()
                        
                })
                i++
            }
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.newBackground()
            })
            
            
            //延时执行代码 ------------------
            
            let time: NSTimeInterval = 2.0
            
            let delay = dispatch_time(DISPATCH_TIME_NOW,
                
                Int64(time * Double(NSEC_PER_SEC)))
            
            dispatch_after(delay, dispatch_get_main_queue()) {
                
                //延时执行的代码
                self.LV += 1
                self.markLabel.text = "\(self.markNum)      LV \(Int(self.LV))   最高分数: \(Int(self.userAccount?.userMarkNum == nil ? 0 : self.userAccount!.userMarkNum! ))"
                //删掉碰撞小球数组,重新添加
                self.ballArr.removeAll()
                //取消正在升级
                self.isShowAddLV = false
                var rect = self.ball.frame
                if rect.size.width <= 30 {
                    rect.size.width += 0.5
                    rect.size.height += 0.5
                }
                self.ball.frame = rect
                
            }
            //------------------
            //删除掉所有数组
            
        }
        //如果正在升级
        if isShowAddLV {

            return
        }
        if footView!.hidden {//如果食物是隐藏的,那么重新给定一个方向,让其可以食用
            var arcNum = 0
    
            while true {
                arcNum = Int(arc4random() % 8)
                if arcNum != footCurrentIndex && arcNum != currentIndex {
                    break
                }
            }
                footCurrentIndex = arcNum
                arcNum = Int(arc4random() % 8)

            

            
            let cell = centerCollectView?.cellForItemAtIndexPath(NSIndexPath(forRow: footCurrentIndex, inSection: 0))
            footView!.center = cell!.center
            footView!.hidden = false
        }
    }
    
    //让球跑起来的方法和做一些是否输掉游戏等判断
    func timerGo() {
        
        
        if isLose {//判断是否输掉游戏,给与输掉游戏的动画
            bili += 0.005
            
            let scaleForm = CGAffineTransformMakeScale(CGFloat(bili), CGFloat(bili))
            
            view.transform = CGAffineTransformTranslate(scaleForm,CGFloat(bili) , CGFloat(bili))
            return
        }
        if isShowAddLV {//判断是否在秀出升级界面
            return
        }
        currentTime += 1
        if (currentTime % 120) == 0 && ballArr.count <= Int(LV) / 3 + 5 {//判断,每2秒增加一个球 //并根据等级每三级增加一个球
            for var i = 0 ; i < Int(arc4random_uniform(3 - 1) + 1); i++ {
                let v = addBall()
                view.addSubview(v)
                var dict = [String: AnyObject]()
                dict = ["\(ballArr.count)": v]
                dict["TTBoxTypeAcross"] = "\(TTBoxTypeAcross.right)"
                dict["TTBoxTypeVertical"] = "\(TTBoxTypeVertical.Down)"
                ballArr.append(dict)
            }
            
            if twoTimer == nil {
                twoTimer = NSTimer(timeInterval: 1 / 60, target: self, selector: "arrBallGo", userInfo: nil, repeats: true)
                NSRunLoop.currentRunLoop().addTimer(twoTimer!, forMode: NSRunLoopCommonModes)
            }
        }
        
        //        var rect = v!.frame
        //        rect.origin.y += 1
        //        v!.frame = rect
        
        //如果碰撞,则输了
        if isInvisible {
            return
        }
        var i = 0
        for viewBall in ballArr {
            if ballArr.count == 0 {
                return
            }
            let balls = viewBall["\(i)"]
            

            
            
            if CGRectIntersectsRect(view.convertRect(balls!.frame, toView: view), centerCollectView!.convertRect(ball.frame, toView: view)) {//如果球撞到一起,则游戏Over
                view.userInteractionEnabled = false
                //增加存分数.
                if userAccount?.userMarkNum < markNum {
                    // 字典转模型，创建用户账户
                    let account = UserAccount(dict: ["userMarkNum": markNum])
                    // 将 account 对象保存在属性中
                    self.userAccount = account
                    userAccount!.userMarkNum = markNum
                    userAccount!.saveUserAccount()
                }
                let rect = centerCollectView!.convertRect(ball.frame, toView: view)
                print(rect)
                x = (rect.origin.x + rect.width / 2) / UIScreen.mainScreen().bounds.width
                y = (rect.origin.y + rect.height / 2) / UIScreen.mainScreen().bounds.height
                view.layer.anchorPoint = CGPoint(x: x!,y: y!)//获取的锚点.
                print("\(x)\(y)")
                isLose = true
                let btn = UIButton(frame: CGRectMake(100,100,100,100))
                btn.setTitle("重新开始", forState: .Normal)
                btn.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                btn.backgroundColor = UIColor.darkGrayColor()
                btn.addTarget(self, action: "newPlayClick:", forControlEvents: .TouchUpInside)
                
                
                UIApplication.sharedApplication().keyWindow?.addSubview(btn)
                break
            }
            i++
        }
        
        i = 0
        
    }
    

    
    ///添加碰撞小球
    func addBall() -> UIView {
        let arcX = CGFloat(arc4random()) % view.frame.width
        let arcY = CGFloat(arc4random()) % view.frame.height
        let arcAcc = arc4random() % 3
        var balls: UIView?
        if arcAcc == 0 {
            balls = UIView(frame: CGRectMake(arcX,0,25,25))
        }else if arcAcc == 1 {
            balls = UIView(frame: CGRectMake(0,arcY,25,25))
        }else if arcAcc == 2 {
            balls = UIView(frame: CGRectMake(view.frame.width,arcY,25,25))
        }else {
            balls = UIView(frame: CGRectMake(arcX,view.frame.height,25,25))
        }
        balls!.userInteractionEnabled = false
        balls!.backgroundColor = UIColor.blackColor()
        
        return balls!
    }
    
    //所有小球移动的方法
    func arrBallGo() {
        if isLose {
            return
        }else if isShowAddLV {
            return
        }
        var i = 0
        for var viewBall in ballArr {//循环遍历小球数组.让其移动
            var newDict = viewBall
            var ballRect = viewBall["\(i)"]!.frame
            let arcNum = arc4random() % 10
            if newDict["TTBoxTypeAcross"] as! String == "\(TTBoxTypeAcross.right)" {
                ballRect.origin.x += (0.3 + LV * 0.3)//根据等级比例来计算碰撞小球移动速度
            }
            if newDict["TTBoxTypeAcross"] as! String == "\(TTBoxTypeAcross.left)" {
                ballRect.origin.x -= (0.3 + LV * 0.3)
            }
            if newDict["TTBoxTypeVertical"] as! String == "\(TTBoxTypeVertical.Down)" {
                ballRect.origin.y += (0.3 + LV * 0.3)
            }
            if newDict["TTBoxTypeVertical"] as! String == "\(TTBoxTypeVertical.Up)" {
                ballRect.origin.y -= (0.3 + LV * 0.3)
            }
            if CGRectGetMaxX(ballRect) >= view.frame.size.width {
                newDict["TTBoxTypeAcross"] = "\(TTBoxTypeAcross.left)"
                if arcNum == 5 {
                    return
                }
            }
            if CGRectGetMinX(ballRect) <= 0 {
                newDict["TTBoxTypeAcross"] = "\(TTBoxTypeAcross.right)"
                if arcNum == 5 {
                    return
                }
            }
            if CGRectGetMaxY(ballRect) >= view.frame.size.height {
                newDict["TTBoxTypeVertical"] = "\(TTBoxTypeVertical.Up)"
                if arcNum == 5 {
                    return
                }
            }
            if CGRectGetMinY(ballRect) <= 0 {
                newDict["TTBoxTypeVertical"] = "\(TTBoxTypeVertical.Down)"
                if arcNum == 5 {
                    return
                }
            }
            (newDict["\(i)"] as! UIView).frame = ballRect
            viewBall = newDict
            ballArr[i] = viewBall
            i++
        }
        
        
    }
    
    //更换背景颜色
    func newBackground() {
        
        let max: UInt32 = 200//最大,不让其显示白色底色
        let min: UInt32 = 50//最小,不让其显示黑色底色
        
        UIView.animateWithDuration(1) { () -> Void in
            let color = UIColor(red: CGFloat(arc4random_uniform(max - min) + min)/256, green: CGFloat(arc4random_uniform(max - min) + min)/256, blue: CGFloat(arc4random_uniform(max - min) + min)/256, alpha: 1.0)
            UIApplication.sharedApplication().keyWindow?.backgroundColor = color
            self.view.backgroundColor = color
        }

    }

    func newPlayClick(btn: UIButton) {
        // *** 一定要等待控制器被销毁后，再发送通知
        footTimer?.invalidate()
        timer?.invalidate()
        twoTimer?.invalidate()
        btn.removeFromSuperview()
        self.dismissViewControllerAnimated(false, completion: { () -> Void in
            // 控制器被销毁后再执行的代码
            NSNotificationCenter.defaultCenter().postNotificationName(SwitchRootViewControllerNotification, object: nil)
        })
        
    }
    
    deinit {
        print("游戏控制器销毁了")
        footTimer?.invalidate()
        timer?.invalidate()
        twoTimer?.invalidate()
    }
    ///
    var userAccount: UserAccount?
    ///是否已经读取过升级判断
    var isRead = false
    ///等级
    var LV: CGFloat = 1
    ///是否正在秀增加等级
    var isShowAddLV = false
    ///是否隐身
    var isInvisible = false
    ///分数标签
    var markLabel = UILabel(frame: CGRectMake(UIScreen.mainScreen().bounds.width / 2 - 150, 0, 300, 150))
    ///目前所得分数
    var markNum = 0
    ///当前食物所在位置
    var footCurrentIndex = Int(arc4random() % 8)
    ///食物用的定时器
    var footTimer: NSTimer?
    ///食物
    var footView: UIView?
    
    
    ///第二个定时器,用在所有碰撞小球的运行使用
    var twoTimer: NSTimer?
    ///所有碰撞小球的数组,里面存放的是字典,用下标取小球
    var ballArr = [[String: AnyObject]]()
    ///用来计算结束游戏锚点的x
    var x: CGFloat?
    ///用来计算结束游戏锚点的x
    var y: CGFloat?
    ///当前时间
    var currentTime = CGFloat()
    ///比例
    var bili = 1.0
    ///是否输掉游戏
    var isLose = false
    ///控制游戏运行中的大部分判断
    var timer: NSTimer?
    ///拖动手势
    var pan = UIPanGestureRecognizer()
    ///当前自己控制的小球所在的位置
    var currentIndex = 4
    ///是否在移动
    var isMove = false
    ///我们控制的小球
    var ball = UIView()
    ///中间的colletionView
    var centerCollectView: UICollectionView?
    ///中间的collectionViewFolwLayout
    var centerCollectFlowLayout = UICollectionViewFlowLayout()
}


extension PlayerViewController: UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9
    }
    
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if isInvisible {//如果隐身
            return false
        } else if isMove {//如果正在移动
            
            return false
        } else if isLose{//如果输了
            return false
        } else {//都不是,那么可以移动
            let point = pan.translationInView(view)
            var index = currentIndex
            if point.x < 0 {//左滑
                index -= 1
                if index == -1 || index == 2 || index == 5 {//超出边界则不让手势有效
                    return false
                }
            }else if point.x > 0 {//右滑
                index += 1
                if index == 3 || index == 6 || index == 9 {
                    return false
                }
                
            }else if point.y < 0 {//上滑
                index -= 3
                if index == -1 || index == -2 || index == -3 {
                    return false
                }
                
            }else if point.y > 0 {//下滑
                index += 3
                if index == 9 || index == 10 || index == 11 {
                    return false
                }
            }
            
            //来到这里证明手势是有效的,给小球做移动处理
            currentIndex = index
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            let cell = centerCollectView?.cellForItemAtIndexPath(indexPath)
            UIView.animateWithDuration(0.1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: [], animations: { () -> Void in
                self.ball.center = cell!.center
                
                }, completion: { (_) -> Void in
                    self.isMove = false
                    
            })

            //如果当前移动位置有食物,那么加一分并且重新显示新的食物
            if currentIndex == footCurrentIndex && !footView!.hidden{
                isRead = false
                footView!.hidden = true
                markNum += 1
                markLabel.text = "\(markNum)      LV \(Int(LV))   最高分数: \(Int(userAccount?.userMarkNum == nil ? 0 : userAccount!.userMarkNum! ))"
            }
            return true
        }
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ID, forIndexPath: indexPath)
        cell.backgroundColor = UIColor.whiteColor()
        
        if indexPath.row == 4 {//初始游戏,把玩家小球放到中间
            
            ball.frame = CGRectMake(0, 0, 15, 15)
            ball.backgroundColor = UIColor.blueColor()
            
            centerCollectView!.addSubview(ball)
            ball.center = cell.center
            timer = NSTimer(timeInterval: 1 / 60, target: self, selector: "timerGo", userInfo: nil, repeats: true)
            NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
        }
        
        return cell
    }
}


/* ----------------------------------------- 该方法可以作圆形是否重叠判断的一个方法,能够取出整个圆形所有坐标..思路,取整条圆半径所有像素点作X,并且给圆半径所有像素点都添加360旋转的点,作Y,放进数组,即二维数组,即可当做x.y来进行循环判断圆形下是否重叠

//MARK: - 计算雷达圆形里所在的某一个点坐标
///-center:圆心点坐标
///-angle:角度
///-radius:圆半径
///-return:所需要的坐标
func calcCircleCoordinateWithCenter(center: CGPoint, angle: CGFloat, radius: CGFloat) -> CGPoint {
let m_pi = CGFloat(M_PI)
let cosfNum = Float(angle * m_pi) / 180
let x2 = radius * CGFloat(cosf(cosfNum))
let y2 = radius * CGFloat(sinf(cosfNum))
return CGPointMake(x2 + center.x, center.y - y2)
}


*/