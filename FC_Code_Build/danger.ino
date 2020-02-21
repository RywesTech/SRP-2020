void arm() {
  armed = true;
  HWSERIAL.println("arm");
  tone(p_buzzer, 500, 250);
}

void disarm() {
  armed = false;
  HWSERIAL.println("dis-arm");
  tone(p_buzzer, 1500, 250);  
}

void fire() {
  if(armed){
    fireing = true;
    fired = true;
    fireStart = millis();
  }
}

void drop(){
  // SEND COMMAND TO DROP
  dropped = true;
  dropped_millis = millis();
}

void open(){
  digitalWrite(30, HIGH);
}

void close(){
  digitalWrite(30, LOW);
}
