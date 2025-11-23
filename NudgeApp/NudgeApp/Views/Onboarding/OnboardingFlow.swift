import SwiftUI
import PhotosUI

struct OnboardingFlow: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var locationService: LocationService

    @State private var currentStep = 0
    @State private var name = ""
    @State private var age = 21
    @State private var gender = "Woman"
    @State private var selectedPhotos: [UIImage] = []
    @State private var prompts: [Prompt] = []
    @State private var minAge = 18
    @State private var maxAge = 35
    @State private var maxDistance = 50
    @State private var interestedIn: Set<String> = ["Man"]

    var body: some View {
        ZStack {
            DesignSystem.Colors.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress Bar
                ProgressView(value: Double(currentStep + 1), total: 6)
                    .tint(DesignSystem.Colors.accentBlue)
                    .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                    .padding(.vertical, DesignSystem.Spacing.inlineSpacing)

                // Content
                TabView(selection: $currentStep) {
                    BasicInfoView(name: $name, age: $age, gender: $gender)
                        .tag(0)

                    PhotoUploadView(selectedPhotos: $selectedPhotos)
                        .tag(1)

                    PromptsView(prompts: $prompts)
                        .tag(2)

                    PreferencesView(
                        minAge: $minAge,
                        maxAge: $maxAge,
                        maxDistance: $maxDistance,
                        interestedIn: $interestedIn
                    )
                    .tag(3)

                    LocationPermissionView()
                        .tag(4)

                    CompleteView()
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .disabled(true)

                // Navigation Buttons
                HStack(spacing: DesignSystem.Spacing.inlineSpacing) {
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Text("Back")
                                .font(DesignSystem.Typography.buttonFont)
                                .foregroundColor(DesignSystem.Colors.accentBlue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(DesignSystem.Colors.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                        .stroke(DesignSystem.Colors.accentBlue, lineWidth: 2)
                                )
                        }
                    }

                    Button(action: {
                        handleContinue()
                    }) {
                        Text(currentStep == 5 ? "Finish" : "Continue")
                            .font(DesignSystem.Typography.buttonFont)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(canContinue ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.mediumGray)
                            .cornerRadius(DesignSystem.CornerRadius.button)
                    }
                    .disabled(!canContinue)
                }
                .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                .padding(.bottom, DesignSystem.Spacing.moduleSpacing)
            }
        }
    }

    private var canContinue: Bool {
        switch currentStep {
        case 0: return !name.isEmpty && age >= 18
        case 1: return selectedPhotos.count >= 3
        case 2: return prompts.count >= 2
        case 3: return !interestedIn.isEmpty
        case 4: return locationService.authorizationStatus == .authorizedWhenInUse || locationService.authorizationStatus == .authorizedAlways
        case 5: return true
        default: return false
        }
    }

    private func handleContinue() {
        if currentStep < 5 {
            withAnimation {
                currentStep += 1
            }
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        Task {
            // Upload photos (simplified - in production, upload to Supabase Storage)
            let photoUrls = selectedPhotos.enumerated().map { index, _ in
                "https://placeholder.com/photo\(index).jpg"
            }

            let preferences = UserPreferences(
                minAge: minAge,
                maxAge: maxAge,
                maxDistance: maxDistance,
                interestedIn: Array(interestedIn)
            )

            try? await authService.createUserProfile(
                name: name,
                age: age,
                gender: gender,
                photos: photoUrls,
                prompts: prompts,
                preferences: preferences
            )

            // Create AI profile
            if let userId = authService.currentUser?.id {
                try? await AIService.shared.createAIProfile(userId: userId)
            }

            // Start location tracking
            locationService.startCoarseLocationUpdates()
        }
    }
}

// MARK: - Basic Info View

struct BasicInfoView: View {
    @Binding var name: String
    @Binding var age: Int
    @Binding var gender: String

