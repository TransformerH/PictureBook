//
//  CoverViewModel.swift
//  Alamofire
//
//  Created by 韩雪滢 on 26/02/2018.
//

import UIKit
import Moya
import RxSwift
public class PictureEnv: NSObject {
    var appkey: String = ""
    var token: String = ""
    var accountID: String = ""
    var channelID: String = ""
    var baseURL: String = ""
    var domain: String = ""
    var middleDomain: String = ""
    var setEnv = false
    var mScreenRate = (1.0, 1.0)
    var mExtra: [String: String] = [:]
    
    @objc public static let shared = PictureEnv()
    
    @objc public class func setEnv(appkey: String,
                                   token: String,
                                   accountID: String,
                                   channelID: String,
                                   baseUrl: String,
                                   domain: String,
                                   middleDomain: String,
                                   ext: [String: String]) {
        shared.appkey = appkey
        shared.token = token
        shared.accountID = accountID
        shared.channelID = channelID
        shared.baseURL = baseUrl
        shared.domain = domain
        shared.middleDomain = middleDomain
        shared.setEnv = true
        shared.mExtra = ext
        
        if !PictureBookTools.isIphoneX(){
            shared.mScreenRate = (Double(UIScreen.main.bounds.height / 667.0), Double(UIScreen.main.bounds.width / 375.0))
        } else {
            shared.mScreenRate = (Double(UIScreen.main.bounds.height / 1000.0), 1.0)
        }
    }
}


class CoverViewModel: NSObject {
    
    var downloadResult:Bool!
    var canReturn:Bool!
    
    func isDownloadAudio(mBookID: String, mode: String) -> Bool {
        let filePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        var PBPath = filePath + "/" + "Download" + "/" + mBookID
        let fileManager = FileManager.default
        
        if mode == "1" {
            PBPath = PBPath + "_OriginalRecord"
        }
        return fileManager.fileExists(atPath: PBPath)
    }
    
    // 得到下载文件的localPath
    func getFilePath(mBookID:String, listenRecordMode:Bool) -> URL{
        var subFilePath = mBookID
        if listenRecordMode {
            subFilePath = subFilePath + "_OriginalRecord"
        }
        
        let directory:URL = GetFileSystem.downloadDirectory
        let filePath = directory.appendingPathComponent(subFilePath)
        
        return filePath
    }
    
    func failureThenDelete(mBookID: String, listenRecordMode:Bool) {
        //有一个下载失败，删除download下该绘本的文件
        let downloadDirectory = getFilePath(mBookID:mBookID, listenRecordMode: listenRecordMode)
        let manager = FileManager.default
        let pathString = downloadDirectory.path
        let directoryContents:[Any]? = try? manager.contentsOfDirectory(atPath: pathString)
        
        //删除bookID_bookName文件夹下的所有文件
        if directoryContents != nil {
            for file in directoryContents! {
                do {
                    try manager.removeItem(atPath: pathString + "/\(file)")
                    print("删除文件 \(file)成功")
                }catch let error as NSError {
                    print("删除文件\(file)错误：" + error.description)
                }
            }
        } else {
            print("directoryContents is nil")
        }
        //删除bookID_bookName文件夹
        do{
            try manager.removeItem(atPath: pathString)
        } catch let error as NSError {
            print("删除\(pathString)错误：" + error.description)
        }
    }
    
    func buildAudioInfoArchive(mBookID: String, listenRecordMode:Bool, audioDicArray:[[String:String]]){
        //将book的audioInfo存入archive
        var audioArchiveName = mBookID
        audioArchiveName += listenRecordMode ? "_recordAudio.archive" : "_Audio.archive"
        Archive.archiveBookAudioInfo(fileName: audioArchiveName, audioInfoArray: audioDicArray)
    }
    
    // 将Cover的信息存进Archive: endPage需要使用，page没有必要存储cover的信息
    func buildCoverInfoDic(pageViewModel: PageViewModel) {
        let bookCoverName = pageViewModel.mBookID + "_Cover.archive"
        let coverDic = ["bookID":pageViewModel.mBookID,
                        "bookName":pageViewModel.mBookName,
                        "coverImg":pageViewModel.mCoverImgUrl?.absoluteString]
        Archive.archiveBookCoverInfo(fileName: bookCoverName, coverDic: coverDic as! [String : String])
    }
    
