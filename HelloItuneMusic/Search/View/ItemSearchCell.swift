//
//  ItemSearchCell.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/20.
//

import UIKit
import AVKit
import RxSwift

class ItemSearchCell: UICollectionViewCell {
    static var reuseIdentifier: String {
        return String(describing: ItemSearchCell.self)
    }
    
    private var isHeightCalculated: Bool = false
    private var loadingTask: Task<Void, Never>?
    var nameHeightConstraint: NSLayoutConstraint!
    
    let avatarImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.borderWidth = 1
        imageView.layer.masksToBounds = false
        imageView.layer.borderColor = UIColor.clear.cgColor
        imageView.clipsToBounds = true
        imageView.image = UIImage(systemName: "person.crop.circle")
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let playButton: UIButton = {
        var configuration = UIButton.Configuration.tinted()
        configuration.baseBackgroundColor = .systemGreen
        configuration.baseForegroundColor = .label
        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Play", for: UIControl.State.normal)
        return button
    }()
  
    let progressBarView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.progress = 0
        progressView.progressTintColor = UIColor.systemBlue.withAlphaComponent(0.5)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    var act = UIActivityIndicatorView(style: .large)
    private var playerItem:AVPlayerItem?
    private var player:AVPlayer?
    private var dataTask: URLSessionDataTask?
    private var playUrl: String?
    private let disposeBag = DisposeBag()
    private let loadInProgress: PublishSubject<Bool> = PublishSubject<Bool>()
    private var isPlaying: Bool = false
    
    var playAction: (() -> Void)?
    var timeObserver: Any?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        bindButton()
        configureConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImage.image = UIImage(systemName: "person.crop.circle")
        nameLabel.text = ""
        descriptionLabel.text = ""
        progressBarView.progress = 0
        isLoading(isLoading: false)
        
        player = nil
        playerItem = nil
        playUrl = ""
        playButton.setTitle("Play", for: UIControl.State.normal)
        
        if #available(iOS 15.0, *) {
            loadingTask?.cancel()
            loadingTask = nil
        } else {
            dataTask?.cancel()
            dataTask = nil
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImage.layer.cornerRadius = avatarImage.frame.height/2
    }
}

extension ItemSearchCell {
    func configureView() {
        act.color = traitCollection.userInterfaceStyle == .light ? UIColor.black : UIColor.white
        self.contentView.addSubview(progressBarView)
        self.contentView.addSubview(act)
        self.contentView.addSubview(avatarImage)
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(descriptionLabel)
        self.contentView.addSubview(playButton)
        
        loadInProgress.bind(to: act.rx.isAnimating).disposed(by: disposeBag)
    }
    
    func bindButton() {
        if #available(iOS 15.0, *) {
            playButton.addTarget(self, action: #selector(playTap), for: .touchUpInside)
        } else {
            playButton.rx.tap
                .subscribe(onNext: { [self] in
                    playTap()
            })
            .disposed(by: disposeBag)
        }
    }
    
    func configureConstraints() {
        
        nameHeightConstraint = nameLabel.heightAnchor.constraint(equalToConstant: 16)
       
        NSLayoutConstraint.activate([
            
            progressBarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            progressBarView.topAnchor.constraint(equalTo: contentView.topAnchor),
            progressBarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            progressBarView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            avatarImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            avatarImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            avatarImage.heightAnchor.constraint(equalToConstant: 44),
            avatarImage.widthAnchor.constraint(equalToConstant: 44),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImage.trailingAnchor, constant: 5),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameHeightConstraint,

            playButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            playButton.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            playButton.heightAnchor.constraint(equalToConstant: 26),
            playButton.widthAnchor.constraint(equalToConstant: 100),
     
            descriptionLabel.leadingAnchor.constraint(equalTo: avatarImage.trailingAnchor, constant: 5),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            descriptionLabel.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 5),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            
            act.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            act.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
}

extension ItemSearchCell {
    func configureCell(name: String?, des: String?, imageUrl: String?, previewUrl: String?) {
        
        descriptionLabel.text = des
        playUrl = previewUrl
    
        if let name = name {
            let height = self.height(withString: name, font: nameLabel.font)
            nameHeightConstraint.constant = height
            nameLabel.text = name
        }
        
        if let imageUrl = imageUrl {
            let url = URL(string: imageUrl)
            if #available(iOS 15.0, *) {
                loadingTask = Task {
                    do {
                        try await avatarImage.image = downloadImage(url)
                        isLoading(isLoading: false)
                    } catch  {
                        print("downloadImage error \(error)")
                    }
                }
            } else {
                isLoading(isLoading: true)
                
                guard let url = url else {
                    return
                }
                
                URLSession.shared.rx.data(request: URLRequest(url: url))
                    .subscribe(onNext: { data in
                      
                        let image = UIImage(data: data)

                        DispatchQueue.main.async { [weak self] in
                            self?.isLoading(isLoading: false)
                            self?.avatarImage.image = image
                        }
                    }, onError: { error in
                        print("Data Task Error: \(error)")
                    })
                    .disposed(by: disposeBag)
            }
            
        }
    }
    
