function [TT, err] = FlickerFaces_Proc_GazeData(s, exp, maxBlinkDur, ...
    minFixDur, maxNbTr, caStaMs, caEndMs, oaStaMs, oaEndMs)
% This function interpolates blinks and identifies fixations in the Eyelink
% Sample Report. It outputs a table with all the fixations, their duration, start
% time, end time andelapsed time since trial start.
%
% 2022-12-02 created by Natasa Ganea (natasa.ganea@gmail.com)

%% 0. Defaults

if nargin < 1 || isempty(s) == 1
    s = 1;           % participant ID
end

if nargin < 2 || isempty(exp) == 1
    exp = 'FF4';     % experiment name
end

if nargin < 3 || isempty(maxBlinkDur) == 1
    maxBlinkDur = 300;    % ms; max blink dur to interp = 300 ms (see Holmqvist et al, 2011, p. 324)
end

if nargin < 4 || isempty(minFixDur) == 1
    minFixDur = 2000;     % ms; minimum fixation duration 2000 ms (EEG epoch)
end

if nargin < 5 || isempty(maxNbTr) == 1
    maxNbTr = 40;        % max number of trials
end

if nargin < 6 || isempty(caStaMs) == 1
    caStaMs = 834;       % covert attention EEG epoch start
end

if nargin < 7 || isempty(caEndMs) == 1
    caEndMs = 2834;       % covert attention EEG epoch end
end

if nargin < 8 || isempty(oaStaMs) == 1
    oaStaMs = 4167;       % overt attention EEG epoch start
end

if nargin < 9 || isempty(oaEndMs) == 1
    oaEndMs = 6167;       % overt attention EEG Epoch end
end

%% 1. Filename

folderPs = sprintf('%s_%d', exp, s);
folderData = fullfile(pwd, 'FlickerFaces.data', folderPs);
folderEToutput = ('Output');

fileInGaze = sprintf('%s_%d_GAZE.xls', exp, s);
fileInGaze = fullfile(folderData, folderPs, folderEToutput, fileInGaze);

fileOutGazeInt = sprintf('%s_%d_GazeInt_%d.csv', exp, s, minFixDur);
fileOutGazeInt = fullfile(folderData, fileOutGazeInt);

fileOutFixAll = sprintf('%s_%d_FixAll_%d.csv', exp, s, minFixDur);
fileOutFixAll = fullfile(folderData, fileOutFixAll);

%% 2. Import GAZE Data

% import data
fileInGaze = struct2table(tdfread(fileInGaze)); % read tab delimited file

% read values
tr = table2array(fileInGaze(:,'TRIAL_INDEX'));         % tr
rBlink = table2array(fileInGaze(:,'RIGHT_IN_BLINK'));  % right eye in blink (1 = blink; 0 = fixat)
rSacc = table2array(fileInGaze(:,'RIGHT_IN_SACCADE')); % right eye in sacc (1 = sacc; 0 = fixat)
timestamp = table2array(fileInGaze(:,'TIMESTAMP'));    % timestamp sample

% configure NaN values in RIGHT_INTEREST_AREA_ID
rAOI_tmp = table2array(fileInGaze(:,'RIGHT_INTEREST_AREA_ID'));   % right eye interest area (. = empty; 1 = cloud; 2 = fq1; 3 = fq2)
rAOI = zeros(height(fileInGaze),1);
for i = 1:length(rAOI_tmp)
    if strcmp('.',rAOI_tmp(i,1))
        rAOI(i,1) = NaN;
    else
        rAOI(i,1) = str2double(rAOI_tmp(i,1));
    end
end
clear rAOI_tmp;

%% 3. Interpolate Blinks GAZE Data

b = 0;                          % count number of consecutive NaN values in rAOI
rAOI_interp = rAOI;             % var with interpolated blinks

