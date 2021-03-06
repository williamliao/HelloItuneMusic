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
        
        let result = decode(from: "ituneSearch", with: "json")

        apiClient.getSearchResult = .success(result)
        
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
    
    func testEmptyFriendCells() {
        let disposeBag = DisposeBag()
        let appServerClient = MockAppServerClient()
        appServerClient.getSearchResult = .success(nil)

        let viewModel = ItemSearchViewModel(apiClient: appServerClient)
        viewModel.searchByTerm(term: "jason mars")

        let expectEmptyFriendCellCreated = expectation(description: "searchCells contains an empty cell")

        viewModel.searchItemCells.subscribe(
            onNext: {
                let firstCellIsEmpty: Bool

                if case.some(.empty) = $0.first {
                    firstCellIsEmpty = true
                } else {
                    firstCellIsEmpty = false
                }

                XCTAssertTrue(firstCellIsEmpty)
                expectEmptyFriendCellCreated.fulfill()
            }
        ).disposed(by: disposeBag)

        wait(for: [expectEmptyFriendCellCreated],timeout: 0.1)
    }
    
    func testErrorFriendCells() {
        let disposeBag = DisposeBag()
        let appServerClient = MockAppServerClient()
        appServerClient.getSearchResult = .failure(NetworkError.notFound)

        let viewModel = ItemSearchViewModel(apiClient: appServerClient)
        viewModel.searchByTerm(term: "jason mars")

        let expectErrorFriendCellCreated = expectation(description: "searchCells contains an error cell")

        viewModel.searchItemCells.subscribe(
            onNext: {
                let firstCellIsError: Bool

                if case.some(.error) = $0.first {
                    firstCellIsError = true
                } else {
                    firstCellIsError = false
                }

                XCTAssertTrue(firstCellIsError)
                expectErrorFriendCellCreated.fulfill()
            }
        ).disposed(by: disposeBag)

        wait(for: [expectErrorFriendCellCreated],timeout: 0.1)
    }
}

final class MockAppServerClient: APIClient {
    
    var getSearchResult: Result<Decodable?, NetworkError>?
    
    override func getSearchByTerm<T: Decodable>(term: String, decode: @escaping (Decodable) -> T?) -> Observable<T?> {
        return Observable.create { observer in
            switch self.getSearchResult {
            case .success(let result):
                observer.onNext(result as? T)
            case .failure(let error)?:
                observer.onError(error)
            case .none:
                observer.onError(NetworkError.notFound)
            }
            return Disposables.create()
        }
    }
}
