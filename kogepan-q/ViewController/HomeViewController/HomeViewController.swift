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

class HomeViewController: UIViewController, UIDocumentInteractionControllerDelegate {

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
        
//        let share: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action:#selector(self.shareAction)) // アイコンを追加し、アイコンを押したときに"TapMenu()"が実行されるように指定
//        self.navigationItem.setRightBarButton(share, animated: true)//rigltBarButtonItem = Menu // ナビゲーションバーにアイコンを追加
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
    
    var documentInteraction:UIDocumentInteractionController!
    @objc func shareAction() {
        self.dialog(title: NSLocalizedString("shareTitle", comment: ""), message: NSLocalizedString("shareContext", comment: ""))
    }
    
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    public func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        documentInteraction = nil
    }
    
    func dialog(title: String, message:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
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
                        
                        self.sentShare(fileName: item)
                    }
                    alertController.addAction(okAction)
                }
            } catch let error {
                print(error)
            }
        }
        let cancelButton = UIAlertAction(title: "CANCEL", style: UIAlertActionStyle.cancel, handler: nil)
        alertController.addAction(cancelButton)
        
       
        present(alertController,animated: true,completion: nil)
    }
    
    func sentShare(fileName: String) {
        print(getURL(fileName: fileName, m4aAddFlag: false))
        documentInteraction = UIDocumentInteractionController()
        documentInteraction.url = getURL(fileName: fileName, m4aAddFlag: false)
        documentInteraction.delegate = self
        
        let shareWidth = self.view.frame.width/2
        let shareHeigth = self.view.frame.height/2
        if !documentInteraction.presentOpenInMenu(from: CGRect(x: shareWidth - 150, y: shareHeigth - 150, width: 300, height:300), in: self.view, animated: true) {
            // 送信できるアプリが見つからなかった時の処理
            let alert = UIAlertController(title: "送信失敗", message: "ファイルを送れるアプリが見つかりません", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

}

