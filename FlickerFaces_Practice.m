function [practComplete, totalPressPract] = FlickerFaces_Practice(nbPerifStimIn,testIn,PC)
%
% This script allows the participant to read the study instructions for the
% FlickerFaces study and run 10 practice trials.
%
% Key presses:
%   E = example
%   SPACEBAR = start practice
%   ESC = end practice
%
%==========================================================================
% Created by Natasa Ganea, 2022-11-15, Haskins Laboratories (natasa.ganea@gmail.com)
% Licensed to you under the MIT open-source license.
%==========================================================================

%% 1. DEFAULTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 1 || isempty(nbPerifStimIn) == 1
    nbPerifStim = 1;     % Number peripheral stimuli
elseif nbPerifStimIn > 2
    disp('Practice cancelled. Max 2 peripheral stimuli')
    return
end

if nargin < 2 || isempty(testIn) == 1
    test = 0; % if 1 = temporary screen mode, if 0 = real mode (for true data collection)
elseif testIn > 1
    disp('Practice cancelled. Max test mode is 1')
    return
end

if nargin < 3 || isempty(PC) == 1
    PC = 0; % 2 = Haskins laptop; 1 = Desk screen; 0 = Haskins EEG
end

%% 2. INITIALIZE VARIABLES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% 2.1. User options %%%%%%%%%%%%%%%%%%%%%

% Load practice images
root = pwd;
rootStim = fullfile(pwd, 'FlickerFaces.stim');
practImg = FlickerFaces_LoadStim(fullfile(rootStim, 'Practice'));
instrImg = FlickerFaces_LoadStim(fullfile(rootStim, 'Instruct'));

% Trials practice
nbSeq = 6; % trials
nbNoOvTr = round(nbSeq/1); % no overlap trials (central stim appears 1x)
nbOvTr = nbSeq-nbNoOvTr; % overlap trials

% Frequency ID
idFq = [6,12];  % use 2 flicker frequences simulateneously; fq1 = 6Hz & fq2 = 12Hz

% Cued trials
cueDur = 0; % in seconds (=0.25s); % cue participants to a perif stim for 250 ms

% Extended trials
extDur = 0;   % in seconds (=2s); % extend trial by 2s after flicker

% Counterbalance peripheral stimuli
fqABBA = 1; % 1 = counterbalance; 0 = don't counetrbalance

% % Catch trials
nbDogTr = 0;  % catch trials ('dog' pic = target)

% Rotate Face images
rotaDur = 0.5; % rotation duration in seconds (=500ms)
rotaAngleMax = 90; % max rotation angle left/right (=90 deg)

% Experiment control keys
KbName('UnifyKeyNames');
keyEsc = KbName('Escape');        % Esc to terminate experiment (when trial ends)
keySpace = KbName('Space');       % Spacebar for answer
keyE = KbName('E');               % E for example video
totalPressPract = zeros(nbSeq,2); % Record Spacebar presses & RT; c1 = perifAnimRota1; c2 = faceRota2

%%% 2.2. SSVEP Parameters %%%%%%%%%%%%%%%%%%%%%

% Basic SSVEP parameters
RR = 60; % screen refresh rate
squareWaveP = 0; % 0 = presentation sine wave; 1 = presentation square wave

% Frequency of stimulation
fq = idFq(1,1);  % flicker fq1 required RR/6 = 10 refresh cycles per item
if size(idFq,2) == 2
    fq2 = idFq(1,2); % flicker fq2 requires RR/12 = 5 refresh cycles per item
else
    fq2 = idFq(1,1);
end


% Number of items in a trial/sequence (trDur = 450 refCy = 7.5 sec)
nbStim = 9; % = 450 refCyTot / 5 refCyFq1 / 10 refCyFq2 = 9; during the trial the alpha transparency value is the same for both fq every 50 refCy (happens 9 times during trial).
fullNbStim = nbStim*(RR/fq2); % 50 items @ 6Hz    (=8.33s; 50 items * 10 cycles/item = 500 refresh cycles)
fullNbStim2 = nbStim*(RR/fq); % 100 items @ 12Hz  (=8.33s; 100 items * 5 cycles/item = 500 refresh cycles)

%%% 2.3. Stimuli size and location %%%%%%%%%%%%%%%%%%%%%

% Stimuli eccentricity (cm)
eccCm = 10;                                     % stimuli eccentricity = 10 cm

