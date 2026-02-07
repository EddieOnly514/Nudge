# Nudge - React Native Dating App

A modern dating app built with React Native and Expo, featuring location-based matching and AI-powered profiles.

## Features

- 📱 **Phone Authentication**: Secure sign-in with OTP
- 🎯 **Smart Matching**: Swipe through potential matches
- 📍 **Nudge Mode**: Discover people nearby in real-time
- 💬 **Real-time Chat**: Message your matches instantly
- 👤 **Profile Management**: Create and customize your profile
- 🤖 **AI Integration**: Smart matching and conversation starters

## Tech Stack

- **React Native** with Expo
- **TypeScript** for type safety
- **Supabase** for backend (authentication, database, real-time)
- **React Navigation** for routing
- **Expo Location** for location services
- **Expo Image Picker** for photo uploads

## Setup

### Prerequisites

- Node.js (v16 or higher)
- Expo CLI
- iOS Simulator (Mac only) or Android Emulator
- Supabase account

### Installation

1. Install dependencies:
   ```bash
   npm install
   ```

2. Set up environment variables:
   - Copy `.env.example` to `.env`
   - Add your Supabase credentials:
     ```
     EXPO_PUBLIC_SUPABASE_URL=your_supabase_url
     EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
     ```

3. Start the development server:
   ```bash
   npx expo start
   ```

4. Run on your device:
   - Download **Expo Go** app on your iOS/Android device
   - Scan the QR code from the terminal
   - Or press `i` for iOS simulator, `a` for Android emulator

## Project Structure

```
nudge-app/
├── src/
│   ├── config/          # Configuration files (Supabase)
│   ├── navigation/      # Navigation setup
│   ├── screens/         # App screens
│   │   ├── auth/        # Authentication screens
│   │   ├── main/        # Main app screens
│   │   └── onboarding/  # Onboarding flow
│   ├── services/        # API and business logic
│   ├── types/           # TypeScript types
│   └── utils/           # Utility functions
├── App.tsx              # Root component
└── app.json             # Expo configuration
```

## Available Screens

### Authentication
- **Welcome Screen**: Landing page with app introduction
- **Phone Login**: OTP-based authentication

### Main App
- **Home**: Swipe through potential matches
- **Nudge Mode**: Activate to see people nearby
- **Matches**: View and chat with your matches
- **Chat**: Real-time messaging
- **Profile**: View and edit your profile

### Onboarding
- Profile setup flow for new users

## Key Services

### AuthService
Handles user authentication with Supabase:
- Phone OTP sign-in
- Session management
- Sign out

### LocationService
Manages location features:
- Request permissions
- Get current location
- Watch location updates
- Calculate distances

### MatchingService
Handles matching logic:
- Get potential matches
- Like/pass users
- Create matches
- Retrieve user matches

### ChatService
Manages real-time messaging:
- Send messages
- Load chat history
- Subscribe to new messages

## Database Schema

Refer to `../supabase_schema.sql` for the complete database structure.

### Main Tables
- `users`: User profiles
- `matches`: Matched user pairs
- `likes`: User likes
- `messages`: Chat messages
- `nudges`: Nudge interactions

## Running with Expo Go

1. Install **Expo Go** on your phone:
   - [iOS App Store](https://apps.apple.com/app/apple-store/id982107779)
   - [Google Play Store](https://play.google.com/store/apps/details?id=host.exp.exponent)

2. Start the dev server:
   ```bash
   npx expo start
   ```

3. Scan the QR code:
   - **iOS**: Use the Camera app
   - **Android**: Use the Expo Go app

4. The app will load on your device!

## Development Tips

- **Hot Reload**: Shake your device and select "Reload" to see changes
- **Debug Menu**: Shake device to open debug menu
- **Console Logs**: Run `npx expo start` and press `j` to open debugger

## Deployment

### iOS
```bash
eas build --platform ios
```

### Android
```bash
eas build --platform android
```

## Environment Variables

Required environment variables in `.env`:

```env
EXPO_PUBLIC_SUPABASE_URL=your_supabase_project_url
EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Troubleshooting

### Location Permissions
Make sure location permissions are enabled in your device settings.

### Supabase Connection
Verify your Supabase URL and API keys are correct in the `.env` file.

### Build Issues
Try clearing the cache:
```bash
npx expo start -c
```

## License

MIT
