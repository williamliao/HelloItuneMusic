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
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
}

extension ItemSearchViewModel {
    
    func searchTask() async throws {
        
        guard let enPoint = EndPoint.search(matching: "").url else {
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
                    break
                
                case .failure(let error):
                    print("searchRepositories \(error)")
                    showError?(error)
            }
            
        }  catch  {
            isFetching = false
            print("searchRepositories error \(error)")
            showError?(error as? NetworkError ?? NetworkError.unKnown)
        }
        
    }
}
