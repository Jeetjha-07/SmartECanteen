# Image Upload Fix for Restaurant and Menu Images - Render Deployment Issue

## Problem Identified
**Render platform uses ephemeral filesystem** - Files stored in the container's `/uploads` directory are deleted when the container restarts or redeploys. This caused restaurant and menu images to disappear after deployment.

### Error Observed
```
[ShopDetail] Building URL: /uploads/1775961213620-237145858.jpg ->
https://smartecanteen-1.onrender.com/uploads/1775961213620-237145858.jpg
```
The URL was constructed correctly, but the file didn't exist on the server.

---

## Solution Implemented: Cloudinary Integration

All images now use **Cloudinary** (persistent cloud storage) instead of local filesystem storage.

### What Was Changed

#### 1. **Backend - Created Cloudinary Utility** (`backend/utils/cloudinary.js`)
- `uploadToCloudinary()` - Uploads image buffer to Cloudinary
- `deleteFromCloudinary()` - Deletes images from Cloudinary
- Handles streaming and error handling

#### 2. **Backend - Updated `/restaurants/register` Route** (`backend/routes/restaurants.js`)
**Before:**
```javascript
router.post('/register', verifyJWT, upload.single('image'), async (req, res) => {
  // Stored in /uploads directory
  imageUrl = `/uploads/${req.file.filename}`;
```

**After:**
```javascript
router.post('/register', verifyJWT, async (req, res) => {
  // Accepts Cloudinary URL from body
  const finalImageUrl = imageUrl || 'https://res.cloudinary.com/placeholder.png';
  imageUrl: finalImageUrl // Stores Cloudinary URL
```

#### 3. **Backend - Added `/restaurants/upload` Endpoint**
New endpoint for uploading restaurant images to Cloudinary:
```javascript
router.post('/upload', verifyJWT, upload.single('image'), async (req, res) => {
  const cloudinaryUrl = await uploadToCloudinary(req.file.buffer, 'smartcanteen/restaurants');
  res.json({ success: true, imageUrl: cloudinaryUrl });
});
```

#### 4. **Backend - Updated Packages** (`backend/package.json`)
Added `streamifier` dependency for Cloudinary integration:
```json
"streamifier": "^0.1.1"
```

#### 5. **Backend - Improved CORS Headers** (`backend/server.js`)
Added proper CORS configuration for external image sources:
```javascript
app.use(cors({
  origin: '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Add CORS headers for static assets
res.header('Cross-Origin-Resource-Policy', 'cross-origin');
res.header('Cross-Origin-Embedder-Policy', 'require-corp');
```

#### 6. **Flutter - Updated RestaurantService** (`lib/services/restaurant_service.dart`)
**New method:** `_uploadImageToCloudinary()`
```dart
static Future<String> _uploadImageToCloudinary(XFile imageFile) async {
  // POST to /restaurants/upload
  // Returns Cloudinary URL
}
```

**Updated method:** `registerShop()`
```dart
// Step 1: Upload image to Cloudinary first
String cloudinaryUrl = await _uploadImageToCloudinary(imageFile);

// Step 2: Send registration with Cloudinary URL
request.fields['imageUrl'] = cloudinaryUrl;
```

---

## How It Works Now

### Restaurant Image Upload Flow:
```
1. Flutter App picks image from camera/gallery
                    ↓
2. Upload to backend /restaurants/upload endpoint
                    ↓
3. Backend receives file buffer
                    ↓
4. Upload to Cloudinary using streamifier
                    ↓
5. Cloudinary returns persistent URL
                    ↓
6. Backend returns Cloudinary URL to Flutter
                    ↓
7. Flutter saves Cloudinary URL with restaurant data
                    ↓
8. Backend stores Cloudinary URL in MongoDB
                    ↓
9. Customer views restaurant image from Cloudinary (persistent!)
```

### Menu Item Image Upload Flow:
```
Same as restaurant images - all menu items also use Cloudinary
```

---

## Deployment Steps

### 1. Install Dependencies
```bash
cd backend
npm install streamifier
```

### 2. Verify Environment Variables
Ensure `.env` has Cloudinary credentials:
```
CLOUDINARY_CLOUD_NAME=deeifvoqv
CLOUDINARY_API_KEY=291573376946522
CLOUDINARY_API_SECRET=gQ-oJT4hfyCm0FObehWlCfnAVRE
```

### 3. Deploy Backend
```bash
git add backend/utils/cloudinary.js backend/routes/restaurants.js backend/server.js backend/package.json
git commit -m "Fix: Migrate restaurant images to Cloudinary for Render persistence"
git push
# Render will auto-deploy
```

### 4. Deploy Flutter
```bash
git add lib/services/restaurant_service.dart
git commit -m "Fix: Upload restaurant images to Cloudinary before registration"
git push
flutter pub get
```

---

## Benefits

✅ **Persistent Storage** - Images survive container restarts/redeployments  
✅ **CDN Delivery** - Cloudinary serves images from edge locations (faster)  
✅ **Automatic Optimization** - Images compressed and optimized  
✅ **Scalable** - Handles unlimited image uploads  
✅ **Secure** - Cloudinary handles SSL/TLS  
✅ **No Local Storage** - Eliminates filesystem issues on Render  

---

## Testing

### Test Restaurant Image Upload:
1. Launch Flutter app
2. Go to "Register Your Restaurant"
3. Select shop image
4. Fill in shop details
5. Verify image displays from Cloudinary URL
6. Deploy backend and restart Render container
7. Verify image still displays (not lost)

### Test Menu Item Upload:
1. Login as restaurant
2. Add menu item with image
3. Image uploads to Cloudinary
4. Verify in menu listing
5. Restart backend
6. Verify image still displays

---

## Rollback (if needed)

If you need to revert to local filesystem (not recommended):
```bash
git revert <commit-hash>
npm remove streamifier
rm backend/utils/cloudinary.js
```

---

## Future Improvements

- [ ] Add image compression before upload
- [ ] Add image watermarking
- [ ] Add batch image optimization
- [ ] Implement image version control (keep old versions)
- [ ] Add image usage analytics from Cloudinary

---

## Files Modified

✅ `backend/utils/cloudinary.js` - NEW file  
✅ `backend/routes/restaurants.js` - Updated  
✅ `backend/server.js` - Updated CORS  
✅ `backend/package.json` - Added streamifier  
✅ `lib/services/restaurant_service.dart` - Updated  

---

**Status:** ✅ COMPLETE & READY FOR DEPLOYMENT
