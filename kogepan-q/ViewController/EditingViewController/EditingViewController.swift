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

    @IBOutlet weak var stopPlayButton: UIButton!
    @IBOutlet weak var concatFileNameTextField: UITextField!
    @IBOutlet weak var concatButton: UIButton!
    @IBOutlet weak var cutButton: UIButton!
    @IBOutlet weak var viewhakei: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var label: UILabel!
    var timer: Timer = Timer()
    @IBOutlet weak var fileNamelabel: UILabel!
    @IBOutlet weak var cutTextField: UITextField!
    @IBOutlet weak var playSlider: UISlider!
    
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
        
        stopPlayButton.rx.tap.bind(){
            self.play()
        }
        
        concatButton.rx.tap.bind(){
            self.concatFileSelect()
        }
        
        cutButton.rx.tap.bind(){
            self.cut()
        }
        let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(AVAudioSessionCategoryPlayback)
        audioPlayer = try! AVAudioPlayer(contentsOf: getURL(fileName: self.fileName, m4aAddFlag: false))
        audioPlayer.delegate = self as AVAudioPlayerDelegate
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
        self.openFileWithFilePathURL(filePathURL: getURL(fileName: self.fileName, m4aAddFlag: false))
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
        print(getURL(fileName: self.fileName, m4aAddFlag: false))
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
        
        var saveFileName = self.fileName
        if self.fileName.contains("Inbox") {
            let array = self.fileName.components(separatedBy:"/")
            saveFileName = array[1]
        }
        
        for halfName in ["_first.m4a", "_latter.m4a"] {
            let isFirst: Bool = (halfName == "_first.m4a")
            let croppedFileSaveURL = docsDirect.appendingPathComponent(saveFileName + halfName)
            // arg1 / arg2 = CMTimeらしいので、とりあえず1で除算
            
            // 本当はもっと厳密にやったほうが良いかも
            let startTime = CMTimeMake(Int64(isFirst ? startTime : cropTime), 1)
            let endTime = CMTimeMake(Int64(isFirst ? cropTime : recordedTime), 1)
            // 開始時間、終了時間からCropするTimeRangeを作成
            let exportTimeRange = CMTimeRangeFromTimeToTime(startTime, endTime)
            
            // AssetにInputとなるファイルのUrlをセット
            let asset = AVAsset(url: getURL(fileName: self.fileName, m4aAddFlag: false))
            // cafファイルとしてExportする
            let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
            exporter?.outputFileType = AVFileType.m4a
            exporter?.timeRange = exportTimeRange
            exporter?.outputURL = croppedFileSaveURL as URL
            
            // Export
            exporter!.exportAsynchronously(completionHandler: {
                switch exporter!.status {
                case .completed:
                    DispatchQueue.main.async {
                        self.dialog(title: "分割成功", message:"一度戻って、ファイルを選択してください", isFileSelect:false)
                    }
                    print("Crop Success! Url")
                case .failed, .cancelled:
                    print("error = \(String(describing: exporter?.error))")
                    DispatchQueue.main.async {
                        self.dialog(title: "分割失敗", message:"同じファイルを分割していないかご確認ください。\nファイル削除方法は、音源選択画面で左スライドをお試しください", isFileSelect:false)
                    }
                default:
                    print("error = \(String(describing: exporter?.error))")
                }
            })
        }
        
    }
    
    func play(){
       
        if !isPlaying {
            if self.playSlider.value == 1.0 {
                self.playSlider.value = 0.0
            }
            audioPlayer.play()
            audioPlayer.currentTime = TimeInterval(self.playSlider.value * Float(audioPlayer.duration))
            isPlaying = true
            label.text = "再生準備"
            playButton.setTitle("STOP", for: .normal)
            playButtonHidden(hidden: true)
            //画面がlockしないように対応
            UIApplication.shared.isIdleTimerDisabled = true
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
        let audioFileURLs = [getURL(fileName: self.fileName, m4aAddFlag: false), concatUrl]
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
                    print("Concat Success! Url")
                    DispatchQueue.main.async {
                        self.dialog(title: "合成成功", message:"一度戻って、ファイルを選択してください", isFileSelect:false)
                    }
                case .failed, .cancelled:
                    print("error  : " )
                    print(exportSession.error!)
                    DispatchQueue.main.async {
                        self.dialog(title: "合成失敗", message:"同じファイル名が存在しないかご確認ください。\nファイル削除方法は、音源選択画面で左スライドをお試しください", isFileSelect:false)
                    }
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
        playButtonHidden(hidden: false)
        //画面がlockするに対応
        UIApplication.shared.isIdleTimerDisabled = false
        //タイマーを停止
        timer.invalidate()
    }
    
    func playButtonHidden(hidden: Bool) {
        playButton.isHidden = hidden
        stopPlayButton.isHidden = !hidden
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.playSlider.value = 1.0
        label.text = "待機中"
        audioStop()
    }
    
    // MARK: - Silder fuction
    @IBAction func changePlaySilder(_ sender: UISlider) {
        if isPlaying {
            audioStop()
        }
        self.playStatusLabel()
        
    }
    
    func playStatusLabel() {
        let min: Int = Int(self.playSlider.value * Float(audioPlayer.duration)) / 60
        let sec: Int = Int(self.playSlider.value * Float(audioPlayer.duration)) % 60
        
        let playerMin: Int = Int(audioPlayer.duration / 60)
        let playerSec: Int = Int(audioPlayer.duration) % 60
        label.text = isPlaying ? "再生中 : " : "停止中 : "
        label.text = label.text! + String(format:"%02d:%02d/",min, sec) +  String(format:"%02d:%02d",playerMin, playerSec)
    }
    
    
    
    //ダイアログを押下すること
    func dialog(title: String, message:String, isFileSelect:Bool) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        if isFileSelect {
            if let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                
                do {
                    var items = try FileManager.default.contentsOfDirectory(atPath: documentDirectory)
                    if items.index(of: "Inbox") != nil {
                        items.remove(at: items.index(of: "Inbox")!)//[fileNameArray.index(of: "Inbox")!]
                    }
                    do {
                        let otherFileNameArray = try FileManager.default.contentsOfDirectory(atPath: documentDirectory + "/Inbox")
                        for oFile in  otherFileNameArray {
                            items += ["Inbox/" + oFile]
                        }
                    } catch let error {
                        print(error)
                    }
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
        self.playStatusLabel()
        self.playSlider.value += 1/Float(self.audioPlayer.duration)
    }
    
}

