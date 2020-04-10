void updatePIDs() {
  float x_error = s_pitch;
  float y_error = s_yaw;
  float dt = (millis() - prev_ms) / 1000.0; // time difference in seconds

  x_p = x_error;
  y_p = y_error;

  if (fired) {
    x_i = prev_x_i + (x_error * dt);
    y_i = prev_y_i + (y_error * dt);
  }

  x_d = (x_error - prev_x_error) / dt;
  y_d = (y_error - prev_y_error) / dt;

  prev_x_error = x_error;
  prev_y_error = y_error;
  prev_x_i = x_i;
  prev_y_i = y_i;
  prev_ms = millis();

  x_pid = (x_p * kp) + (x_i * ki) + (x_d * kd);
  y_pid = (y_p * kp) + (y_i * ki) + (y_d * kd);
}
