function [movEnded, expLoop] = FlickerFaces_AttGet(EXPWIN_in,...
    EXPWINsz_in, EXPWINcol_in, movFolder_in, movRect_in,...
    withPhotodiode, pdOff, pdRect)

% Function that presents the TRIAL movies for avGender study.
%
% General syntax
% [trialEnded, experimentLoop]
%       = FlickerFaces_AttGet([EXPWIN][,EXPWINSIZE][,movFolder][,movRectangle])
%
% movRect = requires 4 data points, e.g.[0 0 800 600]
%
% Defaults:
%           1) EXPWIN = computer screen
%           2) EXPWINSIZE = whole screen
%           3) movFolder = 'FlickerFaces.extra'
%           4) movRect = entire screen
%
% Movies run until the end, or keypress. In the first 20 s, max movie
% duration is 5 s.
%
% Key controls: ESC to exit the function
%
% =======================
% Created by Natasa Ganea, Goldsmiths InfantLab, 2019 (natasa.ganea@gmail.com)
% Modified by Natasa Ganea, Haskins Lab, 2022 - default movie, elapsed time
%
% Copyright © 2019 Natasa Ganea. All Rights Reserved.
% =======================

%% keycodes

KbName('UnifyKeyNames');    % keyboard mapping same on all supported operating systems
ESC = KbName('escape');     % exit experiment
SPACE = KbName('Space');    % exit movie presentation

%% function inputs

% if EXPWIN window is omitted or empty
if nargin < 1 || isempty(EXPWIN_in)
    trialTest = 1;
    Screen('Preference','SkipSyncTests',0);
    screens = Screen('Screens');
    screenNum = max(screens);
    PsychDebugWindowConfiguration(0,0.5); % type "clear all" in the CmdWindow
    [EXPWIN, EXPWINsz] = Screen('OpenWindow', screenNum);
    Screen('FillRect', EXPWIN, [255 255 255]);
    Screen('Flip', EXPWIN, [], 1);
else
    trialTest = 0;
    EXPWIN = EXPWIN_in;
end

% if EXPWINsize is omitted or empty
if nargin < 2 || isempty(EXPWINsz_in)
    if isempty(EXPWINsz)
        EXPWINsz = [0, 0, 800, 600];
    end
else
    EXPWINsz = EXPWINsz_in;
end

% if EXPWINcolour is omitted or empty
if nargin < 3 || isempty(EXPWINcol_in)
    EXPWINcol = [0 0 0]; % black (helps with photodiode)
else
    EXPWINcol = EXPWINcol_in;
end

% if no attention stimulus given, use default
if nargin < 4 || isempty(movFolder_in)
    root = pwd;
    rootExtra = fullfile(root,'FlickerFaces.extra');
else
    rootExtra = movFolder_in;
end
rootFix = fullfile(rootExtra,'fixation');
rootMov = fullfile(rootExtra,'movies');

% if no Trial stimulus rectangle given
if nargin < 5 || isempty(movRect_in)
    [movDest] = [EXPWINsz(3)/2-100, EXPWINsz(4)/2-100,...
        EXPWINsz(3)/2+100, EXPWINsz(4)/2+100];
else
    movDest = movRect_in;
end

% with Photodiode rectangle?
if nargin < 6 || isempty(withPhotodiode)
    withPhotodiode = 0;
end

% Photodiode OFF - black
if nargin < 7 || isempty(pdOff)
    pdOff = [0 0 0];
end

% Photodiode rectangle (bottom left corner on Stim screen)
if nargin < 8 || isempty(pdRect)
    pdRect = [0, EXPWINsz(4)-40, 40, EXPWINsz(4)];
end


%% initialize variables

% expLoop
expLoop = 0;                                                            % continue experimental loop, until stopped by Q press

% TRIAL ended manually
movEnded = 0;                                                         % TRIAL ended manually = 1

% max duration
maxDur = 60;       % max AttGet dur
maxDurFixAll = 20; % max all Fix dur
maxDurFixEach = 5; % max each Fix dur


%% start AttGet movie

% stopwatch
t0 = tic;     % start                                                         
t1 = toc(t0); % time elapsed

% present video if less than 60 s have elapsed
while t1 < maxDur
    
    % choose movie
    if t1 < maxDurFixAll
        movStim = LoadStim(rootFix);
    else
        movStim = LoadStim(rootMov);
        movDest = [100, 100, EXPWINsz(3)-100, EXPWINsz(4)-100];
    end
    
    % set screen background to black
    Screen(EXPWIN, 'FillRect', EXPWINcol);

    % photodiode OFF
    if withPhotodiode == 1
        Screen(EXPWIN, 'FillRect', pdOff, pdRect);
    end
    
    % open TRIAL movie
    movTmp = Screen('OpenMovie', EXPWIN, movStim, 0, 1, 1); % open movie async = 0; preloadSecs = 1; specialFlags1 = 1 to load .mp4 or .m4v movies faster
    
    % start playing the TRIAL movie
    Screen('SetMovieTimeIndex', movTmp, 0);
    Screen('PlayMovie', movTmp, 1);
    tt0 = tic;
    
    % while the TRIAL movie is running, display frames
    movTex = Screen('GetMovieImage', EXPWIN, movTmp, 1);
    while movTex > 0
        Screen('DrawTexture', EXPWIN, movTex,[], movDest, 0);
        Screen('Flip',EXPWIN, [], 1);
        Screen('Close', movTex);
        movTex = Screen('GetMovieImage', EXPWIN, movTmp, 1);
        
        % check elapsed time
        tt1 = toc(tt0);
        if t1 < maxDurFixAll && tt1 > maxDurFixEach
            movTex = -1;
            Screen('PlayMovie', movTmp, 0);                                   % stop playback
            Screen('CloseMovie',movTmp);
        end
    
        % if ESC stop playback and pause TRIAL________________________________
        [~,~,keyCode] = KbCheck();
        if any(keyCode(ESC)) || any(keyCode(SPACE))
            if movTex > 0
                Screen('Close', movTex);
                movTex = -1;
                Screen('PlayMovie', movTmp, 0);
                Screen('CloseMovie', movTmp);
            end
            movEnded = 1;
            if any(keyCode(ESC))
                expLoop = 1;
            end
            break;
        end
    end
   
    if movEnded == 0
        t1 = toc(t0);
    else
        break;
    end
end

% when MaxDur reached
if expLoop == 0 && movTex > 0
    Screen('PlayMovie', movTmp, 0);                                   % stop playback
    Screen('CloseMovie',movTmp);                                      % close movie
end

if trialTest == 1
    Screen('CloseAll');
end

end

function [stimTmp] = LoadStim(root)

% defaults
if nargin < 1 || isempty(root)
    root = pwd;
    root = fullfile(root,'FlickerFaces.extra\fixation');
end

% read directory
DD = dir(root);

% count files in the directory
DDlength = 0;
for i = 1:length(DD)
    if ~strcmp(DD(i).name(1),'.')    
        DDlength = DDlength + 1;     
    end
end

% create stucture to store stimuli
stim = struct('name', cell(1, DDlength));   % field: filename

% go through the directory
count = 0;
for j = 1:length(DD)
    
    % read filename    
    largename = DD(j).name;                                          % read filename
    
    % store filename & load stimuli if file valid
    if ~(strcmp(largename(1),'.'))  
        count = count + 1;
        stim(count).name = largename;                           % store filename
    end
end
stimId = randi(count);
stimTmp = stim(stimId).name;
stimTmp = fullfile(root, stimTmp);

end
