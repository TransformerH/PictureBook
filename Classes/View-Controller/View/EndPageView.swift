//
//  EndPageView.swift
//  demo3_pbDemo_scrollView
//
//  Created by 韩雪滢 on 28/01/2018.
//  Copyright © 2018 韩雪滢. All rights reserved.
//

import UIKit
import SnapKit
import Moya
import RxSwift
import AVFoundation
import SwiftyJSON
import FWPackager
import Then

protocol EndPageProtocol:class {
    func readAgainFromFirst() // MIX模式-跟读状态： 重新返回至绘本page1， 并设置为未跟读状态，之前的跟读录音文件清空
    func getFinishResult() -> Bool // MIX模式-跟读状态： 点击saveAndShare button时判断当前是否全部跟读完
    func showAlertVC(alertVC:UIViewController)// 显示AlertVC
    func shareBtnClick(recordID: Int) // 显示分享界面
    func readAllRecord() //MIX模式-跟读状态： 播放当前的跟读录音
}


class EndPageView: UIView, AVAudioPlayerDelegate, ShareViewProtocol, PageToEndPageProtocol{
    let APP_SCREEN_WIDTH = UIScreen.main.bounds.size.width
    let APP_SCREEN_HEIGHT = UIScreen.main.bounds.size.height
    let mDisposeBag = DisposeBag()
    
    var currentBundle:Bundle!
    weak var delegate:EndPageProtocol?
  
    
    var bookName:String!
    var bookID:String!
    var changePageRecord:[Bool]!
    var recordMP3Array:[String]!
    var recordCAFArray:[String]!
    var recordUploadURL:[String]!
    var uploadID:Int! = 0
    var bookCover:String {
        set {
            bookCoverVariable.value = newValue
        }
        get {
            return bookCoverVariable.value
        }
    }
    
    var bookCoverVariable = Variable("")
    
    var viewWidth:CGFloat!
    var viewHeight:CGFloat!
    
    
    lazy var endPageView = UIView().then { (endPageView) in
        self.addSubview(endPageView)
        endPageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(57 * PictureEnv.shared.mScreenRate.1)
            make.right.equalToSuperview().offset(-57 * PictureEnv.shared.mScreenRate.1)
            make.top.equalToSuperview().offset(36 * PictureEnv.shared.mScreenRate.0)
            make.bottom.equalToSuperview().offset(-70 * PictureEnv.shared.mScreenRate.0)
        }
        endPageView.backgroundColor = UIColor.clear
        
        endPageView.addSubview(self.mImageView)
        mImageView.snp.makeConstraints({(make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(self.viewHeight * CGFloat(PictureEnv.shared.mScreenRate.0) * 0.50)
        })

        endPageView.addSubview(endContentView)
        endContentView.snp.makeConstraints({(make) in
            make.top.equalTo(self.mImageView.snp.bottom).offset(30)
            make.left.right.bottom.equalToSuperview()
        })
        
    }
    lazy var mImageView = UIImageView().then { (image) in
        image.contentMode = UIViewContentMode.scaleAspectFill
        image.backgroundColor = UIColor.clear
        image.layer.borderColor = UIColor(red:238.0/255.0, green: 75.0/255.0, blue:80.0/255.0, alpha:1.0).cgColor
        image.layer.borderWidth = 2.0
        image.layer.cornerRadius = 8.0
        image.clipsToBounds = true
        
        bookCoverVariable.asObservable().subscribe(onNext: { [unowned self] (url) in
            image.kf.setImage(with: URL(string:url)!)
        }).disposed(by: mDisposeBag)
    }
    lazy var  endContentView = UIView().then { (endContentView) in
        endContentView.addSubview(bookNameLabel)
        bookNameLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(0)
            make.left.right.equalToSuperview()
            make.height.equalTo(30 * PictureEnv.shared.mScreenRate.0)
        }
        
