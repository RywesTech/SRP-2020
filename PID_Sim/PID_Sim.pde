import peasy.*;
import controlP5.*;

PeasyCam cam;
ControlP5 cp5;
Table thrust;
Table flight;

// Update these:
float mass = 0.949; //kg
float moi = 0.087706; // kg/m^2
float TVC_to_CG = 0.355; // m
float kp = 0.134; //0.134
float ki = 0.114; //0.114
float kd = 0.074; //0.074
float setpoint[] = {0, 0, 0};

float gavity = -9.80665; // m/s^2
float current_thrust = 0; // Newtons

// UI VALS:
boolean running = false;
boolean sim_ready = false;

void setup() {
  size(1250, 700, P3D);
  smooth();

  cam = new PeasyCam(this, 500, 500, 1000, 100);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(5000);

  cp5 = new ControlP5(this);

  cp5.addButton("simulate")
    .setValue(0)
    .setPosition(10, 570)
    .setSize(180, 30)
    .addCallback(new CallbackListener() {
    public void controlEvent(CallbackEvent event) {
      if (event.getAction() == ControlP5.ACTION_RELEASED) {
        runSim();
      }
    }
  }
  );

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
    .addCallback(new CallbackListener() {
    public void controlEvent(CallbackEvent event) {
      if (event.getAction() == ControlP5.ACTION_RELEASED) {
        print("RESET");
      }
    }
  }
  );

  cp5.setAutoDraw(false);

  thrust = loadTable("F15.csv", "header");
}

void draw() {
  background(0);
  drawLandscape();
  drawRocket(0, 0, 0, 0, 0, 0, (current_thrust > 0));
  drawHUD();
}

/*
public void controlEvent(ControlEvent theEvent) {
 if (theEvent.getController().getName().equals("reset")) {
 }
 }*/

void toggle(boolean flag) {
  if (flag==true) {
    running = true;
    //start_display_sim_ms = millis();
  } else {
    running = false;
  }
  println("a toggle event.");
}

void reset() {
  /*
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
   */
  running = false;
}
