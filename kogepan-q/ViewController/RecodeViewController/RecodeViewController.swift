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
    @IBOutlet weak var distortionSilder: UISlider!
    @IBOutlet weak var eqSilder: UISlider!
    @IBOutlet weak var reverbSilder: UISlider!
    
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
        
        // setUp audioEngine.
        audioEngineMnager.setup()
        
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
        
        if userDefault.object(forKey: "distortionValue") != nil {
            let value = userDefault.float(forKey: "distortionValue")
            distortionSilder.value = value
            distortionLabel.text = String(format:"%.02f",value)
        }
        
        if userDefault.object(forKey: "eqValue") != nil {
            let value = userDefault.float(forKey: "eqValue")
            eqSilder.value = value
            eqLabel.text = String(format:"%.02f",value)
        }
        
        if userDefault.object(forKey: "reverbValue") != nil {
            let value = userDefault.float(forKey: "reverbValue")
            reverbSilder.value = value
            reverbLabel.text = String(format:"%.02f",value)
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
            audioEngineMnager.record(fileName: voiceFileName.text!)
            
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
        switch sender.tag {
        case 1:
            delayLabel.text = setValueString
            userDefault.setValue(sender.value, forKeyPath: "delayValue")
            break
        case 2:
            distortionLabel.text = String(format:"%.02f",sender.value)
            userDefault.setValue(sender.value, forKeyPath: "distortionValue")
            break
        case 3:
            eqLabel.text = String(format:"%.02f",sender.value)
            userDefault.setValue(setValueString, forKeyPath: "eqValue")
            break
        default:
            reverbLabel.text = String(format:"%.02f",sender.value)
            userDefault.setValue(sender.value, forKeyPath: "reverbValue")
            break
        }
    }
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        let userDefault = UserDefaults.standard
        userDefault.setValue(sender.isOn, forKeyPath: "bothPlaySwitch")
        
    }
    
    
}

