# Complete Backend Setup - Step by Step

Follow these steps in order to ensure ALL functionality works properly.

---

## ✅ STEP 1: Database Tables Setup

### 1.1 Run the SQL Schema

1. Go to: https://supabase.com/dashboard/project/jdjmccbdxcsybolxzzrt
2. Click **SQL Editor** (left sidebar)
3. Click **New Query**
4. Open `supabase_schema.sql` and copy ALL contents
5. Paste into Supabase SQL Editor
6. Click **RUN** (or press Cmd/Ctrl + Enter)

**Verify:** Go to **Table Editor** - you should see these tables:
- ✓ users
- ✓ user_preferences
- ✓ prompts
- ✓ likes
- ✓ passes
- ✓ matches
- ✓ messages
- ✓ nudges
- ✓ ai_profiles

---

## ✅ STEP 2: Enable Row Level Security (RLS)

The SQL schema should have created RLS policies. Verify:

1. Go to **Authentication** > **Policies**
2. You should see policies for each table
3. If not, run this SQL:

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE nudges ENABLE ROW LEVEL SECURITY;

-- Users can read their own data
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Users can read other users (for matching)
CREATE POLICY "Users can view all profiles" ON users
    FOR SELECT USING (true);

-- Likes policies
CREATE POLICY "Users can create likes" ON likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own likes" ON likes
    FOR SELECT USING (auth.uid() = user_id);

-- Matches policies
CREATE POLICY "Users can view their matches" ON matches
    FOR SELECT USING (auth.uid() = user_1 OR auth.uid() = user_2);

-- Messages policies
CREATE POLICY "Users can view messages in their matches" ON messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM matches
            WHERE id = match_id
            AND (user_1 = auth.uid() OR user_2 = auth.uid())
        )
    );

CREATE POLICY "Users can create messages in their matches" ON messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM matches
            WHERE id = match_id
            AND (user_1 = auth.uid() OR user_2 = auth.uid())
        )
    );

-- Nudges policies
CREATE POLICY "Users can create nudges" ON nudges
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can view nudges sent to them" ON nudges
    FOR SELECT USING (auth.uid() = receiver_id OR auth.uid() = sender_id);
```

**Verify:** Check that each table shows green checkmarks for RLS in **Table Editor**

---

## ✅ STEP 3: Phone Authentication Setup

### 3.1 Enable Phone Provider

1. Go to **Authentication** > **Providers**
2. Find **Phone** and toggle it ON
3. Enable these settings:
   - ✓ **Enable Phone Signup**
   - ✓ **Enable Phone Confirmations**

### 3.2 Configure for Development (RECOMMENDED FOR NOW)

1. In Supabase, go to **Authentication** > **Settings**
2. Scroll to **Auth Providers** > **Phone**
3. Under **Advanced Settings**:
   - Enable **"Disable email confirmations during development"**
   - This allows testing without real SMS
4. **Save**

**For Testing:** Use any phone number format and OTP code "123456" will work

### 3.3 Production Setup (Do This Later)

When ready for production, set up Twilio:
1. Create account at https://www.twilio.com
2. Get Account SID, Auth Token, Phone Number
3. In Supabase Phone settings, select **Twilio** and enter credentials

**Verify:** Try the phone login flow in your app

---

## ✅ STEP 4: Storage for Profile Photos

### 4.1 Create Storage Bucket

1. Go to **Storage** (left sidebar)
2. Click **New Bucket**
3. Name: `profile-photos`
4. Toggle **Public bucket** ON
5. Click **Create Bucket**

### 4.2 Set Up Storage Policies

1. Click on `profile-photos` bucket
2. Click **Policies** tab
3. Click **New Policy**
4. Create these 4 policies:

**Policy 1: Upload**
```sql
CREATE POLICY "Users can upload profile photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'profile-photos');
```

**Policy 2: View**
```sql
CREATE POLICY "Public can view photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-photos');
```

**Policy 3: Update**
```sql
CREATE POLICY "Users can update their photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'profile-photos');
```

**Policy 4: Delete**
```sql
CREATE POLICY "Users can delete their photos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'profile-photos');
```

**Verify:** Try uploading a test image through the Storage UI

---

## ✅ STEP 5: Enable Real-time Subscriptions

### 5.1 Enable Realtime for Tables

1. Go to **Database** > **Replication**
2. Find these tables and toggle **Realtime** ON:
   - ✓ **messages** (CRITICAL for chat)
   - ✓ **matches** (for instant match notifications)
   - ✓ **nudges** (for proximity notifications)
   - ✓ **likes** (optional, for instant feedback)

3. Click **Save**

**Verify:** Each enabled table should show "Realtime enabled" status

---

## ✅ STEP 6: Test Database Connection

### 6.1 Run Test Query

In SQL Editor, run this to verify everything works:

```sql
-- Test 1: Check tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Test 2: Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';

