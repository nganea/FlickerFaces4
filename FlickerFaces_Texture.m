function [stimT] = FlickerFaces_Texture(w,stimT,greyScale)

if nargin < 1 || isempty(w) == 1
    Screen('Preference', 'SkipSyncTests', 1);
    screens = Screen('Screens'); % screens = 0 (one display); screens = [0, 1, 2] (two displays)
    screenNum = max(screens);    % max(screens) = 2
    [width, height] = Screen('WindowSize', screenNum); % Screen 2 dimensions
    % Open a PTB window on Screen 2
    if screenNum > 0
        [w] = Screen('OpenWindow', screenNum-1, 0, [0 0 width height]);
    else
        [w] = Screen('OpenWindow', screenNum, 0, [0 0 width height]);
    end
end

if nargin < 2 || isempty(stimT)
    rootStim = fullfile(pwd, 'FlickerFaces.stim');
    stimT = FlickerFaces_LoadStim(fullfile(rootStim, 'Cloud'));
end

if nargin < 3 || isempty(greyScale)
    greyScale = 0; % added 2023-08-10 to make grey images
end

nbStimT = size(stimT);
nbStimT = nbStimT(2);
for ii = 1:nbStimT
    stimTmp = stimT(ii).stim;
    % added 2023-08-10 to make grey transparent images
    if greyScale == 1
        stimTmp(:,:,2) = stimTmp(:,:,1);
        stimTmp(:,:,3) = stimTmp(:,:,1);
    end
    stimTmp(:,:,4) = stimT(ii).alpha;
    stimT(ii).tex = Screen('MakeTexture', w, stimTmp);
end

end