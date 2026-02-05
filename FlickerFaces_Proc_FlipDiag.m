function [TT] = FlickerFaces_Proc_FlipDiag(s, exp, nbDinPerTr, DIN2, DIN6)
% This function calculates the interval between the DIN triggers in each tr.
% It also calculate the trial duration based on photodiode DIN triggers and
% PTB Screen('Flip',w) info. It saves everything into a summary table.
%
% 2022-11-23 created by Natasa Ganea (natasa.ganea@gmail.com)

%% Defaults

if nargin < 1 || isempty(s) == 1
    s = 1;                          % participant ID
end

if nargin < 2 || isempty(exp) == 1
    exp = 'FF4';                    % experiment name
end

if nargin < 3 || isempty(nbDinPerTr) == 1
    nbDinPerTr = 10;                % number of DINs per trial;
end

if nargin < 4 || isempty(DIN2) == 1
    DIN2 = 2;                       % Covert Att ep = 2 sec;
end

if nargin < 5 || isempty(DIN6) == 1
    DIN6 = 6;                       % Overt Att ep = 2 sec;
end
%% Initialize

% folder data files
folderPs = sprintf('%s_%d', exp, s);
rootData = fullfile(pwd, 'FlickerFaces.data', folderPs);

% filenames
fileInMat = sprintf('%s_%d.mat', exp, s);
fileInMat = fullfile(rootData, fileInMat);
fileInEvt = sprintf('%s_%d_Evt.csv', exp, s);
fileInEvt = fullfile(rootData, fileInEvt);
fileOutDiag = sprintf('%s_%d_Diag.csv', exp, s);
fileOutDiag = fullfile(rootData, fileOutDiag);

% load PTB Screen('Flip') timestamps
load(fileInMat,'dDiag');

% load totalPress to identify trial without keypress
load(fileInMat, 'totalPress');

%% Screen Flip Diag

% init vars
flipMissNbCy = zeros(length(dDiag),1);
flipDurNbCy = zeros(length(dDiag),1);
keypressMiss = zeros(length(dDiag),1);

% for each tr, check the Screen('Flip') timestamps
for i = 1:length(dDiag)
    d = dDiag(i).d;
    flipTy = dDiag(i).flipTy;
    dd = 0;
    ddd = 0;
    
    % for each refresh cycle
    for ii = 1:length(d)
        
        % do this only for completed/attempted trials
        if ~isempty(flipTy)
            
            % missed flips
            if d(ii,4) > 0
                dd = dd + 1;
            end
            
            % check whether current refresh cycle has a timestamp
            if ii > 2 && d(ii,2) > 0 && d(ii-1,2) > 0
                flipTimeRec = 1;
            else
                flipTimeRec = 0;
            end
            
            % flip duration
            if flipTimeRec == 1
                flipDurTmp = d(ii,1)-d(ii-1,1);
                flipDurTmp = round(flipDurTmp,3);
                if flipDurTmp > 0.017
                    ddd = ddd + 1;  % store cy if flip duration more than 17 ms
                end
            end
        end
    end
    
    % store nb of problematic refresh cycles per tr
    flipMissNbCy(i,1) = dd;
    flipDurNbCy(i,1) = ddd;
    
    % store if no keypress recorded per tr
    if sum(totalPress(i,1:2)) ~= 2
        keypressMiss(i,1) = 1;
    end
end

%% EEG Photodiode Diag

% read EEG Photodiode timestamps
T = readtable(fileInEvt,'TextType','string');
T = renamevars(T,["mff","Var5","Var7","Var8","Var10"],... % old name
    ["evtName","evtTime","evtTy","evtNb","fqTy"]);        % new name
evtName = T.evtName;     % event name
evtTimeStr = T.evtTime;  % timestamp of event
evtNb = T.evtNb;         % event number (trial number or Photodiode DIN number)
fqTy = T.fqTy;           % flicker frequency type (0 = 2 freq; 1 = fq1; 2 = fq2)

% timestamp change str >> ms
evtTimeMs = zeros(length(evtTimeStr),1);
for i = 1:length(evtTimeStr)
    t = char(evtTimeStr(i,1));
    evtTimeMs(i,1) = milliseconds(duration(t(2:13)));
