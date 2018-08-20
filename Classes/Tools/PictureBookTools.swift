//
//  PictureBookTools.swift
//  demo3_pbDemo_scrollView
//
//  Created by 韩雪滢 on 29/01/2018.
//  Copyright © 2018 韩雪滢. All rights reserved.
//

import UIKit

class PictureBookTools: NSObject {
    func topViewController() -> MainScrollViewController {
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController as! UINavigationController
        let mainScrollVC = rootViewController.topViewController as! MainScrollViewController
        return mainScrollVC
    }
    
    
    static func imageForResource(path:String, type:String, bundle:Bundle) -> UIImage? {
        var scale = Int(UIScreen.main.scale)
        
        if scale == 1 {
            scale = 2
        }
        
        var pathWhole = "PictureBook.bundle/" + path + "@" + String(describing: scale) + "x"
        
        if bundle.path(forResource: pathWhole, ofType: type) != nil {
          
            
        } else {
            
            pathWhole = "PictureBook.bundle/" + path
        }
    
        let imgPath:String? = bundle.path(forResource: pathWhole, ofType: type)
        guard let _ = imgPath else {
            return nil
        }
        return UIImage(contentsOfFile: imgPath!)
    }
    
    // 延时执行
    typealias Task = (_ cancel : Bool) -> Void
    
    static func delay(_ time: TimeInterval, task: @escaping ()->()) ->  Task? {
        
        func dispatch_later(block: @escaping ()->()) {
            print("delay time: \(time)")
            let t = DispatchTime.now() + time
            DispatchQueue.main.asyncAfter(deadline: t, execute: block)
        }
        var closure: (()->Void)? = task
        var result: Task?
        
        let delayedClosure: Task = {
            cancel in
            if let internalClosure = closure {
                if (cancel == false) {
                    DispatchQueue.main.async(execute: internalClosure)
                }
            }
            closure = nil
            result = nil
        }
        
        result = delayedClosure
        
        dispatch_later {
            if let delayedClosure = result {
                delayedClosure(false)
            }
        }
        return result
    }
    
    static func cancel(_ task: Task?) {
        task?(true)
    }
    
    static func isIphoneX() -> Bool{
        var isIphoneX = false
        if UIScreen.instancesRespond(to: #selector(getter: UIScreen.currentMode)) {
            isIphoneX = __CGSizeEqualToSize(CGSize(width:1125,height:2436), (UIScreen.main.currentMode?.size)!)
        }
        
        return isIphoneX
    }
    
    static func printLog<T> (message: T,
                              file:String = #file,
                              method:String = #function,
                              line: Int = #line) {
        print("\((file as NSString).lastPathComponent)[\(line)]. \(method): \(message)")
    }
}


