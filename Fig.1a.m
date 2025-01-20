clc;
clear;

% Constants for data dimensions
NROW = 721;  % Number of rows
NCOL = 1440; % Number of columns

% Define parent directories for the data
Parent_Dir_U100 = 'E:\DATA\U100\';
Parent_Dir_V100 = 'E:\DATA\V100\';

% Define year range
startYr = 2004;
endYr = 2023;
numYears = endYr - startYr + 1;

% Initialize accumulation variables
totalTimeSteps = 0;
sumWPD = zeros(NCOL, NROW); 
sumwindspeed = zeros(NCOL, NROW); 

% Define chunk size to avoid memory issues (200 time steps as example)
chunkSize = 200;

% Loop through each year and process the data in chunks
for i = 1:numYears
    year = startYr + i - 1;
    fprintf('Processing year: %d\n', year);  % Display current year
    
    % Read the total number of time steps in the year (from the time variable)
    time = ncread([Parent_Dir_U100, num2str(year), '.nc'], 'time');
    numTimeSteps = length(time);
    
    % Process the data in chunks
    for startIdx = 1:chunkSize:numTimeSteps
        endIdx = min(startIdx + chunkSize - 1, numTimeSteps);
        fprintf('Processing time steps: %d to %d\n', startIdx, endIdx);
        
        % Read the chunk of data for the current time steps
        
        U100_chunk = ncread([Parent_Dir_U100, num2str(year), '.nc'], 'u100', ...
                           [1, 1, startIdx], [Inf, Inf, endIdx - startIdx + 1]);
        V100_chunk = ncread([Parent_Dir_V100, num2str(year), '.nc'], 'v100', ...
                           [1, 1, startIdx], [Inf, Inf, endIdx - startIdx + 1]);


        
        % Calculate wind speed and wind power density
        windSpeed_chunk = sqrt(U100_chunk.^2 + V100_chunk.^2);  % Calculate wind speed from U100 and V100
        windSpeed_chunk(windSpeed_chunk<4) = 0;   %cut-in
        windSpeed_chunk(windSpeed_chunk>=25) = 0;   %cut-out
        windSpeed_chunk(windSpeed_chunk>=13.5) = 13.5;  %rated
        WPD_chunk=0.5*0.32*1.213*(windSpeed_chunk.^3);
        
        
        % Accumulate sums for windSpeed and wind power density over the chunk of time steps
        sumWPD = sumWPD + sum(WPD_chunk, 3);  % Sum across time dimension
        sumwindspeed = sumwindspeed + sum(windSpeed_chunk, 3);
        
        % Update total time steps
        totalTimeSteps = totalTimeSteps + (endIdx - startIdx + 1);
    end
end

% Calculate average values
averageWPD = sumWPD / totalTimeSteps * 8760;  % Annualize by multiplying with hours per year
averagewindspeed = sumwindspeed / totalTimeSteps;
% Save results to .dat files
dlmwrite('WPD_AEP_AVE.dat', averageWPD, 'delimiter', '\t');
dlmwrite('WINDSPEED_AEP_AVE.dat', averagewindspeed, 'delimiter', '\t');

% Play a sound notification
load chirp;
sound(y, Fs);
