// FicTrac reading variables
const int num_chars = 256;
char ft_chars[num_chars];
char _ft_chars[num_chars];
boolean ft_new_data = false;
int ft_index=0;
double ft_heading;
float ft_x;
float ft_y;
const byte ft_frame_pin = 2;
// put pwm pins on same flexPWM timer (FlexPWM1.2)
const byte ft_heading_pin = 7;
const byte ft_x_pin = 8; 
const byte ft_y_pin = 25;
const byte pwm_resolution = 12; // if you change this, need to change optimal fwm freq (https://www.pjrc.com/teensy/td_pulse.html)
const int max_pwm_val = 4095; // 0-4095 => <0-5 V>, change if you change pwm_resolution
const int optimal_pwm_freq = 36621.09; // 
//
const byte ft_num_cols = 26; 
const byte ft_dropped_frame_pin = 9; // still need to check

//Bruker Triggers
const byte bk_start_scan_pin = 4;
bool bk_start_scan_state = false;
int bk_start_scan_timestamp; 

const byte bk_kill_scan_pin = 5;
bool bk_kill_scan_state = false;
int bk_kill_scan_timestamp;

const byte bk_opto_trig_pin = 6;
bool bk_opto_trig_state = false;
int bk_opto_trig_timestamp;
const int bk_trig_timeout = 10;

const byte cam_trig_pin = 24;
int cam_pin_val;


// change FT pin to toggle each frame to that pin has time to get high


void setup() {
  // put your setup code here, to run once:

  // FicTrac setup
  // digital pins
  pinMode(ft_frame_pin,OUTPUT);
  digitalWrite(ft_frame_pin,LOW);
  pinMode(ft_dropped_frame_pin, OUTPUT); 
  digitalWriteFast(ft_dropped_frame_pin, LOW);

  // setup PWM pins
  analogWriteResolution(pwm_resolution); 
  pinMode(ft_heading_pin, OUTPUT);
  analogWriteFrequency(ft_heading_pin,optimal_pwm_freq); // optimal freq, should ft_x_pin and ft_y_pin freqs too but setting them too JIC
  pinMode(ft_x_pin, OUTPUT);
  analogWriteFrequency(ft_x_pin,optimal_pwm_freq); // should be redundant
  pinMode(ft_y_pin, OUTPUT);
  analogWriteFrequency(ft_y_pin,optimal_pwm_freq); // should be redundant
  
  // Bruker setup
  pinMode(bk_start_scan_pin, OUTPUT);
  digitalWriteFast(bk_start_scan_pin, LOW);
  bk_start_scan_timestamp = millis();
  pinMode(bk_kill_scan_pin, OUTPUT);
  digitalWriteFast(bk_kill_scan_pin, LOW);
  bk_kill_scan_timestamp = millis();
  pinMode(bk_opto_trig_pin, OUTPUT);
  digitalWriteFast(bk_opto_trig_pin, LOW);
  bk_opto_trig_timestamp = millis();

  // camera trig
  pinMode(cam_trig_pin,INPUT);
  
  
  
}


void yield() {} // get rid of hidden arduino yield function

FASTRUN void loop() { // FASTRUN teensy keyword
//  noInterrupts(); // prevent interrupts
//  while(1) {  // infinite loop to run as fast as possible
    ft_state();
    bk_state();

//    cam_pin_val = analogRead(cam_trig_pin);
//    if (cam_pin_val>90){
//      SerialUSB2.print("frame \t");
//      SerialUSB2.print(cam_pin_val);
//      SerialUSB2.print("\n");
//    } 
//  }
}

void ft_state() {
  recv_ft_data(); 
  if (ft_new_data == true) {
//    SerialUSB2.print(ft_chars); // for debugging
//    SerialUSB2.print('\t');
//    SerialUSB2.print(ft_index);
//    SerialUSB2.println();
    strcpy(_ft_chars, ft_chars); // prevent overwriting
    ft_state_machine();
    ft_index = (ft_index+1) % ft_num_cols; // keep track of columns in fictrack  
    ft_new_data = false;
  }
  
}

