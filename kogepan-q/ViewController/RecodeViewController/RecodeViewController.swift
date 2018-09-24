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

class RecodeViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, AudioEngineManagerDelegate {
    
    

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
    var distortionType: String = "doNotUse"
    var eqType: String = "doNotUse"
    var reverbType: String = "doNotUse"
    
    //MARK: - メイン処理
    override func viewDidLoad() {
        self.navigationController?.navigationBar.tintColor = UIColor.red
        self.setUserDefalts()
        self.title = NSLocalizedString("voiceRecording", comment: "")
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
        audioEngineMnager.delegate = self
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
        
        if let type = userDefault.object(forKey: "distortionLabel") as? String {
            distortionLabel.text = NSLocalizedString(type, comment: "")
            distortionType = type == "利用しない" ? "doNotUse" : type
        }
        
        if let type = userDefault.object(forKey: "eqLabel") as? String{
            eqLabel.text = NSLocalizedString(type, comment: "")
            eqType = type == "利用しない" ? "doNotUse" : type
        }
        
        if let type = userDefault.object(forKey: "reverbLabel") as? String {
            reverbLabel.text = NSLocalizedString(type, comment: "")
            reverbType = type == "利用しない" ? "doNotUse" : type
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
                                     distortion: distortionType,
                                     eq: eqType,
                                     reverb: reverbType)
            //タイマーが動いている状態で押されたら処理しない
            if timer.isValid == true {
                return
            }
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateElapsedTime), userInfo: nil, repeats: true)
            //画面がlockしないように対応
            UIApplication.shared.isIdleTimerDisabled = true
            isRecording = true
            label.text = NSLocalizedString("recording", comment: "")
            playButton.isEnabled = false
            recodeButtonHidden(hidden: true)
            
        case .isRecording:
            audioEngineMnager.stopRecord()
            
            
            //audioRecorder.stop()
            isRecording = false
            label.text = NSLocalizedString("converting", comment: "")
            UIApplication.shared.isIdleTimerDisabled = false
            //タイマーを停止
            timer.invalidate()
            count = 0
            recodeButton.isEnabled = false
            
            let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
            try! audioSession.setCategory(AVAudioSessionCategoryPlayback)
            recodeButtonHidden(hidden: false)
            
            
        case .isPlaying: break
        }
        
    }
    
    func changeCafToAccfinish() {
        DispatchQueue.main.async {
            self.label.text = NSLocalizedString("waiting", comment: "")
            self.recodeButton.isEnabled = true
            self.playButton.isEnabled = true
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
            label.text = NSLocalizedString("playing", comment: "")
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
        label.text = NSLocalizedString("waiting", comment: "")
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
        let alertController = UIAlertController(title: NSLocalizedString("noFileName", comment: ""),message: NSLocalizedString("canRecordConditions", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
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
            label.text = NSLocalizedString("recording", comment: "") + ":" + String(format:"%02d:%02d",min, sec)
        } else {
            let playerMin: Int = Int(audioPlayer.duration / 60)
            let playerSec: Int = Int(audioPlayer.duration) % 60
            label.text = NSLocalizedString("playing", comment: "")  + " : " + String(format:"%02d:%02d/",min, sec) +  String(format:"%02d:%02d",playerMin, playerSec)
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
            dialog(title: NSLocalizedString("distortionType", comment: ""), message:"", tag: 1, array: ["doNotUse","drumsBitBrush","drumsBufferBeats","drumsLoFi","multiBrokenSpeaker","multiCellphoneConcert","multiDecimated1","multiDecimated2","multiDecimated3","multiDecimated4","multiDistortedFunk","multiDistortedCubed","multiDistortedSquared","multiEcho1","multiEcho2","multiEchoTight1","multiEchoTight2","multiEverythingIsBroken","speechAlienChatter","speechCosmicInterference","speechGoldenPi","speechRadioTower","speechWaves"], before: distortionLabel.text!)
            break
        case 2:
            dialog(title: NSLocalizedString("eqType", comment: ""), message:"", tag: 2, array: ["doNotUse","parametric","lowPass","highPass","resonantLowPass","resonantHighPass","bandPass","bandStop","lowShelf","highShelf","resonantLowShelf","resonantHighShelf"], before: eqLabel.text!)
            break
        default:
            dialog(title: NSLocalizedString("reverbType", comment: ""), message:"", tag: 3, array: ["doNotUse","smallRoom","mediumRoom","largeRoom","mediumHall","largeHall","plate","mediumChamber","largeChamber","cathedral","largeRoom2","mediumHall2","mediumHall3","largeHall2"], before: reverbLabel.text!)
            break
        }

    }
    
    //ダイアログを押下すること
    func dialog(title: String, message:String, tag: Int, array: [String], before: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)

        for item in array {
            let okAction = UIAlertAction(title: NSLocalizedString(item, comment: ""), style: UIAlertActionStyle.default){ (action: UIAlertAction) in
                self.setTypeLabel(tag: tag, item: item)
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
            self.distortionLabel.text = NSLocalizedString(item, comment: "")
            self.distortionType = item
            userDefault.setValue(item, forKeyPath: "distortionLabel")
            break
        case 2:
            self.eqLabel.text = NSLocalizedString(item, comment: "")
            self.eqType = item
            userDefault.setValue(item, forKeyPath: "eqLabel")
            break
        default:
            self.reverbLabel.text = NSLocalizedString(item, comment: "")
            self.reverbType = item
            userDefault.setValue(item, forKeyPath: "reverbLabel")
            break
        }
    }
    
    
}

