//
//  UserAccount.swift
//  Smove
//
//  Created by Apple on 15/12/5.
//  Copyright © 2015年 台. All rights reserved.
//

import UIKit

/// 用户账户模型
class UserAccount: NSObject, NSCoding {
    
    var userMarkNum: Int?
    init(dict: [String: AnyObject]) {
        super.init()
        
        setValuesForKeysWithDictionary(dict)
    }
    
    override func setValue(value: AnyObject?, forUndefinedKey key: String) { }
    
    /// 模型描述信息
    /// 描述对象信息，建议在所有的模型中，都添加此方法，会有利于调试！
    override var description: String {
        let keys = ["UserMarkNum"]
        
        // dictionaryWithValuesForKeys 同样是 KVC 的方法
        // 将对象转换成字典，只转换 keys 数组中包含的`属性`名称
        // 如果 key 不存在，会直接崩溃
        // 跟 setValuesForKeysWithDictionary 刚好对应的一个方法
        return "\(self.dictionaryWithValuesForKeys(keys))"
    }
    
    /// 保存当前用户账户对象到沙盒
    func saveUserAccount() {
        var path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        // 1. 从 Xcode 7 beta 5 开始，stringByAppendingPathComponent 就变成了 NSString 的方法
        // 2. NSString -> String/ NSArray -> [] / NSDictionary - [] 如果要转换苹果底层提供了`桥接`机制
        // 在转换的时候，不需要 ?/!
        path = (path as NSString).stringByAppendingPathComponent("account.plist")
        
        print(path)
        
        // 会自动调用对象的 encodeWithCoder 方法进行归档
        NSKeyedArchiver.archiveRootObject(self, toFile: path)
    }
    
    // MARK: - NSCoding
    /// 归档（encode 编码），将当前`对象`写入沙盒时使用(二进制数据)，以备后续使用，- 序列化类似
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(userMarkNum, forKey: "UserMarkNum")
    }
    
    /// 解档(decode解码)，将沙盒中的`文件(二进制数据)`转换成自定义对象 - 反序列类似
    /// 构造函数的作用是创建对象
    required init?(coder aDecoder: NSCoder) {
        
        userMarkNum = aDecoder.decodeObjectForKey("UserMarkNum") as? Int
    }
}