        endContentView.addSubview(endImgView)
        endImgView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(50 * PictureEnv.shared.mScreenRate.1)
            make.right.equalToSuperview().offset(-50 * PictureEnv.shared.mScreenRate.1)
            //            make.top.equalToSuperview().offset(50 * PictureEnv.shared.mScreenRate.0)
            make.top.equalTo(bookNameLabel.snp.bottom).offset(10)
            make.height.equalTo(20)
        }
        let endImg = PictureBookTools.imageForResource(path: "—theend—", type: "png", bundle: currentBundle)
        endImgView.image = endImg
        
        endContentView.addSubview(saveAndShareBtn)
        saveAndShareBtn.snp.makeConstraints { (make) in
            make.width.equalTo(140 * PictureEnv.shared.mScreenRate.1)
            make.height.equalTo(50 * PictureEnv.shared.mScreenRate.0)
            make.centerX.equalToSuperview()
            make.top.equalTo(endImgView.snp.bottom).offset(20)
        }
    
        endContentView.addSubview(readAgainBtn)
        readAgainBtn.snp.makeConstraints({ (make) in
            make.left.equalToSuperview().offset(50 * PictureEnv.shared.mScreenRate.1)
            make.right.equalToSuperview().offset(-50 * PictureEnv.shared.mScreenRate.1)
            make.height.equalTo(20 * PictureEnv.shared.mScreenRate.0)
            make.top.equalTo(self.endImgView.snp.bottom).offset(90 * PictureEnv.shared.mScreenRate.0)
        })
        
        endContentView.addSubview(progressBtn)
        progressBtn.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
//            make.top.equalToSuperview().offset(70 * PictureEnv.shared.mScreenRate.0)
            make.top.equalTo(endImgView.snp.bottom).offset(20)
            make.width.height.equalTo(53 * PictureEnv.shared.mScreenRate.0)
        }
        progressBtn.isHidden = true
        
        endContentView.addSubview(uploadBtn)
        uploadBtn.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
