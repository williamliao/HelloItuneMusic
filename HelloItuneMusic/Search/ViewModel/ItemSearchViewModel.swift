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
    
    private let disposeBag = DisposeBag()

    var searchModel: ItemSearchModel!
    var decoder = JSONDecoder()

    var subItems : [SearchItem] = []
    let urlSession: URLSession
    
    let onShowError: PublishSubject<NetworkError> = PublishSubject()
    let searchItem: PublishSubject<[SearchItem]> = PublishSubject()

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
            let result = try await apiClient.fetch(enPoint, decode: { json -> ItemSearchModel? in
                guard let feedResult = json as? ItemSearchModel else { return  nil }
                return feedResult
            })
            
            switch result {
                case .success(let responseObject):

                    if responseObject.results.count == 0 {
                        onShowError.onNext( NetworkError.notFound )
                        onShowError.onCompleted()
                        return
                    }

                    responseObject.results.forEach { result in
                        let item = SearchItem(id: UUID() ,name: result.trackName, longDescription: result.longDescription, artworkUrl100: result.artworkUrl100, previewUrl: result.previewUrl)
                        subItems.append(item)
                    }
                
                    searchItem.onNext( subItems )
                    searchItem.onCompleted()
                
                case .failure(let error):
                    print("searchTask \(error)")
                    onShowError.onNext( error )
                    onShowError.onCompleted()
            }
            
        }  catch  {
            print("searchTask error \(error)")
            onShowError.onNext( error as? NetworkError ?? NetworkError.unKnown )
            onShowError.onCompleted()
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
                        onShowError.onNext( error as? NetworkError ?? NetworkError.unKnown )
                        onShowError.onCompleted()
                    }
 
                }, onError: { error in
                    onShowError.onNext( error as? NetworkError ?? NetworkError.unKnown )
                    onShowError.onCompleted()
                })
                .disposed(by: disposeBag)
            
            return Disposables.create()
        }
    }
}
