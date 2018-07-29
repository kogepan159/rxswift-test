//
//  AudioEngineManager.swift
//  AudioEngineSample
//
//  Created by ahirusun on 2016/06/10.
//  Copyright © 2016年 ahirusun. All rights reserved.
//
import Foundation
import AVFoundation

class AudioEngineManager: NSObject {
    
    enum State {
        case Default
        case isRecording
        case isPlaying
    }
    
    // rec format
    let recSettings:[String : AnyObject] = [
        AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM),
        AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue as AnyObject,
        AVNumberOfChannelsKey: 1 as AnyObject,
        AVSampleRateKey : 44100 as AnyObject,
        AVLinearPCMBitDepthKey : 16 as AnyObject
    ]
    
    var status: State = .Default
    var audioPlayer: AVAudioPlayer?
    
    private var audioEngine = AVAudioEngine()
    private var outputFile = AVAudioFile()
    
    override init() {
        super.init()
        setup()
    }
    
    func setup() {
        
        // AudioSession init
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        } catch let error as NSError  {
            print("Error : \(error)")
        }
        
        // Mic -> Effect -> BusMixer
        let input = audioEngine.inputNode
        let mixer = audioEngine.mainMixerNode
        
//        // Reverb
//        let reverb = AVAudioUnitReverb()
//        reverb.loadFactoryPreset(.largeRoom)
//        audioEngine.attach(reverb)
//        
//        // Delay
//        let delay = AVAudioUnitDelay()
//        delay.delayTime = 1
//        audioEngine.attach(delay)
//        
//        // EQs
//        let eq = AVAudioUnitEQ()
//        audioEngine.attach(eq)
//        
//        // connect!
//        audioEngine.connect(input, to: reverb, format: input.inputFormat(forBus: 0))
//        audioEngine.connect(reverb, to: delay, format: input.inputFormat(forBus: 0))
//        audioEngine.connect(delay, to: eq, format: input.inputFormat(forBus: 0))
//        audioEngine.connect(eq, to: mixer, format: input.inputFormat(forBus: 0))
        
        // Distortion
        let distortion = AVAudioUnitDistortion()
        distortion.loadFactoryPreset(.drumsLoFi)
        audioEngine.attach(distortion)
        
        // connect one effectNode
        audioEngine.connect(input, to: distortion, format: input.inputFormat(forBus: 0))
        audioEngine.connect(distortion, to: mixer, format: input.inputFormat(forBus: 0))
    }
    
    // URL for saved RecData
    func recFileURL() -> NSURL {
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
        let pathArray = [dirPath, "rec.caf"]
        let filePath = NSURL.fileURL(withPathComponents: pathArray)
        return filePath! as NSURL
    }
    
    // remove file
    func removeRecFile() {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
        let path = url.appendingPathComponent("rec.caf")?.path
        if manager.fileExists(atPath: path!) {
            try! manager.removeItem(atPath: path!)
        }
    }
    
    // recording start
    func record() {
        status = .isRecording
        
        removeRecFile()
        
        // set outputFile
        outputFile = try! AVAudioFile(forWriting: recFileURL() as URL, settings: recSettings)
        
        // writing recordingData
        let input = audioEngine.inputNode
        
        // if you want to output sound in recording, set "input?.volume = 1"
        input.volume = 0
        
        input.installTap(onBus: 0, bufferSize: 4096, format: input.inputFormat(forBus: 0)) { (buffer, when) in
            try! self.outputFile.write(from: buffer)
        }
        
        // AVAudioEngine start
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch let error as NSError {
                print("Couldn't start engine, \(error.localizedDescription)")
            }
        }
    }
    
    // recording stop
    func stopRecord() {
        status = .Default
        
        // audioEngine stop
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
    }
    
    // play sound
    func playRecData() {
        
        if outputFile.length == 0 { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recFileURL() as URL)
            audioPlayer!.volume = 1.0
            audioPlayer!.prepareToPlay()
            audioPlayer!.play()
            
            status = .isPlaying
        } catch let error as NSError {
            print("Error : \(error)")
        }
    }
    
    // stop sound
    func stopRecData() {
        guard let player = audioPlayer else { return }
        player.stop()
        
        status = .Default
    }
}
