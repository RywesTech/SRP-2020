/*
 * PINS:
 * 0:
 * 1:  
 * 2:  TVC X Output
 * 3:  TVC Y Output
 * 4:  Pyro 1
 * 5:  Pyro 2
 * 6:  Pyro 3
 * 7:  
 * 8:  433Mhz Radio
 * 9:  915Mhz Radio
 * 10: 915Mhz Radio
 * 11: 
 * 12: 
 * 13: Onboard LED
 * 14: LiPo (Flight) read
 * 15: LiPo (Pyro) read
 * 16: TVC X Input
 * 17: TVC Y Input
 * 18: I2C SDA
 * 19: I2C SCL
 * 20: Buzzer
 * 21: LED
 * 22:
 * 23:
 */
 // Complies on 1.8.10 for Teensy 3.5/6

const int p_buzzer = 20;

void setup() {
  // put your setup code here, to run once:
  pinMode(p_buzzer, OUTPUT);
  tone(p_buzzer, 1000, 500);
}

void loop() {
  // put your main code here, to run repeatedly:

}
