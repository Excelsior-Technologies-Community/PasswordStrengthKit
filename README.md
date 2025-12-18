 
# PasswordStrengthKit

PasswordStrengthKit is a SwiftUI password strength meter with
real-time validation and optional secure storage.

---

## Add Dependency (Swift Package Manager)

### Using Xcode

1. Open your project in Xcode
2. Go to **File → Add Packages…**
3. Paste the repository URL:

```

[https://github.com/Excelsior-Technologies-Community/PasswordStrengthKit](https://github.com/Excelsior-Technologies-Community/PasswordStrengthKit)

````

4. Click **Add Package**
5. Select **PasswordStrengthKit** and add it to your app target

---

## Import

```swift
import PasswordStrengthKit
````

---

## Create Password Meter

```swift
@StateObject private var passwordMeter = PasswordStrengthMeter(
    rules: PasswordRule.defaultRules,
    shouldStorePassword: true
)

@State private var userPassword: String = ""
@State private var passwordStrength: PasswordStrengthLevel = .weak
```

---

## Use PasswordStrengthView

```swift
PasswordStrengthView(meter: passwordMeter)
```

---

## Full Example

```swift
//  ContentView.swift
//  DemoProject
//
//  Created by Noman Belim
//

import SwiftUI
import PasswordStrengthKit

struct ContentView: View {

    @StateObject private var passwordMeter = PasswordStrengthMeter(
        rules: PasswordRule.defaultRules,
        shouldStorePassword: true
    )

    @State private var userPassword: String = ""
    @State private var passwordStrength: PasswordStrengthLevel = .weak

    var body: some View {
        VStack(spacing: 24) {

            PasswordStrengthView(meter: passwordMeter)

            Divider()

            Text("Password Strength: \(passwordStrength.rawValue)")
                .foregroundColor(passwordStrength.color)

            Button("Submit") {
                print("Password:", userPassword)
                print("Strength:", passwordStrength)
            }
            .disabled(passwordStrength != .strong)
        }
        .padding()
        .onAppear {
            passwordMeter.onPasswordChange = { password, strength in
                userPassword = password
                passwordStrength = strength
            }
        }
    }
}

#Preview {
    ContentView()
}
```

---

## Where Is the Password Stored?

* The **current password is always available in**:

```swift
userPassword
```

* When `shouldStorePassword = true` and strength is **Strong**:

  * The password is also stored securely in **Keychain**

---

## Summary

* `PasswordStrengthView` → UI
* `PasswordStrengthMeter` → logic
* `userPassword` → final password value
* `passwordStrength` → strength state

 