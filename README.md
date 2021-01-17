# Revo
Revo - Reverse Video, is a soon to be released iOS app that allows users to record seamless video while switching between the front and rear-facing cameras. Revo does this by utilising AVFoundation's AVCaptureMultiCamSession, a capture session that supports simultaneous capture from multiple inputs of the same media type. This app is currently only supported on devices XS, XS Max, XR and later running on iOS 13.
<br>

### Features
<ul>
  <li><strong>SwitchCam Mode</strong> the default mode that allows switch between the front and rear camera within the same take.</li>
  <li><strong>SplitScreen Mode</strong> presents two resizable AVCaptureVideoPreviewLayers which take up the top and bottom half of the display.</li>
  <li><strong>PiP Mode</strong> taken from Apple's PiP, PiP mode presents a mobile, styleable, resizable AVCaptureVideoPreviewLayer.</li>
  <li><strong>Live Broadcasting</strong> using ReplayKit users may live broadcast from with any recording mode.</li>
  <li><strong>Library</strong> recordings are saved to the users gallary, which they can share, save, delete or play.</li>
</ul>

 ### Requirements
<ul>
  <li>iOS 13+</li>
  <li>Xcode 12</li>
</ul>

  
### CocoaPods
Dune uses AirBnb's vector animation library [lottie-ios](https://github.com/airbnb/lottie-ios/blob/master/README.md)

Add the pod to your Podfile:
```ruby
pod 'lottie-ios'
```

And then run:
```ruby
pod install
```

<p align="center" style="background-color: black">
  <img src="https://i.imgur.com/IL9ojDc.png" width="70%">
</p>
