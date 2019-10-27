%% Cleanup

% Clear all pre-existing variables
clear all;
close all;

% Import the curve hill generator and plotter
import curveSimulator.*
import representData.*

%% Setup Trial Variables

% Set random stream
RandStream.setGlobalStream(RandStream('mt19937ar','seed',sum(100*clock)));

% User inputs name to designate name (NOTE: PRECAUTION FOR SAME NAMES)
inputName = input('First Name and Last 2 Initials? ', 's');
inputName = upper(inputName);

% Define size of User and Master File (File with information for 25 curves
numTrials = 10;
numSurfaces = 25;
surfaceStats = 5; % {Y-intercept, lowest point, ball radius, furthest x, furthest y}

% Set up User File, Master File and Plotting File (if applicable)
exportSurfaceStats = zeros(numTrials, surfaceStats+3);
masterRecord = zeros(numSurfaces, surfaceStats);
figureList = cell(numTrials, 1);

%% Set up Directories

% Find all User Files
recordPathway = '/Users/benfalken/Desktop/BallExperimentData/ParticipantData/';

% Get new User Name
inputName = input('continue? ', 's');
inputName = upper(inputName);

% Get the Curve Directory
surfacePathway = '/Users/benfalken/Desktop/BallExperimentData/RollSurfaces/';
surfaceFiles = dir([surfacePathway, '*.png']); % Set up task if directory nonexistent

% Get the Screen Graphics Directory
graphicPathway = '/Users/benfalken/Desktop/BallExperimentData/ScreenGraphics/';
graphicFiles = dir([graphicPathway, '*.png']);

% Return Lengths of User and Graphic Directories
surfaceFileNum = size(surfaceFiles,1);
graphicFileNum = size(graphicFiles,1);

%% Load New Graph Files if None in Folder (initFiles.m)

% Check if Master File, Surface Directory both exist - if not, create them
if isfile([recordPathway 'masterRecord.mat']) && surfaceFileNum == numSurfaces
    masterRecordFile = matfile([recordPathway 'masterRecord.mat']);
    masterRecord = masterRecordFile.updatedMasterRecord;
else
    while surfaceFileNum ~= numSurfaces
    % FIRST ADD NEW INTERCEPT. SECOND LOAD INTERCEPT VALUE AND TRUE END COORDINATES. THEN LOAD GRAPH
    importSurfaceStats = curveSimulator.loadData(surfaceFileNum+1, figureList);
    %for index=1:7
    masterRecord(surfaceFileNum+1, 1:surfaceStats) = importSurfaceStats(1, 1:surfaceStats);
    %end
    surfaceFileNum = surfaceFileNum +1;
    end
end

% Check if the Screen Graphic "GraphReference" exists - if not, create it
if ~isfile([graphicPathway 'GraphReference.png'])
    graphReference = figure;
    bothAxes = [1:10];
    area(bothAxes, bothAxes.*-1);
    saveas(graphReference, ... 
        [graphicPathway 'GraphReference.png'])
end

%% Make Data Uinque to User

% Fetch random indices from the Master File for a random trial
randSurfaces = randperm(numSurfaces, numTrials);
exportSurfaceStats(:,1:surfaceStats) = masterRecord(randSurfaces, 1:surfaceStats);

%% Set up Window

% Create Screen
Screen('Preference', 'SkipSyncTests', 1);
[window, rect] = Screen('OpenWindow', 0);
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Define Screen Size
window_w = rect(3);
window_h = rect(4);

% Find Screen Centers for later use
x_center = window_w/2;
y_center = window_h/2;

%% Set all Textures

% Create Texture Arrays
surfaceTextures = zeros(1, numTrials);
graphicsTextures = zeros(1, graphicFileNum-1);

% Fetch all Curve Files from Directory
for trial=1:numTrials
    surfaceFile = randSurfaces(trial);
    surfaceImage = imread([surfacePathway 'SurfaceGraph_' num2str(surfaceFile) '.png']);
    surfaceImage = imresize(surfaceImage, window_h/size(surfaceImage,1));
    surfaceImage = surfaceImage(1:100*floor(size(surfaceImage,1)/100), ...
        1:100*floor(size(surfaceImage,2)/100), :);
    surfaceTextures(trial) = Screen('MakeTexture', window, surfaceImage);
end

% Fetch Mask from Graphics Directory
graphicMask = resizeGraphic(imread([graphicPathway 'Mask.png']));
graphicMask = graphicMask(:,:,1);

% Fetch all Screen Graphics from Directory
for graphicFile=1:graphicFileNum
    graphicName = graphicFiles(graphicFile).name;
    %disp(graphicName);
    graphicImage = imread([graphicPathway graphicName]);
    if graphicFile > 2
        graphicImage = resizeGraphic(graphicImage);
        graphicImage(:,:,4) = graphicMask;
    end
    graphicsTextures(graphicFile) = Screen('MakeTexture', window, graphicImage);
end


%% Demo Video

% Set Text Box style
Screen('TextFont',window, 'Arial');
Screen('TextSize',window, 30);
Screen('TextStyle', window, 0);

% First Intro Frame - Introduce Ball (LATER, ASK THEM TO CLICK IT IN RANDOM
% SPOTS 10+ TIMES TO GET THEIR MEAN DEVIATION. ADD ANOTHER INDICE TO TRIAL
DrawFormattedText(window,'This is a ball.', x_center-85,300,[0 0 0]);
Screen('DrawTexture', window, graphicsTextures(4), [], [x_center-50, 350, x_center+50, 450]);
Screen('Flip', window)

pause(1)

% Second Intro Frame - Simulate Ball rolling down hill
for step=1:10:4*window_h/5
    pause(0.04)
    Screen('DrawTexture', window, graphicsTextures(1), [], ...
        [490, 340, 950, 800]);
    DrawFormattedText(window,'This ball is placed on a ramp.', x_center-170,300,[0 0 0]);
    Screen('DrawTexture', window, graphicsTextures(4), [], ...
        [540+step^(step/800), 390+step^(step/800), 570+step^(step/800), 420+step^(step/800)], ...
        [360*sqrt(2*(step^(step/800))^2)/(pi*2*50)]);
    Screen('Flip', window)
end

pause(1);

% Third Intro Frame - Ask User to click ball in window

userError = zeros(10, 2);

for testClick=1:size(userError,1)
    randCoordinates = [(window_w-100)*rand(1), (window_h-100)*rand(1)];
    
    DrawFormattedText(window,'Click where you see the ball', x_center-170,300,[0 0 0]);
    Screen('DrawTexture', window, graphicsTextures(4), [], ...
        [randCoordinates(1)-25, randCoordinates(2)-25, randCoordinates(1)+25, randCoordinates(2)+25]);
    Screen('Flip', window)
    % Define Mouse Click conditions
    [Mousex, Mousey, Clicks] = GetMouse;

    % Don't do anything until mouse clicks
    while ~any(Clicks)
    [Mousex, Mousey, Clicks] = GetMouse;
    end
    pause(0.15)
    
    userError(testClick,:) = [abs(Mousex-randCoordinates(1)), abs((Mousey-randCoordinates(2)))];
    
end

% Fourth Intro Frame - Ask User to begin
DrawFormattedText(window, ...
    'Click where on the curves the ball will reach at its furthest point. Click when ready.' ...
    , x_center-550,300,[0 0 0]);
Screen('DrawTexture', window, graphicsTextures(4), [], [x_center-50, 350, x_center+50, 450]);
Screen('Flip', window)

%% While Loop For Trial

% Define Mouse Click conditions
[Mousex, Mousey, Clicks] = GetMouse;

% Don't do anything until mouse clicks
while ~any(Clicks)
    [Mousex, Mousey, Clicks] = GetMouse;
end

pause(0.1)

Screen('TextSize',window, 60);

% Go through each trial, project graph and ask users to click where ball
% ends up
for trial=1:numTrials
    [Mousex, Mousey, Clicks] = GetMouse;
    
    lowPoint = exportSurfaceStats(trial, 2);
    ballRad = exportSurfaceStats(trial, 3);
    
    %disp(trialRecord(trial, 1));
    Intercept = ((window_h-150)-(660*(exportSurfaceStats(trial, 1))/5));

    Screen('DrawTexture', window, surfaceTextures(trial));
    Screen('DrawTexture', window, graphicsTextures(4), [], ...
        [275-(ballRad/2), 50+Intercept-ballRad, 275+(ballRad/2), 50+Intercept]);
    
    DrawFormattedText(window,['Graph ' num2str(trial)], x_center, 200,[0 0 0]);
    
    Screen('Flip', window);
    while ~any(Clicks)
        [Mousex, Mousey, Clicks] = GetMouse;
    end
    
    Screen('DrawTexture', window, surfaceTextures(trial), [], ...
        [120, 0, 1320, window_h]);
    Screen('DrawTexture', window, graphicsTextures(4), [], ...
        [275-(ballRad/2), 50+Intercept-ballRad, 275+(ballRad/2), 50+Intercept]);
    Screen('DrawTexture', window, graphicsTextures(3), [], ...
        [Mousex-25, Mousey-25, Mousex+25, Mousey+25]);
    
    DrawFormattedText(window,['Graph ' num2str(trial)], x_center, 200,[0 0 0]);
    
    exportSurfaceStats(trial, 6) = 10*(Mousex-154)/938;
    %disp(Mousey);
    exportSurfaceStats(trial, 7) = (15*(800-Mousey)/735)-lowPoint; % Set 900 to something at some point
    
    userError(trial,1) = 10*userError(trial,1)/938;
    userError(trial,2) = 5*userError(trial,2)/735;
    
    Screen('Flip', window);
    pause(0.25)
    
end

stdUserError = zeros(10,1);
stdUserError(:) = sqrt(userError(:,1).^2 + userError(:,2).^2);

userError = sum(stdUserError)/size(userError,1);
exportSurfaceStats(:, 8) = userError;

%% End and Save Data

% Turns Screen to white
Screen('Flip', window);
WaitSecs(1);

% Closes Screen
Screen('CloseAll');

% Saves Master Record and the User's Data
updatedMasterRecord = masterRecord;
save([recordPathway 'masterRecord.mat'], 'updatedMasterRecord');
save([recordPathway [inputName '.mat']], 'exportSurfaceStats');

%Graph the Data
%representData.Graph(recordPathway, surfaceStats);

%% Function to Resize Graphics

function newGraphic = resizeGraphic(Image)

smallerDimenion = min(size(Image,1), size(Image,2));
newGraphic = imresize(Image, 100/smallerDimenion);
if size(Image,1) ~= size(Image,2)
    smallerDimenion = min(size(newGraphic,1), size(newGraphic,2));
    newGraphic = newGraphic(1:smallerDimenion, 1:smallerDimenion,:);
end
end