function [frq, avgCoi, avgCfs, x, y, dx, icfs] = waveletTransform(I, numRows, numCols, scaleRatio)
    
% Define the spatial dimensions
x = linspace(0,numRows/scaleRatio,numRows); % (start, #um, #pixels) (in microns)
y = linspace(0,numCols/scaleRatio,numCols); % (start, #um, #pixels) (in microns)
dx = x(2); % Spatial step size

    % Pre allocate the matrix
    [cfs,frq,coi] = cwt(I(:,1), 1/dx);
    [m,n] = size(cfs);

    cwtResult = zeros(m,n,numCols);
    coiResult = zeros(size(coi,1),numCols);

    % Wavelet transform on the image
    for col = 1:numCols
        % Computes wavelet for each column
        [cfs,frq,coi] = cwt(I(:,col), 1/dx);

        % Assign result to cwtResult and coiResult
        cwtResult(:, :, col) = cfs;
        coiResult(:, col) = coi;
    end

    % Average across the 3rd dimension
    avgCfs = mean(cwtResult,3);
    % Average along the 2nd dimension (columns)
    avgCoi = mean(coiResult, 2); 
    
    % Averaged wavelet inversion
    icfs = icwt(avgCfs);
end