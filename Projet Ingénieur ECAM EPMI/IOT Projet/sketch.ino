// Christian NGATCHOU & Franc MEVENGUE

#include <OneWire.h>
#include <DallasTemperature.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// Configuration du capteur de température
#define ONE_WIRE_BUS 33
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

// Configuration du capteur à ultrasons
const int trigPin = 27;
const int echoPin = 26;
long duration;
int distance;

// Initialise l'écran LCD I2C à l'adresse 0x27 pour un écran 16 caractères et 2 lignes
LiquidCrystal_I2C lcd(0x27, 16, 2); 

void setup() {
  Serial.begin(115200);
  sensors.begin();
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  
  lcd.init(); // Initialiser l'écran LCD
  lcd.backlight(); // Allumer le rétroéclairage
}

void loop() {
  // Mesure de la température
  sensors.requestTemperatures(); 
  float temperatureC = sensors.getTempCByIndex(0);
  Serial.print("Temperature: ");
  Serial.print(temperatureC);
  Serial.println("°C");
  
  // Mesure du niveau d'eau
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  duration = pulseIn(echoPin, HIGH);
  distance = duration * 0.034 / 2;
  Serial.print("Niveau d'eau: ");
  Serial.print(distance);
  Serial.println(" cm");
  
  // Afficher les données sur l'écran LCD
  lcd.clear();
  lcd.setCursor(0, 0); // Définir le curseur au début de la première ligne
  lcd.print("Temp: ");
  lcd.print(temperatureC);
  lcd.print(" C");
  
  lcd.setCursor(0, 1); // Définir le curseur au début de la deuxième ligne
  lcd.print("Niv eau: ");
  lcd.print(distance);
  lcd.print(" cm");
  
  delay(1000); // Attendre une seconde avant de répéter la mesure
}
