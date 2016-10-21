Pod::Spec.new do |s|

  s.name         = "SwiftMessageBar"
  s.version      = "3.0.1"
  s.summary      = "A Swift Message Bar"

  s.description  = <<-DESC
                   A longer description of SwiftMessageBar in Markdown format.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC

  s.homepage     = "https://github.com/JanGorman/SwiftMessageBar"
  s.license      = "MIT"
  s.authors            = { "Jan Gorman" => "https://github.com/JanGorman/", "Ramy Kfoury" => "https://github.com/ramy-kfoury/" }
  s.social_media_url   = "http://twitter.com/JanGorman"

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/JanGorman/SwiftMessageBar.git", :tag => s.version }

  s.source_files  = "SwiftMessageBar/*.swift"
  s.resources = "SwiftMessageBar/*.png"

end
