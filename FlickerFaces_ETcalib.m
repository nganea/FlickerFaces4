% FlickerFaces_ETcalib 

% clea workspace
clearvars;

% initialize variables
withETrecording = 1;
test = 0;
exp = 'ETca';
SsID = '99';
root = pwd;

% Screen colours
fore = [0 0 0]; % stimuli color (foreground) if written stimuli
back = [128 128 128]; % background color; [128 128 128] = grey

%% PSYCHTOOLBOX PARAMETERS
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
    [w, wrect] = Screen('OpenWindow', screenNum-1, 0, [0 0 width height]);
else
    [w, wrect] = Screen('OpenWindow', screenNum, 0, [0 0 width height]);
end

% Info about the PTB window
[mx,my] = RectCenter(wrect); % centre of the window
Priority(MaxPriority(w));  % make PTB window max priority
Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % set colors properly
cycleRefresh = Screen('GetFlipInterval', w); % get duration of refresh cycle

% initialize ET
if withETrecording == 1
    Eyelink_Initialize;
end

% show AttGet video
FlickerFaces_AttGet(w, wrect);

% disconnect ET
if withETrecording == 1
    Eyelink_Disconnect;
end
 
ShowCursor;
cd(root);
Screen('CloseAll');
clearvars;