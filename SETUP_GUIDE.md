# Nudge App - Complete Setup Guide

## ✅ Already Configured

- ✓ Supabase credentials in `.env`
- ✓ React Native app structure
- ✓ All dependencies installed
- ✓ Location services configured

## 🚀 Quick Start (5 minutes)

### 1. Set Up Database (2 min)

1. Go to your Supabase dashboard:
   ```
   https://supabase.com/dashboard/project/jdjmccbdxcsybolxzzrt
   ```

2. Click **SQL Editor** in the left sidebar

3. Click **New Query**

4. Copy the entire contents of `supabase_schema.sql` and paste it

5. Click **Run** to create all tables

### 2. Enable Phone Authentication (2 min)

1. In Supabase dashboard, go to **Authentication** > **Providers**

2. Enable **Phone** provider

3. For testing, you can use **"Skip SMS sending during development"**
   - Or set up Twilio for production SMS

### 3. Start the App (1 min)

```bash
cd nudge-app
npx expo start
```

Scan the QR code with:
- **iOS**: Camera app
- **Android**: Expo Go app

## 📱 What Works Now

### Without Additional Setup:
- ✓ App navigation and UI
- ✓ Onboarding flow
- ✓ Profile screens
- ✓ Swiping interface
- ✓ Chat interface
- ✓ Location services (with permission)

### With Database Setup:
- ✓ User registration
- ✓ Profile creation
- ✓ Matching algorithm
- ✓ Real-time chat
- ✓ Likes and matches
- ✓ Nudge mode

### Optional (Not Required):
- ⚪ OpenAI integration (for AI features)
- ⚪ Push notifications
- ⚪ Image uploads (needs storage bucket)

## 🔧 Current Features Status

| Feature | Status | Requires |
|---------|--------|----------|
| UI/Navigation | ✅ Working | Nothing |
| Phone Auth | ⚠️ Needs Setup | SMS provider |
| Database | ⚠️ Needs Setup | Run SQL schema |
| Location | ✅ Working | Device permission |
| Chat | ⚠️ Needs DB | Database tables |
| Matching | ⚠️ Needs DB | Database tables |
| Image Upload | ❌ Not Set Up | Supabase Storage |
| AI Features | ❌ Not Set Up | OpenAI API |

## 📖 Database Tables Created

When you run `supabase_schema.sql`, you'll get:

- `users` - User profiles
- `user_preferences` - Match preferences
- `prompts` - Profile prompts/questions
- `likes` - User likes
- `matches` - Matched pairs
- `messages` - Chat messages
- `nudges` - Proximity nudges
- `ai_profiles` - AI-generated insights

## 🎯 Testing Without Full Setup

You can test the app immediately with:

1. **UI Testing**: Navigate through all screens
2. **Location**: Enable Nudge Mode (needs device permission)
3. **Mock Data**: The app shows placeholder profiles

To test with real data, you need to:
1. Run the SQL schema
2. Enable phone auth
3. Create test users

## 🔐 Environment Variables

Already configured in `nudge-app/.env`:
```env
EXPO_PUBLIC_SUPABASE_URL=https://jdjmccbdxcsybolxzzrt.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...
```

## 🐛 Troubleshooting

### "Port 8081 is in use"
```bash
npx expo start --port 8082
```

### "Package version mismatch"
```bash
cd nudge-app
npm install
```

### "Cannot connect to Supabase"
- Check your internet connection
- Verify credentials in `.env`
- Ensure database tables are created

## 🚢 Next Steps

1. **Now**: Run the SQL schema ✅
2. **Now**: Enable phone auth ✅
3. **Now**: Test the app on your phone ✅
4. **Later**: Set up image uploads (Supabase Storage)
5. **Later**: Add OpenAI for AI matching
6. **Later**: Configure push notifications

## 📱 Quick Commands

```bash
# Start the app
cd nudge-app && npx expo start

# Clear cache and start
cd nudge-app && npx expo start --clear

# Install dependencies
cd nudge-app && npm install

# Update packages
cd nudge-app && npm update
```

---

**Ready in 5 minutes!** Just run the SQL schema and start the app! 🚀
