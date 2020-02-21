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
   16: TVC X Input
   17: TVC Y Input
   18: I2C SDA
   19: I2C SCL
   20: Buzzer
   21:
   22:
   23:
   30: 433Mhz Radio
*/
// Complies on 1.8.10 for Teensy 3.5/6

/*
   Commands:
   a: arm
   o: open drop motor
   c: close drop motor
   d: disarm
   b: calibrate barometer
   r: toggel recording
*/

#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include <Adafruit_Sensor.h>
#include <Servo.h>
#include "Adafruit_BMP3XX.h"
#include <Adafruit_BNO055.h>
#include <utility/imumaths.h>

#define SEALEVELPRESSURE_HPA (1013.25)
#define HWSERIAL Serial2

Adafruit_BNO055 bno = Adafruit_BNO055(-1, 0x28);
Adafruit_BMP3XX bmp;

Servo x, y;

/*
   UPDATE THESE:
*/
float releaseAlt = 2; //58.6
float ignAlt = 1; //34.9
float x_neutral = 90;
float y_neutral = 90;
const double kp = 0.28;
const double ki = 0.08;
const double kd = 0.13;
/*
   DONE
*/

int bootTime;
float temp, pressure, alt;
float axg, ayg, azg;
float gx, gy, gz;
float mx, my, mz;
float pitch, yaw, roll;
int cal_s, cal_g, cal_a, cal_m;

int maxServoAngle = 30;

float x_p, x_i, x_d;
float y_p, y_i, y_d;

bool armed = false;
bool fireing = false;
bool fired = false;
int fireStart = 0;

float groundAlt;
bool dropped = false;

float pyro_voltage = 0;

int fireLength = 1250;

const int x_out = 2;
const int y_out = 3;
const int p_pyro1 = 4;
const int p_pyro2 = 5;
const int p_pyro3 = 6;
const int p_buzzer = 20;
const int x_in = 16;
const int y_in = 17;
const int pyro_v_read = 15;
const int p_aux = 11;

const char* initLogNo;
const int SD_CS = BUILTIN_SDCARD;
String filenameStr = "";

int dropped_millis = 0;