end

% calculate time interval between photodiode triggers (between DINs)
t = 0;                              % tr count; start from 0
trTrig = strings(length(dDiag),1);  % tr Matlab trigger ('s1Lf')
trNb = zeros(length(dDiag),1);      % tr number
trFqTy = zeros(length(dDiag),1);    % tr flicker frequency (0 = both freq; 1 = fq1; 2 = fq2)
trDur = zeros(length(dDiag),1);     % tr dur
eTimeDIN2 = zeros(length(dDiag),1); % elapsed time since trial start to DIN2
eTimeDIN6 = zeros(length(dDiag),1); % elapsed time since trial start to DIN6
dif = zeros(nbDinPerTr,1);          % store time difference between DINs in one trial
dinDiffMean = zeros(length(dDiag),1);   % store mean time difference between DINs in one trial
dinDiffStd = zeros(length(dDiag),1);    % store std time differebce between DINs in one trial
dinStimOnset = zeros(length(dDiag),1);  % stim onset as marked by Photodiode DIN (relative time from beginning of EEG session; see EventExport Tool in NetStation)
dinTrigOffset = zeros(length(dDiag),1); % offset Matlab trigger & Photodiode DIN (Haskins EEG: 29 ms)

% for each event in the EEG event list
for i = 1:length(evtName)
    
    % get event name
    e = char(evtName(i,1));
    
    % if Matlab event
    if strcmp(e(1),'s') == 1
        
        % reset values (needed later in the tr)
        t = t + 1;       % increase tr nb
        d = 0;           % reset DIN nb
        dif(:,1) = 0;    % reset diff between event timestamps
        
        % store trigger time, name, & trial number
        trSta = evtTimeMs(i,1);
        trTrig(t,1) = e;
        trNb(t,1) = evtNb(i,1);
        trFqTy(t,1) = fqTy(i,1);
        
    % if Photodiode event (DIN)
    elseif strcmp(e(1),'D') == 1
        
        % reset values (needed later in the tr)
        d = d + 1;        % increase DIN nb
        
        % 1st DIN since trial start (=stim appears on screen)
        if d == 1
            
            % offset Matlab trigger & DIN trigger
            stimSta = evtTimeMs(i,1);           % DIN marking STIM_ONSET timestamp
            dinStimOnset(t,1) = evtTimeMs(i,1); % store STIM_ONSET timestamp
            dinTrigOffset(t,1) = stimSta-trSta; % offset Matlab trigger & DIN trigger
            
        % later DIN
        else
            
            % tr dur based on DIN diff
            stimEnd = evtTimeMs(i,1);           % DIN during the tr
            trDur(t,1) = stimEnd-stimSta;       % tr dur or stim dur based on DIN nb
            
            % store tr dur for DIN2 and DIN6 need for EEG epochs
            if d == DIN2                        % d == 2, 667 ms; d == 3, 333 ms
                eTimeDIN2(t,1) = trDur(t,1);
            elseif d == DIN6                    % d == 7, 667 ms; d == 13, 333 ms
                eTimeDIN6(t,1) = trDur(t,1);
            end
            
            % average DIN diff during the tr
            dif(d,1) = evtTimeMs(i,1)-evtTimeMs(i-1,1); % DIN diff relative to previous DIN
            dinDiffMean(t,1) = mean(dif(2:d-1,1));      % mean DIN diff within tr
            dinDiffStd(t,1) = std(dif(2:d-1,1));        % st dev DIN diff within tr
            
        end
    end
end

%% Summary Table

TT = table(trNb, flipMissNbCy, flipDurNbCy,...
    trDur, dinDiffMean, dinDiffStd, dinTrigOffset, trTrig, trFqTy,...
    dinStimOnset, eTimeDIN2, eTimeDIN6, keypressMiss);
TT = renamevars(TT, ["flipMissNbCy","flipDurNbCy","trDur"],...          % old name
    ["ptbMissedFlips","ptbFlipsOver17ms","dinTrDur"]);  % new name
writetable(TT, fileOutDiag);

end
