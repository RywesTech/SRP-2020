#include <VirtualWire.h>

int transmit = 0;

void setup() {
  vw_set_tx_pin(2);
  vw_setup(2000);
  pinMode(3, INPUT);
}

void loop() {
  if (digitalRead(3) == HIGH) {
    transmit = 1;
  } else {
    transmit = 0;
  }
  vw_send((byte *) &transmit, sizeof(transmit));
  vw_wait_tx();
}
