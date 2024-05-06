//
//  AppDelegate.swift
//  FilterMSL
//
//  Created by 陈逸安 on 4/29/24.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Assuming FiltersViewController is your start page
        let initialViewController = FiltersViewController()
        let navigationController = UINavigationController(rootViewController: initialViewController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        return true
    }
}
