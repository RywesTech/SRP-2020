int lastHBSentMillis = 0;

void updateHeartBeat() {
  int currentMillis = millis();

  if (currentMillis - lastHBSentMillis >= 100) { //500
    String out = "";
    out += String(s_alt);
    out += "\t";
    out += String(cal_s) + ", " + String(cal_g) + ", " + String(cal_a) + ", " + String(cal_m);
    out += "\t";
    out += String(s_pitch);
    out += "\t";
    out += String(s_yaw);
    out += "\t";
    out += String(pyro_voltage);
    out += "\t";
    out += String(flight_voltage);


    telemetry.println(out);
    lastHBSentMillis = currentMillis;
    if (armed) {
      tone(p_buzzer, 2000, 20);
    }
  }
}

void checkTelemetryInput() {
  int incomingByte;
  if (telemetry.available() > 0) {
    incomingByte = telemetry.read();
    telemetry.println(incomingByte, DEC);
    if (incomingByte == 97) {
      arm();
    } else if (incomingByte == 111) {
      UAVopen();
    } else if (incomingByte == 99) {
      UAVclose();
    } else if (incomingByte == 100) {
      disarm();
    } else if (incomingByte == 98) {
      calAlt();
    } else if (incomingByte == 114) {
      toggleCam();
    } else if(incomingByte == 102){
      fire();
    }
  }
}
