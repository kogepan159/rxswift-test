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
    let recSettings = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue,
        AVNumberOfChannelsKey: 2,
        AVSampleRateKey : 44100,
        AVLinearPCMBitDepthKey : 16
        ] as [String : Any]
    
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
        let output = audioEngine.outputNode
        
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
        audioEngine.connect(mixer, to: output, format: input.inputFormat(forBus: 0))

    }
    
    // URL for saved RecData
    func recFileURL(fileName: String) -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        let url = docsDirect.appendingPathComponent(fileName + ".m4a")
        return url
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
    func record(fileName: String) {
        status = .isRecording
        
        removeRecFile()
        
        print("--- file名------")
        print(recFileURL(fileName: fileName))
        print("--- file名End------")
        // set outputFile
        outputFile = try! AVAudioFile(forWriting: recFileURL(fileName: fileName), settings: recSettings)
        
        // writing recordingData
        let input = audioEngine.inputNode
        
        print("\(input.inputFormat(forBus: 0))")
        // if you want to output sound in recording, set "input?.volume = 1"
        input.volume = 0
        
        input.installTap(onBus: 0, bufferSize: 4096, format: input.inputFormat(forBus: 0)) { (buffer, when) in
            print(buffer)
            do {
                // audioFileにバッファを書き込む
                try self.outputFile.write(from: buffer)
            } catch let error {
                print("audioFile.writeFromBuffer error:", error)
            }
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
    func playRecData(fileName: String) {
        
        if outputFile.length == 0 { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recFileURL(fileName: fileName) as URL)
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
