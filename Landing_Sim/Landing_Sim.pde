import peasy.*;
import grafica.*;
import controlP5.*;

PeasyCam cam;
ControlP5 cp5;
GPlot alt_plot;
Table thrust;

float pitch, yaw, roll; // pitch, yaw, and roll in radians
int sim_ms; // simulation millis

float forces_x, forces_y, forces_z;
float accel_x, accel_y, accel_z;
float vel_x, vel_y, vel_z;
float pos_x, pos_y, pos_z;

float prev_accel_z;
float prev_vel_z;
float prev_pos_z;
float prev_millis;

// Constants:
float mass = 1; //kg
float gavity = -9.80665;
float drop_alt = 3500;

float current_thrust = 0;

// UI VALS:
boolean running = false;

void setup() {
  size(1250, 700, P3D);
  frameRate(50);
  smooth();

  // set initial position:
  pos_x = 500;
  pos_y = 500;
  pos_z = drop_alt;
  prev_pos_z = 1000;

  cam = new PeasyCam(this, 500, 500, 1000, 100);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(5000);

  cp5 = new ControlP5(this);
  cp5.addToggle("running")
    .setPosition(10, 50)
    .setSize(60, 20)
    .setValue(true)
    .setMode(ControlP5.SWITCH)
    ;
  cp5.addButton("reset")
    .setValue(0)
    .setPosition(100, 50)
    .setSize(60, 20)
    ;
    
    cp5.addButton("simulate")
    .setValue(0)
    .setPosition(10, 650)
    .setSize(180, 20)
    ;
  cp5.setAutoDraw(false);

  thrust = loadTable("F15.csv", "header");
  
  alt_plot = new GPlot(this);
  alt_plot.setPos(900,50);
  alt_plot.setTitleText("Altitude");
  alt_plot.getXAxis().setAxisLabelText("Time");
  alt_plot.getYAxis().setAxisLabelText("Altitude");
  alt_plot.setOuterDim(350, 350);
}

void draw() {
  background(0);
  drawLandscape();

  if (!running) {
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
  if (current_thrust > 0) {
    drawRocket(pos_x, pos_y, pos_z, 0, 0, 0, true);
  } else {
    drawRocket(pos_x, pos_y, pos_z, 0, 0, 0, false);
  }

  cam.beginHUD();
  fill(100, 100, 100, 100);
  stroke(255);
  rect(0, 0, 200, 700);
  rect(900, 0, 350, 700);
  fill(255);
  textSize(20);
  text("CONTROL PANNEL", 10, 40);
  cp5.draw();
  alt_plot.defaultDraw();
  cam.endHUD();
}

public void controlEvent(ControlEvent theEvent) {
  println(theEvent.getController().getName());
  if (theEvent.getController().getName().equals("reset")) {
    reset();
  }
}

void reset() {
  forces_x = 0;
  forces_y = 0;
  forces_z = 0;

  accel_x = 0;
  accel_y = 0;
  accel_z = 0;

  vel_x = 0;
  vel_y = 0;
  vel_z = 0;

  pos_x = 500;
  pos_y = 500;
  pos_z = drop_alt;

  prev_accel_z = 0;
  prev_vel_z = 0;
  prev_pos_z = drop_alt;
  prev_millis = 0;
  sim_ms = 0;

  running = true;
}
