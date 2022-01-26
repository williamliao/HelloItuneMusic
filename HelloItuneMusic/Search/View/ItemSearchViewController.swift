//
//  ItemSearchViewController.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/20.
//

import UIKit

class ItemSearchViewController: UIViewController {
    
    var searchView: ItemSearchView!
    var viewModel: ItemSearchViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func renderView() {
       
        self.title = "Search"
        searchView = ItemSearchView(viewModel: viewModel, navItem: self.navigationItem)
        searchView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(searchView)
        
        NSLayoutConstraint.activate([
            searchView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            searchView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            searchView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            searchView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
        ])
    }
}
