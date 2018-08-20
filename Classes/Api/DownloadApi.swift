//
//  Download.swift
//  pb_download
//
//  Created by 韩雪滢 on 30/01/2018.
//  Copyright © 2018 韩雪滢. All rights reserved.
//

import UIKit
import Moya
import SwiftyJSON


enum DownloadFile {
    case downloadFile(url:String, fileName:String?, filePath: URL?)
    
    var localLocation:URL {
        switch self {
        case .downloadFile(_, let fileName, let filePath):
            let compFilePath: URL = filePath!.appendingPathComponent(fileName!)
            
            print("downloadfilePath: \(compFilePath)")
            
            return compFilePath
        }
    }
    
    var downloadDestination:DownloadDestination {
        return {
            _, _ in
            return (self.localLocation, [.removePreviousFile, .createIntermediateDirectories])
        }
    }
}

extension DownloadFile:TargetType {
    var headers: [String : String]? {
        return nil
    }
    
    var baseURL: URL {
        switch self {
        case .downloadFile(let url, _, _):
            return URL(string:url)!
        }
    }
    
    var path: String {
        switch self {
        case .downloadFile:
            return ""
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .downloadFile:
            return .get
        }
    }
    
    var parameters: [String : Any]? {
        switch self {
        case .downloadFile:
            return nil
        }
    }
    
    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .downloadFile(_, _, _):
            return .downloadDestination(downloadDestination)
        }
    }
}




