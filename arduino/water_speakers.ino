#define SPEAKERS_BOTH 8
#define SPEAKER_LEFT 9 
#define SPEAKER_RIGHT 10

#define LEFT_TRIAL_PIN 11
#define RIGHT_TRIAL_PIN 12

#define LEFT_LICK 5
#define RIGHT_LICK 6

#define LEFT 1
#define RIGHT -1


const int start_go_freq = 200;  // 6 kHz carrier frequency
const int incr_go_freq = 50;  // 360 Hz modulating frequency
const int go_durat = 100;
const int left_tone = 10000;
const int right_tone = 3000;

int left_trial = 0;
int right_trial = 0;



void setup() {
    pinMode(SPEAKER_LEFT, OUTPUT);
    pinMode(SPEAKER_RIGHT, OUTPUT);
    pinMode(SPEAKERS_BOTH, OUTPUT);
    pinMode(LEFT_TRIAL_PIN, INPUT);
    pinMode(RIGHT_TRIAL_PIN, INPUT);
    pinMode(LEFT_LICK, INPUT);
    pinMode(RIGHT_LICK, INPUT);
}

void loop() {
    // Get signal from Raspberry about the start of the trial and which trial it is
 //   left_trial = digitalRead(LEFT_TRIAL_PIN);
  //  right_trial = digitalRead(RIGHT_TRIAL_PIN);


        // if it is A1, both left and right will give signal
  ////  if (left_trial && right_trial) {
   //     go_sound(SPEAKER_LEFT);  // CHANGE LATER TO SPEAKERS BOTH
   // }
    

  // Go signal
  go_sound();

  delay(1000);  // 1 second delay before the next AM signal

  tone(SPEAKER_LEFT, 3000);
    delay(500);
  noTone(SPEAKER_LEFT);
  tone(SPEAKER_RIGHT, 1000);
  delay(500);
  noTone(SPEAKER_RIGHT);
  delay(1000);
}

void discr_trial(int side) {
    // determine the side related variables
    if (side == LEFT) {
        int tone_freq = left_tone;
        SPEAKER = SPEAKER_LEFT;
        port = port_left;
    } else {
        int tone_freq = right_tone;
        SPEAKER = SPEAKER_RIGHT;
        port = port_right;
    }
    // play the tone indicating the rewarded port
    // right_tone for the right, left_tone for the left
    for (int i=0; i<4; i++){
        tone(SPEAKER, tone_freq);
        delay(150);
        noTone(SPEAKER);
        delay(50);
    }
    // play go sound
    go_sound();

    // monitor the lick events
    bool correct false
    while (!correct )

}

void play_tone

void go_sound() {
    for (int i = 0; i < go_durat; i++) {
        int toneValue = start_go_freq + i*incr_go_freq;
        tone(SPEAKERS_BOTH, toneValue); 
        delayMicroseconds(1000);  // Adjust this delay as needed for the desired audio quality
    }
    noTone(SPEAKERS_BOTH);
}
