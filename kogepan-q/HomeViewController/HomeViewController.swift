//
//  ViewController.swift
//  kogepan-q
//
//  Created by 堅固潤也 on 2018/05/20.
//  Copyright © 2018年 堅固潤也. All rights reserved.
// 緑: rgb(6, 169, 10)

import UIKit
import Firebase
import TwitterKit
import RxSwift
import RxCocoa

class HomeViewController: UIViewController {

    @IBOutlet weak var shareButton: UIButton!
    let dis = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        shareButton.rx.tap.bind{
                self.shareAction()
            }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func shareAction() {
        // Documentディレクトリ
        let documentDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, .userDomainMask, true).last!
        
        // 送信するファイル名
        let filename = "recording.m4a"
        
        // 送信ファイルのパス
        let targetDirPath = "\(documentDir)/\(filename)"
        
        let documentInteraction = UIDocumentInteractionController(url: URL(fileURLWithPath: targetDirPath))
        
        if !documentInteraction.presentOpenInMenu(from: self.view.frame, in: self.view, animated: true) {
            // 送信できるアプリが見つからなかった時の処理
            let alert = UIAlertController(title: "送信失敗", message: "ファイルを送れるアプリが見つかりません", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

        
    }

//    @IBAction func twitterLogin(_ sender: Any) {
//        print("Twitterログイン")
//        let logInButton = TWTRLogInButton(logInCompletion: { session, error in
//            if (session != nil) {
//                let authToken = session?.authToken
//                let authTokenSecret = session?.authTokenSecret
//                let credential = TwitterAuthProvider.credential(withToken: authToken, secret: authTokenSecret)
//                Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
//                    if let error = error {
//                        // ...
//                        return
//                    }
//                    // User is signed in
//                    // ...
//                }
//            } else {
//            }
//        })
//    }
}

