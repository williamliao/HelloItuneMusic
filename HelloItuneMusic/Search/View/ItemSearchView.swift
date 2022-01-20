//
//  ItemSearchView.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/20.
//

import Foundation
import UIKit

class ItemSearchView: UIView {
    
    private enum Section: CaseIterable {
        case main
    }
    
    var searchViewController: UISearchController!
    var collectionView: UICollectionView!
    
    var viewModel: ItemSearchViewModel
    var navItem: UINavigationItem
    
    init(viewModel: ItemSearchViewModel, navItem: UINavigationItem) {
        self.viewModel = viewModel
        self.navItem = navItem
        super.init(frame: CGRect.zero)
        configureView()
        configureConstraints()
    }
 
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var searchDataSource: UICollectionViewDiffableDataSource<Section, Results>!
}

extension ItemSearchView {
    func configureView() {
        
    }
    
    func configureConstraints()  {
        NSLayoutConstraint.activate([
            
        ])
    }
}
