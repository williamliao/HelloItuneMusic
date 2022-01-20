//
//  ItemSearchViewModel.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/20.
//

import Foundation

class ItemSearchViewModel {
    let apiClient: APIClient
    
    private(set) var isFetching = false
    var reloadCollectionView: (() -> Void)?
    var showError: ((_ error:NetworkError) -> Void)?
    var searchModel: ItemSearchModel!
    var searchItem = [SearchItem]()
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
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
                    let item = SearchItem(id: UUID() ,name: result.trackName, longDescription: result.longDescription, artworkUrl100: result.artworkUrl100)
                    searchItem.append(item)
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
}
