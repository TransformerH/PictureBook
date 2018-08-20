//
//  ViewController.swift
//  demo3_pbDemo_scrollView
//
//  Created by 韩雪滢 on 19/01/2018.
//  Copyright © 2018 韩雪滢. All rights reserved.
//

import UIKit
import AVFoundation

class MainScrollViewController: UIViewController, UIScrollViewDelegate, PageViewProtocol, EndPageProtocol, CoverProtocol{
    
    let commonColor = UIColor(red:244.0/255.0, green: 100.0/255.0, blue:99.0/255.0, alpha:1.0)
    var currentBundle:Bundle!
    var delayTask:PictureBookTools.Task!
    
    let flag = "MainScrollViewController"
    var readType = ReadType.origin
    
    var pageState = PageState.mix_read
    var endPageState = EndPageState.mix_notReadAll
    var coverState = CoverState.normal
    
    var readRecordFinish:Bool = false //
    var canScrollAuto = true  //判断当前是否可以延迟2秒后自动滑动
    var finishRecording:[Bool]!
    var finishListening:[Bool]!
    
    var scrollView:UIScrollView!
    var pageViewArray:[PageView]!
    var endPageView:EndPageView!
    var pageInfoArray:[[String:String]]!
    var audioInfoArray:[[String:String]]!
    var bookInfoDic:[String:String]!
    var recordCAFPathArray:[String]!
    
    var backBtn:UIButton!
    
    var gestureReg:UIPanGestureRecognizer!
    
    var bookID:String!
    var bookName:String!
    var coverImg:String!
    
    var savePageState:PageState!
    
    var tools: PictureBookTools!
    var pageViewModel: PageViewModel!
    weak var coverVC:CoverViewController!
    var currentPageIndex: Int = 0
    
    lazy var mShareView = ShareView()
    
    // todo 参数写到 init方法里
    convenience init(_ bookID: String, coverVC:CoverViewController, pageState:PageState) {
        self.init()
        print("MainScrollViewController init")
        self.bookID = bookID
        self.coverVC = coverVC
        self.coverVC.delegate = self
        self.pageState = pageState
        self.savePageState = pageState
        
        addData()
        self.setAVAudio()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if currentPageIndex >= pageInfoArray.count {
            return
        }
        let pageView = pageViewArray[currentPageIndex]
        pageView.stopPlayOrigin()
    }
    
    
    override func viewDidLoad() {
        print("MainScrollViewController viewDidLoad")
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        self.edgesForExtendedLayout = []
        
        tools = PictureBookTools()
        pageViewModel = PageViewModel()
        //        coverVC.delegate = self
        gestureReg = UIPanGestureRecognizer()
        
        addViews()
        scrollViewDidScroll(scrollView)
    }
    
    //添加数据
    func addData(){
        self.currentBundle = Bundle(for: MainScrollViewController.self)
        
        /// 获得bookCover的信息
        let bookCoverName = bookID + "_Cover.archive"
        bookInfoDic = Archive.unarchiveBookCoverInfo(fileName: bookCoverName)
        
        bookName = bookInfoDic["bookName"]
        coverImg = bookInfoDic["coverImg"]
        
        /// 获得pageInfo 和 audioInfo
        var pageFileName = bookID
        var audioFileName = bookID
        
        switch pageState {
        case .play:
            // 录音文件存储名
            audioFileName = audioFileName! + "_recordAudio.archive"
            pageFileName = pageFileName! + "_Pages_Record.archive"
            self.readType = ReadType.follow
            break
        case .mix_play, .mix_read, .mix_read_playRecord:
            // 录音文件存储名
            audioFileName = audioFileName! + "_Audio.archive"
            pageFileName = pageFileName! + "_Pages.archive"
            self.readType = ReadType.origin
            break
        }
        audioInfoArray = Archive.unarchiveBookAudioInfo(fileName: audioFileName!)
        pageInfoArray = Archive.unarchivePageArray(fileName: pageFileName!)
        
        PictureBookTools.printLog(message: "audioInfoArray: \(audioInfoArray)")
        
        pageViewArray = Array(repeating:PageView(),count:pageInfoArray.count)
        
        recordCAFPathArray = [String]()
        finishListening = Array<Bool>(repeating:false, count:pageInfoArray.count)
        
        //创建录音文件夹
        let directory:URL = GetFileSystem.saveCAFDirectory
        let manager = FileManager.default
        do{
            if !manager.fileExists(atPath: directory.absoluteString) {
                try manager.createDirectory(atPath: directory.absoluteString, withIntermediateDirectories: true, attributes: nil)
            }
        } catch let error as NSError {
            print("创建upload文件夹失败：" + error.description)
        }
    }
    
