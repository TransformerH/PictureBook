//
//  ChangeState.swift
//  Alamofire
//
//  Created by 韩雪滢 on 28/02/2018.
//

import UIKit

enum PageState {
    /// PLAY模式
    case play
    /// MIX模式-跟读
    case mix_read
    /// MIX模式-跟读-回放
    case mix_read_playRecord
    /// MIX模式-播放
    case mix_play
}

enum EndPageState {
    case mix_readAll
    case mix_notReadAll
    case play
}

enum CoverState {
    case normal
    case mix_play
}

