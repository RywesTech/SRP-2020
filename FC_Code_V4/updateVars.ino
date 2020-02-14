void updateSensorVars() {
  temp = bme.readTemperature();
  pressure = bme.readPressure();
  alt = bme.readAltitude();

  if (imu.gyroAvailable()) {
    imu.readGyro();
  }
  if (imu.accelAvailable()) {
    imu.readAccel();
  }
  if (imu.magAvailable()) {
    imu.readMag();
  }

  axg = imu.calcAccel(imu.ax);
  ayg = imu.calcAccel(imu.ay);
  azg = imu.calcAccel(imu.az);

  gx = imu.calcGyro(imu.gx);
  gy = imu.calcGyro(imu.gy);
  gz = imu.calcGyro(imu.gz);

  mx = imu.calcMag(imu.mx);
  my = imu.calcMag(imu.my);
  mz = imu.calcMag(imu.mz);
}

