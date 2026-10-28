# Smart Grocery Budgeting System

A modern Flutter application designed to optimize grocery shopping costs with the help of AI. This system tracks your budget in real-time and suggests cheaper alternatives for scanned items using Groq AI.

## 🚀 Features
- **Real-time Budget Tracking**: Set a budget and watch it update as you scan items.
- **Product Scanning Mode**:
  - **Phone Scanner**: Use your device's camera.
- **AI Recommendations**: Powered by Groq to suggest cost-effective alternatives.
- **Purchase History**: Keep track of your previous shopping trips and savings.
- **Dynamic UI**: Beautiful, dark-themed interface with smooth animations.

## 📂 Project Structure
- `/lib`: Flutter application source code.
- `/backend`: Node.js

## 🛠️ Setup
1. **Flutter App**:
   - Create a `.env` file in the root directory.
   - Add your Groq API key: `GROQ_API_KEY=your_groq_api_key_here`.
   - Run `flutter pub get` and `flutter run`.
2. **Backend**:
   - Navigate to `/backend`.
   - Run `npm install` and `npm start`.
   - Before deploying the backend changes for automatic product saving, configure `MONGO_URI` for the target database and run `npm run migrate:optional-product-barcode` once. This updates the unique barcode index to allow manually entered products without a barcode.

## 🎓 Research Project
This application is part of a Capstone Research Project focusing on IoT and AI integration in retail environments.