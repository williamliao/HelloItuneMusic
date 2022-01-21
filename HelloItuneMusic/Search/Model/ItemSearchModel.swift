//
//  ItemSearchModel.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/20.
//

import Foundation

struct SearchItem: Codable {
    let id : UUID
    let name: String?
    let longDescription: String?
    let artworkUrl100: String?
    let previewUrl: String?
}

extension SearchItem: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SearchItem, rhs: SearchItem) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ItemSearchModel: Codable {
    let resultCount: Int
    let results: [Results]
}

struct Results: Codable {
    let wrapperType: String?
    let kind: String?
    let artistId: Int?
    let collectionId: Int?
    let trackId: Int?
    let artistName: String
    let collectionName: String?
    let trackName: String?
    let collectionCensoredName: String?
    let trackCensoredName: String?
    let collectionArtistId: Int?
    let collectionArtistName: String?
    let collectionArtistViewUrl: String?
    let artistViewUrl: String?
    let collectionViewUrl: String?
    let trackViewUrl: String?
    let previewUrl: String?
    let artworkUrl30: String?
    let artworkUrl60: String?
    let artworkUrl100: String?
    let releaseDate: String?
    let collectionExplicitness: String?
    let trackExplicitness: String?
    let discCount: Int?
    let discNumber: Int?
    let trackCount: Int?
    let trackNumber: Int?
    let trackTimeMillis: Int?
    let country: String?
    let currency: String?
    let primaryGenreName: String?
    let isStreamable: Bool?
    let collectionPrice: Double?
    let trackPrice: Double?
    let contentAdvisoryRating: String?
    let feedUrl: String?
    let trackRentalPrice: Double?
    let collectionHdPrice: Double?
    let trackHdPrice: Double?
    let trackHdRentalPrice: Double?
    let artworkUrl600: String?
    let genreIds: [String]?
    let genres: [String]?
    let shortDescription: String?
    let longDescription: String?
    let hasITunesExtras: Bool?
}
