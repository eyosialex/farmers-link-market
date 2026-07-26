# 🌱 LinkedFarm

> **Connecting farmers, vendors, advisors, and the entire agricultural supply chain — in one platform.**

LinkedFarm is a full-featured Flutter mobile application built for the Ethiopian agricultural ecosystem. It digitizes every step of the farm-to-market journey: from planting and crop management to selling, buying, delivery, and financial services.

---

## 🚀 Features by Role

### 🌾 Farmer Suite

| Feature | Description |
|--------|-------------|
| **Home Dashboard** | Dynamic greeting, live weather, today's summary (sales, orders, harvest), quick actions, recent activity feed |
| **My Farm Tab** | List and manage all products with live stock status (Active / Low Stock / Closed) |
| **Sell Harvest** | List crops with photos, price, quantity, location, and bank payment details |
| **Order Management** | Incoming orders with Accept / Reject / Verify Payment / Ready for Pickup flow |
| **Market Page** | SELL hub, BUY marketplace, and real-time PRICES tab with 7-day trend curves |
| **Land Boundary Mapper** | Draw farm boundaries on OpenStreetMap, calculate area in hectares/acres, save to Firestore |
| **Farm Plan (Virtual Farm)** | AI-powered crop simulation — weather integration, daily growth tracking, soil/pest risk alerts |
| **Advisor Hub** | Expert advice feed, free & premium courses, AI agronomist, farming pulse analytics |
| **Chat** | Direct messaging with vendors and buyers, group chats, image/video/audio sharing |
| **Profile Page** | View/edit profile, product grid, enrolled courses, order history, land map entry, farm plan entry |

---

### 🏪 Vendor Suite

| Feature | Description |
|--------|-------------|
| **Product Marketplace** | Browse all farm products with search, category filters, map-based distance sorting |
| **Buy & Order** | Place orders via COD or Bank Transfer, upload payment proof |
| **Wanted Products** | Post crop demand — farmers with matching listings are notified automatically |
| **Price Prediction** | Analytical price trend graphs with "Buy Now" alerts when prices are rising |
| **Trusted Farmers Index** | AI-ranked farmer profiles based on rating and supply consistency |
| **My Purchases** | Track orders: Pending → Awaiting Verification → Verified → In Transit → Delivered |
| **Delivery Tracking Hub** | Live map tracking of drivers during transit |
| **Shared Delivery** | Pool deliveries with other vendors to reduce logistics cost |

---

### 🚚 Delivery Suite

| Feature | Description |
|--------|-------------|
| **Available Orders** | Browse orders marked "Ready for Pickup" in the area |
| **Accept Delivery** | Claim an order — farmer and vendor are notified instantly |
| **Live Location Tracking** | Real-time GPS position shared during transit |
| **OSRM Smart Routing** | Optimal route from farm to dropoff using open-source road routing |
| **Delivery Completion** | Mark as Delivered to close the transaction and trigger notifications |

---

### 🧪 Shopper (Agri-Input Supplier) Suite

| Feature | Description |
|--------|-------------|
| **Input Listing** | List pesticides, seeds, fertilizers, tools with expiry dates and quantities |
| **Smart Referral** | When AI recommends a product to a farmer, a direct link is sent to the nearest matching shopper |
| **Inventory Management** | Update stock levels, manage incoming orders |

---

### 🎓 Advisor Suite

| Feature | Description |
|--------|-------------|
| **Post Advice** | Publish expert agronomic articles to the advice feed |
| **Course Management** | Create free/premium courses with lessons, videos, and quizzes |
| **AI Agronomist** | Gemini-powered crop disease identification via photo upload |
| **Farming Pulse** | Real-time analytics on crop health, market trends, and weather |

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile UI | Flutter (Dart) |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| Media Storage | Cloudinary |
| AI / LLM | Google Gemini AI (`google_generative_ai`) |
| Weather | OpenWeatherMap API |
| Maps & Land | OpenStreetMap + flutter_map + OSRM |
| Local Storage | Hive |
| State Management | Provider |
| Localization | flutter_localizations (EN / አማርኛ / Oromiffa) |
| Notifications | Custom Firestore-based notification service |
| Real-time Chat | Firestore streams + WebSocket service |

---

## 📂 Project Structure

```
lib/
├── Advisor View/           # Advisor: courses, articles, post advice
├── Chat/                   # Messaging: direct, group, media sharing
├── Dlivery View/           # Delivery: tracking, routing, live location
├── Farmers View/           # Farmer: home, market, products, orders, profile
│   ├── tabs/               # Advisor hub sub-tabs (AI, Pulse, Learn)
│   └── learning/           # Course detail & lesson viewer
├── Game/                   # Virtual farm simulation
│   ├── models/             # Game state, crop, soil models
│   ├── logic/              # Simulation engine, AI advisor
│   └── ui/                 # Farm dashboard, land selection, main screen
├── l10n/                   # Localization ARB files + generated code
├── Main Office/            # Central office management page
├── Models/                 # Shared: Order, Course, Notification models
├── Services/               # Firebase, Weather, Chat, Gemini, Hive services
├── Shopper View/           # Input supplier role
├── User Credential/        # Auth: login, register, profile setup
└── Vendors View/           # Vendor: marketplace, orders, delivery tracking
```

---

## 🌍 Localization

LinkedFarm supports **3 languages**:

| Language | Code | File |
|----------|------|------|
| English | `en` | `lib/l10n/app_en.arb` |
| Amharic (አማርኛ) | `am` | `lib/l10n/app_am.arb` |
| Oromiffa | `om` | `lib/l10n/app_om.arb` |

Switch language from **Profile → Settings → Language**.

---

## 🔐 User Roles & Auth Flow

```
Login / Register
      │
      ▼
  AuthGate  ──  checks userType in Firestore (Usersstore collection)
      │
      ├── farmer    →  FarmersHomePage   (5-tab shell: Home, Farm, Market, Advisor, Profile)
      ├── vendor    →  VendorHomePage
      ├── advisor   →  AdvisorHomePage
      ├── delivery  →  DeliveryHomePage
      └── shopper   →  ShopperHomePage
```

New users must complete their profile (name, location, farm type) before accessing the main app.

---

## ⚙️ Setup & Installation

### Prerequisites
- Flutter SDK `^3.8.1`
- Dart SDK `^3.8.1`
- Firebase project with Android + iOS configured
- Android Studio or VS Code with Flutter + Dart extensions

### 1. Clone the repo
```bash
git clone https://github.com/your-username/linkedfarm.git
cd linkedfarm
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure Firebase
- Add your `google-services.json` to `android/app/`
- Add your `GoogleService-Info.plist` to `ios/Runner/`
- The `lib/firebase_options.dart` file is already generated — replace with your own using:
```bash
flutterfire configure
```

### 4. Run code generation (Hive models)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 5. Run the app
```bash
flutter run
```

---

## 🗄️ Firestore Collections

| Collection | Description |
|-----------|-------------|
| `Usersstore` | All user profiles (userType, fullName, location, profileImage, bio) |
| `agricultural_items` | Farmer product listings |
| `orders` | All orders between farmers and vendors |
| `land_boundaries` | Farmer land polygon data |
| `courses` | Learning courses and lessons |
| `delivery_locations` | Live GPS positions of delivery drivers |
| `users/{uid}/notifications` | Per-user notification inbox |
| `chat_rooms` | Direct and group chat metadata |
| `messages` | Chat messages (nested under chat rooms) |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is private. All rights reserved © 2025 LinkedFarm.

---

## 📞 Contact

Built with ❤️ for Ethiopian farmers.  
For inquiries, open an issue or contact the development team.
