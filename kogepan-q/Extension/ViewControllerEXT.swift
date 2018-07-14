//
//  ViewController.swift
//  kogepan-q
//
//  Created by 堅固潤也 on 2018/05/20.
//  Copyright © 2018年 堅固潤也. All rights reserved.
//

import UIKit


extension UIViewController {
    func getURL(fileName: String, m4aAddFlag: Bool = true) -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        let url = docsDirect.appendingPathComponent((m4aAddFlag ? fileName + ".m4a" : fileName))
        return url
    }
    
}

