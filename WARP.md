# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

**Pulse** is a full-stack Twitter-like social media application with:
- **Frontend**: Flutter mobile app with advanced features like optimistic updates, real-time notifications, and rich media support
- **Backend**: Node.js/Express API with MongoDB, supporting social features like tweets, retweets, likes, followers, and real-time interactions

## Common Development Commands

### Backend Development
```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Start development server with auto-reload
npm run dev

# Start production server
npm start

# Database operations
npm run seed                 # Seed initial data
npm run fix-indexes         # Fix MongoDB indexing issues
npm run force-fix-indexes   # Force fix indexes (destructive)

# Test operations
npm run test-tweets         # Test tweet creation functionality
node scripts/test-tweet-creation.js
```

### Flutter Development
```bash
# Install Flutter dependencies
flutter pub get

# Generate launcher icons
flutter pub run flutter_launcher_icons:main

# Run on different platforms
flutter run                 # Default device
flutter run -d android      # Android
flutter run -d ios         # iOS
flutter run --release      # Release build

# Build for production
flutter build apk          # Android APK
flutter build aar         # Android library
flutter build ios         # iOS

# Testing
flutter test               # Run unit tests
flutter test test/widget_test.dart

# Clean and reset
flutter clean
flutter pub get
```

### Development Environment Setup
```bash
# Backend setup
cd backend
npm install
cp envCopy.txt .env         # Configure environment variables
npm run dev

# In separate terminal - Flutter setup  
cd ..
flutter pub get
flutter run
```

## Code Architecture

### Frontend Architecture (Flutter)

**Provider-Based State Management**: The app uses Provider pattern for state management with these key providers:
- `AuthProvider`: User authentication and session management
- `TweetProvider`: Tweet data, feed management, optimistic updates
- `NotificationProvider`: Real-time notifications and unread counts
- `ThemeProvider`: Dark/light mode theming
- `UploadProvider`: File upload progress and media handling

**Key Architectural Patterns**:
- **Optimistic Updates**: UI updates immediately before API calls (like/retweet actions)
- **Auto-refresh**: Background polling every 45 seconds for new tweets
- **Lazy Loading**: Infinite scroll with pagination for tweets and recommendations
- **Provider Consumer Pattern**: UI components consume state changes reactively

**Main App Structure**:
```
lib/
├── main.dart                    # App entry point with MultiProvider setup
├── screens/main_screen.dart     # Bottom navigation with Twitter-like behavior
├── providers/                   # State management (Auth, Tweet, Theme, etc.)
├── services/                    # API calls and external services
├── models/                      # Data models (Tweet, User, Notification)
├── widgets/                     # Reusable UI components
└── utils/                       # Themes and utilities
```

**Screen Organization**:
- **MainScreen**: Bottom navigation hub with Twitter-like double-tap behavior
- **HomeScreen**: Main feed with mixed regular and recommended tweets
- **TweetDetailScreen**: Individual tweet view with replies and interactions
- **EnhancedComposeTweetScreen**: Advanced tweet composition with media support

### Backend Architecture (Node.js/Express)

**RESTful API Design** with modular route organization:
```
backend/
├── server.js                    # Express app setup and middleware
├── routes/                      # API endpoints (auth, tweets, users, etc.)
├── models/                      # MongoDB schemas (Tweet, User, Notification)
├── middleware/                  # Authentication and request processing
├── services/                    # Business logic (RecommendationEngine)
└── scripts/                     # Database utilities and maintenance
```

**Database Schema (MongoDB)**:
- **Tweet**: Content, media files, engagement arrays (likes, retweets), parent-child relationships
- **User**: Profile data, follower/following relationships, preferences
- **Notification**: Real-time user notifications with read status

**Key Backend Features**:
- **Engagement Sorting**: Aggregation pipelines for sorting by likes/retweets
- **Recommendation System**: `RecommendationEngine.js` for discovering new content
- **Media Handling**: File uploads with video thumbnail generation using FFmpeg
- **Real-time Features**: Auto-refresh endpoints and notification systems

### Inter-Component Communication

**Provider → UI Flow**:
```
User Action → Provider Method → API Service → Backend Route → Database
     ↑                                                              ↓
UI Update ← notifyListeners() ← Provider State Update ← API Response
```

