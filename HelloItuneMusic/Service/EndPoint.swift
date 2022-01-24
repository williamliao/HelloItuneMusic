//
//  EndPoint.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/20.
//

import Foundation

struct EndPoint {
    let path: String
    let queryItems: [URLQueryItem]
}

enum ItunesSort: String {
    case recent
}

enum ItunesMedia: String {
    case music
    case movie
    case musicVideo
    case podcast
    case audiobook
    case shortFilm
    case tvShow
    case ebook
    case software
    case all
}

enum ItunesEntity: String {
    case music
    case podcast
    case movie
    case musicVideo
    case audiobook
    case shortFilm
    case tvShow
    case ebook
    case software
    case all
}

extension EndPoint {
    static func search(matching term: String) -> EndPoint {
        return EndPoint(
            path: "/search",
            queryItems: [
                URLQueryItem(name: "term", value: term),
            ]
        )
    }
    
    static func searchAlbum(matching term: String, limit: Int = 50, entity: ItunesEntity = .music, country: String = "tw", lang: String = "zh-tw") -> EndPoint {
        
        var limitValue = limit
        
        if limitValue >= 200 {
            limitValue = 200
        }
        
        return EndPoint(
            path: "/search",
            queryItems: [
                URLQueryItem(name: "term", value: term),
                URLQueryItem(name: "entity", value: entity.rawValue),
                URLQueryItem(name: "limit", value: "\(limitValue)"),
                URLQueryItem(name: "entity", value: entity.rawValue),
                URLQueryItem(name: "country", value: country),
            ]
        )
    }
}

extension EndPoint {
    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        components.path = path
        components.queryItems = queryItems
        return components.url
    }
}
