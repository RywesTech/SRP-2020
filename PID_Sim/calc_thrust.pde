float calcThrust(int millis) {
  float[] times = {};
  float[] thrusts = {};

  for (TableRow row : thrust.rows()) {
    times = append(times, row.getFloat("time"));
    thrusts = append(thrusts, row.getFloat("thrust"));
  }

  int currentCheckTime = 0;
  int currentCheckIndex = 0;

  while (currentCheckTime < millis && currentCheckIndex < times.length) {
    currentCheckTime = int(times[currentCheckIndex] * 1000);

    if (currentCheckTime == millis) {
      return thrusts[currentCheckIndex];
    } else {
      if (currentCheckIndex > 0) {
        float nextVal = thrusts[currentCheckIndex];
        float nextMillis = times[currentCheckIndex] * 1000;
        float lastVal = thrusts[currentCheckIndex - 1];
        float lastMillis = times[currentCheckIndex - 1] * 1000;
        float slope = (nextVal-lastVal)/(nextMillis - lastMillis); // y2-y1/x2-x1
        float thrust = slope * (millis - lastMillis) + lastVal; // y=m(x-x1)+y1
        if (currentCheckTime > millis) {
          return(thrust);
        }
      }
    }
    currentCheckIndex++;
  }
  return 0;
}
