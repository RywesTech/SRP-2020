/*
 * PINS:
 * 0:
 * 1:  
 * 2:  TVC X Output
 * 3:  TVC Y Output
 * 4:  Pyro 1
 * 5:  Pyro 2
 * 6:  Pyro 3
 * 7:  
 * 8:  433Mhz Radio
 * 9:  915Mhz Radio
 * 10: 915Mhz Radio
 * 11: 
 * 12: 
 * 13: Onboard LED
 * 14: LiPo (Flight) read
 * 15: LiPo (Pyro) read
 * 16: TVC X Input
 * 17: TVC Y Input
 * 18: I2C SDA
 * 19: I2C SCL
 * 20: Buzzer
 * 21: LED
 * 22:
 * 23:
 */

// Complies on 1.8.10 for Teensy 3.6

#include <SD.h>
#include <SPI.h>
#include <Wire.h>
#include <Servo.h>
#include <Adafruit_Sensor.h> // BMP
#include <Adafruit_BMP280.h> // BMP
#include <SparkFunLSM9DS1.h> // IMU
#include "SensorFusion.h"
#include <PID_v1.h>


// UPDATE BEFORE FLIGHT:
#define DECLINATION -8.58 // Declination (degrees) in Boulder, CO. //change this
const float pressAtSeaLevel = 1013.25;
const int accelScale = 2; //2, 4, 8, or 16g's
float releaseAlt = 13; //12.5 //14 //26
const int ignitionDelay = 1300; //ms from drone drop // 1400
float dropSafetyMargin = 2; //2 // how many meters the rocekt must be below the drone to fire

//Datalog:
const int SD_CS = BUILTIN_SDCARD;

// Objects:
Servo roll0, roll1;
Servo pitch0, pitch1;
LSM9DS1 imu;
SF fusion;
Adafruit_BMP280 bme;

#define LSM9DS1_M  0x1E // Would be 0x1C if SDO_M is LOW
#define LSM9DS1_AG  0x6B // Would be 0x6A if SDO_AG is LOW

//Servo offsets:
float p0offset = 91;
float p1offset = 74;
float r0offset = 84;
float r1offset = 71;
int maxServoAngle = 50;

//Pins:
const int bluePin     = 2;
const int redPin      = 3;
const int greenPin    = 4;
const int firePinR    = 6; // Roll
const int firePinP    = 7; // Pitch
const int dropServoPin = 8;
const int roll0Pin    = 9;
const int roll1Pin    = 10;
const int pitch0Pin   = 11;
const int pitch1Pin   = 12;
const int bootLEDPin  = 13;
const int armPin      = 16;

// arm pins:
int lastMillisNotPressed;
int armTime = 1500; // time needed to hold down arm button
int armStartTime; // when the arm starteds
boolean armed = false;

// Process vars
int bootTime;
float temp, pressure, alt;
float axg, ayg, azg;
float gx, gy, gz;
float mx, my, mz;
float pitch, yaw, roll;
float deltat;
int roll0Angle, roll1Angle, pitch0Angle, pitch1Angle;
float pitchCalibrationOffset, rollCalibrationOffset;
float groundAlt;

// PID vals:
const double Kp = 1.7; // 1.5 // 1.9 // 2.0
const double Ki = 0.3; // 0.3 // 0.3 // 0.3
const double Kd = 0.9; // 0.95 // 0.8 // 0.7
double setpoint = 0.0;
double pitchInput = 0.0;
double pitchOutput = 0.0;
double rollInput = 0.0;
double rollOutput = 0.0;

PID pitchPID(&pitchInput, &pitchOutput, &setpoint, Kp, Ki, Kd, DIRECT);
PID rollPID(&rollInput, &rollOutput, &setpoint, Kp, Ki, Kd, DIRECT);

// Fire params
const int fireTime = 1250; // How long to hold the charge on the fire pin (in millis)
bool fireing = false;
bool ignited = false;
bool fired = false;
long startMillis = 0;

Servo dropServo;
int dropServoOpen = 140;
int dropServoClosed = 20;
int dropServoStatusOpen = false;
int dropTime;
bool dropped = false;

