function [trTyBySeq,fqLoc,cueLoc] = FlickerFaces_TrialType(nbSeq,...
    nbCyReq, nbItemFade, nbNoOvTr, nbOvTr, nbDogTr, nbPerifStim,...
    idFq, fqABBA, RR, cueDur, extDur, epDur, fqBlk1)
%% defaults

if nargin < 1 || isempty(nbSeq) == 1
    nbSeq = 1;   % nr trials
end

if nargin < 2 || isempty(nbCyReq) == 1
    nbCyReq = 8; % cycles requred for the Fq
end

if nargin < 3 || isempty(nbItemFade) == 1
    nbItemFade = 5;  % nr items fade in
end

if nargin < 4 || isempty(nbNoOvTr) == 1
    nbNoOvTr = round(nbSeq/2); % half are NoOverlap trials (only ClouAim Pair1)
end

if nargin < 5 || isempty(nbOvTr) == 1
    nbOvTr = nbSeq - nbNoOvTr; % half are Overlap trials (both ClouAnim Pair1 & Pair2)
end

if nargin < 6 || isempty(nbDogTr) == 1
    nbDogTr = round(nbSeq*10/100); % 10% are catch trials
end

if nargin < 7 || isempty(nbPerifStim) == 1
    nbPerifStim = 2;   % number of periferal stimuli
end
 
if nargin < 8 || isempty(idFq) == 1
    idFq = [1,2];      % use both frequencies fq1 & fq2
end

if nargin < 9 || isempty(fqABBA) == 1
    fqABBA = 1;    % 0 = don't counterbalance; 1 = counterbalance
end

if nargin < 10 || isempty(RR) == 1
    RR = 60;    % screen refresh rate; 60Hz
end

if nargin < 11 || isempty(cueDur) == 1
    cueDur = 0.5;     % in seconds (=0.5s); cue participants to a perif stim for 500 ms
end

if nargin < 12 || isempty(extDur) == 1
    extDur = randi(2);  % in seconds (=1s or 2s); extend trial by 1s after flicker
end

if nargin < 13 || isempty(epDur) == 1
    epDur = 2;  % in seconds (=2s); EEG epoch duration
end

if nargin < 14 || isempty(fqBlk1) == 1
    fqBlk1 = 1;  % 1st frequency block
end

%% initialize variables

% key variables
nbCyFade = nbCyReq * nbItemFade; % refresh cycles fadeIn/fadeOut
n = 10;                          % 10 possible combinations for trial type
jMin = 5;    
jMax = jMin + RR/4;  % jitter by 250 ms nbCyPr1 & nbCyRotaFace

% cycles Cloud >> Animal Pair 1
nbCyPr1Min = nbCyFade + epDur*RR + jMin;   % 50 + 2*60 + 5 = 175 refresh cycles
nbCyPr1Max = nbCyFade + epDur*RR + jMax;   % 50 + 2*60 + 20 = 190 

% cycles Blnk Screen after Cloud >> Animal
nbCyBlnkMin = 2*nbCyFade + RR/2;   % 2*50 + 60/2 = 130 refresh cycles
nbCyBlnkMax = 2*nbCyFade + RR/2;   

% cycles Cloud >> Animal Pair 2
nbCyPr2Min = epDur*RR + jMin; % 2*60 + 5 = 125 refresh cycles
nbCyPr2Max = epDur*RR + jMax; % 2*60 + 20 = 140 refresh cycles

%% table trial types

% table variables
trTy = (1:n); trTy = trTy';              % 10 possible trial types (diff comb of Pr1, Blnk, Pr2 dur)
nbPrs = ones(n,1); nbPrs(3:end,1) = 2;   % nr pairs for each trial type
nbCyPr1 = repmat([nbCyPr1Min;nbCyPr1Max],n/2,1); % half trial types display Pr1 short
nbCyBlnk = zeros(n,1); nbCyBlnk(1:2,1) = 0;                       % first 2 trial types display only Pr1
nbCyBlnk(3:end,1) = repmat([nbCyBlnkMin; nbCyBlnkMin;...
                            nbCyBlnkMax; nbCyBlnkMax],(n-2)/4,1); % other trial types display Blnk short or Blnk long
nbCyPr2 = zeros(n,1);nbCyPr2(1:2,1) = 0;              % first 2 trial types display only Pr1
nbCyPr2(3:end,1) = [repmat(nbCyPr2Min,(n-2)/2,1);...
                      repmat(nbCyPr2Max,(n-2)/2,1)];  % other trial types display Pr2 short or Pr2 long

