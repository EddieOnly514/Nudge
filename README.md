# Nudge

**Real-life attraction, intelligently amplified.**

Nudge is a modern dating app that combines elegant Hinge-style design with AI-powered matching and hyperlocal proximity features. Users can browse profiles in Regular Mode or activate Nudge Mode for real-time connections within 20-50 meters.

## Features

### Regular Mode
- Hinge-style dating feed with photos and prompts
- AI-powered matching based on behavioral data
- Proximity intelligence (coarse location)
- Smart contextual suggestions
- Like/pass swiping with instant match notifications

### Nudge Mode
- Hyperlocal proximity detection (20-50m radius)
- Anonymous silhouette grid of nearby users
- Mutual reveal system
- Real-time location tracking (only while active)
- Building/venue context awareness

### AI Intelligence
- Behavioral affinity scoring
- Feed ranking and optimization
- Contextual suggestions
- Chat message assistance
- Safety content moderation

### Safety & Privacy
- Precise location only in Nudge Mode
- Block/report system
- AI content filtering
- No location tracking when inactive
- One-tap privacy controls

## Tech Stack

- **Frontend**: SwiftUI, iOS 16+
- **Backend**: Supabase (PostgreSQL, Auth, Realtime, Storage)
- **Location**: CoreLocation (coarse + precise)
- **AI**: OpenAI API (moderation, chat assistance)
- **Analytics**: Mixpanel/Amplitude (optional)
- **Subscriptions**: RevenueCat (optional)

## Setup Instructions

### Prerequisites

- Xcode 15.0+
- iOS 16.0+ deployment target
- Supabase account
- OpenAI API key (optional for AI features)

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/nudge.git
cd nudge
```

### 2. Set Up Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to SQL Editor and run the schema:
   ```bash
   cat supabase_schema.sql
   ```
   Copy and paste the entire contents into Supabase SQL Editor and run

3. Enable Realtime for `chat_messages`:
   - Go to Database → Replication
   - Enable realtime for `chat_messages` table

4. Set up Storage bucket for photos:
   - Go to Storage
   - Create a new public bucket named `profile-photos`

5. Get your credentials:
   - Go to Settings → API
   - Copy the Project URL and anon/public key

### 3. Configure the App

Update `NudgeApp/NudgeApp/Config/SupabaseConfig.swift`:

```swift
import Foundation

struct SupabaseConfig {
    static let url = "YOUR_SUPABASE_PROJECT_URL"
    static let anonKey = "YOUR_SUPABASE_ANON_KEY"
    static let openAIKey = "YOUR_OPENAI_API_KEY"
}
```

⚠️ **Important**: This file is gitignored to protect your API keys.

### 4. Install Dependencies

The project uses Swift Package Manager. Dependencies will be automatically resolved when you open the project in Xcode.

Required packages:
- Supabase Swift (`https://github.com/supabase/supabase-swift.git`)

### 5. Build and Run

1. Open `NudgeApp/NudgeApp.xcodeproj` in Xcode
2. Select your team for code signing
3. Select a simulator or device
4. Press Cmd+R to build and run
5. Grant location permissions when prompted

## Project Structure

```
NudgeApp/
├── NudgeApp/
│   ├── NudgeApp.swift          # Main app entry
│   ├── ContentView.swift        # Root navigation
│   ├── Models/                  # Data models
│   │   ├── User.swift
│   │   ├── Nudge.swift
│   │   ├── Match.swift
│   │   ├── ChatMessage.swift
│   │   └── AIProfile.swift
│   ├── Views/                   # UI components
│   │   ├── Onboarding/
│   │   ├── Home/
│   │   ├── NudgeMode/
│   │   ├── Chat/
│   │   └── Profile/
│   ├── Services/                # Business logic
│   │   ├── SupabaseClient.swift
│   │   ├── AuthService.swift
│   │   ├── LocationService.swift
│   │   ├── MatchingService.swift
│   │   ├── AIService.swift
│   │   ├── NudgeModeService.swift
│   │   └── ChatService.swift
│   ├── Utils/
│   │   └── DesignSystem.swift   # Hinge-style design system
│   ├── Config/
│   │   └── SupabaseConfig.swift # API keys (gitignored)
│   └── Info.plist
└── supabase_schema.sql          # Database schema
```

