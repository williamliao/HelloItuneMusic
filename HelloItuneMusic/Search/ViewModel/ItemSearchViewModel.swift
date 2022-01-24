//
//  ItemSearchViewModel.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/20.
//

import Foundation
import RxSwift
import RxCocoa

enum ItemSearchCellType {
    case normal(item: SearchItem)
    case error(message: String)
    case empty
}

extension ItemSearchCellType: Hashable {

    func hash(into hasher: inout Hasher) {

        switch self {
        case .normal(let value):
            hasher.combine(value)
        case .error(let value):
            hasher.combine(value)
        case .empty:
            break
        }
    }
}

class ItemSearchViewModel {
    private let apiClient: APIClient
    
    private var decoder = JSONDecoder()
    private let urlSession: URLSession

    var subItems : [SearchItem] = []
    
    private let disposeBag = DisposeBag()
    let cells = BehaviorRelay<[ItemSearchCellType]>(value: [])
    var searchItemCells: Observable<[ItemSearchCellType]> {
        return cells.asObservable()
    }

    init(apiClient: APIClient, urlSession: URLSession = .shared) {
        self.apiClient = apiClient
        self.urlSession = urlSession
    }
}

extension ItemSearchViewModel {
    
    func searchTask(term: String) async throws {
        
        subItems.removeAll()
        
        guard let enPoint = EndPoint.search(matching: term).url else {
            throw NetworkError.invalidURL
        }

        do {
            let result = try await apiClient.fetch(enPoint, decode: { json -> ItemSearchModel? in
                guard let feedResult = json as? ItemSearchModel else { return  nil }
                return feedResult
            })
            
            switch result {
                case .success(let responseObject):

                    if responseObject.results.count == 0 {
                        cells.accept([.empty])

                        return
                    }

                    responseObject.results.forEach { result in
                        let item = SearchItem(id: UUID() ,name: result.trackName, longDescription: result.longDescription, artworkUrl100: result.artworkUrl100, previewUrl: result.previewUrl)
                        subItems.append(item)
                    }
                
                    cells.accept(responseObject.results.compactMap {
                      
                        .normal(item: SearchItem(id: UUID() ,name: $0.trackName, longDescription: $0.longDescription, artworkUrl100: $0.artworkUrl100, previewUrl: $0.previewUrl))
                        
                    })
               
                case .failure(let error):
                    cells.accept([.error( message: (error.localizedDescription))])
            }
            
        }  catch  {
            cells.accept([.error( message: (error.localizedDescription))])
        }
        
    }
    
    func searchByTerm(term: String) {
        
        subItems.removeAll()

        apiClient.getSearchByTerm(term: term)
                .subscribe(
                    onNext: { [weak self] responseObject in

                        guard responseObject.count > 0 else {
                            self?.cells.accept([.empty])
                            return
                        }
                        
                        self?.cells.accept(responseObject.compactMap {
                            
                            .normal(item: $0)
                            
                        })
                        
                        self?.subItems.append(contentsOf: responseObject)
                        
                    },
                    onError: { [weak self] error in
                
                        self?.cells.accept([.error( message: (error.localizedDescription))])
                    }
                )
                .disposed(by: disposeBag)
    }
}
