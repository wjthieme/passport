//
//  AppDelegate.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 05/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    internal var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            UserDefaults.standard.set("\(version)", forKey: "appVersion")
        }
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = CameraController()
        window?.makeKeyAndVisible()
        
        return true
    }


}

