//
//  ApiSearchTest.swift
//  HelloItuneMusicTests
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/24.
//

import XCTest
import RxSwift
@testable import HelloItuneMusic

class ApiSearchTest: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

extension ApiSearchTest {
    
    func testLoadJsonData(){
        let result: ItemSearchModel = decode(from: "ituneSearch", with: "json")
        
        XCTAssertNotNil(result)
    }
    
    func testDecoding() throws {
        guard let jsonData = decodeToData(from: "ituneSearch", with: "json") else {
            XCTFail("Missing file: ituneSearch.json")
            return
        }

        XCTAssertNoThrow(try JSONDecoder().decode(ItemSearchModel.self, from: jsonData))
    }
    
    @available(iOS 13.0, *)
    func testSearchData() async {
        let viewModel = ItemSearchViewModel(apiClient: APIClient())
        
        do {
            let _ = try await viewModel.searchTask(term: "jason mars")
            
            XCTAssertEqual(50, viewModel.subItems.count)
            
        } catch  {
            
        }
    }
    
    func testRxSearchData() {
        let disposeBag = DisposeBag()
        let apiClient = MockAppServerClient()
        
        let result: ItemSearchModel = decode(from: "ituneSearch", with: "json")
        var items = [SearchItem]()

        items = result.results.compactMap {
             SearchItem(id: UUID() ,name: $0.trackName, longDescription: $0.longDescription, artworkUrl100: $0.artworkUrl100, previewUrl: $0.previewUrl)
        }
        
        apiClient.getSearchResult = .success(items)
        
        let viewModel = ItemSearchViewModel(apiClient: apiClient)
        viewModel.searchByTerm(term: "jason mars")
        
        let expectNormalSearchCellCreated = expectation(description: "searchCells contains a normal cell")
 
        viewModel.searchItemCells.subscribe(
            onNext: {
                let firstCellIsNormal: Bool

                if case.some(.normal(_)) = $0.first {

                    firstCellIsNormal = true
                } else {
                    firstCellIsNormal = false
                }
                XCTAssertTrue(firstCellIsNormal)
                expectNormalSearchCellCreated.fulfill()
            }
        ).disposed(by: disposeBag)
        wait(for: [expectNormalSearchCellCreated], timeout: 0.1)
    }
}

private final class MockAppServerClient: APIClient {
    
    var getSearchResult: Result<[SearchItem], NetworkError>?
    
    override func getSearchByTerm(term: String) -> Observable<[SearchItem]> {
        return Observable.create { observer in
            switch self.getSearchResult {
            case .success(let result)?:
                observer.onNext(result)
            case .failure(let error)?:
                observer.onError(error)
            case .none:
                observer.onError(NetworkError.notFound)
            }
            return Disposables.create()
        }
    }
}
