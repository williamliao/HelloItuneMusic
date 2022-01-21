//
//  ItemSearchView.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/20.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class ItemSearchView: UIView {
    
    private enum Section: CaseIterable {
        case main
    }
    
    var searchViewController: UISearchController!
    var collectionView: UICollectionView!
    
    var viewModel: ItemSearchViewModel
    var navItem: UINavigationItem
    var nameHeightDictionary: [IndexPath: CGFloat]?
    private let disposeBag = DisposeBag()
    
    let showSearchItem = PublishSubject<[SearchItem]>()
    
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
    
    private var searchDataSource: UICollectionViewDiffableDataSource<Section, SearchItem>!
}

// MARK: - View
extension ItemSearchView {
    func configureView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.estimatedItemSize = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 15.0, *) {
            collectionView.dataSource = self.searchDataSource
            configureDataSource()
        }
    
        collectionView.delegate = self

        if #available(iOS 13.0, *) {
            collectionView.register(ItemSearchCell.self, forCellWithReuseIdentifier: ItemSearchCell.reuseIdentifier)
        }
        
        self.addSubview(collectionView)
        
        searchViewController = UISearchController(searchResultsController: nil)
        searchViewController.searchBar.delegate = self
        searchViewController.definesPresentationContext = true
        searchViewController.searchBar.autocapitalizationType = .none
        searchViewController.searchBar.placeholder = "Search Iterm"

        navItem.searchController = searchViewController
        searchViewController.hidesNavigationBarDuringPresentation = false
        navItem.hidesSearchBarWhenScrolling = false
        
        viewModel.reloadCollectionView = { [weak self] in
            DispatchQueue.main.async {
                self?.applyInitialSnapshots()
            }
        }
    }
    
    func configureConstraints()  {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ItemSearchView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = UIScreen.main.bounds.size.width
        
        if viewModel.subItems.count == 0 {
            return CGSize(width: width, height: 44)
        }
        
        let res = viewModel.subItems[indexPath.row]
        
        var baseHeight: Double = 44.0 + 26.0
        let padding: Double = 22.0
        if let nameHeight = nameHeightDictionary?[indexPath] {
            baseHeight = baseHeight + nameHeight
        }
        
        if let longDescription = res.longDescription {
            
            let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
            let boundingBox = longDescription.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)], context: nil)
            
            return CGSize(width: width, height: baseHeight + ceil(boundingBox.height) + padding)
        } else {
            return CGSize(width: width, height: baseHeight + padding)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}

// MARK: - UICollectionViewDiffableDataSource
extension ItemSearchView {
    func configureDataSource() {
       
        if #available(iOS 14.0, *) {
            
            let configuredMainCell = UICollectionView.CellRegistration<ItemSearchCell, SearchItem> { [self] (cell, indexPath, itemIdentifier) in
                
                configureDataSource(cell: cell, itemIdentifier: itemIdentifier, index: indexPath.row)
            }
            
            searchDataSource = UICollectionViewDiffableDataSource<Section, SearchItem>(collectionView: collectionView) {
                (collectionView: UICollectionView, indexPath: IndexPath, identifier: SearchItem) -> ItemSearchCell? in
                return collectionView.dequeueConfiguredReusableCell(using: configuredMainCell, for: indexPath, item: identifier)
            }
            
        } else {
            // Fallback on earlier versions
            
            searchDataSource = UICollectionViewDiffableDataSource<Section, SearchItem>(collectionView: collectionView) {
                (collectionView: UICollectionView, indexPath: IndexPath, identifier: SearchItem) -> UICollectionViewCell? in
                return collectionView.dequeueReusableCell(withReuseIdentifier: ItemSearchCell.reuseIdentifier, for: indexPath)
            }
        }
    }
    
    func applyInitialSnapshots() {
        
        DispatchQueue.main.async { [weak self] in
            self?.updateSnapShot()
        }
    }
    
    func updateSnapShot() {
        configureSearchItem()
    }
    
    func configureSearchItem() {
       
        var snapshot = NSDiffableDataSourceSnapshot<Section, SearchItem>()
 
        Section.allCases.forEach { snapshot.appendSections([$0]) }
        searchDataSource.apply(snapshot, animatingDifferences: false)
        
        if  viewModel.subItems.count > 0 {
            snapshot.appendItems(viewModel.subItems, toSection: .main)
        } else {
            snapshot.appendItems([], toSection: .main)
        }
        
        searchDataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - UISearchBarDelegate
extension ItemSearchView: UISearchBarDelegate {
   
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

        if #available(iOS 15.0, *) {
            guard let searchText = searchBar.text else {
                return
            }

            let whitespaceCharacterSet = CharacterSet.whitespaces
            let strippedString =
                searchText.trimmingCharacters(in: whitespaceCharacterSet)

            Task {
                try await viewModel.searchTask(term: strippedString)
            }
        } else {
            let searchResults = searchBar.rx.text.orEmpty
                        .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
                        .distinctUntilChanged()
            
                        .flatMapLatest {  query -> Observable<[SearchItem]> in
                                if query.isEmpty {
                                    return .just([])
                                }
                            return self.viewModel.searchByTerm(term: query)
                                    .catchAndReturn([])
                            }
                        .observe(on: MainScheduler.instance)
            
            searchResults
                .bind(to: collectionView.rx.items(cellIdentifier: ItemSearchCell.reuseIdentifier)) { [self]
                    (index, itemIdentifier: SearchItem, cell: ItemSearchCell) in
                    
                    configureDataSource(cell: cell, itemIdentifier: itemIdentifier, index: index)
                    
                }
                .disposed(by: disposeBag)
        }
    }
    
    func configureDataSource(cell: ItemSearchCell, itemIdentifier: SearchItem, index: Int) {
        
        let indexPath = IndexPath(item: index, section: 0)
        
        cell.configureCell(name: itemIdentifier.name, des: itemIdentifier.longDescription, imageUrl: itemIdentifier.artworkUrl100, previewUrl: itemIdentifier.previewUrl)
        
        self.nameHeightDictionary?[indexPath] = cell.nameHeightConstraint.constant
        
        cell.playAction = { [self] in
            for tempCell in collectionView.visibleCells {
                 if let specificTempCell = tempCell as? ItemSearchCell, specificTempCell != cell{
                     specificTempCell.stopPlayAfterTapOtherCell()
                 }
             }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        closeSearchView()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            closeSearchView()
        }
    }
    
    func closeSearchView() {
        endEditing(true)
    }
}
