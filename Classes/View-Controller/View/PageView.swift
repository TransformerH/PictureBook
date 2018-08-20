//
//  PageView.swift
//  demo3_pbDemo_scrollView
//
//  Created by 韩雪滢 on 20/01/2018.
//  Copyright © 2018 韩雪滢. All rights reserved.
//

/*  important
 pageID 从0开始
 */

import UIKit
import SnapKit
import AVFoundation
import RxSwift
import RxCocoa
import Then

enum SpeakButtons {
    enum recordBtn {
        case recording
        case stop
    }
    
    enum playOriginBtn {
        case play
        case stop
    }
    
    enum playRecordBtn {
        case disable
        case play
        case stop
    }
}

enum ListenButton {
    case play
    case stop
}

// MainScrollView 实现的代理方法
protocol PageViewProtocol: class {
    func setFinishRecord(index:Int, finish:Bool) // MIX模式-跟读状态： 设置当前page是否完成跟读
    func setScrollEnable(enable:Bool) // MIX模式-跟读状态: 录音时不能滑动
    func toNextPage() // 2秒延时，自动滑动至下一页
}

// EndPageView 实现的代理方法
protocol PageToEndPageProtocol:class {
    func changeRecordState(page:Int, change:Bool) // MIX模式-跟读状态: 判断当前page的录音是否重新录音 -> 更改endPageView saveAndShare button的状态
}

class PageView: UIView, AVAudioRecorderDelegate, AVAudioPlayerDelegate{
    
    var currentBundle:Bundle!
    weak var delegate:PageViewProtocol?
    weak var endPageDelegate:PageToEndPageProtocol?
    
    let commonColor =  UIColor(red:244.0/255.0, green: 100.0/255.0, blue:99.0/255.0, alpha:1.0)
    let mDisposeBag = DisposeBag()
    
    var viewWidth:CGFloat!
    var viewHeight:CGFloat!
    
    // infoDic = bookName + bookID + pageID(page数组的index) + 文本(words) + 原音文件路径(originFile) + 图片(imgUrl) + 录音文件路径(recordFile) + pageIndex(String)
    var infoDic: NSDictionary!
    var recordAndPlay:Recording!
    var tools:PictureBookTools!
    
    var bookName:String!
    var bookID:String!
    var pageIndex:String!
    var recordFile:URL!
    var originFile:URL!
    var words:String!
    var imgUrl:String {
        set {
            imgUrlVariable.value = newValue
        }
        get {
            return imgUrlVariable.value
        }
    }
    var pageID:Int!
    
    var imgUrlVariable = Variable("")
    
    var ifListeningControlView:Bool!
    
    var speakRecordBtnState = SpeakButtons.recordBtn.stop
    var speakPlayRecordBtnState = SpeakButtons.playRecordBtn.disable
    var speakPlayOriginBtnState = SpeakButtons.playOriginBtn.stop
    var listenPlayBtnState = ListenButton.stop
    
    lazy var contentView = UIView().then { (contentView) in
        self.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(57 * PictureEnv.shared.mScreenRate.1)
            make.right.equalToSuperview().offset(-57 * PictureEnv.shared.mScreenRate.1)
            make.top.equalToSuperview().offset(36 * PictureEnv.shared.mScreenRate.0)
            make.height.equalTo(viewHeight * 0.67 * CGFloat(PictureEnv.shared.mScreenRate.0))
        }
        contentView.backgroundColor = UIColor.white
        
        
        contentView.addSubview(image)
        image.snp.makeConstraints({(make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(self.viewHeight * 0.50 * CGFloat(PictureEnv.shared.mScreenRate.0))
        })
        
        imgUrlVariable.asObservable().subscribe(onNext: { [unowned self] (url) in
            self.image.kf.setImage(with: URL(string:url)!)
        }).disposed(by: mDisposeBag)
        
        contentView.addSubview(content)
        content.snp.makeConstraints({(make) in
            make.height.equalTo(80)
            make.left.right.bottom.equalToSuperview()
        })
    }
    
    lazy var image = UIImageView().then { (image) in
        image.contentMode = UIViewContentMode.scaleAspectFit
        image.backgroundColor = UIColor.white
        image.layer.borderColor = UIColor(red:238.0/255.0, green: 75.0/255.0, blue:80.0/255.0, alpha:1.0).cgColor
        image.layer.borderWidth = 2.0
        image.layer.cornerRadius = 8.0
        image.clipsToBounds = true
    }
    
