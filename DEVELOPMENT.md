# Nudge - Development Guide

Technical implementation details for developers.

## Architecture Overview

Nudge follows a clean architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│              Views (SwiftUI)            │
│  Onboarding, Home, Nudge, Chat, Profile │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          ViewModels / Services          │
│  Auth, Location, Matching, AI, Nudge   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           Supabase Client               │
│   Auth, Database, Realtime, Storage     │
└─────────────────────────────────────────┘
```

## Core Services

### AuthService

Manages user authentication and session state.

**Key Methods:**
- `checkAuthStatus()` - Verifies existing session
- `sendOTP(phoneNumber:)` - SMS authentication
- `verifyOTP(phoneNumber:code:)` - Code verification
- `createUserProfile(...)` - New user onboarding
- `updateUserLocation(coordinate:)` - Location updates

**State:**
- `@Published var currentUser: User?`
- `@Published var isAuthenticated: Bool`

**Usage:**
```swift
@EnvironmentObject var authService: AuthService

Task {
    try await authService.sendOTP(phoneNumber: "+1234567890")
}
```

### LocationService

Handles both coarse and precise location tracking.

**Modes:**
- **Coarse** (Regular Mode): 100-400m accuracy, updates every 100m
- **Precise** (Nudge Mode): 10-50m accuracy, updates every 10m

**Key Methods:**
- `startCoarseLocationUpdates()` - For Regular Mode
- `enterNudgeMode()` - Enables precise location
- `exitNudgeMode()` - Disables precise location
- `distance(from:)` - Calculate distance to coordinate
- `getVenueName(for:)` - Reverse geocoding

**Usage:**
```swift
locationService.enterNudgeMode()

// Calculate distance
if let distance = locationService.distance(from: userCoordinate) {
    print("Distance: \(distance)m")
}
```

### MatchingService

Core matching logic and feed generation.

**Algorithm:**
```swift
1. Fetch users matching preferences
   - Age: minAge...maxAge
   - Gender: in interestedIn[]
   - Distance: ≤ maxDistance

2. Filter out interacted users
   - Check likes table
   - Check passes table

3. AI affinity ranking
   - Historical probability: 40%
   - Proximity score: 30%
   - Location overlap: 20%
   - Recency: 10%

4. Return ranked feed
```

**Key Methods:**
- `fetchFeed()` - Generate user feed
- `likeUser(_:)` - Like and check for match
- `passUser(_:)` - Pass on user
- `fetchMatches()` - Get existing matches

**Match Detection:**
```swift
// Check for mutual like
let reciprocalLike = try await supabase.database
    .from("likes")
    .select()
    .eq("user_id", value: targetUser.id)
    .eq("liked_user_id", value: currentUser.id)
    .execute()

if !reciprocalLike.isEmpty {
    // Create match!
}
```

### AIService

Machine learning and intelligent features.

**Affinity Scoring:**
```swift
func calculateAffinityScore(
    currentUser: User,
    targetUser: User,
    aiProfile: AIProfile
) -> Double {
    var score = 0.0

    // Historical match probability
    if let prob = aiProfile.matchProbabilityMap[targetUser.id] {
        score += prob * 0.4
    }

    // Proximity bonus
    let proximity = calculateProximityScore(distance)
    score += proximity * 0.3

    // Location overlap
    if hasFrequentLocationOverlap {
        score += 0.2
    }

    // Recency
    if isActiveRecently {
        score += 0.1
    }

    return score
}
```

**Interaction Tracking:**
Every user action is tracked:
- `viewed` - User appeared in feed
- `liked` - User liked profile
- `passed` - User passed
- `matched` - Mutual match created
- `messaged` - Sent message

**Match Probability Update:**
```swift
// Simplified ML model
liked → +0.2 probability
matched → 0.9 probability
messaged → +0.1 probability
passed → -0.3 probability
```

### NudgeModeService

Hyperlocal proximity matching.

**Flow:**
```
1. activateNudgeMode()
   → Enable precise location
   → Insert into nudge_mode_active_users
   → Start polling timer (5s interval)

2. Poll for nearby users
   → Fetch from nudge_mode_active_users
   → Filter by radius (20-50m)
   → Filter by preferences
   → Display as anonymous silhouettes

3. sendNudge(to:)
   → Create nudge record
   → Check for reciprocal nudge
   → If mutual: create match + reveal

4. deactivateNudgeMode()
   → Stop polling
   → Remove from active_users
   → Disable precise location
