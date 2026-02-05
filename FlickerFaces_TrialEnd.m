function [dDiag,totalPress] = FlickerFaces_TrialEnd(command,varargin)

% defaults
if nargin < 1 || isempty(command)
    command = 'SendTrigger';
end

if nargin < 2 || isempty(varargin)
    varargin = cell(1,12);    % 12 cells because 'SaveTrialData' requires 12 arguments
end

%% Choose function

switch lower(command)
    
    case 'sendtrigger'
        
        % Eyelink recording?
        if isempty(varargin{1}) == 1
            withETrecording = 0;
        else
            withETrecording = varargin{1};
        end
        
        % NetStation recording?
        if isempty(varargin{2}) == 1
            withEEGrecording = 0;
        else
            withEEGrecording = varargin{2};
        end
        
        % Trigger
        if isempty(varargin{3}) == 1
            trigger = struct('sta','TEST', ...    % trigger = test
                'tr', '999',...                   % keycode1 = tria number
                'fq', '999',...                   % keycode2 = flicker freq (0 = both freq, 1 = fq1, 2 = fq2)
                'ecc','999',...                   % keycode3 = ecc flicker (0 = centre)
                'cue','999');                     % keycode4 = trial cued? (0 = no cue)
        else
            trigger = varargin{3};
        end
        
        % Flicker onset
        if isempty(varargin{4}) == 1
            nsEvtSot = GetSecs();      % timestamp of flicker start
        else
            nsEvtSot = varargin{4};
        end
        
        % Call function
        SendTigger(withETrecording, withEEGrecording, trigger, nsEvtSot);
        
    case 'savetrialdata'
        
        % Trial number
        if isempty(varargin{1}) == 1
            ss = 1;        % trial 1
        else
            ss = varargin{1};
        end
        
        % ScreenFlip info
        if isempty(varargin{2}) == 1
            d = zeros(1,8);        % PTB [output] = Screen('Flip',w);
        else
            d = varargin{2};
        end
        
        % ScreenFlip type
        if isempty(varargin{3}) == 1
            flipTy = {'extra'};    % type of ScreenFlip (cue, fadeIn, exp, fadeOut, extra)
        else
            flipTy = varargin{3};
        end
        
        % Screen diagnostic data
        if isempty(varargin{4}) == 1
            dDiag = struct('d',zeros(ss,1),'flipTy',cell(ss,1));
        else
            dDiag = varargin{4};
        end
        
        % Keypress during trial
        if isempty(varargin{5}) == 1
            totalPress = zeros(ss,4); % faceRota1, faceRota2, keyTime1, keyTime2
        else
            totalPress = varargin{5};
        end
        
        % FaceRota1 Onset
        if isempty(varargin{6}) == 1
            cyEndPr1A = 1;        % endClouAnim1/staFaceRota1 at ref cy 1
        else
            cyEndPr1A = varargin{6};
        end
        
        % FaceRota2 Onset
        if isempty(varargin{7}) == 1
            cyStaRota = 1;        % staFaceRota2 at ref cy 1
        else
            cyStaRota = varargin{7};
        end
        
        % Eyelink recording?
        if isempty(varargin{8}) == 1
            withETrecording = 0; % no Eyelink recording
        else
            withETrecording = varargin{8};
        end
        
        % Trial type
        if isempty(varargin{9}) == 1
            trTyBySeq = struct('trTyFq','999', ...    % flicker freq (0 = both freq, 1 = fq1, 2 = fq2)
                'fqFace', '999',...                   % flicker face (1 = face, 2 = noise); if flicker freq = 0, then fqFace = face for fq1
                'cueFq', '999',...                    % cued flicker frequency (1 = fq1, 2 = fq2)
                'fqEcc','999',...                     % ecc flicker (0 = centre)
                'nbPrs','999',...                     % ClouAnim pairs (1 or 2 pairs)
                'trTyDog','999');                     % catch trial? (0 = no; 1 = catch)
        else
            trTyBySeq = varargin{9};
        end
        
        % Flicker location
        if isempty(varargin{10}) == 1
            fqLoc = {'TEST'}; % flicker location can be right/left; if flicker freq = 0, then fqLoc is for fq1 loc
        else
            fqLoc = varargin{10};
        end
        
        % Flicker eccentricity
        if isempty(varargin{11}) == 1
            fqEcc = 999; % background color; [128 128 128] = grey
        else
            fqEcc = varargin{11};
        end
        
        % Screen background colour
        if isempty(varargin{12}) == 1
            back = [128 128 128]; % background color; [128 128 128] = grey
        else
            back = varargin{12};
        end
        
        % Call function
        [dDiag, totalPress] = SaveTrialData(ss, d, flipTy, dDiag,...
            totalPress, cyEndPr1A, cyStaRota, withETrecording, trTyBySeq,...
            fqLoc, fqEcc, back);
end

end

%% SendTrigger

function [status] = SendTigger(withETrecording, withEEGrecording,...
    trigger, nsEvtSot)

% send event to EDF file
if withETrecording == 1
    Eyelink('Message', 'BLANK_SCREEN');
end

% send event to NetStation file
if withEEGrecording == 1
    NetStation('Event', trigger.sta, nsEvtSot, [],...
        'tria', trigger.tr,...
        'fqTy', trigger.fq,...
        'ecc_', trigger.ecc,...
        'cue_', trigger.cue);
end

% status
status = 1;
end


%% SaveTrialData

function [dDiag, totalPress] = SaveTrialData(ss, d, flipTy, dDiag,...
    totalPress, cyEndPr1A, cyStaRota, withETrecording, trTyBySeq, fqLoc,...
    fqEcc, back)

% put ET in idle mode; ET needs these variables
if withETrecording == 1
    if isempty(trTyBySeq) == 0 && isempty(fqLoc) == 0 && ...
            isempty(fqEcc) == 0 && isempty(back) == 0
        Eyelink_TrialEnd;
    end
end

% save diagnostic data
dDiag(ss).d = d;
dDiag(ss).flipTy = flipTy;

% FaceRota keypress RT
totalPress(ss,3) = totalPress(ss,3) - d(cyEndPr1A,2); % keyPressTime1 - FaceRota1 = RT1
totalPress(ss,4) = totalPress(ss,4) - d(cyStaRota,2); % keyPressTime2 - FaceRota2 = RT2

end
