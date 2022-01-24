//
//  AVPlayer+RxSwift.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/24.
//

import Foundation

import Foundation
import AVFoundation

import RxSwift
import RxCocoa

extension Reactive where Base: AVPlayer
{
    public func playbackPosition(updateInterval: TimeInterval, updateQueue: DispatchQueue?) -> Observable<TimeInterval>
    {
        return Observable.create({[weak base] observer in
            
            guard let player = base else
            {
                observer.onCompleted()
                return Disposables.create()
            }
            
            let intervalTime = CMTime(seconds: updateInterval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            let obj = player.addPeriodicTimeObserver(
                forInterval: intervalTime,
                queue: updateQueue,
                using: { positionTime in
                    
                    let currentSeconds = CMTimeGetSeconds(positionTime)
                    guard let duration = player.currentItem?.duration else { return }
                    let totalSeconds = CMTimeGetSeconds(duration)
                    let progress: Float = Float(currentSeconds/totalSeconds)
                    
                    observer.onNext(TimeInterval(progress))
            })
            
            return Disposables.create
            {
                player.removeTimeObserver(obj)
            }
        })
    }
    
}