-- Test 3: Check policies exist
SELECT tablename, policyname
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename;
```

**Expected Results:**
- Test 1: Should show all 8+ tables
- Test 2: All tables should have `rowsecurity = true`
- Test 3: Should show multiple policies per table

---

## ✅ STEP 7: Verify App Services

I've created these new service files with full backend integration:

### 7.1 Services Created

✓ `src/services/authService.ts` - Phone auth
✓ `src/services/userService.ts` - User CRUD operations
✓ `src/services/matchingService.ts` - Likes and matches
✓ `src/services/chatService.ts` - Real-time messaging
✓ `src/services/locationService.ts` - Location tracking
✓ `src/services/nudgeService.ts` - Proximity nudges
✓ `src/services/storageService.ts` - Image uploads (NEW!)

### 7.2 Service Exports

Update the services index file:

---

## ✅ STEP 8: Test Each Feature End-to-End

### 8.1 Test Authentication

**Test Steps:**
1. Open app in Expo Go
2. Click "Get Started"
3. Enter phone number (any format)
4. Enter OTP: `123456`
5. Should navigate to onboarding

**Expected:** User authenticated, session created

**SQL to verify:**
```sql
SELECT * FROM auth.users ORDER BY created_at DESC LIMIT 5;
```

---

### 8.2 Test User Creation

**Test Steps:**
1. Complete onboarding flow
2. Enter name, age, gender, bio
3. Finish onboarding

**SQL to verify:**
```sql
-- Check user created
SELECT id, name, age, gender FROM users ORDER BY created_at DESC LIMIT 1;

-- Check preferences created
SELECT * FROM user_preferences ORDER BY created_at DESC LIMIT 1;
```

---

### 8.3 Test Photo Upload

**Test Steps:**
1. Go to Profile screen
2. Tap "Edit Profile"
3. Tap photo to upload
4. Select image
5. Upload

**SQL to verify:**
```sql
-- Check photos array updated
SELECT id, name, photos FROM users WHERE id = 'your-user-id';
```

**Storage verify:**
- Go to Storage > profile-photos
- Should see uploaded image

---

### 8.4 Test Matching Flow

**Test Steps:**
1. Go to Home screen
2. Like a profile
3. Create second test user
4. Have second user like first user back
5. Check for match notification

**SQL to verify:**
```sql
-- Check likes created
SELECT * FROM likes ORDER BY timestamp DESC LIMIT 5;

-- Check match created (when mutual)
SELECT * FROM matches ORDER BY created_at DESC LIMIT 5;
```

---

### 8.5 Test Real-time Chat

**Test Steps:**
1. Open chat with a match
2. Send message
3. Open same chat on another device/user
4. Should see message appear in real-time

**SQL to verify:**
```sql
-- Check messages
SELECT m.*, u.name as sender_name
FROM messages m
JOIN users u ON m.sender_id = u.id
ORDER BY m.timestamp DESC
LIMIT 10;
```

---

### 8.6 Test Nudge Mode

**Test Steps:**
1. Enable location permissions
2. Activate Nudge Mode
3. Location should be updated in database
4. Should see nearby users (if any)

**SQL to verify:**
```sql
-- Check location updated
SELECT id, name, approximate_location, last_active 
FROM users 
WHERE approximate_location IS NOT NULL
ORDER BY last_active DESC;

-- Check nudges sent
SELECT * FROM nudges ORDER BY timestamp DESC LIMIT 5;
```

---

### 8.7 Test Real-time Subscriptions

**Test Steps:**
1. Open app on Device A (User 1)
2. Open app on Device B (User 2)
3. Have User 2 send message to User 1
4. User 1 should receive message instantly

**Expected:** Message appears without refresh

---

## ✅ STEP 9: Create Test Data (Optional)

Run this SQL to create test users for development:

```sql
-- Create test user 1
INSERT INTO users (id, name, age, gender, bio, photos)
VALUES (
  'test-user-1-uuid',
  'Sarah',
  25,
  'woman',
  'Coffee lover and hiking enthusiast',
  ARRAY['https://via.placeholder.com/400']
);