    func makeShareDic(mBookID:String) -> Dictionary<String, Any> {
        let bookCoverName = mBookID + "_Cover.archive"
        let bookInfoDic = Archive.unarchiveBookCoverInfo(fileName: bookCoverName)
        let bookID = (bookInfoDic["bookID"]! as NSString).integerValue
        let shareDic = ["channel": Int(PictureEnv.shared.channelID) as Any,
                        "id":bookID,
                        "type": Int(ReadType.origin.rawValue) as Any,
                        "bookName":bookInfoDic["bookName"]! ,
                        "userName":PictureEnv.shared.mExtra["userName"] ?? "",
                        "coverImg":bookInfoDic["coverImg"]!,
                        "title":"我家\(PictureEnv.shared.mExtra["userName"] ?? "")正在读【\(bookInfoDic["bookName"]!)】"] as [String : Any]
        return shareDic
    }
    
    //判断是否下载成功的函数：mp3文件是否都存在
    func ifDownloadSuccess(audioDicArray:[[String:String]]) -> Bool {
        for file in 0...audioDicArray.count - 1 {
            let downloadFilePath = audioDicArray[file]["audioLocalPath"]!
            if !FileManager.default.fileExists(atPath: downloadFilePath){
                return false;
            }
        }
        return true
    }
    
    func buildAudioInfoDic(pageViewModel:PageViewModel, listenRecordMode:Bool) -> [[String:String]] {
        let pageInfoArray:[[String:String]] = pageViewModel.pageArray
        var audioDicArray:[[String:String]] = [[String:String]]()
        let filePath = self.getFilePath(mBookID:pageViewModel.mBookID, listenRecordMode: listenRecordMode)
        
        for page in 0...pageInfoArray.count-1 {
            let url = listenRecordMode ? pageInfoArray[page]["record"]!: pageInfoArray[page]["audio"]!
            let audioFileName = pageViewModel.mBookID + "_" + pageInfoArray[page]["index"]! + ".mp3"
            let audioLocalPath = filePath.appendingPathComponent(audioFileName)
            let audioDic:[String:String] = ["audioName":audioFileName, "audioURL":url, "audioLocalPath":audioLocalPath.absoluteString]
            audioDicArray.append(audioDic)
        }
        self.buildAudioInfoArchive(mBookID: pageViewModel.mBookID, listenRecordMode: listenRecordMode, audioDicArray: audioDicArray)
        
        return audioDicArray
    }
    
    func downloadAllAudio(vc:CoverViewController){
        vc.pageInfoArray = vc.pageViewModel.pageArray
        let pageCount = vc.pageInfoArray.count
        var completed:Float = 0.0
        var downloadFinishedValue = Variable(0)
        let provider = MoyaProvider<DownloadFile>()
        
        for page in 0...vc.pageInfoArray.count-1 {
            provider.request(DownloadFile.downloadFile(url:vc.pageInfoArray[page]["audio"]!, fileName: vc.audioDicArray[page]["audioName"], filePath: self.getFilePath(mBookID: vc.pageViewModel.mBookID, listenRecordMode: vc.listenRecordMode)), progress: {
                progress in
                // 设置button外circle的progress
                completed = completed + Float(progress.progress) / Float(pageCount)
                vc.setProgress(value:completed)
            }, completion: {
                result in
                switch result {
                case let .success(response):
                    let stateCode = response.statusCode
                    // 下载成功200，更改监听值
                    if stateCode == 200 {
                        downloadFinishedValue.value = downloadFinishedValue.value + 1
                    }
                    
                case .failure(_):
                    let img = PictureBookTools.imageForResource(path: "download", type: "png", bundle: vc.currentBundle)
                    vc.downloadBtn.setImage(img, for: .normal)
                    vc.setProgress(value: 0)
                    
                    self.failureThenDelete(mBookID: vc.pageViewModel.mBookID, listenRecordMode: vc.listenRecordMode)
                    
                    let alertController = UIAlertController(title: "下载失败，请重新尝试。", message:nil, preferredStyle:UIAlertControllerStyle.alert)
                    let continueAction = UIAlertAction(title:"好的", style:.default) {action in}
                    alertController.addAction(continueAction)
                    vc.present(alertController, animated: true, completion: nil)
                }
                
            })
        }
        
        //监听是否所有的音频都下载完毕
        _ = downloadFinishedValue.asObservable().subscribe(onNext: { (num) in
            if num == pageCount {
                //隐藏downloadView, 显示controlView
                vc.downLoadView.removeFromSuperview()
                vc.makeControlView(isListenMode: vc.listenRecordMode)
            }
        }, onError: nil, onCompleted: nil, onDisposed: nil)
    }

}
