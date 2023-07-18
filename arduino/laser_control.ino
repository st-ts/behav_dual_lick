/// should be com3

// Set pin names
#define LASER_RASP 4
#define LASER 3
#define LED_MASK 13

// Customizable laser stim parameters
// for yellow laser:
int pulse_dur = 2500; int n_pulses = 1; int pulse_isi =10;
// for blue laser
// int pulse_dur = 50; int n_pulses = 6; int pulse_isi =100;


// 
int laser_state;
int n = 0;

void setup() {
  pinMode(LASER, OUTPUT);
  pinMode(LED_MASK, OUTPUT);
  pinMode(LASER_RASP, INPUT);
}

void loop() {
  // put your main code here, to run repeatedly:
  // uncomment for the laser calibration:
  // digitalWrite(LASER, 1);
    laser_state =  digitalRead(LASER_RASP);
    if (laser_state) {
        // Give pulses of laser & masking LED
        for (n=0; n<n_pulses; n++) {
            digitalWrite(LASER, 1);
            digitalWrite(LED_MASK, 1);
            delay(pulse_dur);
            digitalWrite(LASER, 0);
            digitalWrite(LED_MASK, 0);
            delay(pulse_isi);
        }
        
    }
  
    


}
