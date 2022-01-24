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
    private let loadInProgress: PublishSubject<Bool> = PublishSubject<Bool>()
    private let disposeBag = DisposeBag()

    var viewModel: ItemSearchCellViewModel? {
        didSet {
            bindViewModel()
        }
    }
    
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
   
        if #available(iOS 15.0, *) {
            loadingTask?.cancel()
            loadingTask = nil
        }
        
        if let viewModel = viewModel {
            viewModel.player = nil
            viewModel.playerItem = nil
            viewModel.playUrl = ""
            playButton.setTitle(viewModel.playButtonTitle, for: UIControl.State.normal)
            viewModel.resetPlayer()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImage.layer.cornerRadius = avatarImage.frame.height/2
    }
}

// MARK: - View
extension ItemSearchCell {
    private func configureView() {
        act.color = traitCollection.userInterfaceStyle == .light ? UIColor.black : UIColor.white
        self.contentView.addSubview(progressBarView)
        self.contentView.addSubview(act)
        self.contentView.addSubview(avatarImage)
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(descriptionLabel)
        self.contentView.addSubview(playButton)
        
        loadInProgress.bind(to: act.rx.isAnimating).disposed(by: disposeBag)
    }
    
    private func bindButton() {
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
    
    private func configureConstraints() {
        
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

// MARK: - Public
extension ItemSearchCell {
    
    private func bindViewModel() {
        if let viewModel = viewModel {
            descriptionLabel.text = viewModel.description

            if let name = viewModel.name {
                let height = viewModel.height(withString: name, font: nameLabel.font, width: self.contentView.frame.size.width)
                nameHeightConstraint.constant = height
                nameLabel.text = name
            }
            
            isLoading(isLoading: true)
            if #available(iOS 15.0, *) {
                loadingTask = Task {
                    await viewModel.configureImage()
                    avatarImage.image = viewModel.avatarImage
                    isLoading(isLoading: false)
                }
            } else {
                viewModel.rxImageOb
                    .bind(to: avatarImage.rx.image)
                    .disposed(by: disposeBag)
                isLoading(isLoading: false)
            }
            
        }
    }
    
    func stopPlayAfterTapOtherCell() {
        if let viewModel = viewModel {
            viewModel.player?.pause()
            viewModel.timeObserverDisposbale?.dispose()
            playButton.setTitle(viewModel.playButtonTitle, for: UIControl.State.normal)
            progressBarView.progress = 0
        }
        
    }
}

// MARK: - Private
extension ItemSearchCell {
    
    @available(iOS 15.0, *)
    private func downloadImage(_ imageUrl: URL?) async throws -> UIImage? {
        
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
    
    private func height(withString string: String, font: UIFont) -> CGFloat {

        let width = self.contentView.frame.size.width
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)

        let boundingBox = string.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : font], context: nil)
        return ceil(boundingBox.height)
    }
    
    private func isLoading(isLoading: Bool) {
        
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
    
    @objc private func playTap() {
        
        if let viewModel = viewModel {
            viewModel.playTap()
            playButton.setTitle(viewModel.playButtonTitle, for: UIControl.State.normal)
            
            let mainQueue = DispatchQueue.main
            viewModel.timeObserverDisposbale = viewModel.player?.rx.playbackPosition(updateInterval: 0.5, updateQueue: mainQueue)
                .subscribe(onNext: { [self] position in
                    if viewModel.playButtonTitle != "Play" {
                        progressBarView.progress = Float(position)
                    }
                }, onError: { error in
                    
                }, onCompleted: {
                    
                }, onDisposed: {
                    print("### DISPOSED ###")
                })
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