    func addViews(){
        var pageCount = pageInfoArray.count
        if pageState == .mix_read || pageState == .play || pageState == .mix_read_playRecord{
            pageCount += 1
        }
        
        finishRecording = Array(repeating:false, count:pageInfoArray.count)
        
        var height = view.frame.height
        var contentHeight = height - 66
        if PictureBookTools.isIphoneX() {
            height -= 34
            contentHeight = height - 120
        }
        scrollView = UIScrollView(frame:CGRect(x:0, y:0, width:view.frame.width, height:height))
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(PictureBookTools.isIphoneX() ? -34 : 0)
        }
        
        scrollView.contentSize = CGSize(width:(scrollView.frame.size.width*CGFloat(pageCount)), height:contentHeight)
        scrollView.scrollRectToVisible(CGRect(x:0,y:0,width:view.frame.size.width,height:view.frame.size.height), animated: false)
        scrollView.backgroundColor = UIColor.white
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.scrollsToTop = false
        scrollView.delegate = self
        
        var ifListen = true
        // MIX模式的跟读状态和PLAY模式下 添加endPage
        // MIX模式的播放状态 不添加endPage
        switch pageState {
        case .mix_read:
            ifListen = false
            makeEndPage()
            break
        case .play:
            makeEndPage()
            //PLAY模式，更改endPage的UI
            endPageView.endPageState = .play
            readRecordFinish = true
            break
        case .mix_play:
            break
            
        case .mix_read_playRecord:
            makeEndPage()
            break
        }
        
        //创建 录音caf格式的文件夹
        let directory:URL = GetFileSystem.saveCAFDirectory
        
        
        for count in 0...(pageInfoArray.count - 1){
            
            let imgUrl = pageInfoArray[count]["picture"]!
            let words = pageInfoArray[count]["text"]!
            let pageIndex = pageInfoArray[count]["index"]!
            
            let recordFile = buildRecordFilePath(pageID: pageIndex,path:directory)
            let originFile = audioInfoArray[count]["audioLocalPath"]!
            
            var infoDic = [String:Any]()
            var view = PageView()
            
            infoDic = ["bookID":bookID,
                       "pageIndex":pageIndex,
                       "pageID":count,
                       "bookName":bookName,
                       "words":words,
                       "imgUrl":imgUrl,
                       "originFile":URL(string:originFile)!,
                       "recordFile":recordFile] as [String : Any]
            
            print("playMode Page Dic : \(infoDic)")
            view = PageView.init(frame: CGRect(x:scrollView.frame.size.width * CGFloat(count), y:0, width:scrollView.frame.size.width, height:scrollView.frame.size.height),dic:infoDic, ifListen: ifListen)
            
            if pageState == PageState.mix_read || pageState == PageState.mix_read_playRecord{
                //MIX模式跟读状态下才有endpage
                view.endPageDelegate = endPageView
            }
            
            view.delegate = self
            pageViewArray[count] = view
            scrollView.addSubview(view)
        }
        