```

**Ephemeral Data:**
- `nudge_mode_active_users` cleaned up after 1 hour
- `nudges` without matches deleted after 24 hours

**Privacy:**
- No GPS coordinates stored permanently
- Only distance shown, not exact location
- Users invisible when inactive

### ChatService

Realtime messaging with Supabase Realtime.

**Setup:**
```swift
func subscribeToConversation(_ id: String) {
    channel = supabase.realtime.channel("messages:\(id)")

    channel?.on(.insert) { [weak self] message in
        self?.handleNewMessage(message)
    }

    channel?.subscribe()
}
```

**Message Flow:**
```
1. User types message
2. AI moderation check
3. Insert into chat_messages
4. Supabase broadcasts to channel
5. Recipient receives via Realtime
6. Update UI
```

**AI Features:**
- Message suggestions
- Conversation starters
- Smart replies
- Icebreaker prompts

## Data Models

### User
```swift
struct User {
    let id: String
    var name: String
    var age: Int
    var gender: String
    var bio: String
    var photos: [String]
    var preferences: UserPreferences
    var approximateLocation: CLLocationCoordinate2D?
    var lastActive: Date
    var prompts: [Prompt]
}
```

### Match
```swift
struct Match {
    let id: String
    let user1Id: String
    let user2Id: String
    let createdAt: Date
    let expiredAt: Date?
    var matchType: MatchType // .regular or .nudge
}
```

### Nudge
```swift
struct Nudge {
    let id: String
    let senderId: String
    let receiverId: String
    let timestamp: Date
    let locationContext: LocationContext?
    var isRevealed: Bool
}
```

## Database Design

### Performance Indexes
```sql
-- Location queries
CREATE INDEX idx_users_location
    ON users USING GIST (approximate_location);

-- Feed generation
CREATE INDEX idx_users_age ON users(age);
CREATE INDEX idx_users_gender ON users(gender);

-- Nudge Mode
CREATE INDEX idx_nudge_active_location
    ON nudge_mode_active_users USING GIST (location);
```

### Row-Level Security

All tables have RLS enabled:

```sql
-- Users can view other users
CREATE POLICY "Users can view other users"
    ON users FOR SELECT
    USING (true);

-- Users can only update their own profile
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);
```

## Design Patterns

### Singleton Services
All services use the singleton pattern for shared state:

```swift
class AuthService: ObservableObject {
    static let shared = AuthService()
    private init() {}
}
```

### Environment Objects
Services injected via SwiftUI environment:

```swift
@main
struct NudgeApp: App {
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}
```

### Async/Await
All network calls use modern Swift concurrency:

```swift
func fetchFeed() async {
    do {
        let users: [User] = try await supabase.database
            .from("users")
            .select()
            .execute()
            .value
    } catch {
        print("Error: \(error)")
    }
}
```

## Error Handling

### Network Errors
```swift
do {
    try await someNetworkCall()
} catch {
    // Log to analytics
    // Show user-friendly error
    errorMessage = "Something went wrong. Please try again."
}
```

### Location Errors
```swift
func locationManager(_ manager: CLLocationManager,
                     didFailWithError error: Error) {
    print("Location error: \(error)")
    // Fallback to last known location
}
```

## Testing

### Unit Tests
Test services in isolation:

```swift
class MatchingServiceTests: XCTestCase {
    func testAffinityScoring() {
        let service = MatchingService.shared
        let score = service.calculateAffinity(...)
        XCTAssertGreaterThan(score, 0.5)
    }
}
```

### Integration Tests
Test full flows:

```swift
func testMatchFlow() async {
    // Like user
    try await matchingService.likeUser(testUser)

    // Other user likes back
    try await matchingService.likeUser(currentUser)

    // Verify match created
    XCTAssertTrue(matchingService.matches.count > 0)
}
```

### UI Tests
Test user flows:

```swift
func testOnboarding() {
    let app = XCUIApplication()
    app.launch()

    app.buttons["Get Started"].tap()
    // ... test full flow
}
```

## Performance Optimization

### Feed Loading
- Limit to 50 users per fetch
- Paginate if needed
- Cache AI affinity scores

### Location Updates
- Debounce location updates
- Only update DB when significant movement (100m+)
- Use geohashing for proximity queries

### Realtime Scaling
- Subscribe only to active conversations
- Unsubscribe when leaving chat
- Batch message updates

### Image Loading
- Lazy load images in feed
- Cache with URLCache
- Compress uploads to Supabase Storage

## Security Checklist

- [ ] API keys in gitignored config
- [ ] Row-level security on all tables
- [ ] Location data ephemeral
- [ ] Messages moderated
- [ ] Rate limiting on nudges
- [ ] HTTPS only
- [ ] No SQL injection (using Supabase client)

## Deployment Checklist

- [ ] Update version in Info.plist
- [ ] Archive for distribution
- [ ] Run tests
- [ ] Check crash logs
- [ ] Update App Store metadata
- [ ] Submit for review
- [ ] Monitor analytics post-launch

## Future Improvements

### V1.1
- Photo verification with ML
- Push notifications
- Background location (with care)
- Enhanced AI suggestions

### V1.2
- Video prompts
- Voice messages
- Read receipts
- Match expiration

### Infrastructure
- Move AI scoring to backend
- Add Redis caching
- Implement CDN for photos
- Add job queue for heavy tasks

---

**Happy coding! 🎉**
