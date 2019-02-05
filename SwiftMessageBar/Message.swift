//
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import UIKit

protocol Identifiable {

  var id: UUID { get }

}

final class Message: UIView {
  
  private static let padding: CGFloat = 10
  private static let messageOffset: CGFloat = 2
  private static let iconSize: CGFloat = 36

  private(set) var type: MessageType!
  private let uuid = UUID()
  private var title: String?
  private var message: String?
  private var titleFontColor: UIColor!
  private var messageFontColor: UIColor!
  private var icon: UIImage?
  var isHit: Bool = false
  private(set) var callback: Callback?
  private(set) var duration: TimeInterval!
  private(set) var dismiss: Bool = true
  private var languageDirection: NSLocale.LanguageDirection!
  private var titleFont: UIFont!
  private var messageFont: UIFont!
  
  private var paragraphStyle: NSMutableParagraphStyle {
    let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
    paragraphStyle.alignment = .left
    return paragraphStyle
  }
  
  init(type: MessageType, title: String?, message: String?, backgroundColor: UIColor, titleFontColor: UIColor,
       messageFontColor: UIColor, icon: UIImage?, duration: TimeInterval, dismiss: Bool = true, callback: Callback?,
       languageDirection: NSLocale.LanguageDirection, titleFont: UIFont, messageFont: UIFont) {
    self.type = type
    self.title = title
    self.message = message
    self.duration = duration
    self.callback = callback
    self.titleFontColor = titleFontColor
    self.messageFontColor = messageFontColor
    self.icon = icon
    self.dismiss = dismiss
    self.languageDirection = languageDirection
    self.titleFont = titleFont
    self.messageFont = messageFont
    
    super.init(frame: CGRect.zero)
    
    self.backgroundColor = backgroundColor
    usesAutoLayout(true)
  }
  
  func configureSubviews() {
    let iconImageView = makeIconView()
    let titleLabel = makeTitleLabel()
    let messageLabel = makeMessageLabel()

    if languageDirection == .rightToLeft {
      titleLabel.textAlignment = .right
      messageLabel.textAlignment = .right
      titleLabel.flipHorizontal()
      messageLabel.flipHorizontal()
      iconImageView.flipHorizontal()
    }

    let textStackView = makeTextStackView(with: titleLabel, messageLabel: messageLabel)
    
    let parentStackView: UIStackView = {
      let stackView = UIStackView(arrangedSubviews: [iconImageView, textStackView])
      stackView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
      stackView.isLayoutMarginsRelativeArrangement = true
      stackView.axis = .horizontal
      stackView.spacing = 15
      stackView.distribution = .fillProportionally
      return stackView
    }()
    parentStackView.usesAutoLayout(true)
    addSubview(parentStackView, constrainedTo: self)
  }
  
  private func makeIconView() -> UIImageView {
    let iconImageView = UIImageView()
    iconImageView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
    iconImageView.contentMode = .center
    iconImageView.image = icon
    return iconImageView
  }
  
  private func makeTitleLabel() -> UILabel {
    let titleLabel = UILabel()
    titleLabel.numberOfLines = 0

    if let title = title {
      let attributes: [NSAttributedString.Key: Any] = [
        .font : titleFont,
        .foregroundColor: titleFontColor,
        .paragraphStyle: paragraphStyle
      ]
      titleLabel.attributedText = NSAttributedString(string: title, attributes: attributes)
    }
    return titleLabel
  }
  
  private func makeMessageLabel() -> UILabel {
    let messageLabel = UILabel()
    messageLabel.numberOfLines = 0

    if let message = message {
      let attributes: [NSAttributedString.Key: Any] = [
        .font : messageFont,
        .foregroundColor: messageFontColor,
        .paragraphStyle: paragraphStyle
      ]
      messageLabel.attributedText = NSAttributedString(string: message, attributes: attributes)
    }
    return messageLabel
  }

  private func makeTextStackView(with titleLabel: UILabel, messageLabel: UILabel) -> UIStackView {

    let isTitleEmpty = title?.isEmpty ?? true
    let isMessageEmpty = message?.isEmpty ?? true

    let stackView = UIStackView()
    if !isTitleEmpty {
      stackView.addArrangedSubview(titleLabel)
    }
    if !isMessageEmpty {
      stackView.addArrangedSubview(messageLabel)
    }

    stackView.usesAutoLayout(true)
    stackView.axis = .vertical
    stackView.spacing = 1
    stackView.distribution = .fill
    return stackView
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func updateConstraints() {
    superview?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: [],
                                                             metrics: nil, views: ["view": self]))
    super.updateConstraints()
  }
  
  override var intrinsicContentSize: CGSize {
    return CGSize(width: statusBarFrame.width, height: estimatedHeight)
  }

  var estimatedHeight: CGFloat {
      let iconSize = icon == nil ? 0 : Message.iconSize
      return max(topMargin + titleSize.height + Message.messageOffset + messageSize.height + bottomMargin,
                 topMargin + iconSize + bottomMargin)
  }

  var titleSize: CGSize {
    let boundedSize = CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
    let titleFontAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
    if let size = title?.boundingRect(with: boundedSize,
                                      options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin],
                                      attributes: titleFontAttributes, context: nil).size {
      return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    return .zero
  }
  
  var messageSize: CGSize {
    let boundedSize = CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
    let titleFontAttributes: [NSAttributedString.Key: Any] = [.font: messageFont]
    if let size = message?.boundingRect(with: boundedSize,
                                        options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin],
                                        attributes: titleFontAttributes, context: nil).size {
      return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    return .zero
  }
  
  var statusBarOffset: CGFloat {
    return statusBarFrame.height
  }
  
  var topMargin: CGFloat {
    return max(statusBarOffset, Message.padding)
  }

  var bottomMargin: CGFloat {
    return Message.padding
  }
    
  var width: CGFloat {
    return statusBarFrame.width
  }
  
  var statusBarFrame: CGRect {
    let windowFrame = UIScreen.main.bounds
    let statusFrame = UIApplication.shared.statusBarFrame
    return CGRect(x: windowFrame.minX, y: windowFrame.minY, width: windowFrame.width, height: statusFrame.height)
  }
  
  var availableWidth: CGFloat {
    return width - Message.padding * 2 - Message.iconSize
  }

  static func ==(lhs: Message, rhs: Message) -> Bool {
    return lhs.id == rhs.id
  }

}

extension Message: Identifiable {

  var id: UUID {
    return uuid
  }

}

extension UIView {
  
  func usesAutoLayout(_ usesAutoLayout: Bool) {
    translatesAutoresizingMaskIntoConstraints = !usesAutoLayout
  }
    
  func flipHorizontal() {
    layer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
  }

  func addSubview(_ subviews: UIView,
                  constrainedTo anchorView: UIView) {
    addSubview(subviews)
    subviews.usesAutoLayout(true)

    NSLayoutConstraint.activate([
      subviews.centerXAnchor.constraint(equalTo: anchorView.centerXAnchor),
      subviews.centerYAnchor.constraint(equalTo: anchorView.centerYAnchor),
      subviews.widthAnchor.constraint(equalTo:  anchorView.widthAnchor),
      subviews.heightAnchor.constraint(equalTo: anchorView.heightAnchor)])

  }

}

