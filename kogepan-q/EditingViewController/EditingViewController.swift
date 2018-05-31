//
//  ViewController.swift
//  kogepan-q
//
//  Created by 堅固潤也 on 2018/05/20.
//  Copyright © 2018年 堅固潤也. All rights reserved.
//

import UIKit
import Firebase
import TwitterKit
import RxSwift
import RxCocoa
import AVFoundation


class EditingViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    @IBOutlet weak var playButton: UIButton!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var isRecording = false
    var isPlaying = false
    let dis = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "音声編集"
        playButton.rx.tap.bind(){
            self.play()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getURL() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        let url = docsDirect.appendingPathComponent("recording.m4a")
        return url
    }
    
    func microPhoneCheck() -> Int {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        
        if status == AVAuthorizationStatus.authorized {
            return 1
            // アクセス許可あり
        } else if status == AVAuthorizationStatus.restricted {
            // ユーザー自身にカメラへのアクセスが許可されていない
            return 2
        } else if status == AVAuthorizationStatus.notDetermined {
            // まだアクセス許可を聞いていない
            return 0
        } else if status == AVAuthorizationStatus.denied {
            // アクセス許可されていない
            return 2
        }
        return 0
    }
    
    func play(){
        if self.microPhoneCheck() != 1{ return }
        if !isPlaying {
            audioPlayer = try! AVAudioPlayer(contentsOf: getURL())
            audioPlayer.delegate = self as AVAudioPlayerDelegate
            audioPlayer.play()
            
            isPlaying = true
            
            playButton.setTitle("STOP", for: .normal)
        }else{
            
            audioPlayer.stop()
            isPlaying = false
            playButton.setTitle("PLAY", for: .normal)
            
        }
    }
}