% Size stimuli on the screen (cm)
sizeFacePx = size(practImg(4).stim);
sizeAnimPx = size(practImg(2).stim);
% sizeDiscCm = 10;                                          % width disc = 10 cm
sizeFaceCm = [7.5, 7.5*(sizeFacePx(1)/sizeFacePx(2))];    % width face = 3 cm; height face = 3.72 cm
sizeAnimCm = [5, 5*(sizeAnimPx(1)/sizeAnimPx(2))];        % width animal = 5 cm; height anim = maintain ratio
% sizeCloudCm = 5;                                          % width cloud = 5 cm

% Screen dimensions (cm)
if PC == 0 % Haskins EEG
    widthCm = 52.5;   % cm
    heightCm = 29.5;  % cm
elseif PC == 1 % Desk Screen
    widthCm = 51.5;
    heightCm = 32;
else % Haskins Laptop
    widthCm = 31.7;
    heightCm = 17.1;
end

% Screen colours
fore = [0 0 0]; % stimuli color (foreground) if written stimuli
% foreOval = [50, 50, 50]; % disc colour = grey; [255 255 255] = white;
back = [128 128 128]; % background color; [128 128 128] = grey

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

% check screen refresh cycle matches the one entered by user
if round(1/RR,3) ~= round(cycleRefresh,3)
    disp('Practice cancelled. Check screen refresh rate.');
    Screen('CloseAll');
end
%% 4. SSVEP PARAMETERS COMPUTED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% 4.1. Basic parameters %%%%%%%%%%%%%%%%%%%%%

% Frequency 1 = 6 Hz
nbCyReq = RR/fq;        % nb of refresh cycles required to display a stimulus (i.e., steps of the pyramid)
nbItemFade = 1*RR/fq2;  % nb items fadeIn
nbItemExp = fullNbStim - 2*nbItemFade; % number of experimental items

% Frequency 2 = 12 Hz
nbCyReq2 = RR/fq2;      % nb of refresh cycles required to display a stimulus (i.e., steps of the pyramid)
nbItemFade2 = 1*RR/fq;  % nb items fadeIn
nbItemExp2 = fullNbStim2 - 2*nbItemFade2; % number of experimental items

%%% 4.2. Computations for transparency %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Computing alpha values - 6 Hz; 10 refresh cyles
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

%% 5. DEFINE TRIAL TYPE, STIMULI ONSET, STIMULI POSITION, ALPHA, PHOTODIODE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% 5.1. Trial type %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[trTyPract, fqLoc, ~] = FlickerFaces_TrialType(nbSeq, nbCyReq,...
    nbItemFade, nbNoOvTr, nbOvTr, nbDogTr, nbPerifStim, idFq, fqABBA,...
    RR, cueDur, extDur); % last output = cueLoc

%%% 5.2. Stim textures %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
faceStim = FlickerFaces_Texture(w,practImg(4:5));
animStim = FlickerFaces_Texture(w,practImg(3:4));
% cloudStim = FlickerFaces_Texture(w,practImg(1));

% stimTmp = practImg(6).stim;
% stimTmp(:,:,:) = back(1);
% squareStim.tex = Screen('MakeTexture', w, stimTmp);
% clearvars stimTmp

%%% 5.3. Stim order %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stimOrderPract = FlickerFaces_StimOrder(nbSeq, nbCyReq, nbItemFade,...
    trTyPract, faceStim, animStim, 1, 1);   % cloudStim = 1; squareStim = 1;

%%% 5.4. Stim onset %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stimOnsetPract = FlickerFaces_StimOnset(nbSeq, nbCyReq, nbItemFade,...
    nbItemExp, trTyPract, RR);

%%% 5.5. Stim position %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rectAttGet = [width/2-100, height/2-100, width/2+100, height/2+100];

% rectCloud = FlickerFaces_StimRect(nbPerifStim, nbSeq, width, height, widthCm, heightCm,...
%     sizeCloudCm, sizeCloudCm, eccCm, fqABBA, fqLoc);  % fqABBA = 1; counterbalance faces

rectAnim = FlickerFaces_StimRect(nbPerifStim, nbSeq, width, height, widthCm, heightCm,...
    sizeAnimCm(1), sizeAnimCm(2),  eccCm, fqABBA, fqLoc); % fqABBA = 1; counterbalance faces

