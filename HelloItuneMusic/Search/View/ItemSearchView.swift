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
import RxDataSources
import Differentiator

struct MySection {
    var header: String
    var items: [Item]
}

extension MySection : AnimatableSectionModelType {
    typealias Item = ItemSearchCellType

    var identity: String {
        return header
    }

    init(original: MySection, items: [Item]) {
        self = original
        self.items = items
    }
}

class ItemSearchView: UIView {
    
    private enum Section: CaseIterable {
        case main
    }
    
    var searchViewController: UISearchController!
    var collectionView: UICollectionView!
    
    var viewModel: ItemSearchViewModel
    var navItem: UINavigationItem
    private let disposeBag = DisposeBag()
    
    var audioIndex = Set<IndexPath>()
    
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
    
    private var searchDataSource: UICollectionViewDiffableDataSource<Section, ItemSearchCellType>!
    var dataSource: RxCollectionViewSectionedReloadDataSource<MySection>?
}

// MARK: - View
extension ItemSearchView {
    func configureView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInsetReference = .fromContentInset
        flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        flowLayout.minimumInteritemSpacing = 10
        flowLayout.minimumLineSpacing = 10
        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 15.0, *) {
            collectionView.dataSource = self.searchDataSource
            configureDataSource()
        }
        
        bindSearchItem()
        collectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
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

extension ItemSearchView: UICollectionViewDelegateFlowLayout {}

// MARK: - RxCollectionViewSectionedReloadDataSource
extension ItemSearchView {
    func configureRxDataSource() {
        let dataSource = RxCollectionViewSectionedReloadDataSource<MySection>(
            configureCell: { [self] dataSource, collectionView, indexPath, item in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ItemSearchCell.reuseIdentifier, for: indexPath) as! ItemSearchCell
                
                switch item {
                case .normal(let itemIdentifier):
                    configureDataSource(cell: cell, itemIdentifier: itemIdentifier, index: indexPath.row)
                    cell.playButton.isHidden = false
                case .error(let message):
                    cell.nameLabel.text = message
                    cell.playButton.isHidden = true
                case .empty:
                    cell.nameLabel.text = "No data available"
                    cell.playButton.isHidden = true
                }
                
                return cell
            }
        )
        
        self.dataSource = dataSource
    }
    
    func applyInitialRxDataSource() {
        
        var sections = [MySection]()
        
        let cells: Observable<[ItemSearchCellType]> = viewModel.cells
            .flatMap { Observable.from($0).map { $0 }.toArray() }
        
        cells
        .observe(on: MainScheduler.instance)
        .subscribe { items in
            
            guard let cell = items.element else {
                return
            }
            sections.append(MySection(header: "First section", items: cell))
        }
        .disposed(by: disposeBag)
        
        
        guard let dataSource = dataSource else {
            print("no dataSource")
            return
        }
        
        Observable.just(sections)
                .bind(to: collectionView.rx.items(dataSource: dataSource))
                .disposed(by: disposeBag)
    }
}

// MARK: - UICollectionViewDiffableDataSource
extension ItemSearchView {
    func configureDataSource() {
       
        if #available(iOS 15.0, *) {
            
            let configuredMainCell = UICollectionView.CellRegistration<ItemSearchCell, ItemSearchCellType> { [self] (cell, indexPath, itemIdentifier) in
                
                switch itemIdentifier {
                    case .normal( let item):
                        configureDataSource(cell: cell, itemIdentifier: item, index: indexPath.row)
                        cell.playButton.isHidden = false
                    case .error(let message):
                        cell.nameLabel.text = message
                        cell.playButton.isHidden = true
                    case .empty:
                        cell.nameLabel.text = "NO Data Avaliable"
                        cell.playButton.isHidden = true
                }
            }
            
            searchDataSource = UICollectionViewDiffableDataSource<Section, ItemSearchCellType>(collectionView: collectionView) {
                (collectionView: UICollectionView, indexPath: IndexPath, identifier: ItemSearchCellType) -> ItemSearchCell? in
                return collectionView.dequeueConfiguredReusableCell(using: configuredMainCell, for: indexPath, item: identifier)
            }
            
        } else {
            // Fallback on earlier versions
            searchDataSource = UICollectionViewDiffableDataSource<Section, ItemSearchCellType>(collectionView: collectionView) {
                (collectionView: UICollectionView, indexPath: IndexPath, identifier: ItemSearchCellType) -> UICollectionViewCell? in
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
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, ItemSearchCellType>()
       // snapshot.deleteAllItems()
 
        Section.allCases.forEach { snapshot.appendSections([$0]) }
        searchDataSource.apply(snapshot, animatingDifferences: false)

        let cells: Observable<[ItemSearchCellType]> = viewModel.cells
            .flatMap { Observable.from($0).map { $0 }.toArray() }
        
        cells
        .observe(on: MainScheduler.instance)
        .subscribe { [self] items in
            
            guard let cell = items.element else {
                return
            }
            snapshot.appendItems(cell, toSection: .main)
            searchDataSource.apply(snapshot, animatingDifferences: false)
            
        }
        .disposed(by: disposeBag)
    }
}

// MARK: - UISearchBarDelegate
extension ItemSearchView: UISearchBarDelegate {
   
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        guard let searchText = searchBar.text else {
            return
        }

        let whitespaceCharacterSet = CharacterSet.whitespaces
        let strippedString =
            searchText.trimmingCharacters(in: whitespaceCharacterSet)

        if #available(iOS 15.0, *) {
            Task {
                try await viewModel.searchTask(term: strippedString)
            }
        } else {
             viewModel.searchByTerm(term: strippedString)
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

// MARK: - Bind
extension ItemSearchView {
    func bindSearchItem() {

        if #available(iOS 15.0, *) {
            viewModel.searchItemCells
                .observe(on: MainScheduler.instance)
                .subscribe { [self] elements in
                    DispatchQueue.main.async {
                        if let count = elements.element?.count {
                            if count > 0 {
                                applyInitialSnapshots()
                            }
                        }
                    }
                }
                .disposed(by: disposeBag)
        } else {
            viewModel.searchItemCells
                .bind(to: collectionView.rx.items(
                    cellIdentifier: ItemSearchCell.reuseIdentifier,
                    cellType: ItemSearchCell.self
                )) { [self] row, element, cell in

                    switch element {
                    case .normal(let itemIdentifier):
                        configureDataSource(cell: cell, itemIdentifier: itemIdentifier, index: row)
                        cell.playButton.isHidden = false
                    case .error(let message):
                        cell.nameLabel.text = message
                        cell.playButton.isHidden = true
                    case .empty:
                        cell.nameLabel.text = "No data available"
                        cell.playButton.isHidden = true
                    }
                }
                .disposed(by: disposeBag)
        }
    }
}

// MARK: - Private
extension ItemSearchView {
    
    func configureDataSource(cell: ItemSearchCell, itemIdentifier: SearchItem, index: Int) {
        
        let indexPath = IndexPath(item: index, section: 0)
        
        let cellViewModel = ItemSearchCellViewModel(itemIdentifier: itemIdentifier)
        cell.viewModel = cellViewModel
        audioIndex.insert(indexPath)

        cellViewModel.playAction = { [self] in
            for audioIndexPath in audioIndex {
                let tempCell = self.collectionView.cellForItem(at: audioIndexPath)
                 if let specificTempCell = tempCell as? ItemSearchCell, specificTempCell != cell{
                     specificTempCell.stopPlayAfterTapOtherCell()
                 }
             }
        }
    }
}
