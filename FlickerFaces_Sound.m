function [soundEnded, expLoop] = FlickerFaces_Sound(soundDurMax_in, soundFolder_in)

% Function that presents the Attention movies for avGender study. 
%
% General syntax
% [attentionEndedByUser, experimentLoop] = FlickerFaces_Sound([soundFolder_in]
%   [,soundFreq_in][,soundDurationMax])
%
% Defaults: 
%           1) soundFolder = 'experimentsMATLAB/common/movies/fixatMov.avi'
%           2) soundFreq = sound frequency 48000;
%           3) soundDur = 300 ms;
% 
% Sound plays until the end of the sound, or keypress.
%   
% Key controls: SPACE or ESC to exit the function
%
% =======================
% Created by Natasa Ganea, Haskins Labs, May 2022 (natasa.ganea@gmail.com)
%
% Copyright © 2022 Natasa Ganea. All Rights Reserved.
% =======================

%% keycodes

KbName('UnifyKeyNames');                                                % keyboard mapping same on all supported operating systems
ESC = KbName('escape');                                                 % pause experiment
SPACE = KbName('space');                                                % move on

%% defaults
 
% if no maximum Attention duration given, use 1s
if nargin < 1 || isempty(soundDurMax_in)
    soundDurMax = 1;                                                      
else
    soundDurMax = soundDurMax_in;
end

% if no attention stimulus given, use default
if nargin < 2 || isempty(soundFolder_in)
    root = pwd;
    rootExtra = fullfile(root,'FlickerFaces.extra');
else
    rootExtra = soundFolder_in;
end
rootSound = fullfile(rootExtra,'soundsExtra');

%% play Sound

% random sound
soundStim = LoadStim(rootSound);
[sound, soundFreq] = audioread(soundStim);

% intialize variables
soundEnded = 0;
expLoop = 0;

% Initialize Sound driver
InitializePsychSound;

% Open Psych-Audio port, 2 = stereo
pahandle = PsychPortAudio('Open', [], [], 0, soundFreq, 2);

% Set the volume to default
PsychPortAudio('Volume', pahandle, []);

% Fill the audio playback buffer with the audio data
PsychPortAudio('FillBuffer', pahandle, sound');

% Start audio playback; repeat until stopped
PsychPortAudio('Start', pahandle, 0, 0, 1);

% stopwatch
t0 = tic;     % start                                                         
t1 = toc(t0); % time elapsed

while t1 < soundDurMax
    
    % if ESC stop playback________________________________
    [~,~,keyCode] = KbCheck();
    if any(keyCode(ESC)) || any(keyCode(SPACE))
        soundEnded = 1;
        if any(keyCode(ESC))
            expLoop = 1;
        end
        break;
    end
    
    if soundEnded == 0
        t1 = toc(t0);
    else
        break;
    end
        
end

% Stop playback 
PsychPortAudio('Stop', pahandle);

% Close the audio device
PsychPortAudio('Close', pahandle);

end


function [stimTmp] = LoadStim(root)

% defaults
if nargin < 1 || isempty(root)
    root = pwd;
    root = fullfile(root,'FlickerFaces.extra\soundsExtra');
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
stimTmp = fullfile(root,stimTmp);

end
