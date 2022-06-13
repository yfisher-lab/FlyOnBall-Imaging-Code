const byte numChars = 32;
char receivedChars[numChars];
char tempChars[numChars];

boolean newData = false;


void setup() {
  // put your setup code here, to run once:
  
  
}

void loop() {
  // put your main code here, to run repeatedly:
  recvWithStartEndMarkers();
  if (newData == true) {
      strcpy(tempChars, receivedChars);
          // this temporary copy is necessary to protect the original data
          //   because strtok() used in parseData() replaces the commas with \0
      parseData();
      showParsedData();
      newData = false;
  }
    
    
    

}


void recvWithStartEndMarkers() {
    static boolean recvInProgress = false;
    static byte ndx = 0;
    char startMarker = 'FT';
    char endMarker = '\n';
    char rc;

    while (Serial.available() > 0 && newData == false) {
        rc = Serial.read();

        if (recvInProgress == true) {
            if (rc != endMarker) {
                receivedChars[ndx] = rc;
                ndx++;
                if (ndx >= numChars) {
                    ndx = numChars - 1;
                }
            }
            else {
                receivedChars[ndx] = '\0'; // terminate the string
                recvInProgress = false;
                ndx = 0;
                newData = true;
            }
        }

        else if (rc == startMarker) {
            recvInProgress = true;
        }
    }
}



void parseData() {      // split the data into its parts

    char * strtokIndx; // this is used by strtok() as an index

    
    // col 1 frame counter
    strtokIndx = strtok(tempChars, ",");
    int framecount = atoi(strtokIndx);

    // col 2-4 delta rotation vector (x,y,z) cam coords
    strtokIndx = strtok(NULL, ",");
    float d_rot_cam_x = atof(strtokIndx);
    strtokIndx = strtok(NULL, ",");
    float d_rot_cam_y = atof(strtokIndx);
    strtokIndx = strtok(NULL, ",");
    float d_rot_cam_z = atof(strtokIndx);

    // col 5 delta rotation error
    strtokIndx = strtok(NULL, ",");
    float d_rot_err = atof(strtokIndx); 

    // col 6-8 delta rotation in lab coordinates
    strtokIndx = strtok(NULL, ",");
    float d_rot_lab_x = atof(strtokIndx);
    strtokIndx = strtok(NULL, ",");
    float d_rot_lab_y = atof(strtokIndx);
    strtokIndx = strtok(NULL, ",");
    float d_rot_lab_z = atof(strtokIndx);

    // col 9-11 abs. rot. vector cam coords
    strtokIndx = strtok(NULL, ",");
    float abs_rot_cam_x = atof(strtokIndx);
    strtokIndx = strtok(NULL, ",");
    float abs_rot_cam_y = atof(strtokIndx);
    strtokIndx = strtok(NULL, ",");
    float abs_rot_cam_z = atof(strtokIndx);

    // col 12-14 abs. rot. vector lab coords
    strtokIndx = strtok(NULL, ",");
    float abs_rot_lab_x = atof(strtokIndx);
    strtokIndx = strtok(NULL, ",");
    float abs_rot_lab_y = atof(strtokIndx);
    strtokIndx = strtok(NULL, ",");
    float abs_rot_lab_z = atof(strtokIndx);

    // col 15-16 integrated x/y lab coords
    strtokIndx = strtok(NULL, ",");
    float integ_lab_x = atof(strtokIndx);
    strtokIndx = strtok(NULL, ",");
    float integ_lab_y = atof(strtokIndx);
    
    // col 17 integrated heading lab coords
    strtokIndx = strtok(NULL, ",");
    float integ_lab_head = atof(strtokIndx);

    // col 18 movement direction lab coords (add col 17 to get world centric direction)
    strtokIndx = strtok(NULL, ",");
    float move_dir = atof(strtokIndx);

    // col 19 running speed. scale by sphere radius to get true speed
    strtokIndx = strtok(NULL, ",");
    float walk_speed = atof(strtokIndx);

    // col 20-21 integrated x/y neglecting heading
    strtokIndx = strtok(NULL, ",");
    float integ_sanshead_x = atof(strtokIndx);
    strtokIndx = strtok(NULL, ",");
    float integ_sanshead_y = atof(strtokIndx);

    // col 22 timestamp either position in video file or frame capture time
    strtokIndx = strtok(NULL, ",");
    float frame_cap_time = atof(strtokIndx);

    // col 23 sequence counter - usually frame counter but can reset is tracking resets
    strtokIndx = strtok(NULL, ",");
    int seq_counter = atoi(strtokIndx);

    // col 24 delta timestep since last frame
    strtokIndx = strtok(NULL, ",");
    float d_frame = atof(strtokIndx);

    // col 25 alt timestamp - frame capture time (ms since midnight)
    strtokIndx = strtok(NULL, ",");
    float frame_cap_time_abs = atof(strtokIndx);
    

}

void showParsedData() {
    SerialUSB1.println("New Frame");
//    Serial.println(messageFromPC);
//    Serial.print("Integer ");
//    Serial.println(integerFromPC);
//    Serial.print("Float ");
//    Serial.println(floatFromPC);
}
