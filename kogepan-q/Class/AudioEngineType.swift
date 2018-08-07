//
//  AudioEngineType.swift
//  kogepan-q
//
//  Created by 堅固潤也 on 2018/08/07.
//  Copyright © 2018年 堅固潤也. All rights reserved.
//

import Foundation
import AVFoundation

class AudioEngineType: NSObject {
    
    
    func returntDistortionType(setType: String) -> Int {
        let checkArray = ["drumsBitBrush","drumsBufferBeats","drumsLoFi","multiBrokenSpeaker","multiCellphoneConcert","multiDecimated1","multiDecimated2","multiDecimated3","multiDecimated4","multiDistortedFunk","multiDistortedCubed","multiDistortedSquared","multiEcho1","multiEcho2","multiEchoTight1","multiEchoTight2","multiEverythingIsBroken","speechAlienChatter","speechCosmicInterference","speechGoldenPi","speechRadioTower","speechWaves"]
        print(checkArray.index(of: setType)!)
        print(setType)
        return checkArray.index(of: setType)!
    }
    
    
    func returntEqType(setType: String) -> Int {
        let checkArray = ["parametric","lowPass","highPass","resonantLowPass","resonantHighPass","bandPass","bandStop","lowShelf","highShelf","resonantLowShelf","resonantHighShelf"]
        return checkArray.index(of: setType)!
    }
    
    func returntReverbType(setType: String) -> Int {
        let checkArray = ["smallRoom","mediumRoom","largeRoom","mediumHall","largeHall","plate","mediumChamber","largeChamber","cathedral","largeRoom2","mediumHall2","mediumHall3","largeHall2"]
        return checkArray.index(of: setType)!
    }
    
    
}