% create a table with the 10 diff trial types
trTyTmp = [trTy, nbPrs, nbCyPr1, nbCyBlnk, nbCyPr2];  % create a matrix 
%trTyT = table(trTy,nbPrs,nbCyPr1,nbCyBlnk,nbCyPr2);   % matrix >> table
%trTyT.Properties.VariableNames = {'trTy','nbPrs','nbCyPr1','nbCyBlnk','nbCyPr2'}; % table headings

%% trial type per trial/sequence

% initialize variable
trTyBySeqTmp = [];

% for the NoOvTr, use TrTy 1 & 2
if isempty(nbNoOvTr)~=1 || nbNoOvTr == 0
    trTyNoOv = repmat(trTyTmp(1:2,:),ceil(nbNoOvTr/2),1);
    trTyNoOv = trTyNoOv(1:nbNoOvTr,:);
    trTyBySeqTmp = [trTyBySeqTmp;trTyNoOv];
end

% for the OvTr, use TrTy 3, 4, etc.
if isempty(nbOvTr)~=1 || nbOvTr == 0
    trTyOv = repmat(trTyTmp(3:end,:),ceil(nbOvTr/(n-2)),1);
    trTyOv = trTyOv(1:nbOvTr,:);
    trTyBySeqTmp = [trTyBySeqTmp;trTyOv];
end

% if no NoOvTr or OvTr (unlikely), then use TrTy 1
if isempty(trTyBySeqTmp) == 1
    trTyBySeqTmp = repmat(trTyTmp(1,:),nbSeq,1);
end

% shuffle TrTy across trials/sequences
trTyBySeqTmp(randperm(nbSeq),:) = trTyBySeqTmp(:,:);

%%  catch trials

trTyDog = zeros(nbSeq,1); % initialize variable for catch trials
if nbDogTr > 0 % if the user wants any catch trials
    trTyDog(1:nbDogTr,1) = 1; % first x trials are catch trials
    trTyDog(randperm(nbSeq),:) = trTyDog(:,:); % suffle catch trials
end

%% frequency type per trial

% number of flicker frequencies used during each trial
nbFqs(1:nbSeq,1) = floor(mean(nbPerifStim,length(idFq))); 

% frequency type during each trial
trTyFq = zeros(nbSeq,1);
idFqSz = size(idFq); % value in idFq var can change, size(var) is safer

if nbPerifStim == 2    % 2 perif stimuli used in each trial  
    if length(idFq) == 1          % user enters 1 freq type
        trTyFq(:,1) = idFqSz(1,1); 
    elseif length(idFq) == 2      % user enters 2 freq types
        trTyFq(:,1) = 0;   % 0 = use both frequences per trial
    end
    
elseif nbPerifStim < 2 % if central stimulus, or 1 periferal stimulus   
    if length(idFq) == 1                    % user enters 1 freq type
        trTyFq(1:nbSeq,1) = idFqSz(1,1);       
    elseif length(idFq) == 2                % user enters 2 freq types
            h = round(nbSeq/2);
            if fqBlk1 == 2
                trTyFq(1:h,1) = idFqSz(1,2);      % half trials use one freq type
                trTyFq(h+1:end,1) = idFqSz(1,1);  % other half use the other freq type
            else
                trTyFq(1:h,1) = idFqSz(1,1);      % half trials use one freq type
                trTyFq(h+1:end,1) = idFqSz(1,2);  % other half use the other freq type
            end
    end
end

%% frequency location

% fq1 location: centre, left, or right
switch nbPerifStim
    case 0
        fqLoc(1:nbSeq,1) = {'Centre'};
    case 1
        h = round(nbSeq/2); % half trials
        if length(idFq) == 1
            fqLoc = [repmat({'Left'},h,1);...% half trials Left position; SPACE after Left to have same length as Right
                repmat({'Right'},h,1)];  % other half Right position
        elseif length(idFq) == 2
            fqLoc = [repmat({'Left'},round(h/2),1);...% quarter trials Left position
                repmat({'Right'},round(h/2),1)];  % other quarter Right position
            fqLoc = repmat(fqLoc,2,1); % duplicate position first half of the trials
        end
        fqLoc = fqLoc(1:nbSeq,1); % account for when odd nb tr
    case 2
        h = round(nbSeq/2); % half trials
        fqLoc = [repmat({'Left'},h,1);...% half trials Left position
            repmat({'Right'},h,1)];  % other half Right position
        fqLoc = fqLoc(1:nbSeq,1); % account for when odd nb tr
end

%% frequency face

% face stim (face/noise) that goes with fq1 disc
fqFace = repmat([1;2],nbSeq/2,1); % 1 = face; 2 = noise

