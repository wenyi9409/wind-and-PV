clc;
clear;

% Get all .mat files
files = dir('F:\DATA\interest_areas\EEZ_Mask\*.mat'); 
num_files = length(files);

% Load data file
IA_MASK = load('F:\DATA\interest_areas\new\interest_area_Mask_005_PV.mat', 'interest_area_Mask_005');

% Mask out areas outside of EEZ (set non-EEZ regions to NaN)
IA_PV = IA_MASK.interest_area_Mask_005;

% Initialize results table
results = cell(num_files, 3);  % 3 columns: file name, country_power, country_offshore_area

for i = 1:num_files
    GRID_PV = load('F:\DATA\AEP\Power_grid_PV_005.dat');  
    GRID_AREA = load('F:\DATA\AEP\grid_area_005.dat'); 
    disp(['Processing file: ', files(i).name]);

    % Load the current .mat file and extract 'countryMask'
    MASK_COUNTRY = load(fullfile(files(i).folder, files(i).name), 'countryMask');
    countryMask = MASK_COUNTRY.countryMask;  % Extract countryMask from the structure
    MASK = countryMask & IA_PV;  % Perform logical AND operation
    MASK1 = MASK(1:3600, 1:7200);
    
    % Use the mask to filter out non-EEZ regions (set non-EEZ regions to 0)
    GRID_PV(MASK1 == 0) = 0;
    GRID_AREA(MASK1 == 0) = 0;
    GRID_PV = GRID_PV * 0.01;

    % Calculate offshore PV power and offshore area for the country
    country_power = sum(sum(GRID_PV));
    country_offshore_area = sum(sum(GRID_AREA));

    % Store the results of the current file into the cell array
    results{i, 1} = files(i).name;               % File name
    results{i, 2} = country_power;               % Offshore PV power
    results{i, 3} = country_offshore_area;       % Offshore area
end

% Convert the results to a table and save to an Excel file
result_table = cell2table(results, 'VariableNames', {'FileName', 'CountryPower', 'CountryOffshoreArea'});
writetable(result_table, 'Power_Area_Results_PV_005.xlsx');

