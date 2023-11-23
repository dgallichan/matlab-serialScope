% Basic 'scope' for live viewing and recording of serial streamed ASCII
% data
% - gallichand@cardiff.ac.uk 
% 2023 CC0 "no rights reserved"
% 
% I've found that although I've attempted to add the timestamps as the data
% arrives here in MATLAB, this adds another artificial 'jitter' to the
% timing - it is more accurate to add a milliseconds timestamp to the data
% before streaming it from your microcontroller.
%
% A simple example for what to put on a Micro:bit microcontroller can be
% found here: https://github.com/dgallichan/microbit-serialSendData
%
% IMPORTANT - don't forget to close the serial connections in other
% software running on your computer (e.g. Makecode browser, Arduino IDE,
% etc)

clear
close all

s = serialport("COM12", 115200); 

%%% create separate functions at the bottom of this file to handle your
%%% different data streams
scopePars = setPars_just3; % 3 comma separated variables
% scopePars = setPars_just3_plusFunc; % 3 comma separated variables, define a function to calculate magnitude as data arrives
% scopePars = setPars_time_plus3; % 4 parameters total, timestamp then 3 others, comma-separated
% scopePars = setPars_time_Mx_My_Mz_Gx_Gy_Gz_Ax_Ay_Az;


% create variables to store the data
sampleTimes = [];
sampleData = [];

if isfield(scopePars,'func')
    NplotLines = scopePars.Nvariables + length(scopePars.func);
else
    NplotLines = scopePars.Nvariables;
end

% Create a figure to display the live plot
hf = figure;
hf.Position = [ 50 50 1200 600]; % make plot bigger
hp = plot(duration(seconds(0)),NaN*ones(1,NplotLines),'linewidth',2); % Initialize an empty plot
ha = hp(1).Parent;
xlabel('Time');
ylabel('Data');
title('Waiting for data...  If you don''t see anything, check Command Window for parsing errors')
dummyTitle = true;
grid on; grid minor
xlim([0 seconds(scopePars.timeToShow_sec)])
drawnow

s.flush();

doLoop = true;
lastSampleTime = datetime('now') - days(1); % initialise as a while ago!

badDataReads = 0;

% Read and parse the data
while doLoop == true
    % Read a line of data from the serial port
    while s.NumBytesAvailable == 0
    end
    
    data = readline(s);
    timestamp = datetime('now');
    
    % Split the line into individual values using the comma as the delimiter
    values = str2double(split(data, scopePars.dataDelimiter))';
    values(isnan(values)) = [];

    % check the right number of variables are in the new data
    if length(values) ~= scopePars.Nvariables
        disp("Expected " + scopePars.Nvariables + " variables, received: " + length(values))
        badDataReads = badDataReads + 1;
        continue;
    else
        % Update the data
        sampleTimes = [sampleTimes; timestamp];
        sampleData = [sampleData; values];

        % update the plot (if we have waited enough time since last update)
        if milliseconds(timestamp - lastSampleTime) > scopePars.minUpdateTime_ms
            if dummyTitle
                title('Live Data - press any key to stop recording...')
                dummyTitle = false;
            end
            lastSampleTime = timestamp;

            iKeep = find(sampleTimes > sampleTimes(end)-seconds(scopePars.timeToShow_sec));
            thisTime = (sampleTimes(iKeep)-sampleTimes(iKeep(1)));

            % Update the plot with the new data points
            for iD = 1:scopePars.Nvariables
                if scopePars.varsToPlot(iD)
                    set(hp(iD), 'XData', thisTime,'YData', ((iD-1)*scopePars.varOffset) + scopePars.varScale(iD)*sampleData(iKeep,iD));
                end
            end
            if isfield(scopePars,'func')
                for iF = 1:length(scopePars.func)
                    set(hp(scopePars.Nvariables + iF), 'XData', thisTime,'YData', ((scopePars.Nvariables+iF-1)*scopePars.varOffset) + scopePars.func{iF}(sampleData(iKeep,:)));
                end
            end

            drawnow;
        end
    end    

    if hf.CurrentCharacter > 0
        break;
    end
end

% Close the serial port
clear s;

% Make a 'timetable' of the data
recordedData = timetable(sampleTimes,sampleData);

