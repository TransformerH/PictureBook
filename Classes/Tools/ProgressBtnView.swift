//
//  ProgressBtnView.swift
//  demo4
//
//  Created by 韩雪滢 on 22/01/2018.
//  Copyright © 2018 韩雪滢. All rights reserved.
//


import UIKit
import SnapKit

class ProgressBtnView: UIView {
    
    var btnImage:UIImage!
    var progressCircle:UIBezierPath!
    var progressBtn:UIButton!
    var progress:Float = 0.0{
        didSet(newProgress){
            progressLayer.strokeEnd = CGFloat(progress)
            progressLayer.removeAllAnimations()
        }
    }
    var progressLayer:CAShapeLayer!
    
    
    override func draw(_ rect: CGRect) {
        
        let bgColor = UIColor.white
        bgColor.setFill()
        UIRectFill(rect)
        
        let centerX = rect.midX
        let centerY = rect.midY
        let radius = (rect.size.width - 3) / 2
        
        layer.backgroundColor = UIColor.white.cgColor
        backgroundColor = UIColor.white
        layer.masksToBounds = true
        
        progressCircle = UIBezierPath(arcCenter: CGPoint(x:centerX, y:centerY), radius: radius, startAngle: (CGFloat(-0.5 * .pi)), endAngle: (CGFloat(1.5 * .pi)), clockwise: true)
        
        progressLayer = CAShapeLayer()
        progressLayer.backgroundColor = UIColor.white.cgColor
        progressLayer.fillColor = UIColor.white.cgColor
        progressLayer.lineWidth = 2
        progressLayer.strokeColor = UIColor(red:244.0/255.0, green: 100.0/255.0, blue:99.0/255.0, alpha:1.0).cgColor
        progressLayer.lineCap = kCALineCapRound
        progressLayer.path = progressCircle.cgPath
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)

    }
}
