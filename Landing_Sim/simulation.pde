void runSim() {
  // reset all forces:
    current_thrust = calcThrust(sim_ms - 1540);
    forces_z = 0;
    forces_z += (mass * gavity);
    forces_z += current_thrust;

    // stop it if it hits the ground
    if (pos_z <= 45.75) {
      float count_force = ((vel_z * mass) + (mass * gavity)) * -1;
      forces_z = count_force;
    }

    accel_z = forces_z / mass;
    vel_z = prev_vel_z + ((accel_z * ((sim_ms - prev_millis)/1000))*10);
    pos_z = prev_pos_z + ((vel_z * ((sim_ms - prev_millis)/1000))*10);
    println(pos_z);

    prev_accel_z = accel_z;
    prev_vel_z = vel_z;
    prev_pos_z = pos_z;

    prev_millis = sim_ms;
    sim_ms += 20;
}
