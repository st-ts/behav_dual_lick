/// Code for laser stimulation triggered by 
// pulse signal from raspberry pi
// should be COM4


// Variable for pins
#define SHUTTER 11
#define WATER_LEFT 6
#define WATER_RIGHT 5
#define SHUTTER_RASP 8
#define WATER_LEFT_RASP 4
#define WATER_RIGHT_RASP 3 
#define WATER_BOTH_RASP 2 
#define LED_MASK 13

// Customizable laser stim parameters
int pulse_dur = 1200;
int n_pulses = 1; 
int pulse_isi =1;


// For how long to open the water valves for the right amount of reward
int valve_open_L_ms = 9;
int valve_open_R_ms = 11;

// State & count variables
int water_state_L;
int water_state_R;
int water_state_both;
int laser_state;
int n = 0;


void setup() {
    // setup pins:
    pinMode(SHUTTER, OUTPUT);
    pinMode(WATER_LEFT, OUTPUT);
    pinMode(WATER_RIGHT, OUTPUT);
    pinMode(LED_MASK, OUTPUT);
    pinMode(SHUTTER_RASP, INPUT);
    pinMode(WATER_RIGHT_RASP, INPUT);
    pinMode(WATER_LEFT_RASP, INPUT);
    pinMode(WATER_BOTH_RASP, INPUT);
  
}

void loop() {


    // Check if water ports are called and deliver water
    water_state_L =  digitalRead(WATER_LEFT_RASP);
    if (water_state_L) {
        digitalWrite(WATER_LEFT, 1);
        delay(valve_open_L_ms);
        digitalWrite(WATER_LEFT, 0);
        delay(50);
    }



    water_state_R =  digitalRead(WATER_RIGHT_RASP);
    if (water_state_R) {
        digitalWrite(WATER_RIGHT, 1);
        delay(valve_open_R_ms);
        digitalWrite(WATER_RIGHT, 0);
        delay(50);
    }

    water_state_both =  digitalRead(WATER_BOTH_RASP);
    if (water_state_both) {
        digitalWrite(WATER_RIGHT, 1);
        digitalWrite(WATER_LEFT, 1);
        delay(valve_open_R_ms);
        digitalWrite(WATER_RIGHT, 0);
        digitalWrite(WATER_LEFT, 0);
        delay(50);
    }

  
}
