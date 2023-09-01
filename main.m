global allPeakData; 
allPeakData = {};
mainScript();

function mainScript()

    % Create an empty map to cache data
    imageCache = containers.Map('KeyType', 'char', 'ValueType', 'any');

    % Select the images to be inputted
    [imageFiles, pathin, scaleRatio, shellname, scaleInMicrometers] = inputImages();

    % Initial value
    a = 1;

    % Next and previous buttons
    uicontrol('Style', 'pushbutton', 'String', 'Next', 'Position', [1800 42 50 20],...
        'Callback', @(src, ~) processImage(src.UserData + 1, imageFiles, scaleRatio), 'UserData', a, 'Tag', 'nextBtn');
    uicontrol('Style', 'pushbutton', 'String', 'Previous', 'Position', [1750 42 50 20],...
        'Callback', @(src, ~) processImage(max(src.UserData - 1, 1), imageFiles, scaleRatio), 'UserData', a, 'Tag', 'prevBtn');
    
    % Call initial processing
    processImage(a, imageFiles, scaleRatio, imageCache);
end

function processImage(index, imageFiles, scaleRatio, imageCache, sliderValueText)
    global allPeakData;
    % Get the full filename (including the path)
    namestrin = fullfile(imageFiles(index).folder, imageFiles(index).name);

    if isKey(imageCache, namestrin)
        % If the data is in the cache, retrieve it and recalculate
        data = imageCache(namestrin);
        croppedImage = data.croppedImage;
        grayImage = data.grayImage;
        I = data.I;
    else
        % If the data is not in the cache, calculate it
        image = imread(char(namestrin));
        [croppedImage, grayImage, I] = removeScaleBar(image, scaleRatio);
        
        % Store the data in the cache
        data = struct('croppedImage', croppedImage, 'grayImage', grayImage, 'I', I);  % and so on for all variables you want to cache
        imageCache(namestrin) = data;
    end

    % Count the number of rows and columns in the image
    [numRows, numCols] = size(I);

    % Perform wavelet transform
    [frq, avgCoi, avgCfs, x, y, dx, icfs] = waveletTransform(I, numRows, numCols, scaleRatio);

    minSeparation = 20 * 2; % Min distance between peaks
    TF = islocalmax(icfs, 'MinSeparation', minSeparation);
    icfs_max = icfs(TF);
    x_max = x(TF);

    % Calculate the peak data
    numPeaks = sum(TF);
    peakDistances = diff(x_max);
    peakDistances = round(peakDistances * 100) / 100;

    % Update the global variable 'allPeakData' with the current image data
    allPeakData{index} = struct('numPeaks', numPeaks, 'peakDistances', peakDistances);

    % PLOTS
    % Display the figure in full screen
    fig = figure('Units', 'normalized', 'OuterPosition', [0 0 1 1], 'NumberTitle', 'off');
    annotation('textbox', [0.515, 0.98, 0, 0], 'String', ['Image ', num2str(index)], ...
        'FitBoxToText', 'on', 'HorizontalAlignment', 'center', 'FontSize', 16);

    % Wavelet transform plot
    subplot(2, 2, 1);
    pcolor(x, 1./frq, (abs(avgCfs)).^2);
    hold on
    plot(x, 1./avgCoi, '--k', 'Linewidth', 1);
    shading interp
    set(gca, 'yscale', 'log');
    title('Wavelet transform')
    xlabel('Shell length (μm)');
    ylabel('Wavelength (μm)');

    % Original shell plot
    subplot(2, 2, 3);
    imagesc(x, y, croppedImage)
    title('Original shell')
    xlabel('Shell length (μm)');
    ylabel('Shell width (μm)');

    % Averaged, inverted wavelet plot
    subplot(2, 2, 4);
    hPlot = plot(x, icfs); % Store the plot handle
    hold on;
    hPeaks = plot(x_max, icfs_max, 'ro'); % Store the peaks plot handle
    axis tight
    ylabel('Amplitude (μm)');
    xlabel('Shell length (μm)');
    title('Inverted wavelet transform');
 
    % Create the slider
    slider = uicontrol('Style', 'slider', 'Position', [1250 42 300 20],...
        'Min', 0, 'Max', 200, 'Value', minSeparation, 'SliderStep', [0.01 0.1]);

    uicontrol('Style', 'text', 'Position', [1100 40 150 20],...
        'String', 'Peak Separation Distance', 'HorizontalAlignment', 'left');

    % Create the text uicontrol
    sliderValueText = uicontrol('Style', 'text', 'Position', [1570 42 100 20],...
        'String', ['Value: ', num2str(round(minSeparation))], 'HorizontalAlignment', 'left');
   
    % Create the next and previous buttons with new callback functions
    uicontrol('Style', 'pushbutton', 'String', 'Next', 'Position', [1800 42 50 20],...
        'Callback', @(src, ~) nextButtonCallback(src, imageFiles, scaleRatio, imageCache), 'UserData', index, 'Tag', 'nextBtn');
    uicontrol('Style', 'pushbutton', 'String', 'Previous', 'Position', [1750 42 50 20],...
        'Callback', @(src, ~) prevButtonCallback(src, imageFiles, scaleRatio, imageCache), 'UserData', index, 'Tag', 'prevBtn');
 
    % Add an "Add peak" button to the figure
    uicontrol('Style', 'pushbutton', 'String', 'Add peak', 'Position', [1850 42 50 20],...
        'Callback', @(src, ~) addPeak(icfs, x, hPlot, hPeaks, numPeaks, peakDistances, sliderValueText, index));

    % Add an "Export" button to the figure
    uicontrol('Style', 'pushbutton', 'String', 'Export', 'Position', [1850 72 50 20],...
    'Callback', @(src, ~) exportToExcel(allPeakData), 'Tag', 'exportBtn');
    
    % Slider callback property
    set(slider, 'Callback', @(src, ~) recalculatePeaksAndRedraw(src, icfs, x, hPlot, hPeaks, sliderValueText, index));
    % Call the function to set up the figure
    updateFigure(icfs, x, hPlot, hPeaks, numPeaks, peakDistances, sliderValueText, index);

    % Plot the number of peaks and peak distances
    subplot(2, 2, 2);
    bar(peakDistances);
    xlabel('Peak Index / Day count');
    ylabel('Distance between peaks / (μm)');
    title(['Number of peaks: ' num2str(numPeaks)]);

    % At the end, update the UserData of the buttons to the new index
    set(findobj('Tag', 'nextBtn'), 'UserData', min(index + 1, numel(imageFiles)));
    set(findobj('Tag', 'prevBtn'), 'UserData', max(index - 1, 1));
