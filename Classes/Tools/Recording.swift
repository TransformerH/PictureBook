//
//  Recording.swift
//  AudioRecord
//
//  Created by 韩雪滢 on 24/01/2018.
//  Copyright © 2018 韩雪滢. All rights reserved.
//

import UIKit
import AVFoundation

class Recording: NSObject, AVAudioRecorderDelegate{
    
    var recordingSession:AVAudioSession! // manage recording
    var audioRecorder:AVAudioRecorder! // handle the actual reading and saving of data
    var recordPlayer:AVAudioPlayer!
    var originPlayer:AVAudioPlayer!

    var baseInfo:NSDictionary!
    
    init(audioFile:URL, originFile:URL) {
        
        super.init()
        
        // 初始化session
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission(){
                [unowned self] allowed in
                DispatchQueue.main.async {
                }
            }
        } catch let err{
            print("设置recordingSession失败: \(err.localizedDescription)")
        }
        self.checkAVAudio()
        //设置和初始化 recorder
        let settings = [
            AVFormatIDKey:Int(kAudioFormatLinearPCM), //kAudioFormatLinearPCM
            AVSampleRateKey: 11025, // 采样率
            AVNumberOfChannelsKey:2,
            AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue
        ]
        do{
            audioRecorder = try AVAudioRecorder(url:audioFile, settings:settings)
            audioRecorder.delegate = self
        }catch let err{
            print("初始化recorder失败：\(err.localizedDescription)")
        }
        
        //初始化原音的player
        //音频文件不能为nil，且格式要正确
        do {
            originPlayer = try AVAudioPlayer(contentsOf:originFile)
            originPlayer.volume = 1.0
        }catch let err{
            print("初始化originPlayer失败：\(err.localizedDescription)")
        }
        
    }
    func checkAVAudio() {
        do {
            if isHeadSetIn() {
                try recordingSession.overrideOutputAudioPort(AVAudioSessionPortOverride.none)
            } else {
                try recordingSession.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
            }
        } catch _ {
            print("error")
        }
    }
    
    func isHeadSetIn() -> Bool {
        let route = AVAudioSession.sharedInstance().currentRoute
        for desc in route.outputs {
            if desc.portType == AVAudioSessionPortHeadphones {
                return true
            }
        }
        return false
    }
    
}
