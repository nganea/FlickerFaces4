function [trigBySeq] = FlickerFaces_Triggers(nbSeq, trTyFq, fqLoc,...
    trTyDog, fqEcc, cueFq, nbCyCue, fqFace)  
% Triggers 

% NetStation accepts triggers that are 4 char long. Additional info can be
% added in the keycodes.

% NoCue trials:
%
% s0Lf = NoCue, 2 flickers, 7.5 Hz Left disc, 7.5 Hz Face disc
% s0Ln = NoCue, 2 flickers, 7.5 Hz Left disc, 7.5 Hz Noise disc
% s0Rf = NoCue, 2 flickers, 7.5 Hz Right disc, 7.5 Hz Face disc
% s0Rn = NoCue, 2 flickers, 7.5 Hz Right disc, 7.5 Hz Noise disc
%
% s1Lf = NoCue, 1 flicker, 7.5 Hz Left disc, 7.5 Hz Face disc
% s1Ln = NoCue, 1 flicker, 7.5 Hz Left disc, 7.5 Hz Noise disc
% s1Rf = NoCue, 1 flicker, 7.5 Hz Right disc, 7.5 Hz Face disc
% s1Rn = NoCue, 1 flickers, 7.5 Hz Right disc, 7.5 Hz Noise disc
%
% s2Lf = NoCue, 1 flicker, 12 Hz Left disc, 12 Hz Face disc
% s2Ln = NoCue, 1 flicker, 12 Hz Left disc, 12 Hz Noise disc
% s2Rf = NoCue, 1 flicker, 12 Hz Right disc, 12 Hz Face disc
% s2Rn = NoCue, 1 flickers, 12 Hz Right disc, 12 Hz Noise disc

% Cue trials:
%
% S1Lf = Cued 7.5 Hz disc, 7.5 Hz Left disc, 7.5 Hz Face disc
% S1Ln = Cued 7.5 Hz disc, 7.5 Hz Left disc, 7.5 Hz Noise disc
% S1Rf = Cued 7.5 Hz disc, 7.5 Hz Right disc, 7.5 Hz Face disc
% S1Rn = Cued 7.5 Hz disc, 7.5 Hz Right disc, 7.5 Hz Noise disc
%
% S2Lf = Cued 12 Hz disc, 12 Hz Left disc, 12 Hz Face disc
% S2Ln = Cued 12 Hz disc, 12 Hz Left disc, 12 Hz Noise disc
% S2Rf = Cued 12 Hz disc, 12 Hz Right disc, 12 Hz Face disc
% S2Rn = Cued 12 Hz disc, 12 Hz Right disc, 12 Hz Noise disc

%% defaults

if nargin < 1 || isempty(nbSeq) == 1
    nbSeq = 1;
end

if nargin < 2 || isempty(trTyFq) == 1
    trTyFq = zeros(nbSeq,1); % 0 = 2 flicker freq per trial; 1 = flicker Fq1; 2 = flicker Fq2
end

if nargin < 3 || isempty(fqLoc) == 1
    fqLoc = cell(nbSeq,1);
    fqLoc(:,1) = {'Left'};  % Fq1 disc on the left side
end

if nargin < 4 || isempty(trTyDog) == 1
    trTyDog = zeros(nbSeq,1);  % trTyDog = 0, no catch trials
end

if nargin < 5 || isempty(fqEcc)
    fqEcc = ones(nbSeq,1).*10;  % 10 cm eccentricity for perif stim
end

if nargin < 6 || isempty(cueFq)
    cueFq = ones(nbSeq,1); % cue 7.5 Hz
end

if nargin < 7 || isempty(nbCyCue)
    nbCyCue = zeros(nbSeq,1); % no cue; cue dur = 0 s
end

if nargin < 8 || isempty(fqFace)
    fqFace = ones(nbSeq,1); % 7.5 Hz disc displays Face
end

%% initialize vars

% location of Fq2
locFq1 = cell(nbSeq,1);
locFq2 = cell(nbSeq,1);
for i = 1:nbSeq
    if strcmp('Left',fqLoc(i,1)) == 1
        locFq1(i,1) = {'L'}; 
        locFq2(i,1) = {'R'};
    else
        locFq1(i,1) = {'R'};
        locFq2(i,1) = {'L'};
    end
    
    % only Fq2 flicker shown, keep location
    if trTyFq(i,1) == 2
        locFq2(i,1) = locFq1(i,1); 
    end
end

% face/noise
faceFq1 = cell(nbSeq,1);
faceFq2 = cell(nbSeq,1);
for i = 1:nbSeq
    if fqFace(i,1) == 1
        faceFq1(i,1) = {'f'};
        faceFq2(i,1) = {'n'};
    else
        faceFq1(i,1) = {'n'};
        faceFq2(i,1) = {'f'};
    end
    
    % only Fq2 flicker shown, keep face
    if trTyFq(i,1) == 2
        faceFq2(i,1) = faceFq1(i,1); 
    end
