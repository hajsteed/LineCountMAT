function updateFigure(icfs, x, hPlot, hPeaks, numPeaks, peakDistances, sliderValueText, index)
    persistent hLines; % Keep the variable in memory between function calls
    persistent hTexts; % Store the handles for the text objects

    % Update the figure
    set(hPlot, 'XData', x, 'YData', icfs);
    set(hPeaks, 'XData', hPeaks.XData, 'YData', hPeaks.YData);
    axis tight

    % Update the subplot
    subplotHandle = subplot(2, 2, 2);
    bar(subplotHandle, peakDistances);
    xlabel('Peak Index / Day count');
    ylabel('Distance between peaks (μm)');
    title(['Number of peaks: ' num2str(numPeaks)]);

    % Update the xline on the shell image plot
    subplot(2, 2, 3);

    % Delete previous lines and texts
    if ~isempty(hLines) % If hLines is not empty
        for i = 1:length(hLines)
            if ishandle(hLines(i)) % Check if the handle still exists
                delete(hLines(i)); % Delete the handle if it exists
            end
        end
        hLines = []; % Reset the hLines variable
    end

    if ~isempty(hTexts) % If hTexts is not empty
        for i = 1:length(hTexts)
            if mod(i, 2) == 0 && ishandle(hTexts(i))
                delete(hTexts(i)); % Delete the handle if it exists
            end
        end
        hTexts = []; % Reset the hTexts variable
    end

    hold on;
   
    for i = 1:length(hPeaks.XData)
        hLines(i) = xline(hPeaks.XData(i), 'w', 'LineWidth', 1.5); % Create new lines and store handles
        if mod(i, 2) == 0 % If i is even
            hTexts(i) = text(hPeaks.XData(i), 100, num2str(i), 'Color', 'white', 'FontSize',10); % Add text to each line
        end
    end
    hold off;

    % Display the number of peaks and peak distances
    disp(['Number of peaks: ', num2str(numPeaks)]);
    disp('Peak Distances:');
    disp(peakDistances);
end