## Key Implementation Details

### Authentication Flow
1. Welcome screen → Phone login
2. SMS OTP verification via Supabase Auth
3. Onboarding: Photos → Prompts → Preferences → Location
4. Profile creation and AI profile initialization

### Location Strategy
- **Regular Mode**: Coarse location (100-400m accuracy)
- **Nudge Mode**: Precise location (10-50m accuracy)
- Location permissions are clearly gated and explained
- Precise location only used while Nudge Mode is active

### Matching Algorithm
```
1. Fetch users matching preferences (age, gender, distance)
2. Exclude already-liked/passed users
3. Calculate AI affinity score for each:
   - Historical match probability (40%)
   - Proximity score (30%)
   - Frequent location overlap (20%)
   - Activity recency (10%)
4. Rank feed by affinity score
5. Present top matches to user
```

### Nudge Mode Flow
```
1. User taps "Nudge Mode" button
2. Request precise location permission
3. Enable precise location tracking
4. Add user to ephemeral active_users table
5. Poll for nearby users every 5s
6. Display anonymous silhouette grid
7. User sends nudge → check for mutual
8. Mutual nudge → reveal + create match
9. Exit → disable precise location, remove from active_users
```

## Database Schema

Main tables:

- **users**: Profile data, preferences, approximate location
- **matches**: Regular and Nudge Mode matches
- **likes/passes**: User interaction history
- **chat_messages**: Realtime messaging (Supabase Realtime enabled)
- **nudges**: Nudge Mode interactions
- **nudge_mode_active_users**: Ephemeral active sessions
- **ai_profiles**: Affinity vectors and behavioral data
- **user_interactions**: AI learning dataset

See [supabase_schema.sql](supabase_schema.sql) for complete schema with indexes and RLS policies.

## Design System

Following Hinge's clean, elegant aesthetic:

**Colors**
- White: `#FFFFFF`
- Black: `#000000`
- Soft Gray: `#F5F5F5`
- Medium Gray: `#4F4F4F`
- Accent Blue: `#2B7FFF`
- Light Blue Background: `#EAF4FF`

**Typography**
- Headers: Playfair Display (serif)
- Body: SF Pro / Inter (sans-serif)
- Buttons: Semi-bold sans-serif

**Spacing**
- Horizontal padding: 24px
- Module spacing: 32px
- Inline spacing: 16px

## Privacy & Security

### Implemented
✅ Precise location only in Nudge Mode
✅ Ephemeral location data (not stored)
✅ Row-level security on all tables
✅ API keys gitignored
✅ AI content moderation
✅ Block/report functionality

### Recommended for Production
- Photo verification system
- Admin moderation dashboard
- Rate limiting on nudges/messages
- Abuse detection ML
- GDPR compliance tools
- Campus email (.edu) verification

## Deployment

### TestFlight
1. Archive app in Xcode
2. Upload to App Store Connect
3. Add testers
4. Distribute

### App Store Submission
- Prepare screenshots and app preview
- Write compelling description
- Address Apple's privacy requirements
- Plan for location permission review
- Consider age verification for dating apps

## Roadmap

**MVP (6 weeks)** ✓
- Auth, profiles, onboarding
- Regular Mode feed
- Matching system
- Chat with realtime
- Nudge Mode
- AI ranking
- Basic safety features

**V1.1**
- Photo verification
- Push notifications
- Enhanced AI suggestions
- Analytics integration
- Video prompts

**V1.2**
- Events integration
- Premium subscriptions
- Read receipts
- Group Nudge Mode
- Match expiration

## License

Proprietary - All rights reserved.

---

**Built for real connections, powered by intelligence.**