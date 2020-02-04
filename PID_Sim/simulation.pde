//pitch, yaw, and roll data:
float[] torque = new float[3]; // TORQUE (N/m)
float[] accel = new float[3]; // ACCEL (º/S^2)
float[] vel = new float[3]; // VEL (º/S)
float[] pos = new float[3]; // POSITION (rad)

float[] torque_prev = new float[3]; // TORQUE (N/m)
float[] accel_prev = new float[3]; // ACCEL (º/S^2)
float[] vel_prev = new float[3]; // VEL (º/S)
float[] pos_prev = new float[3]; // POSITION (rad)

float error[] = new float[3];
float i_prev[] = new float[3];
float e_prev[] = new float[3];

float p[] = new float[3];
float i[] = new float[3];
float d[] = new float[3];

int sim_length = 5000; // simulate the first 5 seconds of flight
int sim_ms_prev = 0; // previous loop's sim ms
int sim_ms = 0; // simulation millis

float max_TVC_angle = 0.0872665; // 5º deg in radians

float[] TVC = new float[3]; // TVC position (rad)

String[] columns = {"ms", "0_torque", "0_accel", "0_vel", "0_pos", "0_output", "0_p", "0_i", "0_d", "1_torque", "1_accel", "1_vel", "1_pos", "1_output", "1_p", "1_i", "1_d"};

void runSim() {
  int startMillis = millis(); // for analytical purposes
  int endMillis; // for analytical purposes

  flight = new Table();

  for (String column : columns) {
    flight.addColumn(column);
  }

  while (sim_ms < sim_length) {
    //current_thrust = calcThrust(sim_ms);
    current_thrust = 15;

    // calculate forces applied to body, and how much torque results
    torque[0] = (sin(TVC[0]) * current_thrust) * TVC_to_CG;
    torque[1] = (sin(TVC[1]) * current_thrust) * TVC_to_CG; 
    accel[0] = torque[0] / moi;
    accel[1] = torque[1] / moi;

    // Integrate acceleration to find velocity:
    vel[0] = vel_prev[0] + (float(sim_ms - sim_ms_prev) / 1000) * ((accel[0] + accel_prev[0])/2);
    vel[1] = vel_prev[1] + (float(sim_ms - sim_ms_prev) / 1000) * ((accel[1] + accel_prev[1])/2);

    // Integrate velocity to find position:
    pos[0] = pos_prev[0] + (float(sim_ms - sim_ms_prev) / 1000) * ((vel[0] + vel_prev[0])/2);
    pos[1] = pos_prev[1] + (float(sim_ms - sim_ms_prev) / 1000) * ((vel[1] + vel_prev[1])/2);

    // calculate dt and errors:
    int dt = sim_ms - sim_ms_prev;
    error[0] = setpoint[0] - pos[0];
    error[1] = setpoint[1] - pos[1];

    // Update P, I, and D values:
    p[0] = error[0];
    p[1] = error[1];
    i[0] = i_prev[0] + (error[0] * (dt/1000.0));
    i[1] = i_prev[1] + (error[1] * (dt/1000.0));
    d[0] = (error[0] - e_prev[0]) / (dt/1000.0);
    d[1] = (error[1] - e_prev[1]) / (dt/1000.0);

    if (dt == 0) { // this helps on the first found
      d[0] = 0;
      d[1] = 0;
    }

    // This, as they say, is where the magic happens:
    float output[] = new float[2];
    output[0] = constrain((p[0] * kp) + (i[0] * ki) + (d[0] * kd), -max_TVC_angle, max_TVC_angle);
    output[1] = constrain((p[1] * kp) + (i[1] * ki) + (d[1] * kd), -max_TVC_angle, max_TVC_angle);

    TVC[0] = output[0];
    TVC[1] = output[1];

    // Save to the table:
    TableRow newRow = flight.addRow();
    newRow.setInt("ms", sim_ms);
    newRow.setFloat("0_torque", torque[0]);
    newRow.setFloat("0_accel", accel[0]);
    newRow.setFloat("0_vel", vel[0]);
    newRow.setFloat("0_pos", pos[0]);
    newRow.setFloat("0_output", output[0]);
    newRow.setFloat("0_p", p[0]);
    newRow.setFloat("0_i", i[0]);
    newRow.setFloat("0_d", d[0]);
    newRow.setFloat("1_torque", torque[1]);
    newRow.setFloat("1_accel", accel[1]);
    newRow.setFloat("1_vel", vel[1]);
    newRow.setFloat("1_pos", pos[1]);
    newRow.setFloat("1_output", output[1]);
    newRow.setFloat("1_p", p[1]);
    newRow.setFloat("1_i", i[1]);
    newRow.setFloat("1_d", d[1]);

    // Update previous values:
    torque_prev[0] = torque[0];
    torque_prev[1] = torque[1];
    accel_prev[0] = accel[0];
    accel_prev[1] = accel[1];
    vel_prev[0] = vel[0];
    vel_prev[1] = vel[1];
    pos_prev[0] = pos[0];
    pos_prev[1] = pos[1];
    sim_ms_prev = sim_ms;

    i_prev[0] = i[0];
    i_prev[1] = i[1];
    e_prev[0] = error[0];
    e_prev[1] = error[1];

    sim_ms += 1;
  }

  saveTable(flight, "data/flight.csv");

  sim_ready = true;

  endMillis = millis();
  print("Sim time: ");
  println(endMillis - startMillis);
}
