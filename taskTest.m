 %% Task Test

%% Startup
clear all
tasks = readtable('C:\Users\BexLab3D\Dropbox\Kerri_Walter\TaskTest\task_list.xlsx');
load('C:\Users\BexLab3D\Dropbox\Kerri_Walter\TaskTest\task_decider.mat');

commandwindow;
%% Set library
HOMEIMAGES = 'C:\Users\BexLab3D\Dropbox\Kerri_Walter\TaskTest\finalLibrary\task_test\task_test_all';
SAVE = 'C:\Users\BexLab3D\Dropbox\Kerri_Walter\TaskTest';

cd(HOMEIMAGES);
D = dir; 
D = D(~ismember({D.name}, {'.', '..'})); %first elements are '.' and '..' used for navigation - remove these

fileNames = {D.name}; %get all the file names
fileNames(strcmp(fileNames,'.') | strcmp(fileNames,'..')) = [];%remove "." and ".." from file names

%% Standard configuration
Screen('Preference','SkipSyncTests', 1);
PsychImaging('PrepareConfiguration');   % set up imaging pipeline
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma'); % gamma correction

%% Input for general information
prompt = {'Subject Number: ', 'Screen dimensions (cm): ','View Distance (cm): ','Eye tracking (0=No 1=Eyelink 2=Tobii)'};
dlg_title = 'TaskTest';
num_lines = 1;
def = {'XX', '60 34','63', '1'};
answer = inputdlg(prompt,dlg_title,num_lines,def); % read in parameters from GUI
subj = str2num(char(answer(1,1))); %subject number
eyeTracking=str2num(char(answer(4,1))); % which eye tracker is being used 0) none; 1) Eyelink; 2) Tobii

ntrials = length(fileNames); %number of trials

% create file to save data - make sure not to overwrite existing file
sName=char(answer(1,1));
testSName=sName;
string = sprintf('taskTest_subj%s.mat',sName);

cd(SAVE);
if exist(string,'file') ~= 0 % modify sName if subject already exists
    testSName=[sName,'_1'];
end
dataFile=sprintf('taskTest_subj%s.mat', testSName); % matlab datafile to store experiment parameters and results

eyelinkImportedData=[]; % empty structure for saving, in case Tobii used
leftEye=[]; % dummy variables for Tobii, in case Eyelink used
rightEye=[];
eyeXTime=[];
testTimeRec=[];
    
leftEyeXposTrial=cell(1,ntrials); % set up data records for eye position during trials - use cells because # records may vary from trial to trial
leftEyeYposTrial=cell(1,ntrials);
rightEyeXposTrial=cell(1,ntrials);
rightEyeYposTrial=cell(1,ntrials);
%% Screen / Keyboard stuff
display.screens = Screen('Screens');
display.screenNumber = 0 ;
set(0,'units','pixels');
display.resOutput = Screen('Resolution',display.screenNumber);
display.refresh = display.resOutput.hz; 
display.scrnWidthPix=display.resOutput.width; % work out screen dimensions (pixels)
display.scrnHeightPix=display.resOutput.height;
display.viewDistance = str2num(char(answer(3,1))); %viewing distance
display.scrnWidthDeg=2*atand((0.5*display.scrnWidthPix)/display.viewDistance); % convert screen width to degrees visual angle
pixPerDeg=display.scrnWidthPix/display.scrnWidthDeg; % # pixels per degree
display.dimensionsCM = str2num(char(answer(2,1))); % screen size in cm
display.pixelSize = mean(display.dimensionsCM./pixPerDeg); %cm/pixel
display.ScreenBackground = GrayIndex(display.screenNumber); %make the background gray
scrnWidthPix = display.scrnWidthPix;
scrnHeightPix = display.scrnHeightPix;

[w, wRect] = Screen('OpenWindow', display.screenNumber, display.ScreenBackground); %w is name of window, wRect is size of window
frameRate=Screen('FrameRate', w); % screen timing parameters
% nImageFrames=frameRate*duration;
   

