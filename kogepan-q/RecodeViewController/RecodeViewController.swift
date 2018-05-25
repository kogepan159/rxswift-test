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

class RecodeViewController: UIViewController {

    let dis = DisposeBag()
    override func viewDidLoad() {
        self.title = "音声録音"
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func twitterLogin(_ sender: Any) {
        print("Twitterログイン")
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
    }
}

