//
//  FileSystem.swift
//  demo3_pbDemo_scrollView
//
//  Created by 韩雪滢 on 30/01/2018.
//  Copyright © 2018 韩雪滢. All rights reserved.
//

import UIKit

class GetFileSystem: NSObject {
    static let documentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.endIndex - 1]
    }()
    
    static let saveRecordDirectory: URL = {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return URL(string:documentsDirectory)!
    }()
    
    static let saveCAFDirectory:URL = {
        let directory: URL = GetFileSystem.saveRecordDirectory.appendingPathComponent("CAF")
        return directory
    }()
    
    static let saveMP3Directory:URL = {
        let directory: URL = GetFileSystem.saveRecordDirectory.appendingPathComponent("MP3")
        return directory
    }()
    
    static let downloadDirectory: URL = {
        let directory: URL = GetFileSystem.documentsDirectory.appendingPathComponent("Download")
        return directory
    }()
    
    static let uploadDirectory: URL = {
        let directory: URL = GetFileSystem.documentsDirectory.appendingPathComponent("Upload")
        return directory
    }()
}
