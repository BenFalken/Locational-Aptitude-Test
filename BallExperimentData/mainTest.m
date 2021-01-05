%% Cleanup

% Clear all pre-existing variables
clear all;
close all;

% Import the curve hill generator and plotter
import surfaceCreator.*

%% Setup Trial Variables

% Set random stream
RandStream.setGlobalStream(RandStream('mt19937ar','seed',sum(100*clock)));

% User inputs name to designate name (NOTE: PRECAUTION FOR SAME NAMES)
inputName = input('First Name and Last 2 Initials? ', 's');
inputName = upper(inputName);

% Define size of User and Master File (File with information for 25 curves
NUMBER_OF_TRIALS = 10;
NUMBER_OF_SURFACES = 25;
STATS_ASSOCIATED_WITH_SURFACE = 7; % {y-intercept, lowest point, down rate, amplitude, ball radius, furthest x, furthest y}

% Set up User File, Master Record File of Surfaces, and Record of Newly Created Surfaces (If making new surfaces)
surfaceStatsToUseInExperiment = zeros(NUMBER_OF_TRIALS, STATS_ASSOCIATED_WITH_SURFACE+4);
masterRecord = zeros(NUMBER_OF_SURFACES, STATS_ASSOCIATED_WITH_SURFACE);
newlyCreatedSurfacesRecord = cell(NUMBER_OF_TRIALS, 1);

%% Set up Directories

% Find all User Files
recordPathway = '/Users/benfalken/Documents/MATLAB/BallExperimentData/ParticipantData/';

% Get the Curve Directory
surfacePathway = '/Users/benfalken/Documents/MATLAB/BallExperimentData/RollSurfaces/';
surfaceFiles = dir([surfacePathway, '*.png']); % Load all PNG files if any exist

% Get the Screen Graphics Directory
graphicPathway = '/Users/benfalken/Documents/MATLAB/BallExperimentData/ScreenGraphics/';
graphicFiles = dir([graphicPathway, '*.png']); % Load all PNG files, which should exist

% Return Sizes of Surface and Graphic Directories
surfaceFilesNum = size(surfaceFiles,1);
graphicFilesNum = size(graphicFiles,1);

%% Load New Graph Files if None in Folder (initFiles.m)

% Check if Master File, Surface Directory both exist - if not, create them
if isfile([recordPathway 'masterRecord.mat']) && surfaceFilesNum == NUMBER_OF_SURFACES
    masterRecordFile = matfile([recordPathway 'masterRecord.mat']);
    masterRecord = masterRecordFile.updatedMasterRecord;
else
    while surfaceFilesNum ~= NUMBER_OF_SURFACES
    surfaceStats = surfaceCreator.loadData(surfaceFilesNum+1, newlyCreatedSurfacesRecord);
    % Add the random surface info to the master record
    masterRecord(surfaceFilesNum+1, 1) = surfaceStats(1).y_int;
    %disp(surfaceStats(1).y_int);
    masterRecord(surfaceFilesNum+1, 2) = surfaceStats(1).abs_min;
    masterRecord(surfaceFilesNum+1, 3) = surfaceStats(1).down_rate;
    masterRecord(surfaceFilesNum+1, 4) = surfaceStats(1).amplitude;
    masterRecord(surfaceFilesNum+1, 5) = surfaceStats(1).ball_rad;
    masterRecord(surfaceFilesNum+1, 6) = surfaceStats(1).furthest_pt_x;
    masterRecord(surfaceFilesNum+1, 7) = surfaceStats(1).furthest_pt_y;
    % Go to the next surface
    surfaceFilesNum = surfaceFilesNum +1;
    end
end

% Check if the Screen Graphic "GraphReference" exists - if not, create it
if ~isfile([graphicPathway 'GraphReference.png'])
    graphReference = figure;
    x_axis = [1:10];
    y_axis = repelem(5, 10);
    area(x_axis, y_axis);
    saveas(graphReference, ... 
        [graphicPathway 'GraphReference.png'])
end

%% Make Data Unique to User

% Fetch random indices from the Master File for a random trial
randSurfaces = randperm(NUMBER_OF_SURFACES, NUMBER_OF_TRIALS);
surfaceStatsToUseInExperiment(:,1:STATS_ASSOCIATED_WITH_SURFACE) = masterRecord(randSurfaces, 1:STATS_ASSOCIATED_WITH_SURFACE);

%% Set up Window

% Create Screen
Screen('Preference', 'SkipSyncTests', 1);
[window, rect] = Screen('OpenWindow', 0);
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Define Screen Size
WINDOW_W = rect(3);
WINDOW_H = rect(4);

% Find Screen Centers for later use
X_CENTER = WINDOW_W/2;
Y_CENTER = WINDOW_H/2;

%% Set all Textures

% Create Texture Arrays
surfaceTextures = zeros(1, NUMBER_OF_TRIALS);
graphicsTextures = zeros(1, graphicFilesNum-1);

% Fetch all Curve Files from Directory
for trial=1:NUMBER_OF_TRIALS
    surfaceFile = randSurfaces(trial);
    surfaceImage = imread([surfacePathway 'SurfaceGraph_' num2str(surfaceFile) '.png']);
    % Fit Image onto Screen
    surfaceImage = imresize(surfaceImage, WINDOW_H/size(surfaceImage,1));
    % Make image 3D
    surfaceImage = surfaceImage(1:100*floor(size(surfaceImage,1)/100), ...
        1:100*floor(size(surfaceImage,2)/100), :);
    surfaceTextures(trial) = Screen('MakeTexture', window, surfaceImage);
end

% Fetch Mask from Graphics Directory
graphicMask = resizeGraphic(imread([graphicPathway 'Mask.png']));
graphicMask = graphicMask(:,:,1);

% Fetch all Screen Graphics from Directory
for graphicFile=1:graphicFilesNum
    graphicName = graphicFiles(graphicFile).name;
    graphicImage = imread([graphicPathway graphicName]);
    if graphicFile > 2
        graphicImage = resizeGraphic(graphicImage);
        graphicImage(:,:,4) = graphicMask;
    end
    graphicsTextures(graphicFile) = Screen('MakeTexture', window, graphicImage);
end


%% First Intro Slide

% Set Text Box style
Screen('TextFont',window, 'Calibri');
Screen('TextSize',window, 30);
Screen('TextStyle', window, 0);

% First Intro Frame - Introduce Ball (LATER, ASK THEM TO CLICK IT IN RANDOM
% SPOTS 10+ TIMES TO GET THEIR MEAN DEVIATION. ADD ANOTHER INDICE TO TRIAL
DrawFormattedText(window,'This is a ball.', X_CENTER-85,300,[0 0 0]);
Screen('DrawTexture', window, graphicsTextures(4), [], [X_CENTER-50, 350, X_CENTER+50, 450]);
Screen('Flip', window)

pause(0.5)

%% Second Intro Slide

EXAMPLE_BALL_DIAMETER = 0.11; %m
PIXELS_PER_METER = 500;

DROP_DISTANCE = 1;  % m
INIT_VELOCITY = 0.1;  % m/s
g = 9.8; %m/s^2
mu = 0.015; %constant
t = 0;
while 0.5*g*t^2 < DROP_DISTANCE
    pause(0.01)
    Screen('DrawTexture', window, graphicsTextures(1), [], ...
        [490, 515, 1200, 1015]);
    DrawFormattedText(window,'The ball is acted on by gravity', X_CENTER-170,300,[0 0 0]);
    Screen('DrawTexture', window, graphicsTextures(4), [], ...
        [590, 500-(PIXELS_PER_METER*DROP_DISTANCE)+(PIXELS_PER_METER*(0.5*g*t^2)), 590+(EXAMPLE_BALL_DIAMETER*PIXELS_PER_METER), 500+(EXAMPLE_BALL_DIAMETER*PIXELS_PER_METER)-(PIXELS_PER_METER*DROP_DISTANCE)+(PIXELS_PER_METER*(0.5*g*t^2))], ...
        [360*sqrt(2*((INIT_VELOCITY*t)-(0.5*g*mu*t^2))^2)/(EXAMPLE_BALL_DIAMETER*pi)]);
    Screen('Flip', window)
    t = t + 0.01;
end
pause(0.5);

%% Third Intro Slide
t = 0;
while g*mu*t < INIT_VELOCITY
    pause(0.01)
    Screen('DrawTexture', window, graphicsTextures(1), [], ...
        [490, 515, 1200, 1015]);
    DrawFormattedText(window,'The ball is kicked softly, moves on a sticky surface', X_CENTER-170,300,[0 0 0]);
    Screen('DrawTexture', window, graphicsTextures(4), [], ...
        [590+(PIXELS_PER_METER*((INIT_VELOCITY*t)-(0.5*g*mu*t^2))), 500, 590+(EXAMPLE_BALL_DIAMETER*PIXELS_PER_METER)+(PIXELS_PER_METER*((INIT_VELOCITY*t)-(0.5*g*mu*t^2))), 500+(EXAMPLE_BALL_DIAMETER*PIXELS_PER_METER)], ...
        [360*sqrt(2*((INIT_VELOCITY*t)-(0.5*g*mu*t^2))^2)/(EXAMPLE_BALL_DIAMETER*pi)]);
    Screen('Flip', window)
    t = t + 0.01;
end
pause(0.5);

%% Fourth Intro Slide
t = 0;
while 0.5*g*t^2 < DROP_DISTANCE
    pause(0.01)
    Screen('DrawTexture', window, graphicsTextures(1), [], ...
        [490, 515, 1200, 1015]);
    DrawFormattedText(window,'The ball can move in 2D.', X_CENTER-170,300,[0 0 0]);
    Screen('DrawTexture', window, graphicsTextures(4), [], ...
        [590+(PIXELS_PER_METER*((10*INIT_VELOCITY*t))), 500-(PIXELS_PER_METER*DROP_DISTANCE)+(PIXELS_PER_METER*(0.5*g*t^2)), 590+(EXAMPLE_BALL_DIAMETER*PIXELS_PER_METER)+(PIXELS_PER_METER*((10*INIT_VELOCITY*t))), 500-(PIXELS_PER_METER*DROP_DISTANCE)+(EXAMPLE_BALL_DIAMETER*PIXELS_PER_METER)+(PIXELS_PER_METER*(0.5*g*t^2))], ...
        [360*sqrt(2*((INIT_VELOCITY*t)-(0.5*g*mu*t^2))^2)/(EXAMPLE_BALL_DIAMETER*pi)]);
    Screen('Flip', window)
    t = t + 0.01;
end
pause(0.5);

%% Fifth Intro Frame

NUMBER_OF_TEST_CLICKS = NUMBER_OF_TRIALS;

initialUserError = zeros(NUMBER_OF_TEST_CLICKS, 2);

for testClick=1:size(initialUserError,1)
    randomDiam = randi([floor(0.5*EXAMPLE_BALL_DIAMETER*PIXELS_PER_METER) ceil(1.5*EXAMPLE_BALL_DIAMETER*PIXELS_PER_METER)], 1);
    randCoordinates = [(WINDOW_W-100)*rand(1), (WINDOW_H-100)*rand(1)];
    
    %disp(randomDiam);
    
    DrawFormattedText(window,'Click where you see the ball', X_CENTER-170,300,[0 0 0]);
    Screen('DrawTexture', window, graphicsTextures(4), [], ...
        [randCoordinates(1)-(randomDiam/2), randCoordinates(2)-(randomDiam/2), randCoordinates(1)+(randomDiam/2), randCoordinates(2)+(randomDiam/2)]);
    Screen('Flip', window)
    % Define Mouse Click conditions
    [Mousex, Mousey, Clicks] = GetMouse;

    % Don't do anything until mouse clicks
    while ~any(Clicks)
    [Mousex, Mousey, Clicks] = GetMouse;
    end
    pause(0.15)
    
    initialUserError(testClick,:) = [(Mousex-randCoordinates(1))/randomDiam, (Mousey-randCoordinates(2))/randomDiam];
end

% Fourth Intro Frame - Ask User to begin
DrawFormattedText(window, ...
    'Click where on the curves the ball will reach at its furthest point. Click when ready.' ...
    , X_CENTER-550,300,[0 0 0]);
Screen('DrawTexture', window, graphicsTextures(4), [], [X_CENTER-50, 350, X_CENTER+50, 450]);
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

userErrorDuringTrial = zeros(NUMBER_OF_TRIALS, 2);
PIXELS_PER_METER_ON_GRAPH = 70;

for trial=1:NUMBER_OF_TRIALS
    [Mousex, Mousey, Clicks] = GetMouse;
    
    lowestPoint = surfaceStatsToUseInExperiment(trial, 2);
    ballRadius = PIXELS_PER_METER_ON_GRAPH*surfaceStatsToUseInExperiment(trial, 5);
    
    %disp(trialRecord(trial, 1));
    intercept = (WINDOW_H - 105) - (460*(surfaceStatsToUseInExperiment(trial, 1))/5);

    Screen('DrawTexture', window, surfaceTextures(trial));
    Screen('DrawTexture', window, graphicsTextures(4), [], ...
        [392-(ballRadius/2), intercept-ballRadius, 392+(ballRadius/2), intercept]);
    
    DrawFormattedText(window,['Trial ' num2str(trial) ' out of ' num2str(NUMBER_OF_TRIALS)], X_CENTER, 200,[0 0 0]);
    
    Screen('Flip', window);
    while ~any(Clicks)
        [Mousex, Mousey, Clicks] = GetMouse;
    end
    
    Screen('DrawTexture', window, surfaceTextures(trial), []);
    Screen('DrawTexture', window, graphicsTextures(4), [], ...
        [392-(ballRadius/2), intercept-ballRadius, 392+(ballRadius/2), intercept]);
    Screen('DrawTexture', window, graphicsTextures(3), [], ...
        [Mousex-(ballRadius/2), Mousey-(ballRadius/2), Mousex+(ballRadius/2), Mousey+(ballRadius/2)]);
    
    DrawFormattedText(window,['Trial ' num2str(trial) ' out of ' num2str(NUMBER_OF_TRIALS)], X_CENTER, 200,[0 0 0]);
    
    surfaceStatsToUseInExperiment(trial, 8) = (10*(Mousex-154)/938)/ballRadius;
    %disp(Mousey);
    surfaceStatsToUseInExperiment(trial, 9) = ((15*(800-Mousey)/735)-lowestPoint)/ballRadius; % Set 900 to something at some point
    
    %userErrorDuringTrial(trial,1) = 10*userError(trial,1)/938;
    %userErrorDuringTrial(trial,2) = 5*userError(trial,2)/735;
    
    Screen('Flip', window);
    pause(0.25)
    
end

%% End and Save Data

% Turns Screen to white
Screen('Flip', window);
WaitSecs(1);

% Closes Screen
Screen('CloseAll');

% Saves Master Record and the User's Data
updatedMasterRecord = masterRecord;
save([recordPathway 'masterRecord.mat'], 'updatedMasterRecord');
save([recordPathway [inputName '.mat']], 'surfaceStatsToUseInExperiment');

%Graph the Data
%representData.Graph(recordPathway, surfaceStats);

%% Add the beginning unique user start error

meanX = mean(initialUserError(:, 1));
meanY = mean(initialUserError(:, 1));

surfaceStatsToUseInExperiment(:, 10) = meanX*ones(NUMBER_OF_TEST_CLICKS, 1);
surfaceStatsToUseInExperiment(:, 11) = meanY*ones(NUMBER_OF_TEST_CLICKS, 1);

%stdUserError = zeros(10,1);
%stdUserError(:) = sqrt(userError(:,1).^2 + userError(:,2).^2);

%userError = sum(stdUserError)/size(userError,1);
%surfaceStatsToUseInExperiment(:, 8) = userError;


%% Function to Resize Graphics

function newGraphic = resizeGraphic(Image)

smallerDimenion = min(size(Image,1), size(Image,2));
newGraphic = imresize(Image, 100/smallerDimenion);
if size(Image,1) ~= size(Image,2)
    smallerDimenion = min(size(newGraphic,1), size(newGraphic,2));
    newGraphic = newGraphic(1:smallerDimenion, 1:smallerDimenion,:);
end
end