void setup() {
  // put your setup code here, to run once:
  delay(2000);
  Serial.begin(9600);
  Serial.println("BOOT START V2.2");

  pinMode(firePinR, OUTPUT);
  pinMode(firePinP, OUTPUT);
  pinMode(redPin, OUTPUT);
  pinMode(greenPin, OUTPUT);
  pinMode(bluePin, OUTPUT);
  pinMode(bootLEDPin, OUTPUT);
  pinMode(armPin, INPUT);

  digitalWrite(firePinR, HIGH); // OFF
  digitalWrite(firePinP, HIGH); // OFF

  digitalWrite(greenPin, HIGH);
  digitalWrite(redPin, LOW);
  digitalWrite(bluePin, LOW);
  digitalWrite(bootLEDPin, HIGH);

  dropServo.attach(dropServoPin);
  dropServo.write(dropServoClosed);

  pitch0.attach(pitch0Pin);
  pitch1.attach(pitch1Pin);
  roll0.attach(roll0Pin);
  roll1.attach(roll1Pin);

  // Zero the servos:
  pitch0.write(p0offset);
  pitch1.write(p1offset);
  roll0.write(r0offset);
  roll1.write(r1offset);

  //PID Setup:
  pitchPID.SetMode(AUTOMATIC);
  rollPID.SetMode(AUTOMATIC);
  pitchPID.SetOutputLimits(-90, 90);
  rollPID.SetOutputLimits(-90, 90);

  // Init SD card:
  if (!SD.begin(SD_CS)) {
    Serial.println("ERROR: SD Failed");
    digitalWrite(greenPin, LOW);
    digitalWrite(redPin, HIGH);
    while (1);
  }
  Serial.println("PASS: SD Card hardware");

  // Set up file for datalogging:
  String dataString = "\n -- SYSTEM INITIATED, NEW DATALOG -- ";
  File dataFile = SD.open("flight.txt", FILE_WRITE);

  if (dataFile) {
    dataFile.println(dataString);
    dataFile.close();
  } else {
    digitalWrite(greenPin, LOW);
    digitalWrite(redPin, HIGH);
    Serial.println("ERROR: SD Card software");
    while (1);
  }
  Serial.println("PASS: SD Card software");

  // Barometer check
  if (!bme.begin()) {
    Serial.println("ERROR: BMP280");
    digitalWrite(redPin, HIGH);
    //while (1);
  }
  Serial.println("PASS: BMP280");

  // IMU init
  imu.settings.device.commInterface = IMU_MODE_I2C;
  imu.settings.device.mAddress = LSM9DS1_M;
  imu.settings.device.agAddress = LSM9DS1_AG;
  imu.settings.accel.scale = accelScale;

  if (!imu.begin()) {
    Serial.println("ERROR: IMU");
    while (1);
  }
  Serial.println("PASS: IMU");

  calAlt();

  digitalWrite(greenPin, LOW);

  Serial.print("BOOT COMPLETE. Total startup time: ");
  bootTime = millis();
  Serial.println(bootTime);
}

