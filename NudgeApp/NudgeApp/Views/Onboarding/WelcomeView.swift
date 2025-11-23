import SwiftUI

struct WelcomeView: View {
    @State private var showPhoneLogin = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.white
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.moduleSpacing) {
                Spacer()

                // Logo placeholder
                Image(systemName: "arrow.right.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(DesignSystem.Colors.accentBlue)

                VStack(spacing: DesignSystem.Spacing.inlineSpacing) {
                    Text("Welcome to Nudge")
                        .font(DesignSystem.Typography.headerFontLarge)
                        .foregroundColor(DesignSystem.Colors.black)

                    Text("Real-life attraction, intelligently amplified")
                        .font(DesignSystem.Typography.bodyFont)
                        .foregroundColor(DesignSystem.Colors.mediumGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                }

                Spacer()

                VStack(spacing: DesignSystem.Spacing.inlineSpacing) {
                    Button(action: {
                        showPhoneLogin = true
                    }) {
                        Text("Get Started")
                            .font(DesignSystem.Typography.buttonFont)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(DesignSystem.Colors.accentBlue)
                            .cornerRadius(DesignSystem.CornerRadius.button)
                    }

                    Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                        .font(DesignSystem.Typography.smallFont)
                        .foregroundColor(DesignSystem.Colors.mediumGray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                .padding(.bottom, DesignSystem.Spacing.moduleSpacing)
            }
        }
        .fullScreenCover(isPresented: $showPhoneLogin) {
            PhoneLoginView()
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