    lazy var content = UITextView().then { (content) in
        content.backgroundColor = UIColor.white
        content.isEditable = false
        content.text = words
        content.textAlignment = .center
        content.textColor = UIColor(red:59.0/255.0, green: 59.0/255.0, blue:59.0/255.0, alpha:1.0)
        content.font = UIFont.systemFont(ofSize: 20)
        content.showsVerticalScrollIndicator = true
    }
    
    // MIX模式-播放状态 或 录音状态的听当前录音 /PLAY模式
    lazy var listeningControlView = UIView().then { (listeningControlView) in
        addSubview(listeningControlView)
        listeningControlView.snp.makeConstraints { (make) in
            //            make.top.equalToSuperview().offset(viewHeight * 0.70 * CGFloat(PictureEnv.shared.mScreenRate.0) + 30)
            make.top.equalTo(contentView.snp.bottom).offset(30)
            make.left.equalToSuperview().offset(57 * PictureEnv.shared.mScreenRate.1)
            make.right.equalToSuperview().offset(-57 * PictureEnv.shared.mScreenRate.1)
            make.height.equalTo(50 * PictureEnv.shared.mScreenRate.0)
        }
        
        listeningControlView.addSubview(listeningPlayOriginBtn)
        listeningPlayOriginBtn.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(50)
        }
    }
    
    lazy var listeningPlayOriginBtn = UIButton().then { (listeningPlayOriginBtn) in
        listeningPlayOriginBtn.layer.cornerRadius = 50 / 2
        
        let imgO = PictureBookTools.imageForResource(path: "playingOrigin", type: "png", bundle: currentBundle)
        if imgO != nil {
            listeningPlayOriginBtn.setImage(imgO, for: .normal)
        } else {
            print("back_Item lost")
        }
        
        listeningPlayOriginBtn.addTarget(self, action: #selector(listeningBtnClicked), for: .touchUpInside)
    }
    
    //MIX模式-跟读状态
    lazy var speakingControlView = UIView().then { (speakingControlView) in
        addSubview(speakingControlView)
        speakingControlView.snp.makeConstraints { (make) in
            make.top.equalTo(contentView.snp.bottom).offset(30)
            make.left.equalToSuperview().offset(57 * PictureEnv.shared.mScreenRate.1)
            make.right.equalToSuperview().offset(-57 * PictureEnv.shared.mScreenRate.1)
            make.height.equalTo(50)
        }
        
        speakingControlView.addSubview(speakingPlayOriginBtn)
        speakingPlayOriginBtn.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.height.equalTo(30)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        
        speakingControlView.addSubview(speakingRecordBtn)
        speakingRecordBtn.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(50)
        }
        
        speakingControlView.addSubview(speakingPlayRecordBtn)
        speakingPlayRecordBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.width.height.equalTo(30)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
    }
    
    lazy var speakingPlayOriginBtn = UIButton().then { (speakingPlayOriginBtn) in
        speakingPlayOriginBtn.layer.cornerRadius = 30 / 2
        
        let imgO = PictureBookTools.imageForResource(path: "finishPlayOrigin", type: "png", bundle: currentBundle)
        if imgO != nil {
            speakingPlayOriginBtn.setImage(imgO, for: .normal)
        } else {
            print("back_Item lost")
        }
        
        speakingPlayOriginBtn.addTarget(self, action: #selector(speakingPlayOriginBtnClicked), for: .touchUpInside)
    }
    
    lazy var speakingRecordBtn = UIButton().then { (speakingRecordBtn) in
        
        speakingRecordBtn.layer.cornerRadius = 50 / 2
        let imgR = PictureBookTools.imageForResource(path: "beforeRecord", type: "png", bundle: currentBundle)
        if imgR != nil {
            speakingRecordBtn.setImage(imgR, for: .normal)
        } else {
            print("beforeRecord lost")
        }
        
        speakingRecordBtn.addTarget(self, action: #selector(speakingRecordBtnClicked), for: .touchUpInside)
    }
    lazy var speakingPlayRecordBtn = UIButton().then { (speakingPlayRecordBtn) in
        
        speakingPlayRecordBtn.layer.cornerRadius = 30 / 2
        
        let imgPR = PictureBookTools.imageForResource(path: "enablePlayRecord", type: "png", bundle: currentBundle)
        if imgPR != nil {
            speakingPlayRecordBtn.setImage(imgPR, for: .normal)
        } else {
            print("beforeRecord lost")
        }
        
        //初始化不能播放
        speakingPlayRecordBtn.isEnabled = false
        speakingPlayRecordBtn.addTarget(self, action: #selector(speakingPlayRecordBtnClicked), for: .touchUpInside)
    }
    
    var recordGifImg:UIImageView!
    var listenGifImg:UIImageView!
    var listen_listenGifImg:UIImageView!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
    }
    
    init(frame:CGRect,dic:Dictionary<String, Any>!, ifListen:Bool){
        
        //给子类的参数赋值时，要在super.init之前
        self.bookName = dic["bookName"] as! String
        self.bookID = dic["bookID"] as! String
        self.pageIndex = dic["pageIndex"] as! String
        self.pageID = dic["pageID"] as! Int
        self.words = dic["words"] as! String
        self.originFile = dic["originFile"] as! URL
        self.recordFile = dic["recordFile"] as! URL
        self.ifListeningControlView = ifListen
        
        super.init(frame:frame)
        self.backgroundColor = UIColor.white
        self.viewWidth = self.frame.size.width
        self.viewHeight = self.frame.size.height
        self.imgUrl = dic["imgUrl"] as! String
        
        self.currentBundle = Bundle(for: PageView.self)
        print("\n originFile\(originFile)")
        
        //初始化recoder, player
        setPlayerAndRecoderBy(pageViewState: 0)
        
        tools = PictureBookTools()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        
        print("UIView drawed")
        _ = speakingControlView
        _ = listeningControlView
        
        if ifListeningControlView{
            speakingControlView.isHidden = true
        } else {
            listeningControlView.isHidden = true
        }
        
    }
    
    func setSpeakRecordBtnBy(state:SpeakButtons.recordBtn) {
        switch state {
        case .recording:
            speakRecordBtnState = .recording
            if speakPlayRecordBtnState == .play {
                setSpeakPlayRecordBtnBy(state: .stop)
            }
            
            recordAndPlay.audioRecorder.record()
            recordGifImg = UIImageView()
            speakingRecordBtn.addSubview(recordGifImg)
            recordGifImg.snp.makeConstraints({ (make) in
                make.width.height.equalToSuperview()
                make.center.equalToSuperview()
            })
            
            // 录音时的gif效果
            let recordinggif1 = PictureBookTools.imageForResource(path: "recordinggif1", type: "png", bundle: currentBundle)
            let recordinggif2 = PictureBookTools.imageForResource(path: "recordinggif2", type: "png", bundle: currentBundle)
            let recordinggif3 = PictureBookTools.imageForResource(path: "recordinggif3", type: "png", bundle: currentBundle)
            recordGifImg.animationImages = [recordinggif1!, recordinggif2!, recordinggif3!]
            recordGifImg.animationDuration = 1.0
            recordGifImg.startAnimating()
            
            //正在录音，禁用滑动scrollView
            delegate?.setScrollEnable(enable: false)
            speakingPlayOriginBtn.isEnabled = false
            speakingPlayRecordBtn.isEnabled = false
            
            //设置当前页面已录音
            delegate?.setFinishRecord(index: pageID, finish: true)
            
            break
        case .stop:
            speakRecordBtnState = .stop
            if speakPlayRecordBtnState == .stop {
                endPageDelegate?.changeRecordState(page: pageID, change: true)
            } else if speakPlayRecordBtnState == .disable {
                endPageDelegate?.changeRecordState(page: pageID, change: false)
            }
            recordAndPlay.audioRecorder.stop()
            
            //停止录音，启用滑动scrollView
            delegate?.setScrollEnable(enable: true)
            
            //移除录音时的gif效果
            if recordGifImg != nil {
                recordGifImg.removeFromSuperview()
            }
            let imgSR1 = PictureBookTools.imageForResource(path: "beforeRecord", type: "png", bundle: currentBundle)
            speakingRecordBtn.setImage(imgSR1, for: .normal)
            speakingPlayOriginBtn.isEnabled = true
            speakingPlayRecordBtn.isEnabled = true
            
            //初始化 recordAndPlay.recordPlayer
            do {
                recordAndPlay.recordPlayer = try AVAudioPlayer(contentsOf:recordFile)
                recordAndPlay.recordPlayer.delegate = self
                recordAndPlay.recordPlayer.volume = 1.0
                setSpeakPlayRecordBtnBy(state: .stop)
            } catch let err{
                print("初始化recordPlayer失败：\(err.localizedDescription)")
            }
            break
        }
    }
    
    func setSpeakPlayRecordBtnBy(state:SpeakButtons.playRecordBtn) {
        switch state {
        case .disable:
            speakPlayRecordBtnState = .disable
            let imgPR = PictureBookTools.imageForResource(path: "enablePlayRecord", type: "png", bundle: currentBundle)
            speakingPlayRecordBtn.setImage(imgPR, for: .normal)
            speakingPlayRecordBtn.isEnabled = false
            break
        case .play:
            speakPlayRecordBtnState = .play
            setSpeakPlayOriginBtnBy(state: .stop)
            recordAndPlay.recordPlayer.currentTime = 0.0
            recordAndPlay.recordPlayer.play()
            let img1 = PictureBookTools.imageForResource(path: "playingRecord", type: "png", bundle: currentBundle)
            speakingPlayRecordBtn.setImage(img1, for: .normal)
            break
        case .stop:
            speakPlayRecordBtnState = .stop
            speakingPlayRecordBtn.isEnabled = true
            recordAndPlay.recordPlayer.stop()
            let imgSR2 = PictureBookTools.imageForResource(path: "ablePlayRecord", type: "png", bundle: currentBundle)
            speakingPlayRecordBtn.setImage(imgSR2, for: .normal)
            break
        }
    }
    
    func setSpeakPlayOriginBtnBy(state:SpeakButtons.playOriginBtn) {
        switch state {
        case .play:
            if speakRecordBtnState != .recording {
                speakPlayOriginBtnState = .play
                
                if speakPlayRecordBtnState == .play {
                    setSpeakPlayRecordBtnBy(state: .stop)
                }
                recordAndPlay.originPlayer.currentTime = 0.0
                recordAndPlay.originPlayer.play()
                listenGifImg = UIImageView()
                speakingPlayOriginBtn.addSubview(listenGifImg)
                listenGifImg.snp.makeConstraints({ (make) in
                    make.width.height.equalToSuperview()
                    make.center.equalToSuperview()
                })
                let listeninggif1 = PictureBookTools.imageForResource(path: "listeninggif1", type: "png", bundle: currentBundle)
                let listeninggif2 = PictureBookTools.imageForResource(path: "listeninggif2", type: "png", bundle: currentBundle)
                let listeninggif3 = PictureBookTools.imageForResource(path: "listeninggif3", type: "png", bundle: currentBundle)
                listenGifImg.animationImages = [listeninggif1!, listeninggif2!, listeninggif3!]
                listenGifImg.animationDuration = 1.0
                listenGifImg.startAnimating()
            }
            break
        case .stop:
            speakPlayOriginBtnState = .stop
            
            recordAndPlay.originPlayer.stop()
            if listenGifImg != nil {
                listenGifImg.removeFromSuperview()
            }
            let imgO = PictureBookTools.imageForResource(path: "finishPlayOrigin", type: "png", bundle: currentBundle)
            speakingPlayOriginBtn.setImage(imgO, for: .normal)
            break
        }
    }
    
    func setListenPlayBtnBy(state:ListenButton) {
        switch state {
        case .play:
            listenPlayBtnState = .play
            recordAndPlay.originPlayer.currentTime = 0.0
            recordAndPlay.originPlayer.play()
            listenGifImg = UIImageView()
            listeningPlayOriginBtn.addSubview(listenGifImg)
            listenGifImg.snp.makeConstraints({ (make) in
                make.width.height.equalToSuperview()
                make.center.equalToSuperview()
            })
            let listeninggif1 = PictureBookTools.imageForResource(path: "listen_listeninggif1", type: "png", bundle: currentBundle)
            let listeninggif2 = PictureBookTools.imageForResource(path: "listen_listeninggif2", type: "png", bundle: currentBundle)
            let listeninggif3 = PictureBookTools.imageForResource(path: "listen_listeninggif3", type: "png", bundle: currentBundle)
            listenGifImg.animationImages = [listeninggif1!, listeninggif2!, listeninggif3!]
            listenGifImg.animationDuration = 1.0
            listenGifImg.startAnimating()
            break
        case .stop:
            listenPlayBtnState = .stop
            recordAndPlay.originPlayer.stop()
            if listenGifImg != nil {
                listenGifImg.removeFromSuperview()
            }
            let imgO = PictureBookTools.imageForResource(path: "finishPlay", type: "png", bundle: currentBundle)
            listeningPlayOriginBtn.setImage(imgO, for: .normal)
            break
        }
    }
    
    
    //播放原音时，如果正在录音则停止录音,正在播放录音则停止播放
    @objc func speakingPlayOriginBtnClicked(){
        switch speakPlayOriginBtnState {
        case .play:
            setSpeakPlayOriginBtnBy(state: .stop)
            break
        case .stop:
            setSpeakPlayOriginBtnBy(state: .play)
            break
        }
    }
    
    // 录音button的点击事件
    @objc func speakingRecordBtnClicked() {
        switch speakRecordBtnState {
        case .recording:
            setSpeakRecordBtnBy(state: .stop)
            break
        case .stop:
            if self.speakPlayOriginBtnState == .play {
                self.setSpeakPlayOriginBtnBy(state: .stop)
                PictureBookTools.delay(0.1){
                    self.setSpeakRecordBtnBy(state: .recording)
                }
            } else if self.speakPlayOriginBtnState == .stop {
                self.setSpeakRecordBtnBy(state: .recording)
            }
            
            break
        }
    }
    
    //播放录音
    @objc func speakingPlayRecordBtnClicked(){
        switch speakPlayRecordBtnState {
        case .disable:
            break
        case .play:
            setSpeakPlayRecordBtnBy(state: .stop)
            break
        case .stop:
            setSpeakPlayRecordBtnBy(state: .play)
            break
        }
    }
    
    // 在播放模式界面， 听原音
    @objc func listeningBtnClicked(){
        switch listenPlayBtnState {
        case .play:
            setListenPlayBtnBy(state: .stop)
            break
        case .stop:
            setListenPlayBtnBy(state: .play)
            break
        }
    }
    
    // 滑动到新的页面时开始播放录音+gif
    func playOriginAtStart(isListen:Bool) {
        if !isListen {
            setSpeakPlayOriginBtnBy(state: .play)
        } else {
            setListenPlayBtnBy(state: .play)
        }
    }
    
    
    func play() {
        if ifListeningControlView {
            setListenPlayBtnBy(state: .play)
        } else {
            setSpeakPlayOriginBtnBy(state: .play)
        }
    }
    
    
    // MainScrollViewController 滑动时停止当前播放原音
    func stopPlayOrigin() {
        setSpeakPlayOriginBtnBy(state: .stop)
        setListenPlayBtnBy(state: .stop)
    }
    
    // MainScrollViewController 滑动时停止当前播放录音
    func stopPlayRecord() {
        if speakPlayRecordBtnState == .play {
            setSpeakPlayRecordBtnBy(state: .stop)
        }
    }
    
    //录音状态的pageView -> 播放状态的pageview
    
    func changeRecordToListenBy(recordToListen:Bool) {
        if recordToListen {
            ifListeningControlView = true
            
            speakingControlView.isHidden = true
            listeningControlView.isHidden = false
            
            speakingPlayRecordBtn.isEnabled = false
            
            setPlayerAndRecoderBy(pageViewState: 1)
            
        } else {
            ifListeningControlView = false
            
            listeningControlView.isHidden = true
            speakingControlView.isHidden = false
            
            speakingPlayRecordBtn.isEnabled = true
            let imgPR = PictureBookTools.imageForResource(path: "ablePlayRecord", type: "png", bundle: currentBundle)
            speakingPlayRecordBtn.setImage(imgPR, for: .normal)
            setPlayerAndRecoderBy(pageViewState: 2)
            do {
                recordAndPlay.recordPlayer = try AVAudioPlayer(contentsOf:recordFile)
                recordAndPlay.recordPlayer.delegate = self
                recordAndPlay.recordPlayer.volume = 1.0
                
            } catch let err{
                print("初始化recordPlayer失败：\(err.localizedDescription)")
            }
        }
    }
    
    // 设置player和recoder
    /* pageView 只听状态-听原音 - 0
     * pageView 只听状态-听录音 - 1
     * pageView 录音状态       - 2
     */
    
    func setPlayerAndRecoderBy(pageViewState: Int) {
        switch pageViewState {
        case 0,2:
            recordAndPlay = Recording(audioFile:recordFile, originFile:originFile)
            recordAndPlay.originPlayer.delegate = self
        case 1:
            let recordFileName = bookID + "_" + pageIndex + "_record.caf"
            let recordLocalPath = GetFileSystem.saveCAFDirectory.appendingPathComponent(recordFileName)
            recordAndPlay = Recording(audioFile: recordLocalPath, originFile: recordLocalPath)
            recordAndPlay.originPlayer.delegate = self
        default:
            break
        }
    }
    
    
    //判断当前音频是否播放完
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            if player == recordAndPlay.originPlayer{
                if listenPlayBtnState == .play {
                    setListenPlayBtnBy(state: .stop)
                }
                
                if speakPlayOriginBtnState == .play {
                    setSpeakPlayOriginBtnBy(state: .stop)
                }
            }
            
            if player == recordAndPlay.recordPlayer{
                setSpeakPlayRecordBtnBy(state: .stop)
            }
            
            //如果是只听原音的界面，播放完2s自动翻页
            if ifListeningControlView {
                self.delegate?.toNextPage()
            }
        }
    }
    
}
