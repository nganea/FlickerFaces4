function [stimOnBySeq, stimOnByTrTyBySeqT] = FlickerFaces_StimOnset(nbSeq,...
    nbCyReq, nbItemFade, nbItemExp, trTyBySeq, RR)
%% defaults

if nargin < 1 || isempty(nbSeq) == 1
    nbSeq = 1;
end

if nargin < 2 || isempty(nbCyReq) == 1
    nbCyReq = 8;
end

if nargin < 3 || isempty(nbItemFade) == 1
    nbItemFade = 5;
end

if nargin < 4 || isempty(nbItemExp) == 1
    nbItemExp = 10;
end

nbCyFade = nbCyReq * nbItemFade;
nbCyTot = nbCyReq * (nbItemFade*2 + nbItemExp);

if nargin < 5 || isempty(trTyBySeq) == 1
    nbCyPr1Min = 4*nbCyFade+2;   % big >> small; small >> big
    nbCyPr2Min = 2*nbCyFade;     % small>>big; big>>small
    trTyBySeq = struct('tr',(1:nbSeq)', 'trTy',ones(nbSeq,1),...
        'nbPrs',ones(nbSeq,1), 'nbCyPr1',ones(nbSeq,1)*nbCyPr1Min,...
        'nbCyBlnk',zeros(nbSeq,1), 'nbCyPr2',ones(nbSeq,1)*nbCyPr2Min,...
        'trTyDog',zeros(nbSeq,1), 'nbFqs',ones(nbSeq,1)*2,...
        'trTyFq',zeros(nbSeq,1), 'nbCyCue',zeros(nbSeq,1),...
        'nbCyExt',zeros(nbSeq,1),'nbCyRota',zeros(nbSeq,1));
end

if nargin < 6 || isempty(RR) == 1
    RR = 60; % 60 Hz refresh rate screen
end

%% end stim (refresh cycle)

% end cloud jitter
j = round(RR/4); % jitter end cloud in X refresh cycles or 250 ms

% start & end Flicker Sequence & end Trial
cyStaSeq = zeros(nbSeq,1);  % cy start flicker sequence
cyEndSeq = zeros(nbSeq,1);  % cy end flicker sequence
cyStaRota = zeros(nbSeq,1); % cy start face rotation
cyEndTr = zeros(nbSeq,1);   % cy end trial
for i = 1:nbSeq
    cyStaSeq(i,1) = trTyBySeq.nbCyCue(i) + 1;           % Matlab starts counting from 1
    cyEndSeq(i,1) = trTyBySeq.nbCyCue(i) + nbCyTot;
    cyStaRota(i,1) = trTyBySeq.nbCyCue(i) + nbCyFade + 2*RR + ...
        (nbCyFade+RR/2) + 2*RR + trTyBySeq.nbCyRota(i); % rotate face time at 7s after tr onset
    cyEndTr(i,1) = trTyBySeq.nbCyCue(i) + nbCyTot + trTyBySeq.nbCyExt(i) + 1;
end

% end Cloud & Animal Pair1
cyEndPr1C = zeros(nbSeq,1); % make end cloud unpredictible
for i = 1:nbSeq
    h = round(trTyBySeq.nbCyPr1(i)/2); % half point
    cyEndPr1C(i,1) = trTyBySeq.nbCyCue(i) + randi([h-j,h+j]); % 500 ms jitter
end
cyEndPr1A = trTyBySeq.nbCyCue(:) + trTyBySeq.nbCyPr1(:); % end animal = end ClouAnim Pair1

% end Blank screen between ClouAnim Pair1 >> ClouAnim Pair2
cyEndBlnk = zeros(nbSeq,1);
for i=1:nbSeq
    if trTyBySeq.nbPrs(i) == 2 % if 2 ClouAnim pairs, then set a time to end Blank screen
        cyEndBlnk(i,1) = trTyBySeq.nbCyCue(i) + trTyBySeq.nbCyPr1(i)...
            + trTyBySeq.nbCyBlnk(i);
    else
        cyEndBlnk(i,1) = cyEndTr(i,1);
    end
end

% end Cloud & Animal Pair2 
cyEndPr2C = zeros(nbSeq,1);  % end Cloud 
cyEndPr2A = zeros(nbSeq,1);  % end Animal
for i=1:nbSeq  
    h = round(trTyBySeq.nbCyPr2(i)/2); % half point
    if trTyBySeq.nbPrs(i) == 2
        cyEndPr2C(i,1) = trTyBySeq.nbCyCue(i) + trTyBySeq.nbCyPr1(i)...
            + trTyBySeq.nbCyBlnk(i) + randi([h-j,h+j]);        % end Cloud; jitter 500 ms
        cyEndPr2A(i,1) = trTyBySeq.nbCyCue(i) + trTyBySeq.nbCyPr1(i)...
            + trTyBySeq.nbCyBlnk(i) + trTyBySeq.nbCyPr2(i);    % end Animal = end ClouAnim Pair2
    else
        cyEndPr2C(i,1) = cyEndTr(i,1);
        cyEndPr2A(i,1) = cyEndTr(i,1);
    end
end

%% stim onset/offset structure

stimOnBySeq = struct('tr',(1:nbSeq)', 'cyStaSeq',cyStaSeq, 'cyEndPr1C',cyEndPr1C,...
    'cyEndPr1A',cyEndPr1A, 'cyEndBlnk',cyEndBlnk, 'cyEndPr2C',cyEndPr2C,...
    'cyEndPr2A',cyEndPr2A, 'cyEndSeq',cyEndSeq, 'cyEndTr',cyEndTr,...
    'cyStaRota',cyStaRota, 'cyEndCue',cyStaSeq(:,1)-1,...               % Matlab starts counting from 1
    'cyEndFadeIn',cyStaSeq+nbCyFade-1, 'cyEndExp',cyEndSeq-nbCyFade,...
    'cySendEvt',cyEndSeq+1, 'cyEndKbCk1',cyEndPr1A+RR, ...
    'cyEndKbCk2',cyStaRota+RR);           % check for KbPress for 1s after Face rotation starts  

%% stim onset/offset table

trTyBySeqT = struct2table(trTyBySeq);
stimOnBySeqT = struct2table(stimOnBySeq);
stimOnByTrTyBySeqT = join(trTyBySeqT,stimOnBySeqT);
end