        //存储当前绘本所有page的record CAF 路径
        let fileName = bookID + "_recordCAF.archive"
        Archive.archiveRecordCAFPathArray(fileName:fileName, cafArray: recordCAFPathArray)
    }
    
    func makeEndPage() {
        let infoDic = ["bookName":bookName,
                       "bookCover":coverImg,
                       "bookID":bookID] as [String : String]
        endPageView = EndPageView.init(
            frame: CGRect(x:scrollView.frame.size.width * CGFloat(pageInfoArray.count), y:0, width:scrollView.frame.size.width, height:scrollView.frame.size.height),
            dic:infoDic,
            pageCount:pageInfoArray.count)
        endPageView.delegate = self
        scrollView.addSubview(endPageView)
    }
    
    func buildRecordFilePath(pageID:String,path:URL!) -> URL{
        let fileName = bookID + "_" + pageID + "_record.caf"
        let audioFileName = path.appendingPathComponent(fileName)
        recordCAFPathArray.append(audioFileName.absoluteString)
        return audioFileName
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: -- Scrollview delegate
    
    /// 开始滑动
    ///
    /// - Parameter scrollView: scrollView
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let currentPage = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        print("scrollViewWillBeginDragging-currentPage: \(currentPage)")
        
        //当前不是endPage时,且不是在录音时，滑动可以停止播放，否则报错
        
        if currentPage != pageInfoArray.count {
            pageViewArray[currentPage].stopPlayRecord()
            pageViewArray[currentPage].stopPlayOrigin()
            
        }
        
        canScrollAuto = false
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        var currentPage = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        print("scrollViewDidEndDragging-currentPage: \(currentPage)")
        let slideDirection = scrollView.panGestureRecognizer.translation(in:scrollView)
        
        if (slideDirection.x < 0){
            print("right")
            currentPage += 1
            
            switch pageState {
            case .mix_read, .mix_play, .mix_read_playRecord:
                if currentPage == pageViewArray.count {
                    if canGoBack() {
                        //绘本未全部读完
                        endPageView.makeAddComponents()
                        
                    }
                }
                break
            case .play:
                //PLAY模式最后一页不能手动滑至endPage
                if currentPage == pageViewArray.count - 1 {
                    scrollView.isScrollEnabled = false
                }
                break
            }
        }else if (slideDirection.x > 0){
            print("left")
        }
    }
    
    /// scrollview 停止滑动
    ///
    /// - Parameter scrollView: scrollview
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if !canScrollAuto{
            PictureBookTools.cancel(delayTask)
            canScrollAuto = true
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        let currentPage = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        
        print("scrollViewDidEndScrollingAnimation-currentPage: \(currentPage)")
        
        //滑动停止开始播放
        playPageViewBy(pageID: currentPage)
        currentPageIndex = currentPage
        
        if currentPage + 1 <= pageViewArray.count {
            self.title = "\(currentPage + 1)/\(pageViewArray.count)"
            
        } else {
            self.title = ""
            
        }
        
        let slideDirection = scrollView.panGestureRecognizer.translation(in:scrollView)
        if (slideDirection.x < 0){
            print("right")
            
            if readRecordFinish && currentPage == pageViewArray.count{
                //再次返回到endPage，将状态更改为 MIX模式下的 跟读状态
                pageState = .mix_read
                for page in 0...pageViewArray.count - 1 {
                    if  pageViewArray[page].ifListeningControlView {
                        pageViewArray[page].changeRecordToListenBy(recordToListen: false)
                    }
                }
            }
        }
        
    }
    
    /// 开始滑动
    ///
    /// - Parameter scrollView: scrollView
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(scrollViewDidEndScrollingAnimation), with: scrollView, afterDelay: 0.3 )
    }
    
    
    // MARK: -- Private Method
    
    /// 播放此页的音频
    ///
    /// - Parameter pageID: 页码ID
    func playPageViewBy(pageID: Int) {
        if pageID >= pageViewArray.count {
            return
        }
        let pageview = pageViewArray[pageID]
        
        pageview.play()
        self.finishListening[pageID] = true
    }
    
    //MIX模式下的跟读状态： 判断是否每页都已录音
    func canGoBack() -> Bool{
        var flag = true
        for page in 0...finishRecording.count-1 {
            print("page \(page)")
            if !finishRecording[page] {
                flag = false
                print("false")
            }else {
                print("true")
            }
        }
        return flag
    }
    
    @objc func backBtnClicked(){
        switch pageState {
        case .mix_play:
            //非听本次跟读录音, 绘本的pageView点击返回button 应返回绘本详情页
            self.navigationController?.popViewController(animated: true)
            break
        case .mix_read:
            coverShowMessage(sender: coverVC, showMessage: false)
            returnToCoverPage()
            break
        case .mix_read_playRecord:
            // MIX模式下的 播放状态
            //在听本次跟读录音，绘本的pageView点击返回button 应返回endPage
            let currentPage = Int(self.scrollView.contentOffset.x / self.scrollView.frame.size.width)
            pageViewArray[currentPage].stopPlayOrigin()
            //再次返回到endPage，将状态更改为 MIX模式下的 跟读状态
            pageState = .mix_read
            scrollView.scrollRectToVisible(
                CGRect(x:scrollView.frame.size.width * CGFloat(pageInfoArray.count), y:0, width:scrollView.frame.size.width,
                       height:scrollView.frame.size.height),
                animated: false)
            for page in 0...pageViewArray.count - 1 {
                if  pageViewArray[page].ifListeningControlView {
                    pageViewArray[page].changeRecordToListenBy(recordToListen: false)
                }
            }
            break
        case .play:
            // PLAY模式 返回Cover
            coverShowMessage(sender: coverVC, showMessage: false)
            self.navigationController?.popViewController(animated: true)
            break
        }
    }
    
    func showAlert(){
        let alertController = UIAlertController(title: "还未录制完成，确认离开吗？", message:nil, preferredStyle:UIAlertControllerStyle.alert)
        
        let leaveAction = UIAlertAction(title:"确认离开",style: .default){
            action in
            self.navigationController?.popViewController(animated: true)
        }
        leaveAction.setValue(commonColor, forKey: "titleTextColor")
        
        let continueAction = UIAlertAction(title:"继续录音", style:.default) {
            action in
        }
        continueAction.setValue(UIColor(red:113.0/255.0, green: 98.0/255.0, blue:91.0/255.0, alpha:1.0), forKey: "titleTextColor")
        
        alertController.addAction(continueAction)
        alertController.addAction(leaveAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func returnToCoverPage(){
        let currentPage = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        //MIX模式下的 跟读状态 ： 判断是否能返回绘本详情页
        if canGoBack() {
            if(currentPage >= 0 && currentPage < pageViewArray.count && pageViewArray[currentPage].speakRecordBtnState == .recording){
                pageViewArray[currentPage].stopPlayRecord()
                showAlert()
            }
            self.navigationController?.popViewController(animated: true)
        }else{
            if currentPage < pageViewArray.count {
                pageViewArray[currentPage].stopPlayOrigin()
                pageViewArray[currentPage].stopPlayRecord()
                
                if(pageViewArray[currentPage].speakRecordBtnState == .recording){
                    pageViewArray[currentPage].stopPlayRecord()
                    showAlert()
                }
            }
            if self.savePageState == PageState.mix_read {
                showAlert()
            }
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    
    // MARK: -- AVAudioSetting
    func setAVAudio (){
        NotificationCenter.default.addObserver(self, selector: #selector(audioRouteChangeListenerCallback(note:)), name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)
        
    }
    
    @objc func audioRouteChangeListenerCallback(note: Notification) {
        // 把声音输出扬声器
        let interuptionDict = note.userInfo
        guard let temp = interuptionDict![AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSessionRouteChangeReason.init(rawValue: temp) else {
                return
        }
        switch reason {
        case AVAudioSessionRouteChangeReason.newDeviceAvailable:
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
            } catch _ {
                
            }
            break
        case AVAudioSessionRouteChangeReason.oldDeviceUnavailable:
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.none)
            } catch _ {
                
            }
            break
        case AVAudioSessionRouteChangeReason.categoryChange:
            break
        default:
            break
        }
    }
    
    
    // MARK: -- PageViewProtocol
    
    func setFinishRecord(index: Int, finish: Bool) {
        finishRecording[index] = finish
    }
    
    func setScrollEnable(enable: Bool) {
        self.scrollView.isScrollEnabled = enable
    }
    
    func toNextPage() {
        
      delayTask = PictureBookTools.delay(2) {
            if self.canScrollAuto {
                let currentPage = Int(self.scrollView.contentOffset.x / self.scrollView.frame.size.width)
                print("toNextPage-currentPage: \(currentPage)")
                if currentPage != self.pageInfoArray.count - 1 {
                    self.scrollView.scrollRectToVisible(
                        CGRect(x:self.scrollView.frame.size.width * CGFloat(currentPage + 1),
                               y:0,
                               width:self.self.scrollView.frame.size.width,
                               height:self.scrollView.frame.size.height),
                        animated: true)
                } else {
                    switch self.pageState {
                    case .mix_play:
                        // MIX模式-播放： 播放完所有原音返回到Cover并显示已读完
                        self.coverShowMessage(sender: self.coverVC, showMessage: true)
                        self.navigationController?.popViewController(animated: false)
                        break
                    case .mix_read, .play:
                        self.scrollView.scrollRectToVisible(
                            CGRect(x:self.scrollView.frame.size.width * CGFloat(self.pageInfoArray.count),
                                   y:0,
                                   width:self.scrollView.frame.size.width,
                                   height:self.scrollView.frame.size.height),
                            animated: true)
                        break
                    case .mix_read_playRecord:
                        //MIX模式跟读回放完毕，将pageState更改为录音状态
                        self.pageState = .mix_read
                        for page in 0...self.pageViewArray.count - 1 {
                            self.pageViewArray[page].changeRecordToListenBy(recordToListen: false)
                        }
                        self.scrollView.scrollRectToVisible(
                            CGRect(x:self.scrollView.frame.size.width * CGFloat(self.pageInfoArray.count),
                                   y:0,
                                   width:self.scrollView.frame.size.width,
                                   height:self.scrollView.frame.size.height),
                            animated: true)
                        break
                    }
                }
            }
        }
    }
    
    
    // MARK: -- EndPageViewProtocol
    func readAgainFromFirst() {
        
        pageState = .mix_read
        
        scrollView.scrollRectToVisible(
            CGRect(x:0,
                   y:0,
                   width:scrollView.frame.size.width,
                   height:scrollView.frame.size.height),
            animated: false)
        
        
        for page in 0...finishRecording.count - 1 {
            if pageViewArray[page].ifListeningControlView {
                pageViewArray[page].changeRecordToListenBy(recordToListen: false)
            }
            finishRecording[page] = false
            pageViewArray[page].speakingPlayRecordBtn.isEnabled = false
            let imgPR = PictureBookTools.imageForResource(path: "enablePlayRecord", type: "png", bundle: currentBundle)
            pageViewArray[page].speakingPlayRecordBtn.setImage(imgPR, for: .normal)
            
            pageViewArray[page].listeningControlView.isHidden = true
            pageViewArray[page].speakingControlView.isHidden = false
        }
    }
    
    func getFinishResult() -> Bool {
        return canGoBack()
    }
    
    func showAlertVC(alertVC:UIViewController) {
        present(alertVC, animated: true, completion: nil)
    }
    
    func shareBtnClick(recordID: Int) {
        switch pageState {
        case .mix_read, .mix_read_playRecord, .play:
            readType = ReadType.follow
            break
        case .mix_play:
            readType = ReadType.origin
            break
        }
        
        let shareDic = ["channel": Int(PictureEnv.shared.channelID) as Any,
                        "id":recordID,
                        "type": Int(self.readType.rawValue) as Any,
                        "bookName":bookName,
                        "userName": PictureEnv.shared.mExtra["userName"] ?? "",
                        "coverImg":coverImg,
                        "title": "我家\(PictureEnv.shared.mExtra["userName"] ?? "")为【\(bookName!)】配音"] as [String : Any]
        PictureBookTools.printLog(message: "\(shareDic)")
        
        let shareView = ShareView(frame: CGRect(x:0, y: 0, width: UIScreen.main.bounds.size.width, height: 0), dic: shareDic)
        shareView.coverShare = false
        shareView.delegate = endPageView
        
        shareView.showAnimationWithView(self.view)
        shareView.snp.makeConstraints { (make) in
            make.height.equalTo(190)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(UIApplication.shared.keyWindow!).offset(PictureBookTools.isIphoneX() ? -34 : 0)
        }
    }
    
    func readAllRecord() {
        pageState = .mix_read_playRecord
        for page in 0...pageViewArray.count - 1 {
            pageViewArray[page].changeRecordToListenBy(recordToListen: true)
            
            if page == pageViewArray.count - 1 {
                readRecordFinish = true
            }
        }
        
        scrollView.scrollRectToVisible(
            CGRect(x:0,
                   y:0,
                   width:scrollView.frame.size.width,
                   height:scrollView.frame.size.height),
            animated: false)
    }
    
    //MARK: -- CoverProtocol
    func coverShowMessage(sender:CoverViewController, showMessage:Bool) {
        sender.listenAll = showMessage
    }
    
    /// BackItem override method
    ///
    /// - Returns: void
    public override func navigationShouldPopOnBackButton() -> Bool {
        self.backBtnClicked()
        return false
    }
}