rectFace = FlickerFaces_StimRect(0, nbSeq, width, height,...
    widthCm, heightCm, sizeFaceCm(1), sizeFaceCm(2)); % 0 = central stimulus

% rectDisc = FlickerFaces_StimRect(0, nbSeq, width, height,...
%     widthCm, heightCm, sizeDiscCm, sizeDiscCm); % 0 = central stimulus
%
% rectCue = FlickerFaces_StimRect(nbPerifStim, nbSeq, width, height,...
%     widthCm, heightCm, sizeDiscCm, sizeDiscCm, eccCm, fqABBA, cueLoc);

%%% 5.6. Stim looming %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% loomCloud = FlickerFaces_LoomStim(nbSeq, nbCyReq, nbItemFade,...
%     width, height, widthCm, heightCm, stimOnsetPract, rectCloud);
% loomAnim = FlickerFaces_LoomStim(nbSeq, nbCyReq, nbItemFade,...
%     width, height, widthCm, heightCm, stimOnsetPract, rectAnim);

%%% 5.7. Rotate face %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rotaFace = FlickerFaces_RotaStim(nbSeq, nbCyReq, nbItemFade,...
    stimOnsetPract, RR, rotaDur, rotaAngleMax);

%%% 5.8. Alpha by sequence %%%%%%%%%%%%%%%%%%%%%%%%%
alphaPract = FlickerFaces_StimAlpha(nbSeq, RR, fq, fq2, alphaByCyTot,...
    alphaByCyTot2, stimOnsetPract.cyStaSeq, stimOnsetPract.cyEndSeq);

%% 6. INSTRUCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% 6.1. Participant instructions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
instr1 = {'This study aims to find out whether your brain activity ',...
    'differs when you pay attention to something. \n\n',...
    'During each trial, you will see a flickering picture ',...
    'in the centre of the screen. \n',...
    'Next to the picture, you will see a cartoon. The cartoon ',...
    'and the central picture will \n',...
    'swing at different points during the trial. \n\n',...
    'Your task is to always look at the central picture. While ',...
    'you look at the centre, pay attention to the \n',...
    'peripheral cartoon. When the cartoon swings, press the ',...
    'SPACEBAR. After you press the SPACEBAR, \n',...
    'continue to look at the central picture and pay attention ',...
    'to it because it will swing later in the trail. \n',...
    'When the central picture swings, press the SPACEBAR again. \n\n',...
    'The cartoon can be on the left or right side of the screen. \n\n',...
    'Press E to watch an example. \n',...
    'Press SPACEBAR to start the practice trials. \n',...
    'Press ESC to cancel. \n\n'};
instr1 = sprintf('%s', instr1{:});

% write instructions
DrawText(w, instr1, 'Arial', 30, 0, fore, 40, 100);
instrStimTex = Screen('MakeTexture', w, instrImg(1).stim);
Screen('DrawTexture', w, instrStimTex, [],...
    [mx-round(size(instrImg(1).stim,2)/2,1), my,... % left top
    mx+round(size(instrImg(1).stim,2)/2,2), my+size(instrImg(1).stim,1)]); % right bottom
Screen('Flip', w);

%%% 6.2. User options %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while 1
    [~, keyCode] = KbWait([],3);
    
    % trial example
    if any(keyCode(keyE))
        for i = 1:length(instrImg)
            DrawText(w, instr1, 'Arial', 30, 0, fore, 40, 100);
            instrStimTex = Screen('MakeTexture', w, instrImg(i).stim);
            Screen('DrawTexture', w, instrStimTex, [],...
                [mx-round(size(instrImg(1).stim,2)/2,1), my,...
                mx+round(size(instrImg(1).stim,2)/2,2), my+size(instrImg(1).stim,1)]);
            Screen('Close',instrStimTex);
            Screen('Flip', w);
        end
        
        % end practice
    elseif any(keyCode(keyEsc))
        break
        
        % continue to practice trials
    elseif any(keyCode(keySpace))
        break
    end
end

% close PTB window if practice ended by user
if any(keyCode(keyEsc))
    Screen('CloseAll');
    return
end

%%% 6.3. Summary instructions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
instr2 = {'Remember \n\n',...
    '1) always look at the central picture, but attend to the cartoon \n\n',...
    '     a) when the cartoon swings >> press SPACEBAR \n\n',...
    '2) always look at the central picture, and attend to it \n\n',...
    '     a) when the central picture swings >> press SPACEBAR \n\n\n',...
    'Try to be fast and accurate! \n\n\n', ...
    'Press SPACEBAR to start the practice trials. \n',...
    'Press ESC to cancel. \n\n'};
