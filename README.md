# FinMate

A premium, modern, AI-powered personal finance partner built with Flutter.

FinMate helps you track your expenses, manage budgets, analyze your financial health score, and forecast future spending using AI. The app features a beautiful, glassmorphic UI with vibrant Zomato-red accents.

## Features

- **Transaction Tracking**: Log income and expenses with automatic categorization.
- **Budget Management**: Set and track monthly budget limits per category.
- **Financial Health Score**: Get a dynamic 0-100 score analyzing your savings rate, budget adherence, and emergency fund goals.
- **AI Spending Forecast**: Machine learning fallback model to predict next month's expenses based on your trend.
- **Smart Analytics**: Beautiful, interactive pie charts and trend lines.
- **Premium UI**: Glassmorphism aesthetic, subtle haptics, and smooth animations.

## Getting Started

### 1. Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- Android Studio / Xcode

### 2. Configure Firebase (Mandatory)
This project uses Firebase for real-time database sync and authentication. **You must add your own Firebase API keys to run the app.**

1. Create a project at [Firebase Console](https://console.firebase.google.com/).
2. Register an Android App (package name: `com.finmate.frontend`) and a Web App.
3. Update `android/app/google-services.json`:
   - Replace all instances of `INSERT_YOUR_...` with your actual Firebase project credentials.
4. Update `lib/firebase_options.dart`:
   - Replace all placeholder `INSERT_YOUR_...` strings with your actual Firebase keys.

### 3. Run the App
Once you have inserted your API keys, fetch the dependencies and run the app:

```bash
flutter pub get
flutter run
```

## Contributing
Pull requests are welcome! Ensure you do not commit your real `google-services.json` or `firebase_options.dart` keys if you make changes. 

## License
MIT License
