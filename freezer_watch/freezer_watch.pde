#include <Wire.h>
#include <OneWire.h>
#include <DallasTemperature.h> 
#include <NewSoftSerial.h>
#include <LCD117.h>
#include <RTClib.h>

#define DPIN_ONE_WIRE 2
#define DPIN_LED 11
#define DPIN_LCD_TX 6
#define DPIN_LCD_RX 5
#define DPIN_HALL_PWR 3
#define DPIN_HALL_DATA 4
#define APIN_PHOTOCELL 0
#define DELAY 100

#define LCD_NUM_ROWS 2
#define LCD_NUM_COLS 16

OneWire oneWire(DPIN_ONE_WIRE);
DallasTemperature sensors(&oneWire);
DeviceAddress insideThermometer  = { 0x28, 0x5F, 0x7F, 0x77, 0x03, 0x00, 0x00, 0xDC };
DeviceAddress outsideThermometer = { 0x28, 0x57, 0x6B, 0x77, 0x03, 0x00, 0x00, 0x1E };

LCD117 lcd = LCD117(LCD_NUM_COLS, LCD_NUM_ROWS);

RTC_DS1307 rtc;

int brightness, hallEffect;
float tempInsideC, tempOutsideC;

char buffer[20];

void setup(void) {
  Serial.begin(57600);
  
  Wire.begin();
  
  lcd.begin(DPIN_LCD_TX, DPIN_LCD_RX);
  lcd.clearLCD();
  lcd.hideCursor();
  
  sensors.begin();
  
  pinMode(DPIN_HALL_PWR, OUTPUT); 
  pinMode(DPIN_HALL_DATA, INPUT); 
  
  rtc.begin();
  if (!rtc.isrunning()) {
    //rtc.adjust(DateTime(__DATE__, __TIME__));
  }
  
}

void loop(void) {
  
  brightness = readPhotocell(APIN_PHOTOCELL);
  analogWrite(DPIN_LED, brightness);
  
  hallEffect = readHallEffectSensor(DPIN_HALL_PWR, DPIN_HALL_DATA);
  
  sensors.requestTemperatures();
  tempInsideC = readTempAsC(insideThermometer);
  tempOutsideC = readTempAsC(outsideThermometer);
  
  Serial.print("Reading = ");
  Serial.print(brightness);
  Serial.print(", ");
  Serial.print(hallEffect);
  Serial.print(", in=");
  Serial.print(tempInsideC);
  Serial.print("C (");
  Serial.print(DallasTemperature::toFahrenheit(tempInsideC));
  Serial.print("F), out=");
  Serial.print(tempOutsideC);
  Serial.print("C (");
  Serial.print(DallasTemperature::toFahrenheit(tempOutsideC));
  Serial.println("F)");
  
  lcd.setCursor(0, 0);
  lcd.print("F:");
  lcd.print(dtostrf(DallasTemperature::toFahrenheit(tempInsideC), 5, 1, buffer));
  lcd.print("F");
  lcd.setCursor(0, 1);
  lcd.print("O:");
  lcd.print(dtostrf(DallasTemperature::toFahrenheit(tempOutsideC), 5, 1, buffer));
  lcd.print("F");
  
  DateTime now = rtc.now();
  lcd.setCursor(11, 0);
  lcd.print(dtostrf(now.hour(), 2, 0, buffer));
  lcd.print(":");
  if (now.minute() < 10) { 
    lcd.print("0"); 
    lcd.print(dtostrf(now.minute(), 1, 0, buffer));
  } else {
    lcd.print(dtostrf(now.minute(), 2, 0, buffer));
  }

  lcd.setCursor(12, 1);
  if (hallEffect == 0 || brightness > 25) {
    lcd.print("OPEN");
  } else if (brightness > 10) {
    lcd.print("AJAR");
  } else {
    lcd.print("    ");
  }
  
  delay(DELAY);
}

int readHallEffectSensor(int powerPin, int dataPin) {
  digitalWrite(powerPin, HIGH);
  delay(50);
  int val = digitalRead(dataPin);
  digitalWrite(powerPin, LOW);
  return val;
}

int readPhotocell(int photocellPin) {
  return map(1023 - analogRead(photocellPin), 0, 1023, 0, 255);
}

float readTempAsC(DeviceAddress deviceAddress) {
  return sensors.getTempC(deviceAddress);
}

