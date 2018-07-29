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
    
    func startRecode() {
        print("録音スタート")
        print(self.microPhoneCheck())
        if voiceFileName.text != "" {
        } else {
            dialog()
            return
        }
        
        
        if self.microPhoneCheck(){ return }
        if !isRecording {
            //タイマーが動いている状態で押されたら処理しない
            if timer.isValid == true {
                return
            }
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateElapsedTime), userInfo: nil, repeats: true)
            
            let session = AVAudioSession.sharedInstance()
            try! session.setCategory(AVAudioSessionCategoryRecord)
            try! session.setActive(true)
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try! AVAudioRecorder(url: getURL(fileName: voiceFileName.text!), settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            //画面がlockしないように対応
            UIApplication.shared.isIdleTimerDisabled = true
            isRecording = true
            label.text = "録音中"
            playButton.isEnabled = false
            recodeButtonHidden(hidden: true)
        }else{
            
            audioRecorder.stop()
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
            self.audioRecorder.updateMeters()
            print("-----power------")
            print(self.audioRecorder.peakPower(forChannel: 1))
            print(self.audioRecorder.peakPower(forChannel: 2))
            print(self.audioRecorder.averagePower(forChannel: 0))
            print(self.audioRecorder.averagePower(forChannel: 1))
            label.text = "録音中:" + String(format:"%02d:%02d",min, sec) + ", 音量(Max50):" + String(Int(self.audioRecorder.averagePower(forChannel: 2)))
        } else {
            let playerMin: Int = Int(audioPlayer.duration / 60)
            let playerSec: Int = Int(audioPlayer.duration) % 60
            label.text = "再生中 : " + String(format:"%02d:%02d/",min, sec) +  String(format:"%02d:%02d",playerMin, playerSec)
        }
    }
    
    
}

