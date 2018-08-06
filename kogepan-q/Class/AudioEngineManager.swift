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
    
    override init() {
        super.init()
        setup()
    }
    
    func setup() {
        
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
        reverb.loadFactoryPreset(.largeRoom)
        audioEngine.attach(reverb)

        // Delay
        let delay = AVAudioUnitDelay()
        delay.delayTime = 0.2
        audioEngine.attach(delay)
        
        // EQs
        let eq = AVAudioUnitEQ()
        audioEngine.attach(eq)

        // connect!
        audioEngine.connect(input, to: reverb, format: input.inputFormat(forBus: 0))
        audioEngine.connect(reverb, to: delay, format: input.inputFormat(forBus: 0))
        audioEngine.connect(delay, to: eq, format: input.inputFormat(forBus: 0))
        audioEngine.connect(eq, to: mixer, format: input.inputFormat(forBus: 0))
        
        // Distortion
        let distortion = AVAudioUnitDistortion()
        distortion.loadFactoryPreset(.drumsLoFi)
        audioEngine.attach(distortion)

        // connect one effectNode
        audioEngine.connect(input, to: distortion, format: input.inputFormat(forBus: 0))
        audioEngine.connect(distortion, to: mixer, format: input.inputFormat(forBus: 0))
        

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
    func record(fileName: String, isOutputVolume: Bool) {
        status = .isRecording
        self.fileName = fileName
        
        let input = audioEngine.mainMixerNode
        print("--- file名------")
        print(input.outputFormat(forBus: 0).settings)
        print(recSettings)
        print("--- file名End------")
        
        // set outputFile
        do {
            outputFile = try AVAudioFile(forWriting: recFileURL(fileName: fileName), settings: recSettings)
        } catch {
            print("error \(error.localizedDescription)")
        }
        
        input.outputVolume =  isOutputVolume ? 1 : 0
        
        input.installTap(onBus: 0, bufferSize: 1024, format: input.inputFormat(forBus: 0), block:
            { (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                do {
                    try self.outputFile.write(from: buffer)
                    
                }
                catch {
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
    
    
    //MARK: - cafからm4a変換
    func changeAcc() {
        let audioURL = recFileURL(fileName: fileName)
        
        let fileMgr = FileManager.default
        
        let dirPaths = fileMgr.urls(for: .documentDirectory,
                                    in: .userDomainMask)
        
        let outputUrl = dirPaths[0].appendingPathComponent(fileName + ".m4a")
        
        let asset = AVAsset.init(url: audioURL)
        
        let exportSession = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        
        // remove file if already exits
        let fileManager = FileManager.default
        do{
            try? fileManager.removeItem(at: outputUrl)
            
        }catch{
            print("can't")
        }
        
        
        exportSession?.outputFileType = AVFileType.mp4
        exportSession?.outputURL = outputUrl
        exportSession?.metadata = asset.metadata
        
        //出力処理
        exportSession?.exportAsynchronously(completionHandler: {
            if (exportSession?.status == .completed) {
                print("AV export succeeded.")
                
            } else if (exportSession?.status == .cancelled) {
                print("AV export cancelled.")
            } else {
                print ("Error is \(String(describing: exportSession?.error))")
            }
        })
    }
}
