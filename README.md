# 🚌 Smart IoT-Based School Bus Tracking & Live Monitoring System

A comprehensive real-time school bus tracking solution featuring GPS tracking, live video streaming, push notifications, and multi-role access control for parents, drivers, and administrators.

**🔥 NEW: Driver's mobile phone acts as an IoT Edge Device for real-time telemetry, motion detection, and live video streaming!**

## 📋 Table of Contents

- [Features](#-features)
- [IoT Edge Device](#-iot-edge-device)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Configuration](#-configuration)
- [API Documentation](#-api-documentation)
- [Deployment](#-deployment)
- [Security](#-security)

## ✨ Features

### For Parents
- 🗺️ **Real-time GPS Tracking** - Live bus location on an interactive map
- 📹 **Live Video Streaming** - Watch dashcam footage via WebRTC
- 🔔 **Smart Notifications** - Alerts when bus approaches pickup/dropoff points
- 📊 **Trip History** - View past trips and arrival times
- 👨‍👩‍👧 **Multi-child Support** - Track multiple children on different buses

### For Drivers
- 📍 **Background Location Tracking** - Automatic GPS updates even when app is minimized
- 👥 **Student Management** - Mark students as picked up/dropped off
- 🆘 **Emergency Alerts** - One-tap emergency reporting
- 📹 **Live Streaming** - Broadcast dashcam footage to parents
- 🛣️ **Route Navigation** - View assigned routes and stops

### For Administrators
- 📊 **Dashboard Analytics** - Real-time fleet overview
- 🗺️ **Live Tracking Map** - Monitor all buses simultaneously
- 👤 **User Management** - Manage parents, drivers, and admins
- 🚌 **Fleet Management** - Add/edit buses, assign drivers
- 📈 **Reports** - Generate trip and performance reports

## 📡 IoT Edge Device

The driver's smartphone functions as a powerful **IoT Edge Device**, providing:

### Real-time Telemetry
- **GPS Location** - High-accuracy location updates every 3 seconds
- **Speed Monitoring** - Real-time speed tracking with speeding alerts
- **Heading/Direction** - Vehicle orientation for accurate map display
- **Altitude/Accuracy** - Detailed location metadata

### Motion Detection (Accelerometer + Gyroscope)
- **Harsh Braking Detection** - Alerts when driver brakes suddenly
- **Harsh Acceleration** - Detects aggressive acceleration
- **Sharp Turn Detection** - Identifies dangerous turning maneuvers
- **Driving Score** - Calculate driver safety scores

### Device Health Monitoring
- **Battery Level** - Monitor device battery with low-battery alerts
- **Network Status** - Track online/offline connectivity
- **Automatic Data Sync** - Buffer data offline, sync when connected

### Live Video Streaming (WebRTC)
- **Dashcam Mode** - Stream rear camera as dashcam
- **Multi-viewer Support** - Multiple parents can watch simultaneously
- **Adaptive Quality** - Adjusts video quality based on network
- **Audio Toggle** - Optional audio streaming

```
┌─────────────────────────────────────────────────────────────────┐
│                   DRIVER'S PHONE (IoT Edge Device)              │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    SENSORS & DATA                         │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐      │   │
│  │  │   GPS   │  │ Accel.  │  │  Gyro   │  │ Camera  │      │   │
│  │  │ (3s)    │  │ (50Hz)  │  │ (50Hz)  │  │ (WebRTC)│      │   │
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘      │   │
│  │       │            │            │            │            │   │
│  │       └──────┬─────┴────────────┴────────────┘            │   │
│  │              │                                            │   │
│  │       ┌──────┴──────┐                                     │   │
│  │       │  IoT Edge   │  ← Motion Analysis                  │   │
│  │       │  Service    │  ← Event Detection                  │   │
│  │       │             │  ← Offline Buffering                │   │
│  │       └──────┬──────┘                                     │   │
│  │              │                                            │   │
│  └──────────────┼────────────────────────────────────────────┘   │
│                 │                                                │
│          Socket.IO + WebRTC                                      │
│                 │                                                │
└─────────────────┼────────────────────────────────────────────────┘
                  ▼
           ┌──────────────┐
           │    CLOUD     │
           │   BACKEND    │
           └──────────────┘
```

## 🔌 Flexible Input Sources

The system supports **multiple input sources** for both GPS tracking and live video - choose what works best for your fleet!

### 📍 GPS Sources (Pluggable)

| Source | Description | Use Case |
|--------|-------------|----------|
| **📱 Phone GPS** | Built-in smartphone GPS | Default, no extra hardware |
| **📡 Bluetooth GPS** | External Bluetooth GPS receiver | Higher accuracy |
| **🚗 OBD-II Tracker** | Vehicle diagnostic port GPS | Vehicle-integrated tracking |
| **☁️ Fleet Tracker** | Dedicated GPS tracker via API | Enterprise fleet management |
| **🔌 USB GPS** | USB GPS dongle (tablets) | Fixed installation |

### 📹 Video Sources (Pluggable)

| Source | Description | Use Case |
|--------|-------------|----------|
| **📱 Phone Camera** | Built-in rear/front camera | Default, no extra hardware |
| **🎥 RTSP Dashcam** | External dashcam via RTSP | Professional dashcam |
| **📷 CCTV Camera** | Bus CCTV via RTSP/RTMP | Existing CCTV integration |
| **🌐 IP Camera** | IP camera via HTTP/MJPEG | Network cameras |

### Configuration Example

```dart
// Add external dashcam
await telemetryService.addRtspCamera(
  rtspUrl: 'rtsp://192.168.1.100:554/stream1',
  name: 'Front Dashcam',
  username: 'admin',
  password: 'password',
);

// Add Bluetooth GPS
await telemetryService.addExternalGps(
  type: 'bluetooth',
  deviceId: 'XX:XX:XX:XX:XX:XX',
  deviceName: 'Garmin GLO 2',
);

// Add fleet tracker
await telemetryService.addExternalGps(
  type: 'fleet',
  deviceId: 'TRACKER-001',
  apiEndpoint: 'https://api.fleettracker.com',
  apiKey: 'your-api-key',
);
```

### Architecture: Multiple Input Sources

```
┌─────────────────────────────────────────────────────────────────┐
│                    INPUT SOURCES (PLUGGABLE)                     │
│                                                                  │
│  GPS SOURCES                      VIDEO SOURCES                  │
│  ┌──────────┐                     ┌──────────┐                  │
│  │📱 Phone  │ ←─ Default          │📱 Phone  │ ←─ Default       │
│  │   GPS    │                     │  Camera  │                  │
│  └────┬─────┘                     └────┬─────┘                  │
│       │                                │                         │
│  ┌────┴─────┐                     ┌────┴─────┐                  │
│  │📡Bluetooth│ ←─ Optional        │🎥 RTSP   │ ←─ Optional      │
│  │   GPS    │                     │ Dashcam  │                  │
│  └────┬─────┘                     └────┬─────┘                  │
│       │                                │                         │
│  ┌────┴─────┐                     ┌────┴─────┐                  │
│  │🚗 OBD-II │ ←─ Optional         │📷 CCTV   │ ←─ Optional      │
│  │ Tracker  │                     │ Camera   │                  │
│  └────┬─────┘                     └────┴─────┘                  │
│       │                                │                         │
│  ┌────┴─────┐                          │                         │
│  │☁️ Fleet  │ ←─ Optional              │                         │
│  │ Tracker  │                          │                         │
│  └────┬─────┘                          │                         │
│       │                                │                         │
│       └────────────┬───────────────────┘                         │
│                    │                                             │
│            ┌───────┴───────┐                                     │
│            │   UNIFIED     │                                     │
│            │  TELEMETRY    │ ←─ Single Interface                 │
│            │   SERVICE     │                                     │
│            └───────┬───────┘                                     │
│                    │                                             │
└────────────────────┼─────────────────────────────────────────────┘
                     │
                     ▼
              ┌──────────────┐
              │   BACKEND    │
              │   SERVER     │
              └──────────────┘
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Mobile Apps                               │
│  ┌─────────────────┐  ┌─────────────────┐                       │
│  │   Parent App    │  │   Driver App    │                       │
│  │   (Flutter)     │  │   (Flutter)     │                       │
│  └────────┬────────┘  └────────┬────────┘                       │
│           │                    │                                 │
│           └────────┬───────────┘                                 │
│                    │                                             │
└────────────────────┼─────────────────────────────────────────────┘
                     │
          ┌──────────┴──────────┐
          │                     │
     ┌────┴────┐          ┌────┴────┐
     │  REST   │          │ Socket  │
     │  API    │          │   IO    │
     └────┬────┘          └────┬────┘
          │                    │
          └────────┬───────────┘
                   │
┌──────────────────┴──────────────────────────────────────────────┐
│                     Backend Server                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  Node.js + Express                        │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐    │   │
│  │  │   Auth   │ │ Location │ │  Alerts  │ │  WebRTC  │    │   │
│  │  │ Service  │ │ Service  │ │ Service  │ │ Signaling│    │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│              ┌───────────────┼───────────────┐                  │
│              │               │               │                   │
│         ┌────┴────┐    ┌────┴────┐    ┌────┴────┐              │
│         │ MongoDB │    │Firebase │    │  MQTT   │              │
│         │         │    │  FCM    │    │(future) │              │
│         └─────────┘    └─────────┘    └─────────┘              │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                     Admin Dashboard                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                 React.js + Material-UI                    │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐    │   │
│  │  │Dashboard │ │ Live Map │ │  Users   │ │ Reports  │    │   │
│  │  │          │ │          │ │Management│ │          │    │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘    │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

## 🛠️ Tech Stack

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Language**: TypeScript
- **Database**: MongoDB with Mongoose ODM
- **Real-time**: Socket.IO
- **Authentication**: JWT (JSON Web Tokens)
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Video Streaming**: WebRTC Signaling Server

### Mobile Apps (Flutter)
- **Framework**: Flutter 3.0+
- **State Management**: flutter_bloc
- **HTTP Client**: Dio
- **Maps**: Google Maps Flutter
- **Location**: Geolocator
- **Video**: flutter_webrtc
- **Push Notifications**: firebase_messaging
- **Local Storage**: flutter_secure_storage

### Admin Dashboard
- **Framework**: React 18
- **UI Library**: Material-UI (MUI) v5
- **State Management**: Zustand
- **Charts**: Chart.js / react-chartjs-2
- **Maps**: @react-google-maps/api
- **HTTP Client**: Axios
- **Forms**: react-hook-form

## 📁 Project Structure

```
school-bus-tracking/
├── backend/                    # Node.js Backend
│   ├── src/
│   │   ├── models/            # MongoDB Models
│   │   ├── routes/            # API Routes
│   │   ├── middleware/        # Auth & Validation
│   │   ├── services/          # Business Logic
│   │   ├── socket/            # Socket.IO Handlers
│   │   └── server.ts          # Entry Point
│   ├── package.json
│   └── tsconfig.json
│
├── flutter_parent_app/         # Parent Mobile App
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   ├── routes/
│   │   │   ├── services/
│   │   │   └── theme/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── home/
│   │   │   ├── tracking/
│   │   │   ├── notifications/
│   │   │   └── profile/
│   │   └── main.dart
│   └── pubspec.yaml
│
├── flutter_driver_app/         # Driver Mobile App
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   ├── routes/
│   │   │   ├── services/
│   │   │   └── theme/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── home/
│   │   │   └── trip/
│   │   └── main.dart
│   └── pubspec.yaml
│
├── admin-dashboard/            # React Admin Dashboard
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── store.js
│   │   ├── api.js
│   │   └── App.js
│   └── package.json
│
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ and npm/yarn
- MongoDB (local or Atlas)
- Flutter SDK 3.0+
- Firebase Project (for FCM)
- Google Maps API Key

### 1. Backend Setup

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your configuration
nano .env

# Start development server
npm run dev
```

### 2. Parent App Setup (Flutter)

```bash
# Navigate to parent app directory
cd flutter_parent_app

# Install dependencies
flutter pub get

# Update API URL in lib/core/constants/constants.dart

# Run the app
flutter run
```

### 3. Driver App Setup (Flutter)

```bash
# Navigate to driver app directory
cd flutter_driver_app

# Install dependencies
flutter pub get

# Update API URL in lib/core/constants/constants.dart

# Run the app
flutter run
```

### 4. Admin Dashboard Setup

```bash
# Navigate to admin dashboard directory
cd admin-dashboard

# Install dependencies
npm install

# Create .env file
echo "REACT_APP_API_URL=http://localhost:5000/api" > .env
echo "REACT_APP_SOCKET_URL=http://localhost:5000" >> .env
echo "REACT_APP_GOOGLE_MAPS_KEY=your-google-maps-key" >> .env

# Start development server
npm start
```

## ⚙️ Configuration

### Backend Environment Variables

```env
# Server
PORT=5000
NODE_ENV=development

# Database
MONGODB_URI=mongodb://localhost:27017/school-bus-tracking

# JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=7d

# Firebase (for push notifications)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# Google Maps (for geocoding)
GOOGLE_MAPS_API_KEY=your-google-maps-api-key

# Alert Settings
PROXIMITY_ALERT_DISTANCE=500  # meters
ARRIVAL_ALERT_DISTANCE=100    # meters
```

### Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Cloud Messaging
3. Download `google-services.json` for Android
4. Download `GoogleService-Info.plist` for iOS
5. Add server key to backend `.env`

### Google Maps Setup

1. Enable Maps SDK for Android/iOS
2. Enable Places API (optional)
3. Enable Directions API (optional)
4. Add API key restrictions for security

## 📡 API Documentation

### Authentication

```http
POST /api/auth/register
POST /api/auth/login
GET  /api/auth/me
PUT  /api/auth/profile
PUT  /api/auth/fcm-token
```

### Parent Endpoints

```http
GET  /api/parent/children
GET  /api/parent/children/:id/bus
GET  /api/parent/trips/history
GET  /api/parent/notifications
```

### Driver Endpoints

```http
GET  /api/driver/bus
GET  /api/driver/current-trip
POST /api/driver/trip/start
POST /api/driver/trip/end
PUT  /api/driver/location
POST /api/driver/student/:id/pickup
POST /api/driver/student/:id/dropoff
POST /api/driver/emergency
```

### Admin Endpoints

```http
# Users
GET    /api/admin/users
POST   /api/admin/users
PUT    /api/admin/users/:id
DELETE /api/admin/users/:id

# Buses
GET    /api/admin/buses
POST   /api/admin/buses
PUT    /api/admin/buses/:id
DELETE /api/admin/buses/:id

# Students
GET    /api/admin/students
POST   /api/admin/students
PUT    /api/admin/students/:id
DELETE /api/admin/students/:id

# Routes
GET    /api/admin/routes
POST   /api/admin/routes
PUT    /api/admin/routes/:id
DELETE /api/admin/routes/:id

# Stats & Reports
GET    /api/admin/stats
GET    /api/admin/alerts
PUT    /api/admin/alerts/:id/resolve
```

### Socket.IO Events

```javascript
// Client -> Server
'join:bus'           // Join bus room for updates
'leave:bus'          // Leave bus room
'location:update'    // Send location update (driver)
'stream:start'       // Start video stream (driver)
'stream:stop'        // Stop video stream (driver)
'webrtc:offer'       // WebRTC offer
'webrtc:answer'      // WebRTC answer
'webrtc:ice'         // ICE candidate

// Server -> Client
'bus:location'       // Bus location update
'student:status'     // Student pickup/dropoff
'alert:proximity'    // Proximity alert
'alert:emergency'    // Emergency alert
'stream:available'   // Stream available notification
```

## 🚀 Deployment

### Docker Deployment

```dockerfile
# Backend Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY dist ./dist
EXPOSE 5000
CMD ["node", "dist/server.js"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  backend:
    build: ./backend
    ports:
      - "5000:5000"
    environment:
      - MONGODB_URI=mongodb://mongo:27017/school-bus
    depends_on:
      - mongo

  mongo:
    image: mongo:6
    volumes:
      - mongo-data:/data/db

  admin:
    build: ./admin-dashboard
    ports:
      - "3000:80"

volumes:
  mongo-data:
```

### Production Checklist

- [ ] Set `NODE_ENV=production`
- [ ] Use strong JWT secret
- [ ] Enable HTTPS
- [ ] Configure CORS properly
- [ ] Set up rate limiting
- [ ] Enable MongoDB authentication
- [ ] Configure Firebase for production
- [ ] Set up monitoring (PM2, Datadog, etc.)
- [ ] Configure backup strategy
- [ ] Set up CI/CD pipeline

## 🔒 Security

### Implemented Security Measures

1. **JWT Authentication** - Secure token-based auth
2. **Password Hashing** - bcrypt with salt rounds
3. **Role-Based Access** - Parent/Driver/Admin separation
4. **Input Validation** - Request sanitization
5. **CORS Configuration** - Restricted origins
6. **Rate Limiting** - API request throttling
7. **Secure Headers** - Helmet.js integration

### Recommendations

- Use HTTPS in production
- Rotate JWT secrets periodically
- Implement API key rotation
- Set up intrusion detection
- Regular security audits
- GDPR compliance for student data

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

## 📞 Support

For support, email support@tirthgoyani.me or create an issue in the repository.

---

Built with ❤️ for safer school transportation
