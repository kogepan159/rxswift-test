//
//  AudioEngineManager.swift
//  AudioEngineSample
//
//  Created by ahirusun on 2016/06/10.
//  Copyright © 2016年 ahirusun. All rights reserved.
//
import Foundation
import AVFoundation

protocol AudioEngineManagerDelegate {
    func changeCafToAccfinish()
    
}

class AudioEngineManager: NSObject {
    
    enum State {
        case Default
        case isRecording
        case isPlaying
    }
    
    // rec format
    let recSettings = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVNumberOfChannelsKey: 2,
        AVSampleRateKey : 44100,
        AVLinearPCMIsFloatKey : 1,
        AVLinearPCMIsNonInterleaved : 1,
        AVLinearPCMBitDepthKey: 32,
        AVLinearPCMIsBigEndianKey: 0
        ] as [String : Any]
    
    
    var status: State = .Default
    var audioPlayer: AVAudioPlayer?
    
    private var audioEngine = AVAudioEngine()
    private var outputFile = AVAudioFile()
    private var fileName:String = ""
    var delegate:AudioEngineManagerDelegate? = nil
    
    override init() {
        super.init()
    }
    
    func setup(isOutputVolume: Bool, delayFloat: Float, distortionString: String, eqString: String, reverbString: String) {
        
        var isEffect: [Bool] = [false,false,false,false]
        // AudioSession init
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch{
            print("could not set session category")
            print("error \(error.localizedDescription)")
            
        }
        
        do {
            try audioSession.setActive(true)
        } catch let error as NSError  {
            print("Error : \(error)")
        }
        
        // Mic -> Effect -> BusMixer
        let input = audioEngine.inputNode
        let mixer = audioEngine.mainMixerNode
        
        // Reverb
        let reverb = AVAudioUnitReverb()
        if reverbString != "利用しない" {
            isEffect[0] = true
            let typeInt: Int = AudioEngineType().returntReverbType(setType: reverbString)
            reverb.loadFactoryPreset(AVAudioUnitReverbPreset(rawValue: typeInt)!)
            audioEngine.attach(reverb)
            audioEngine.connect(input, to: reverb, format: input.inputFormat(forBus: 0))
        }

        // Delay
        let delay = AVAudioUnitDelay()
        if delayFloat > 0.005 {
            isEffect[1] = true
            delay.delayTime = TimeInterval(delayFloat)
            audioEngine.attach(delay)
            if isEffect[0] {
                audioEngine.connect(reverb, to: delay, format: input.inputFormat(forBus: 0))
            } else {
                audioEngine.connect(input, to: delay, format: input.inputFormat(forBus: 0))
            }
        }
        
        // EQs
        let eq = AVAudioUnitEQ(numberOfBands: 10)
        if eqString != "利用しない" {
            isEffect[2] = true
            let typeInt: Int = AudioEngineType().returntEqType(setType: eqString)
            eq.bands[0].filterType =  AVAudioUnitEQFilterType(rawValue: typeInt)!
            eq.bypass = true
            audioEngine.attach(eq)
            if isEffect[1] {
                audioEngine.connect(delay, to: eq, format: input.inputFormat(forBus: 0))
            } else if isEffect[0] {
                audioEngine.connect(reverb, to: eq, format: input.inputFormat(forBus: 0))
            } else {
                audioEngine.connect(input, to: eq, format: input.inputFormat(forBus: 0))
            }
        }
        
        
        // Distortion
        let distortion = AVAudioUnitDistortion()
        if distortionString != "利用しない" {
            isEffect[3] = true
            let typeInt: Int = AudioEngineType().returntDistortionType(setType: distortionString)
            distortion.loadFactoryPreset(AVAudioUnitDistortionPreset(rawValue: typeInt)!)
            audioEngine.attach(distortion)
            if isEffect[2] {
                audioEngine.connect(eq, to: distortion, format: input.inputFormat(forBus: 0))
            } else if isEffect[1] {
                audioEngine.connect(delay, to: distortion, format: input.inputFormat(forBus: 0))
            } else if isEffect[0] {
                audioEngine.connect(reverb, to: distortion, format: input.inputFormat(forBus: 0))
            } else {
                audioEngine.connect(input, to: distortion, format: input.inputFormat(forBus: 0))
            }
        }
        
        // mixへの結合処理
        if !isOutputVolume {
            audioEngine.connect(input, to: mixer, format: input.inputFormat(forBus: 0))
        } else if isEffect[3] {
            audioEngine.connect(distortion, to: mixer, format: input.inputFormat(forBus: 0))
        } else if isEffect[2] {
            audioEngine.connect(eq, to: mixer, format: input.inputFormat(forBus: 0))
        } else if isEffect[1] {
            audioEngine.connect(delay, to: mixer, format: input.inputFormat(forBus: 0))
        } else if isEffect[0] {
            audioEngine.connect(reverb, to: mixer, format: input.inputFormat(forBus: 0))
        } else {
            audioEngine.connect(input, to: mixer, format: input.inputFormat(forBus: 0))
        }
        
    }
    
    // URL for saved RecData
    func recFileURL(fileName: String) -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        let url = docsDirect.appendingPathComponent(fileName + ".caf")
        return url
    }
    
    // remove file
    func removeRecFile(fileName: String) {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
        let path = url.appendingPathComponent(fileName + ".caf")?.path
        if manager.fileExists(atPath: path!) {
            try! manager.removeItem(atPath: path!)
        }
    }
    
    // recording start
    func record(fileName: String, isOutputVolume: Bool, delay: Float, distortion: String, eq: String, reverb: String) {
        self.setup(isOutputVolume: isOutputVolume, delayFloat: delay, distortionString: distortion, eqString: eq, reverbString: reverb)
        status = .isRecording
        self.fileName = fileName
        
        
        // set outputFile
        do {
            outputFile = try AVAudioFile(forWriting: recFileURL(fileName: fileName), settings: recSettings)
        } catch {
            print("error \(error.localizedDescription)")
        }
        
        print("isOutputVolume:", isOutputVolume)
        let input = audioEngine.mainMixerNode
        input.volume = isOutputVolume ? 1 : 0
        //audioEngine.in.volume = isOutputVolume ? 1 : 0
        input.installTap(onBus: 0, bufferSize: 1024, format: input.inputFormat(forBus: 0), block:
            { (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                do {
                    try self.outputFile.write(from: buffer)
                } catch {
                    print(NSString(string: "Write failed"));
                }
        })
        
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
        audioEngine.mainMixerNode.removeTap(onBus: 0)
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        changeAcc()
        removeRecFile(fileName: fileName)
        
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
    
    
//    //MARK: - cafからm4a変換
    func changeAcc() {
        let audioURL = recFileURL(fileName: fileName)
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        let outputUrl = docsDirect.appendingPathComponent(fileName + ".m4a")
        
        let asset = AVAsset.init(url: audioURL)
        
        let exportSession = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        
        // remove file if already exits
        let fileManager = FileManager.default
        do{
            try? fileManager.removeItem(at: outputUrl)
        }catch{
            print("can't")
        }
        
        
        exportSession?.outputFileType = AVFileType.m4a
        exportSession?.outputURL = outputUrl
        exportSession?.metadata = asset.metadata
        
        //出力処理
        exportSession?.exportAsynchronously(completionHandler: {
            if (exportSession?.status == .completed) {
                self.delegate?.changeCafToAccfinish()
                print("AV export succeeded.")
                
            } else if (exportSession?.status == .cancelled) {
                self.delegate?.changeCafToAccfinish()
                print("AV export cancelled.")
            } else {
                self.delegate?.changeCafToAccfinish()
                print ("Error is \(String(describing: exportSession?.error))")
            }
        })
    }
    
}
