//
//  ViewController.swift
//  kogepan-q
//
//  Created by 堅固潤也 on 2018/05/20.
//  Copyright © 2018年 堅固潤也. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AVFoundation



class EditingViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, EZAudioFileDelegate, UITextFieldDelegate {

    @IBOutlet weak var concatFileNameTextField: UITextField!
    @IBOutlet weak var concatButton: UIButton!
    @IBOutlet weak var cutButton: UIButton!
    @IBOutlet weak var viewhakei: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var label: UILabel!
    var timer: Timer = Timer()
    var count: Int = 0
    @IBOutlet weak var fileNamelabel: UILabel!
    @IBOutlet weak var cutTextField: UITextField!
    
    var audioPlayer: AVAudioPlayer!
    var isPlaying = false
    var fileName:String = ""
    
    var audioFile:EZAudioFile!
    var audioPlot:EZAudioPlot!
    var audioPlayerEZ:EZAudioPlayer!
    var audioCoreGrph:EZAudioPlotGL!
    
    let dis = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.red
        concatFileNameTextField.delegate = self
        cutTextField.delegate = self
        self.title = "音声編集"
        playButton.rx.tap.bind(){
            self.play()
        }
        
        concatButton.rx.tap.bind(){
            self.concatFileSelect()
        }
        
        cutButton.rx.tap.bind(){
            self.cut()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setWaveform()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isPlaying {
            self.audioStop()
        }
    }
    
    //波形生成
    func setWaveform() {
        self.fileNamelabel.text = "ファイル名: " + self.fileName
        //波形
        self.audioPlot = EZAudioPlot(frame: self.viewhakei.frame)
        self.audioPlot.backgroundColor = UIColor.blue
        self.audioPlot.color = UIColor.white
        self.audioPlot.plotType = EZPlotType.buffer
        self.audioPlot.shouldFill = true
        self.audioPlot.shouldMirror = true
        self.audioPlot.shouldOptimizeForRealtimePlot = true
        self.audioPlot.tag = 1
        
        //ファイルのパスを指定して読み込み
        self.openFileWithFilePathURL(filePathURL: getURL())
        //        self.openFileWithFilePathURL(filePathURL: NSURL(fileURLWithPath: Bundle.main.path(forResource: "kaze", ofType: "mp3")!))
        let subviews = self.view.subviews
        for subview in subviews {
            if subview.tag == 1 {
                subview.removeFromSuperview()
            }
        }
        
        self.view.addSubview(self.audioPlot)
        
    }
    
    //ファイルの読み込みと波形の読み込み
    func openFileWithFilePathURL(filePathURL:URL){
        print("openFileWithFilePathURL")
        print(filePathURL)
        print("---------------------")
        print(getURL())
        self.audioFile = EZAudioFile(url: filePathURL)
        self.audioFile.delegate = self
        
        let buffer = self.audioFile.getWaveformData().buffer(forChannel: 0)
        let bufferSize = self.audioFile.getWaveformData().bufferSize
        self.audioPlot.updateBuffer(buffer, withBufferSize: bufferSize)
        
        //読み込んだオーディオファイルをプレイヤーに設定して初期化
        self.audioPlayerEZ = EZAudioPlayer(audioFile: self.audioFile)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getURL() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        let url = docsDirect.appendingPathComponent(self.fileName)
        return url
    }
    
    // MARK: - Action
    func fileSelect(){
        dialog(title: "再生するファイルを選択してください", message:"", isFileSelect:true)
    }
    
    func concatFileSelect(){
        if (self.concatFileNameTextField.text?.isEmpty)! {
            dialog(title: "合成後の名前を入力してください", message:"合成後の名前に設定してから、合成ボタンを押下してください", isFileSelect:false)
            return
        }
        dialog(title: "結合するファイルを選択してください", message:"", isFileSelect:true)
    }
    