KbName('UnifyKeyNames'); %set key names
activeKeys = [KbName('Space') KbName('Q') KbName('C') KbName('V') KbName('Return') KbName('Escape') KbName('LeftArrow') KbName('RightArrow')];
% restrict the keys for keyboard input to the keys we want
RestrictKeysForKbCheck(activeKeys);

%Set up eyetracking
if eyeTracking==1 % Eye tracking with Eyelink
    if (Eyelink('Initialize') ~= 0), return; % check eye tracker is live
    end
    el=EyelinkInitDefaults(w);
    if ~EyelinkInit(0)
        fprintf('Eyelink Init aborted.\n');
        cleanup;  % cleanup function
        return;
    end
    Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');
    
    params.calibProp = [.5 .5];
    Eyelink('command', 'calibration_type = HV9');
    Eyelink('command',['calibration_area_proportion =' num2str(params.calibProp(1)) ' ' num2str(params.calibProp(2))]);
    Eyelink('command',['validation_area_proportion =' num2str(params.calibProp(1)) ' ' num2str(params.calibProp(2))]);

    Eyelink('openfile', 'ETData.edf');
    EyelinkDoTrackerSetup(el); 
    Eyelink('StartRecording'); % start eye tracking at trial start
    HideCursor; % remove distraction of cursor - later restore it with:  ShowCursor('Arrow');
