%runExpt
%
% Starter code for running a basic fly on ball expeirment using FicTrac to create a VR system
%
%   TODO: 
%   -integrate this with imaging software to sync up with
%   2photon data
%   -integrate with Rieser LED panels system and other wanted stimuli
%
% Yvette Fisher 3/2022
clear all;

%% Experiment Parameters

% Currently unused functionality 
USE_PANELS = false; %controls whether panels are used in trial (false -> off; true -> on)
USE_ANALOG_OUT = true; %controls whether an LED or other triggered devise is used (false -> off; true -> on)

% Configure panels, for closed loop mode and set up which pattern to use
% and set up external tiggering if you want things to
% start with a trigger, or just have the pattern start 
panelParams.panelModeNum = [3, 0];
panelParams.patternNum = 1;
panelParams.initialPosition = [0, 0];

% set full aq time if not sending analog out
fullTime = 10; % seconds

% Configure LED flashes (sample code for any analog output)
LEDParams.baselineTime = 1; %initial time LED off in second
LEDParams.LEDonTime = 15; % time LED on in second
LEDParams.afterTime = 4; % time LED off in second
LEDParams.REP_NUM = 10; %60*10=

%% Start FicTrac in background from current experiment directory (config file must be in directory)
FT_PATH = 'C:\Users\fisherlab\Documents\FicTrac211\';
FT_EXE_FILENAME = 'fictrac.exe';
cmdStr = ['cd "', FT_PATH, '" ', '& start ', FT_PATH, FT_EXE_FILENAME];
system(cmdStr); % run on windows system
pause(1);


% Call socket_client_360 to open socket connection from fictrac to Phiget22 device
% to edit socket_client_360 you can use PyCharm Edu
Socket_PATH = 'C:\Users\fisherlab\Documents\GitHub\FlyOnBall-Imaging-Code\';
SOCKET_SCRIPT_NAME = 'socket_client_360.py';
cmdstring = ['cd "' Socket_PATH '" & py ' SOCKET_SCRIPT_NAME ' &'];
[status] = system(cmdstring, '-echo');


%% Run panels
if(USE_PANELS)
    setUpClosedLoopPanelTrial(panelParams);    
    Panel_com('start');
end

% Recording the data!!!                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
% Fictrac ball heading (0-10V)
% Panel pattern postion (x pos)  

% Set NI (terminal block) config
%d = daqlist;  % uncomment to check NI devices connected to computer
%d{1, "DeviceInfo"}  %see NI device info 

% Setup data acquisition session (daq)
dq = daq("ni"); %create data acquisition object
addinput(dq,"Dev1", "ai0","Voltage"); % add analog input(AI) primary channel (xpos)
addinput(dq,"Dev1", "ai1","Voltage"); % add AI secondary channel (ball_heading/ yaw)
addinput(dq,"Dev1", "ai2","Voltage"); % add AI third channel (ball_heading/ xPos)
addinput(dq,"Dev1", "ai3","Voltage"); % add AI fourth channel (ball_heading/ yPos)
addinput(dq,"Dev1", "ai4","Voltage"); % add piezo position output
addinput(dq,"Dev1", "ai5","Voltage"); % add res frame start trigger 
addinput(dq,"Dev1", "ai6","Voltage"); % add Z trigger volume start
addoutput(dq, "Dev1", "ao0", "Voltage"); % add AO primary channel (output device timing triggers 100 Hz)

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

if(USE_ANALOG_OUT)
    commandOut = zeros(fullTime * dq.Rate, 1);
    if( mod(dq.Rate, TRIGGER_RATE) ~= 0 )
        warning('Error: your tigger rate must divide evenly into the aquisition rate')
    end

    for i = 1: int16(dq.Rate/TRIGGER_RATE) :length(commandOut)
    
        up_frames = ceil( TRIGGER_DUR*dq.Rate ); 
        commandOut(i: i + up_frames-1) = HIGHVOLTAGE;
    end


else
    % create empty commandOut for times when not used
    commandOut = zeros(fullTime * dq.Rate, 1);
end

%% Recording the data in forground
data = readwrite(dq, commandOut);

if(USE_PANELS)     % Turn panels off when aquisition is finished
    Panel_com('stop');
    Panel_com('all_off'); % LEDs panel off
end

%%

% % frame start
% plot((1:length(data.Dev1_ai5))/dq.Rate, data.Dev1_ai5); hold on;
% %piezo
% plot((1:length(data.Dev1_ai4))/dq.Rate, data.Dev1_ai4); hold on;
% 
% %volume start
% plot((1:length(data.Dev1_ai6))/dq.Rate, data.Dev1_ai6); hold on;


% change = diff(data.Dev1_ai5>2.5);
% startInd = find(change>0);
% endInd = find(change<0);
% 
% frameTimeList = (endInd - startInd) / dq.Rate;
% 
% breakTimeList = (startInd(2:end) - endInd(1:end-1)) / dq.Rate;




%% Save Data

% Store ball heading and panel position (x_pos) values in mV
x_pos = (data.Dev1_ai0); % DAC0 output from controller gives x frame 
ball_heading = (data.Dev1_ai1); % phidget output 
ball_xPos = (data.Dev1_ai2); % phidget output 
ball_yPos = (data.Dev1_ai3); % phidget output 
%% TODO !!!!!!
% save frame and piezo position information

% change V to angle
x_posRad = (x_pos) * (2 *pi) / 10;  % V to radians
ball_headingRad = (ball_heading) * (2 *pi) / 10;

x_posDeg = (x_pos) * 360 / 10;    % V to degrees
ball_headingDeg = (ball_heading) * 360 / 10;

ball_xPos = (ball_xPos) * 360 / 10;
ball_yPos = (ball_yPos) * 360 / 10;

% create larger struct for all data and recording conditions
ballData.data = data;
ballData.data.x_posDeg = x_posDeg;
ballData.data.ballHeadingDeg = ball_headingDeg;
ballData.data.ballxPosDeg = ball_xPos;
ballData.data.ballyPosDeg = ball_yPos;
ballData.data.x_posRad = x_posRad;
ballData.data.ballHeadingRad = ball_headingRad;
ballData.dqRate = dq.Rate;
ballData.data.LEDcommand = commandOut;

if(USE_PANELS)
    ballData.panelParams = panelParams;
end
if(USE_ANALOG_OUT)
    ballData.LEDParams = LEDParams;
end

% Save data  
saveData ('C:\Users\fisherlab\Dropbox\Data\ImagingData_2pPlus_Smaug\BallData\',ballData, 'Tianhao_EPG_imaging');