    let genders = ["Woman", "Man", "Non-binary"]

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.moduleSpacing) {
            VStack(spacing: DesignSystem.Spacing.smallSpacing) {
                Text("Let's start with the basics")
                    .font(DesignSystem.Typography.headerFont)
                    .foregroundColor(DesignSystem.Colors.black)
            }
            .padding(.top, DesignSystem.Spacing.moduleSpacing)

            VStack(spacing: DesignSystem.Spacing.inlineSpacing) {
                TextField("First Name", text: $name)
                    .font(DesignSystem.Typography.bodyFontMedium)
                    .padding()
                    .background(DesignSystem.Colors.softGray)
                    .cornerRadius(DesignSystem.CornerRadius.small)

                HStack {
                    Text("Age")
                        .font(DesignSystem.Typography.bodyFontMedium)
                    Spacer()
                    Picker("Age", selection: $age) {
                        ForEach(18...80, id: \.self) { age in
                            Text("\(age)").tag(age)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                .background(DesignSystem.Colors.softGray)
                .cornerRadius(DesignSystem.CornerRadius.small)

                HStack {
                    Text("I am a")
                        .font(DesignSystem.Typography.bodyFontMedium)
                    Spacer()
                    Picker("Gender", selection: $gender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                .background(DesignSystem.Colors.softGray)
                .cornerRadius(DesignSystem.CornerRadius.small)
            }
            .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)

            Spacer()
        }
    }
}

// MARK: - Photo Upload View

struct PhotoUploadView: View {
    @Binding var selectedPhotos: [UIImage]
    @State private var showImagePicker = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.moduleSpacing) {
            VStack(spacing: DesignSystem.Spacing.smallSpacing) {
                Text("Add your photos")
                    .font(DesignSystem.Typography.headerFont)
                    .foregroundColor(DesignSystem.Colors.black)

                Text("Add at least 3 photos")
                    .font(DesignSystem.Typography.bodyFont)
                    .foregroundColor(DesignSystem.Colors.mediumGray)
            }
            .padding(.top, DesignSystem.Spacing.moduleSpacing)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.inlineSpacing) {
                ForEach(0..<6, id: \.self) { index in
                    if index < selectedPhotos.count {
                        Image(uiImage: selectedPhotos[index])
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(DesignSystem.CornerRadius.small)
                    } else {
                        Button(action: { showImagePicker = true }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                    .fill(DesignSystem.Colors.softGray)
                                    .frame(height: 200)

                                Image(systemName: "plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(DesignSystem.Colors.mediumGray)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)

            Spacer()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImages: $selectedPhotos, maxSelection: 6)
        }
    }
}

// Simple Image Picker placeholder
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    let maxSelection: Int

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage, parent.selectedImages.count < parent.maxSelection {
                parent.selectedImages.append(image)
            }
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Additional views (simplified for length)

struct PromptsView: View {
    @Binding var prompts: [Prompt]

    let availablePrompts = [
        "My ideal Sunday",
        "I'm looking for",
        "A life goal of mine",
        "I geek out on",
        "The key to my heart"
    ]

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.moduleSpacing) {
            Text("Answer 2 prompts")
                .font(DesignSystem.Typography.headerFont)
                .padding(.top, DesignSystem.Spacing.moduleSpacing)

            ForEach(0..<2, id: \.self) { index in
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.smallSpacing) {
                    if index < prompts.count {
                        Text(prompts[index].question)
                            .font(DesignSystem.Typography.promptQuestionFont)
                            .foregroundColor(DesignSystem.Colors.mediumGray)
                    } else {
                        Menu {
                            ForEach(availablePrompts, id: \.self) { prompt in
                                Button(prompt) {
                                    prompts.append(Prompt(id: UUID().uuidString, question: prompt, answer: ""))
                                }
                            }
                        } label: {
                            Text("Select a prompt")
                                .font(DesignSystem.Typography.promptQuestionFont)
                                .foregroundColor(DesignSystem.Colors.accentBlue)
                        }
                    }

                    if index < prompts.count {
                        TextField("Your answer", text: Binding(
                            get: { prompts[index].answer },
                            set: { prompts[index].answer = $0 }
                        ))
                        .font(DesignSystem.Typography.bodyFont)
                        .padding()
                        .background(DesignSystem.Colors.softGray)
                        .cornerRadius(DesignSystem.CornerRadius.small)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
            }

            Spacer()
        }
    }
}

struct PreferencesView: View {
    @Binding var minAge: Int
    @Binding var maxAge: Int
    @Binding var maxDistance: Int
    @Binding var interestedIn: Set<String>

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.moduleSpacing) {
            Text("Set your preferences")
                .font(DesignSystem.Typography.headerFont)
                .padding(.top, DesignSystem.Spacing.moduleSpacing)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.inlineSpacing) {
                Text("Age range: \(minAge) - \(maxAge)")
                    .font(DesignSystem.Typography.bodyFontMedium)

                HStack {
                    Slider(value: Binding(
                        get: { Double(minAge) },
                        set: { minAge = Int($0) }
                    ), in: 18...80, step: 1)
                    Slider(value: Binding(
                        get: { Double(maxAge) },
                        set: { maxAge = Int($0) }
                    ), in: 18...80, step: 1)
                }
                .accentColor(DesignSystem.Colors.accentBlue)

                Text("Distance: \(maxDistance) km")
                    .font(DesignSystem.Typography.bodyFontMedium)
                    .padding(.top)

                Slider(value: Binding(
                    get: { Double(maxDistance) },
                    set: { maxDistance = Int($0) }
                ), in: 1...100, step: 1)
                .accentColor(DesignSystem.Colors.accentBlue)

                Text("Interested in")
                    .font(DesignSystem.Typography.bodyFontMedium)
                    .padding(.top)

                HStack {
                    ForEach(["Woman", "Man", "Non-binary"], id: \.self) { gender in
                        Button(action: {
                            if interestedIn.contains(gender) {
                                interestedIn.remove(gender)
                            } else {
                                interestedIn.insert(gender)
                            }
                        }) {
                            Text(gender)
                                .font(DesignSystem.Typography.bodyFont)
                                .foregroundColor(interestedIn.contains(gender) ? .white : DesignSystem.Colors.accentBlue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(interestedIn.contains(gender) ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.white)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(DesignSystem.Colors.accentBlue, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)

            Spacer()
        }
    }
}

struct LocationPermissionView: View {
    @EnvironmentObject var locationService: LocationService

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.moduleSpacing) {
            VStack(spacing: DesignSystem.Spacing.smallSpacing) {
                Text("Enable location")
                    .font(DesignSystem.Typography.headerFont)

                Text("Precise location is used only in Nudge Mode")
                    .font(DesignSystem.Typography.bodyFont)
                    .foregroundColor(DesignSystem.Colors.mediumGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
            }
            .padding(.top, DesignSystem.Spacing.moduleSpacing * 2)

            Image(systemName: "location.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(DesignSystem.Colors.accentBlue)

            Button(action: {
                locationService.requestWhenInUseAuthorization()
            }) {
                Text("Enable Location")
                    .font(DesignSystem.Typography.buttonFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(DesignSystem.Colors.accentBlue)
                    .cornerRadius(DesignSystem.CornerRadius.button)
            }

            Spacer()
        }
    }
}

struct CompleteView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.moduleSpacing) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(DesignSystem.Colors.accentBlue)

            Text("You're all set!")
                .font(DesignSystem.Typography.headerFont)

            Text("Start discovering people near you")
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.Colors.mediumGray)

            Spacer()
        }
    }
}
