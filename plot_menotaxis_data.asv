
clear all;
% Import file with data to plot
importfile('Ball_Testing_001_4_6_2022220406_trial_1')

%% Plot data in sec 
+
figure;
plot( [1:1:length(ballData.data.LEDcommand)]/ballData.dqRate ,ballData.data.ballHeadingDeg);

%% Plot data in sec 
figure;
plot( [1:1:length(ballData.data.LEDcommand)]/ballData.dqRate ,ballData.data.Dev1_ai3);
%% 
%hold on;
figure;
plot( [1:1:length(ballData.data.LEDcommand)]/ballData.dqRate ,ballData.data.ballyPosDeg);
%%
figure;
plot( [1:1:length(ballData.data.LEDcommand)]/ballData.dqRate ,ballData.data.ballxPosDeg);

figure;
plot( [1:1:length(ballData.data.LEDcommand)]/ballData.dqRate ,ballData.data.ballyPosDeg);



%% Plot data in min
figure;
plot( [1:1:length(ballData.data.LEDcommand)]/(60*ballData.dqRate) ,ballData.data.ballHeadingDeg);
%hold on;
figure;
plot( [1:1:length(ballData.data.LEDcommand)]/(60*ballData.dqRate) ,ballData.data.x_posDeg);


%% histogram - to check if results are random vs. she's actually menotaxing
%figure;
%hist.plot = histogram(ballData.data.ballHeadingDeg);
figure;
%hist.plot = histogram(ballData.data.ballyPosDeg);
%figure;
hist.plot = histogram(ballData.data.ballxPosDeg);


%% Calculate velocity

%sampleTheta = [0,pi/2,pi,4*pi/3,2*pi,5.2];%for troubleshooting
%t = [1,2,3,4,5,6]
%v = diff(sampleTheta)/diff(t);

pos = ballData.data.ballHeadingDeg;
%time = [];
%for i = 1:length(ballData.data.ballHeadingDeg)
 %   time(i,1) = i;
%end

v = diff(pos);
v = v/ballData.dqRate;
%vTotal = mean(v);

figure;
plot([1:1:length(ballData.data.LEDcommand)-1]/ballData.dqRate ,v);




%% create intervals of each min in data

INTERVAL_LENGTH = 60; %seconds
totalNumIntervals = length(ballData.data.ballHeadingDeg)/(ballData.dqRate*INTERVAL_LENGTH);
totalNumIntervals = floor(totalNumIntervals);
figure;

for i = 1:totalNumIntervals
    x = [];
    y = [];
    startInt = [ballData.dqRate *(i-1)*INTERVAL_LENGTH] + 1;
    endInt = i * ballData.dqRate *INTERVAL_LENGTH;
    currMin = ballData.data.ballHeadingRad(startInt:endInt);
    [xMean,yMean] = meanVector (currMin);
    [xMeanTot,yMeanTot] = meanVector (ballData.data.ballHeadingRad);
   % for k = 1:length(currMin)
%         theta =currMin(k);
%         vLength =1; % vector size
%         [x(k),y(k)] = pol2cart (theta,vLength);
%     end
%     xMean = mean(x);
%     yMean = mean(y);
    compass(xMean,yMean);
    c= compass(xMeanTot,yMeanTot,'r');
    c.LineWidth = 4;
    title(['Dot Trial 38A11']);
    hold on;

end




function [xMean,yMean]= meanVector(data)

for k = 1:length(data)
    theta =data(k);
    vLength =1; % vector size
    [x(k),y(k)] = pol2cart (theta,vLength);
end
xMean = mean(x);
yMean = mean(y);

end







    
