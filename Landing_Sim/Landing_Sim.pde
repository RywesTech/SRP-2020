import peasy.*;
import controlP5.*;

PeasyCam cam;
ControlP5 cp5;

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

// UI VALS:
boolean running = false;

void setup() {
  size(800, 600, P3D);
  frameRate(50);
  smooth();

  // set initial position:
  pos_x = 500;
  pos_y = 500;
  pos_z = 1000;
  prev_pos_z = 1000;

  cam = new PeasyCam(this, 500, 500, 1000, 100);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(5000);

  cp5 = new ControlP5(this);
  cp5.addToggle("running")
    .setPosition(10, 10)
    .setSize(60, 20)
    .setValue(true)
    .setMode(ControlP5.SWITCH)
    ;
  cp5.setAutoDraw(false);
}

void draw() {
  background(0);
  stroke(255, 0, 0);
  fill(255, 0, 0);
  line(0, 0, 0, 100, 0, 0);
  text("X", 100, 0, 0);

  stroke(0, 255, 0);
  fill(0, 255, 0);
  line(0, 0, 0, 0, 100, 0);
  text("Y", 0, 100, 0);

  stroke(0, 0, 255);
  fill(0, 0, 255);
  line(0, 0, 0, 0, 0, 100);
  text("Z", 0, 0, 100);

  fill(100, 100, 100, 50);
  stroke(255);
  rect(0, 0, 1000, 1000);
  for (int i = 0; i <= 10; i++) {
    line(0, i*100, 1000, i*100);
    line(i*100, 0, i*100, 1000);
  }

  if (!running) {
    // reset all forces:
    forces_z = 0;
    forces_z += (mass * gavity);

    // stop it if it hits the ground
    if (pos_z <= 0) {
      float count_force = ((vel_z * mass) + (mass * gavity)) * -1;
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
  
  println(pos_z);
  drawRocket(pos_x, pos_y, pos_z, 0, 0, 0, true);

  cam.beginHUD();
  fill(100, 100, 100, 100);
  stroke(255);
  rect(0, 0, 100, 600);
  cp5.draw();
  cam.endHUD();
}

void drawRocket(float x_func, float y_func, float z_func, float pitch_func, float yaw_func, float roll_func, boolean firing) {
  pushMatrix();
  translate(x_func, y_func, z_func - 45.75);
  stroke(0, 253, 255);
  rotateX((PI/2) + pitch_func);
  rotateY(yaw_func);
  drawCylinder(7.4, 7.4, 91.5, 20);
  popMatrix();

  if (firing) {
    pushMatrix();
    translate(x_func, y_func, z_func - 45.75);
    stroke(255, 165, 0);
    rotateX(-(PI/2));
    drawCylinder(1, 10, 40, 6);
    popMatrix();
  }
}

void drawCylinder(float topRadius, float bottomRadius, float tall, int sides) {
  float angle = 0;
  float angleIncrement = TWO_PI / sides;
  beginShape(QUAD_STRIP);
  for (int i = 0; i < sides + 1; ++i) {
    vertex(topRadius*cos(angle), 0, topRadius*sin(angle));
    vertex(bottomRadius*cos(angle), tall, bottomRadius*sin(angle));
    angle += angleIncrement;
  }
  endShape();

  // If it is not a cone, draw the circular top cap
  if (topRadius != 0) {
    angle = 0;
    beginShape(TRIANGLE_FAN);

    // Center point
    vertex(0, 0, 0);
    for (int i = 0; i < sides + 1; i++) {
      vertex(topRadius * cos(angle), 0, topRadius * sin(angle));
      angle += angleIncrement;
    }
    endShape();
  }

  // If it is not a cone, draw the circular bottom cap
  if (bottomRadius != 0) {
    angle = 0;
    beginShape(TRIANGLE_FAN);

    // Center point
    vertex(0, tall, 0);
    for (int i = 0; i < sides + 1; i++) {
      vertex(bottomRadius * cos(angle), tall, bottomRadius * sin(angle));
      angle += angleIncrement;
    }
    endShape();
  }
}
