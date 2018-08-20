//
//  CoverViewController.swift
//  demo3_pbDemo_scrollView
//
//  Created by 韩雪滢 on 25/01/2018.
//  Copyright © 2018 韩雪滢. All rights reserved.
//

import UIKit
import Moya
import SwiftyJSON
import RxSwift
import Kingfisher
import RxCocoa
import CIProgressHUD
import Then
import BackButtonHandler

protocol CoverProtocol:class {
    func coverShowMessage(sender:CoverViewController, showMessage:Bool)
}


public class CoverViewController: UIViewController {
    
    let mDisposeBag = DisposeBag()
    
    var currentBundle:Bundle!
    weak var delegate:CoverProtocol?
    
    let commonColor = UIColor(red:244.0/255.0, green: 100.0/255.0, blue:99.0/255.0, alpha:1.0)
    var viewWidth:CGFloat!
    var viewHeight:CGFloat!
    var listenAll:Bool!  //MIX模式-播放状态： 是否全部播放 -> 显示分享button和label
    var listenRecordMode:Bool! // MIX模式 or PLAY模式
    var idType:String!
    var shareView:ShareView!
    
    let coverViewModel = CoverViewModel()
    let pageViewModel = PageViewModel()
    var pageInfoArray:[[String:String]]!
    var audioDicArray = [[String:String]]()
    var uploadURLArray:[String]!

    var coverView:UIImageView!
    var controlView:UIView!
    var downLoadView:UIView!
    
    var backBtn:UIButton!
    var shareBtn:UIButton!
    var downloadBtn:UIButton!
    var progressBtn:ProgressBtnView!
    var listenBtn:UIButton!
    var speakBtn:UIButton!
    
    var readAllLabel:UILabel!

    
    ///
    ///
    /// - Parameters:
    ///   - bookID: 绘本ID
    ///   - bookName: 绘本名称
    ///   - idType: 0表示id为绘本ID，1表示id为跟读记录id
    ///   - mode: “PLAY”代表仅播放模式，不能进行跟读。“MIX”代表可以进行播放和跟读
    public convenience init( bookID: String, idType: String, mode: String) {
        self.init()
        self.pageViewModel.mBookID = bookID
        self.idType = idType
        
        self.pageViewModel.mPictureMode = (mode == "PLAY") ? .play : .mix
        self.listenRecordMode = (mode == "PLAY") ? true : false
        if mode == "PLAY" {
            self.pageViewModel.mPictureMode = .play
            self.listenRecordMode = true
        } else if mode == "MIX" {
            self.pageViewModel.mPictureMode = .mix
            self.listenRecordMode = false
        }
    }
    
    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    //在ViewDidLoad中获取page的数据
    //在点击下载button时对plistenModelageInfoArray进行复制，并下载所有的音频
    //下载后移除下载button, 显示播放和录音button
    override public func viewDidLoad() {
        super.viewDidLoad()
        // 设置 阻止自动锁屏
        UIApplication.shared.isIdleTimerDisabled = true
        if (!PictureEnv.shared.setEnv) {
            print("请先设置环境变量")
            return
        }
        listenAll = false
        
        self.currentBundle = Bundle(for: MainScrollViewController.self)
        
        view.backgroundColor = UIColor.white
        self.viewWidth = self.view.frame.size.width
        self.viewHeight = self.view.frame.size.height
        self.edgesForExtendedLayout  = []
        
        MBProgressHUD.ci_showAdded(to: self.view, title: "正在加载...")
        
        let subscribe: Observable<JSON> = listenRecordMode ? pageViewModel.getBookWithRecord() : pageViewModel.getPictureBookDetail()
        let isListenMode:Bool = listenRecordMode ? true : false
        subscribe.subscribe {[unowned self] (event) in
            MBProgressHUD.hide(for: self.view, animated: true)
            switch event {
            case .next(_):
                if self.coverViewModel.isDownloadAudio(mBookID: self.pageViewModel.mBookID, mode: self.idType) {
                    print("File exists")
                    self.makeControlView(isListenMode: isListenMode)
                } else {
                    print("File does not exist")
                    self.makeDownLoadView()
                }
                break
            case .error(let err):
                if case let PicError.api(msg: message) = err {
                    MBProgressHUD.ci_showTitle(message, to: self.view, hideAfter: 1.0)
                }
                break
            default:break
            }
            }.disposed(by: mDisposeBag)
        makeCoverView()
    }
    
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        makeReadAllView(isReadAll: listenAll)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    func makeCoverView(){
        self.coverView = UIImageView()
        self.coverView.backgroundColor = UIColor.clear
        self.coverView.layer.borderColor = UIColor(red:238.0/255.0, green: 75.0/255.0, blue:80.0/255.0, alpha:1.0).cgColor
        self.coverView.layer.borderWidth = 2.0
        self.coverView.layer.cornerRadius = 10.0
        self.coverView.clipsToBounds = true
        self.coverView.contentMode = UIViewContentMode.scaleAspectFill
        self.view.addSubview(self.coverView)
        self.coverView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(20.0 * PictureEnv.shared.mScreenRate.0)
            make.height.equalTo(self.viewHeight * 0.54 * CGFloat(PictureEnv.shared.mScreenRate.0))
            make.left.equalToSuperview().offset(57 * PictureEnv.shared.mScreenRate.1)
            make.right.equalToSuperview().offset(-57 * PictureEnv.shared.mScreenRate.1)
        }
        
