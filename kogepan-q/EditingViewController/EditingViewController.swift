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



class EditingViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, EZAudioFileDelegate {

    @IBOutlet weak var viewhakei: UIView!
    @IBOutlet weak var fileSelectButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var label: UILabel!
    var timer: Timer = Timer()
    var count: Int = 0
    @IBOutlet weak var fileNamelabel: UILabel!
    
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
        self.title = "音声編集"
        playButton.rx.tap.bind(){
            self.play()
        }
        
        fileSelectButton.rx.tap.bind(){
            self.fileSelect()
        }
        
        
    }
    
    func setWaveform() {
        //波形
        self.audioPlot = EZAudioPlot(frame: self.viewhakei.frame)
        self.audioPlot.backgroundColor = UIColor.cyan
        self.audioPlot.color = UIColor.purple
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
    
    func play(){
        if fileName.isEmpty {
            dialog(title: "fileを選択してください", message:"file選択は、下のファイル選択ボタンを押下してください。", isFileSelect:false)
            return
        }
       
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
                            self.fileName = item
                            self.fileNamelabel.text = "ファイル名: " + item
                            self.setWaveform()
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
    
    //
    //  一定間隔で実行される処理
    //
    @objc func updateElapsedTime() {
        count += 1
        let min: Int = count / 60
        let sec: Int = count % 60
        label.text = "再生中 : " + String(format:"%02d:%02d",min, sec)
    }
    
}

