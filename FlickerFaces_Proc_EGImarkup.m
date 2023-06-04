function [TT] = FlickerFaces_Proc_EGImarkup(s, exp, minFixDur, trDur,...
    trDurJitMax, dinDiff, dinDiffJitMax, dinDiffStdMax, gazeIntDurMax)
% This function checks whether the fixations identified in the Eyelink
% Sample Report are long enough for the EEG epochs. There are 2 EEG epochs:
% CA = covert attention (2s) & OA = overt attention (2s). It outputs 2
% tables, one XLS table to keep track of excl trials and reason for
% exclusion, and one Ascii table for NetStation Markup.
%
% 2022-12-02 created by Natasa Ganea (natasa.ganea@gmail.com)

%% 0. Defaults

if nargin < 1 || isempty(s) == 1
    s = 1;                         % participant ID
end

if nargin < 2 || isempty(exp) == 1
    exp = 'FF4';                   % experiment
end

if nargin < 3 || isempty(minFixDur) == 1
    minFixDur = 2000;               % ms; min fixation duration
end

if nargin < 4 || isempty(trDur) == 1
    trDur = 7500;         % ms; trial duration (full flicker sequence)
end

if nargin < 5 || isempty(trDurJitMax) == 1
    trDurJitMax = 3;      % ms; trial duration jitter (graphics card has a +/-3 ms jitter)
end

if nargin < 6 || isempty(dinDiff) == 1
    dinDiff = 834;        % ms; flicker duration between DINs; 833.6 ms
end

if nargin < 7 || isempty(dinDiffJitMax) == 1
    dinDiffJitMax = 2;    % ms; flicker duration between DINs jitter
end

if nargin < 8 || isempty(dinDiffStdMax) == 1
    dinDiffStdMax = 2;  % max variability flicker duration between DINs
end

if nargin < 9 || isempty(gazeIntDurMax) == 1
    gazeIntDurMax = 500;  % maximum Gaze interpolation duration during EEG epoch 500 ms
end

%% 1. Filename

folderPs = sprintf('%s_%d', exp, s);
folderData = fullfile(pwd, 'FlickerFaces.data', folderPs);

fileInDiag = sprintf('%s_%d_Diag.csv', exp, s);
fileInDiag = fullfile(folderData, fileInDiag);

fileInGazeInt = sprintf('%s_%d_GazeInt_%d.csv', exp, s, minFixDur);
fileInGazeInt = fullfile(folderData, fileInGazeInt);

fileInFixAll = sprintf('%s_%d_FixAll_%d.csv', exp, s, minFixDur);
fileInFixAll = fullfile(folderData, fileInFixAll);

fileOutMarkupXLS = sprintf('%s_%d_MarkupXLS_%d.xlsx', exp, s, minFixDur);
fileOutMarkupXLS = fullfile(folderData, fileOutMarkupXLS);

fileOutMarkupAscii = sprintf('%s_%d_Markup_%d.txt', exp, s, minFixDur);
fileOutMarkupAscii = fullfile(folderData, fileOutMarkupAscii);

%% 2. Import Data

% EEG data
fileInDiag = readtable(fileInDiag,'PreserveVariableNames',true);   % read comma delimited file
trTrig = table2array(fileInDiag(:,'trTrig'));            % trial EEG trigger
dinTrDur = table2array(fileInDiag(:,'dinTrDur'));        % trial duration based on PD trig
dinDiffMean = table2array(fileInDiag(:,'dinDiffMean'));  % trial duration based on PD trig
dinDiffStd = table2array(fileInDiag(:,'dinDiffStd'));    % std PT trig during tr (excl if std > 1.5)
dinStimOnset = table2array(fileInDiag(:,'dinStimOnset'));% timestamp STIM_ONSET based on PD DIN1
eTimeDIN2sta = table2array(fileInDiag(:,'eTimeDIN2'));   % timestamp PD DIN2; CA EEG epoch start
eTimeDIN2end = eTimeDIN2sta(:,1) + minFixDur;            % timestamp CA EEG epoch end (after 2000 ms)
eTimeDIN6sta = table2array(fileInDiag(:,'eTimeDIN6'));   % timestamp PD DIN6; OA EEG epoch start
eTimeDIN6end = eTimeDIN6sta(:,1) + minFixDur;            % timestamp OA EEG epoch end (after 2000 ms)
keypressMiss = table2array(fileInDiag(:,'keypressMiss'));% is participat failed to press key when detecting movement 2x

% ET gaze interpolation data
fileInGazeInt = readtable(fileInGazeInt,'PreserveVariableNames',true); % read comma delimited file
gazeIntDurCA = table2array(fileInGazeInt(:,'intDurCA_Ms'));   % gaze interp dur covert attention EEG epoch
gazeIntDurOA = table2array(fileInGazeInt(:,'intDurOA_Ms'));   % gaze interp dur overt attention EEG epoch

