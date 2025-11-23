import SwiftUI

struct PhoneLoginView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService

    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var isCodeSent = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.white
                    .ignoresSafeArea()

                VStack(spacing: DesignSystem.Spacing.moduleSpacing) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.smallSpacing) {
                        Text(isCodeSent ? "Enter Code" : "My number is")
                            .font(DesignSystem.Typography.headerFont)
                            .foregroundColor(DesignSystem.Colors.black)

                        Text(isCodeSent ? "We sent a code to \(phoneNumber)" : "We use phone verification for safety")
                            .font(DesignSystem.Typography.bodyFont)
                            .foregroundColor(DesignSystem.Colors.mediumGray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, DesignSystem.Spacing.moduleSpacing * 2)

                    Spacer()

                    // Input
                    if !isCodeSent {
                        VStack(spacing: DesignSystem.Spacing.inlineSpacing) {
                            TextField("Phone Number", text: $phoneNumber)
                                .font(DesignSystem.Typography.bodyFontMedium)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .padding()
                                .background(DesignSystem.Colors.softGray)
                                .cornerRadius(DesignSystem.CornerRadius.small)

                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(DesignSystem.Typography.captionFont)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                    } else {
                        VStack(spacing: DesignSystem.Spacing.inlineSpacing) {
                            TextField("Verification Code", text: $verificationCode)
                                .font(DesignSystem.Typography.bodyFontMedium)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .padding()
                                .background(DesignSystem.Colors.softGray)
                                .cornerRadius(DesignSystem.CornerRadius.small)

                            Button(action: {
                                isCodeSent = false
                                verificationCode = ""
                            }) {
                                Text("Didn't receive it? Try again")
                                    .font(DesignSystem.Typography.captionFont)
                                    .foregroundColor(DesignSystem.Colors.accentBlue)
                            }

                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(DesignSystem.Typography.captionFont)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                    }

                    Spacer()

                    // Continue Button
                    Button(action: {
                        handleContinue()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        } else {
                            Text("Continue")
                                .font(DesignSystem.Typography.buttonFont)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    }
                    .background(isButtonEnabled ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.mediumGray)
                    .cornerRadius(DesignSystem.CornerRadius.button)
                    .disabled(!isButtonEnabled || isLoading)
                    .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                    .padding(.bottom, DesignSystem.Spacing.moduleSpacing)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(DesignSystem.Colors.black)
                    }
                }
            }
        }
    }

    private var isButtonEnabled: Bool {
        if isCodeSent {
            return verificationCode.count >= 4
        } else {
            return phoneNumber.count >= 10
        }
    }

    private func handleContinue() {
        errorMessage = nil

        if !isCodeSent {
            sendOTP()
        } else {
            verifyOTP()
        }
    }

    private func sendOTP() {
        isLoading = true

        Task {
            do {
                try await authService.sendOTP(phoneNumber: phoneNumber)
                isCodeSent = true
            } catch {
                errorMessage = "Failed to send code. Please try again."
            }
            isLoading = false
        }
    }

    private func verifyOTP() {
        isLoading = true

        Task {
            do {
                try await authService.verifyOTP(phoneNumber: phoneNumber, code: verificationCode)
                dismiss()
            } catch {
                errorMessage = "Invalid code. Please try again."
            }
            isLoading = false
        }
    }
}

struct PhoneLoginView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneLoginView()
            .environmentObject(AuthService.shared)
    }
}
