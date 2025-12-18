//
//  PasswordStrengthKit.swift
//  DeliveryTrackingSystem
//
//  Created by Noman belim on 18/12/25.
//

import Foundation
import SwiftUI

public enum PasswordStrengthLevel: String, CaseIterable {
    case weak = "Weak"
    case medium = "Medium"
    case strong = "Strong"
    
    public var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
    
    public var progress: CGFloat {
        switch self {
        case .weak: return 0.33
        case .medium: return 0.66
        case .strong: return 1.0
        }
    }
}

// MARK: - PasswordRule.swift
public struct PasswordRule: Identifiable {
    public let id = UUID()
    public let title: String
    public let validator: (String) -> Bool
    
    public init(title: String, validator: @escaping (String) -> Bool) {
        self.title = title
        self.validator = validator
    }
    
    public static var defaultRules: [PasswordRule] {
        [
            PasswordRule(title: "At least 8 characters") { $0.count >= 8 },
            PasswordRule(title: "Contains uppercase letter") { $0.rangeOfCharacter(from: .uppercaseLetters) != nil },
            PasswordRule(title: "Contains lowercase letter") { $0.rangeOfCharacter(from: .lowercaseLetters) != nil },
            PasswordRule(title: "Contains number") { $0.rangeOfCharacter(from: .decimalDigits) != nil },
            PasswordRule(title: "Contains special character") { $0.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil }
        ]
    }
}

// MARK: - PasswordStrengthMeter.swift
public class PasswordStrengthMeter: ObservableObject {
    @Published public var password: String = ""
    @Published public var strengthLevel: PasswordStrengthLevel = .weak
    @Published public var isSecure: Bool = true
    
    public let rules: [PasswordRule]
    public let shouldStorePassword: Bool
    public var onPasswordChange: ((String, PasswordStrengthLevel) -> Void)?
    
    public init(
        rules: [PasswordRule] = PasswordRule.defaultRules,
        shouldStorePassword: Bool = false,
        onPasswordChange: ((String, PasswordStrengthLevel) -> Void)? = nil
    ) {
        self.rules = rules
        self.shouldStorePassword = shouldStorePassword
        self.onPasswordChange = onPasswordChange
    }
    
    public func validatePassword() {
        let passedRules = rules.filter { $0.validator(password) }.count
        
        if passedRules <= 2 {
            strengthLevel = .weak
        } else if passedRules <= 4 {
            strengthLevel = .medium
        } else {
            strengthLevel = .strong
        }
        
        // Notify callback with password and strength
        onPasswordChange?(password, strengthLevel)
        
        // Store password if needed
        if shouldStorePassword && strengthLevel == .strong {
            storePassword()
        }
    }
    
    public func isRuleSatisfied(_ rule: PasswordRule) -> Bool {
        rule.validator(password)
    }
    
    private func storePassword() {
        // Securely store password in Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userPassword",
            kSecValueData as String: password.data(using: .utf8)!
        ]
        
        // Delete old password first
        SecItemDelete(query as CFDictionary)
        
        // Add new password
        SecItemAdd(query as CFDictionary, nil)
    }
    
    public func retrieveStoredPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userPassword",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return password
    }
}

// MARK: - PasswordStrengthView.swift
public struct PasswordStrengthView: View {
    @ObservedObject var meter: PasswordStrengthMeter
    
    public init(meter: PasswordStrengthMeter) {
        self.meter = meter
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Password Input Field
            HStack {
                if meter.isSecure {
                    SecureField("Enter password", text: $meter.password)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: meter.password) { _ in
                            meter.validatePassword()
                        }
                } else {
                    TextField("Enter password", text: $meter.password)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: meter.password) { _ in
                            meter.validatePassword()
                        }
                }
                
                Button(action: { meter.isSecure.toggle() }) {
                    Image(systemName: meter.isSecure ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            
            // Strength Indicator
            if !meter.password.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Strength:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(meter.strengthLevel.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(meter.strengthLevel.color)
                    }
                    
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(meter.strengthLevel.color)
                                .frame(width: geometry.size.width * meter.strengthLevel.progress, height: 8)
                                .cornerRadius(4)
                                .animation(.easeInOut(duration: 0.3), value: meter.strengthLevel)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Rules Checklist
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password Requirements:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top, 8)
                    
                    ForEach(meter.rules) { rule in
                        HStack(spacing: 8) {
                            Image(systemName: meter.isRuleSatisfied(rule) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(meter.isRuleSatisfied(rule) ? .green : .gray)
                                .font(.system(size: 16))
                            
                            Text(rule.title)
                                .font(.caption)
                                .foregroundColor(meter.isRuleSatisfied(rule) ? .primary : .secondary)
                        }
                        .animation(.easeInOut(duration: 0.2), value: meter.isRuleSatisfied(rule))
                    }
                }
            }
        }
        .padding()
    }
}