void setup() {
  tone(p_buzzer, 1000, 500);
  delay(500);

  HWSERIAL.begin(57600);
  Serial.begin(57600);
  HWSERIAL.println("BOOT START V4.0.0");
  
  pinMode(30, OUTPUT);
  digitalWrite(30, LOW);

  x.attach(x_out);
  x.write(x_neutral);
  y.attach(y_out);
  y.write(x_neutral);

  pinMode(p_buzzer, OUTPUT);
  pinMode(p_pyro1, OUTPUT);
  pinMode(p_pyro2, OUTPUT);
  pinMode(p_pyro3, OUTPUT);
  pinMode(x_in, INPUT);
  pinMode(y_in, INPUT);
  pinMode(pyro_v_read, INPUT);
  pinMode(p_aux, OUTPUT);

  if (!bno.begin()) {
    HWSERIAL.println("No BNO055 detected.");
    while (1);
  }

  if (!bmp.begin()) {
    HWSERIAL.println("No BMP388 detected.");
    while (1);
  }

  if (!SD.begin(SD_CS)) {
    HWSERIAL.println("NO SD detected.");
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

  bmp.setTemperatureOversampling(BMP3_OVERSAMPLING_8X);
  bmp.setPressureOversampling(BMP3_OVERSAMPLING_4X);
  bmp.setIIRFilterCoeff(BMP3_IIR_FILTER_COEFF_3);
  bmp.setOutputDataRate(BMP3_ODR_50_HZ);

  calAlt();

  bno.setExtCrystalUse(true);

  tone(p_buzzer, 1250, 500);
}

float prev_x_error, prev_x_i;
float prev_y_error, prev_y_i;
float prev_ms;
float x_pid, y_pid;

int incomingByte = 0;

void loop() {

  updateSensorVars();

  //TVC:
  float x_error = pitch;
  float y_error = yaw;
  float dt = (millis() - prev_ms) / 1000.0; // time difference in seconds

  x_p = x_error;
  y_p = y_error;
  
  x_d = (x_error - prev_x_error) / dt;
  y_d = (y_error - prev_y_error) / dt;
  
  if (fired) {
    x_i = prev_x_i + (x_error * dt);
    y_i = prev_y_i + (y_error * dt);
  }

  prev_x_error = x_error;
  prev_y_error = y_error;
  prev_x_i = x_i;
  prev_y_i = y_i;
  prev_ms = millis();

  x_pid = (x_p * kp) + (x_i * ki) + (x_d * kd);
  y_pid = (y_p * kp) + (y_i * ki) + (y_d * kd);

  int x_write = constrain((x_pid * 6) + x_neutral, x_neutral - maxServoAngle, x_neutral + maxServoAngle);
  int y_write = constrain((y_pid * 6) + y_neutral, y_neutral - maxServoAngle, y_neutral + maxServoAngle);

  if(dropped){
    x.write(x_write);
    y.write(y_write);
    if(dropped_millis >= millis() - 2000){
      open();
    }else{
      close();
    }
  }else{
    x.write(x_neutral);
    y.write(y_neutral);
  }
  
  //Ign stuff:
  if (alt >= groundAlt + releaseAlt && !dropped && armed) {
    drop();
  }

  if (alt <= groundAlt + ignAlt && dropped && !fireing && armed) {
    fire();
  }

  if (fireing && armed) {
    digitalWrite(p_pyro2, HIGH);
    tone(p_buzzer, 500, 10);
  } else {
    digitalWrite(p_pyro2, LOW);
  }

  if (fireing && fireStart + fireLength < millis()) {
    fireing = false;
    armed = false;
    tone(p_buzzer, 800, 100);
  }
  
  if (!dropped) { // While we're falling it's all hands on deck for stabalization
    updateHeartBeat();

    int incomingByte;
    
    if (HWSERIAL.available() > 0) {
      incomingByte = HWSERIAL.read();
      HWSERIAL.println(incomingByte, DEC);
      if (incomingByte == 97) { // a for arm
        arm();
      } else if (incomingByte == 111){
        open();
      } else if (incomingByte == 99){
        close();
      } else if (incomingByte == 100){
        disarm();
      } else if (incomingByte == 98){
        calAlt();
      }else if (incomingByte == 114){
        digitalWrite(p_aux, HIGH);
        delay(750);
        digitalWrite(p_aux, LOW);
      }
    }
    
  }

  logData();
}



void updateSensorVars() {
  // Barometer
  if (!bmp.performReading()) {
    HWSERIAL.println("Failed to read altitude.");
    return;
  }
  temp = bmp.temperature;
  pressure = bmp.pressure / 100.0;
  alt = bmp.readAltitude(SEALEVELPRESSURE_HPA);

  // IMU
  imu::Vector<3> euler = bno.getVector(Adafruit_BNO055::VECTOR_EULER);
  pitch = euler.y();
  roll = euler.x();
  yaw = -euler.z();

  uint8_t system, gyro, accel, mag = 0;
  bno.getCalibration(&system, &gyro, &accel, &mag);
  cal_s = system;
  cal_g = gyro;
  cal_a = accel;
  cal_m = mag;

  // Voltages
  pyro_voltage = (analogRead(pyro_v_read) * 0.00322265625)/(47.6/(20.19+47.6));
}



void calAlt() {
  Serial.println("Start launch level calc.");

  if (!bmp.performReading()) {
    Serial.println("Failed to real altitude.");
    return;
  }
  alt = bmp.readAltitude(SEALEVELPRESSURE_HPA);
  delay(100);

  int countItterations = 10;
  float levels[countItterations];

  for (int i = 0; i <= countItterations; i++) {
    if (!bmp.performReading()) {
      Serial.println("Failed to real altitude.");
      return;
    }
    alt = bmp.readAltitude(SEALEVELPRESSURE_HPA);
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
