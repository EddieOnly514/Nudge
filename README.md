# Nudge

**Real-life attraction, intelligently amplified.**

A modern dating app built with React Native and Expo that combines elegant design with AI-powered matching and hyperlocal proximity features.

## ✨ Features

### 🎯 Regular Mode
- Swipeable dating feed with photos and prompts
- AI-powered matching based on preferences
- Proximity-based discovery
- Like/pass with instant match notifications

### 📍 Nudge Mode
- Hyperlocal proximity detection (nearby users)
- Real-time location tracking (only while active)
- Send nudges to people around you
- Anonymous discovery until mutual interest

### 💬 Chat & Messaging
- Real-time messaging with matches
- Clean, modern chat interface
- Message notifications

### 🔒 Safety & Privacy
- Phone-based authentication with OTP
- Location only shared in Nudge Mode
- Secure data handling with Supabase

## 🚀 Quick Start

### Prerequisites
- Node.js (v16+)
- Expo Go app on your phone ([iOS](https://apps.apple.com/app/apple-store/id982107779) | [Android](https://play.google.com/store/apps/details?id=host.exp.exponent))
- Supabase account

### Setup

1. **Install dependencies:**
   ```bash
   cd nudge-app
   npm install
   ```

2. **Configure Supabase:**

   Create your Supabase project and update `nudge-app/.env`:
   ```env
   EXPO_PUBLIC_SUPABASE_URL=your_supabase_url
   EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

3. **Set up database:**

   Run the SQL schema from `supabase_schema.sql` in your Supabase SQL Editor

4. **Start the app:**
   ```bash
   npx expo start
   ```

5. **Open on your phone:**
   - Scan the QR code with Expo Go app (Android) or Camera app (iOS)
   - The app will load instantly!

## 📱 Tech Stack

- **Frontend:** React Native with Expo
- **Language:** TypeScript
- **Backend:** Supabase (PostgreSQL, Auth, Realtime)
- **Navigation:** React Navigation
- **Location:** Expo Location
- **State Management:** React Hooks

## 📂 Project Structure

```
Nudge/
├── nudge-app/              # React Native app
│   ├── src/
│   │   ├── config/         # Supabase configuration
│   │   ├── navigation/     # Navigation setup
│   │   ├── screens/        # App screens
│   │   ├── services/       # Business logic
│   │   └── types/          # TypeScript types
│   ├── App.tsx
│   └── app.json
└── supabase_schema.sql     # Database schema
```

## 🎨 Key Screens

- **Welcome** - Landing and introduction
- **Phone Login** - OTP authentication
- **Onboarding** - Profile setup
- **Home** - Swipeable discovery feed
- **Nudge Mode** - Location-based nearby users
- **Matches** - Your matches and conversations
- **Chat** - Real-time messaging
- **Profile** - View and edit profile

## 🔧 Development

### Run the app
```bash
cd nudge-app
npx expo start
```

### Key Commands
- `i` - Open iOS simulator
- `a` - Open Android emulator
- `r` - Reload app
- `j` - Open debugger

### Environment Variables
Required in `nudge-app/.env`:
```env
EXPO_PUBLIC_SUPABASE_URL=your_supabase_project_url
EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

## 📖 Documentation

Full documentation available in [`nudge-app/README.md`](nudge-app/README.md)

## 🗄️ Database

The complete database schema is in [`supabase_schema.sql`](supabase_schema.sql)

Key tables:
- `users` - User profiles and preferences
- `matches` - Matched user pairs
- `messages` - Chat messages
- `likes` - User interactions
- `nudges` - Proximity-based nudges

## 🚢 Deployment

### Build for iOS
```bash
cd nudge-app
eas build --platform ios
```

### Build for Android
```bash
cd nudge-app
eas build --platform android
```

## 📝 License

MIT

---

Built with ❤️ using React Native and Expo
