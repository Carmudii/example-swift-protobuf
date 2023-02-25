//
//  AppDelegate.swift
//  swift-protobuf
//
//  Created by Car mudi on 25/02/23.
//

import UIKit
import Starscream

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureRootViewController()

        return true
    }

    private func configureRootViewController() {


        let viewController = HomeViewController(socket: createWebSocketURL())
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: viewController)
        window?.makeKeyAndVisible()
    }

    private func createWebSocketURL() -> WebSocket {
        var socketURL = URLRequest(url: URL(string: "ws://localhost:8080/ws")!)
        socketURL.timeoutInterval = 5

        let pinner = FoundationSecurity(allowSelfSigned: true)
        let webSocketConnection = WebSocket(request: socketURL, certPinner: pinner)

        return webSocketConnection
    }

}