%% 

figure
plot(sampleTimes,sampleData(:,logical(scopePars.varsToPlot)))
title("All recorded data")
grid on; grid minor


%%
function scopePars = setPars_time_plus3
% 4 parameters total, timestamp then 3 others, comma-separated
    scopePars.timeToShow_sec = 10; % time window to display
    scopePars.Nvariables = 4;     % all variables assumed to be in one line of ASCII
    scopePars.dataDelimiter = ','; % how are the variables separated in the line

    scopePars.varScale = ones(1,scopePars.Nvariables);
    
    scopePars.varsToPlot = ones(1,scopePars.Nvariables);
    scopePars.varsToPlot(1) = 0; % decide whether or not to plot particular variables (for display only)
    % The first variable is likely to already be a timestamp
    % of some kind, rather than actual data.

    scopePars.varOffset = 0; % how much to offset variables by in the y-axis (for display only)
    
    scopePars.minUpdateTime_ms = 50; % mininum time to wait before updating the graph (doesn't affect actual data sampling)
    % Make sure this is not too short, otherwise
    % graph update can interfere with data transfer
end

%%
function scopePars = setPars_just3
% 3 parameters total, comma-separated
    scopePars.timeToShow_sec = 10; % time window to display
    scopePars.Nvariables = 3;     % all variables assumed to be in one line of ASCII
    scopePars.dataDelimiter = ','; % how are the variables separated in the line

    scopePars.varScale = ones(1,scopePars.Nvariables);
    
    scopePars.varsToPlot = ones(1,scopePars.Nvariables);
    % scopePars.varsToPlot(1) = 0; % decide whether or not to plot particular variables (for display only)
    % The first variable is likely to already be a timestamp
    % of some kind, rather than actual data.

    scopePars.varOffset = 0; % how much to offset variables by in the y-axis (for display only)
    
    scopePars.minUpdateTime_ms = 50; % mininum time to wait before updating the graph (doesn't affect actual data sampling)
    % Make sure this is not too short, otherwise
    % graph update can interfere with data transfer
end

%%
function scopePars = setPars_just3_plusFunc
% 3 parameters total, comma-separated
    scopePars.timeToShow_sec = 10; % time window to display
    scopePars.Nvariables = 3;     % all variables assumed to be in one line of ASCII
    scopePars.dataDelimiter = ','; % how are the variables separated in the line

    scopePars.varScale = ones(1,scopePars.Nvariables);
    
    scopePars.varsToPlot = ones(1,scopePars.Nvariables);
    % scopePars.varsToPlot(1) = 0; % decide whether or not to plot particular variables (for display only)
    % The first variable is likely to already be a timestamp
    % of some kind, rather than actual data.

    scopePars.varOffset = 0; % how much to offset variables by in the y-axis (for display only)
    
    scopePars.minUpdateTime_ms = 50; % mininum time to wait before updating the graph (doesn't affect actual data sampling)
    % Make sure this is not too short, otherwise
    % graph update can interfere with data transfer

    scopePars.func{1} = @(x) sqrt(sum(x.^2,2));
end


%%

function scopePars = setPars_time_Mx_My_Mz_Gx_Gy_Gz_Ax_Ay_Az

    scopePars.timeToShow_sec = 10; % time window to display
    scopePars.Nvariables = 10;     % all variables assumed to be in one line of ASCII
    scopePars.dataDelimiter = ','; % how are the variables separated in the line


    scopePars.varScale = ones(1,scopePars.Nvariables);
    scopePars.varScale(2:4) = 1000; % scale up mag force
    scopePars.varScale(8:10) = 100; % scale up acc

    scopePars.varsToPlot = ones(1,scopePars.Nvariables);
    scopePars.varsToPlot(1) = 0; % decide whether or not to plot particular variables (for display only)
    % The first variable is likely to already be a timestamp
    % of some kind, rather than actual data.

    % scopePars.varOffset = 0; % how much to offset variables by in the y-axis (for display only)
    scopePars.varOffset = 1e5;

    scopePars.minUpdateTime_ms = 50; % mininum time to wait before updating the graph (doesn't affect actual data sampling)
    % Make sure this is not too short, otherwise
    % graph update can interfere with data transfer

end

%%

