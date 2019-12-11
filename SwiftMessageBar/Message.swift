//
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import UIKit

final class Message: UIView {

  var isHit = false

  private(set) var type: MessageType!
  private let uuid = UUID()
  private var title: String?
  private var message: String?
  private var titleFontColor: UIColor!
  private var messageFontColor: UIColor!
  private var icon: UIImage?
  private(set) var callback: Callback?
  private(set) var duration: TimeInterval!
  private(set) var dismiss = true
  private var languageDirection: NSLocale.LanguageDirection!
  private var titleFont: UIFont!
  private var messageFont: UIFont!
  private var accessoryView: UIView?

  public lazy var contentStackView: UIStackView = {
    let contentView = UIStackView(frame: bounds)
    contentView.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    contentView.isLayoutMarginsRelativeArrangement = true
    contentView.axis = .horizontal
    contentView.spacing = 10
    return contentView
  }()
  
  private var paragraphStyle: NSMutableParagraphStyle {
    let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
    paragraphStyle.alignment = .left
    return paragraphStyle
  }
  
  init(type: MessageType, title: String?, message: String?, backgroundColor: UIColor, titleFontColor: UIColor,
       messageFontColor: UIColor, icon: UIImage?, duration: TimeInterval, dismiss: Bool = true, callback: Callback?,
       languageDirection: NSLocale.LanguageDirection, titleFont: UIFont, messageFont: UIFont, accessoryView: UIView?) {
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
    self.accessoryView = accessoryView
    
    super.init(frame: .zero)
    
    self.backgroundColor = backgroundColor
    usesAutoLayout(true)
  }
  
  func configureSubviews(topAnchor: NSLayoutYAxisAnchor) {
    let iconImageView = makeIconView()
    let titleLabel = makeTitleLabel()
    let messageLabel = makeMessageLabel()

    if languageDirection == .rightToLeft {
      titleLabel.textAlignment = .right
      messageLabel.textAlignment = .right
      titleLabel.flipHorizontal()
      messageLabel.flipHorizontal()
      iconImageView.flipHorizontal()
      accessoryView?.flipHorizontal()
    }

    let textStackView = makeTextStackView(with: titleLabel, messageLabel: messageLabel)
    contentStackView.addArrangedSubview(iconImageView)
    contentStackView.addArrangedSubview(textStackView)

    if let accessoryView = accessoryView {
      contentStackView.addArrangedSubview(makeWrapperView(for: accessoryView))
    }

    addSubview(contentStackView)
    configureConstraints(withTopAnchor: topAnchor)
  }
  
  private func configureConstraints(withTopAnchor topAnchor: NSLayoutYAxisAnchor) {
    contentStackView.usesAutoLayout(true)
    NSLayoutConstraint.activate([
      contentStackView.rightAnchor.constraint(equalTo: rightAnchor),
      contentStackView.leftAnchor.constraint(equalTo: leftAnchor),
      contentStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
      contentStackView.topAnchor.constraint(equalTo: topAnchor),
    ])
  }
  
  private func makeIconView() -> UIImageView {
    let iconImageView = UIImageView(image: icon)
    iconImageView.contentMode = .center
    iconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    iconImageView.setContentHuggingPriority(.required, for: .horizontal)
    return iconImageView
  }
  
  private func makeTitleLabel() -> UILabel {
    let titleLabel = UILabel()
    titleLabel.numberOfLines = 0

    if let title = title {
      let attributes: [NSAttributedString.Key: Any] = [
        .font : titleFont!,
        .foregroundColor: titleFontColor!,
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
        .font : messageFont!,
        .foregroundColor: messageFontColor!,
        .paragraphStyle: paragraphStyle
      ]
      messageLabel.attributedText = NSAttributedString(string: message, attributes: attributes)
    }
    return messageLabel
  }

  private func makeTextStackView(with titleLabel: UILabel, messageLabel: UILabel) -> UIStackView {
    let isTitleEmpty = title?.isEmpty ?? true
    let isMessageEmpty = message?.isEmpty ?? true

    let stackView = UIStackView(frame: bounds)
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

  private func makeWrapperView(for view: UIView) -> UIView {
    let wrapper = UIView(frame: view.bounds)

    view.setContentCompressionResistancePriority(.required, for: .horizontal)
    wrapper.addSubview(view)
    wrapper.contentMode = .center
    NSLayoutConstraint.activate([
      view.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor),
      view.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
      view.widthAnchor.constraint(equalTo: wrapper.widthAnchor)])

    view.usesAutoLayout(true)
    return wrapper
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func updateConstraints() {
    if let superview = superview {
      NSLayoutConstraint.activate([
        rightAnchor.constraint(equalTo: superview.rightAnchor),
        leftAnchor.constraint(equalTo: superview.leftAnchor),
        topAnchor.constraint(equalTo: superview.topAnchor)
      ])
    }
    super.updateConstraints()
  }

  var estimatedHeight: CGFloat {
    self.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
  }
}

extension Message: Identifiable {

  var id: UUID {
    uuid
  }

}

extension UIView {

  func flipHorizontal() {
    layer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
  }

  fileprivate func usesAutoLayout(_ usesAutoLayout: Bool) {
    translatesAutoresizingMaskIntoConstraints = !usesAutoLayout
  }
}