end

function nextButtonCallback(src, imageFiles, scaleRatio, imageCache)
    global allPeakData;
    currentFig = gcf;
    processImage(src.UserData, imageFiles, scaleRatio, imageCache);
    if ishandle(currentFig)
        close(currentFig);
    end
    
end

function prevButtonCallback(src, imageFiles, scaleRatio, imageCache)
    global allPeakData; % Access the global variable

    % Remove the last entry from allPeakData
    allPeakData = allPeakData(1:end - 1);

    currentFig = gcf;
    processImage(src.UserData, imageFiles, scaleRatio, imageCache);
    if ishandle(currentFig)
        close(currentFig);
    end
end

function prevImage(imageIndex)
    assignin('base', 'imageIndex', imageIndex - 1);
    evalin('base', 'mainScript');
end

function nextImage(imageIndex)
    assignin('base', 'imageIndex', imageIndex + 1);
    evalin('base', 'mainScript');
end

function addPeak(icfs, x, hPlot, hPeaks, numPeaks, peakDistances,sliderValueText, index)
    global allPeakData
    % Use ginput to get the coordinates of the clicked point
    [X, Y] = ginput(1);

    % Get the x coordinates and y coordinates of the existing peaks
    x_peaks = hPeaks.XData;
    y_peaks = hPeaks.YData;

    % Calculate the distances between the clicked point and the existing peaks
    dists = abs(x_peaks - X);

    % Find the index of the closest peak
    [~, idx] = min(dists);

    % If the clicked point is to the right of the closest peak, increment the index
    if X > x_peaks(idx)
        idx = idx + 1;
    end

    % Insert the new peak into the list
    x_peaks = [x_peaks(1:idx-1) X x_peaks(idx:end)];

    % Interpolate the y values of the plot at the new x values
    y_new = interp1(hPlot.XData, hPlot.YData, X, 'linear', 'extrap');
    y_peaks = [y_peaks(1:idx-1) y_new y_peaks(idx:end)];

    hPeaks.XData = x_peaks;
    hPeaks.YData = y_peaks;

    % Recalculate the peak distances and update the bar plot
    peakDistances = diff(x_peaks);
    numPeaks = numel(x_peaks); % Count the number of peaks including the new one

    updateFigure(icfs, x, hPlot, hPeaks, numPeaks, peakDistances,sliderValueText, index)

    % Assign new value for numPeaks and peakDistances in the base workspace
    assignin('base', 'numPeaks', numPeaks);
    assignin('base', 'peakDistances', peakDistances);
    allPeakData{index} = struct('numPeaks', numPeaks, 'peakDistances', peakDistances);
end

function recalculatePeaksAndRedraw(src, icfs, x, hPlot, hPeaks, sliderValueText, index)
    global allPeakData
    % Recalculate the peaks based on the new slider value
    newMinSeparation = src.Value;
    TF = islocalmax(icfs, 'MinSeparation', newMinSeparation);
    icfs_max = icfs(TF);
    x_max = x(TF);

    % Update the peaks plot
    hPeaks.XData = x_max;
    hPeaks.YData = icfs_max;

    % Recalculate the peak data
    numPeaks = sum(TF);
    peakDistances = diff(x_max);
    peakDistances = round(peakDistances * 100) / 100;

    % Update the slider value text
    set(sliderValueText, 'String', ['Value: ', num2str(round(newMinSeparation))]);

    % Update the figure
    updateFigure(icfs, x, hPlot, hPeaks, numPeaks, peakDistances, sliderValueText, index);
   
    % Assign new value for numPeaks and peakDistances in the base workspace
    assignin('base', 'numPeaks', numPeaks);
    assignin('base', 'peakDistances', peakDistances);   
    allPeakData{index} = struct('numPeaks', numPeaks, 'peakDistances', peakDistances);
end

function exportToExcel(allPeakData)
    % Extract peakDistances data from allPeakData for each image i
    peakDistancesArray = cellfun(@(x) x.peakDistances(:), allPeakData, 'UniformOutput', false);

    % Combine the peakDistancesArray into a single column vector
    peakDistancesVector = [];
    for i = 1:numel(peakDistancesArray)
        peakDistancesVector = [peakDistancesVector; peakDistancesArray{i}];
    end

    % Define the title
    title = {'Distance between peaks (μm)'};

    % Combine title and peakDistancesVector into a cell array
    dataCellArray = [title; num2cell(peakDistancesVector)];

    % Define the Excel filename
    filename = fullfile(pwd, ['SHELL_DATA.xlsx']);

    % Write data to Excel using the writecell function with 'OutputType' set to 'spreadsheet'
    writecell(dataCellArray, filename, 'Sheet', 1);

    % Display a message confirming the export
    fprintf('Data exported to Excel file: %s\n', filename);
    msgbox("Growth data exported","Success");
   end