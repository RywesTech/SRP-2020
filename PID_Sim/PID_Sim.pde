import peasy.*;
import controlP5.*;

PeasyCam cam;
ControlP5 cp5;
Table flight;
Table vehicle;

float mass, moi, TVC_to_CG, cd, cs, kp, ki, kd, drop_alt, ign_alt;

// UI VALS:
boolean running = false;
boolean sim_ready = false;
int start_display_sim_ms = 0;

void setup() {
  size(1250, 700, P3D);
  smooth();

  vehicle = loadTable("vehicle.csv", "header");
  int row = vehicle.getRowCount() - 1;

  mass = vehicle.getFloat(row, "mass");
  moi = vehicle.getFloat(row, "moi");
  TVC_to_CG = vehicle.getFloat(0, "TVC_to_CG");
  cd = vehicle.getFloat(row, "cd");
  cs = vehicle.getFloat(row, "cs");
  kp = vehicle.getFloat(row, "kp");
  ki = vehicle.getFloat(row, "ki");
  kd = vehicle.getFloat(row, "kd");
  drop_alt = vehicle.getFloat(row, "drop_alt");
  ign_alt = vehicle.getFloat(row, "ign_alt");

  cam = new PeasyCam(this, 0, 0, 0, 200);
  cp5 = new ControlP5(this);

  cp5.addTextfield("mass")
    .setPosition(10, 60)
    .setSize(80, 30)
    .setText(str(mass))
    .setFont(createFont("arial", 12))
    .setAutoClear(false)
    ;

  cp5.addTextfield("moi")
    .setPosition(110, 60)
    .setSize(80, 30)
    .setText(str(moi))
    .setFont(createFont("arial", 12))
    .setAutoClear(false)
    ;

  cp5.addTextfield("TVC2CG")
    .setPosition(10, 120)
    .setSize(80, 30)
    .setText(str(TVC_to_CG))
    .setFont(createFont("arial", 12))
    .setAutoClear(false)
    ;

  cp5.addTextfield("Cd")
    .setPosition(110, 120)
    .setSize(80, 30)
    .setText(str(cd))
    .setFont(createFont("arial", 12))
    .setAutoClear(false)
    ;

  cp5.addTextfield("CS Area")
    .setPosition(10, 180)
    .setSize(80, 30)
    .setText(str(cs))
    .setFont(createFont("arial", 12))
    .setAutoClear(false)
    ;

  cp5.addTextfield("P")
    .setPosition(10, 240)
    .setSize(50, 30)
    .setText(str(kp))
    .setFont(createFont("arial", 12))
    .setAutoClear(false)
    ;
  cp5.addTextfield("I")
    .setPosition(75, 240)
    .setSize(50, 30)
    .setText(str(ki))
    .setFont(createFont("arial", 12))
    .setAutoClear(false)
    ;
  cp5.addTextfield("D")
    .setPosition(140, 240)
    .setSize(50, 30)
    .setText(str(kd))
    .setFont(createFont("arial", 12))
    .setAutoClear(false)
    ;

  cp5.addButton("Auto Calc D_alt")
    .setValue(0)
    .setPosition(10, 300)
    .setSize(80, 30)
    .addCallback(new CallbackListener() {
    public void controlEvent(CallbackEvent event) {
      if (event.getAction() == ControlP5.ACTION_RELEASED) {
        float max_vel = Integer.MAX_VALUE;
        float test_drop_alt = 100;
        float test_alt = 87; // start from the drop altitude
        int landed_millis = 0;
        while (max_vel > 0) {
          runSim(test_alt, test_drop_alt);
          max_vel = getMaxValue(flight, "2_lin_vel");
          println(test_alt);
          test_alt = test_alt - 0.01;
        }

        for (int i = 100; i < flight.getRowCount(); i++) {
          if (flight.getFloat(i, "2_lin_vel") >= getMaxValue(flight, "2_lin_vel")) {
            landed_millis = i;
          }
        }

        println("dropped: " + test_drop_alt);
        println("ignited: " + test_alt);
        println("landed: " + flight.getFloat(landed_millis, "2_lin_pos"));
        drop_alt = test_drop_alt - flight.getFloat(landed_millis, "2_lin_pos");
        ign_alt = test_alt - flight.getFloat(landed_millis, "2_lin_pos");
        cp5.get(Textfield.class, "Drop Alt").setText(str(drop_alt));
        cp5.get(Textfield.class, "Ign Alt").setText(str(ign_alt));
      }
    }
  }
  );

  cp5.addTextfield("Drop Alt")
    .setPosition(10, 340)
    .setSize(80, 30)
    .setText(str(drop_alt))
    .setFont(createFont("arial", 12))
    .setAutoClear(false)
    ;

  cp5.addTextfield("Ign Alt")
    .setPosition(110, 340)
    .setSize(80, 30)
    .setText(str(ign_alt))
    .setFont(createFont("arial", 12))
    .setAutoClear(false)
    ;

  cp5.addButton("Update Values")
    .setValue(0)
    .setPosition(10, 530)
    .setSize(180, 30)
    .addCallback(new CallbackListener() {
    public void controlEvent(CallbackEvent event) {
      if (event.getAction() == ControlP5.ACTION_RELEASED) {
        saveParams();
      }
    }
  }
  );

  cp5.addButton("simulate")
    .setValue(0)
    .setPosition(10, 570)
    .setSize(180, 30)
    .addCallback(new CallbackListener() {
    public void controlEvent(CallbackEvent event) {
      if (event.getAction() == ControlP5.ACTION_RELEASED) {
        runSim(ign_alt, drop_alt);
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
        cam.lookAt(0, 0, 0, 50);
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
  if (running) {
    int flight_ms = millis() - start_display_sim_ms;
    println(flight_ms);
    if (flight_ms < sim_length) {
      float z_func = flight.getFloat(flight_ms, "2_lin_pos") * 100;
      if (z_func < 0) {
        z_func = 0;
      }
      drawRocket(flight.getFloat(flight_ms, "1_lin_pos") * 100, flight.getFloat(flight_ms, "0_lin_pos") * 100, z_func, flight.getFloat(flight_ms, "0_ang_pos"), flight.getFloat(flight_ms, "1_ang_pos"), 0, flight.getFloat(flight_ms, "0_tvc"), flight.getFloat(flight_ms, "1_tvc"), (flight.getFloat(flight_ms, "current_thrust") > 0));
      cam.lookAt(flight.getFloat(flight_ms, "1_lin_pos") * 100, flight.getFloat(flight_ms, "0_lin_pos") * 100, z_func, 50);
      delay(30);
      cam.beginHUD();
      stroke(255);
      text("Alt: " + str(flight.getFloat(flight_ms, "2_lin_pos")), width-180, 20);
      cam.endHUD();
    }
  }
  drawHUD();
}

void running(boolean flag) {
  if (flag==true) {
    running = false;
    println("not running");
  } else {
    running = true;
    start_display_sim_ms = millis();
    println("running");
  }
  println("a toggle event.");
}

void saveParams() {
  TableRow newRow = vehicle.addRow();
  mass = float(cp5.get(Textfield.class, "mass").getText());
  moi = float(cp5.get(Textfield.class, "moi").getText());
  TVC_to_CG = float(cp5.get(Textfield.class, "TVC2CG").getText());
  cd = float(cp5.get(Textfield.class, "Cd").getText());
  cs = float(cp5.get(Textfield.class, "CS Area").getText());
  kp = float(cp5.get(Textfield.class, "P").getText());
  ki = float(cp5.get(Textfield.class, "I").getText());
  kd = float(cp5.get(Textfield.class, "D").getText());
  drop_alt = float(cp5.get(Textfield.class, "Drop Alt").getText());
  ign_alt = float(cp5.get(Textfield.class, "Ign Alt").getText());

  newRow.setInt("ID", vehicle.getRowCount());
  newRow.setFloat("mass", mass);
  newRow.setFloat("moi", moi);
  newRow.setFloat("TVC_to_CG", TVC_to_CG);
  newRow.setFloat("cd", cd);
  newRow.setFloat("cs", cs);
  newRow.setFloat("kp", kp);
  newRow.setFloat("ki", ki);
  newRow.setFloat("kd", kd);
  newRow.setFloat("drop_alt", drop_alt);
  newRow.setFloat("ign_alt", ign_alt);

  saveTable(vehicle, "data/vehicle.csv");
}

void reset() {
  running = false;
}

int getMinValue(Table t, String colName) {
  int minValue = Integer.MAX_VALUE;
  for (TableRow row : t.rows()) {
    int val = row.getInt(colName);
    if (val < minValue) minValue = val;
  }
  return minValue;
}

int getMaxValue(Table t, String colName) {
  int maxValue = Integer.MIN_VALUE;
  for (TableRow row : t.rows()) {
    int val = row.getInt(colName);
    if (val > maxValue) maxValue = val;
  }
  return maxValue;
}
