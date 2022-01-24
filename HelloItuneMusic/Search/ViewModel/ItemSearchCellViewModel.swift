//
//  ItemSearchCellViewModel.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/24.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import AVKit

class ItemSearchCellViewModel {
    
    var name: String?
    var description: String!
    var playUrl: String?
    var avatarImage: UIImage!
    var playButtonTitle: String!
    var progressValue: Float?

    private let disposeBag = DisposeBag()
    
    var playerItem:AVPlayerItem?
    var player:AVPlayer?
    var isPlaying: Bool = false
    
    var playAction: (() -> Void)?
    var timeObserverDisposbale:Disposable?
    
    var rxImage = BehaviorRelay<UIImage?>(value: UIImage(systemName: "person.crop.circle"))
    var rxImageOb: Observable<UIImage?> {
        return rxImage.asObservable()
    }
    
    private var itemIdentifier: SearchItem
    
    init(itemIdentifier: SearchItem) {
        self.itemIdentifier = itemIdentifier
        configureCell()
    }
    
    func configureCell() {
        description = itemIdentifier.longDescription
        playUrl = itemIdentifier.previewUrl
        name = itemIdentifier.name
    }
    
    func configureImage() async {
        if let imageUrl = itemIdentifier.artworkUrl100 {
            let url = URL(string: imageUrl)
            if #available(iOS 15.0, *) {
                do {
                    try await avatarImage = downloadImage(url)

                } catch  {
                    print("downloadImage error \(error)")
                    avatarImage = UIImage(systemName: "person.crop.circle")
                }
            } else {
                
                
                guard let url = url else {
                    return
                }
                
                URLSession.shared.rx.data(request: URLRequest(url: url))
                    .subscribe(onNext: { [self] data in
                      
                        avatarImage = UIImage(data: data)

                        rxImage.accept(avatarImage)
                        
                    }, onError: { [self]  error in
                        print("Data Task Error: \(error)")
                        let image = UIImage(systemName: "person.crop.circle")
                        rxImage.accept(image)
                    })
                    .disposed(by: disposeBag)
            }
            
        }
    }
    
    func height(withString string: String, font: UIFont, width: CGFloat) -> CGFloat {

        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)

        let boundingBox = string.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : font], context: nil)
        return ceil(boundingBox.height)
    }
    
    @available(iOS 15.0, *)
    private func downloadImage(_ imageUrl: URL?) async throws -> UIImage? {
        
        guard let imageUrl = imageUrl else {
            return nil
        }

        let imageRequest = URLRequest(url: imageUrl)
        let (data, imageResponse) = try await URLSession.shared.data(for: imageRequest)
        guard let image = UIImage(data: data), (imageResponse as? HTTPURLResponse)?.statusCode == 200 else {
            throw NetworkError.invalidImage
        }
        return image
    }
    
    private func reset() {
    }
}

extension ItemSearchCellViewModel {
    
    @objc func playTap() {
        playAction?()
     
        if let url = playUrl, let previewUrl = URL(string: url) {
            
            playerItem = AVPlayerItem(url: previewUrl)
            player = AVPlayer(playerItem: playerItem)
            player?.volume = 0.5
        }
        
        if isPlaying == true {
            resetPlayer()
            return
        }
        
        if player?.rate == 0 {
            isPlaying = true
            player?.play()
            playButtonTitle = "Pause"
        } else {
            player?.pause()
            playButtonTitle = "Play"
            isPlaying = false
        }
    }
   
    func resetPlayer() {
        player?.pause()
        timeObserverDisposbale?.dispose()
        playButtonTitle = "Play"
        progressValue = 0
        isPlaying = false
    }
}
