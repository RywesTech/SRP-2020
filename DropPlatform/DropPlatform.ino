#include <VirtualWire.h>
#include <Servo.h>

Servo servo;
byte message[VW_MAX_MESSAGE_LEN];
byte messageLength = VW_MAX_MESSAGE_LEN;
bool drop = false;

void setup() {
  Serial.begin(9600);
  vw_set_rx_pin(3);
  vw_setup(2000);
  vw_rx_start();
  Serial.println("Value : ");
  servo.attach(2);
  servo.write(20);
  pinMode(13, OUTPUT);
}

void loop() {
  if (vw_get_message(message, &messageLength)) {
    drop = message[0];
    if(drop){
      servo.write(140);
      digitalWrite(13, HIGH);
      Serial.println("OPEN");
    }else{
      servo.write(20);
      digitalWrite(13, LOW);
      Serial.println("CLOSE");
    }
  }
}
