//
//  PageViewModel.swift
//  
//
//  Created by 韩雪滢 on 22/01/2018.
//

import UIKit
import Moya
import SwiftyJSON
import RxSwift
import RxCocoa

extension UIDevice {
    public func isX() -> Bool {
        if UIScreen.main.bounds.height == 812 {
            return true
        }
        return false
    }
}

enum PicError: Error {
    case api(msg: String)
}


enum PictureMode {
    case play
    case mix
}

enum ReadType: Int {
    case origin = 0 // 原声
    case follow = 1 // 跟读
}


class PageViewModel: NSObject {
    let accountID = PictureEnv.shared.accountID
    let channelID = PictureEnv.shared.channelID
    let token = PictureEnv.shared.token
    let appkey = PictureEnv.shared.appkey

    var mBookID = ""
    var recordID = ""
    var mBookName:String {
        set {
            mBookNameVariable.value = newValue
        }
        get {
            return mBookNameVariable.value
        }
    }
    var mCoverImgUrl: URL? {
        set {
            mCoverVariabel.value = newValue
        }
        get {
            return mCoverVariabel.value
        }
    }
    
    var mUserName:String? {
        set {
            mUserNameVariable.value = newValue!
        }
        get {
            return mUserNameVariable.value
        }
    }
    
    var mProgress:Float {
        set {
            mProgressVariable.value = newValue
        }
        get {
            return mProgressVariable.value
        }
    }
    
    var mCoverVariabel = Variable(URL(string: ""))
    var mBookNameVariable = Variable("")
    var mProgressVariable = Variable(Float(0))
    var mUserNameVariable = Variable("")
    var mPictureMode: PictureMode!
    var allPageInfo:Array<Dictionary<String, Any>>!
    var provider:MoyaProvider<PBAPI>!
    var pageArray:[[String: String]]!
    var tools:PictureBookTools!
    
    
    override init() {
        provider = MoyaProvider<PBAPI>()
        tools = PictureBookTools()
        super.init()
        //获得书的总数目
        self.pageArray = [[String:String]]()
    }
 
    func getPictureBookDetail() -> Observable<JSON> {
        let bookID = self.mBookID
        return  provider.rx.request(.getDetail( channelID:channelID, accountID: accountID, token: token, id:bookID, appkey: appkey))
            .mapJSON()
            .asObservable()
            .flatMap({ (response) -> Observable<JSON> in
                let data_json = JSON(response)
                
                if (data_json["ret"].intValue != 1){
                    return Observable.error(PicError.api(msg: data_json["msg"].stringValue))
                } else {
                    return Observable.just(data_json["data"])
                }
            })
            .do(onNext: { (data_json) in
                let pages = data_json["pages"].arrayValue
                
                print("getPictureBookDetail: \(pages)")
                
                self.mCoverImgUrl = URL(string: data_json["cover"].stringValue)!
                self.mBookName = data_json["name"].stringValue
                for page in pages{
                    let audio = page["audio"].stringValue
                    let id = page["id"].stringValue
                    let created_at = page["created_at"].stringValue
                    let channelID = page["channelID"].stringValue
                    let picture = page["picture"].stringValue
                    let text = page["text"].stringValue
                    let isDel = page["isDel"].stringValue
                    let updated_at = page["updated_at"].stringValue
                    let index = page["index"].stringValue

                    let dic:Dictionary<String,String> = ["audio": audio,
                                                         "id": id,
                                                         "created_at": created_at,
                                                         "channelID": channelID,
                                                         "picture": picture,
                                                         "text": text,
                                                         "isDel": isDel,
                                                         "updated_at": updated_at,
                                                         "index": index]
                    self.pageArray.append(dic)
                }
                //存储book的array信息
                let pageName = bookID + "_Pages.archive"
                Archive.archivePagesArray(fileName: pageName, pageArray: self.pageArray)
            })
    }
    
    
    func addRecord(recordURL:String) {
        provider.request(.addRecord(channelID: channelID, accountID: accountID, token: token, pictureBookID: self.mBookID, audio: recordURL, appkey: appkey)){[unowned self]
            result in
            switch result {
            case let .success(response):
                let data_json = JSON(response.data)
            case let .failure(error):
                print("addRecord failure: \(error)")
            }
        }
    }
    

    
    func getBookWithRecord() -> Observable<JSON> {
        
        return provider.rx.request(.getBookWithRecord(channelID: channelID, accountID: accountID, token: token, id: mBookID, appkey: appkey))
            .mapJSON()
            .asObservable()
            .flatMap({ (response) -> Observable<JSON> in
                let data_json = JSON(response)
                
                PictureBookTools.printLog(message: "\(data_json)")
                
                if data_json["ret"].intValue != 1 {
                    return Observable.error(PicError.api(msg: data_json["msg"].stringValue))
                } else {
                    return Observable.just(data_json["data"])
                }
            })
            .do(onNext: { (data_json) in
                let pages = data_json["pages"].arrayValue
                
                self.mCoverImgUrl = URL(string:data_json["cover"].stringValue)
                self.mBookName = data_json["name"].stringValue
                self.mUserName = data_json["vipName"].stringValue
                
                
                for page in pages{
                    let index = page["index"].stringValue
                    let picture = page["picture"].stringValue
                    let audio = page["audio"].stringValue
                    let text = page["text"].stringValue
                    let record = page["record"].stringValue
                    
                    let dic:Dictionary<String,String> = ["index":index, "picture":picture, "audio":audio, "text":text, "record":record]
                    self.pageArray.append(dic)
                }
                let pageName = self.mBookID + "_Pages_Record.archive"
                Archive.archivePagesArray(fileName: pageName, pageArray: self.pageArray)
            })

    }
    
}