void loop() {

  updateSensorVars();
  updateFusion();

  if (alt >= groundAlt + releaseAlt && !dropped) {
    drop();
    dropped = true;
    Serial.println("DROPPING");
  }

  if (millis() >= dropTime + ignitionDelay && dropped && !fired) {
    Serial.println("Attempt firing...");
    if (alt < groundAlt + releaseAlt - dropSafetyMargin) {
      fire(); //FIRE
      ignited = true;
    } else {
      Serial.println("ERROR: Alt safety margin");
    }
  }

  if (fireing) {
    unsigned long currentMillis = millis();
    if (currentMillis - startMillis < fireTime) {
      digitalWrite(firePinR, LOW); //ON
      digitalWrite(firePinP, LOW); //ON
      fired = true;
    } else {
      fireing = false;
    }
  } else {
    digitalWrite(firePinR, HIGH); //OFF
    digitalWrite(firePinP, HIGH); //OFF
  }

  pitch = fusion.getPitch() - pitchCalibrationOffset;
  roll = fusion.getRoll() - rollCalibrationOffset;
  yaw = fusion.getYaw();

  pitchInput = double(pitch);
  rollInput = double(roll);

  if (fired) {
    pitchPID.Compute();
    rollPID.Compute();
  }

  roll0Angle  = constrain(r0offset - rollOutput, r0offset - maxServoAngle, r0offset + maxServoAngle);
  roll1Angle  = constrain(r1offset + rollOutput, r1offset - maxServoAngle, r1offset + maxServoAngle);
  pitch0Angle = constrain(p0offset - pitchOutput, p0offset - maxServoAngle, p0offset + maxServoAngle);
  pitch1Angle = constrain(p1offset + pitchOutput, p1offset - maxServoAngle, p1offset + maxServoAngle);

  Serial.print("Pitch: " + String(pitch));
  Serial.print(", Roll: " + String(roll));
  Serial.println(", Alt: " + String(alt - groundAlt));

  pitch0.write(pitch0Angle);
  pitch1.write(pitch1Angle);
  roll0.write(roll0Angle);
  roll1.write(roll1Angle);

  if (Serial.available() > 0) {
    String incoming = Serial.readString();

    if (incoming.equals("c")) { // calibrate IMU

      float pitchAccumulator = 0;
      float rollAccumulator = 0;
      int calibrateCount = 10;
      Serial.println("Starting cal...");
      for (int i = 0; i < calibrateCount; i++) {
        updateSensorVars();
        updateFusion();
        pitchAccumulator += fusion.getPitch();
        rollAccumulator += fusion.getRoll();

        Serial.println("Pitch: " + String(fusion.getPitch()) + ", roll: " + String(fusion.getRoll()));

        delay(250);
      }
      pitchCalibrationOffset = pitchAccumulator / calibrateCount;
      rollCalibrationOffset = rollAccumulator / calibrateCount;
      Serial.println("pOffset: " + String(pitchCalibrationOffset) + ", rOffset: " + String(rollCalibrationOffset));

      calAlt();
    } else if (incoming.equals("s")) { // Set servo vals
      Serial.println("Starting servo position calibration...");

      Servo servos[4] = {pitch0, pitch1, roll0, roll1};
      float offsets[4] = {p0offset, p1offset, r0offset, r1offset};
      String names[4] = {"P0", "P1", "R0", "R1"};

      for (int i = 0; i < sizeof(servos); i++) {

        boolean calibratingSero = true;

        Serial.println("Input offset for " + names[i] + ", then send any letter");
        while (calibratingSero) {

          while (!Serial.available() ) {}
          int offsetInput = Serial.readString().toFloat();
          if (offsetInput == 0) { // not a number
            calibratingSero = false;
            Serial.println();
          } else {
            offsets[i] = offsetInput;
            servos[i].write(offsets[i]);
            Serial.println(offsetInput);
          }
        }
      }
    } else if (incoming.equals("d")) {
      drop();
    } else if (incoming.equals("r")) {
      resetServo();
    }
  }

  logData();

}

void fire() {
  Serial.println("FIRE START");
  fireing = true;
  startMillis = millis();
}


void drop() {
  dropServo.write(dropServoOpen);
  dropServoStatusOpen = true;
  dropTime = millis();
}

void resetServo() {
  dropServo.write(dropServoClosed);
  dropServoStatusOpen = false;
}

void updateFusion() {
  deltat = fusion.deltatUpdate();
  fusion.MahonyUpdate(-gx * DEG_TO_RAD, -gy * DEG_TO_RAD, -gz * DEG_TO_RAD, axg, ayg, azg, deltat);
}

void calAlt() {
  Serial.println("Start launch level calc.");

  alt = bme.readAltitude();
  delay(100);

  int countItterations = 10;
  float levels[countItterations];

  for (int i = 0; i <= countItterations; i++) {
    alt = bme.readAltitude();
    levels[i] = alt;
    delay(100);
    Serial.println(alt);
  }

  float avgCount = 0;
  for (int i = 0; i <= countItterations; i++) {
    avgCount += levels[i];
  }
  Serial.print("AVG");
  Serial.println(avgCount);
  groundAlt = avgCount / 11;

  Serial.print("Start level taken: ");
  Serial.print(groundAlt);
  Serial.println("m");

}
