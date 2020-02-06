

// Simulation params:
int sim_length = 8000; // simulate the first 5 seconds of flight

float max_TVC_angle = 0.0872665; // 5º deg in radians
float[] TVC = new float[3]; // TVC ang_position (rad)

float setpoint[] = {0.0, 0.0, 0.0};
float gravity = -9.80665; // m/s^2

String[] columns = {"ms", "current_thrust", 
  "0_ang_torque", "0_ang_accel", "0_ang_vel", "0_ang_pos", "0_output", "0_p", "0_i", "0_d", 
  "1_ang_torque", "1_ang_accel", "1_ang_vel", "1_ang_pos", "1_output", "1_p", "1_i", "1_d", 
  "0_lin_force", "0_lin_accel", "0_lin_vel", "0_lin_pos", 
  "1_lin_force", "1_lin_accel", "1_lin_vel", "1_lin_pos", 
  "2_lin_force", "2_lin_accel", "2_lin_vel", "2_lin_pos", 
  "0_tvc", "1_tvc"
};

void runSim(float ign_alt, float drop_alt) {
  //pitch, yaw, and roll data:
  float[] ang_torque = new float[3]; // TORQUE (N/m)
  float[] ang_accel = new float[3]; // ACCEL (º/S^2)
  float[] ang_vel = new float[3]; // VEL (º/S)
  float[] ang_pos = new float[3]; // POSITION (rad)

  float[] ang_torque_prev = new float[3]; // TORQUE (N/m)
  float[] ang_accel_prev = new float[3]; // ACCEL (º/S^2)
  float[] ang_vel_prev = new float[3]; // VEL (º/S)
  float[] ang_pos_prev = new float[3]; // POSITION (rad)

  float[] ang_error = new float[3];
  float[] ang_i_prev = new float[3];
  float[] ang_e_prev = new float[3];

  float[] ang_p = new float[3];
  float[] ang_i = new float[3];
  float[] ang_d = new float[3];

  // Linear data:
  float[] lin_force = new float[3]; // FORCE (N)
  float[] lin_accel = new float[3]; // ACCEL (m/S^2)
  float[] lin_vel = new float[3]; // VEL (m/S)
  float[] lin_pos = new float[3]; // POSITION (m)

  float[] lin_force_prev = new float[3]; // FORCE (N)
  float[] lin_accel_prev = new float[3]; // ACCEL (m/S^2)
  float[] lin_vel_prev = new float[3]; // VEL (m/S)
  float[] lin_pos_prev = new float[3]; // POSITION (m)

  int sim_ms_prev = 0; // previous loop's sim ms
  int sim_ms = 0; // simulation millis

  int startMillis = millis(); // for analytical purposes
  int endMillis; // for analytical purposes

  Boolean ignited = false;
  int ignited_millis = 0;
  float current_thrust = 0;

  ang_pos[0] = 0.3;
  ang_pos_prev[0] = 0.3;
  ang_pos[1] = 0.0;
  ang_pos_prev[1] = 0.0;

  lin_pos[2] = drop_alt;
  lin_pos_prev[2] = drop_alt;

  flight = new Table();
  
  speedy_max_vel = Integer.MIN_VALUE;

  for (String column : columns) {
    flight.addColumn(column);
  }

  while (sim_ms < sim_length) {

    // CALC THRUST:
    if (lin_pos[2] < ign_alt && ignited == false) {
      ignited = true;
      ignited_millis = sim_ms;
    }
    //if (lin_pos[2] < ign_alt) {
    if(ignited){
      current_thrust = calcThrust(sim_ms - ignited_millis);
    }
    //current_thrust = 15;


    //setpoint[0] = 5*cos((sim_ms*PI)/125);

    // CALC ANGLE:
    // calculate forces applied to body, and how much ang_torque results
    ang_torque[0] = (sin(TVC[0]) * current_thrust) * TVC_to_CG;
    ang_torque[1] = (sin(TVC[1]) * current_thrust) * TVC_to_CG; 
    ang_accel[0] = ang_torque[0] / moi;
    ang_accel[1] = ang_torque[1] / moi;

    // Integrate ang_acceleration to find ang_velocity:
    ang_vel[0] = ang_vel_prev[0] + (float(sim_ms - sim_ms_prev) / 1000) * ((ang_accel[0] + ang_accel_prev[0])/2);
    ang_vel[1] = ang_vel_prev[1] + (float(sim_ms - sim_ms_prev) / 1000) * ((ang_accel[1] + ang_accel_prev[1])/2);

    // Integrate ang_velocity to find ang_position:
    ang_pos[0] = ang_pos_prev[0] + (float(sim_ms - sim_ms_prev) / 1000) * ((ang_vel[0] + ang_vel_prev[0])/2);
    ang_pos[1] = ang_pos_prev[1] + (float(sim_ms - sim_ms_prev) / 1000) * ((ang_vel[1] + ang_vel_prev[1])/2);

    // CALC TVC:
    // calculate dt and ang_errors:
    int dt = sim_ms - sim_ms_prev;
    ang_error[0] = setpoint[0] - ang_pos[0];
    ang_error[1] = setpoint[1] - ang_pos[1];

    // Update P, I, and D values:
    ang_p[0] = ang_error[0];
    ang_p[1] = ang_error[1];
    if (current_thrust > 0) {
      ang_i[0] = ang_i_prev[0] + (ang_error[0] * (dt/1000.0));
      ang_i[1] = ang_i_prev[1] + (ang_error[1] * (dt/1000.0));
    }
    ang_d[0] = (ang_error[0] - ang_e_prev[0]) / (dt/1000.0);
    ang_d[1] = (ang_error[1] - ang_e_prev[1]) / (dt/1000.0);

    if (dt == 0) { // this helps on the first round
      ang_d[0] = 0;
      ang_d[1] = 0;
    }

    // This, as they say, is where the magic happens:
    float[] output = new float[2];
    output[0] = constrain((ang_p[0] * kp) + (ang_i[0] * ki) + (ang_d[0] * kd), -max_TVC_angle, max_TVC_angle);
    output[1] = constrain((ang_p[1] * kp) + (ang_i[1] * ki) + (ang_d[1] * kd), -max_TVC_angle, max_TVC_angle);

    TVC[0] = output[0];
    TVC[1] = output[1];

    // CALC LINEAR POS:
    float[] thrust_vector = new float[2];
    thrust_vector[0] = TVC[0] + ang_pos[0];
    thrust_vector[1] = TVC[1] + ang_pos[1];
    lin_force[0] = current_thrust * sin(thrust_vector[0]);
    lin_force[1] = current_thrust * sin(thrust_vector[1]);
    lin_force[2] = (((cos(thrust_vector[0]) + cos(thrust_vector[1]))/2) * current_thrust) + (mass * gravity); // so this really just isn't correct but it's the best I've got

    lin_accel[0] = lin_force[0] / mass;
    lin_accel[1] = lin_force[1] / mass;
    lin_accel[2] = lin_force[2] / mass;

    lin_vel[0] = lin_vel_prev[0] + (float(sim_ms - sim_ms_prev) / 1000) * ((lin_accel[0] + lin_accel_prev[0])/2);
    lin_vel[1] = lin_vel_prev[1] + (float(sim_ms - sim_ms_prev) / 1000) * ((lin_accel[1] + lin_accel_prev[1])/2);
    lin_vel[2] = lin_vel_prev[2] + (float(sim_ms - sim_ms_prev) / 1000) * ((lin_accel[2] + lin_accel_prev[2])/2);

    lin_pos[0] = lin_pos_prev[0] + (float(sim_ms - sim_ms_prev) / 1000) * ((lin_vel[0] + lin_vel_prev[0])/2);
    lin_pos[1] = lin_pos_prev[1] + (float(sim_ms - sim_ms_prev) / 1000) * ((lin_vel[1] + lin_vel_prev[1])/2);
    lin_pos[2] = lin_pos_prev[2] + (float(sim_ms - sim_ms_prev) / 1000) * ((lin_vel[2] + lin_vel_prev[2])/2);

    if (lin_pos[2] <= 0) {
      lin_vel[0] = 0;
      lin_vel[1] = 0;
      lin_vel_prev[0] = 0;
      lin_vel_prev[1] = 0;
      ang_vel[0] = 0;
      ang_vel[1] = 0;
      ang_vel_prev[0] = 0;
      ang_vel_prev[1] = 0;
    }

    // Save to the table:
    if (!speedy) {
      TableRow newRow = flight.addRow();
      newRow.setInt("ms", sim_ms);
      newRow.setFloat("current_thrust", current_thrust);
      newRow.setFloat("0_ang_torque", ang_torque[0]);
      newRow.setFloat("0_ang_accel", ang_accel[0]);
      newRow.setFloat("0_ang_vel", ang_vel[0]);
      newRow.setFloat("0_ang_pos", ang_pos[0]);
      newRow.setFloat("0_output", output[0]);
      newRow.setFloat("0_p", ang_p[0]);
      newRow.setFloat("0_i", ang_i[0]);
      newRow.setFloat("0_d", ang_d[0]);
      newRow.setFloat("1_ang_torque", ang_torque[1]);
      newRow.setFloat("1_ang_accel", ang_accel[1]);
      newRow.setFloat("1_ang_vel", ang_vel[1]);
      newRow.setFloat("1_ang_pos", ang_pos[1]);
      newRow.setFloat("1_output", output[1]);
      newRow.setFloat("1_p", ang_p[1]);
      newRow.setFloat("1_i", ang_i[1]);
      newRow.setFloat("1_d", ang_d[1]);
      newRow.setFloat("0_lin_force", lin_force[0]);
      newRow.setFloat("0_lin_accel", lin_accel[0]);
      newRow.setFloat("0_lin_vel", lin_vel[0]);
      newRow.setFloat("0_lin_pos", lin_pos[0]);
      newRow.setFloat("1_lin_force", lin_force[1]);
      newRow.setFloat("1_lin_accel", lin_accel[1]);
      newRow.setFloat("1_lin_vel", lin_vel[1]);
      newRow.setFloat("1_lin_pos", lin_pos[1]);
      newRow.setFloat("2_lin_force", lin_force[2]);
      newRow.setFloat("2_lin_accel", lin_accel[2]);
      newRow.setFloat("2_lin_vel", lin_vel[2]);
      newRow.setFloat("2_lin_pos", lin_pos[2]);
      newRow.setFloat("0_tvc", TVC[0]);
      newRow.setFloat("1_tvc", TVC[1]);
    }
    /*
    speedy_vel = lin_vel[2];
    speedy_alt = lin_pos[2];
    if(speedy_vel > speedy_max_vel){
      speedy_max_vel = speedy_vel;
    }*/

    // Update previous values:
    ang_torque_prev[0] = ang_torque[0];
    ang_torque_prev[1] = ang_torque[1];
    ang_accel_prev[0] = ang_accel[0];
    ang_accel_prev[1] = ang_accel[1];
    ang_vel_prev[0] = ang_vel[0];
    ang_vel_prev[1] = ang_vel[1];
    ang_pos_prev[0] = ang_pos[0];
    ang_pos_prev[1] = ang_pos[1];

    lin_force_prev[0] = lin_force[0];
    lin_force_prev[1] = lin_force[1];
    lin_force_prev[2] = lin_force[2];
    lin_accel_prev[0] = lin_accel[0];
    lin_accel_prev[1] = lin_accel[1];
    lin_accel_prev[2] = lin_accel[2];
    lin_vel_prev[0] = lin_vel[0];
    lin_vel_prev[1] = lin_vel[1];
    lin_vel_prev[2] = lin_vel[2];
    lin_pos_prev[0] = lin_pos[0];
    lin_pos_prev[1] = lin_pos[1];
    lin_pos_prev[2] = lin_pos[2];

    sim_ms_prev = sim_ms;

    ang_i_prev[0] = ang_i[0];
    ang_i_prev[1] = ang_i[1];
    ang_e_prev[0] = ang_error[0];
    ang_e_prev[1] = ang_error[1];

    sim_ms += 1;
  }

  if (!speedy) {
    saveTable(flight, "data/flight.csv");
  }

  sim_ready = true;

  endMillis = millis();
  print("Sim time: ");
  println(endMillis - startMillis);
}