% store interpolation info
gazeInt = zeros(maxNbTr,5);  % store GAZE interpolation info for each trial
gazeInt(:,1) = 1:maxNbTr;    % fill in trial number
intNum = 0;    % number of inetrpolations per trial
intDur = 0;    % total interpolation duration per trial
intDurCA = 0;  % interpolation duration during the CA EEG epoch
intDurOA = 0;  % interpolation duration during the OA EEG epoch

for i = 1:length(rAOI)
    
    % EEG epoch start and end - sample number
    if i == 1 || (i > 1 && tr(i) ~= tr(i-1))
        caSta = i + floor(caStaMs/2);  % covert attention start
        caEnd = i + ceil(caEndMs/2);   % covert attention end
        oaSta = i + floor(oaStaMs/2);  % overt attention start
        oaEnd = i + ceil(oaEndMs/2);   % overt attention end
    end
    
    % NaN value in rAOI
    if i > 1 && isnan(rAOI(i)) && (rBlink(i) == 1 || rSacc(i) == 1)
        b = b + 1;                       % count number of consecutive NaN
        if b == 1
            bSta = i;                    % identify when the blink started
            aoiBeforeBlink = rAOI(i-1);  % store the AOI fixated before the blink
            trBeforeBlink = tr(i-1);     % trial number
        end
        
        % value in rAOI
    elseif ~isnan(rAOI(i))
        if b > 0                         % if a NaN in the previous sample
            bEnd = i-1;                  % get index of last NaN value
            aoiAfterBlink = rAOI(i);     % store the AOI fixated on this sample
            trAfterBlink = tr(i);        % store trial number
            
            % if same trial & same AOI
            if trBeforeBlink == trAfterBlink && aoiBeforeBlink == aoiAfterBlink
                if b < maxBlinkDur/2                     % NaN samples < 1/2 blinkDuration (ET = 500Hz;ETsample=2ms)
                    
                    % total interp dur this trail
                    intDur = intDur + b*2;               % interpolation dur per trial
                    
                    % if total interp dur during trial less than minFixDur
                    if intDur < minFixDur
                        
                        % interpolate blink values
                        rAOI_interp(bSta:bEnd,1) = aoiBeforeBlink;
                        
                        % interp dur CA EEG epoch
                        if bSta > caSta && bEnd < caEnd
                            intDurCA = intDurCA + (bEnd-bSta+1)*2;
                        elseif bSta > caSta && bSta < caEnd && ...
                                bEnd > caEnd && bEnd < oaSta
                            intDurCA = intDurCA + (caEnd-bSta+1)*2;
                        elseif bSta < caSta && bEnd > caSta && bEnd < caEnd
                            intDurCA = intDurCA + (caSta-bEnd+1)*2;
                        end
                        
                        % interp dur OA EEG epoch
                        if bSta > oaSta && bEnd < oaEnd
                            intDurOA = intDurOA + (bEnd-bSta+1)*2;
                        elseif bSta > oaSta && bSta < oaEnd && bEnd > oaEnd
                            intDurOA = intDurOA + (oaEnd-bSta+1)*2;
                        elseif bSta > caEnd && bSta < oaSta &&...
                                bEnd > oaSta && bEnd < oaEnd
                            intDurOA = intDurOA + (caSta-bEnd+1)*2;
                        end                
                        
                        % store intrpolation info
                        intNum = intNum + 1;                              % number interpolations per trial
                        gazeInt(trBeforeBlink,1) = trBeforeBlink;         % trial
                        gazeInt(trBeforeBlink,2) = intNum;                % number of inetrpolations
                        gazeInt(trBeforeBlink,3) = intDur;                % total interpolation duration
                        gazeInt(trBeforeBlink,4) = intDurCA;              % interpolation duration CA EEG epoch
                        gazeInt(trBeforeBlink,5) = intDurOA;              % interpolation duration OA EEG epoch
                        
                    end
                end
            else
                intNum = 0;
                intDur = 0;
                intDurCA = 0;
                intDurOA = 0;
            end
            
            % reset count of consecutive NaN
            b = 0;
        end
    end
