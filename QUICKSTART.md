# Nudge - Quick Start Guide

Get the Nudge dating app running in 15 minutes.

## Prerequisites Checklist

- [ ] Xcode 15.0+
- [ ] Supabase account (free tier is fine)
- [ ] OpenAI API key (optional, for AI features)

## 5-Step Setup

### 1. Supabase Setup (5 min)

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Wait for project to initialize (~2 minutes)
3. Go to **SQL Editor** → New Query
4. Copy entire contents of `supabase_schema.sql` and run
5. Go to **Settings** → **API** and copy:
   - Project URL
   - `anon` public key

### 2. Configure App (2 min)

Open `NudgeApp/NudgeApp/Config/SupabaseConfig.swift` and update:

```swift
struct SupabaseConfig {
    static let url = "https://xxxxx.supabase.co"
    static let anonKey = "your-anon-key-here"
    static let openAIKey = "" // Optional
}
```

### 3. Open in Xcode (3 min)

```bash
cd NudgeApp
open NudgeApp.xcodeproj
```

Wait for Swift Package Manager to resolve dependencies (Supabase Swift).

### 4. Configure Signing (2 min)

1. Select **NudgeApp** target
2. Go to **Signing & Capabilities**
3. Select your Team
4. Change bundle identifier if needed (e.g., `com.yourname.nudge`)

### 5. Run (3 min)

1. Select iPhone 15 Pro simulator (or your device)
2. Press `Cmd+R`
3. Wait for build to complete
4. Grant location permissions when prompted

## Test the App

### Onboarding Flow
1. Tap "Get Started"
2. Enter phone number (use test number in Supabase Auth settings)
3. Enter OTP code
4. Complete profile:
   - Name, age, gender
   - Upload 3 photos (use simulator camera or library)
   - Answer 2 prompts
   - Set preferences
   - Enable location

### Regular Mode
- View dating feed
- Swipe right to like
- Swipe left to pass
- Get matches when mutual

### Nudge Mode
1. Tap "Nudge Mode" button
2. Grant precise location
3. See nearby users (needs 2+ users active)
4. Send nudges
5. Match when mutual

## Common Issues

### Dependencies not resolving
- File → Packages → Reset Package Caches
- File → Packages → Update to Latest Package Versions

### Build errors about Supabase
- Ensure you're using the latest supabase-swift package
- Clean build folder (Cmd+Shift+K)

### Location not working
- Simulator: Features → Location → Custom Location
- Device: Settings → Privacy → Location Services → Nudge → While Using

### Database errors
- Verify schema was run successfully in Supabase
- Check RLS policies are enabled
- Verify your API keys are correct

## Next Steps

1. **Add test users**: Create multiple accounts to test matching
2. **Enable Realtime**: Database → Replication → Enable for `chat_messages`
3. **Set up Storage**: Storage → Create bucket `profile-photos`
4. **Add analytics**: Integrate Mixpanel/Amplitude (optional)
5. **Deploy to TestFlight**: Archive and upload

## Development Workflow

```bash
# Run app
Cmd+R

# Clean build
Cmd+Shift+K

# Run tests
Cmd+U

# Archive for TestFlight
Product → Archive
```

## Resources

- [README.md](README.md) - Full documentation
- [supabase_schema.sql](supabase_schema.sql) - Database schema
- [Supabase Docs](https://supabase.com/docs)
- [SwiftUI Docs](https://developer.apple.com/documentation/swiftui)

## Support

Issues? Check:
1. Supabase project is running
2. API keys are correct
3. Location permissions granted
4. Dependencies resolved

---

**Ready to build! 🚀**
