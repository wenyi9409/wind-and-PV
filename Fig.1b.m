
clc;
clear;


NROW = 721;  % Number of rows
NCOL = 1440; % Number of columns


Parent_Dir_PV  = 'E:\DATA\PV\';
Parent_Dir_U10 = 'E:\DATA\U10\';
Parent_Dir_V10 = 'E:\DATA\V10\';
Parent_Dir_T2M = 'E:\DATA\T2M\';

% Define year range
startYr = 2004;
endYr = 2023;
numYears = endYr - startYr + 1;

% Initialize accumulation variables
totalTimeSteps = 0;
sumPV = zeros(NCOL, NROW); 
sumEfficiency = zeros(NCOL, NROW);  

% Define chunk size to avoid memory issues (200 time steps as example)
chunkSize = 200;

% Loop through each year and process the data in chunks
for i = 1:numYears
    year = startYr + i - 1;
    fprintf('Processing year: %d\n', year);  % Display current year
    
    % Read the total number of time steps in the year (from the time variable)
    time = ncread([Parent_Dir_PV, num2str(year), '.nc'], 'time');
    numTimeSteps = length(time);
    
    % Process the data in chunks
    for startIdx = 1:chunkSize:numTimeSteps
        endIdx = min(startIdx + chunkSize - 1, numTimeSteps);
        fprintf('Processing time steps: %d to %d\n', startIdx, endIdx);
        
        % Read the chunk of data for the current time steps
        PV_chunk  = ncread([Parent_Dir_PV, num2str(year), '.nc'], 'ssrd', ...
                           [1, 1, startIdx], [Inf, Inf, endIdx - startIdx + 1]);
        T2M_chunk = ncread([Parent_Dir_T2M, num2str(year), '.nc'], 't2m', ...
                           [1, 1, startIdx], [Inf, Inf, endIdx - startIdx + 1]);
        U10_chunk = ncread([Parent_Dir_U10, num2str(year), '.nc'], 'u10', ...
                           [1, 1, startIdx], [Inf, Inf, endIdx - startIdx + 1]);
        V10_chunk = ncread([Parent_Dir_V10, num2str(year), '.nc'], 'v10', ...
                           [1, 1, startIdx], [Inf, Inf, endIdx - startIdx + 1]);

        % Convert negative PV values to 0 and adjust units
        PV_chunk(PV_chunk < 0) = 0;
        PV_chunk = PV_chunk / 3600;  % Convert from J/m² to W/m²
        
        % Calculate wind speed and temperature adjustments
        windSpeed_chunk = sqrt(U10_chunk.^2 + V10_chunk.^2);  % Calculate wind speed from U10 and V10
        T2M_chunk = T2M_chunk - 273.15;  % Convert temperature from Kelvin to Celsius
        
        % Calculate cell temperature and efficiency
        cellTemp_chunk = 2.0458 + 0.9458 * T2M_chunk + 0.0215 * PV_chunk - 1.2376 * windSpeed_chunk;
        efficiency_chunk = 0.17 * (1 - 0.005 * (cellTemp_chunk - 25));
        
        % Adjust PV based on efficiency
        PV_chunk = PV_chunk .* efficiency_chunk;
        
        % Accumulate sums for PV and efficiency over the chunk of time steps
        sumPV = sumPV + sum(PV_chunk, 3);  % Sum across time dimension
        sumEfficiency = sumEfficiency + sum(efficiency_chunk, 3);
        
        % Update total time steps
        totalTimeSteps = totalTimeSteps + (endIdx - startIdx + 1);
    end
end

% Calculate average values
averagePV = sumPV / totalTimeSteps * 8760;  % Annualize by multiplying with hours per year
averageEfficiency = sumEfficiency / totalTimeSteps;

% Save results to .dat files
dlmwrite('Solar_AEP_AVE.dat', averagePV, 'delimiter', '\t');
dlmwrite('Solar_ETA_AVE.dat', averageEfficiency, 'delimiter', '\t');

% Play a sound notification
load chirp;
sound(y, Fs);
