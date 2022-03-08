function [ ] = setUpClosedLoopPanelTrial( panelParams )
%SETUPCLOSEDLOOPPANELTRIAL Intializes the Panel visual display system by
%setting up which Pattern and which Position_Function will be used. 
%    
% This function is meant to set up a Pattern to be ready to be played using
% the Panel Arena system.  
%
% INPUT 
% panelParams - struct containing parameters of this trial
%
% Yvette Fisher 1/2022

% Check patternNum exists
%panelParams.patternNum = 1; %MATC added it for troubleshooting
if(~isfield( panelParams, 'patternNum'))
    error('Error: panelParams.patternNum field was not set ')
end

% POSITION FUNCTION 
% note - not used for dimiention that is in closed loop but useful to still
% set to avoid Panel issues
if(~isfield( panelParams, 'positionFuncNumX'))
    % default behavior
    panelParams.positionFuncNumX = 1;
end

if(~isfield( panelParams, 'positionFuncNumY'))
    % default behavior
    panelParams.positionFuncNumY = 1;
end

% FREQUENCY PARAMETERS
% if funcx_freq or funcy_freq are not set, use default values
if( ~isfield(panelParams,'funcx_freq') || ~isfield(panelParams,'funcy_freq')) 
    % default behavior
    panelParams.funcx_freq = 50; % Hz
    panelParams.funcy_freq = 50; % Hz
end
% check that x/y frequencys are the same
if(panelParams.funcx_freq ~= panelParams.funcy_freq)
    error('Error: frequency settings for x and y should match to avoid issues (panelParams.funcx_freq & panelParams.funcy_freq)');
end

% CHANNEL PARAMS
% 1:X channel    2:Y channel
X_channelNum = 1;
Y_channelNum = 2;

     
% *************** SET-UP PANELS******************** by loading to controller/LED system

% SET PATTERN ID NUMBER
Panel_com('set_pattern_id', panelParams.patternNum);
pause(.03)

% SET INITIAL PATTERN POSITION
% This is used if you want the user to be able to set the bar position/initial pattern position, 
% which depending on the pattern will either set the initial location in x
% but can also set the initial ypos or contrast
initPanelPosition = [0, 0]; %dafault behavior
if( isfield( panelParams, 'initialPosition' ))
    
    % if only x pos is specified
    if( numel(panelParams.initialPosition) == 1) % initial x-pos
        initPanelPosition(1) =  panelParams.initialPosition;
     
    % if x and y pos are specified    
    elseif (numel(panelParams.initialPosition) == 2) %intial x,y positions
        initPanelPosition(1) =  panelParams.initialPosition(1);
        initPanelPosition(2) =  panelParams.initialPosition(2);
    else
        disp('WARNING: panelParams.initialPosition did not have the expected number of elements (1 or 2), the default: [0 0] was used for intial panel positions');
    end
    
end
Panel_com('set_position',initPanelPosition + 1);% offset the position functions, add 1 to counter act Panel_com behavior
             % Caution: Panel_com automatically subtract 1 from init_pos.
pause(.03) 

% SET CONTROLLER MODE
% – sets the mode for the controller%s X and Y channels
% Arguments: 2 values to set the mode for X and Y channels. 0 – open loop, 1 – closed loop, 2 – both, closed loop plus function as bias, 3 – External input sets position, 4 – Internal function generator sets velocity/position, 5 – internal function generator debug mode.
% Usage: Panel_com(‘set_mode’, [0 1]); % X to open loop, Y to closed loop.

% Closed Loop setting
if( ~isfield(panelParams,'panelModeNum')) 
    % default behavior
    panelParams.panelModeNum = [3, 0];
    warning('panelParams.panelModeNum = default');

end

%PANEL_MODE_NUMS = [3 , 0]; % ClosedLoop 3 – External input sets position using ficTrac signal
% Possible update: add this as a input field if we want to use different closed loop or
% open loop settings

Panel_com('set_mode', panelParams.panelModeNum);
pause(.03)

Panel_com( 'set_funcy_freq' , panelParams.funcy_freq ); % set y freq
pause(.03)

% takes argeuments [channel num, positionFunc number] 
Panel_com( 'set_posfunc_id', [ X_channelNum, panelParams.positionFuncNumX ] );
pause(.03)

Panel_com( 'set_funcx_freq', panelParams.funcx_freq ); % set x freq
pause(.03)

% takes argeuments [channel num, positionFunc number] 
Panel_com( 'set_posfunc_id',[ Y_channelNum, panelParams.positionFuncNumY ] );
pause(.03)
% 

end
