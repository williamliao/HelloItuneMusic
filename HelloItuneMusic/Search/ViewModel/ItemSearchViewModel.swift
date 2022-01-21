//
//  ItemSearchViewModel.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/20.
//

import Foundation
import RxSwift

enum ItemSearchCellType {
    case normal
    case error(message: String)
    case empty
}

class ItemSearchViewModel {
    let apiClient: APIClient
    
    private(set) var isFetching = false
    private let disposeBag = DisposeBag()
    
    var reloadCollectionView: (() -> Void)?
    var showError: ((_ error:NetworkError) -> Void)?
    var searchModel: ItemSearchModel!
    var decoder = JSONDecoder()

    var subItems : [SearchItem] = []
    let urlSession: URLSession
    
    init(apiClient: APIClient, urlSession: URLSession = .shared) {
        self.apiClient = apiClient
        self.urlSession = urlSession
    }
}

extension ItemSearchViewModel {
    
    func searchTask(term: String) async throws {
        
        guard let enPoint = EndPoint.search(matching: term).url else {
            throw NetworkError.invalidURL
        }

        do {
            let result = try await apiClient.fetch(enPoint, decode: { [self]  json -> ItemSearchModel? in
                isFetching = false
                guard let feedResult = json as? ItemSearchModel else { return  nil }
                return feedResult
            })
            
            switch result {
                case .success(let responseObject):
                    searchModel = responseObject

                    searchModel.results.forEach { result in
                        let item = SearchItem(id: UUID() ,name: result.trackName, longDescription: result.longDescription, artworkUrl100: result.artworkUrl100, previewUrl: result.previewUrl)
                        subItems.append(item)
                    }
                
                    reloadCollectionView?()
                case .failure(let error):
                    print("searchTask \(error)")
                    showError?(error)
            }
            
        }  catch  {
            isFetching = false
            print("searchTask error \(error)")
            showError?(error as? NetworkError ?? NetworkError.unKnown)
        }
        
    }
    
    func searchByTerm(term: String) -> Observable<[SearchItem]> {
        
        guard let enPoint = EndPoint.search(matching: term).url else {
            return .just([])
        }
        
        return Observable.create { [self] observer in

            urlSession.rx.data(request: URLRequest(url: enPoint))
                .subscribe(onNext: { data in
                  
                    do {
                        let responseObject = try decoder.decode(ItemSearchModel.self, from: data)
                        
                        responseObject.results.forEach { result in
                            let item = SearchItem(id: UUID() ,name: result.trackName, longDescription: result.longDescription, artworkUrl100: result.artworkUrl100, previewUrl: result.previewUrl)
                            subItems.append(item)
                        }
                        
                        observer.onNext( subItems )
                        observer.onCompleted()
                        
                    } catch  {
                        print("error \(error)")
                    }
 
                }, onError: { error in
                    print("Data Task Error: \(error)")
                })
                .disposed(by: disposeBag)
            
            return Disposables.create()
        }
    }
}
