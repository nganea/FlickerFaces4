function [stimRectBySeq, stimLocBySeq] = FlickerFaces_StimRect(nbPerifStim,...
    nbSeq, screenWidthPx, screenHeightPx, screenWidthCm, screenHeightCm,...
    stimWidthCm, stimHeightCm, eccCm, fqABBA, stimLoc)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Function for computing stimuli location on the screen.
%
% Natasa Ganea - March 2022 - natasa.ganea@gmail.com
%
% Copyright © 2022 Natasa Ganea. All Rights Reserved.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Defaults:
% - squareWaveP = 0   0 = sine wave; 1 = square wave

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Defaults

if nargin < 1 || isempty(nbPerifStim) == 1
    nbPerifStim = 0;      % 0 = central stimulus; 1 = one peripheral stimulus; 2 = two peripheral stimuli
end

if nargin < 2 || isempty(nbSeq) == 1
    nbSeq = 1;       % 1 = one sequence/trial
end

if nargin < 3 || isempty(screenWidthPx) == 1
    screenWidthPx = 640; % 640 px
end

if nargin < 4 || isempty(screenHeightPx) == 1
    screenHeightPx = 500; % 500 px
end

if nargin < 5 || isempty(screenWidthCm) == 1
    screenWidthCm = 15;   % 15 cm
end

if nargin < 6 || isempty(screenHeightCm) == 1
    screenHeightCm = 15;  % 15 cm
end

if nargin < 7 || isempty(stimWidthCm) == 1
    stimWidthCm = 2;      % 2 cm stimulus width
end

if nargin < 8 || isempty(stimHeightCm) == 1
    stimHeightCm = 2;     % 2 cm stim height
end

if nargin < 9 || isempty(eccCm) == 1
    eccCm = 5;       % 5 cm eccentricity;
elseif length(eccCm) > 2
    eccCm(:) = eccCm(1:2);      % accept 2 values, e.g., eccCm = [5,10]
end

if nargin < 10 || isempty(fqABBA) == 1
    fqABBA = 1;
end

if nargin < 11 || isempty(stimLoc) == 1
    stimLoc = [];
end

%% Initialize Variables

% eccentricity (px)
eccPx = zeros(1, length(eccCm));
for i = 1:length(eccCm)
    eccPx(i) = round(eccCm(i)*round(screenWidthPx/screenWidthCm)); % change eccentricity from Cm to Px based on screen width
end

% stimuli size (px)
stimWidthPx = round(stimWidthCm(1)*round(screenWidthPx/screenWidthCm));  % stim width
stimHeightPx = round(stimHeightCm*round(screenHeightPx/screenHeightCm)); % stim height

% calculate eccentricity for each sequence/trial
eccTmp = zeros(nbSeq,1);
for i = 1:nbSeq
    if length(eccPx) == 2 && i > nbSeq/2
        eccTmp(i,1) = eccPx(2);  % 2nd half = ecc2
    else
        eccTmp(i,1) = eccPx(1);  % 1st half = ecc1
    end
end
eccBySeq(randperm(nbSeq),1) = eccTmp(:,1); % randomize the eccentricity

% fq location (left/right) for each sequence/trial
if fqABBA == 1
    h = ceil(nbSeq/2); % half tr; account for odd nr tr
    stimLocBySeq = {'Left';'Right'};
    stimLocBySeq = repmat(stimLocBySeq,h,1); % half tr {Left, Right, Left, Right}
    stimLocBySeq = stimLocBySeq(1:nbSeq,1);  
    stimLocBySeq(randperm(length(stimLocBySeq)),1) = stimLocBySeq(:,1);% shuffle location
else
    stimLocBySeq = cell(nbSeq,1);
    stimLocBySeq(:,1) = {'Left'}; % is no Left/Right counter balance, use 'Left'
end

% if use provides stimulus location, use that one
if isempty(stimLoc) == 0    
    stimLocBySeq = stimLoc; 
end

%% Calculate Stimuli Position (px)

% initialize variables
if nbPerifStim == 2 % store info for each sequence
    stimRectBySeq = struct('nbSeq',zeros(nbSeq,1),'rect',zeros(4,2), ...
        'ecc',zeros(nbSeq,1),'loc',cell(nbSeq,1));
else
    stimRectBySeq = struct('nbSeq',zeros(nbSeq,1),'rect',zeros(1,4),...
        'ecc',zeros(nbSeq,1),'loc',cell(nbSeq,1));
end
locTmp = zeros(nbPerifStim,4);         % temporary stimuli location

% half screen size (px)
wT = round(screenWidthPx/2);   % half screen width (px)
hT = round(screenHeightPx/2);  % half screen height (px)

% stimulus size (px)
stimW = round(stimWidthPx/2);  % width (px)
stimH = round(stimHeightPx/2); % height (px)

% for each sequence/trial
for i = 1:nbSeq
    
    % eccentricity temporary
    eccT = eccBySeq(i);     % eccentricity (px)
    
    % position rectangle - left top right bottom - for each stimulus type
    if nbPerifStim == 0    % central stimulus
        stimRectBySeq(i).nbSeq = i;
        stimRectBySeq(i).rect = [wT-stimW, hT-stimH, wT+stimW, hT+stimH];
        stimRectBySeq(i).ecc = 0;
        stimRectBySeq(i).loc = {'Centre'};
        
    elseif nbPerifStim == 1  % one peripheral stimulus (left/right)
        switch stimLocBySeq{i,1}
            case 'Left'
                wTmp = wT-eccT;
            case 'Right'
                wTmp = wT+eccT;
        end
        stimRectBySeq(i).nbSeq = i;
        stimRectBySeq(i).rect = [wTmp-stimW, hT-stimH, wTmp+stimW, hT+stimH];
        stimRectBySeq(i).ecc = round(eccT/round(screenWidthPx/screenWidthCm));
        stimRectBySeq(i).loc = stimLocBySeq{i,1};
        
    elseif nbPerifStim == 2 % two pripheral stimuli
        switch stimLocBySeq{i,1}
            case 'Left' % fq = Left; fq2 = Right
                wTmp(1) = wT-eccT; % left
                wTmp(2) = wT+eccT; % right
            case 'Right' % fq = Right; fq2 = Left
                wTmp(1) = wT+eccT; % right
                wTmp(2) = wT-eccT; % left
        end
        
        % calculate position
        for ii = 1:nbPerifStim
            locTmp(ii,:) = [wTmp(ii)-stimW, hT-stimH, wTmp(ii)+stimW, hT+stimH];
        end
        stimRectBySeq(i).nbSeq = i;
        stimRectBySeq(i).rect = locTmp';
        stimRectBySeq(i).ecc = round(eccT/round(screenWidthPx/screenWidthCm));
        stimRectBySeq(i).loc = stimLocBySeq{i,1};
    end
    
end

end
