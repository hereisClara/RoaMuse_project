//
//  ChatMessageCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/5.
//

import Foundation
import UIKit
import SnapKit
import Kingfisher

class ChatMessageCell: UITableViewCell {
    
    let messageLabel = UILabel()
    let messageBubble = UIView()
    let avatarImageView = UIImageView()
    let timestampLabel = UILabel()
    let messageImageView = UIImageView()
    var imageUrlString: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont(name: "NotoSerifHK-Black", size: 16)
        messageBubble.layer.cornerRadius = 12
        messageBubble.clipsToBounds = true
        
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        
        timestampLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 12)
        timestampLabel.textColor = .lightGray
        
        messageImageView.contentMode = .scaleAspectFill
        messageImageView.clipsToBounds = true
        messageImageView.layer.cornerRadius = 16
        messageImageView.isHidden = true
        
        contentView.addSubview(messageImageView)
        contentView.addSubview(messageBubble)
        contentView.addSubview(messageLabel)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(timestampLabel)
        
        messageBubble.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.width.lessThanOrEqualTo(250)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.edges.equalTo(messageBubble).inset(10)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.bottom.equalTo(messageBubble)
            make.left.equalToSuperview().offset(16)
        }
        
        timestampLabel.snp.makeConstraints { make in
            make.bottom.equalTo(messageBubble.snp.bottom)
            make.width.lessThanOrEqualTo(80)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
            super.prepareForReuse()
            
            messageLabel.text = nil
            messageImageView.image = nil
            avatarImageView.image = nil
            timestampLabel.text = nil
            
            messageLabel.isHidden = false
            messageImageView.isHidden = true
            avatarImageView.isHidden = false
            
            messageBubble.backgroundColor = .clear
            messageLabel.textColor = .black
        imageUrlString = nil
        }
    
    func configure(with message: ChatMessage, profileImageUrl: String) {

        prepareForReuse()
        
        messageImageView.isHidden = true
        messageLabel.isHidden = false
        avatarImageView.isHidden = false
        
        messageLabel.text = message.text
        let isFromCurrentUser = message.isFromCurrentUser

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        timestampLabel.text = dateFormatter.string(from: message.timestamp)

        if let imageUrl = message.imageUrl {
            imageUrlString = imageUrl
            messageImageView.isHidden = false
            messageLabel.isHidden = true
            messageImageView.kf.setImage(with: URL(string: imageUrl), placeholder: UIImage(named: "photo-placeholder"))
            
            messageImageView.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(photoTapped(_:)))
            messageImageView.addGestureRecognizer(tapGesture)
            
            messageImageView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.bottom.equalToSuperview().offset(-10)
                make.width.height.lessThanOrEqualTo(250)
            }
            
            if isFromCurrentUser {
                messageImageView.snp.makeConstraints { make in
                    make.right.equalToSuperview().offset(-16)
                }
                avatarImageView.isHidden = true
                timestampLabel.snp.remakeConstraints { make in
                    make.bottom.equalTo(messageImageView.snp.bottom)
                    make.trailing.equalTo(messageImageView.snp.leading).offset(-8)
                }
            } else {
                
                messageImageView.snp.makeConstraints { make in
                    make.left.equalTo(avatarImageView.snp.right).offset(8)
                }
                avatarImageView.isHidden = false
                avatarImageView.kf.setImage(with: URL(string: profileImageUrl), placeholder: UIImage(named: "user-placeholder"))
                timestampLabel.snp.remakeConstraints { make in
                    make.bottom.equalTo(messageImageView.snp.bottom)
                    make.leading.equalTo(messageImageView.snp.trailing).offset(8)
                }
            }

        } else {
            
            messageImageView.isHidden = true
            messageLabel.isHidden = false
            
            if isFromCurrentUser {
                messageBubble.backgroundColor = .deepBlue
                messageLabel.textColor = .backgroundGray
                
                messageBubble.snp.remakeConstraints { make in
                    make.right.equalToSuperview().offset(-16)
                    make.top.equalToSuperview().offset(10)
                    make.bottom.equalToSuperview().offset(-10)
                    make.width.lessThanOrEqualTo(250)
                }
                
                avatarImageView.isHidden = true
                
                timestampLabel.snp.remakeConstraints { make in
                    make.bottom.equalTo(messageBubble.snp.bottom)
                    make.trailing.equalTo(messageBubble.snp.leading).offset(-8)
                }
            } else {
                messageBubble.backgroundColor = .white
                messageLabel.textColor = .deepBlue
                avatarImageView.kf.setImage(with: URL(string: profileImageUrl), placeholder: UIImage(named: "user-placeholder"))
                
                messageBubble.snp.remakeConstraints { make in
                    make.left.equalTo(avatarImageView.snp.right).offset(8)
                    make.top.equalToSuperview().offset(10)
                    make.bottom.equalToSuperview().offset(-10)
                    make.width.lessThanOrEqualTo(250)
                }
                
                avatarImageView.isHidden = false
                avatarImageView.snp.remakeConstraints { make in
                    make.left.equalToSuperview().offset(16)
                    make.bottom.equalTo(messageBubble)
                    make.width.height.equalTo(40)
                }
                
                timestampLabel.snp.remakeConstraints { make in
                    make.bottom.equalTo(messageBubble.snp.bottom)
                    make.leading.equalTo(messageBubble.snp.trailing).offset(8)
                }
            }
        }
    }
    
    @objc func photoTapped(_ gesture: UITapGestureRecognizer) {
            guard let imageUrlString = imageUrlString else { return }
            showFullScreenImage(photoUrl: imageUrlString)
        }
    
    func showFullScreenImage(photoUrl: String) {
        let fullScreenVC = FullScreenImageViewController()
        
        guard let url = URL(string: photoUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("圖片下載失敗: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    fullScreenVC.images.append(image)
                    fullScreenVC.modalPresentationStyle = .fullScreen
                    self.window?.rootViewController?.present(fullScreenVC, animated: true, completion: nil)
                }
            }
        }.resume()
    }

}
