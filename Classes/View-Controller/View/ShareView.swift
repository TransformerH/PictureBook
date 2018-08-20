//
//  ShareView.swift
//  Alamofire
//
//  Created by 韩雪滢 on 07/02/2018.
//

import UIKit
import SnapKit
import FWPackager
import CIProgressHUD
import CIRouter

protocol ShareViewProtocol:class {
    func changeBtn()
}

let shareViewHeight = CGFloat(190.0)


class ShareView: UIView {
    
    let APP_SCREEN_WIDTH = UIScreen.main.bounds.size.width
    let APP_SCREEN_HEIGHT = UIScreen.main.bounds.size.height
    let margin = 25
    let cellWidth = (UIScreen.main.bounds.size.width - 25 * 5) / 4
    let cellHeight = 100
    let mWindow = UIApplication.shared.keyWindow!
    
    var baseURL = PictureEnv.shared.baseURL
    
    weak var delegate:ShareViewProtocol?
    
    var backView:UIView!
    var cellView:UIView!
    var qqShareBtn:UIButton!
    var qqLabel:UILabel!
    var weChatShareBtn:UIButton!
    var weChatLabel:UILabel!
    var qqZoneShareBtn:UIButton!
    var qqZoneLabel:UILabel!
    var weChatZoneBtn:UIButton!
    var weChatZoneLabel:UILabel!
    var shareLabel:UILabel!
    var cancelBtn: UIButton!
    
    var channel:Int!
    var id:Int!
    var type: Int!
    var bookName:String!
    var coverImg:String!
    var userName:String!
    var shareURL:String!
    var title:String!
    
    var coverShare:Bool!
    
    var currentBundle:Bundle!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(frame:CGRect, dic: Dictionary<String,Any>) {
        self.channel = dic["channel"] as! Int
        self.id = dic["id"] as! Int
        self.type = dic["type"] as! Int
        self.bookName = dic["bookName"] as! String
        self.userName = dic["userName"] as! String
        self.coverImg = dic["coverImg"] as! String
        self.title = dic["title"] as! String
        self.currentBundle = Bundle(for: ShareView.self)
        super.init(frame: frame)
        
        self.backgroundColor =  UIColor(red:232.0/255.0, green: 231.0/255.0, blue:231.0/255.0, alpha:1.0)
        
        makeShareView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeShareView() {
        shareLabel = UILabel()
        addSubview(shareLabel)
        shareLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(50)
        }
        shareLabel.text = "分享至"
        shareLabel.textColor = UIColor.gray
        shareLabel.textAlignment = .center
        shareLabel.backgroundColor = UIColor(red:232.0/255.0, green: 231.0/255.0, blue:231.0/255.0, alpha:1.0)
        
        var btnImg = UIImage()
        
        weChatZoneBtn = UIButton()
        weChatZoneBtn.tag = 0
        btnImg = PictureBookTools.imageForResource(path: "WeChatZone", type: "png", bundle: currentBundle)!
        weChatZoneBtn.setImage(btnImg, for: .normal)
        makeCellView(x: CGFloat(margin), button: weChatZoneBtn, text: "朋友圈")
        
        weChatShareBtn = UIButton()
        weChatShareBtn.tag = 1
        btnImg = PictureBookTools.imageForResource(path: "WeChat", type: "png", bundle: currentBundle)!
        weChatShareBtn.setImage(btnImg, for: .normal)
        makeCellView(x: (CGFloat(margin * 2) + cellWidth), button: weChatShareBtn, text: "微信")
        
        qqShareBtn = UIButton()
        qqShareBtn.tag = 2
        btnImg = PictureBookTools.imageForResource(path: "QQ", type: "png", bundle: currentBundle)!
        qqShareBtn.setImage(btnImg, for: .normal)
        makeCellView(x: (CGFloat(margin * 3) + cellWidth * 2), button: qqShareBtn, text: "QQ")
        
        qqZoneShareBtn = UIButton()
        qqZoneShareBtn.tag = 3
        btnImg = PictureBookTools.imageForResource(path: "QQZone", type: "png", bundle: currentBundle)!
        qqZoneShareBtn.setImage(btnImg, for: .normal)
        makeCellView(x: (CGFloat(margin * 4) + cellWidth * 3), button: qqZoneShareBtn, text: "QQ空间")
        
        cancelBtn = UIButton()
        addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(40)
        }
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.titleLabel?.textAlignment = .center
        cancelBtn.setTitleColor(UIColor.black, for: .normal)
        cancelBtn.addTarget(self, action: #selector(cancelBtnClicked), for: .touchUpInside)
        cancelBtn.backgroundColor = UIColor.white
        
    }
    
    func makeCellView(x: CGFloat, button:UIButton, text:String) {
        cellView = UIView()
        addSubview(cellView)
        cellView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(x)
            make.top.equalToSuperview().offset(50)
            make.width.equalTo(cellWidth)
            make.height.equalTo(cellHeight)
        }
        cellView.backgroundColor = UIColor.clear
        
        cellView.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(cellWidth)
        }
        button.addTarget(self, action: #selector(shareBtnClicked(sender:)), for: .touchUpInside)
        
        let textLabel = UILabel()
        cellView.addSubview(textLabel)
        textLabel.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(button.snp.bottom).offset(3)
            //            make.height.equalTo(cellHeight - cellWidth - 10)
        }
        textLabel.font = UIFont.systemFont(ofSize: 15)
        textLabel.text = text
        textLabel.textAlignment = .center
        textLabel.textColor = UIColor.gray
    }
    
    func makeBackView() {
        backView = UIView(frame: CGRect(x:0, y:-66, width:APP_SCREEN_WIDTH, height:APP_SCREEN_HEIGHT))
        backView.backgroundColor = UIColor.black
        backView.alpha = 0.3
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(cancelBtnClicked))
        backView.addGestureRecognizer(tap)
    }
    
    @objc func shareBtnClicked(sender:UIButton){
        shareURL = baseURL + "/pictureBookShare?" + "channel=" + String(channel) + "&id=" + String(id) + "&type=" + String(type)
        do {
            let imageData = try Data(contentsOf: URL(string: coverImg)!)
            let dict:[String: Any] = ["mImage": imageData,
                                      "mShareBody":"乐伴绘本，和宝宝一起爱上英语",
                                      "mTitle":title,
                                      "mLink": shareURL
            ]
            
            let shareModel = FWShareObject()
            shareModel.mImage = imageData
            shareModel.mShareBody = "乐伴绘本，和宝宝一起爱上英语"
            shareModel.mTitle = title
            shareModel.mLink = shareURL
            
            ShareManager.shareBtnClicked(with: .init(UInt(sender.tag)), dict: dict, success: { (data) in
                MBProgressHUD.ci_showTitle("分享成功", to: UIApplication.shared.keyWindow, hideAfter: 1.0)
                
            }, failure: { (tip) in
                MBProgressHUD.ci_showTitle(tip, to: UIApplication.shared.keyWindow, hideAfter: 1.0)
                
                if !self.coverShare {
                    self.delegate?.changeBtn()
                }
            })
            self.cancelBtnClicked()
        } catch {
            
        }
    }
    
    @objc func cancelBtnClicked() {
        removeFromSuperview()
        backView.removeFromSuperview()
    }
    
    func showAnimationWithView(_ parentView:UIView) {
        makeBackView()
        mWindow.addSubview(backView)
        mWindow.addSubview(self)
    }
}

