#Overview
 Coming soon.

#Usage
## Installing the library

#### Using Swift package manager
not implemented yet.
#### Using Cocoapods
not implemented yet.
#### Installing mannaually
Copy the contents of [BTCPhotonKit](./BTCPhotonKit) to your xcode project

### Configuring Xcode
* Enable the Cloudkit capability within xcode settings


## Example usage

##### Start the key server 
Ensure the server is running [Coming soon]

##### Generate a secret and encrypt it using cha-cha
```swift
 let secret = "bottom evoke mask jar patch distance force invite senior soccer allow youth normal beauty joke live rebel charge merge episode abandon donor screen video"
 let encryptedSecret = secret.data(using: .utf8)
 
 var cha = ChaCha()
 let key: SymmetricKey = cha.generateKey()
 let keyAsData = key.withUnsafeBytes({
             return Data(Array($0))
         })
 
 let sealedBox = try! cha.encrypt(secret: encryptedSecret!, key: keyAsData)
```
##### Store the encryption key on the keyserver
```swift
 let keyServer = Keyserver("http://localhost:8000")
 keyServer.createKey(pin: pin) { (result) in
            if case .success(let data) = result {
                // if our session will return an error
                // this will not set
             }
        }
```
##### Store the encrypted secret on the users iCloud
```swift
let cloudStore = CloudStore()
cloudStore.putKey(keyId: keyId, ciphertext: ciphertext) { (result) in
            if case .success(let status) = result {
                mResponse = status
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
