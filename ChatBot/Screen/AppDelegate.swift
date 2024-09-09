//
//  AppDelegate.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/11.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupNavigationBar()
        setupTabbar()
        return true
    }
    
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .fromAppColors(\.lightCoffeeButton)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.fromAppColors(\.darkCoffeeText)]
        appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.fromAppColors(\.darkCoffeeText)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor =  UIColor.fromAppColors(\.darkCoffeeText)
    }
    
    private func setupTabbar() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.backgroundColor = .fromAppColors(\.lightCoffeeButton)
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = .fromAppColors(\.creamBackground)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.fromAppColors(\.creamBackground)]
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .fromAppColors(\.normalText)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.fromAppColors(\.normalText)]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

