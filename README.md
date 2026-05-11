# IoT-Enabled Smart Grocery Budgeting System

A modern Flutter application designed to optimize grocery shopping costs using AI and IoT. This system tracks your budget in real-time and suggests cheaper alternatives for scanned items using Google Gemini AI.

## 🚀 Features
- **Real-time Budget Tracking**: Set a budget and watch it update as you scan items.
- **Dual Scanning Modes**:
  - **Phone Scanner**: Use your device's camera.
  - **IoT Scanner**: Connect to an external smart cart scanner (ESP32-based).
- **AI Recommendations**: Powered by Google Gemini to suggest cost-effective alternatives.
- **Purchase History**: Keep track of your previous shopping trips and savings.
- **Dynamic UI**: Beautiful, dark-themed interface with smooth animations.

## 📂 Project Structure
- `/lib`: Flutter application source code.
- `/backend`: Node.js + Socket.io server to bridge IoT hardware and the app.
- `/iot_firmware`: C++ code for the ESP32-based barcode scanner.

## 🛠️ Setup
1. **Flutter App**:
   - Create a `.env` file in the root directory.
   - Add your API key: `GEMINI_API_KEY=your_key_here`.
   - Run `flutter pub get` and `flutter run`.
2. **Backend**:
   - Navigate to `/backend`.
   - Run `npm install` and `npm start`.
3. **Hardware**:
   - Flash the code in `/iot_firmware` to your ESP32.
   - Ensure the server IP matches your local machine's IP.

## 🎓 Research Project
This application is part of a Capstone Research Project focusing on IoT and AI integration in retail environments.
