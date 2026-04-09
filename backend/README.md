# Smart Canteen Backend - README

## Setup Instructions

### 1. Prerequisites
- Node.js 16+ installed
- MongoDB instance (Atlas or local)
- Firebase project with service account

### 2. Installation

```bash
# Install dependencies
npm install
```

### 3. Environment Setup

```bash
# Copy example file
cp .env.example .env

# Edit .env with your credentials:
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/smartcanteen
PORT=3000
NODE_ENV=development
FIREBASE_PROJECT_ID=smartcanteen-6764c
FIREBASE_PRIVATE_KEY="your-private-key"
FIREBASE_CLIENT_EMAIL=your-email@smartcanteen-6764c.iam.gserviceaccount.com
```

### 4. Running the Backend

**Development:**
```bash
npm run dev
```

**Production:**
```bash
npm start
```

Server runs on `http://localhost:3000`

## 🚀 Deployment

### Deploy to Render
For production deployment to Render.com, follow the complete guide:
- **[RENDER_DEPLOYMENT.md](./RENDER_DEPLOYMENT.md)** - Full deployment instructions

**Quick start:**
1. Push to main branch
2. Connect GitHub repository to Render
3. Set environment variables (MONGODB_URI, JWT_SECRET)
4. Deploy!

## API Endpoints

### Users
- `POST /api/users/sync` - Sync/create user from Firebase
- `GET /api/users/me` - Get current user
- `PUT /api/users/me` - Update current user profile
- `GET /api/users/:userId` - Get user by ID (public)

### Menu
- `GET /api/menu` - Get all available menu items
- `GET /api/menu?category=Main` - Filter by category
- `GET /api/menu/:id` - Get single menu item
- `POST /api/menu` - Create menu item (auth required)
- `PUT /api/menu/:id` - Update menu item (auth required)
- `DELETE /api/menu/:id` - Delete menu item (auth required)
- `PATCH /api/menu/:id/availability` - Toggle availability

### Orders
- `POST /api/orders` - Create new order (auth required)
- `GET /api/orders` - Get user's orders (auth required)
- `GET /api/orders/:id` - Get single order (auth required)
- `PATCH /api/orders/:id/status` - Update order status (auth required)
- `PATCH /api/orders/:id/cancel` - Cancel order (auth required)

### Reviews
- `POST /api/reviews` - Create review (auth required)
- `GET /api/reviews` - Get all reviews
- `GET /api/reviews/order/:orderId` - Get reviews for order
- `PUT /api/reviews/:id` - Update review (auth required)
- `DELETE /api/reviews/:id` - Delete review (auth required)

## Authentication

All endpoints (except public GET requests) require Firebase ID token:

```
Authorization: Bearer <firebase-id-token>
```

## Database Collections

### Users
```
{
  uid: String,           // Firebase UID
  name: String,
  email: String,
  role: "customer" | "restaurant",
  phoneNumber: String,
  address: String,
  profileImage: String,
  createdAt: Date,
  updatedAt: Date
}
```

### MenuItems
```
{
  name: String,
  description: String,
  price: Number,
  imageUrl: String,
  category: String,
  isAvailable: Boolean,
  preparationTime: Number,
  rating: Number (0-5),
  createdAt: Date
}
```

### Orders
```
{
  customerId: String,
  customerName: String,
  items: [{
    foodItemId: ObjectId,
    foodItemName: String,
    price: Number,
    quantity: Number,
    imageUrl: String
  }],
  totalAmount: Number,
  deliveryAddress: String,
  status: "Pending" | "Preparing" | "Ready" | "Delivered" | "Cancelled",
  paymentMethod: String,
  orderDate: Date,
  updatedAt: Date
}
```

### Reviews
```
{
  orderId: ObjectId,
  customerId: String,
  customerName: String,
  rating: Number (1-5),
  comment: String,
  imageUrl: String,
  createdAt: Date
}
```

## Deployment

### Heroku
```bash
heroku login
heroku create smartcanteen-api
heroku config:set MONGODB_URI="your-connection-string"
heroku config:set FIREBASE_PROJECT_ID="your-project-id"
# ... set other env vars
git push heroku main
```

### Docker
```bash
docker build -t smartcanteen-backend .
docker run -p 3000:3000 --env-file .env smartcanteen-backend
```

### Important: Update Flutter App

After deployment, update `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'https://smartcanteen-api.herokuapp.com/api';
```

## Troubleshooting

**MongoDB connection fails:**
- Check MONGODB_URI in .env
- Verify IP whitelist in MongoDB Atlas

**Firebase authentication errors:**
- Verify Firebase credentials in .env
- Check token expiration
- Ensure Firebase project exists

**CORS errors:**
- Backend has cors() enabled by default
- For production, update CORS policy in server.js

## Support

For issues, check:
1. Backend logs: `npm run dev`
2. MongoDB connection
3. Firebase credentials
4. Flutter app's API base URL
