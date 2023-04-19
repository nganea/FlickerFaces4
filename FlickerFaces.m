% Script for steady state visual evoked potentials (SSVEP) experiments.
% Items display in sine wave.
%
% Fabienne Chetail - August 2015 - Fabienne.Chetail@ulb.be
% Natasa Ganea - March 2022 - natasa.ganea@gmail.com
%
% Copyright © 2022 Fabienne Chetail & Natasa Ganea. All Rights Reserved.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Fabienne Chetail script: https://osf.io/53hdb/ (March 2022)
%
% Natasa Ganea wrote this script based on Fabienne Chetail script. All the
% FlickerFaces functions were written by Natasa Ganea.
%
% FlickerFaces.m is the main script, and it is calling on:
%   PTB functions (http://psychtoolbox.org/)
%   Eyelink functions (SR-Research)
%   NetStation functions (EGI)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if nbCyReq is even, there are nbCyReq/2 different values of alpha in both ascending and descending):
%   - horizontal bar = level
%   - vertical bar = limit of a period
%
%      g h           i j
%      _ _           _ _
%     _   _         _   _
%    _     _       _     _
%   _       _     _       _
%  _         _   _         _
% _           _|_           _|_ ...
% a           c d           e f
%
%
% - a & c = item 1 invisible (alpha = 1)
% - d & e = item 2 invisible
% - f = item 3 invisible
% - g & h = item 1 visible (alpha = 0)
% - i & j = item 2 visible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if nbCyReq is odd, there are nbCyReq/2 different values of alpha in ascending and nbCyReq/2-1 in descending):
%   - horizontal bar = level
%   - vertical bar = limit of a period
%
%      g           i
%      _           _
%     _ _         _ _
%    _   _       _   _
%   _     _     _     _
%  _       _   _       _
% _         _|_         _|_ ...
% a         c d         e f
%
%
% - a & c = item 1 invisible (alpha = 1)
% - d & e = item 2 invisible
% - f = item 3 invisible
% - g = item 1 visible (alpha = 0)
% - i = item 2 visible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create alpha values for fadeIn / fadeOut
%
%                       _
%              _       _ _
%       _     _ _     _   _
%  _   _ _   _   _   _     _
% _ _|_   _|_     _|_       _|_ ... // x (10) trials (nbItemFade) to reach the base of an experiment trial
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% for pictures
%   - alpha = 0 => invisible
%   - alpha = 1 => visible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 0. INITIALIZING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
close all;

root = pwd;
rootStim = fullfile(pwd, 'FlickerFaces.stim');

% Load Face Images
faceStim = FlickerFaces_LoadStim(fullfile(rootStim, 'Faces'));
faceStimSz = size(faceStim(1).stim);

% Load Animal Images
animStim = FlickerFaces_LoadStim(fullfile(rootStim, 'Animals'));
animStimSz = size(animStim(1).stim);

% % Load Cloud Image
% cloudStim = FlickerFaces_LoadStim(fullfile(rootStim, 'Cloud'));
% 
% % Load Square Image = transparency mask
% squareStim = FlickerFaces_LoadStim(fullfile(rootStim, 'Square'));

%% 1. PARAMETERS FOR USERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% 1.1. General Parameters %%%%%%%%%%%%%%%%%%%%%

% Initialize variables
withETrecording = 0; % if 0 no interfacing with ET system, if 1 sending trigger to ET system
withEEGrecording = 0; % if 0 no interfacing with EEG system, if 1 sending trigger to EEG system
withPhotodiode = 1; % if 0 = square displayed for checking with photodiode, if 0 = no square
test = 0; % if 1 = temporary screen mode, if 0 = real mode (for true data collection)

% PC used
PC = 1; % 1 = Haskins desk screen; 2 = Haskins Laptop; 0 = Haskins EEG

% Trials/sequences per participant
nbSeq = 40; % trials; (2023-04-14 NG checked FF3 data FACE tr only, getting ITC & SNR peaks)
nbNoOvTr = round(nbSeq/1); % no overlap trials (central stim appears 1x)
nbOvTr = nbSeq - nbNoOvTr; % overlap trials

