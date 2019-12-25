void runSim(boolean drop, boolean pid) {
  int startMillis = millis();
  int endMillis; // for analytical purposes
  
  int sim_length = 8000; // simulate the first 8 seconds of flight
  while (sim_ms < sim_length) {
    // reset all forces:
    current_thrust = calcThrust(sim_ms - 1540);
    forces_z = 0; // reset forces
    forces_z += (mass * gavity); // gravity
    // drag
    forces_z += current_thrust; // thrust

    // stop it if it hits the ground
    //if (pos_z <= 45.75) {
      //float count_force = ((vel_z * mass) + (mass * gavity)) * -1;
      //forces_z = count_force;
    //}
    
    // integrate the force data to position data
    accel_z = forces_z / mass;
    vel_z = prev_vel_z + ((accel_z * ((sim_ms - prev_millis)/1000))*10);
    pos_z = prev_pos_z + ((vel_z * ((sim_ms - prev_millis)/1000))*10);
    
    // Save to the table
    TableRow newRow = flight.addRow();
    newRow.setInt("ms", sim_ms);
    newRow.setFloat("pos_z", pos_z);
    newRow.setFloat("vel_z", vel_z);
    newRow.setFloat("accel_z", accel_z);

    prev_accel_z = accel_z;
    prev_vel_z = vel_z;
    prev_pos_z = pos_z;

    prev_millis = sim_ms;
    sim_ms += 1;
  }
  saveTable(flight, "data/flight.csv");
  
  //float min_vel = min(flight.getStringColumn("pos_z"));
  //print(flight.getFloatColumn("pos_z"));
  for(TableRow row : flight.rows()){
    print(row.getFloat("pos_z"));
  }
  
  //Update graph
  GPointsArray positions = new GPointsArray(400);
  for(int i = 0; i <= 7900; i += 100){
    TableRow row = flight.getRow(i);
    positions.add(row.getInt("ms"), row.getFloat("pos_z"));
  }
  //alt_plot.setPoints(positions);
  //alt_plot.updateLimits();
  sim_ready = true;
  
  endMillis = millis();
  print("Sim time: ");
  println(endMillis - startMillis);
}
