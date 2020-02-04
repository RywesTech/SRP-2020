void drawLandscape() {
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

void drawHUD() { 
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
    fill(29, 209, 161);
  } else {
    stroke(255);
    fill(238, 82, 83);
  }
  rect(10, 610, 180, 30);

  //alt_plot.defaultDraw();
  cam.endHUD();
}
