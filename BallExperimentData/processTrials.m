% Take all data from all trials in directory
% Using specified metric (ball size), code each set of data by color
% Plot each set of points based on color code

% Find all User Files
recordPathway = '/Users/benfalken/Documents/MATLAB/BallExperimentData/ParticipantData/';

dataFiles = dir([recordPathway '*.mat']);
            
allNames = dataFiles(:).name;
fileNum = size(dataFiles, 1);

allGraphs = cell(3);

totalBallRadAcrossUsers = zeros(1);
totalErrorAcrossUsers = zeros(1);

for dataFile=1:fileNum
    dataName = dataFiles(dataFile).name;
    disp(dataName);
    if dataName ~= "masterRecord.mat" && dataName ~= ".mat" && dataName ~= "..K.mat"
        dataPoints = matfile([recordPathway dataName]);
        dataPoints = dataPoints.surfaceStatsToUseInExperiment;
        ballRad = dataPoints(:, 3);
        
        paddingX = dataPoints(:, 10);
        paddingY = dataPoints(:, 11);
        
        errorX = dataPoints(:, 8) - paddingX;
        errorY = dataPoints(:, 9) - paddingY;
        
        totalError = (errorX + errorY).^2;
        
        totalBallRadAcrossUsers = [totalBallRadAcrossUsers; ballRad];
        totalErrorAcrossUsers = [totalErrorAcrossUsers; totalError];
    end
end

totalBallRadAcrossUsers = totalBallRadAcrossUsers(2:end);
totalErrorAcrossUsers = totalErrorAcrossUsers(2:end);

plotErrorVersusSizeBarAndScatter(totalBallRadAcrossUsers, totalErrorAcrossUsers);
plotErrorVersusSizeLine(totalBallRadAcrossUsers, totalErrorAcrossUsers);

function plotErrorVersusSizeBarAndScatter(totalBallRadAcrossUsers, totalErrorAcrossUsers)
    x = sort(unique(totalBallRadAcrossUsers));
    y = zeros(size(x)); 
    for i=1:size(totalErrorAcrossUsers)
        selectRad = totalBallRadAcrossUsers(i);
        index = find(x == selectRad);
        y(index) = y(index) + totalErrorAcrossUsers(i);
    end
    y = y./max(y);
    
    figure
    bar(x,y)
    title('Bar Graph of Normalized Error vs. the Ball Radius')
    xlabel('Ball Radius')
    ylabel('Normalized Error 0-1');
    
    figure
    plot(x, y)
    title('Plot of Normalized Error vs. the Ball Radius')
    xlabel('Ball Radius')
    ylabel('Normalized Error 0-1');
end

function plotErrorVersusSizeLine(totalBallRadAcrossUsers, totalErrorAcrossUsers)
    x = totalBallRadAcrossUsers;
    y = totalErrorAcrossUsers; 
    R = corrcoef(x, y);
    R = num2str(R(1, 2));
    
    figure
    scatter(x,y)
    
    titleString = strcat('Scatter Plot of All User Error vs. All Ball Radii. R Coefficient: ', R);
    
    title(titleString)
    xlabel('Ball Radii')
    ylabel('User Error')
end
