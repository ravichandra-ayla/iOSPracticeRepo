# Ayla Mobile Fast Track (AMFT)
## Codename: iOS_FastTrack 
A starter Sepia-based white label Application for iOS

Ayla Mobile Fast Track is a showcase of all of the functionality residing within the AMF (Sepia) framework with white label capability.

If you have not installed the above components, please install them first.

## Setup
### Clone the iOS_FastTrack repo.

$ git clone https://github.com/AylaNetworks/iOS_FastTrack_Public.git

### Execute the setup script

From the project root:
$ cd iOS_FastTrack_Public/


$ ./setup_customer.sh

After the script finishes, the project will be opened for you, run FastTrack target.

## Assets

Refer to the architecture and guide documents from the [Common_Sepia](https://github.com/AylaNetworks/common_sepia_Public) repo for refernce level information.

The [Common Sepia Assets](https://github.com/AylaNetworks/common_sepia_assets_Public/) repo houses the Ayla Mobile UI Design Kit, associated documents and color specifications.


## Minimum Requirements

- [CocoaPods](http://cocoapods.org) 1.9.0 or higher
- [Xcode 12.0.1](https://developer.apple.com/xcode/downloads/) or higher
- iOS 12.2 or higher

# Release Notes

### [6.6.10](https://github.com/AylaNetworks/iOS_FastTrack_Public/releases/tag/v6.6.10)
#### (2021-09-23)
- FastTrack UI Misc. fixes


### [6.6.4](https://github.com/AylaNetworks/iOS_FastTrack_Public/releases/tag/v6.6.4)
#### (2021-01-30)
- FastTrack UI Misc. fixes


### [6.6.3](https://github.com/AylaNetworks/iOS_FastTrack_Public/releases/tag/v6.6.3)
#### (2021-01-18)
- Updated localizations and image assets for schedules, onboarding screens
- Misc Bug and crash fixes
  - Missing Push notification capability for TF/App Store builds fix
  - Schedules screen for other than FastTrack devices configurations crash fix
  - Sign-in screen and drawer menu logo is not aligned properly fix
  - Device list screen margin is not as per UI/UX fix
  - Product name is not displaying in some edge cases fix
  - Account creation and forgot password email template issues fix
- Built using iOS_AylaSDK_Public  & iOS_Sepia_Public v6.6.3

### [6.6.2](https://github.com/AylaNetworks/iOS_FastTrack_Public/releases/tag/v6.6.2)
#### (2020-11-20)
- FastTrack UI Misc. fixes
- iOS 14.2 Support
- Minimum deployment target bumped to 12.2
- Built using iOS_AylaSDK_Public & iOS_Sepia_Public v6.6.2

### [6.6.1](https://github.com/AylaNetworks/iOS_FastTrack_Public/releases/tag/v6.6.1)
#### (2020-10-30)
- WPA3 Support and updated Wi-Fi Security type strings
- FastTrack UI Support
- Built using iOS_AylaSDK_Public  & iOS_Sepia_Public v6.6.1