instr2 = sprintf('%s', instr2{:});

% write summary instructions
DrawText(w, instr2, 'Arial', 40, 0, fore, 200, 200);
Screen('Flip', w);

% user options
[~, keyCode] = KbWait([],3);
if any(keyCode(keyEsc))
    Screen('CloseAll');
    return
end

%% 7. PRACTICE TRIALS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% For each trial/equence %%%%%%%%%%%%%%%%%%
for ss = 1:nbSeq
    
    % define textures
    iA1 = stimOrderPract.A1(ss);
    % iS = stimOrderPract.square(ss);
    iF1 = stimOrderPract.F1(ss);
    iF2 = stimOrderPract.F2(ss);
    
    if nbPerifStim == 2     % 2 peripheral stimuli
        faceTex = [faceStim(iF1).tex, faceStim(iF2).tex];       % 2 face textures
        % squareTex = [squareStim(iS).tex, squareStim(iS).tex]; % 2 square textures
        iAlpha = (1:2);                                         % 2 alpha values for transparency
    else                    % 0 or 1 peripheral stimulus
        faceTex = faceStim(iF1).tex;                    % 1 face texture
        % squareTex = squareStim(iS).tex;                 % 1 square texture
        iAlpha = trTyPract.trTyFq(ss);                  % 1 alpha value for transparency
    end
    
    % AttGet
    [~,endPract] = FlickerFaces_AttGet(w, wrect, back, [], rectAttGet);
    Screen('FillRect', w, back, rectAttGet);
    Screen('Flip', w);
    
    % for each refresh cycle
    for j = 1:stimOnsetPract.cyEndTr(ss)
        
        % STIMULI
        if j <= stimOnsetPract.cyEndCue(ss)
            
            DrawText(w, '+', 'Arial', 150, 1, fore);           % bold black fix cross
            % Screen('FillOval', w, foreOval, rectCue(ss).rect); % cue grey circle
            Screen('Flip', w);
            
        elseif j <= stimOnsetPract.cyEndSeq(ss)
            
            if j <= stimOnsetPract.cyStaRota(ss)
                Screen('DrawTextures', w, animStim(iA1).tex, [], rectAnim(ss).rect,...
                    rotaFace(ss).ang(j,:));
                Screen('DrawTextures', w, faceTex, [], rectFace(ss).rect, [], [],...
                    alphaPract(ss).alpha(j,iAlpha));
            else
                Screen('DrawTextures', w, animStim(iA1).tex, [], rectAnim(ss).rect);
                Screen('DrawTextures', w, faceTex, [], rectFace(ss).rect, ...
                    rotaFace(ss).ang(j,:));
            end
            Screen('Flip', w);
            
        end  % end RefCy type loop
        
        % keypresses for AnimRota1
        if j > stimOnsetPract.cyEndPr1A(ss) && j <= stimOnsetPract.cyEndKbCk1(ss)
            if totalPressPract(ss,1) == 0
                [~,~,keyCode] = KbCheck();
                if any(keyCode(keySpace))
                    totalPressPract(ss,1) = 1;   % keypress AnimRota1
                end
            end
        end
        
        % keypresses for FaceRota2
        if j > stimOnsetPract.cyStaRota(ss) && j <= stimOnsetPract.cyEndKbCk2(ss)
            
            % keypresses for FaceRota2
            if totalPressPract(ss,2) == 0
                [~,~,keyCode] = KbCheck();
                if any(keyCode(keySpace))
                    totalPressPract(ss,2) = 1; % keypress FaceRota2
                end
            end
        end
        
        % END PRACTICE
        [~,~,keyCode] = KbCheck(); % RestrictKeysForKbCheck([spaceKey escapeKey]);
        if any(keyCode(keyEsc))
            disp('Practice cancelled');
            endPract = 1;
            break % exit refresh cycle FOR loop
        end
        
    end % end refresh cycle FOR loop
    
    % exit trials FOR loop
    if endPract == 1
        break
    end
    
end

%% 8. END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Close PTB
Screen('CloseAll');
ShowCursor;
cd(root);

% function status
practComplete = 1;
end
