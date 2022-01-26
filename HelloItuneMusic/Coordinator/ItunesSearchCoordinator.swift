//
//  ItunesSearchCoordinator.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/26.
//

import UIKit
import RxSwift
import SafariServices

class ItunesSearchCoordinator: BaseCoordinator<Void> {
    private let window: UIWindow
    private let scene: UIWindowScene?

    init(window: UIWindow, scene: UIWindowScene?) {
        self.window = window
        self.scene = scene
    }
    
    override func start() -> Observable<Void> {
        let viewModel = ItemSearchViewModel(apiClient: APIClient())
        //let viewController = ItemSearchViewController.initFromStoryboard(name: "Main")
        let viewController = ItemSearchViewController()
        viewController.view.backgroundColor = .systemBackground
        let navigationController = UINavigationController(rootViewController: viewController)
        viewController.viewModel = viewModel
        viewController.renderView()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        window.windowScene = scene

        return Observable.never()
    }
}
