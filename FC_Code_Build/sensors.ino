void updateSensorVars() {
  updateBaro();
  updateIMU();

  // Voltages
  pyro_voltage = (analogRead(p_pyroVoltage) * 0.00322265625)/(47.6/(20.19+47.6));
  flight_voltage = (analogRead(p_flightVoltage) * 0.00322265625)/(47.6/(20.19+47.6));
}


void updateBaro() {
  if (!bmp.performReading()) {
    telemetry.println("Failed to read altitude.");
  }
  s_temp = bmp.temperature;
  s_pressure = bmp.pressure / 100.0;
  s_altASL = bmp.readAltitude(seaPressure);
  s_alt = s_altASL - groundAlt;
}


void updateIMU(){
  imu::Vector<3> euler = bno.getVector(Adafruit_BNO055::VECTOR_EULER);
  s_pitch = euler.y() - pitchOffset;
  s_yaw = -euler.z() - yawOffset;
  s_roll = euler.x();

  uint8_t system, gyro, accel, mag = 0;
  bno.getCalibration(&system, &gyro, &accel, &mag);
  cal_s = system;
  cal_g = gyro;
  cal_a = accel;
  cal_m = mag;
}



void calAlt() {
  telemetry.println("Calibrating barometer");

  updateBaro(); // clean the feed
  delay(100);

  int countItterations = 10;
  float avgCount = 0;

  for (int i = 0; i <= countItterations - 1; i++) {
    updateBaro();
    avgCount += s_altASL;
    telemetry.println("Reading " + String(i + 1) + ": " + String(s_altASL));
    delay(100);
  }

  groundAlt = avgCount / countItterations;

  Serial.print("Ground level taken: ");
  Serial.print(groundAlt);
  Serial.println("m ASL");

}
