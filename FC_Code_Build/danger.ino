void arm() {
  armed = true;
  if(!recording){
    toggleCam();
  }
  telemetry.println("arm");
  tone(p_buzzer, 500, 250);
}

void disarm() {
  armed = false;
  telemetry.println("dis-arm");
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
  dropped = true;
  dropped_millis = millis();
}

void updateUAV() { // Keep the UAV mount open for 2 seconds after dropping. This way, if the rocket doesn't fall at first it won't fall after the drone gets way too high
  if(dropped){
    if(dropped_millis >= millis() - 2000){
      UAVopen();
    }else{
      UAVclose();
    }
  }
}

void UAVopen(){
  digitalWrite(p_drop, HIGH);
}

void UAVclose(){
  digitalWrite(p_drop, LOW);
}

void updateIgnitor() {
  if (fireing && armed) {
    digitalWrite(p_pyro2, HIGH);
    tone(p_buzzer, 500, 10);
  } else {
    digitalWrite(p_pyro2, LOW);
  }
}
