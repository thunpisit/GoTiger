//
//  Defined.swift
//  GoTiger!
//
//  Created by Thunpisit Amnuaikiatloet on 4/24/18.
//  Copyright © 2018 Thunpisit Amnuaikiatloet. All rights reserved.
//

import Foundation
import CoreGraphics

let DefinedScreenWidth:CGFloat = 1536
let DefinedScreenHeight:CGFloat = 2048

enum GoTigerGameSceneChildName : String {
    case HeroName = "hero"
    case TigerName = "tiger"
    case StackName = "stack"
    case StackMidName = "stack_mid"
    case ScoreName = "score"
    case TipName = "tip"
    case PerfectName = "perfect"
    case GameOverLayerName = "over"
    case RetryButtonName = "retry"
    case HighScoreName = "highscore"
}

enum GoTigerGameSceneActionKey: String {
    case WalkAction = "walk"
    case GoTigerGrowAudioAction = "stick_grow_audio"
    case GoTigerGrowAction = "stick_grow"
    case GoTigerScaleAction = "hero_scale"
}

enum GoTigerGameSceneEffectAudioName: String {
    case DeadAudioName = "dead.wav"
    case GoTigerGrowAudioName = "stick_grow_loop.wav"
    case GoTigerGrowOverAudioName = "kick.wav"
    case GoTigerFallAudioName = "fall.wav"
    case GoTigerTouchMidAudioName = "touch_mid.wav"
    case VictoryAudioName = "victory.wav"
    case HighScoreAudioName = "highScore.wav"
}

enum GoTigerGameSceneZposition: CGFloat {
    case backgroundZposition = 0
    case stackZposition = 30
    case stackMidZposition = 35
    case GoTigerZposition = 40
    case scoreBackgroundZposition = 50
    case heroZposition, scoreZposition, tipZposition, perfectZposition = 100
    case emitterZposition
    case gameOverZposition
}
