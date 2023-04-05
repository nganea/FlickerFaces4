function [statusEEG, errorEEG, vbl, Wsot, ft, m] = HaskinsEEG_TimingTest(EXPWIN_in, Bdur_in, Wdur_in)

KbName('UnifyKeyNames');    % keyboard mapping same on all supported operating systems
ESC = KbName('escape');     % exit experiment

% colour index
black = [0, 0, 0];
white = [255, 255, 255];

%% function inputs

% if EXPWIN window is omitted or empty
if nargin < 1 || isempty(EXPWIN_in)
    Screen('Preference','SkipSyncTests',0);
    screens = Screen('Screens');
    screenNum = max(screens);
    % PsychDebugWindowConfiguration(0,0.5);
    [w, wSz] = Screen('OpenWindow', screenNum);
    Screen('FillRect', w, black);
    Screen('Flip', w, [], 1);
end

% if BlackDuration is omitted or empty
if nargin < 2 || isempty(Bdur_in)
    Bdur = 1.5;
else
    Bdur = Bdur_in;
end

% if WhiteDuration is omitted or empty
if nargin < 3 || isempty(Wdur_in)
    Wdur = 1.5;
else
    Wdur = Wdur_in;
end

%% EGI Timing Test

%%% Connect to NetStation
withEEGrecording = 1;
if withEEGrecording == 1
    [statusEEG, errorEEG] =  NetStation('Connect', '10.10.10.51', '55513');
    NetStation('Synchronize');
    NetStation('StartRecording');
    WaitSecs(0.1);
end

% max duration
maxDur = 120;       % max Timing Test dur (seconds)
vbl = 0;

% stopwatch
t0 = tic;     % start
t1 = toc(t0); % time elapsed

% stwiich screen colour black/white for 120 s
while t1 < maxDur
    
    % screen background black
    Screen(w, 'FillRect', black, wSz);
    [vbl, Bsot] = Screen('Flip', w, vbl + Wdur);
    
    % screen background white
    Screen(w, 'FillRect', white, wSz);
    [vbl, Wsot, ft, m] = Screen('Flip', w, vbl + Bdur);
    
    % NetStation trigger
    NetStation('Event', 'whit', Wsot, Wsot - Bsot);
    
    % if ESC stop
    [~,~,keyCode] = KbCheck();
    if any(keyCode(ESC))
        break;
    else
        t1 = toc(t0);
    end
    
end

if withEEGrecording == 1
    NetStation('StopRecording');
    NetStation('Disconnect');
end
Screen('CloseAll');

end


