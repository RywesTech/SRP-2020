#include <SD.h>

void logData() { // dataLogTemp --> permanent storage
  String ds = ""; //ds = dataString
  ds += millis();
  ds += ";";
  ds += String(armed);
  ds += ";";
  ds += String(dropped);
  ds += ";";
  ds += String(fireing);
  ds += ";";
  ds += String(alt);
  ds += ";";
  ds += String(groundAlt);
  ds += ";";
  ds += String(alt - groundAlt);
  ds += ";";
  ds += String(pressure);
  ds += ";";
  ds += String(pitch);
  ds += ";";
  ds += String(yaw);
  ds += ";";
  ds += String(roll);
  ds += ";";
  ds += String(cal_s);
  ds += ";";
  ds += String(cal_g);
  ds += ";";
  ds += String(cal_a);
  ds += ";";
  ds += String(cal_m);
  ds += ";";
  ds += String(x_p);
  ds += ";";
  ds += String(x_i);
  ds += ";";
  ds += String(x_d);
  ds += ";";
  ds += String(x_pid);
  ds += ";";
  ds += String(y_p);
  ds += ";";
  ds += String(y_i);
  ds += ";";
  ds += String(y_d);
  ds += ";";
  ds += String(y_pid);
  ds += ";";
  ds += String(pyro_voltage);


  char filename[filenameStr.length() + 1];
  filenameStr.toCharArray(filename, sizeof(filename));

  File dataFile = SD.open(filename, FILE_WRITE);
  
  if (dataFile) {
    dataFile.println(ds);
    dataFile.close();
  } else {
    Serial.println(F("ERROR: opening thrust.txt"));
  }
}
