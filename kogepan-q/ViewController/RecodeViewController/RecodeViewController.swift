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
import AudioToolbox

class RecodeViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    private var audioEngineMnager = AudioEngineManager()
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recodeButton: UIButton!
    @IBOutlet weak var voiceFileName: UITextField!
    @IBOutlet weak var stopRecodeButton: UIButton!
    @IBOutlet weak var stopPlayButton: UIButton!
    
    @IBOutlet weak var delayLabel: UILabel!
    @IBOutlet weak var distortionLabel: UILabel!
    @IBOutlet weak var eqLabel: UILabel!
    @IBOutlet weak var reverbLabel: UILabel!
    
    
    @IBOutlet weak var delaySilder: UISlider!
    @IBOutlet weak var distortionButton: UIButton!
    @IBOutlet weak var eqSilder: UIButton!
    @IBOutlet weak var reverbSilder: UIButton!
    
    @IBOutlet weak var bothPlaySwitch: UISwitch!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var isRecording = false
    var isPlaying = false
    let dis = DisposeBag()
    var timer: Timer = Timer()
    var count: Int = 0
    
    //MARK: - メイン処理
    override func viewDidLoad() {
        self.navigationController?.navigationBar.tintColor = UIColor.red
        self.setUserDefalts()
        self.title = "音声録音"
        super.viewDidLoad()
        recodeButton.rx.tap.bind{
            self.startRecode()
        }
        playButton.rx.tap.bind{
            self.play()
        }
        
        stopRecodeButton.rx.tap.bind{
            self.startRecode()
        }
        
        stopPlayButton.rx.tap.bind{
            self.play()
        }

        let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(AVAudioSessionCategoryPlayback)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isPlaying {
            self.audioStop()
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUserDefalts() {
        let userDefault = UserDefaults.standard
        
        if userDefault.object(forKey: "delayValue") != nil {
            let value = userDefault.float(forKey: "delayValue")
            delaySilder.value = value
            delayLabel.text = String(format:"%.02f",value)
        }
        
        if userDefault.object(forKey: "distortionLabel") != nil {
            distortionLabel.text = userDefault.string(forKey: "distortionLabel")
        }
        
        if userDefault.object(forKey: "eqLabel") != nil {
            eqLabel.text = userDefault.string(forKey: "eqLabel")
        }
        
        if userDefault.object(forKey: "reverbLabel") != nil {
            reverbLabel.text = userDefault.string(forKey: "reverbLabel")
        }
        
        bothPlaySwitch.isOn = userDefault.object(forKey: "bothPlaySwitch") != nil  ?  userDefault.bool(forKey: "bothPlaySwitch"): false
    }
    
    func startRecode() {
        print("録音スタート")
        
        if audioEngineMnager.status == .isPlaying { return }
        if voiceFileName.text != "" {
        } else {
            dialog()
            return
        }
        if self.microPhoneCheck(){ return }
        
        
        switch audioEngineMnager.status {
        case .Default:
            audioEngineMnager.record(fileName: voiceFileName.text!,
                                     isOutputVolume: bothPlaySwitch.isOn,
                                     delay: delaySilder.value,
                                     distortion: distortionLabel.text!,
                                     eq: eqLabel.text!,
                                     reverb: reverbLabel.text!)
            //タイマーが動いている状態で押されたら処理しない
            if timer.isValid == true {
                return
            }
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateElapsedTime), userInfo: nil, repeats: true)
            //画面がlockしないように対応
            UIApplication.shared.isIdleTimerDisabled = true
            isRecording = true
            label.text = "録音中"
            playButton.isEnabled = false
            recodeButtonHidden(hidden: true)
            
        case .isRecording:
            audioEngineMnager.stopRecord()
            
            
            //audioRecorder.stop()
            isRecording = false
            label.text = "待機中"
            UIApplication.shared.isIdleTimerDisabled = false
            //タイマーを停止
            timer.invalidate()
            count = 0
            playButton.isEnabled = true
            let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
            try! audioSession.setCategory(AVAudioSessionCategoryPlayback)
            recodeButtonHidden(hidden: false)
            
            
        case .isPlaying: break
        }
        
    }
    
    
    func microPhoneCheck() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        
        if status == AVAuthorizationStatus.authorized {
            return false
            // アクセス許可あり
        } else if status == AVAuthorizationStatus.restricted {
            // ユーザー自身にカメラへのアクセスが許可されていない
            return true
        } else if status == AVAuthorizationStatus.notDetermined {
            // まだアクセス許可を聞いていない
            return false
        } else if status == AVAuthorizationStatus.denied {
            // アクセス許可されていない
            return true
        }
        return false
    }
    
    func play(){
        
        if voiceFileName.text != "" {
        } else {
            dialog()
            return
        }
        
        if !isPlaying {
            audioPlayer = try! AVAudioPlayer(contentsOf: getURL(fileName: voiceFileName.text!))
            audioPlayer.delegate = self as AVAudioPlayerDelegate
            audioPlayer.play()
            //画面がlockしないように対応
            UIApplication.shared.isIdleTimerDisabled = true
            isPlaying = true
            playButtonHidden(hidden:true)
            label.text = "再生中"
            playButton.setTitle("STOP", for: .normal)
            recodeButton.isEnabled = false
            //タイマーが動いている状態で押されたら処理しない
            if timer.isValid == true {
                return
            }
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateElapsedTime), userInfo: nil, repeats: true)
        }else{
           audioStop()
        }
    }
    
    // MARK: - 録音再生系Action
    func playButtonHidden(hidden: Bool) {
        playButton.isHidden = hidden
        stopPlayButton.isHidden = !hidden
    }
    
    func recodeButtonHidden(hidden: Bool) {
        recodeButton.isHidden = hidden
        stopRecodeButton.isHidden = !hidden
        
    }
    
    func audioStop() {
        audioPlayer.stop()
        isPlaying = false
        label.text = "待機中"
        playButtonHidden(hidden:false)
        UIApplication.shared.isIdleTimerDisabled = false
        //タイマーを停止
        timer.invalidate()
        count = 0
        playButton.setTitle("PLAY", for: .normal)
        recodeButton.isEnabled = true
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if isPlaying { audioStop()}
    }
    
    func dialog() {
        let alertController = UIAlertController(title: "ファイル名を未入力です",message: "こちらのアプリは、ファイル名を入れていれることで録音が可能になります。", preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        alertController.addAction(okAction)
        present(alertController,animated: true,completion: nil)
    }
    @IBAction func end(_ sender: Any) {
    }
    
    //
    //  一定間隔で実行される処理
    //
    @objc func updateElapsedTime() {
        count += 1
        let min: Int = count / 60
        let sec: Int = count % 60
        
        if isRecording {
            label.text = "録音中:" + String(format:"%02d:%02d",min, sec)
        } else {
            let playerMin: Int = Int(audioPlayer.duration / 60)
            let playerSec: Int = Int(audioPlayer.duration) % 60
            label.text = "再生中 : " + String(format:"%02d:%02d/",min, sec) +  String(format:"%02d:%02d",playerMin, playerSec)
        }
    }
    
    // MARK: - StoryBorad Action系
    @IBAction func valueChanged(_ sender: UISlider) {
        let userDefault = UserDefaults.standard
        let setValueString: String = String(format:"%.02f",sender.value)
        delayLabel.text = setValueString
        userDefault.setValue(sender.value, forKeyPath: "delayValue")
    }
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        let userDefault = UserDefaults.standard
        userDefault.setValue(sender.isOn, forKeyPath: "bothPlaySwitch")
        
    }
    
    @IBAction func touchUpButton(_ sender: UIButton) {
        switch sender.tag {
        case 1:
            dialog(title: "distortionのタイプを選択してください", message:"", tag: 1, array: ["利用しない","drumsBitBrush","drumsBufferBeats","drumsLoFi","multiBrokenSpeaker","multiCellphoneConcert","multiDecimated1","multiDecimated2","multiDecimated3","multiDecimated4","multiDistortedFunk","multiDistortedCubed","multiDistortedSquared","multiEcho1","multiEcho2","multiEchoTight1","multiEchoTight2","multiEverythingIsBroken","speechAlienChatter","speechCosmicInterference","speechGoldenPi","speechRadioTower","speechWaves"], before: distortionLabel.text!)
            break
        case 2:
            dialog(title: "EQのタイプを選択してください", message:"", tag: 2, array: ["利用しない","parametric","lowPass","highPass","resonantLowPass","resonantHighPass","bandPass","bandStop","lowShelf","highShelf","resonantLowShelf","resonantHighShelf"], before: eqLabel.text!)
            break
        default:
            dialog(title: "Reverbのタイプを選択してください", message:"", tag: 3, array: ["利用しない","smallRoom","mediumRoom","largeRoom","mediumHall","largeHall","plate","mediumChamber","largeChamber","cathedral","largeRoom2","mediumHall2","mediumHall3","largeHall2"], before: reverbLabel.text!)
            break
        }

    }
    
    //ダイアログを押下すること
    func dialog(title: String, message:String, tag: Int, array: [String], before: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)

        for item in array {
            let okAction = UIAlertAction(title: item, style: UIAlertActionStyle.default){ (action: UIAlertAction) in
                self.setTypeLabel(tag: tag, item:item)
            }
            alertController.addAction(okAction)
        }

        let cancelButton = UIAlertAction(title: "CANCEL", style: UIAlertActionStyle.cancel){ (action: UIAlertAction) in
            self.setTypeLabel(tag: tag, item:before)
        }
        alertController.addAction(cancelButton)
        present(alertController,animated: true,completion: nil)
    }
    
    func setTypeLabel(tag: Int, item:String) {
         let userDefault = UserDefaults.standard
        switch tag {
        case 1:
            self.distortionLabel.text = item
            userDefault.setValue(item, forKeyPath: "distortionLabel")
            break
        case 2:
            self.eqLabel.text = item
            userDefault.setValue(item, forKeyPath: "eqLabel")
            break
        default:
            self.reverbLabel.text = item
            userDefault.setValue(item, forKeyPath: "reverbLabel")
            break
        }
    }
    
    
}

