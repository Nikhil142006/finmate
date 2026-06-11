# 💰 FinMate - Your AI-Powered Personal Finance Partner

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.8+-blue?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8+-00A8E1?style=flat-square&logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud%20Firestore-yellow?style=flat-square&logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/Nikhil142006/finmate?style=flat-square)](https://github.com/Nikhil142006/finmate/stargazers)

**Premium personal finance management with intelligent AI insights and stunning glassmorphic design**

[Features](#-features) • [Screenshots](#-screenshots) • [Getting Started](#-getting-started) • [Contributing](#-contributing)

</div>

---

## 🎯 About FinMate

FinMate is a **next-generation personal finance app** that combines modern UI design with powerful AI capabilities. Whether you're tracking daily expenses or planning long-term budgets, FinMate provides intelligent insights to help you make smarter financial decisions.

Built with **Flutter** for cross-platform excellence and **Firebase** for seamless real-time synchronization, FinMate delivers a premium experience on iOS and Android.

### Why FinMate?

- 🤖 **AI-Powered Intelligence** - Machine learning models predict spending patterns
- 💎 **Premium Experience** - Glassmorphic UI with smooth animations
- 🎯 **Real-Time Sync** - Cloud-based storage with Firebase
- 📊 **Deep Analytics** - Beautiful charts and financial health insights
- 🚀 **High Performance** - Optimized Dart/C++ implementation

---

## ✨ Features

### 💳 Transaction Tracking
- Log income and expenses with ease
- Automatic expense categorization
- Receipt capture with image picker
- Transaction history with powerful search

### 📋 Budget Management
- Set personalized monthly budget limits per category
- Track spending in real-time
- Get alerts when nearing budget limits
- Visual progress indicators

### 🏥 Financial Health Score
- **Dynamic 0-100 score** analyzing your financial wellness
- Factors considered:
  - Savings rate tracking
  - Budget adherence metrics
  - Emergency fund readiness
  - Spending patterns & trends
- Monthly improvement insights

### 🤖 AI Spending Forecast
- Machine learning-powered expense predictions
- Forecast next month's spending based on historical trends
- Adaptive models that learn your habits
- Smart category-wise predictions

### 📈 Smart Analytics
- Interactive pie charts for expense breakdown
- Trend lines showing spending patterns over time
- Category-wise analysis and comparisons
- Monthly and yearly reports

### 🎨 Premium UI/UX
- **Glassmorphic design** aesthetic
- Smooth animations and transitions
- Subtle haptic feedback
- Dark mode support
- Responsive across all screen sizes
- Zomato-inspired color palette

### 🔐 Security & Authentication
- Google Sign-In integration
- Firebase Authentication
- Secure cloud storage
- Data encryption in transit

---

## 🛠 Tech Stack

| Component | Technology |
|-----------|-----------|
| **Frontend** | Flutter + Dart |
| **Backend** | Firebase (Firestore, Auth) |
| **AI/ML** | Google Generative AI API |
| **Charts** | fl_chart |
| **State Management** | Provider |
| **Platform** | iOS & Android (Native code in C++) |

**Language Composition:**
- Dart: 77.3% (Flutter logic)
- C++: 11.4% (Native performance)
- CMake: 8.9% (Build system)
- Swift: 1.2% (iOS integration)

---

## 📸 Screenshots

> Coming soon! Share your best UI screenshots here to showcase the glassmorphic design.

```
Dashboard    │    Budget View    │    Analytics    │    Profile
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (latest stable - 3.8+)
- **Dart SDK** (3.8+)
- **Android Studio** or **Xcode** (for emulator/device)
- **Git**

### Step 1: Clone the Repository

```bash
git clone https://github.com/Nikhil142006/finmate.git
cd finmate
```

### Step 2: Configure Firebase (⚠️ MANDATORY)

This project requires **Firebase credentials** to function. You must set up your own Firebase project:

1. **Create Firebase Project**:
   - Visit [Firebase Console](https://console.firebase.google.com/)
   - Create a new project

2. **Register Apps**:
   - Add an **Android App** (package: `com.finmate.frontend`)
   - Download `google-services.json`
   - Add an **iOS App**
   - Download `GoogleService-Info.plist`

3. **Update Android Configuration**:
   - Replace `android/app/google-services.json` with your downloaded file
   - Ensure all `INSERT_YOUR_...` placeholders are replaced

4. **Update Dart Configuration**:
   - Open `lib/firebase_options.dart`
   - Replace all `INSERT_YOUR_...` placeholders with your Firebase credentials:
     - API keys
     - Project IDs
     - Web client IDs

5. **Enable Firebase Services**:
   - Firestore Database (test mode for development)
   - Authentication (Google Sign-In)
   - Cloud Storage (optional)

### Step 3: Install Dependencies

```bash
flutter pub get
```

### Step 4: Run the App

```bash
# On connected device/emulator
flutter run

# Specific device
flutter run -d <device-id>

# Release build
flutter run --release
```

---

## 📚 Project Structure

```
finmate/
├── lib/
│   ├── main.dart              # App entry point
│   ├── firebase_options.dart  # Firebase configuration
│   ├── screens/               # UI screens
│   ├── models/                # Data models
│   ├── services/              # Business logic & API calls
│   ├── widgets/               # Reusable components
│   └── utils/                 # Helper functions
├── android/                   # Android-specific code
├── ios/                       # iOS-specific code
├── web/                       # Web support (future)
└── pubspec.yaml              # Dependencies
```

---

## 🤝 Contributing

We welcome contributions! Whether it's bug fixes, features, or improvements, your help makes FinMate better.

### How to Contribute

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Before Submitting

- ✅ Test your changes thoroughly
- ✅ Follow Dart/Flutter style guidelines
- ✅ Add comments for complex logic
- ✅ **Do NOT commit** real Firebase credentials
- ✅ Keep `.gitignore` updated

### Development Setup

```bash
# Install dependencies
flutter pub get

# Run code analysis
flutter analyze

# Format code
dart format .

# Run tests (if available)
flutter test
```

---

## 🐛 Bug Reports & Feature Requests

Found a bug or have a feature idea? 

- **Bug Reports**: [Open an Issue](https://github.com/Nikhil142006/finmate/issues/new?labels=bug)
- **Feature Requests**: [Open an Issue](https://github.com/Nikhil142006/finmate/issues/new?labels=enhancement)

Please include:
- Clear description
- Steps to reproduce (for bugs)
- Expected vs actual behavior
- Screenshots/videos (if applicable)

---

## 📞 Support & Feedback

- 💬 **Discussions**: [GitHub Discussions](https://github.com/Nikhil142006/finmate/discussions)
- 🐦 **Issues**: [Report an Issue](https://github.com/Nikhil142006/finmate/issues)

---

## 🎓 Learning Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase + Flutter Guide](https://firebase.google.com/docs/flutter/setup)
- [Dart Language](https://dart.dev/guides)
- [Material Design](https://material.io/design)

---

<div align="center">

**Questions? Check out the [documentation](https://github.com/Nikhil142006/finmate#-getting-started) or open a discussion.**

</div>
