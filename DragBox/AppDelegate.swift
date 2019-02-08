//
//  AppDelegate.swift
//  DragBox
//
//  Created by HIROTA Ichiro on 2019/01/11.
//  Copyright © 2019 HIROTA Ichiro. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    func application(_ app: UIApplication, open inputURL: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let navi = window?.rootViewController as? UINavigationController {
            for vc in navi.viewControllers.reversed() {
                if let filesVC = vc as? FilesViewController {
                    return filesVC.openURL(inputURL: inputURL)
                }
            }
        }
        return false
    }
}