//            make.top.equalToSuperview().offset(70 * PictureEnv.shared.mScreenRate.0)
            make.top.equalTo(endImgView.snp.bottom).offset(20)
            make.width.height.equalTo(50 * PictureEnv.shared.mScreenRate.0)
        }
        uploadBtn.isHidden = true
        
        endContentView.addSubview(shareOnlyBtn)
        shareOnlyBtn.snp.makeConstraints { (make) in
            make.width.equalTo(140 * PictureEnv.shared.mScreenRate.1)
            make.height.equalTo(50 * PictureEnv.shared.mScreenRate.0)
            make.centerX.equalToSuperview()
            make.top.equalTo(endImgView.snp.bottom).offset(20)
        }
        shareOnlyBtn.isHidden = true
    }
    lazy var bookNameLabel = UILabel().then { (bookNameLabel) in
        bookNameLabel.textAlignment = .center
        bookNameLabel.textColor = UIColor.black
        bookNameLabel.font = UIFont.systemFont(ofSize: 18)
        bookNameLabel.text = "<" + bookName + ">"
    }
    lazy var endImgView = UIImageView()
    
    lazy var progressBtn = ProgressBtnView()
   
    lazy var saveAndShareBtn = UIButton().then { (saveAndShareBtn) in
        saveAndShareBtn.layer.cornerRadius = CGFloat(25 * PictureEnv.shared.mScreenRate.0)
        saveAndShareBtn.backgroundColor = UIColor(red:253.0/255.0, green: 196.0/255.0, blue:37.0/255.0, alpha:1.0)
        saveAndShareBtn.setTitle("保存并分享", for: .normal)
        saveAndShareBtn.setTitleColor(UIColor(red:140.0/255.0, green: 79.0/255.0, blue:36.0/255.0, alpha:1.0), for: .normal)
        saveAndShareBtn.titleLabel?.textAlignment = .center
        saveAndShareBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        
        saveAndShareBtn.addTarget(self, action: #selector(saveAndShare), for: .touchUpInside)
    }
    
    lazy var shareOnlyBtn = UIButton().then { (shareOnlyBtn) in
        shareOnlyBtn.layer.cornerRadius = CGFloat(25 * PictureEnv.shared.mScreenRate.0)
        shareOnlyBtn.backgroundColor = UIColor(red:253.0/255.0, green: 196.0/255.0, blue:37.0/255.0, alpha:1.0)
        shareOnlyBtn.setTitle("分享", for: .normal)
        shareOnlyBtn.setTitleColor(UIColor(red:140.0/255.0, green: 79.0/255.0, blue:36.0/255.0, alpha:1.0), for: .normal)
        shareOnlyBtn.titleLabel?.textAlignment = .center
        shareOnlyBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        shareOnlyBtn.addTarget(self, action: #selector(shareRecord), for: .touchUpInside)
    }
    
    lazy var uploadBtn = UIButton().then { (uploadBtn) in
        let imgUpload = PictureBookTools.imageForResource(path: "upload", type: "png", bundle: currentBundle)
        uploadBtn.setImage(imgUpload, for: .normal)
        uploadBtn.imageView?.contentMode = .scaleAspectFit
        uploadBtn.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        uploadBtn.layer.cornerRadius = CGFloat(25)
    }
    
    lazy var playAllBtn = UIButton().then { (playAllBtn) in
        self.addSubview(playAllBtn)
        playAllBtn.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(self.viewHeight * CGFloat(PictureEnv.shared.mScreenRate.0) * 0.60 * 0.4)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(60 * PictureEnv.shared.mScreenRate.0)
        }
        playAllBtn.layer.cornerRadius = 20
        
        let imgAll = PictureBookTools.imageForResource(path: "playAllRecord", type: "png", bundle: currentBundle)
        playAllBtn.setImage(imgAll, for: .normal)
        playAllBtn.addTarget(self, action: #selector(playAllRecordClicked), for: .touchUpInside)
        playAllBtn.isHidden = true
    }
    lazy var readAgainBtn = UIButton().then { (readAgainBtn) in
        readAgainBtn.setTitle("再次跟读", for: .normal)
        readAgainBtn.setTitleColor(UIColor.black, for: .normal)
        readAgainBtn.titleLabel?.textAlignment = .center
        readAgainBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        readAgainBtn.addTarget(self, action: #selector(returnToFirst), for: .touchUpInside)
        readAgainBtn.isHidden = true
    }
    
    
    
    var tools:PictureBookTools!
    var pageViewModel:PageViewModel!
    var queuePlayer:AVQueuePlayer!
    var player:AVAudioPlayer!
    
    var endPageState = EndPageState.mix_notReadAll
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(frame:CGRect, dic:Dictionary<String, String>!, pageCount:Int){
        self.bookName = dic["bookName"]
        self.bookID = dic["bookID"]
        self.recordMP3Array = [String]()
        self.recordUploadURL = [String]()
        self.changePageRecord = Array<Bool>(repeating:false, count:pageCount)
        
        super.init(frame: frame)
        
        self.bookCover = dic["bookCover"]!
        self.currentBundle = Bundle(for: MainScrollViewController.self)
        self.backgroundColor = UIColor.clear
        self.viewWidth = self.frame.size.width
        self.viewHeight = self.frame.size.height
        tools = PictureBookTools()
        pageViewModel = PageViewModel()
        
        _ = self.endPageView
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        if saveAndShareBtn.isHidden {
            saveAndShareBtn.isHidden = false
        }
        switch endPageState {
        case .mix_notReadAll:
            break
        case .mix_readAll:
            makeAddComponents()
            break
        case .play:
            endImgView.isHidden = true
            
            saveAndShareBtn.setTitle("分享我的作品", for: .normal)
            saveAndShareBtn.isHidden = false
            readAgainBtn.isHidden = true
            break
        }
    }
    
    func makeAddComponents(){
        //从archive中得到record CAF
        let cafFileName = bookID + "_recordCAF.archive"
        recordCAFArray = Archive.unarchiveRecordCAFPathArray(fileName: cafFileName)
        
        var itemsArray = Array<AVPlayerItem>()
        for record in 0...recordCAFArray.count-1 {
            let fileURL = URL(fileURLWithPath:recordCAFArray[record])
            let playerItem = AVPlayerItem(url:fileURL)
            itemsArray.append(playerItem)
        }
        queuePlayer = AVQueuePlayer(items: itemsArray)
        
        playAllBtn.isHidden = false
        readAgainBtn.isHidden = false
    }
    
    
    @objc func playAllRecordClicked(){
        delegate?.readAllRecord()
    }
    
    @objc func returnToFirst() {
        if !shareOnlyBtn.isHidden {
            shareOnlyBtn.isHidden = true
        }
        if saveAndShareBtn.isHidden{
            saveAndShareBtn.isHidden = false
        }
        
        delegate?.readAgainFromFirst()
      
        let manager = FileManager.default
        let directory:URL = GetFileSystem.saveCAFDirectory
        let delectAllFileArray:[Any]? = manager.subpaths(atPath:directory.absoluteString)
        //删除bookID_bookName文件夹下的所有文件
        if delectAllFileArray != nil {
            for file in delectAllFileArray! {
                do {
                    try manager.removeItem(atPath: directory.absoluteString + "/\(file)")
                }catch let error as NSError {
                    print("删除录音文件夹中的文件错误：" + error.description)
                }
            }
        }
    }
    
    @objc func saveAndShare() {
        switch endPageState {
        case .mix_notReadAll, .mix_readAll:
            if (delegate?.getFinishResult())! {
                readAgainBtn.isEnabled = false
                // 重置button -> caf转为mp3 -> 上传MP3
                saveAndShareBtn.isHidden = true
                progressBtn.isHidden = false
                uploadBtn.isHidden = false
                transToMp3()
                uploadAudioMP3()
            } else {
                let alertController = UIAlertController(title: "有缺少录音的页面，再检查一下哦~", message:nil, preferredStyle:UIAlertControllerStyle.alert)
                let continueAction = UIAlertAction(title:"好的", style:.default) {
                    action in
                }
                alertController.addAction(continueAction)
                delegate?.showAlertVC(alertVC: alertController)
            }
            break
        case .play:
            PictureBookTools.printLog(message: bookID)
            self.delegate?.shareBtnClick(recordID: Int(bookID)!)
            break
        }
    }
    
    @objc func uploadAudioMP3(){
        
        var completed:Float = 0.0
        var uploadFinishedValue = Variable(0)
        let provider = MoyaProvider<PBAPI>()
        let recordCount = recordMP3Array.count
        let accountID = PictureEnv.shared.accountID
        let channelID = PictureEnv.shared.channelID
        let token = PictureEnv.shared.token
        let appkey = PictureEnv.shared.appkey
        
        recordUploadURL = Array(repeating:"", count: recordCount)
        
        for record in 0...recordCount-1 {
            
            print("uploadAudioMP3- url: \(recordMP3Array[record])")
            
            let data = NSData.init(contentsOfFile: recordMP3Array[record])
            provider.request(PBAPI.uploadAudio(channelID: channelID, accountID: accountID, token: token, audio:data! as Data, appkey: appkey), progress:{
                progress in
                completed = completed + Float(progress.progress) / Float(recordCount)
                self.setProgress(value: completed)
                
            },completion:{
                result in
                
                switch result {
                case let .success(response):
                    
                    let data_json = JSON(response.data)
                    let url = data_json["data"]["url"].stringValue
                    self.recordUploadURL[record] = url
                    PictureBookTools.printLog(message: "Index:\(record) \n uploadAudioMP3- url: \(self.recordMP3Array[record]) \n recordUploadURL: \(self.recordUploadURL[record])")
                    
                    
                    let stateCode = response.statusCode
                    if stateCode == 200 {
                        uploadFinishedValue.value = uploadFinishedValue.value + 1
                    }
                case .failure(_):
                    //将下载进度条设置为0
                    self.setProgress(value: 0)
                    let alertController = UIAlertController(title: "上传失败，请重新尝试。", message:nil, preferredStyle:UIAlertControllerStyle.alert)
                    let continueAction = UIAlertAction(title:"好的", style:.default) {
                        action in
                        self.uploadBtn.isHidden = true
                        self.progressBtn.isHidden = true
                        self.saveAndShareBtn.isHidden = false
                        self.setProgress(value: 0)
                        self.readAgainBtn.isEnabled = true
                    }
                    alertController.addAction(continueAction)
                    self.delegate?.showAlertVC(alertVC: alertController)
                }
            })
        }
        
        // 全部上传成功
        _ = uploadFinishedValue.asObservable().subscribe(onNext: { (num) in
            
            if num == recordCount {
                
                let recordURL = JSON(self.recordUploadURL)
                let jsonString = recordURL.rawString(String.Encoding.utf8, options: [])
                
                // 添加跟读记录
                provider.request(.addRecord(channelID: channelID, accountID: accountID, token: token, pictureBookID: self.bookID, audio: jsonString!, appkey: appkey)){[unowned self]
                    result in
                    
                    self.uploadBtn.isHidden = true
                    self.progressBtn.isHidden = true
                    self.saveAndShareBtn.isHidden = false
                    self.changeBtn()
                    self.setProgress(value: 0)
                    
                    if self.endPageState != .play {
                        self.readAgainBtn.isEnabled = true
                    }
                    
                    switch result {
                    case let .success(response):
                        
                        let data_json = JSON(response.data)
                        let id = data_json["data"].intValue
                        let ret = data_json["ret"].intValue
                       
                        
                        PictureBookTools.printLog(message: "ret: \(ret)")
                        
                        if ret == 1 {
                            PictureBookTools.printLog(message: "\(id)")
                            self.uploadID = id
                            self.delegate?.shareBtnClick(recordID: id)
                        } else {
                             let message = data_json["msg"].stringValue
                            let alertController = UIAlertController(title: message, message:nil, preferredStyle:UIAlertControllerStyle.alert)
                            let continueAction = UIAlertAction(title:"好的", style:.default) {
                                action in
                                self.shareOnlyBtn.isHidden = true
                                self.saveAndShareBtn.isHidden = false
                                self.setProgress(value: 0)
                                self.readAgainBtn.isEnabled = true
                            }
                            alertController.addAction(continueAction)
                            self.delegate?.showAlertVC(alertVC: alertController)
                        }
                    
                    case let .failure(error):
                        print("addRecord failure: \(error)")
                    }
                }
            }
        }, onError: nil, onCompleted: nil, onDisposed: nil)
    }

    @objc func shareRecord() {
        print("shareRecord: \(uploadID)")
        self.delegate?.shareBtnClick(recordID: uploadID)
    }
    
    //设置上传进度
    func setProgress(value:Float){
        progressBtn.progress = value
    }
    
    // caf转为MP3
    func transToMp3() {
        //创建MP3文件夹
        let directory:URL = GetFileSystem.saveMP3Directory
        
        let manager = FileManager.default
        do{
            if !manager.fileExists(atPath: directory.absoluteString) {
                try manager.createDirectory(atPath: directory.absoluteString, withIntermediateDirectories: true, attributes: nil)
            }
        } catch let error as NSError {
            print("创建upload MP3文件夹失败：" + error.description)
        }
        
        let cafFileName = bookID + "_recordCAF.archive"
        recordCAFArray = Archive.unarchiveRecordCAFPathArray(fileName: cafFileName)
        
        //OC class
        for record in 0...recordCAFArray.count-1 {
            let cafPath = recordCAFArray[record]
            let mp3FileName = bookID + "_" + String(record) + ".mp3"
            let mp3FilePath = directory.appendingPathComponent(mp3FileName)

            let _ = LameManager().audioCAFtoMP3(cafPath, mp3Path: mp3FilePath.absoluteString)
            recordMP3Array.append(mp3FilePath.absoluteString)
        }
        //将转换后的mp3存入archive
        let mp3FileName = bookID + "_recordMP3.archive"
        Archive.archiveRecordMP3PathArray(fileName: mp3FileName, mp3Array: recordMP3Array)
    }
    
    
    // MARK: -- shareViewProtocol
    func changeBtn() {
        saveAndShareBtn.isHidden = true
        shareOnlyBtn.isHidden = false
        self.recordMP3Array = [String]()
        
    }
    
    
    // MARK: -- PageToEndPageProtocol
    func changeRecordState(page: Int, change: Bool) {
        changePageRecord[page] = change
        
        var changeBtnState = false
        for page in 0...changePageRecord.count - 1 {
            if changePageRecord[page] {
                changeBtnState = true
            }
        }
        
        if changeBtnState {
            if !shareOnlyBtn.isHidden {
                shareOnlyBtn.isHidden = true
            }
            
            if saveAndShareBtn.isHidden {
                saveAndShareBtn.isHidden = false
            }
        }
    }
}
