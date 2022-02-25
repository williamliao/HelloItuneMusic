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
    var desHeightConstraint: NSLayoutConstraint!
   
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
    
    let audioBackgroudView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var act = UIActivityIndicatorView(style: .large)
    private let loadInProgress: PublishSubject<Bool> = PublishSubject<Bool>()
    private let disposeBag = DisposeBag()

    var viewModel: ItemSearchCellViewModel? {
        didSet {
            bindViewModel()
        }
    }
    
    var widthConstraint: NSLayoutConstraint!
    
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
        act.translatesAutoresizingMaskIntoConstraints = false
        
        self.widthConstraint = self.contentView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width)
       // self.widthConstraint.constant = UIScreen.main.bounds.width
        
        self.contentView.addSubview(audioBackgroudView)
        audioBackgroudView.addSubview(progressBarView)
        audioBackgroudView.addSubview(act)
        audioBackgroudView.addSubview(avatarImage)
        audioBackgroudView.addSubview(nameLabel)
        audioBackgroudView.addSubview(descriptionLabel)
        audioBackgroudView.addSubview(playButton)
        
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
        desHeightConstraint = descriptionLabel.heightAnchor.constraint(equalToConstant: 16)
        
        //contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            
            widthConstraint,
            
            audioBackgroudView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            audioBackgroudView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            audioBackgroudView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            audioBackgroudView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),

            progressBarView.leadingAnchor.constraint(equalTo: audioBackgroudView.leadingAnchor),
            progressBarView.topAnchor.constraint(equalTo: audioBackgroudView.topAnchor),
            progressBarView.trailingAnchor.constraint(equalTo: audioBackgroudView.trailingAnchor),
            progressBarView.bottomAnchor.constraint(equalTo: audioBackgroudView.bottomAnchor),
            
            avatarImage.leadingAnchor.constraint(equalTo: audioBackgroudView.leadingAnchor, constant: 15),
            avatarImage.topAnchor.constraint(equalTo: audioBackgroudView.topAnchor, constant: 10),
            avatarImage.heightAnchor.constraint(equalToConstant: 44),
            avatarImage.widthAnchor.constraint(equalToConstant: 44),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImage.trailingAnchor, constant: 5),
            nameLabel.trailingAnchor.constraint(equalTo: audioBackgroudView.trailingAnchor, constant: -5),
            nameLabel.topAnchor.constraint(equalTo: audioBackgroudView.topAnchor, constant: 10),
            nameHeightConstraint,

            playButton.trailingAnchor.constraint(equalTo: audioBackgroudView.trailingAnchor, constant: -15),
            playButton.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            playButton.heightAnchor.constraint(equalToConstant: 26),
            playButton.widthAnchor.constraint(equalToConstant: 100),
     
            descriptionLabel.leadingAnchor.constraint(equalTo: avatarImage.trailingAnchor, constant: 5),
            descriptionLabel.trailingAnchor.constraint(equalTo: audioBackgroudView.trailingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 5),
            descriptionLabel.bottomAnchor.constraint(equalTo: audioBackgroudView.bottomAnchor, constant: -5),
            desHeightConstraint,
            
            act.centerXAnchor.constraint(equalTo: audioBackgroudView.centerXAnchor),
            act.centerYAnchor.constraint(equalTo: audioBackgroudView.centerYAnchor),
        ])
    }
}

// MARK: - Public
extension ItemSearchCell {
    
    private func bindViewModel() {
        if let viewModel = viewModel {
            
            descriptionLabel.text = viewModel.description
            if let name = viewModel.name {
                let height = viewModel.height(withString: name, font: nameLabel.font, width: UIScreen.main.bounds.width - 44)
                nameHeightConstraint.constant = height
                nameLabel.text = name
            }

            if let des = viewModel.description {
                let height = viewModel.height(withString: des, font: descriptionLabel.font, width: UIScreen.main.bounds.width - 44)
                desHeightConstraint.constant = ceil(height)
              
            } else {
                desHeightConstraint.constant = 0
            }
            
            if let long = viewModel.itemIdentifier.longDescription {
                let height = viewModel.height(withString: long, font: descriptionLabel.font, width: self.contentView.frame.size.width)
                let baseHeight: Double = 44.0 + 26.0
                let padding: Double = 22.0
                desHeightConstraint.constant = baseHeight + ceil(height) + padding
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