%% cue frequency

if max(nbFqs) == 2      % if 2 flicker freq per trial
    h = round(nbSeq/4);               % quarter trials
    cueFq = [repmat(idFqSz(1,1),h,1);...% quarter trials cue Fq1
             repmat(idFqSz(1,2),h,1)];  % quarter trials cue Fq2
    cueFq = repmat(cueFq,2,1); % duplicate half trials
    cueFq = cueFq(1:nbSeq);    % account for when odd nb tr
else
    cueFq = trTyFq;  % if 1 flicker freq per trial
end

%% cue location

% cue location foe each trial
cueLoc = cell(nbSeq,1);

for i = 1:nbSeq
    if cueFq(i,1) == trTyFq(i,1) || cueFq(i,1) == idFqSz(1,1)
        cueLoc(i,1) = fqLoc(i,1); % cue loc and flicker loc the same when 1 flicker freq per tr or fq1 flicker cued
    else
        if strcmp('Left', fqLoc(i,1)) == 1
            cueLoc(i,1) = {'Right'};
        else
            cueLoc(i,1) = {'Left'};
        end
    end
end

%% cue duration

% number cycles cue duration
nbCyCue = zeros(nbSeq,1);  

if length(cueDur) == 1                    % use value indicated by used
    nbCyCue(1:nbSeq,1) = cueDur(1,1)*RR;
elseif length(cueDur) == 2                % if user wants both cue and noCue trials
    h = round(nbSeq/2);
    nbCyCue(1:h,1) = cueDur(1,1)*RR;     % half trials one Cue duration
    nbCyCue(h+1:end,1) = cueDur(1,2)*RR; % other half another Cue duration
end

%% extend/noExtend trials

% number cycles trial extension duration
nbCyExt = zeros(nbSeq,1);  

if length(extDur) == 1               % use value indicated by used
    nbCyExt(1:nbSeq,1) = extDur(1,1)*RR;
elseif length(extDur) == 2           % if user wants both ext and noExt trials
    h = round(nbSeq/2);
    nbCyExt(1:h,1) = extDur(1,1)*RR;    % half trials one Ext dur
    nbCyExt(h+1:end,1) = extDur(1,2)*RR;% other half onother Ext dur
end

%% rotate face

% number cycles when rotate face after flicker ends
nbCyRota = repmat([jMin;jMax], nbSeq/2, 1);     % nbCyRota = [5;20;5;20]; cyEndSeq + 1 = cySendEvt; cyEndSeq + 5 = cyStaRota

%% suffle trials

if fqABBA == 1
    r = randperm(nbSeq); % store this to shuffle trTrFq, fqLoc, fqFace, cueFq, cueLoc in same way for counterbalancing
    %trTyFq(r,1) = trTyFq(:,1);    % shuffle flicker frequency; 0 = 2 flicker frequencies per trial
    fqLoc(r,1) = fqLoc(:,1);      % shuffle fq1 location; loc of flicker frequency fq1
    fqFace(r,1) = fqFace(:,1);    % shuffle face presented with fq1 flicker;
    cueFq(r,1) = cueFq(:,1);      % shuffle cued flicker frequency (fq1 or fq2)
    cueLoc(r,1) = cueLoc(:,1);    % shuffle location of the cue deending on the location of the cued flicker frequency
    nbCyCue(randperm(nbSeq),1) = nbCyCue(:,1);   % shuffle cue dur
    nbCyExt(randperm(nbSeq),1) = nbCyExt(:,1);   % shuffle ext dur
    nbCyRota(randperm(nbSeq),1) = nbCyRota(:,1); % shuffle when to rotate face
end

%% trial type structure

trTyBySeq = struct('tr',(1:nbSeq)', 'trTy',trTyBySeqTmp(:,1),...
    'nbPrs',trTyBySeqTmp(:,2), 'nbCyPr1',trTyBySeqTmp(:,3),...
    'nbCyBlnk',trTyBySeqTmp(:,4), 'nbCyPr2',trTyBySeqTmp(:,5),...
    'trTyDog',trTyDog(:,1), 'nbFqs',nbFqs(:,1), 'trTyFq',trTyFq(:,1),...
    'fqLoc',string(fqLoc(:,1)), 'fqFace',fqFace(:,1), 'cueFq',cueFq(:,1),...
    'cueLoc',string(cueLoc(:,1)), 'nbCyCue',nbCyCue(:,1), 'nbCyExt',nbCyExt(:,1),...
    'nbCyRota',nbCyRota(:,1));

end