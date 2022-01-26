//
//  AppCoordinator.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/26.
//

import UIKit
import RxSwift

class AppCoordinator: BaseCoordinator<Void> {

    private let window: UIWindow
    private let scene: UIWindowScene?

    init(window: UIWindow, scene: UIWindowScene?) {
        self.window = window
        self.scene = scene
    }

    override func start() -> Observable<Void> {
        let itunesSearchCoordinator = ItunesSearchCoordinator(window: window, scene: scene)
        return coordinate(to: itunesSearchCoordinator)
    }
}
