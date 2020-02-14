void logData() { // dataLogTemp --> permanent storage
  String ds = ""; //ds = dataString
  ds += millis();
  ds += ";";
  ds += String(roll);
  ds += ";";
  ds += String(pitch);
  ds += ";";
  ds += String(temp);
  ds += ";";
  ds += String(pressure);
  ds += ";";
  ds += String(alt);
  ds += ";";
  ds += String(axg);
  ds += ";";
  ds += String(ayg);
  ds += ";";
  ds += String(azg);
  ds += ";";
  ds += String(gx);
  ds += ";";
  ds += String(gy);
  ds += ";";
  ds += String(gz);
  ds += ";";
  ds += String(mx);
  ds += ";";
  ds += String(my);
  ds += ";";
  ds += String(mz);
  ds += ";";
  ds += String(roll0Angle);
  ds += ";";
  ds += String(roll1Angle);
  ds += ";";
  ds += String(pitch0Angle);
  ds += ";";
  ds += String(pitch1Angle);
  ds += ";";
  ds += String(groundAlt);
  ds += ";";
  ds += String(fireing);
  ds += ";";
  ds += String(dropped);
  
  // Log to SD:
  File dataFile = SD.open("flight.txt", FILE_WRITE);
  if (dataFile) {
    digitalWrite(bluePin, HIGH);

    dataFile.println(ds);
    dataFile.close();
    //Serial.println("DATA LOGGED");

    digitalWrite(bluePin, LOW);
  } else {
    digitalWrite(redPin, HIGH);
    Serial.println(F("ERROR: opening thrust.txt"));
  }
}