elseif eyeTracking==2 % % Eye tracking with Tobii EyeX or 4C
    addpath(genpath('C:\toolbox\TobiiMatlabToolbox3.0')); % add path to Tobii toolbox files
    tobii = tobii_connect('C:\toolbox\TobiiMatlabToolbox3.0\matlab_server\'); % establish connection ot Tobii
    [msg, DATA, tobii]= tobii_command(tobii,'init'); % initialize Tobii
    [msg, DATA]= tobii_command(tobii,'start','EyeXData\'); % start logging data
    testTimeRec=nan(ntrials,2); % empty matrix of start and stop times for Tobii
    HideCursor; % remove distraction of cursor - later restote it with:  ShowCursor('Arrow');
end

%% Experiment

try
    Seed=round(sum(100*clock)); % use current time to generate new seed number for random number generation so that all trial parameters can be reproduced if necessary
    rng(Seed); % seed the random number generator
    [keyIsDown,seconds,keyCode] = KbCheck; % initialize KbCheck and variables to make sure they're properly initialized
    CenterX=wRect(1)+(display.scrnWidthPix/2); % center X of display
    CenterY=wRect(2)+(display.scrnHeightPix/2); %center Y of display

    % write message to subject
    Screen('TextSize', w, 32); %set text size for message
    message= 'Hello! Thank you for participating in this study. \n Your goal is to view the following scenes while pretending to accomplish a task.\n Move your eyes around the image as if you were completing the task. \n When you have completed the task, press spacebar. \n Press spacebar to continue.';
    DrawFormattedText(w, message, 'center', 'center', WhiteIndex(w));
    % Update the display to show the instruction text:
    Screen('Flip', w);
    % Wait for keypress:
    KbWait; 
    
    [keyIsDown, secs, keyCode] = KbCheck;
    if keyCode('Q') == 1 %if pressed escape then quit
        sca;
    end
    
    % Clear screen to background color (our 'gray' as set at the beginning):
    Screen('Flip', w);
    % Wait a second before starting trial
    WaitSecs(1.000);

    %randomize files
    randomOrder=randperm(length(fileNames)); %random order
    randomFile=fileNames(randomOrder); %rearrange files into this order 
    subjTasks = decider(:,subj); %tasks for this subj
    subjTasks = subjTasks(randomOrder); %rearrange tasks into this order

    for trial=1:ntrials
        
        HideCursor; %hide while images are being shown

        % wait a bit between trials
        WaitSecs(0.500);

        %get file info
        fileName = char(randomFile(trial))
        fileShort = erase(fileName, '.jpg'); %just the name (no .jpg) for later
        fileArray(trial) = {fileShort}; %list all the files as they appear throughout the experiment 
        fullImgFile = strcat(HOMEIMAGES, '\', fileName); % get image file destination

        %determine which task to use
        taskOpts = tasks.(fileShort); %grab the 2 tasks for this scene
        taskChos = taskOpts(subjTasks(trial)+1); %choose which task to use

        taskArray(trial) = taskChos; %keep track of tasks choosen

        %read the task prompt
        DrawFormattedText(w, char(taskChos), 'center', 'center', WhiteIndex(w));
        Screen('Flip', w);
        
        KbWait;
        
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyCode('Q') == 1 %if pressed escape then quit
           sca;
        end
        
        WaitSecs(0.500);

        % read stimulus image into matlab matrix 'imdata':
        imdata=imread(char(fullImgFile));
        %resize all images to be the same size
        width = length(imdata(1,:,:)); %dimensions of image
        height = length(imdata(:,1,:));
        maxDim = max([width;height]); %largest dimension
        scaleratio = 1280 / maxDim; %scale based off largest dimension
        imdata = imresize(imdata, scaleratio);
        sizeArray(1,trial) = length(imdata(1,:,:)); %save resized width dimension
        sizeArray(2,trial) = length(imdata(:,1,:)); %save resized height dimension 
        % make texture image out of image matrix 'imdata'
        tex=Screen('MakeTexture', w, imdata);
        % Draw texture image
        Screen('DrawTexture', w, tex);
        % Show stimulus on screen at next possible display refresh cycle, and record stimulus onset time in 'startIm':
        [VBLTimestamp, startIm]=Screen('Flip', w);
        imageArray{trial}=Screen('GetImage', w); % grab an RGB image of the screen for visualization

        onsetTime = GetSecs; % note time at start of trial
               
        %start recording eye position
        OSGazeX=[]; % clear records of eye positions
        OSGazeY=[];
        ODGazeX=[];
        ODGazeY=[];
%             for frameNo=1:nImageFrames % for as long as the image is on screen
        if eyeTracking==1 % Eyelink
%                 if frameNo==1
           Eyelink('Message', sprintf('StartTrial%d',trial)); % inset message at start of trial
%                 end
            if Eyelink('NewFloatSampleAvailable')>0 % get the sample in the form of an event structure
                evt = Eyelink('NewestFloatSample'); % capture latest position
                OSGazeX=[OSGazeX evt.gx(1)]; % store current OS and OD gaze
                OSGazeY=[OSGazeY evt.gy(1)];
                ODGazeX=[ODGazeX evt.gx(2)];
                ODGazeY=[ODGazeY evt.gy(2)];
            end
        elseif eyeTracking==2 % Tobii
            [LEpos, REpos, etTime] = tobii_getGPN(tobii,scrnWidthPix,scrnHeightPix); % get Tobii's estimate of current point of gaze
%                 if frameNo==1 
            testTimeRec(trial,1)=etTime; % note time at start of this trial
%                 end
            OSGazeX=[OSGazeX LEpos(1)*display.scrnWidthPix]; % store current OS and OD gaze
            OSGazeY=[OSGazeY LEpos(2)*display.scrnHeightPix];
            ODGazeX=[ODGazeX REpos(1)*display.scrnWidthPix];
            ODGazeY=[ODGazeY REpos(2)*display.scrnHeightPix];
        end
%             end
        
%         % Wait for keypress:
%         KbWait;

        [keyIsDown,seconds,keyCode] = KbCheck;
        while 1 % wait indefinitely (until loop is exited)
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyCode(KbName('Space')) %break out of while loop, continue script to next trial
                break;
            elseif keyCode(KbName('Q')) %if pressed escape then quit
               sca;
            elseif keyCode(KbName('C')) %if pressed C send back to eyelink setup screen for calibration
                Eyelink('StopRecording');
                EyelinkDoTrackerSetup(el); %hands control off to the eyetracker for calibration
                while keyIsDown
                    [keyIsDown,seconds,keyCode] = KbCheck;
                end
                Eyelink('StartRecording');
                break;% exit out of loop (aborts trial without recording response)
            end
        end
        
         % Clear screen to background color after keypress
        Screen('Flip', w);

        responseLatency(trial)= GetSecs-onsetTime; % note time at end of trial minus time at start of trial
        
        %record end of trial for eyetracking
        if eyeTracking==1 % Eyelink
            Eyelink('Message', sprintf('EndTrial%d',trial)); % inset message at end of trial
        elseif eyeTracking==2 % Tobii
            testTimeRec(trial,2)=etTime; % note time at end of this trial
        end

        % store eye position data
        leftEyeXposTrial{trial}=OSGazeX; % store record of gaze position at frame rate during trial
        leftEyeYposTrial{trial}=OSGazeY;
        rightEyeXposTrial{trial}=ODGazeX;
        rightEyeYposTrial{trial}=ODGazeY;

        % wait a bit between trials
        WaitSecs(0.500);
    end
    
    %% save data and clean up
    cd(SAVE);
    sca;
    ShowCursor;
    Screen('CloseAll');
    Priority(0);
    if eyeTracking==1 % Stop Eyetracker at end of experiment
        Eyelink('StopRecording');
        Eyelink('CloseFile');
        Eyelink('ReceiveFile','ETData.edf',pwd,1);
        eyelinkImportedData = Edf2Mat('ETData.edf'); % https://github.com/uzh/edf-converter
    elseif eyeTracking==2
        [~, ~, tobii]= tobii_command(tobii,'stop');% Stop Eyetracking
        leftEye=load('EyeXData\Left.txt'); % load left eye data from EyeX file
        rightEye=load('EyeXData\Right.txt'); % load right eye data from EyeX file
        eyeXTime=load('EyeXData\Time.txt'); % load time data from EyeX file
        tobii_close(tobii);
    end

    save(dataFile, 'CenterX','CenterY','display','eyelinkImportedData','eyeTracking','eyeXTime','fileArray','imageArray','taskArray','leftEye','leftEyeXposTrial','leftEyeYposTrial','ODGazeX','ODGazeY','OSGazeX','OSGazeY','prompt','rightEye','rightEyeXposTrial','rightEyeYposTrial','sizeArray','wRect','responseLatency');  
    
catch % error during experiment, save data so far and clean up
    cd(SAVE);
    sca;
    ShowCursor;
    Priority(0);
    if eyeTracking==1 % Stop Eyetracker at end of trial
        Eyelink('StopRecording');
        Eyelink('CloseFile');
        Eyelink('ReceiveFile','ETData.edf',pwd,1);
        eyelinkImportedData = Edf2Mat('ETData.edf'); % https://github.com/uzh/edf-converter
    elseif eyeTracking==2
        [~, ~, tobii]= tobii_command(tobii,'stop');% Stop Eyetracking
        leftEye=load('EyeXData\Left.txt'); % load left eye data from EyeX file
        rightEye=load('EyeXData\Right.txt'); % load right eye data from EyeX file
        eyeXTime=load('EyeXData\Time.txt'); % load time data from EyeX file
        tobii_close(tobii);
    end
    Screen('CloseAll');
    
    save(dataFile, 'CenterX','CenterY','display','eyelinkImportedData','eyeTracking','eyeXTime','fileArray','imageArray','taskArray','leftEye','leftEyeXposTrial','leftEyeYposTrial','ODGazeX','ODGazeY','OSGazeX','OSGazeY','prompt','rightEye','rightEyeXposTrial','rightEyeYposTrial','sizeArray','wRect','responseLatency');  
  
    % Output the error message that describes the error:
    psychrethrow(psychlasterror);
end
 