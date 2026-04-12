# 🚀 IoT Smart Utility Monitoring System (Electricity & Water)

[cite_start]A comprehensive IoT solution designed to collect and identify sensor data via **Bluetooth Low Energy (BLE)**, featuring real-time cloud synchronization with **Firebase** and an interactive mobile dashboard built with **Flutter**[cite: 6, 8, 11, 12].

---

## Demo
![video_demo_CK_mobile_application-ezgif com-video-to-gif-converter (3)](https://github.com/user-attachments/assets/daa347e7-0c5d-46b2-b26e-8b81836c7951)
![video_demo_CK_mobile_application-ezgif com-video-to-gif-converter (4)](https://github.com/user-attachments/assets/77c422b8-f7fd-4e88-8526-c485a85fc3bb)

---

## Features
* [cite_start]**BLE Connectivity:** Automatic scanning and seamless connection to IoT peripheral nodes such as **ESP32** or **nRF52**[cite: 6, 8].
* [cite_start]**Data Processing:** Generates and processes raw simulated sensor payloads to mimic real-world utility meter readings[cite: 6, 8, 12].
* [cite_start]**Firebase Integration:** Automated real-time data uplink to **Firebase Realtime Database** for instant global accessibility[cite: 6, 11].
* [cite_start]**Intuitive UI:** Dynamic tracking charts and real-time parameter monitoring within the mobile application[cite: 6, 8].
* [cite_start]**History Management:** Secure cloud storage for logging and retrieving historical data trends[cite: 6, 11].

---

## System Architecture
1. [cite_start]**Peripheral Layer (Sensor Nodes):** **ESP32** nodes that acquire sensor data and transmit it via the BLE protocol[cite: 6, 8, 12].
2. [cite_start]**Gateway Layer (Central/Mobile App):** A smartphone acting as a central gateway, receiving BLE packets and forwarding them to the cloud[cite: 6, 8].
3. [cite_start]**Cloud Layer (Storage):** **Firebase** manages data persistence, user authentication, and push notifications[cite: 6, 11].

---

## Tech Stack

| Component | Technology / Tools |
| :--- | :--- |
| **Microcontroller** | [cite_start]**ESP32** (Supporting Dual-mode Bluetooth) [cite: 6, 12] |
| **Mobile Application** | [cite_start]**Flutter (Dart)** [cite: 6, 8] |
| **Database** | [cite_start]**Firebase (Realtime Database)** [cite: 6, 11] |
| **Protocol** | [cite_start]**BLE (Bluetooth Low Energy 4.2/5.0)** [cite: 6] |

---

## Setup & Usage

### 1. Hardware Configuration (Firmware)
* [cite_start]Open the source code located in the `firmware/` directory using **Arduino IDE**[cite: 6, 12].
* [cite_start]Install the `ESP32 BLE Arduino` library via the Library Manager[cite: 6].
* [cite_start]Flash the code to your **ESP32** development kit[cite: 6, 12].

### 2. Mobile Application Setup
* [cite_start]**Prerequisites:** Ensure **Flutter SDK** is installed and **Android Studio** is configured[cite: 6, 8].
* Fetch necessary dependencies:
    ```bash
    flutter pub get
    ```
* [cite_start]Download the `google-services.json` file from your **Firebase Console** and place it in the `android/app/` directory[cite: 6, 11].
* Run the application on a physical device (ensure Bluetooth and Location services are enabled):
    ```bash
    flutter run
    ```

---

