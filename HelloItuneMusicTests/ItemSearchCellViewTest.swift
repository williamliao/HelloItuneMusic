//
//  ItemSearchCellViewTest.swift
//  HelloItuneMusicTests
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/24.
//

import XCTest
import RxSwift
@testable import HelloItuneMusic

class ItemSearchCellViewTest: XCTestCase {
    
    var items = [SearchItem]()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let result: ItemSearchModel = decode(from: "ituneSearch", with: "json")
        
        items = result.results.compactMap {
             SearchItem(id: UUID() ,name: $0.trackName, longDescription: $0.longDescription, artworkUrl100: $0.artworkUrl100, previewUrl: $0.previewUrl)
        }
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

extension ItemSearchCellViewTest {
    
    func testConfigureCell() {
        
        guard let firstItem = items.first else {
            XCTFail("Missing data")
            return
        }
        
        let viewCellModel = ItemSearchCellViewModel(itemIdentifier: firstItem)
        
        XCTAssertNotNil(viewCellModel.name)
    }
    
    @available(iOS 13.0, *)
    func testAssignImage() async {
        
        guard let firstItem = items.first else {
            XCTFail("Missing data")
            return
        }
        
        let viewCellModel = ItemSearchCellViewModel(itemIdentifier: firstItem)
        
        await viewCellModel.configureImage()
        XCTAssertNotNil(viewCellModel.avatarImage)
    }
    
    func testAssignImageRx() {
        let disposeBag = DisposeBag()
        guard let firstItem = items.first else {
            XCTFail("Missing data")
            return
        }
        
        let viewCellModel = ItemSearchCellViewModel(itemIdentifier: firstItem)
        
        viewCellModel.rxImageOb
            .subscribe { image in
                XCTAssertNotNil(image)
            }
            .disposed(by: disposeBag)
    }
}
