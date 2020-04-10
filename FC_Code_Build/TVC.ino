void updateTVC() {
  // Gear ratio is 6 to 1 so multiply PID value by 6
  int x_write = constrain((x_pid * 6) + xNeutral, xNeutral - maxServoAngle, xNeutral + maxServoAngle);
  int y_write = constrain((y_pid * 6) + yNeutral, yNeutral - maxServoAngle, yNeutral + maxServoAngle);

  if(dropped){
    TVCx.write(x_write);
    TVCy.write(y_write);
  }else{
    TVCx.write(xNeutral);
    TVCy.write(yNeutral);
  }
}