        pageViewModel.mCoverVariabel.asObservable().subscribe(onNext: {[unowned self] (url) in
            self.coverView.kf.setImage(with: url)
        }).disposed(by: mDisposeBag)
        
        readAllLabel = UILabel()
        view.addSubview(readAllLabel)
        readAllLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.viewHeight * 0.6 * CGFloat(PictureEnv.shared.mScreenRate.0))
            make.left.equalToSuperview().offset(57 * PictureEnv.shared.mScreenRate.1)
            make.right.equalToSuperview().offset(-57 * PictureEnv.shared.mScreenRate.1)
            make.height.equalTo(30 * PictureEnv.shared.mScreenRate.0)
        }
        readAllLabel.textAlignment = .center
        
        pageViewModel.mBookNameVariable.asObservable().subscribe(onNext:{[unowned self] (bookName) in
            self.readAllLabel.text = "<" + bookName + ">"
        }).disposed(by: mDisposeBag)
        
        readAllLabel.font = UIFont.systemFont(ofSize: 16)
        readAllLabel.textColor = UIColor.black
        readAllLabel.backgroundColor = UIColor.clear
    }
    
    func makeReadAllView(isReadAll:Bool){
        if isReadAll {
            readAllLabel.text = "<" + self.pageViewModel.mBookName + ">" + "读完了！"
            
            let negativeSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            negativeSpacer.width = 12
            shareBtn = UIButton.init(type: .custom)
            shareBtn.frame = CGRect(x:0, y:0, width:44, height:44)
            let imgShare = PictureBookTools.imageForResource(path: "shareImg1", type: "png", bundle: currentBundle)
            shareBtn.setImage(imgShare, for: .normal)
            
            let rightItem = UIBarButtonItem(customView:shareBtn)
            navigationItem.rightBarButtonItems = [negativeSpacer, rightItem]
            shareBtn.addTarget(self, action: #selector(shareBtnClicked), for: .touchUpInside)
        } else {
            if shareBtn != nil {
                readAllLabel.removeFromSuperview()
                navigationItem.rightBarButtonItems?.removeAll()
            }
        }
        
    }
    
    @objc func shareBtnClicked() {
        if shareView == nil {
            coverShareBtnClick(recordID: 0)
        } else {
            shareView.cancelBtnClicked()
            shareView = nil
        }
    }
    
    
    func coverShareBtnClick(recordID: Int) {
        let shareDic = self.coverViewModel.makeShareDic(mBookID: self.pageViewModel.mBookID)

        shareView = ShareView(frame: CGRect(x:0, y: 0, width: UIScreen.main.bounds.size.width, height: 0), dic: shareDic)
        shareView.coverShare = true
        
        shareView.showAnimationWithView(self.view)
        shareView.snp.makeConstraints { (make) in
            make.height.equalTo(190)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(UIApplication.shared.keyWindow!).offset(PictureBookTools.isIphoneX() ? -34 : 0)
        }
    }
    
    //listenBtn, speakBtn
    func makeControlView(isListenMode:Bool){
        controlView = UIView()
        view.addSubview(controlView)
        
        var bottomOffset = -80.0
        if PictureBookTools.isIphoneX() {
            bottomOffset = -200.0
        }
        controlView.snp.makeConstraints { (make) in
            make.height.equalTo(80)
            make.bottom.equalToSuperview().offset(bottomOffset * PictureEnv.shared.mScreenRate.0)
            make.left.equalToSuperview().offset(57 * PictureEnv.shared.mScreenRate.1)
            make.right.equalToSuperview().offset(-57 * PictureEnv.shared.mScreenRate.1)
        }
        controlView.backgroundColor = UIColor.clear
        
        makelistenBtn(isListenMode: isListenMode)
        if !isListenMode {
            makeSpeakBtn()
        }
    }
    
    func makelistenBtn(isListenMode:Bool) {
        listenBtn = UIButton()
        controlView.addSubview(listenBtn)
        
        let img1 = PictureBookTools.imageForResource(path: "playingOrigin", type: "png", bundle: currentBundle)
        listenBtn.setImage(img1, for: .normal)
        listenBtn.addTarget(self, action: #selector(listenBtnClicked), for: .touchUpInside)
        
        let listenLabel = UILabel()
        controlView.addSubview(listenLabel)
        listenLabel.text = "播放"
        listenLabel.textAlignment = .center
        listenLabel.textColor = UIColor.black
        listenLabel.font = UIFont.init(name: "Arial", size: 14)
        
        listenBtn.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            if !isListenMode{
                make.left.equalToSuperview()
            }else{
                make.centerX.equalToSuperview()
            }
            make.height.width.equalTo(55)
        }
        listenBtn.layer.cornerRadius = 55/2
        
        listenLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.width.equalTo(50)
            make.height.equalTo(20)
            if !isListenMode {
                make.left.equalToSuperview()
            } else {
                make.centerX.equalToSuperview()
            }
        }
        
    }
    
    func makeSpeakBtn() {
        speakBtn = UIButton()
        controlView.addSubview(speakBtn)
        speakBtn.snp.makeConstraints { (make) in
            make.top.right.equalToSuperview()
            make.height.width.equalTo(55)
        }
        speakBtn.layer.cornerRadius = 55/2
        
        let img2 = PictureBookTools.imageForResource(path: "recording", type: "png", bundle: currentBundle)
        speakBtn.setImage(img2, for: .normal)
        speakBtn.addTarget(self, action: #selector(speakBtnClicked), for: .touchUpInside)
        
        let speakLabel = UILabel()
        controlView.addSubview(speakLabel)
        speakLabel.snp.makeConstraints { (make) in
            make.bottom.right.equalToSuperview()
            make.width.equalTo(50)
            make.height.equalTo(20)
        }
        speakLabel.text = "跟读"
        speakLabel.textAlignment = .center
        speakLabel.textColor = UIColor.black
        speakLabel.font = UIFont.init(name: "Arial", size: 14)
    }
    
    func makeDownLoadView(){
        downLoadView = UIView()
        view.addSubview(downLoadView)
        
        var bottomOffset = -80.0
        if PictureBookTools.isIphoneX() {
            bottomOffset = -200.0
        }
        downLoadView.snp.makeConstraints { (make) in
            make.height.equalTo(80)
            make.bottom.equalToSuperview().offset(bottomOffset * PictureEnv.shared.mScreenRate.0)
            make.left.equalToSuperview().offset(57 * PictureEnv.shared.mScreenRate.1)
            make.right.equalToSuperview().offset(-57 * PictureEnv.shared.mScreenRate.1)
        }
        downLoadView.backgroundColor = UIColor.clear
        
        progressBtn = ProgressBtnView()
        downLoadView.addSubview(progressBtn)
        progressBtn.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(58)
        }
        
        downloadBtn = UIButton()
        let img = PictureBookTools.imageForResource(path: "download", type: "png", bundle: currentBundle)
        downloadBtn.setImage(img, for: .normal)
        downloadBtn.layer.cornerRadius = 55/2
        downloadBtn.addTarget(self, action: #selector(downloadBtnClicked), for: .touchUpInside)
        downLoadView.addSubview(downloadBtn)
        downloadBtn.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(55)
        }
    }
    
    @objc func backBtnClicked(){
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @objc func listenBtnClicked(){
        self.audioDicArray = self.audioDicArray.isEmpty ? self.coverViewModel.buildAudioInfoDic(pageViewModel: self.pageViewModel, listenRecordMode: self.listenRecordMode) : self.audioDicArray
        self.coverViewModel.buildCoverInfoDic(pageViewModel:self.pageViewModel)
        let pageState =  self.listenRecordMode ? PageState.play : PageState.mix_play
        let mainScrollVC = MainScrollViewController.init(pageViewModel.mBookID, coverVC: self, pageState: pageState)
        mainScrollVC.readType = ReadType.origin
        self.navigationController?.pushViewController(mainScrollVC, animated: true)
    }
    
    @objc func speakBtnClicked(){
        self.audioDicArray = self.audioDicArray.isEmpty ? self.coverViewModel.buildAudioInfoDic(pageViewModel: self.pageViewModel, listenRecordMode: self.listenRecordMode) : self.audioDicArray
        self.coverViewModel.buildCoverInfoDic(pageViewModel:self.pageViewModel)
        let mainScrollVC = MainScrollViewController.init(pageViewModel.mBookID, coverVC: self, pageState: PageState.mix_read)
        mainScrollVC.readType = ReadType.follow
        self.navigationController?.pushViewController(mainScrollVC, animated: true)
    }
    
    @objc func downloadBtnClicked(){
        let img = PictureBookTools.imageForResource(path: "downloading", type: "png", bundle: currentBundle)
        downloadBtn.setImage(img, for: .normal)
        self.audioDicArray = self.audioDicArray.isEmpty ? self.coverViewModel.buildAudioInfoDic(pageViewModel: self.pageViewModel, listenRecordMode: self.listenRecordMode) : self.audioDicArray
        
        //下载失败再点击  或  未下载
        if !self.coverViewModel.ifDownloadSuccess(audioDicArray:audioDicArray) {
            self.coverViewModel.downloadAllAudio(vc: self)
            setProgress(value: 0)
        }
    }
   
    func setProgress(value:Float){
        progressBtn.progress = value
        print(value)
    }
    
    public override func navigationShouldPopOnBackButton() -> Bool {
        self.backBtnClicked()
        return false
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


