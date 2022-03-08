function [] = saveData( directory , ballData, expName)
%SAVEDATA
% INPUT
%       directory - location where the data should be saved
%       ballData - data to be saved in that location
%       expName - experiment name/ type ie BallData
%
% The data will be saved as %'BallData_YYMMDD_trial_##'
% where YY== year, MM = month, DD= day and ## is the next trial that
% doesn't yet exist in that folder for that date
%
% Yvette Fisher and Jessica Co 2/2022

% make date number string
format = 'yymmdd';  %YYMMDD format
fileNamePrefix = [ expName datestr(now, format) ]; % today's date ie 'BallData_161014'

% navigate to data directory
cd(directory)

%Check how many .mat files contain fileNamePrefix
fileList = dir(fullfile(directory,'*.mat'));

counter = 1;
for i = 1:length(fileList)

    currFile = fileList(i);
    if( contains(currFile.name, fileNamePrefix) )
        counter = counter + 1;
    end
end

fullFileName = [fileNamePrefix '_trial_' num2str(counter)];
% e.g. 'BallData_161014_trial_##'

%save your variable with the full file name
save(fullFileName, 'ballData')

end