% Number peripheral stimuli
nbPerifStim = 1;

% Frequency ID
idFq = [6,12];  % use 2 flicker frequencies; fq1 = 6Hz & fq2 = 12Hz

% Cued trials
cueDur = 0; % in seconds (=0.5s); % cue participants to a perif stim for 500 ms

% Extended trials
extDur = 0;   % in seconds (=2s); % extend trial by 2s after flicker

% Counterbalance peripheral stimuli
fqABBA = 1; % 1 = counterbalance; 0 = don't counterbalance

% Catch trials
strCatch = 'dog';
nbDogTr = nbSeq * 0/100;  % catch trials ('dog' pic = target)

% Shuffle Face images
pairShuf = 1; % 0 = suffle randomly; 1 = suffle in pairs (3 4 7 8 1 2), because face >> noise

% Rotate Face images
rotaDur = 0.5; % rotation duration in seconds (=500ms)
rotaAngleMax = 90; % max rotation angle left/right (=90 deg)

% Experiment control keys
KbName('UnifyKeyNames');
keyEsc = KbName('Escape');        % Esc to terminate experiment (when trial ends)
keySpace = KbName('Space');       % Spacebar for Catch trials
keyA = KbName('A');               % A to start AttGet
totalPress = zeros(nbSeq,4);      % Record Spacebar presses & RT; c1 = faceRota1; c2 = faceRota2

%%% 1.2. SSVEP Parameters %%%%%%%%%%%%%%%%%%%%%

% Basic SSVEP parameters
RR = 60; % screen refresh rate
squareWaveP = 0; % 0 = presentation sine wave; 1 = presentation square wave

% Frequency of stimulation
fq = idFq(1,1); % flicker fq 1 required RR/6 = 10 refresh cycles per item
if size(idFq,2) == 2
    fq2 = idFq(1,2); % flicker fq2 requires RR/12 = 5 refresh cycles per item
else
    fq2 = idFq(1,1);
end

% Check that both frequencies divide equally the screen refresh rate
if isinteger(int8(RR/fq))~= 1 || isinteger(int8(RR/fq2))~= 1
    disp('Experiment cancelled');
    return
end

% Duration of fade in/fade out for each trial/sequence (to avoid ERP)
fade = RR/fq2/fq;   % =0.833 s; 5 items * 10 cycles/item = 50 refresh cycles
fade2 = RR/fq/fq2;  % =0.833 s; 10 items * 5 cycles/item = 50 refresh cycles

% Duration EEG epoch
epDur = 2; % =2s EEG epoch NoAtt/Att  

% Duration trial/sequence
trDur = 7.5; % 50/RR*9=7.5s;

% Number of flicker cycles in a trial/sequence
nbStim = round(RR*trDur/(RR/fq*RR/fq2),0); % = 450 refCyTot / 5 refCyFq1 / 10 refCyFq2 = 9; during the trial the alpha transparency value is the same for both fq every 50 refCy (happens 9 times during trial).
fullNbStim = nbStim*(RR/fq2); % 9*5 = 45 flickerCy; 45*10 refCy/flickerCy = 450 refCy; 450 refCy total / 60 refCy per sec = 7.5 sec
fullNbStim2 = nbStim*(RR/fq); % 9*10 = 90 flickerCy; 90*5 refCy/flickerCy = 450 refCy; 

% Check that both streams of items are equally long
if fullNbStim/fullNbStim2 ~= fq/fq2
    disp('Experiment cancelled');
    return
end

%%% 1.3. Stimuli size and location %%%%%%%%%%%%%%%%%%%%%

% Stimuli eccentricity (cm)
eccCm = 10;                                     % stimuli eccentricity = 10 cm

% Size stimuli on the screen (cm)
sizeDiscCm = 10;                                % width disc = 10 cm
sizeFaceCm = [7.5, 7.5*(faceStimSz(1)/faceStimSz(2))];  % width face = 3 cm; height face = 3.72 cm
sizeAnimCm = [5, 5*(animStimSz(1)/animStimSz(2))];  % width animal = 5 cm; height anim = maintain ratio
sizeCloudCm = 5;                                % width cloud = 5 cm

