function [croppedImage, grayImage,I] = removeScaleBar(image, scaleRatio)

    % Define the RGB threshold values for the black bar, adjust as needed
    threshold_black_R = 10; 
    threshold_black_G = 10;  
    threshold_black_B = 10;  

    % Define the RGB threshold values for the white part, adjust as needed
    threshold_white_R = 230;
    threshold_white_G = 230;
    threshold_white_B = 230;

    % Extract the RGB color channels
    R = image(:, :, 1);
    G = image(:, :, 2);
    B = image(:, :, 3);

    % Create a binary mask for the black and white bar region
    binaryMask = ((R < threshold_black_R) & (G < threshold_black_G) & (B < threshold_black_B)) | ...
                 ((R > threshold_white_R) & (G > threshold_white_G) & (B > threshold_white_B));

    % Perform morphological operations to clean up the binary mask
    se = strel('rectangle', [5, 1]);  % Structuring element to define the size of the bar
    cleanedMask = imopen(binaryMask, se);

    % Dilate the cleaned mask to include the gray boundary
    seDilate = strel('rectangle', [5, 5]);  % Adjust structuring element size as needed
    dilatedMask = imdilate(cleanedMask, seDilate);

    % Find the boundaries of the black bar region
    boundaries = bwboundaries(dilatedMask);

    % Iterate through the boundaries and calculate bar positions and lengths
    barPositions = [];
    barLengths = [];
    for k = 1:length(boundaries)
        boundary = boundaries{k};
        minX = min(boundary(:, 2));
        maxX = max(boundary(:, 2));
        minY = min(boundary(:, 1));
        maxY = max(boundary(:, 1));

        barPositions = [barPositions; minX, minY, maxX, maxY];
        barLengths = [barLengths; maxX - minX];
    end

    % Determine the scale of the image in pixels/micrometers
    [longestBarLength, index] = max(barLengths);
    scaleBar = barPositions(index, :);

    % Create a copy of the original image
    croppedImage = image;

    % Determine the coordinates of the rectangle enclosing the black bar
    x1 = barPositions(index, 1);
    y1 = barPositions(index, 2);
    x2 = barPositions(index, 3);
    y2 = barPositions(index, 4);

    % Set the pixels within the defined rectangle region to a desired background color (white)
    croppedImage(y1:y2, x1:x2, :) = 255;  % Set to white (255) for RGB images

    % Extract the remaining sections of the image
    topSection = image(1:y1-1, :, :);
    bottomSection = image(y2+1:end, :, :);

    % Ask the user for the orientation of the lines
    answer = questdlg('Are the lines of interest going horizontally or vertically in the image?', ...
        'Image Orientation', ...
        'Horizontal','Vertical','Horizontal');

    % Handle response
    switch answer
        case 'Horizontal'
            disp([answer ' lines selected.'])
            imageOrientation = 'horizontal';
        case 'Vertical'
            disp([answer ' lines selected. Transposing the image.'])
            imageOrientation = 'vertical';
    end

    croppedImage = [topSection; bottomSection];
    grayImage = rgb2gray(croppedImage);
    I = im2double(grayImage);

% Transpose the image if the lines are vertical
if strcmp(imageOrientation, 'vertical')
    I = I.';
end

if strcmp(imageOrientation, 'horizontal')
    croppedImage = imrotate(croppedImage,-90);
end


    % Check if the current figure (gcf) is open
if ishandle(gcf)
    % Close the current figure if it's open
    close(gcf);
    disp('Current figure closed.');
else
    disp('No figure is currently open.');
end
end
