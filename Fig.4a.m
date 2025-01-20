
clc;
clear;

% Constants for data dimensions
NROW = 721;  % Number of rows
NCOL = 1440; % Number of columns

% Define parent directories for the data
Parent_Dir_U100 = 'E:\DATA\U100\';
Parent_Dir_V100 = 'E:\DATA\V100\';

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
sumXY = zeros(NCOL, NROW); 
stdX = zeros(NCOL, NROW); 
stdY = zeros(NCOL, NROW);
X=load('E:\DATA\AEP\WPD_AEP_AVE.dat');
X=X/8760;
Y=load('E:\DATA\AEP\Solar_AEP_AVE.dat');
Y=Y/8760;

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
        
        % Read the chunk of data for the wind
        
        U100_chunk = ncread([Parent_Dir_U100, num2str(year), '.nc'], 'u100', ...
                           [1, 1, startIdx], [Inf, Inf, endIdx - startIdx + 1]);
        V100_chunk = ncread([Parent_Dir_V100, num2str(year), '.nc'], 'v100', ...
                           [1, 1, startIdx], [Inf, Inf, endIdx - startIdx + 1]);


        
        % Calculate wind speed 
        windSpeed_chunk = sqrt(U100_chunk.^2 + V100_chunk.^2);  % Calculate wind speed from U10 and V10
        windSpeed_chunk(windSpeed_chunk<4) = 0;   %cut-in
        windSpeed_chunk(windSpeed_chunk>=25) = 0;   %cut-out
        windSpeed_chunk(windSpeed_chunk>=13.5) = 13.5;  %rated
        WPD_chunk=0.5*0.32*1.213*(windSpeed_chunk.^3);

         % Read the chunk of data for PV
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

                
        
        % Accumulate sums for windSpeed and efficiency over the chunk of time steps
        sumXY = sumXY + sum((WPD_chunk-X).*(PV_chunk-Y), 3);  % Sum across time dimension

        % Accumulate sums for PV and efficiency over the chunk of time steps
        stdX = stdX + sum((WPD_chunk-X).^2, 3);  % Sum across time dimension
        stdY = stdY + sum((PV_chunk-Y).^2, 3);  % Sum across time dimension
        
        % Update total time steps
        totalTimeSteps = totalTimeSteps + (endIdx - startIdx + 1);
    end
end

% Calculate COR
COR=sumXY./(sqrt(stdX).*sqrt(stdY));
% Save results to .dat files
dlmwrite('WPD_PV_COR.dat', COR, 'delimiter', '\t');

% Play a sound notification
load chirp;
sound(y, Fs);
