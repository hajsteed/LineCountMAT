function [imageFiles,pathin,scaleValue,shellname,scaleRatio] = inputImages()

       % Default path
    defaultPath = pwd;

    % Check if lastPath exists in preferences
    if ispref('MyImageProcessingApp', 'lastUsedPath')
        lastPath = getpref('MyImageProcessingApp', 'lastUsedPath');
        if isfolder(lastPath)
            defaultPath = lastPath;
        end
    end

    % Determines image folder
    pathin = uigetdir(defaultPath, 'Select Folder');

    % Save the selected path
    if pathin ~= 0
        setpref('MyImageProcessingApp', 'lastUsedPath', pathin);
    end

    % Specify the image formats
    imageFormats = {'*.jpg', '*.png', '*.tif', '*.bmp', '*.gif', '*.jpeg'};

    % Search for the images in the folder
    imageFiles = [];
    for i = 1:length(imageFormats)
        imageFiles = [imageFiles; dir(fullfile(pathin, imageFormats{i}))];
    end


    % Display a warning message
    uiwait(msgbox('Please ensure your images are of the form: FilePath\ShellName_ShellNumber. For example: ...\ShellName_0001', 'Warning', 'modal'));
    shellname = inputdlg('Enter shell name:', 'Shell Name', [1 40]); 
    shellname = shellname{1};
    


    % Input dialog box to enter scale bar value
    prompt = 'Enter ratio of pixels/micrometer:';
    dlgTitle = 'pix/μm';
    numLines = 1;
    defaultVal = {'0'};  % Default value as a string
    options = struct('Resize', 'on', 'Interpreter', 'none');
    scaleRatio = inputdlg(prompt, dlgTitle, numLines, defaultVal, options);


    % Convert the input to a numeric value
    scaleValue = str2double(scaleRatio{1});

    % Check if the conversion was successful and the input is a number
    if isnan(scaleValue)
        % Handle the case when the input is not a valid number
        error('Invalid input. Please enter a numeric value.');
    end

    % Create a new subfolder named 'wavelet' in the selected directory
    outputFolder = fullfile(pathin, 'wavelet');
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end
end