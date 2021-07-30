#include <Stepper.h>

#define FUL_REV 2038

#define H_IN1 5
#define H_IN2 4
#define H_IN3 3
#define H_IN4 2

#define R_IN1 8
#define R_IN2 9
#define R_IN3 10
#define R_IN4 11

Stepper rot(FUL_REV, R_IN1, R_IN3, R_IN2, R_IN4);
Stepper height(FUL_REV, H_IN1, H_IN3, H_IN2, H_IN4);

int val = 0;

void setup() {
  Serial.begin(9600);
  rot.setSpeed(10);
  height.setSpeed(2);

  Serial.println("find the top (send '#', '+#', '-#', 'r', or 'y')");
}

#define S_WAIT 0
#define S_DOWN 1
#define S_UP 2
#define S_BEGIN 3

#define V_MIN_STEP 2

static int dist = 0;
static int at = 0;
static int n = 0;
static int state = S_BEGIN;

void loop() {
  if (state == S_BEGIN) {
    if (Serial.available()) {
      String s = Serial.readString();
      if (s[0] == 'y') {
        if (dist == 0) Serial.println("winding down, send 'y' when we arrive");
        state = S_DOWN;
      } else if (s[0] == 'r') {
        Serial.println("1 rev comin right up");
        rot.step(FUL_REV);
      } else if (s[0] == '-') {
        Serial.println("down");
        height.step(-s.toInt());
      } else if (s[0] == '+') {
        Serial.println("up");
        height.step(-s.toInt());
      } else {
        Serial.println("set dist");
        dist = s.toInt();
      }
    }
  } else if (state == S_DOWN) {
    rot.step(FUL_REV);
    height.step(V_MIN_STEP);
    at++;

    Serial.println(String(at) + "/" + dist);

    if (dist == 0 && Serial.available() && Serial.readString()[0] == 'y') {
        Serial.println(String("found the bottom at ") + at);
        dist = at;
    }

    if (dist != 0 && at == dist) {
      state = S_UP;
    }
  } else if (state == S_UP) {
    rot.step(FUL_REV);
    height.step(-V_MIN_STEP);
    at--;

    Serial.println(String(at) + "/" + dist);

    if (at == 0) {
      n++;
      Serial.println(String("trip done, ") + n + " round trips * " + dist + " revs per = " + n*2*dist);
      Serial.println("again? 'y'");
      state = S_WAIT;
    }
  } else if (state == S_WAIT) {
    if (Serial.available() && Serial.readString()[0] == 'y') {
      Serial.println("aight, here we go dude");
      state = S_DOWN;
    }
  }
}