% ET fixation data
fileInFixAll = readtable(fileInFixAll,'PreserveVariableNames',true); % read comma delimited file
tr = table2array(fileInFixAll(:,'tr'));                     % trial
rAOI = table2array(fileInFixAll(:,'rAOI'));                 % AOI right eye (1 = cloud; 2 = fq1; 3 = fq2)
eTimeFixSta = table2array(fileInFixAll(:,'eTimeFixSta'));   % elapsed time from tr start when fix start
eTimeFixEnd = table2array(fileInFixAll(:,'eTimeFixEnd'));   % elapsed time from tr start when fix end

%% 3. Fix covers EEG segment?

% for each fixation
eegTr = zeros(length(rAOI),1);       % store EEG tr
eegEpTr = zeros(length(rAOI),1);     % store EEG epoch tr
eegEpTrig = strings(length(rAOI),1); % store EEG epoch trig
eegEpSta = zeros(length(rAOI),1);    % store EEG epoch start time
exclCAorOA = zeros(length(rAOI),1);  % store EEG epoch excl reason
e = 0;
ff = 0;

% check whether fix started before epoch and ended after epoch -  DIN2 and DIN6 used for EEG epoch
for f = 1:length(rAOI)
    
    % do this for trials with fixations
    if tr(f,1) > 0
        
        % if a new trial
        if f == 1 || (f > 1 && (tr(f,1) ~= tr(f-1,1)))
            
            % tr info
            t = tr(f,1);                  % tr number
            trig = char(trTrig(t));       % EEG tr trig
            
            % CA & OA EEG epoch trigger & start time (rAOI; 2 = fq1; 3 = fq2)
            if rAOI(f,1) > 1
                
                % fix covers CA EEG epoch
                ff = ff + 1; % count
                if (eTimeFixSta(f,1) <= eTimeDIN2sta(t,1)) &&...
                        (eTimeFixEnd(f,1) >= eTimeDIN2end(t,1))
                    
                    eegEpTrig(ff,1) = strcat('C',trig(2:end)); % trig
                    eegEpSta(ff,1) = dinStimOnset(t,1) + eTimeDIN2sta(t,1);  % start time
                    
                else
                    eegEpSta(ff,1) = NaN;      % no CA EEG epoch
                    exclCAorOA(ff,1) = 1;      % excl because no fix for CA EEG epoch
                end
                
                % fix covers OA EEG epoch
                ff = ff + 1; % count
                if (eTimeFixSta(f,1) <= eTimeDIN6sta(t,1)) &&...
                        (eTimeFixEnd(f,1) >= eTimeDIN6end(t,1))
                    
                    eegEpTrig(ff,1) = strcat('O',trig(2:end)); % trig
                    eegEpSta(ff,1) = dinStimOnset(t,1) + eTimeDIN6sta(t,1);    % start time
                    
                    % fix doesn't cover CA EEG epoch, fix covers only OA EEG epoch
                    if isnan(eegEpSta(ff-1,1))
                        eegEpSta(ff,1) = NaN;   % no CA EEG epoch, no OA EEG epoch either
                        exclCAorOA(ff,1) = 1;   % excl because no CA EEG epoch
                    end
                    
                % 2 fix per trial covers the OA EEG epoch
                elseif tr(f,1) == tr(f+1,1) &&...
                        (eTimeFixSta(f+1,1) <= eTimeDIN6sta(t,1)) &&...
                        (eTimeFixEnd(f+1,1) >= eTimeDIN6end(t,1))
                    
                    eegEpTrig(ff,1) = strcat('O',trig(2:end)); % trig
                    eegEpSta(ff,1) = dinStimOnset(t,1) + eTimeDIN6sta(t,1);    % start time
                    
                    % fix doesn't cover CA EEG epoch, fix covers only OA EEG epoch
                    if isnan(eegEpSta(ff-1,1))
                        eegEpSta(ff,1) = NaN;   % no CA EEG epoch, no OA EEG epoch either
                        exclCAorOA(ff,1) = 1;   % excl because no CA EEG epoch
                    end
                
                % no fix per trial covers OA EEG epoch
                else
                    eegEpSta(ff,1) = NaN;
                    exclCAorOA(ff,1) = 2;   % excl because no CA EEG epoch
                    
                    % if no OA EEG epoch, no CA EEG epoch either
                    if isnan(eegEpSta(ff,1))
                        eegEpSta(ff-1,1) = NaN;  % no OA EEG epoch, no CA EEG epoch either
                        exclCAorOA(ff-1,1) = 2;  % excl because no OA EEG epoch
                    end
                end
            end
            
            % EEG tr number
            if mod(ff,2) == 0
                eegTr(ff-1,1) = t;   % store trial number (CA epoch)
                eegTr(ff,1) = t;     % store trial number (OA epoch)
            end
            
            % EEG epoch tr number
            if isnan(eegEpSta(ff,1))
                eegEpTr(ff,1) = NaN;
                if eegEpTr(ff-1,1) == 0
                    eegEpTr(ff-1,1) = NaN;
                end
            else
                if ff > 1 && ~isnan(eegEpSta(ff-1,1))
                    e = e+1;
                    eegEpTr(ff,1) = e;
                    eegEpTr(ff-1,1) = e;
                end
            end
        end
    end
