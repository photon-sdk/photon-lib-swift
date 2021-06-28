# Overview
Photon is an SDK for managing encrypted private keys in the cloud.

For the benefits and threat model on storing secrets on iCloud please see here.

There are 3 components to Photon:
- key server run by the wallet provider
    - stores high entropy encryption keys and provides server side security such as rate limited PIN authentication
- The users iCloud
- The bitcoin wallet
    - this is the client application the user interacts with
This SDK is for bitcoin wallet developers who want to implement Photon key management in their app.

This SDK should be used within a iOS wallet to:
- generate encryption keys
- encrypt private keys
- interact with the users iCloud account
- interact with your keyserver

A demo Swift iOS application will be available in September, which documents how the Photon components work together in a final product. The application will be open source.

# Usage
## Installing the library

#### Using Swift package manager
Not yet implemented.

#### Using Cocoapods
Not yet implemented.

#### Installing mannaually
Copy the contents of [BTCPhotonKit](./BTCPhotonKit) to your xcode project.

### Configuring Xcode
* Enable the Cloudkit capability within xcode settings

* ##### Using Xcode automatically manage signing
Follow [Apple documentaion](https://developer.apple.com/documentation/cloudkit/enabling_cloudkit_in_your_app) or follow the images below
     
![Alt text](images/a.png?raw=true)
![Alt text](images/b.png?raw=true)
![Alt text](images/c.png?raw=true)
![Alt text](images/d.png?raw=true)

## Example usage

##### Start the key server 
Ensure the server is running: [Photon KeyServer](https://github.com/photon-sdk/photon-keyserver)

##### Generate a secret and encrypt it using cha-cha
```swift
 let secret = "bottom evoke mask jar patch distance force invite senior soccer allow youth normal beauty joke live rebel charge merge episode abandon donor screen video"
 let encryptedSecret = secret.data(using: .utf8)
 
 var cha = ChaCha()
 let key: SymmetricKey = cha.generateKey()
 let keyAsData = key.withUnsafeBytes({
             return Data(Array($0))
         })
 
 // sealedBox is the encrypted seed/secret
 let sealedBox = try! cha.encrypt(secret: encryptedSecret!, key: keyAsData)
```
##### Store the encryption key on the keyserver
```swift
 let keyServer = Keyserver("http://localhost:8000")
 keyServer.createKey(pin: pin) { (result) in
            if case .success(let data) = result {
                // yay, it worked!
             }
        }
```
##### Store the encrypted secret on the users iCloud
```swift
let cloudStore = CloudStore()
cloudStore.putKey(keyId: keyId, ciphertext: ciphertext) { (result) in
            if case .success(let status) = result {
                response = status
            }
         }

```
##### How to restore the key (from a new phone for example)
```swift
 let cloudStore = CloudStore()
 let keyBackUp = Keybackup("server_path", cloudStore: cloudStore)
 keyBackUp.restoreBackup(pin: pin) { result in
        if case .success(let data) = result {
           restoreBackupResponse = data
       }
    }

```

##### Change the pin
```swift
  let cloudStore = CloudStore()
  let keyBackUp = Keybackup("server_path", cloudStore: cloudStore)
  keyBackUp.changePin(pin: pin, newPin: "") { result in
          if case .success(let data) = result {
               changePinResponse = data
            }
      }

```
##### Add Recovery Phone Number (optional)
```swift
 let cloudStore = CloudStore()
 let keyBackUp = Keybackup("server_path", cloudStore: cloudStore)
 keyBackUp.registerPhone(userId: phone, pin: pin) { result in
           if case .success(let data) = result {
                 registerPhoneResponse = data
           }
                   
     }

```
##### Add Recovery Email Address (optional)
```swift
 let cloudStore = CloudStore()
 let keyBackUp = Keybackup("server_path", cloudStore: cloudStore)
 keyBackUp.registerEmail(userId: email, pin: pin) { result in
         if case .success(let data) = result {
               emailResponse = data
         }
    }

```
##### Reset the PIN via Recovery Email Address (works the same via phone)
```swift
 let cloudStore = CloudStore()
 let keyBackUp = Keybackup("server_path", cloudStore: cloudStore)
 keyBackUp.initPinReset(userId: phone ) { result in
           if case .success(let data) = result {
                pinResponse = data
           } 
      }

```
##### Create backup
```swift
 let cloudStore = CloudStore()
 let keyBackUp = Keybackup("server_path", cloudStore: cloudStore)
 keyBackUp.createBackup(data: ciphertext, pin: pin) { result in
     if case .success(let data) = result {
           createBackupResponse = data
       }
 }

```
##### Restore backup
```swift
 let cloudStore = CloudStore()
 let keyBackUp = Keybackup("server_path", cloudStore: cloudStore)
 keyBackUp.restoreBackup(pin: pin) { result in
   if case .success(let data) = result {
          restoreBackupResponse = data
   }
 }

```
##### How to run the tests
To run test checkout this library open [BTCPhotonKit.xcodeproj](./BTCPhotonKit.xcodeproj) 
select Product > Test  (⌘ + U )
