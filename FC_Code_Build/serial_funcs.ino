int lastHBSentMillis = 0;

void updateHeartBeat() {
  int currentMillis = millis();

  if (currentMillis - lastHBSentMillis >= 500) {
    String out = "";
    out += String(alt - groundAlt);
    out += "\t";
    out += String(cal_s) + ", " + String(cal_g) + ", " + String(cal_a) + ", " + String(cal_m);
    out += "\t";
    out += String(pitch);
    out += "\t";
    out += String(yaw);
    out += "\t";
    out += String(pyro_voltage);


    HWSERIAL.println(out);
    lastHBSentMillis = currentMillis;
    //tone(p_buzzer, 2000, 20);
  }
}