end

%% determine cond

% variables
tSta = cell(nbSeq,1);
tEnd = cell(nbSeq,1);
tCueFq = cell(nbSeq,1);
tLoc = cell(nbSeq,1);
tFace = cell(nbSeq,1);
tTrTyFq = cell(nbSeq,1);

for i = 1:nbSeq
    
    % Cue trials
    if nbCyCue(i,1) > 0
        
        tSta(i,1) = {'S'}; % capital S for Cue tr
        tEnd(i,1) = {'E'}; 
        tCueFq(i,1) = num2cell(cueFq(i,1)); % cued flicker freq
        
        % location & face of cued flicker disc
        if cueFq(i,1) == 1
            tLoc(i,1) = locFq1(i,1); 
            tFace(i,1) = faceFq1(i,1);
        elseif cueFq(i,1) == 2
            tLoc(i,1) = locFq2(i,1);
            tFace(i,1) = faceFq2(i,1);
        end
       
    % NoCue trials
    else 
        tSta(i,1) = {'s'}; % small s for NoCue tr
        tEnd(i,1) = {'e'}; 
        tTrTyFq(i,1) = num2cell(trTyFq(i,1)); % flicker freq disp during tr
        
        % location & face displayed 
        if trTyFq(i,1) == 2           % if only 12 Hz disc, use loc 12 Hz disc
            tLoc(i,1) = locFq2(i,1); 
            tFace(i,1) = faceFq2(i,1);
        else                          % if 7.5 Hz disc or 7.5 Hz + 12 Hz, use loc 7.5 Hz disc
            tLoc(i,1) = locFq1(i,1);
            tFace(i,1) = faceFq1(i,1);
        end
        
    end
    
end

%% triggers

% some variables may not have been initialized or are empty cells
if exist('tCueFq','var') == 0 || max(cellfun(@isempty,tCueFq)) == 1
    tCueFq = num2cell(cueFq);
end

if exist('tTrTyFq','var') == 0 || max(cellfun(@isempty,tTrTyFq)) == 1
    tTrTyFq = num2cell(trTyFq);
end

% NetStation accepts only 4 char triggers, extra used as keycodes
trigBySeq = struct('sta', cell(nbSeq,1), 'end', cell(nbSeq,1));
for i = 1:nbSeq
    staT = char(tSta(i,1)); % char mark start of flicker
    endT = char(tEnd(i,1)); % char mark end of flicker
    if nbCyCue(i,1) > 0
        cueTrT = '1'; % Cue tr; char var
    else
        cueTrT = '0'; % NoCue tr
    end
    cueFqT = char(string(tCueFq(i,1))); % char mark cued flicker    
    tyFqT = char(string(tTrTyFq(i,1))); % char mark type of flicker displayed   
    locT = char(tLoc(i,1));             % char mark loc of flicker cued or displayed
    faceT = char(tFace(i,1));           % char mark whether Face/Noise of flicker cued or displayed    
    dogTrT = num2str(trTyDog(i,1));     % 1 = catch trial
    eccT = num2str(fqEcc(i,1));                  % eccentricity disc
   
    if nbCyCue(i,1) > 0 % Cue tr
    
        % S2Lf = Cued 12 Hz disc, 12 Hz Left disc, 12 Hz Face disc
        trigBySeq(i).sta = strcat(staT, cueFqT, locT, 'f'); %faceT
        trigBySeq(i).end = strcat(endT, cueFqT, locT, 'f'); %faceT
        trigBySeq(i).tr = num2str(i);  % tr
        trigBySeq(i).fq = tyFqT;       % 0 = 2 flicker freq; 1 = 7.5 Hz; 2 = 12 Hz
        trigBySeq(i).ecc = eccT;       % 10 = 10 cm
        trigBySeq(i).cue = cueTrT;     % 0 = not cued tr
        trigBySeq(i).catch = dogTrT;   % 1 = catch tr
        
    else % NoCue tr
        
        % s0Lf = NoCue, 2 flickers, 7.5 Hz Left disc, 7.5 Hz Face disc
        trigBySeq(i).sta = strcat(staT, tyFqT, locT, 'f'); % faceT
        trigBySeq(i).end = strcat(endT, tyFqT, locT, 'f'); % faceT
        trigBySeq(i).tr = num2str(i);  % tr
        trigBySeq(i).fq = tyFqT;       % 0 = 2 flicker freq; 1 = 7.5 Hz; 2 = 12 Hz
        trigBySeq(i).ecc = eccT;       % 10 = 10 cm
        trigBySeq(i).cue = cueTrT;     % 0 = not cued tr
        trigBySeq(i).catch = dogTrT;   % 1 = catch tr
        
    end
end

end
