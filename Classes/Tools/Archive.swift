//
//  Archive.swift
//  demo3_pbDemo_scrollView
//
//  Created by 韩雪滢 on 31/01/2018.
//  Copyright © 2018 韩雪滢. All rights reserved.
//


// books_Pages achiveName  = bookID_Pages.archive
// books_audioFiles archiveName = bookID_Audio.archive
// book_Cover archiveName  =  bookID_Cover.archive
// book_RecordCAFFilePath =  bookID_recordCAF.archive

import UIKit

class Archive: NSObject {
    
    static let basePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
    
    static let booksPath = "Books.archive"
    
    static func makeDir() {
        let manager = FileManager.default
        do{
            if !manager.fileExists(atPath: basePath) {
                try manager.createDirectory(atPath: basePath, withIntermediateDirectories: true, attributes: nil)
            }
        } catch let error as NSError {
            print("创建Document文件夹失败：" + error.description)
        }
    }
    
    static func archiveBooks(bookArray:[[String:String]]) {
        let filePath = basePath + "/" + booksPath
        if NSKeyedArchiver.archiveRootObject(bookArray, toFile: filePath) {
            print("BooksArray Archive success: \(filePath)")
        }else {
            print("BooksArray Archive failure")
        }
    }
    
    static func unarchiveBooks() -> [[String:String]]{
        let filePath = basePath + "/" + booksPath
        
        print("unarchiveBooks: \(filePath)")
        let data = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as! Array<[String:String]>
        return data
    }
    
    static func archivePagesArray(fileName:String, pageArray:[[String:String]]){
        let filePath = basePath + "/" + fileName
        if NSKeyedArchiver.archiveRootObject(pageArray, toFile: filePath) {
            print("PagesArray Archive success: \(filePath)")
        }else {
            print("PagesArray Archive failure")
        }
    }
    
    static func unarchivePageArray(fileName:String) -> [[String:String]]{
        let filePath = basePath + "/" + fileName
        
        print("unarchivePageArray: \(filePath)")
        let data = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as! Array<[String:String]>
        return data
    }
    
    static func archiveBookAudioInfo(fileName:String, audioInfoArray:[[String:String]]){
        let filePath = basePath + "/" + fileName
        if NSKeyedArchiver.archiveRootObject(audioInfoArray, toFile: filePath) {
            print("audioInfoArray Archive success: \(filePath)")
        }else {
            print("audioInfoArray Archive failure")
        }
    }
    
    static func unarchiveBookAudioInfo(fileName:String) -> [[String:String]] {
        let filePath = basePath + "/" + fileName
        
         print("unarchiveBookAudioInfo: \(filePath)")
        let data = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as! Array<[String:String]>
        return data
    }
    
    static func archiveBookCoverInfo(fileName:String, coverDic:[String:String]){
        let filePath = basePath + "/" + fileName
        
        if NSKeyedArchiver.archiveRootObject(coverDic, toFile: filePath) {
            print("coverDic Archive success: \(filePath)")
        }else {
            print("coverDic Archive failure")
        }
    }
    
    static func unarchiveBookCoverInfo(fileName:String) -> [String:String] {
        let filePath = basePath + "/" + fileName
        
         print("unarchiveBookCoverInfo: \(filePath)")
        let data = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as! [String:String]
        return data
    }
    
    static func archiveRecordCAFPathArray(fileName:String, cafArray:[String]){
        let filePath = basePath + "/" + fileName
        
        if NSKeyedArchiver.archiveRootObject(cafArray, toFile: filePath) {
            print("cafArray Archive success: \(filePath)")
        }else {
            print("cafArray Archive failure")
        }
    }
    
    static func unarchiveRecordCAFPathArray(fileName:String) -> [String] {
        let filePath = basePath + "/" + fileName
        print("unarchiveRecordCAFPathArray: \(filePath)")
        let data = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as! [String]
        return data
    }
    
    static func archiveRecordMP3PathArray(fileName:String, mp3Array:[String]){
        let filePath = basePath + "/" + fileName
        
        if NSKeyedArchiver.archiveRootObject(mp3Array, toFile: filePath) {
            print("mp3Array Archive success: \(filePath)")
        }else {
            print("mp3Array Archive failure")
        }
    }
    
    static func unarchiveRecordMP3PathArray(fileName:String) -> [String] {
        let filePath = basePath + "/" + fileName
        print("unarchiveRecordMP3PathArray: \(filePath)")
        let data = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as! [String]
        return data
    }

}