% Screen dimensions (cm)
if PC == 0 % Haskins EEG 
    widthCm = 52.5;   % cm
    heightCm = 29.5;  % cm  
elseif PC == 1 % Desc Screen
    widthCm = 51.5;
    heightCm = 32;
else % Haskins Laptop
    widthCm = 31.7;
    heightCm = 17.1;
end

% Square photodiode
pdTy = 0;  % 0 = PD for left frequency; 1 = PD for fq; 2 = PD for fq2
pdSz = 40; % square photodiode = 20 px
pdOn = [255 255 255];  % photodiode on = white
pdOff = [0 0 0];       % photodiode off = black

% Screen colours
fore = [0 0 0]; % stimuli color (foreground) if written stimuli
foreOval = [50, 50, 50]; % disc colour = grey; [255 255 255] = white;
back = [128 128 128]; % background color; [128 128 128] = grey

%% 2. METADATA & CHECK FILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The user is asked to encode metada
SsID = input ('Participant number:  ', 's');
fqBlk1 = input ('Start with frequency block 1 or 2:  ', 's');
fqBlk1 = str2double(fqBlk1);
ini = input ('Initiales?:  ', 's');
exp = input ('Exp?:  ', 's');
disp('  ');

% Check RR
disp(['Is the refresh rate at ' num2str(RR) ' Hz?' ]);
ok = input ('yes [1] or no [0]: ', 's');
if ~strcmp(ok,'1') == 1
    disp('Experiment cancelled');
    return
end

% Check if Screen 2 is the main display
disp('Is Screen 2 the main display and to the right of Screen 1?');
ok = input ('yes or N/A [1] or no [0]: ', 's');
if ~strcmp(ok,'1') == 1
    disp('Experiment cancelled');
    return
end

%% 3. PSYCHTOOLBOX PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Skip screen sync tests if test; for real experiments always do the tests
if test == 1
    Screen('Preference', 'SkipSyncTests', 1);
else
    Screen('Preference', 'SkipSyncTests', 0);
end

% Identify number of screens
screens = Screen('Screens'); % screens = 0 (one display); screens = [0, 1, 2] (two displays)

% Use Screen 2 to display stimuli
screenNum = max(screens);    % max(screens) = 2

% Get Screen 2 dimensions
[width, height] = Screen('WindowSize', screenNum); % Screen 2 dimensions

% If test, use these dimensions
if test == 1
    % width = 640;
    height = 500;
end

% Open a PTB window on Screen 2
if screenNum > 0
    [w, wrect] = Screen('OpenWindow', screenNum-1, back, [0 0 width height]);
else
    [w, wrect] = Screen('OpenWindow', screenNum, back, [0 0 width height]);
end

% Info about the PTB window
[mx,my] = RectCenter(wrect); % centre of the window
Priority(MaxPriority(w));  % make PTB window max priority
Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % set colors properly
cycleRefresh = Screen('GetFlipInterval', w); % get duration of refresh cycle

%% 4. SSVEP PARAMETERS COMPUTED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% 4.1. Basic parameters %%%%%%%%%%%%%%%%%%%%%

% Frequency 1 = 6 Hz 
onsetD = 1000/fq; % one stimulus each *onsetW* ms
TR = cycleRefresh; % duration of refresh cycle, based on what PT detect
nbCyReq = round(onsetD/(TR*1000)); % nb of refresh cycles required to display a stimulus (i.e., steps of the pyramid)
onsetDTrue = nbCyReq * TR*1000; % better estimation of stimulus display duration
fqTrue = 1000/onsetDTrue; % better estimation of frequency of stimulation
durTot = (fullNbStim*onsetDTrue)/1000; % true duration of a sequence
durCrit = durTot-2*fade; % true duration of the critical part of a sequence (without fade in / fade out)
nbItemFade = round(fq*fade); % number of items in fade in/fade out
nbItemExp = fullNbStim - 2*nbItemFade; % number of experimental items

