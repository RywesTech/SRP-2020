#include <SPI.h>
#include <SD.h>
#include "HX711.h"

// Scale values:
#define DOUT 3
#define CLK 2

HX711 scale(DOUT, CLK);

float calibration_factor = -423288; //192000 for lbs

//Datalog:
const int SD_CS = 53; //BUILTIN_SDCARD
const int input = A9;

String filenameStr = "";

void setup() {
  // put your setup code here, to run once:
  Serial.begin(57600);
  pinMode(input, INPUT);
  pinMode(13, OUTPUT);

  delay(1000);
  scale.set_scale();
  scale.tare();

  long zero_factor = scale.read_average(); //Get a baseline reading
  Serial.print("Zero factor: "); //This can be used to remove the need to tare the scale. Useful in permanent scale projects.
  Serial.println(zero_factor);

  Serial.print("Scale init time: ");
  Serial.println(millis());

  // Init SD card:
  if (!SD.begin(SD_CS)) {
    Serial.println(F("ERROR: Card failed, or not present"));
    while (1);
  }
  Serial.println(F("SUCCESS: SD card initialized."));

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

  scale.set_scale(calibration_factor); //Adjust to this calibration factor
  Serial.print(F("Starting! Total boot time: "));
  Serial.println(millis());
}

void loop() {
  digitalWrite(13, HIGH);
  float weight = scale.get_units(); // this is what takes ~80ms (LONG time)

  // Datalog:
  String dataString = "";
  dataString += millis();
  dataString += ";";
  dataString += String(weight);
  dataString += ";";
  dataString += String(calibration_factor);
  dataString += ";";
  dataString += String(analogRead(input));

  char filename[filenameStr.length() + 1];
  filenameStr.toCharArray(filename, sizeof(filename));
  File dataFile = SD.open(filename, FILE_WRITE);
  
  if (dataFile) {
    dataFile.println(dataString);
    dataFile.close();
  } else {
    Serial.println("error opening " + filenameStr);
  }

  //Calibration factor
  if (Serial.available()) {
    char temp = Serial.read();
    if (temp == '+' || temp == 'a') {
      calibration_factor += 100;
      scale.set_scale(calibration_factor);
      Serial.println(calibration_factor);
    } else if (temp == '-' || temp == 'z') {
      calibration_factor -= 100;
      scale.set_scale(calibration_factor);
      Serial.println(calibration_factor);
    }
  } 

  Serial.println(String(weight) + " Kg");

}