-- Create test user 2
INSERT INTO users (id, name, age, gender, bio, photos)
VALUES (
  'test-user-2-uuid',
  'Emma',
  27,
  'woman',
  'Artist and dog mom',
  ARRAY['https://via.placeholder.com/400']
);

-- Create test match
INSERT INTO matches (user_1, user_2, match_type)
VALUES (
  'test-user-1-uuid',
  'your-real-user-id',
  'regular'
);

-- Create test messages
INSERT INTO messages (match_id, sender_id, text)
VALUES (
  'match-id-here',
  'test-user-1-uuid',
  'Hey! How are you?'
);
```

---

## ✅ STEP 10: Verify Everything Works

### Final Checklist

Run through this complete flow:

- [ ] **Sign up** with phone number
- [ ] **Create profile** with photos and bio
- [ ] **See discovery feed** with potential matches
- [ ] **Like a profile**
- [ ] **Get matched** (simulate by liking back)
- [ ] **Send a message** in chat
- [ ] **Receive message** in real-time
- [ ] **Enable Nudge Mode**
- [ ] **Update location**
- [ ] **Send a nudge**
- [ ] **Upload/change profile photo**
- [ ] **Edit profile** information
- [ ] **View matches** list
- [ ] **Sign out and sign back in**

---

## 🔧 Troubleshooting

### Issue: "User not authenticated"
**Fix:** Check auth session:
```sql
SELECT * FROM auth.users WHERE id = 'your-user-id';
```

### Issue: "Permission denied for table"
**Fix:** Check RLS policies are enabled and correct

### Issue: "Cannot upload image"
**Fix:** 
1. Check Storage bucket exists
2. Verify storage policies
3. Check bucket is public

### Issue: "Real-time not working"
**Fix:**
1. Verify Realtime enabled on table
2. Check subscription code in app
3. Test in SQL Editor:
```sql
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
```

### Issue: "Phone OTP not working"
**Fix:**
1. For dev: Use OTP "123456"
2. For prod: Check Twilio credentials
3. Verify phone provider enabled

---

## 📊 Monitoring & Debugging

### Check Recent Activity

```sql
-- Recent signups
SELECT id, email, phone, created_at 
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 10;

-- Recent matches
SELECT m.*, u1.name as user1_name, u2.name as user2_name
FROM matches m
JOIN users u1 ON m.user_1 = u1.id
JOIN users u2 ON m.user_2 = u2.id
ORDER BY m.created_at DESC
LIMIT 10;

-- Recent messages
SELECT m.text, u.name as sender, m.timestamp
FROM messages m
JOIN users u ON m.sender_id = u.id
ORDER BY m.timestamp DESC
LIMIT 20;

-- Active users
SELECT id, name, last_active
FROM users
WHERE last_active > NOW() - INTERVAL '1 hour'
ORDER BY last_active DESC;
```

---

## ✅ All Backend Features Status

| Feature | Backend Ready | App Ready | Tested |
|---------|---------------|-----------|--------|
| Database Tables | ✅ | ✅ | ⬜ |
| Authentication | ✅ | ✅ | ⬜ |
| User Profiles | ✅ | ✅ | ⬜ |
| Photo Upload | ✅ | ✅ | ⬜ |
| Matching Logic | ✅ | ✅ | ⬜ |
| Real-time Chat | ✅ | ✅ | ⬜ |
| Location Services | ✅ | ✅ | ⬜ |
| Nudge Mode | ✅ | ✅ | ⬜ |
| Row Level Security | ✅ | ✅ | ⬜ |

---

## 🎯 Summary

**What you've set up:**
1. ✅ Complete database schema with 8+ tables
2. ✅ Row Level Security on all tables
3. ✅ Phone authentication (dev mode)
4. ✅ Image storage with policies
5. ✅ Real-time subscriptions for chat
6. ✅ All app services connected to backend
7. ✅ Location tracking
8. ✅ Matching algorithm
9. ✅ Chat system
10. ✅ Nudge proximity features

**Next: Start testing!**

```bash
cd nudge-app
npx expo start
```

Scan QR code and test each feature! ✨