**Key Integration Points**:
- `ApiService`: Centralized HTTP client with error handling
- `api_config.dart`: Environment-specific API endpoint configuration
- Provider pattern ensures UI reactivity across all components

## Development Notes

### Database Considerations
- **MongoDB Indexing**: The project has specific index configurations to avoid "parallel arrays" errors
- Use `npm run fix-indexes` if you encounter MongoDB indexing issues
- Tweet engagement is calculated using aggregation pipelines, not direct sorting

### API Configuration
- Backend runs on port 8001 by default (configurable via `PORT` env variable)
- API base URL in `lib/config/api_config.dart` needs to match your development environment
- HTTPS setup available but commented out in `server.js`

### State Management Patterns
- **Optimistic Updates**: UI changes immediately, rolls back on API failure
- **Provider Consumer**: Use `Consumer<ProviderName>` for reactive UI updates
- **Global State**: Auth, tweets, and notifications persist across app navigation

### Media and File Handling  
- Backend supports image/video uploads with automatic thumbnail generation
- Frontend uses `UploadProvider` for progress tracking
- File size limits configured in Express middleware (100mb)

### Testing Strategy
- Backend has test scripts in `scripts/` directory for API validation
- Flutter has widget tests in `test/` directory
- Use `npm run test-tweets` to verify tweet creation workflow

### Performance Optimizations
- **Infinite Scroll**: Implemented with pagination and lazy loading
- **Image Caching**: Uses `cached_network_image` package for efficient image handling
- **Background Refresh**: Smart polling for new content without disrupting UX
- **IndexedStack**: Maintains screen state during bottom navigation

### Known Issues and Fixes
- MongoDB indexing errors are documented in `MONGODB_FIX_DOCUMENTATION.md`
- Twitter interaction optimizations are detailed in `ADDITIONAL_FIXES_SUMMARY.md`
- Several test files exist for validating specific functionality

This architecture supports a production-ready social media app with real-time features, optimistic UI updates, and scalable backend design.

## New Twitter Clone Features ✨

### Direct Messages System (COMPLETED)
**Backend**: Complete DM system with MongoDB models and REST API
```bash
# Message API endpoints
GET /api/messages/conversations          # List conversations
POST /api/messages/conversations         # Create conversation
GET /api/messages/conversations/:id/messages  # Get messages
POST /api/messages/conversations/:id/messages # Send message (with media)
PATCH /api/messages/conversations/:id/read     # Mark as read
DELETE /api/messages/messages/:id              # Delete message
POST /api/messages/messages/:id/reactions     # React to message
```

**Frontend**: Flutter models and providers ready
- `MessageProvider`: Real-time state management
- `Message` and `Conversation` models with full feature support
- Media support, reactions, read receipts, and conversation threading

**Usage**: Add MessageProvider to your app and create DM screens
```dart
// Access message provider
final messageProvider = Provider.of<MessageProvider>(context);
// Load conversations
await messageProvider.loadConversations();
// Send message
await messageProvider.sendMessage(conversationId, content);
```

### Quote Tweets & Threads (BACKEND READY)
**Backend**: Tweet model updated with quote tweet and thread support
- `quotedTweet`: Reference to quoted tweet
- `isQuoteTweet`: Boolean flag for quote tweets
- `threadId`: Thread identifier for tweet chains
- `threadOrder`: Order within thread

**Frontend**: Ready for UI implementation

### Enhanced Twitter Features Roadmap
```
✅ COMPLETED:
- Direct Messages (full backend + models)
- Quote Tweets (backend ready)
- Twitter Threads (backend ready)
- Advanced search with all tabs
- Real-time notifications
- Media upload with progress
- Optimistic UI updates

🚧 READY FOR UI IMPLEMENTATION:
- Direct Messages UI screens
- Quote Tweet composer and display
- Thread composer and visualization
- Advanced user interactions (block/mute)

💡 FUTURE ENHANCEMENTS:
- Twitter Spaces (audio rooms)
- Communities
- Polls
- Twitter Blue features
```

The backend infrastructure now supports a complete Twitter clone with modern features. Focus on implementing the frontend UI components to complete the user experience.
