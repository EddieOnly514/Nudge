# ⚡ Quick Start Checklist - Do These Now!

## 🚀 5-Minute Backend Setup

### ☑️ Step 1: Database (2 minutes)
```
1. Open: https://supabase.com/dashboard/project/jdjmccbdxcsybolxzzrt
2. Click: SQL Editor
3. Copy ALL of supabase_schema.sql
4. Paste and RUN
✅ Done when you see 8+ tables in Table Editor
```

### ☑️ Step 2: Phone Auth (1 minute)
```
1. Go to: Authentication > Providers
2. Toggle ON: Phone
3. Enable: "Disable confirmations during development"
4. Save
✅ Done when Phone shows as enabled
```

### ☑️ Step 3: Storage (1 minute)
```
1. Go to: Storage
2. New Bucket: "profile-photos"
3. Toggle: Public ON
4. Create
✅ Done when bucket exists
```

### ☑️ Step 4: Realtime (1 minute)
```
1. Go to: Database > Replication
2. Enable Realtime for:
   - messages ✓
   - matches ✓
   - nudges ✓
3. Save
✅ Done when tables show "Realtime enabled"
```

---

## 🧪 Test the App

```bash
cd nudge-app
npx expo start
```

Scan QR code with Expo Go app!

---

## ✅ What's Ready Now

| Feature | Status |
|---------|--------|
| Supabase Connection | ✅ Connected |
| Database Tables | ⏳ Run SQL |
| Phone Auth | ⏳ Enable |
| Photo Storage | ⏳ Create bucket |
| Realtime Chat | ⏳ Enable replication |
| Location Services | ✅ Ready |
| All App Code | ✅ Ready |

---

## 📱 Testing Order

1. ✅ Sign up with phone (any number + OTP: 123456)
2. ✅ Complete onboarding
3. ✅ Browse profiles
4. ✅ Like someone
5. ✅ Test chat
6. ✅ Enable Nudge Mode
7. ✅ Upload photo

---

## 🆘 If Something Breaks

**Can't login?**
- Check phone auth is enabled
- Use OTP: 123456

**No profiles showing?**
- Create test users (see BACKEND_SETUP_COMPLETE.md Step 9)

**Chat not working?**
- Enable Realtime for messages table

**Can't upload photo?**
- Create profile-photos bucket
- Make it public

---

## 📖 Full Guide

See [BACKEND_SETUP_COMPLETE.md](BACKEND_SETUP_COMPLETE.md) for:
- Detailed setup instructions
- SQL queries for testing
- Troubleshooting guide
- Complete feature list

---

**Time to complete: 5 minutes ⏱️**

**Start here:** Step 1 above ☝️