end

%% 4. Find Fixations GAZE Data

% intialize vars
minFixDurSample = minFixDur/2; % 2 ms per sample
fixAll = zeros(maxNbTr*2,8);     % ps can make up to 2 fix per trial (tr has 6s, fix has 2s)

% for the entire GAZE file, find fix
t = 0; % trial count
f = 0; % fixation count
for s = 1:length(tr)
    
    % if new trial, reset fixDur & trStaTime
    if s == 1 || tr(s,1) ~= tr(s-1,1)
        newTr = 1;                                % new trial
        trStaTime = timestamp(s,1);               % trial start time = ET sample timestamp
        t = t+1;                                  % count tr
        fixDur = 0;                               % fix duration
        storeData = 0;
    else
        newTr = 0;   % same trial
    end
    
    % same trial & same AOI on 2 consecutive samples
    if newTr == 0
        if rAOI_interp(s,1) == rAOI_interp(s-1,1)
            
            % fix start or fix cont?
            if fixDur == 0
                fixDur = 2;                    % fixDur = 2 because 2 consecutive samples in same AOI
                fixStaTime = timestamp(s-1,1); % fix start timestamp ET
            else
                fixDur = fixDur + 1;           % increase fixDur
            end
            
            % store fix data?
            if s < length(tr) && tr(s,1) ~= tr(s+1,1)
                storeData = 1;                        % trial end, store data
            elseif s == length(tr)
                storeData = 1;                        % GAZE file end, store data
            end
            
        else
            storeData = 1;   % fix end, store data
        end
    end
    
    % store data requested
    if storeData == 1
        
        % min fix dur criterion
        if fixDur >= minFixDurSample
            
            % end fix
            if s == length(timestamp)
                fixEndTime = timestamp(s,1) + 2;  % fix end time; add last sample (2 ms), if end of the GAZE file
            else
                fixEndTime = timestamp(s,1);      % fix end time
            end
            
            % store fix info
            f = f + 1;                        % fix count
            fixAll(f,1) = t;                  % tr
            fixAll(f,2) = trStaTime;          % tr start ET timestamp
            fixAll(f,3) = fixDur*2;           % fix dur
            fixAll(f,4) = fixStaTime;         % fix start ET timestamp
            fixAll(f,5) = fixEndTime;         % fix end ET timestamp
            fixAll(f,6) = rAOI_interp(s-1,1); % 1 = cloud; 2 = fq1; 3 = fq2
            
            % store elapsed time for fix start & fix end
            eTimeFixSta = fixStaTime - trStaTime; % elaplsed time between tr start and fix start
            fixAll(f,7) = eTimeFixSta;
            eTimeFixEnd = fixEndTime - trStaTime; % elspased time between tr start and fix end
            fixAll(f,8) = eTimeFixEnd;
            
            % do data sanity check
            if fixDur*2 ~= (eTimeFixEnd - eTimeFixSta)
                err(1,1) = t;
                err(1,2) = fixDur*2;
                err(1,3) = eTimeFixEnd - eTimeFixSta;
                err(1,4) = fixEndTime - fixStaTime;
            else
                err = 0;
            end
        end
        
        % reset fixDur & storeData
        fixDur = 0;
        storeData = 0;
    end
end

%% 5. Save GazeInt & FixAll table

TT = array2table(gazeInt);
TT.Properties.VariableNames = {'tr', 'intNum', 'intDur_Ms', 'intDurCA_Ms', 'intDurOA_Ms'};
writetable(TT,fileOutGazeInt);

TT = array2table(fixAll);
TT.Properties.VariableNames = {'tr', 'trSta', 'fixDur', 'fixSta', 'fixEnd',...
    'rAOI', 'eTimeFixSta', 'eTimeFixEnd'};
writetable(TT,fileOutFixAll);

end