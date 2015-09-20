[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# SwiftMessageBar

A Swift Message Bar Implementation.

## Requirements

- iOS 8+
- Swift 2 (For Swift 1.2 use a build tagged with 1.x.x)
- Xcode 7.0+

## Installation

You can use [Carthage](https://github.com/Carthage/Carthage):

```ogdl
github "JanGorman/SwiftMessageBar"
```

or [CocoaPods](http://cocoapods.org):

```ruby
pod 'SwiftMessageBar'
```

## Usage

The included sample code shows how to use the message bar. There are three different message types:

```swift
enum MessageType {
    case Error, Success, Info
}
```

To display a message:

```swift
import SwiftMessageBar

@IBAction func showSuccess(sender: AnyObject) {
	SwiftMessageBar.showMessageWithTitle("Success", message: "The Message Body", type: .Success)
}
```

You can customize the duration of each message and also pass in a tap handler closure that is executed when a user taps on the message.

To customize the look of the messages, create a custom `MessageBarConfig` and set it on the shared messagebar. You can adjust the background and font colors, and pass in custom images to display.

## Licence

Agrume is released under the MIT license. See LICENSE for details



