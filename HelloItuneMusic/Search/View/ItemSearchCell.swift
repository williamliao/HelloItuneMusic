//
//  ItemSearchCell.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/20.
//

import UIKit

class ItemSearchCell: UICollectionViewCell {
    static var reuseIdentifier: String {
        return String(describing: ItemSearchCell.self)
    }
    
    private var isHeightCalculated: Bool = false
    private var loadingTask: Task<Void, Never>?
    private var nameHeightConstraint: NSLayoutConstraint!
    
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
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
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
        loadingTask?.cancel()
        loadingTask = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImage.layer.cornerRadius = avatarImage.frame.height/2
    }
}

extension ItemSearchCell {
    func configureView() {
        self.contentView.addSubview(avatarImage)
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(descriptionLabel)
    }
    
    func configureConstraints() {
        
        nameHeightConstraint = nameLabel.heightAnchor.constraint(equalToConstant: 16)
       
        NSLayoutConstraint.activate([
            
            avatarImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            avatarImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            avatarImage.heightAnchor.constraint(equalToConstant: 44),
            avatarImage.widthAnchor.constraint(equalToConstant: 44),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImage.trailingAnchor, constant: 5),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameHeightConstraint,
            
            descriptionLabel.leadingAnchor.constraint(equalTo: avatarImage.trailingAnchor, constant: 5),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ])
    }
}

extension ItemSearchCell {
    func configureCell(name: String?, des: String?, imageUrl: String?) {
        
        descriptionLabel.text = des
        
        if let name = name {
            let height = self.height(withString: name, font: nameLabel.font)
            nameHeightConstraint.constant = height
            nameLabel.text = name
        }
        
        
        if #available(iOS 15.0, *) {
            if let imageUrl = imageUrl {
                
                let url = URL(string: imageUrl)
                loadingTask = Task {
                    do {
                        try await avatarImage.image = downloadImage(url)
                    } catch  {
                        print("downloadImage error \(error)")
                    }
                }
                
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    @available(iOS 15.0, *)
    func downloadImage(_ imageUrl: URL?) async throws -> UIImage? {
        
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
    
    func height(withString string: String, font: UIFont) -> CGFloat {

        let width = self.contentView.frame.size.width
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)

        let boundingBox = string.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : font], context: nil)
        return ceil(boundingBox.height)
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
