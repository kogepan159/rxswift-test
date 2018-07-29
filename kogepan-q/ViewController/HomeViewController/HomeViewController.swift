//
//  ViewController.swift
//  kogepan-q
//
//  Created by 堅固潤也 on 2018/05/20.
//  Copyright © 2018年 堅固潤也. All rights reserved.
// 緑: rgb(6, 169, 10)

import UIKit
import RxSwift
import RxCocoa

class HomeViewController: UIViewController {

    @IBOutlet weak var shareButton: UIButton!
    let dis = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.red
        // Do any additional setup after loading the view, typically from a nib.
        shareButton.rx.tap.bind{
                self.shareAction()
            }
        let menu: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "Image"), style:UIBarButtonItemStyle.done, target:self, action:#selector(self.TapMenu)) // アイコンを追加し、アイコンを押したときに"TapMenu()"が実行されるように指定
        self.navigationItem.setLeftBarButton(menu, animated: true)//rigltBarButtonItem = Menu // ナビゲーションバーにアイコンを追加
        
        let share: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action:#selector(self.shareAction)) // アイコンを追加し、アイコンを押したときに"TapMenu()"が実行されるように指定
        self.navigationItem.setRightBarButton(share, animated: true)//rigltBarButtonItem = Menu // ナビゲーションバーにアイコンを追加
    }
    
    @objc func TapMenu() {
        print("メニューがタップされました")
        let next = self.storyboard?.instantiateViewController(withIdentifier:"setting") as? SettingTableViewController
        self.navigationController?.pushViewController(next!, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @objc func shareAction() {
        
        let documentInteraction = UIDocumentInteractionController.init(url: getURL(fileName: "123"))
        
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

