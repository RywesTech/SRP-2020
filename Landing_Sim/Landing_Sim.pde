import peasy.*;
import grafica.*;
import controlP5.*;

PeasyCam cam;
ControlP5 cp5;
GPlot alt_plot;
Table thrust;
Table flight;

float pitch, yaw, roll; // pitch, yaw, and roll in degrees
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
boolean sim_ready = false;
int display_sim_ms = 0;
int start_display_sim_ms = 0;

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

  cp5.addButton("simulate_drop")
    .setValue(0)
    .setPosition(10, 530)
    .setSize(80, 30)
    ;

  cp5.addButton("simulate_pid")
    .setValue(0)
    .setPosition(110, 530)
    .setSize(80, 30)
    ;

  cp5.addButton("simulate")
    .setValue(0)
    .setPosition(10, 570)
    .setSize(180, 30)
    ;

  cp5.addToggle("running")
    .setPosition(10, 650)
    .setSize(80, 30)
    .setValue(true)
    .setMode(ControlP5.SWITCH)
    ;

  cp5.addButton("reset")
    .setValue(0)
    .setPosition(110, 650)
    .setSize(80, 30)
    ;

  /*
  cp5.addSlider("sliderTicks1")
   .setPosition(0,670)
   .setSize(1250,30)
   .setRange(0,8000)
   .setNumberOfTickMarks(4001)
   ;
   */

  cp5.setAutoDraw(false);

  thrust = loadTable("F15.csv", "header");
  flight = new Table();
  flight.addColumn("ms");
  flight.addColumn("pos_z");
  flight.addColumn("vel_z");
  flight.addColumn("accel_z");

  /*
  alt_plot = new GPlot(this);
   alt_plot.setPos(900,50);
   alt_plot.setTitleText("Altitude");
   alt_plot.getXAxis().setAxisLabelText("Time");
   alt_plot.getYAxis().setAxisLabelText("Altitude");
   alt_plot.setOuterDim(350, 350);*/
}

void draw() {
  background(0);
  drawLandscape();
  
  if(running){
    int current_millis = millis() - start_display_sim_ms;
  }

  if (current_thrust > 0) {
    //drawRocket(pos_x, pos_y, pos_z, 0, 0, 0, true);
  } else {
    //drawRocket(pos_x, pos_y, pos_z, 0, 0, 0, false);
  }
  drawRocket(pos_x, pos_y, pos_z, 0, 0, 0, (current_thrust > 0));

  cam.beginHUD();
  fill(100, 100, 100, 100);
  stroke(255);
  rect(0, 0, 200, 700);
  rect(900, 0, 350, 700);
  fill(255);
  textSize(20);
  text("CONTROL PANNEL", 10, 40);
  cp5.draw();

  if (sim_ready) {
    stroke(255);
    fill(20, 255, 20);
  } else {
    stroke(255);
    fill(255, 20, 20);
  }
  rect(10, 610, 180, 30);

  //alt_plot.defaultDraw();
  cam.endHUD();
}

public void controlEvent(ControlEvent theEvent) {
  println(theEvent.getController().getName());
  if (theEvent.getController().getName().equals("simulate_drop")) {
    sim_ready = false;
    runSim(true, false);
  } else if (theEvent.getController().getName().equals("simulate_pid")) {
    sim_ready = false;
    runSim(false, true);
  } else if (theEvent.getController().getName().equals("simulate")) {
    sim_ready = false;
    runSim(true, true);
  } else if (theEvent.getController().getName().equals("reset")) {
    display_sim_ms = 0;
  }
}

void toggle(boolean flag) {
  if(flag==true) {
    running = true;
    start_display_sim_ms = millis();
  } else {
    running = false;
  }
  println("a toggle event.");
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

  running = false;
}