end

%% 4. Excl tr based on DIN diag

exclDinDiag = zeros(length(eegTr),1); % store EEG epoch excl reason
for i = 1:length(dinTrDur)
    
    % trial jitter
    trDurJit = sqrt((dinTrDur(i,1)-trDur)^2);        % jitter trial duration
    dinDiffJit = sqrt((dinDiffMean(i,1)-dinDiff)^2); % jitter din diff within trial
    
    % mark trials for exclusion
    if trDurJit > trDurJitMax || dinDiffJit > dinDiffJitMax ||...
            dinDiffStd(i,1) > dinDiffStdMax
        excl = find(eegTr == i);
        if ~isempty(excl)
            for e = 1:length(excl)
                exclDinDiag(excl(e),1) = 1;            % mark for excl
                eegEpSta(excl(e),1) = NaN;             % excl tr start time
                eegEpTr(excl(e),1) = NaN;              % excl tr
            end
        end
    end
end

%% 5. Excl tr based on GAZE interp dur

exclGazeIntDur = zeros(length(eegTr),1); % store EEG epoch excl reason
for i = 1:length(gazeIntDurCA)
    
    % mark trials for exclusion
    if gazeIntDurCA(i,1) > gazeIntDurMax || gazeIntDurOA(i,1) > gazeIntDurMax
        excl = find(eegTr == i);
        if ~isempty(excl)
            for e = 1:length(excl) 
                if gazeIntDurCA(i,1) > gazeIntDurMax
                    exclGazeIntDur(excl(e),1) = 1;         % mark for excl CA EEG epoch
                elseif gazeIntDurOA(i,1) > gazeIntDurMax
                    exclGazeIntDur(excl(e),1) = 2;         % mark for excl OA EEG epoch
                end
                eegEpSta(excl(e),1) = NaN;             % excl tr start time
                eegEpTr(excl(e),1) = NaN;              % excl tr
            end
        end
    end
end

%% 6. Excl tr based on keypressMiss

exclKeypressMiss = zeros(length(eegTr),1); % store EEG epoch excl reason
for i = 1:length(keypressMiss)
    
    % mark trials for exclusion
    if keypressMiss(i,1) > 0
        excl = find(eegTr == i);
        if ~isempty(excl)
            for e = 1:length(excl) 
                exclKeypressMiss(excl(e),1) = 1;       % mark for excl CA EEG epoch
                eegEpSta(excl(e),1) = NaN;             % excl tr start time
                eegEpTr(excl(e),1) = NaN;              % excl tr
            end
        end
    end
end

%% 7. Recount number of EEG epochs
e = 0;
for i = 1:length(eegEpTr)
    if i > 1 && eegEpTr(i,1) > 0 && eegEpTr(i,1) == eegEpTr(i-1,1)
        e = e + 1;
        eegEpTr(i,1) = e;
        eegEpTr(i-1,1) = e;
    end
end

% delete empty rows
for i = length(eegTr):-1:1
    if eegTr(i,1) == 0
        eegTr(i,:) = [];
        eegEpTr(i,:) = [];
        eegEpSta(i,:) = [];
        eegEpTrig(i,:) = [];
        exclCAorOA(i,:) = [];
        exclDinDiag(i,:) = [];
        exclGazeIntDur(i,:) = [];
        exclKeypressMiss(i,:) = [];
    end
end

%% 8. Save Markup file

% XLS file
TT = table(eegTr, eegEpTr, eegEpSta, eegEpTrig, exclCAorOA, exclDinDiag,...
    exclGazeIntDur, exclKeypressMiss);
TT.Properties.VariableNames = {'Tr', 'evtTr', 'evtTime', 'evtCode', ...
    'exclCAorOA', 'exclDinDiag', 'exclGazeIntDur', 'exclKeypressMiss'};
writetable(TT, fileOutMarkupXLS);

% clean NaN rows
for i = length(eegEpSta):-1:1
    if isnan(eegEpSta(i,1)) || eegEpSta(i,1) == 0
        eegEpSta(i) = [];
        eegEpTrig(i) = [];
    end
end

% Ascii file for NetStation
TT = [eegEpSta, eegEpTrig];
writematrix(TT, fileOutMarkupAscii, 'Delimiter', 'tab');

end