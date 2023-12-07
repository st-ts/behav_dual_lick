



#define SPEAKERS_BOTH 8
#define SPEAKER_LEFT 9
#define SPEAKER_RIGHT 10

// Wires from rasp signling which speaker to turn on
#define RASP_GO 1
#define RASP_TONE_LEFT 2
#define RASP_TONE_RIGHT 3

#define LEFT_TONE 10000
#define RIGHT_TONE 3000

#define RESPONSE_DUR 1000
#define REWARD_COLLECION_DUR 1000

const int start_go_freq = 200;  // 6 kHz carrier frequency
const int incr_go_freq = 50;  // 360 Hz modulating frequency
const int go_durat = 100;
const int left_tone = 10000;
const int right_tone = 3000;



void setup() {
    // init all those damn pins
    pinMode(SPEAKER_LEFT, OUTPUT);
    pinMode(SPEAKER_RIGHT, OUTPUT);
    pinMode(SPEAKERS_BOTH, OUTPUT);
    pinMode(RASP_GO, INPUT);
    pinMode(RASP_TONE_LEFT, INPUT);
    pinMode(RASP_TONE_RIGHT, INPUT);
}

void loop() {

    int tone_go = digitalRead(RASP_GO);
    int tone_left = digitalRead(RASP_TONE_LEFT);
    int tone_right = digitalRead(RASP_TONE_RIGHT);

    // If not too many left/right trials, deliver a reward
    if (tone_go) {
        go_sound();
    } else if (tone_left) {
        play_tone(RASP_TONE_LEFT);
    } else if (tone_right) {
        play_tone(RASP_TONE_RIGHT);
    }
}


void play_tone(int side) {
    // determine the side related variables
    int speaker; int tone_freq; 
    if (side == RASP_TONE_LEFT) {
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
    tone(speaker, tone_freq);
    delay(150);
    noTone(speaker);
    go_sound();
}

void go_sound() {
    for (int i = 0; i < go_durat; i++) {
        int toneValue = start_go_freq + i*incr_go_freq;
        tone(SPEAKERS_BOTH, toneValue); 
        delayMicroseconds(1000);  // Adjust this delay as needed for the desired audio quality
    }
    noTone(SPEAKERS_BOTH);
    delay(500);

}
