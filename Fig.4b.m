clc
clear
WIND = zeros(285, 12);
PV = zeros(285, 12);

for i = 1:12
    i
    % Construct the file name
    filename1 = sprintf('Power_Area_Results_WIND%d_005.xlsx', i);
    filename2 = sprintf('Power_Area_Results_PV%d_005.xlsx', i);
    
    % Read the second row of the file
    WIND(:, i) = readmatrix(filename1, 'Range', 'B2:B286'); % WIND data
    PV(:, i) = readmatrix(filename2, 'Range', 'B2:B286');   % PV data
end

h = [ ... % Hemisphere indicator (1 = North, 2 = South, 0 = excluded, NaN = missing data)
    1, 1, 2, 1, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 2, ...
    % (data continues, truncated for brevity)
];

for j = 1:285
    A = WIND(j, :);  
    B = PV(j, :);
    Amean = mean(A);
    Bmean = mean(B);
    if Amean < Bmean
        diffMatrix = Amean / Bmean;
        B = B * diffMatrix;
        PV(j, :) = B;
    else
        diffMatrix = Bmean / Amean;
        A = A * diffMatrix;
        WIND(j, :) = A;
    end
end

clear i

% Define color mapping (12 different colors)
colors = [ 
    81   9 121;
   149  15 223;
   183  75 243;
   203 126 246;
   225 180 250;
   236 208 252;
   255 245 204;
   255 230 112;
   255 204  51;
   255 175  51;
   255 111   0;
   230  40  30
];

colors = colors / 256; 

% Define month labels
months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', ...
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};


figure;
% plot([-3, 4], [-3, 4], 'k--', 'LineWidth', 1);  % Add 1:1 line with black dashed style
hold on;

% Loop through each file for the Northern Hemisphere
for i = 1:12
    % Read the second row of the file
    data1 = WIND(:, i); % WIND data
    data2 = PV(:, i);   % PV data
    ndata1 = data1(h == 1);
    ndata2 = data2(h == 1);

    % Apply log10 transformation to the data
    x = log10(ndata1);
    y = log10(ndata2);

    % Plot scatter plot with specified color and size
    scatter(x, y, 20, 's', 'filled', 'MarkerFaceColor', colors(i, :), 'DisplayName', months{i});
end

hold on;

% Loop through each file for the Southern Hemisphere
for i = 1:12
    % Read the second row of the file
    data1 = WIND(:, i); % WIND data
    data2 = PV(:, i);   % PV data
    ndata1 = data1(h == 2);
    ndata2 = data2(h == 2);

    % Apply log10 transformation to the data
    x = log10(ndata1);
    y = log10(ndata2);

    % Plot scatter plot with specified color and size
    scatter(x, y, 10, 'o', 'filled', 'MarkerFaceColor', colors(i, :), 'DisplayName', months{i});
end

% Set axis limits
xlim([-3, 3]);
ylim([-3, 3]);

% Add legend and labels
xlabel('Electricity output from offshore wind (TWh) log10', 'FontSize', 10);
ylabel('Electricity output from offshore PV (TWh) log10', 'FontSize', 10);

hold off;
print('scatter_month_output_color', '-dpng', '-r300');  % Save as a high-resolution PNG file