    @available(iOS 15.0, *)
    func downloadImage(_ imageUrl: URL?) async throws -> UIImage? {
        
        guard let imageUrl = imageUrl else {
            return nil
        }
        isLoading(isLoading: true)
        let imageRequest = URLRequest(url: imageUrl)
        let (data, imageResponse) = try await URLSession.shared.data(for: imageRequest)
        guard let image = UIImage(data: data), (imageResponse as? HTTPURLResponse)?.statusCode == 200 else {
            throw NetworkError.invalidImage
        }
        return image
    }
    
    func height(withString string: String, font: UIFont) -> CGFloat {

        let width = self.contentView.frame.size.width
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)

        let boundingBox = string.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : font], context: nil)
        return ceil(boundingBox.height)
    }
    
    func isLoading(isLoading: Bool) {
        
        if #available(iOS 15.0, *)  {
            if isLoading {
                act.startAnimating()
            } else {
                act.stopAnimating()
            }
        } else {
            loadInProgress.onNext(isLoading)
        }
        
        act.isHidden = !isLoading
    }
}

extension ItemSearchCell {
    @objc private func playTap() {
        playAction?()
     
        if let url = playUrl, let previewUrl = URL(string: url) {
            
            playerItem = AVPlayerItem(url: previewUrl)
            player = AVPlayer(playerItem: playerItem)
            player?.volume = 0.5
            
            addPeriodicTimeObserver()
        }
        
        if isPlaying == true {
            player?.pause()
            
            if let timeObserver = self.timeObserver {
                self.player?.removeTimeObserver(timeObserver)
                
            }
            playButton.setTitle("Play", for: UIControl.State.normal)
            progressBarView.progress = 0
            isPlaying = false
            return
        }
        
        if player?.rate == 0 {
            isPlaying = true
            player?.play()
            playButton.setTitle("Pause", for: UIControl.State.normal)
        } else {
            player?.pause()
            playButton.setTitle("Play", for: UIControl.State.normal)
            isPlaying = false
        }
    }
    
    func stopPlayAfterTapOtherCell() {
        player?.pause()
        playButton.setTitle("Play", for: UIControl.State.normal)
        progressBarView.progress = 0
    }

    private func addPeriodicTimeObserver() {
        
        let interval = CMTime(seconds: 0.5,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let mainQueue = DispatchQueue.main
        self.timeObserver = self.player?.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue) { [weak self] time in
            let currentSeconds = CMTimeGetSeconds(time)
            guard let duration = self?.playerItem?.duration else { return }
            let totalSeconds = CMTimeGetSeconds(duration)
            let progress: Float = Float(currentSeconds/totalSeconds)
            self?.progressBarView.progress = progress
        }
    }
}

extension ItemSearchCell {
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if !isHeightCalculated {
            setNeedsLayout()
            layoutIfNeeded()
            let size = contentView.systemLayoutSizeFitting(layoutAttributes.size)
            var newFrame = layoutAttributes.frame
            newFrame.size.width = CGFloat(ceilf(Float(size.width)))
            newFrame.size.height = CGFloat(ceilf(Float(size.height)))
            layoutAttributes.frame = newFrame
            isHeightCalculated = true
        }
        return layoutAttributes
    }
}

extension Reactive where Base: ItemSearchCell {

    var isAnimating: Binder<Bool> {
        return Binder(self.base, binding: { (vc, active) in
            if active {
                vc.act.startAnimating()
            } else {
                vc.act.stopAnimating()
            }
        })
    }
}