    func cut(){
        if (self.cutTextField.text?.isEmpty)! {
            dialog(title: "秒数を入力してください", message:"分割する秒に数字を入力してください", isFileSelect:false)
            return
        }
        let startTime:TimeInterval = 0.0 // 最初の時間
        let cropTime:TimeInterval = Double(self.cutTextField.text!)! // 10秒分切り出す
        let recordedTime: Double = self.audioFile.duration
            
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        
        for halfName in ["_first.m4a", "_latter.m4a"] {
            let isFirst: Bool = (halfName == "_first.m4a")
            let croppedFileSaveURL = docsDirect.appendingPathComponent(self.fileName + halfName)
            // arg1 / arg2 = CMTimeらしいので、とりあえず1で除算
            
            // 本当はもっと厳密にやったほうが良いかも
            let startTime = CMTimeMake(Int64(isFirst ? startTime : cropTime), 1)
            let endTime = CMTimeMake(Int64(isFirst ? cropTime : recordedTime), 1)
            // 開始時間、終了時間からCropするTimeRangeを作成
            let exportTimeRange = CMTimeRangeFromTimeToTime(startTime, endTime)
            
            // AssetにInputとなるファイルのUrlをセット
            let asset = AVAsset(url: getURL())
            // cafファイルとしてExportする
            let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
            exporter?.outputFileType = AVFileType.m4a
            exporter?.timeRange = exportTimeRange
            exporter?.outputURL = croppedFileSaveURL as URL
            
            // Export
            exporter!.exportAsynchronously(completionHandler: {
                switch exporter!.status {
                case .completed:
                    print("Crop Success! Url")
                case .failed, .cancelled:
                    print("error = \(String(describing: exporter?.error))")
                default:
                    print("error = \(String(describing: exporter?.error))")
                }
            })
        }
        
    }
    
    func play(){
       
        if !isPlaying {
            audioPlayer = try! AVAudioPlayer(contentsOf: getURL())
            audioPlayer.delegate = self as AVAudioPlayerDelegate
            audioPlayer.play()
            isPlaying = true
            label.text = "再生中"
            playButton.setTitle("STOP", for: .normal)
            //タイマーが動いている状態で押されたら処理しない
            if timer.isValid == true {
                return
            }
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateElapsedTime), userInfo: nil, repeats: true)
        }else{
            audioStop()
        }
    }
    
    func concat(concatFilename: String) {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        let concatUrl = docsDirect.appendingPathComponent(concatFilename)
        let audioFileURLs = [getURL(), concatUrl]
        var nextStartTime = kCMTimeZero
        let composition = AVMutableComposition()
        let track = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        // 結合するファイル毎に、timerangeを作りtrackにinsertする
        for url in audioFileURLs {
            print("出力テスト")
            print(url)
            let asset = AVURLAsset(url: url as URL)
            if let assetTrack = asset.tracks(withMediaType: AVMediaType.audio).first {
                let timeRange = CMTimeRange(start: kCMTimeZero, duration: asset.duration)
                do {
                    try track?.insertTimeRange(timeRange, of: assetTrack, at: nextStartTime)
                    nextStartTime = CMTimeAdd(nextStartTime, timeRange.duration)
                    print(nextStartTime.seconds)
                } catch {
                    print("concatenateError : \(error)")
                }
            } else {
                print("error")
            }
        }
        
        if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) {
            
            
            
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let docsDirect = paths[0]
            let saveUrl = docsDirect.appendingPathComponent( concatFileNameTextField.text! + ".m4a")
            
            
            exportSession.outputFileType = AVFileType.m4a //AVFileTypeCoreAudioFormat
            exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, (track?.timeRange.duration)!)
            exportSession.outputURL = saveUrl as URL
            
            exportSession.exportAsynchronously(completionHandler: {
                switch exportSession.status {
                case .completed:
                    print("Concat Success! Url -> \(saveUrl)")
                case .failed, .cancelled:
                    print("error  : " )
                    print(exportSession.error!)
                default:
                    print("error")
                    break
                    
                }
            })
        }
        
        
    }
    
    // MARK: - Other
    func audioStop() {
        audioPlayer.stop()
        isPlaying = false
        playButton.setTitle("PLAY", for: .normal)
        label.text = "待機中"
        
        //タイマーを停止
        timer.invalidate()
        count = 0
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioStop()
    }
    
    //ダイアログを押下すること
    func dialog(title: String, message:String, isFileSelect:Bool) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        if isFileSelect {
            if let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                
                do {
                    let items = try FileManager.default.contentsOfDirectory(atPath: documentDirectory)
                    print(items)
                    for item in items {
                        let okAction = UIAlertAction(title: item, style: UIAlertActionStyle.default){ (action: UIAlertAction) in
                            
                            self.concat(concatFilename: item)
                        
                        }
                        alertController.addAction(okAction)
                        
                    }
                } catch let error {
                    print(error)
                }
            }
            let cancelButton = UIAlertAction(title: "CANCEL", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(cancelButton)
        } else {
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
            alertController.addAction(okAction)
        }
        present(alertController,animated: true,completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //
    //  一定間隔で実行される処理
    //
    @objc func updateElapsedTime() {
        count += 1
        let min: Int = count / 60
        let sec: Int = count % 60
        
        let playerMin: Int = Int(audioPlayer.duration / 60)
        let playerSec: Int = Int(audioPlayer.duration) % 60
        label.text = "再生中 : " + String(format:"%02d:%02d/",min, sec) +  String(format:"%02d:%02d",playerMin, playerSec)
    }
    
}