% Frequency 2 = 12 Hz
onsetD2 = 1000/fq2; % one stimulus each *onsetW* ms
nbCyReq2 = round(onsetD2/(TR*1000)); % nb of refresh cycles required to display a stimulus (i.e., steps of the pyramid)
onsetDTrue2 = nbCyReq2*TR*1000; % better estimation of stimulus display duration
fqTrue2 = 1000/onsetDTrue2; % better estimation of frequency of stimulation
durTot2 = (fullNbStim2*onsetDTrue2)/1000; % true duration of a sequence
durCrit2 = durTot2-2*fade2; % true duration of the critical part of a sequence (without fade in / fade out)
nbItemFade2 = round(fq2*fade2); % number of items in fade in/ fade out
nbItemExp2 = fullNbStim2 - 2*nbItemFade2; % number of experimental items

% Log of the parameters
cd(root)
diary 'LOG.txt'
disp(['For the participant ', SsID]);
disp(['Screen refresh rate is ', num2str(1/TR), ' Hz']);
disp(['Duration of refresh cycle is ', num2str(TR*1000), ' ms']);
disp(['A disc flickering at ', num2str(fq),' is displayed each ', num2str(onsetDTrue), ' ms']);
disp(['A disc flickering at ', num2str(fq2),' is displayed each ', num2str(onsetDTrue2), ' ms']);
disp(['A true estimation of the frequency 1 of stimulation is ', num2str(fqTrue), ' Hz']);
disp(['A true estimation of the frequency 2 of stimulation is ', num2str(fqTrue2), ' Hz']);
disp(['The true Total duration of sequence is ', num2str(durTot), ' s']);
disp(['The true Critical duration of sequence is ', num2str(durCrit), ' s']);
disp(['The disc flickering at ', num2str(fq), ' Hz has ',...
    num2str(nbItemExp), ' critical items ',...
    num2str(nbItemFade), ' + ',...
    num2str(nbItemFade), ' items used for fadeIn/fadeOut']);
disp(['The disc flickering at ', num2str(fq2), ' Hz has ',...
    num2str(nbItemExp2), ' critical items ',...
    num2str(nbItemFade2), ' + ',...
    num2str(nbItemFade2), ' items used for fadeIn/fadeOut']);
diary off

%%% 4.2. Computations for transparency %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Computing alpha values - 6 Hz ; 10 refresh cyles
[alpha,alphaFadeIn,alphaFadeOut] = ...
    FlickerFaces_Transparency(squareWaveP,nbCyReq,nbItemFade);

% Computing alpha values - 12 Hz; 5 refresh cyles
[alpha2,alphaFadeIn2,alphaFadeOut2] = ...
    FlickerFaces_Transparency(squareWaveP,nbCyReq2,nbItemFade2);

