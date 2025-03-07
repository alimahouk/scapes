# Scapes Messenger

Scapes was a feature-rich iOS messenger that provides a modern and intuitive messaging experience with advanced features for personal communications.

## Features

### Messaging

- Real-time messaging
- Message timing and delivery status
- Status updates
- Sound notifications
- See public chats happening between mutual contacts in real-time

### Media & Content

- User profiles
- Gallery view with zooming capabilities
- Image sharing and viewing
- Location sharing with map integration

### User Experience

- Thread-based conversation view
- Contact management with cloud sync
- Mini feed for activity updates
- Custom UI elements (switches, strobing effects)
- Smooth orientation handling

### Technical Highlights

- Built for iOS using Objective-C
- Efficient message handling and storage
- Custom UI components for optimal performance
- Location services integration
- Robust media handling

## Project Structure

- `Classes/`: Core application logic
  - `Controllers/`: View controllers
  - `Categories/`: Objective-C category extensions
  - `External/`: Third-party integrations
  - `AppDelegate/`: Application lifecycle management
  - `Support/`: Helper and utility classes
- `Resources/`: Assets and resource files
- `Images.xcassets/`: Image assets
- `en.lproj/ & fr.lproj/`: Localization files

## Acknowledgements

This project makes use of the following third-party libraries and components:

### Networking & Communication

- **AFNetworking**: A delightful networking framework for iOS and macOS
- **GCDAsyncSocket**: An asynchronous socket networking library for Mac and iOS
- **STUN**: STUN (Session Traversal Utilities for NAT) client implementation
- **Reachability**: System library for network status monitoring
- **PortMapper**: Network port mapping utility

### Database & Storage

- **FMDB**: A SQLite database library built on top of SQLite
- **RNCryptor**: CCCryptor (AES encryption) wrappers for iOS and Mac
- **KeychainItemWrapper**: Keychain access and management utility

### UI Components

- **MBProgressHUD**: An iOS drop-in class that displays a translucent HUD with an indicator and/or labels
- **TTTAttributedLabel**: A drop-in replacement for UILabel that supports attributes, data detectors, links, and more
- **EasedValue**: Smooth value transitions and animations utility

### Utilities

- **libPhoneNumber**: Google's common Java, C++ and JavaScript library for parsing, formatting, and validating international phone numbers
- **Base64**: Base64 encoding and decoding utility
- **UIDeviceHardware**: Device identification and hardware capability detection

## License

This project is licensed under the terms specified in the LICENSE file.

## Author

Created by Ali Mahouk.
