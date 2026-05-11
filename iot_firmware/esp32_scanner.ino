/*
 * Smart Grocery Budgeting - IoT Scanner Firmware
 * Hardware: ESP32 + Barcode Scanner Module (GM65 or similar)
 */

#include <WiFi.h>
#include <HTTPClient.h>

// WiFi Configuration
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Backend Configuration
// IMPORTANT: Update this to your computer's local IP address
const char* serverUrl = "http://192.168.1.XX:3000/scan";

void setup() {
  Serial.begin(115200);
  Serial2.begin(9600); // UART for Barcode Scanner

  connectWiFi();
}

void loop() {
  if (Serial2.available()) {
    String barcode = Serial2.readStringUntil('\n');
    barcode.trim();
    
    if (barcode.length() > 0) {
      Serial.println("Scanned: " + barcode);
      sendScanToBackend(barcode);
    }
  }

  // Check WiFi connection
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }
}

void connectWiFi() {
  Serial.print("Connecting to WiFi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");
}

void sendScanToBackend(String barcode) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");

    String jsonPayload = "{\"barcode\":\"" + barcode + "\"}";
    int httpResponseCode = http.POST(jsonPayload);

    if (httpResponseCode > 0) {
      Serial.print("HTTP Response code: ");
      Serial.println(httpResponseCode);
    } else {
      Serial.print("Error code: ");
      Serial.println(httpResponseCode);
    }
    http.end();
  }
}