% Transparency values by refresh cycle
alphaFadeInByCy = reshape(alphaFadeIn',[],1)';                      % fadeIn 6 Hz 
alphaFadeOutByCy = reshape(alphaFadeOut',[],1)';                    % fadeOut 6 Hz 
alphaByCy = repmat(alpha,1,nbItemExp);                              % exp 6 Hz 
alphaByCyTot = [alphaFadeInByCy, alphaByCy, alphaFadeOutByCy];      % all 6 Hz 

alphaFadeInByCy2 = reshape(alphaFadeIn2',[],1)';                    % fadeIn 12 Hz
alphaFadeOutByCy2 = reshape(alphaFadeOut2',[],1)';                  % fadeOut 12 Hz
alphaByCy2 = repmat(alpha2,1,nbItemExp2);                           % exp 12 Hz
alphaByCyTot2 = [alphaFadeInByCy2, alphaByCy2, alphaFadeOutByCy2];  % all 12 Hz

% Plot transparency by refresh cycle
% figure(1); plot(alphaFadeInByCy);figure(2); plot(alphaFadeInByCy2);
% figure(3); plot(alphaFadeOutByCy); figure(4); plot(alphaFadeOutByCy2);
% figure(5); plot(alphaByCyTot);
% figure(6); plot(alphaByCyTot2);

%% 5. DEFINE TRIAL TYPE, STIMULI, STIMULI ONSET, STIMULI POSITION, ALPHA, PHOTODIODE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% 5.1. Trial type %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[trTyBySeq, fqLoc, cueLoc] = FlickerFaces_TrialType(nbSeq, nbCyReq,...
    nbItemFade, nbNoOvTr, nbOvTr, nbDogTr, nbPerifStim, idFq, fqABBA,...
    RR, cueDur, extDur, epDur, fqBlk1);

%%% 5.2. Stim textures %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[faceStim] = FlickerFaces_Texture(w,faceStim);
[animStim] = FlickerFaces_Texture(w,animStim);
% [cloudStim] = FlickerFaces_Texture(w,cloudStim);
% 
% stimTmp = squareStim.stim;
% stimTmp(:,:,:) = back(1);
% squareStim.tex = Screen('MakeTexture', w, stimTmp);
% clearvars stimTmp

%%% 5.3. Stim order %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nbDogTr > 0 % if there are catch trials
    nbAnimStim = size(animStim); % reorder animals so dog last
    nbAnimStim = nbAnimStim(2);
    for i = 1:nbAnimStim
        if strcmp(animStim(i).name(1:3),strCatch) == 1
            animStimTmp = animStim(i);
            delRow = i;
        end
    end
    animStim(delRow) = [];
    animStim = [animStim,animStimTmp];
    clearvars animStimTmp
end

[stimOrderBySeq, stimOrderTable] = FlickerFaces_StimOrder(nbSeq, nbCyReq,...
    nbItemFade, trTyBySeq, faceStim, animStim, 1, 1, pairShuf); % cloudStim = 1; squareStim = 1;

%%% 5.4. Stim onset %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[stimOnsetBySeq, stimOnsetTable] = FlickerFaces_StimOnset(nbSeq, nbCyReq,...
    nbItemFade, nbItemExp, trTyBySeq, RR);

%%% 5.5. Stim position %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% rectCloud = FlickerFaces_StimRect(nbPerifStim, nbSeq, width, height, widthCm, heightCm,...
%     sizeCloudCm, sizeCloudCm, eccCm, fqABBA, fqLoc);    % fqABBA = 1; counterbalance faces

rectAnim = FlickerFaces_StimRect(nbPerifStim, nbSeq, width, height, widthCm, heightCm,...
    sizeAnimCm(1), sizeAnimCm(2), eccCm, fqABBA, fqLoc); % fqABBA = 1; counterbalance faces

rectFace = FlickerFaces_StimRect(0, nbSeq, width, height,...
    widthCm, heightCm, sizeFaceCm(1), sizeFaceCm(2));     % 0 = central stimulus

% rectCue = FlickerFaces_StimRect(nbPerifStim, nbSeq, width, height,...
%     widthCm, heightCm, sizeDiscCm, sizeDiscCm);           % 0 = central stimulus

% store perif stim location info
fqEcc = struct2table(rectFace); fqEcc = fqEcc.ecc;
stimLocBySeq = struct('tr', num2cell((1:nbSeq)'), 'fqEcc', num2cell(fqEcc));
stimLocBySeqT = struct2table(stimLocBySeq);
stimOrderTable = join(stimOrderTable,stimLocBySeqT);
clearvars stimLocBySeqT

%%% 5.6. Rotate face %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rotaFace = FlickerFaces_RotaStim(nbSeq, nbCyReq, nbItemFade,...
    stimOnsetBySeq, RR, rotaDur, rotaAngleMax);

%%% 5.7. Alpha by sequence %%%%%%%%%%%%%%%%%%%%%%%%%
alphaBySeq = FlickerFaces_StimAlpha(nbSeq, RR, fq, fq2, alphaByCyTot,...
    alphaByCyTot2, stimOnsetBySeq.cyStaSeq, stimOnsetBySeq.cyEndSeq);

%%% 5.8. Photodiode by sequence %%%%%%%%%%%%%%%%%%%%%%%%%
pdBySeq = FlickerFaces_PhotodiodeCy(nbSeq, RR, fq, fq2, trTyBySeq.trTyFq,...
    fqLoc, stimOnsetBySeq.cyStaSeq, stimOnsetBySeq.cyEndSeq, stimOnsetBySeq.cyEndTr);
pdRect = [0, height-pdSz, pdSz, height];

%%% 5.9. Triggers by sequence %%%%%%%%%%%%%%%%%%%%%%%%%
trigBySeq = FlickerFaces_Triggers(nbSeq, trTyBySeq.trTyFq, fqLoc,...
    trTyBySeq.trTyDog, fqEcc, trTyBySeq.cueFq, trTyBySeq.nbCyCue,...
    trTyBySeq.fqFace);

%% 6. READY?

%%% Ready to connect to NetStation & Eyelink?
Screen(w, 'FillRect', back);
if withPhotodiode == 1
    Screen(w, 'FillRect', pdOn, pdRect);
end
DrawText(w, 'READY ?', 'Arial', 100, 0, fore)
Screen('Flip', w);
fprintf('Ready? \n');
[~, keyCode] = KbWait([],3); % wait for any key press
if any(keyCode(keyEsc))
    Screen('CloseAll');
    return
end

% Hide mouse cursor
HideCursor(screenNum);
cd(root)
tStart = GetSecs();

%% 6. NET STATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Connect to NetStation
if withEEGrecording == 1
    [statusEEG, errorEEG] = NetStation('Connect', '10.10.10.51', '55513');
    NetStation('GetNTPSynchronize', '10.10.10.51'); % Mark Moran, EGI suggests this function insead of 'Synchronize'
    if statusEEG ~= 0
        disp('Experiment cancelled. Cannot connect to NetStation.');
        return        % abort if cannot connect to NetStation
    else
        fprintf('NetStation connected \n');
    end
end

%% 7. EYELINK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Connect to Eyelink
if withETrecording == 1
    FlickerFaces_AttGet(w, wrect, back, [], [], withPhotodiode, pdOff, pdRect);
    Eyelink_Initialize;
    fprintf('Eyelink connected \n');
end

%% 8. START?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Start experiment?
if withPhotodiode == 1
    Screen(w, 'FillRect', pdOn, pdRect);
end
DrawText(w, 'START ?', 'Arial', 100, 0, fore)
Screen(w, 'Flip');
fprintf('Start \n');
WaitSecs(0.2);
[~, keyCode] = KbWait([],3); % wait for any key press
abortExp = 0;

if any(keyCode(keyEsc))
    disp('Experiment cancelled');
    if withETrecording == 1
        Eyelink_Disconnect;
    end
    if withEEGrecording == 1
        NetStation('StopRecording')
        NetStation('Disconnect')
    end
    Screen('CloseAll');
    ShowCursor;
    cd(root);
    return
end

%% 9. SUPER LOOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% DIAGNOSTIC DATA structure
dDiag = struct('d',zeros(nbSeq,1),'flipTy',cell(nbSeq,1));

%%% Store stim onset time for NetStation event marking;
nsEvtSot = zeros(nbSeq,3); % col1 = stim onset; col2 = FaceRota1; col3 = FaceRota2

%%% Start EEG recording
if withEEGrecording == 1
    NetStation('StartRecording');
    WaitSecs(0.1);  % record some EEG data to avoid data distorsion due to antialiasing filter
end

%%% For each trial/sequence
for ss = 1:nbSeq
    
    % set AttGet to 0
    attGet = 0;
    
    % define textures
    iA1 = stimOrderBySeq.A1(ss);
%     iS = stimOrderBySeq.square(ss);
    iF1 = stimOrderBySeq.F1(ss);
    iF2 = stimOrderBySeq.F2(ss);
    
    if nbPerifStim == 2     % 2 peripheral stimuli
        faceTex = [faceStim(iF1).tex, faceStim(iF2).tex];       % 2 face textures
        % squareTex = [squareStim(iS).tex, squareStim(iS).tex]; % 2 square textures
        iAlpha = (1:2);                                         % 2 alpha values for transparency
    else                    % 0 or 1 peripheral stimulus
        faceTex = faceStim(iF1).tex;                    % 1 face texture
        % squareTex = squareStim(iS).tex;                 % 1 square texture
        iAlpha = trTyBySeq.trTyFq(ss);                  % 1 alpha value for transparency
    end
    
    % initialize DIAGNOSTIC variables
    d = zeros(stimOnsetBySeq.cyEndTr(ss),8);        % flip characteristics (diagnostic data)
    flipTy = cell(stimOnsetBySeq.cyEndTr(ss),1);    % flip type: cue, fade in, exp, fade out, extend
    
    % AttGet
    if withPhotodiode == 1
        Screen(w, 'FillRect', pdOff, pdRect);
    end
    [~,abortExp] = FlickerFaces_AttGet(w, wrect, back, [], ...
            [width/2-100, height/2-100, width/2+100, height/2+100], ...
            withPhotodiode, pdOff, pdRect);
    Screen(w, 'FillRect', back, [width/2-100, height/2-100, width/2+100, height/2+100]);

    % Start ET recording
    if withETrecording == 1 && abortExp == 0
        Eyelink_TrialStart;
    end
    
    % for each refresh cycle
    for j = 1:stimOnsetBySeq.cyEndTr(ss)
        
        % PHOTODIODE
        if withPhotodiode == 1
            if pdBySeq(ss).cyOn(j,1) == 0
                Screen(w, 'FillRect', pdOff, pdRect);
            elseif pdBySeq(ss).cyOn(j,1) == 1
                Screen(w, 'FillRect', pdOn, pdRect);
            end
        end
        
        % STIMULI
        if j <= stimOnsetBySeq.cyEndCue(ss)
            
            flipTy(j) = {'cue'};
            DrawText(w, '+', 'Arial', 150, 1, fore);           % bold black fix cross
            Screen('Flip', w);
            
        elseif j <= stimOnsetBySeq.cyEndSeq(ss)
            
            if j <= stimOnsetBySeq.cyEndFadeIn(ss)
                flipTy(j) = {'fadeIn'};
            elseif j <= stimOnsetBySeq.cyEndExp(ss)
                flipTy(j) = {'exp'};
            else
                flipTy(j) = {'fadeOut'};
            end
            
            if j < stimOnsetBySeq.cyStaRota(ss)  % rotate the peripheral animal
                Screen('DrawTextures', w, animStim(iA1).tex, [], rectAnim(ss).rect, ...
                    rotaFace(ss).ang(j,:));
                Screen('DrawTextures', w, faceTex, [], rectFace(ss).rect, [], [],...
                    alphaBySeq(ss).alpha(j,iAlpha));
            else                                 % stop flicker, rotate the face
                Screen('DrawTextures', w, animStim(iA1).tex, [], rectAnim(ss).rect);
                Screen('DrawTextures', w, faceTex, [], rectFace(ss).rect, ...
                    rotaFace(ss).ang(j,:));
            end
            
            [d(j,1), d(j,2), d(j,3), d(j,4), d(j,5)] = Screen('Flip', w); % save flip characteristics
            d(j,6) = alphaBySeq(ss).alpha(j,iAlpha);
            d(j,7) = alphaBySeq(ss).item(j,iAlpha);
            d(j,8) = alphaBySeq(ss).cy(j,iAlpha);
            
        elseif j == stimOnsetBySeq.cyEndTr(ss)
            
            Screen('Flip', w); % trial end; flip Photodiode rectangle
            
        end % end RefCy type loop
        
        % TRIGGER start trial
        if j == stimOnsetBySeq.cyStaSeq(ss)
            nsEvtSot(ss,1) = d(j,2);               % NetStation event stim onset time
            if withETrecording == 1
                Eyelink('Message', 'STIM_ONSET');  % Write message to EDF file
                Eyelink_TrialMessage;
            end
        end
        
        % FACE_ROTA_1: time & keypress (KbCheck for 1s)
        if j == stimOnsetBySeq.cyEndPr1A(ss)
            nsEvtSot(ss,2) = d(j,2);            % FaceRota1 onset time
        elseif j > stimOnsetBySeq.cyEndPr1A(ss) && j <= stimOnsetBySeq.cyEndKbCk1(ss)
            if totalPress(ss,1) == 0
                [~,keyTime,keyCode] = KbCheck();
                if any(keyCode(keySpace))
                    totalPress(ss,1) = 1;       % keypress FaceRota1
                    totalPress(ss,3) = keyTime; % time of keypress
                end
            end
        end
        
        % FACE_ROTA_2: time & keypress (KbCheck for 1s)
        if j == stimOnsetBySeq.cyStaRota(ss)
            nsEvtSot(ss,3) = d(j,2);            % FaceRota2 onset time
        elseif j > stimOnsetBySeq.cyStaRota(ss) && j <= stimOnsetBySeq.cyEndKbCk2(ss)
            if totalPress(ss,2) == 0
                [~,keyTime,keyCode] = KbCheck();
                if any(keyCode(keySpace))
                    totalPress(ss,2) = 1;       % keypress FaceRota2
                    totalPress(ss,4) = keyTime; % time of keypress
                end
            end
        end
        
        % ATTGET or ABORT EXPERIMENT
        [~,~,keyCode] = KbCheck(); % RestrictKeysForKbCheck([spaceKey escapeKey]);
        if any(keyCode(keyA))
            disp('AttGet');
            attGet = 1;
            break
        elseif any(keyCode(keyEsc))
            disp('Experiment cancelled');
            abortExp = 1;
            break
        end
          
    end  % end TRIAL for loop  

    % blank screen
    if withPhotodiode == 1
        Screen(w, 'FillRect', pdOff, pdRect);
    end
    Screen('Flip', w);
    
    % TRIGGER trial end
    FlickerFaces_TrialEnd('SendTrigger', withETrecording,...
        withEEGrecording, trigBySeq(ss), nsEvtSot(ss,1));
   
    % SAVE DATA trial
    [dDiag, totalPress] = FlickerFaces_TrialEnd('SaveTrialData',...
        ss, d, flipTy, dDiag, totalPress,...
        stimOnsetBySeq.cyEndPr1A(ss),...
        stimOnsetBySeq.cyStaRota(ss),...
        withETrecording, trTyBySeq,...
        fqLoc, fqEcc, back);
    
    % if ATTGET requested, play AttGet video
    if attGet == 1
        [~,abortExp] = FlickerFaces_AttGet(w, wrect, back, [], ...
            [width/2-100, height/2-100, width/2+100, height/2+100]);
        Screen(w, 'FillRect', back); % clean background after AttGet
        if withPhotodiode == 1
            Screen(w, 'FillRect', pdOff, pdRect);
        end
        Screen('Flip', w);
    end
                    
    % if ABORT EXPERIMENT requested, exit trials FOR loop
    if abortExp == 1
        break
    end
    
    % HALFWAY trials
    if ss == nbSeq/2 && abortExp == 0
        DrawText(w, 'Halfway through. Take a short break! \n Press SPACEBAR to continue.',...
            'Arial', 80, 0, fore)
        Screen(w, 'Flip');
        KbWait([],3);
    end

end % end TRIALS loop

%% 10. END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Close Eyelink
if withETrecording == 1
    Eyelink_Disconnect;
end

% Close NetStation
if withEEGrecording == 1
    NetStation('StopRecording')
    NetStation('Disconnect')
end

% Save StimFinalTable to open in Excel
totalPress(:,5) = 1:length(totalPress); % add tr to join tables later
keypressTotalT = array2table(totalPress,'VariableNames',{'keypressFaceRota1',...
    'keypressFaceRota2','rtFaceRota1','rtFaceRota2', 'tr'}); 
stimFinalTable = join(keypressTotalT,stimOnsetTable); 
fileOut = sprintf('%s_%s.csv', exp, SsID);
writetable(stimFinalTable,fileOut);

% Save Matlab variables
fileOut = sprintf('%s_%s', exp, SsID);
save(fileOut)

% Close PTB
Screen('CloseAll');
ShowCursor;
cd(root);