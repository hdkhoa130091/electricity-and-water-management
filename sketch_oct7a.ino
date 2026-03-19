#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <Arduino.h>
#include <time.h> // Thư viện để xử lý thời gian

// ----- CẤU HÌNH -----
#define ESP32_DEVICE_NAME     "ESP32_DienNuoc_Full" // Đổi tên để dễ phân biệt
#define SERVICE_UUID          "4fafc201-1fb5-459e-8fcc-c5c9c331914b"

// (Cũ) Characteristic để GỬI dữ liệu (Notify)
#define DATA_CHAR_UUID        "beb5483e-36e1-4688-b7f5-ea07361b26a8"
// (MỚI) Characteristic để NHẬN ngưỡng (Write)
#define THRESHOLD_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a9"

// (MỚI) Chân LED cảnh báo
#define LED_PIN 2
// -------------------------------------------------------------

BLEServer* pServer = NULL;
BLECharacteristic* pDataCharacteristic = NULL; // Để gửi
BLECharacteristic* pThresholdCharacteristic = NULL; // (MỚI) Để nhận
bool deviceConnected = false;
unsigned long lastTime = 0;
const long interval = 1000; // 1 giây

// (MỚI) Biến lưu trữ ngưỡng, đặt mặc định rất cao
float ele_threshold = 9999.0;

// --- BIẾN ĐỂ GIẢ LẬP DỮ LIỆU THEO THÁNG (Giữ nguyên) ---
int currentYear = 2025;
int currentMonth = 1; 
int readingsPerMonth = 5;
int readingCount = 0; 
float baseElec = 100.0;
float baseWater = 10.0;
// ------------------------------------------

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Thiết bị đã kết nối!");
      // Reset lại tháng về tháng 1 khi có kết nối mới
      currentMonth = 1;
      readingCount = 0;
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("Thiết bị đã ngắt kết nối!");
      // (SỬA ĐỔI) Khởi động lại quảng cáo khi mất kết nối
      pServer->getAdvertising()->start();
    }
};

// --- (MỚI) Callbacks khi App GHI (Write) vào characteristic ---
// Đây là nơi chúng ta nhận ngưỡng
class MyThresholdCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      // Lấy giá trị App gửi xuống (dưới dạng Arduino String)
      String value = pCharacteristic->getValue().c_str();

      if (value.length() > 0) {
        Serial.print("Đã nhận giá trị ngưỡng mới: ");
        Serial.println(value);

        // Chuyển đổi Arduino String sang float và lưu lại
        ele_threshold = value.toFloat();
        
        Serial.print("Đã cập nhật ngưỡng: ");
        Serial.println(ele_threshold);
      }
    }
};


void setup() {
  Serial.begin(115200);
  Serial.println("Bắt đầu khởi tạo BLE Server (Bản Gộp)...");

  // (MỚI) Cấu hình chân LED
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW); // Tắt LED khi khởi động

  BLEDevice::init(ESP32_DEVICE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  // (Cũ) Tạo Characteristic để GỬI DỮ LIỆU (Notify)
  pDataCharacteristic = pService->createCharacteristic(
                         DATA_CHAR_UUID,
                         BLECharacteristic::PROPERTY_NOTIFY
                       );

  // (MỚI) Tạo Characteristic để NHẬN NGƯỠNG (Write)
  pThresholdCharacteristic = pService->createCharacteristic(
                              THRESHOLD_CHAR_UUID,
                              BLECharacteristic::PROPERTY_WRITE
                            );
  // (MỚI) Gán callbacks onWrite cho characteristic này
  pThresholdCharacteristic->setCallbacks(new MyThresholdCallbacks());
                       
  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);     //tên thiết bị
  pAdvertising->setScanResponse(true);
  BLEDevice::startAdvertising();
  
  Serial.println("ESP32 đã sẵn sàng, đang chờ kết nối...");
}

void loop() {
  if (deviceConnected) {
    if (millis() - lastTime > interval) {
      lastTime = millis();
      
      readingCount++;

      // --- TẠO TIMESTAMP GIẢ LẬP  ---
      struct tm timeinfo = {0};
      timeinfo.tm_year = currentYear - 1900;
      timeinfo.tm_mon = currentMonth - 1; 
      timeinfo.tm_mday = readingCount * 5; 
      time_t timestamp = mktime(&timeinfo);

      // --- TẠO DỮ LIỆU NGẪU NHIÊN (Giữ nguyên) ---
      float dienKWh = baseElec + (random(0, 200) / 10.0) + (readingCount * 10.0);
      float nuocM3 = baseWater + (random(0, 20) / 10.0) + (readingCount * 0.5);

      // --- (MỚI) KIỂM TRA NGƯỠNG VÀ BẬT LED ---
      if (dienKWh > ele_threshold) {
        digitalWrite(LED_PIN, HIGH); // Bật LED nếu vượt ngưỡng
      } else {
        digitalWrite(LED_PIN, LOW); // Tắt LED nếu dưới ngưỡng
      }

      // --- ĐỊNH DẠNG DỮ LIỆU MỚI (Giữ nguyên định dạng cũ) ---
      // "Timestamp;Dien:gia_tri;Nuoc:gia_tri"
      String dataToSend = String(timestamp) + ";Dien:" + String(dienKWh, 2) + ";Nuoc:" + String(nuocM3, 2);

      pDataCharacteristic->setValue(dataToSend.c_str());
      pDataCharacteristic->notify();

      Serial.print("Đã gửi cho tháng " + String(currentMonth) + ": ");
      Serial.println(dataToSend);
      Serial.print("   -> (Ngưỡng hiện tại: " + String(ele_threshold) + " | ");
      Serial.println(dienKWh > ele_threshold ? "VƯỢT NGƯỠNG)" : "TRONG NGƯỠNG)");

      // --- CHUYỂN SANG THÁNG MỚI (Giữ nguyên) ---
      if (readingCount >= readingsPerMonth) {
        readingCount = 0;
        currentMonth++; 
        if (currentMonth > 12) {
          currentMonth = 1;
        }
        baseElec = random(80, 300);
        baseWater = random(8, 25);
        Serial.println("------------------------------------");
        Serial.println("Chuyển sang tháng " + String(currentMonth));
        Serial.println("------------------------------------");
      }
    }
  }

  // (SỬA ĐỔI) Nếu không kết nối, không làm gì cả
  // việc quảng cáo lại đã được xử lý trong onDisconnect
  delay(100); 
}