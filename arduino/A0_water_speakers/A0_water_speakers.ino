#define SPEAKERS_BOTH 8
#define SPEAKER_LEFT 9 
#define SPEAKER_RIGHT 10

// for A0 script, these become "too many left/right trials"
#define LEFT_TRIAL_PIN 11 
#define RIGHT_TRIAL_PIN 12

#define LEFT_LICK 5
#define RIGHT_LICK 6

#define LEFT_PORT 0
#define RIGHT_PORT 1

#define LEFT 1
#define RIGHT -1
#define NO 0

#define LEFT_TONE 10000
#define RIGHT_TONE 3000

#define LEFT_REWARD_DUR 15
#define RIGHT_REWARD_DUR 15


#define RESPONSE_DUR 1000

// trial outcome codes
#define CORRECT 1
#define INCORRECT 0
#define NORESPONSE 3



const int start_go_freq = 200;  // 6 kHz carrier frequency
const int incr_go_freq = 50;  // 360 Hz modulating frequency
const int go_durat = 100;
const int left_tone = 10000;
const int right_tone = 3000;

int left_trial = 0;
int right_trial = 0;

// lick detecting variables
int prev_left_lick_state;
int prev_right_lick_state;



void setup() {
    pinMode(SPEAKER_LEFT, OUTPUT);
    pinMode(SPEAKER_RIGHT, OUTPUT);
    pinMode(SPEAKERS_BOTH, OUTPUT);
    pinMode(LEFT_TRIAL_PIN, INPUT);
    pinMode(RIGHT_TRIAL_PIN, INPUT);
    pinMode(LEFT_LICK, INPUT);
    pinMode(RIGHT_LICK, INPUT);
    pinMode(LEFT_PORT, OUTPUT);
    pinMode(RIGHT_PORT, OUTPUT);
}

void loop() {
    // Get signal from Raspberry about the start of the trial and which trial it is
 //   left_trial = digitalRead(LEFT_TRIAL_PIN);
  //  right_trial = digitalRead(RIGHT_TRIAL_PIN);


        // if it is A1, both left and right will give signal
  ////  if (left_trial && right_trial) {
   //     go_sound(SPEAKER_LEFT);  // CHANGE LATER TO SPEAKERS BOTH
   // }
    int lick_detected = monitor_licks();
    int too_many_left = digitalRead(LEFT_TRIAL_PIN);
    int too_many_right = digitalRead(RIGHT_TRIAL_PIN);

    // If not too many left/right trials, deliver a reward
    if (!too_namy_left && (lick_detected == LEFT)) {
        go_sound();
        deliver_reward(LEFT);
    } else if (!not_too_many_right && (lick_detected == RIGHT)) {
        go_sound();
        deliver_reward(RIGHT);
    }
}

void deliver_reward(int side) {
    int port; int reward_dur;
    // set the side-related params
    if (side == LEFT) {
        port = LEFT_PORT;
        reward_dur = LEFT_REWARD_DUR;
    } else {
        port = RIGHT_PORT;
        reward_dur = RIGHT_REWARD_DUR;
    }
    // deliver that reward
    digitalWrite(port, HIGH);
    delay(reward_dur);
    digitalWrite(port, LOW);

    // send signal to raspberri about the reward delivered

}

// Function outputing the info on whether a lick was detected
int monitor_licks() {
    // Read the sensor data
    int left_lick_state = digitalRead(LEFT_LICK);
    int right_lick_state = digitalRead(RIGHT_LICK);
    int lick_detected;
    // compare with the previous state
    if (left_lick_state && !prev_left_lick_state){
        lick_detected = LEFT;
    } else if (right_lick_state && !prev_right_lick_state) {
        lick_detected = RIGHT;
    } else {
        lick_detected = NO;
    }

    // make the current states to be previous
    prev_left_lick_state = left_lick_state;
    prev_right_lick_state = right_lick_state;

    return lick_detected;

}

int discr_trial(int side) {
    // play the tone indicating the rewarded port
    play_tone(side);

    // play go sound
    go_sound();

    // monitor the lick events
    bool timeout = false;
    int trial_outcome;
    long int time_start = millis();
    while (!timeout) {
        int right_lick_detected = digitalRead(RIGHT_LICK);
        if (side == RIGHT && right_lick_detected) {
            trial_outcome = CORRECT;
        } else if (side == LEFT && right_lick_detected) {
            trial_outcome = INCORRECT;
        }
        // check is time for trial is over
        long int time_now = millis();
        if (time_now - time_start > RESPONSE_DUR) {
            trial_outcome = NORESPONSE;
            timeout = true;
        }
    }

}


void play_tone(int side) {
    // determine the side related variables
    int speaker; int tone_freq; 
    if (side == LEFT) {
        tone_freq = LEFT_TONE;
        speaker = SPEAKER_LEFT;
    } else {
        tone_freq = RIGHT_TONE;
        speaker = SPEAKER_RIGHT;
    }
    // play the tone indicating the rewarded port
    // right_tone for the right, left_tone for the left
    for (int i=0; i<4; i++){
        tone(speaker, tone_freq);
        delay(150);
        noTone(speaker);
        delay(50);
    }
}

void go_sound() {
    for (int i = 0; i < go_durat; i++) {
        int toneValue = start_go_freq + i*incr_go_freq;
        tone(SPEAKERS_BOTH, toneValue); 
        delayMicroseconds(1000);  // Adjust this delay as needed for the desired audio quality
    }
    noTone(SPEAKERS_BOTH);
}
