/*
   PINS:
   0:
   1:
   2:  TVC X Output
   3:  TVC Y Output
   4:  Pyro 1
   5:  Pyro 2
   6:  Pyro 3
   7:
   8:
   9:  915Mhz Radio
   10: 915Mhz Radio
   11: Camera Control
   12:
   13: Onboard LED
   14: LiPo (Flight) read
   15: LiPo (Pyro) read
   16:
   17:
   18: I2C SDA
   19: I2C SCL
   20: Buzzer
   21:
   22:
   23:
   30: 433Mhz Radio interface
*/
// Complies on 1.8.10 for Teensy 3.5/3.6

/*
   Commands:
   a: arm
   o: open drop motor
   c: close drop motor
   d: disarm
   b: calibrate barometer
   r: toggel recording
   f: fire! (hold down only)
*/

// UPDATE BEFORE FLIGHT:
const float seaPressure = 1013.25;
const float releaseAlt = 58.6;
const float ignAlt = 34.9;
const float xNeutral = 90;
const float yNeutral = 90;
const double kp = 0.28;
const double ki = 0.08;
const double kd = 0.13;

// Includes:
#include <Servo.h>
#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include <Adafruit_Sensor.h>
#include "Adafruit_BMP3XX.h"
#include <Adafruit_BNO055.h>
#include <utility/imumaths.h>

// Defines/Objects:
#define telemetry Serial2
Adafruit_BNO055 bno = Adafruit_BNO055(-1, 0x28);
Adafruit_BMP3XX bmp;
Servo TVCx, TVCy;

// Vehicle constants:
const int maxServoAngle = 30;
const float pitchOffset = -0.19;
const float yawOffset = -0.14;
const int fireLength = 1250;

// Pins:
const int p_xServo        = 2;
const int p_yServo        = 3;
const int p_pyro1         = 4;
const int p_pyro2         = 5;
const int p_pyro3         = 6;
//        915Mhz          = 9;
//        915Mhz          = 10;
const int p_cam           = 11;
const int p_LED           = 13;
const int p_flightVoltage = 14;
const int p_pyroVoltage   = 15;
//        SDA             = 18;
//        SCL             = 19;
const int p_buzzer        = 20;
const int p_drop          = 30;
const int p_SD            = BUILTIN_SDCARD;

// Variables:
float s_temp, s_pressure, s_alt, s_altASL;
float s_ax, s_ay, s_az;
float s_gx, s_gy, s_gz;
float s_mx, s_my, s_mz;
float s_pitch, s_yaw, s_roll;

int cal_s, cal_g, cal_a, cal_m;

float x_p, x_i, x_d;
float y_p, y_i, y_d;
float x_pid, y_pid;
float prev_x_error, prev_x_i;
float prev_y_error, prev_y_i;
float prev_ms;

int bootTime;
bool armed = false;
bool fireing = false;
bool fired = false;
int fireStart = 0;
bool recording = false;

float groundAlt;
bool dropped = false;
int dropped_millis = 0;

float pyro_voltage, flight_voltage;

const char* initLogNo;
String filenameStr = "";
int incomingByte = 0;

void setup() {
  tone(p_buzzer, 1000, 500);
  delay(500);

  // Begin coms:
  Serial.begin(57600);
  telemetry.begin(57600);
  telemetry.println("BOOT START V4.1.0");

  // Begin TVC:
  TVCx.attach(p_xServo);
  TVCx.write(xNeutral);
  TVCy.attach(p_yServo);
  TVCy.write(xNeutral);

  // Set pin modes:
  pinMode(p_buzzer, OUTPUT);
  pinMode(p_pyro1, OUTPUT);
  pinMode(p_pyro2, OUTPUT);
  pinMode(p_pyro3, OUTPUT);
  pinMode(p_flightVoltage, INPUT);
  pinMode(p_pyroVoltage, INPUT);
  pinMode(p_cam, OUTPUT);
  pinMode(p_drop, OUTPUT);

  // Update UAV:
  UAVclose();

  // Init IMU:
  if (!bno.begin()) {
    telemetry.println("No BNO055 detected.");
    while (1);
  }
  bno.setExtCrystalUse(true);

  // Init Barometer:
  if (!bmp.begin()) {
    telemetry.println("No BMP388 detected.");
    while (1);
  }
  bmp.setTemperatureOversampling(BMP3_OVERSAMPLING_8X);
  bmp.setPressureOversampling(BMP3_OVERSAMPLING_4X);
  bmp.setIIRFilterCoeff(BMP3_IIR_FILTER_COEFF_3);
  bmp.setOutputDataRate(BMP3_ODR_50_HZ);

  // Init SD:
  if (!SD.begin(p_SD)) {
    telemetry.println("NO SD detected.");
    while (1);
  }

  for (int i = 1;; i++) {
    filenameStr = "data";
    filenameStr.concat(i);
    filenameStr.concat(".csv");
    char filename[filenameStr.length() + 1];
    filenameStr.toCharArray(filename, sizeof(filename));
    if (!SD.exists(filename)) {
      File myFile = SD.open(filename, FILE_WRITE);
      break;
    }
  }

  calAlt();

  tone(p_buzzer, 1250, 500);
}

void loop() {

  // Update the vectoring mount:
  updateSensorVars();
  updatePIDs();
  updateTVC();

  // Update the UAV:
  if (s_alt >= releaseAlt && !dropped && armed) {
    drop();
  }
  updateUAV();

  // Update the ignition system:
  if (s_alt <= ignAlt && dropped && !fireing && armed) {
    fire();
  }
  updateIgnitor();

  if (fireing && fireStart + fireLength < millis()) { // Disarm and stop pyro channel
    fireing = false;
    armed = false;
    tone(p_buzzer, 800, 100);
  }

  // If we're still connected,
  if (!dropped) { // While we're falling it's all hands on deck for stabalization
    updateHeartBeat();
    checkTelemetryInput();
  }

  logData();
}

void toggleCam() {
  recording = !recording;
  digitalWrite(p_cam, HIGH);
  delay(500);
  digitalWrite(p_cam, LOW);
}
