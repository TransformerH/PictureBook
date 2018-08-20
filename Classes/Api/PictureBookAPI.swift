//
//  PictureBookAPI.swift
//  pb_download
//
//  Created by 韩雪滢 on 30/01/2018.
//  Copyright © 2018 韩雪滢. All rights reserved.
//

import UIKit
import Moya

enum PBAPI {
    //下载绘本
    case getByPage(channelID:String, accountID:String, token:String, page:Int, appkey:String)
    case getByLast(channelID:String, accountID:String, token:String, appkey:String)
    case getDetail(channelID:String, accountID:String, token:String, id:String, appkey:String)
    case uploadAudio(channelID:String, accountID:String, token:String, audio:Data, appkey:String)
    case addRecord(channelID:String, accountID:String, token:String, pictureBookID:String, audio:String, appkey:String)
    //id 为recordID
    case getBookWithRecord(channelID:String, accountID:String, token:String, id:String, appkey:String)
}

extension PBAPI: TargetType {
    
    var headers: [String : String]? {
        switch self {
        case .getByPage, .getByLast, .getDetail, .addRecord, .getBookWithRecord:
            return ["Content-type": "application/x-www-form-urlencoded"]
        case .uploadAudio:
            return nil
        }
        
    }
    
    
    var baseURL: URL {
        switch self {
        case .getByPage, .getByLast, .getDetail,.addRecord, .getBookWithRecord:
            return URL(string: PictureEnv.shared.middleDomain + "/edu-admin/main.php/json")!
        case .uploadAudio:
            return URL(string: PictureEnv.shared.domain + "/index.php")!
        }
    }
    
    var path: String {
        switch self {
        case .getByPage:
            return "/picture_book/getByPage"
        case .getByLast:
            return "/picture_book/getByLast"
        case .getDetail:
            return "/picture_book/getDetail"
        case .uploadAudio:
            return "/UploadFile/upload"
        case .addRecord:
            return "/picture_book/addRecord"
        case .getBookWithRecord:
            return "/picture_book/getBookWithRecord"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getByPage, .getByLast, .getDetail, .uploadAudio, .addRecord, .getBookWithRecord:
            return .post
        }
    }
    
    var task: Task {
        switch self{
        case .getByPage(let channelID,let accountID,let token, let page, let appkey):
            return .requestParameters(parameters:["channelID":channelID, "accountID":accountID, "token":token, "page":page, "appkey":appkey] , encoding:URLEncoding.default )
        case .getByLast(let channelID, let accountID, let token, let appkey):
            return .requestParameters(parameters: ["channelID":channelID, "accountID":accountID, "token":token, "appkey":appkey], encoding: URLEncoding.default)
        case .getDetail(let channelID, let accountID, let token, let id, let appkey):
            return .requestParameters(parameters: ["channelID":channelID, "accountID":accountID, "token":token, "id":id ,"appkey":appkey], encoding: URLEncoding.default)
        case .uploadAudio(let channelID, let accountID, let token, let audio, let appkey):
            let audioData = MultipartFormData(provider: .data(audio), name: "file", fileName:"audio.mp3", mimeType:"audio/mpeg")
            let multipartData = [audioData]
            let urlParameters = ["channelID":channelID, "accountID": accountID, "token":token, "appkey":appkey]
            return .uploadCompositeMultipart(multipartData, urlParameters: urlParameters)
            
        case .addRecord(let channelID, let accountID, let token, let pictureBookID, let audio, let appkey):
            return .requestParameters(parameters: ["channelID":channelID, "accountID":accountID, "token":token, "pictureBookID":pictureBookID, "audio":audio, "appkey":appkey], encoding: URLEncoding.default)
            
        case .getBookWithRecord(let channelID, let accountID, let token, let id, let appkey):
            return .requestParameters(parameters: ["channelID":channelID, "accountID":accountID, "token":token, "id":id, "appkey":appkey], encoding: URLEncoding.default)
        }
        
    }

    var sampleData: Data {
        return "{}".data(using:String.Encoding.utf8)!
    }

}

class PictureBookAPI: NSObject {

}
