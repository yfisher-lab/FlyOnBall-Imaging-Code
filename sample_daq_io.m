% set full aq time if not sending analog out
fullTime = 10; % seconds

dq = daq("ni"); %create data acquisition object
addinput(dq,"Dev1", "ai0","Voltage"); % add analog input(AI) primary channel (xpos)
addinput(dq,"Dev1", "ai1","Voltage"); % add AI secondary channel (ball_heading/ yaw)
addinput(dq,"Dev1", "ai2","Voltage"); % add AI third channel (ball_heading/ xPos)
addinput(dq,"Dev1", "ai3","Voltage"); % add AI fourth channel (ball_heading/ yPos)
addinput(dq,"Dev1", "ai4","Voltage"); % add piezo position output
addinput(dq,"Dev1", "ai5","Voltage"); % add res frame start trigger 
addinput(dq,"Dev1", "ai6","Voltage"); % add Z trigger volume start
addoutput(dq, "Dev1", "ao0", "Voltage"); % add AO primary channel (output device timing triggers 100 Hz)
addoutput(dq,"Dev1", "Port0/Line0","Digital")
addoutput(dq,"Dev1", "Port0/Line1","Digital")

dq.Channels(1).TerminalConfig = 'SingleEnded'; %save info that channel is in single ended on BOB 
dq.Channels(2).TerminalConfig = 'SingleEnded';
dq.Channels(3).TerminalConfig = 'SingleEnded';
dq.Channels(4).TerminalConfig = 'SingleEnded';
dq.Channels(5).TerminalConfig = 'SingleEnded';
dq.Channels(6).TerminalConfig = 'SingleEnded';
dq.Channels(7).TerminalConfig = 'SingleEnded';


%% Build commandOut for triggering devices 
% create empty commmand out array
commandOut = [];
HIGHVOLTAGE = 5; % V
dq.Rate = 1000; % set sample rate for daq

TRIGGER_RATE = 100;
TRIGGER_DUR =  0.001; % seconds


commandOut = zeros(fullTime * dq.Rate, 1);
if( mod(dq.Rate, TRIGGER_RATE) ~= 0 )
    warning('Error: your tigger rate must divide evenly into the aquisition rate')
end

for i = 1: int16(dq.Rate/TRIGGER_RATE) :length(commandOut)

    up_frames = ceil( TRIGGER_DUR*dq.Rate ); 
    commandOut(i: i + up_frames-1) = HIGHVOLTAGE;
end

dig_out = zeros(fullTime * dq.Rate, 1);
dig_out(floor(dq.Rate*fullTime/2):end-10) = 1;

dig_out2 = zeros(fullTime * dq.Rate, 1);
dig_out2(3*floor(dq.Rate*fullTime/4):end-10) = 1;

%% Recording the data in forground
data = readwrite(dq, [commandOut, dig_out, dig_out2]);

% Store ball heading and panel position (x_pos) values in mV
x_pos = (data.Dev1_ai0); % DAC0 output from controller gives x frame 
ball_heading = (data.Dev1_ai1); % phidget output 
ball_xPos = (data.Dev1_ai2); % phidget output 
ball_yPos = (data.Dev1_ai3); % phidget output 