void recv_ft_data() { // receive Fictrack data
    
    static byte ndx = 0; // buffer index
    char delimiter = ','; // column delimiter
    char endline = '\n'; // endline character
    char rc; // current byte

    if (Serial.available() > 0) { // cannot use while(Serial.available()) because Teensy will read all 
        rc = Serial.read(); 
        if ((rc == endline)|(rc==delimiter)) { // end of frame or new column      
          ft_chars[ndx] = '\0'; // terminate the string
          ndx = 0; // restart buffer index
          ft_new_data = true;   // cue new data

          if (rc == endline) { // check to make sure this works, checks that columns are being counted correctly
            int _ft_index = ft_index + 1;
            if (_ft_index != (ft_num_cols )) {
              digitalToggle(ft_dropped_frame_pin);
//            ft_index = ft_num_cols-1;
            }
          }
          
        }
        else {
          ft_chars[ndx] = rc;
          ndx++;
          if (ndx >= num_chars) {
              ndx = num_chars - 1;
          } 
        }
    }
}

void ft_state_machine() {

  
  

  // switch case statement for variables of interest
  switch (ft_index) {
    
    case 0: // new FicTrac frame
      // flip ft pin high
      digitalWriteFast(ft_frame_pin,HIGH);
      break;

    case 17: // heading 
      // flip ft pin low 
      digitalWriteFast(ft_frame_pin,LOW);

      SerialUSB2.print("z \t");
      SerialUSB2.print(_ft_chars);
      SerialUSB2.print("\n");
      
      // update heading pin
      analogWrite(ft_heading_pin, int(max_pwm_val * atof(_ft_chars) / (2 * PI)));
      break;
    
    case 12: // x
      
      analogWrite(ft_x_pin, int(max_pwm_val * (atof(_ft_chars)+PI) / (2 * PI))); 
      break;

    case 13: // y
      
      analogWrite(ft_y_pin, int(max_pwm_val * (atof(_ft_chars)+PI) / (2 * PI))); 
      break;

    case 20: // x
      // debugging print x cumm
      SerialUSB2.print("x \t");
      SerialUSB2.print(_ft_chars);
      SerialUSB2.print("\t");

      break;

    case 21: // y
      // debugging print y cumm
      SerialUSB2.print("y \t");
      SerialUSB2.print(_ft_chars);
      SerialUSB2.print("\t");
      
      
      break;
  }
  
}


// col 1 frame counter
// col 2-4 delta rotation vector (x,y,z) cam coords
// col 5 delta rotation error
// col 6-8 delta rotation in lab coordinates
// col 9-11 abs. rot. vector cam coords
// col 12-14 abs. rot. vector lab coords
// col 15-16 integrated x/y lab coords
// col 17 integrated heading lab coords
// col 18 movement direction lab coords (add col 17 to get world centric direction)
// col 19 running speed. scale by sphere radius to get true speed
// col 20-21 integrated x/y neglecting heading
// col 22 timestamp either position in video file or frame capture time
// col 23 sequence counter - usually frame counter but can reset is tracking resets
// col 24 delta timestep since last frame
// col 25 alt timestamp - frame capture time (ms since midnight)


void bk_state() {
  int _cmd = 0;
  if (SerialUSB1.available() >0) {
    _cmd = SerialUSB1.parseInt();
  }
  bk_state_machine(_cmd);
    
}

void bk_state_machine(int cmd) {

  // flip triggers down
  int curr_timestamp = millis();
  if (bk_start_scan_state & ((curr_timestamp - bk_start_scan_timestamp) > bk_trig_timeout)) {
    digitalWriteFast(bk_start_scan_pin,LOW);
    bk_start_scan_state=false;
  }
  if (bk_kill_scan_state & ((curr_timestamp - bk_kill_scan_timestamp) > bk_trig_timeout)) {
    digitalWriteFast(bk_kill_scan_pin,LOW);
    bk_kill_scan_state=false;
  }
  if (bk_opto_trig_state & ((curr_timestamp - bk_opto_trig_timestamp) > bk_trig_timeout)) {
    digitalWriteFast(bk_opto_trig_pin,LOW);
    bk_opto_trig_state=false;
  }
  
  switch(cmd){
    case 0: // do nothing
      break;
    case 1: // flip start scan trigger high
      digitalWriteFast(bk_start_scan_pin, HIGH);
      bk_start_scan_state = true;
      bk_start_scan_timestamp = millis();
      break;
    case 2: // flip kill scan trigger high
      digitalWriteFast(bk_kill_scan_pin, HIGH);
      bk_kill_scan_state = true;
      bk_kill_scan_timestamp = millis();
      break;
    case 3: // flip opto scan trigger high
      digitalWriteFast(bk_opto_trig_pin, HIGH);
      bk_opto_trig_state = true;
      bk_opto_trig_timestamp = millis();
      break;
  }

}
