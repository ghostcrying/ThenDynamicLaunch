# ThenDynamicLaunch

Fork from LLDynamicLaunchScreen(https://github.com/internetWei/LLDynamicLaunchScreen)



## Usage

##### first

```
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ThenDynamicLaunch.shared.config()
    return true
}
```

##### then

```
ThenDynamicLaunch.shared.replace(with: UIImage(named: "pexels-1"), direction: .portraitLight)
```



## Requirements

1. iOS 11.0+



## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

1. File > Swift Packages > Add Package Dependency
2. Copy & paste `https://github.com/ghostcrying/ThenDynamicLaunch` then follow the instruction

### [Carthage](https://github.com/Carthage/Carthage)

1. Add this line to your Cartfile: `github "ghostcrying/ThenDynamicLaunch"`
2. Read the [official instruction](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)

### [CocoaPods](http://cocoapods.org)

1. Install the latest release of CocoaPods: `gem install cocoapods`
2. Add this line to your Podfile: `pod 'ThenDynamicLaunch'`
3. Install the pod: `pod install`
