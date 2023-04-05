function [stimOrdBySeq, stimOrdByTrTyBySeqT] = FlickerFaces_StimOrder(nbSeq,...
    nbCyReq, nbItemFade, trTyBySeq, faceStim, animStim, cloudStim, squareStim,...
    pairShuf)
%% defaults

if nargin < 2 || isempty(nbSeq) == 1
    nbSeq = 1;         % 1 tr
end

if nargin < 3 || isempty(nbCyReq) == 1
    nbCyReq = 8;       % 8 refresh cycles per item
end

if nargin < 4 || isempty(nbItemFade) == 1
    nbItemFade = 5;    % 5 items for FadeIn/FadeOut
end
nbCyFade = nbCyReq * nbItemFade; % number of refresh cycles to for FadeIn/FadeOut
nbCyPr1Min = 4*nbCyFade; % big>>small; small>>big; multiple of FadeIn intervals for the looming fix stim

if nargin < 5 || isempty(trTyBySeq) == 1  % trial type by sequence structure; see FlickerFaces_TrialType
    trTyBySeq = struct('tr',(1:nbSeq)','trTy', ones(nbSeq,1),...
        'nbPrs',ones(nbSeq,1), 'nbCyPr1',ones(nbSeq,1)*nbCyPr1Min,...
        'nbCyBlnk',zeros(nbSeq,1), 'nbCyPr2',zeros(nbSeq,1),...
        'trTyDog',zeros(nbSeq,1), 'nbFqs',ones(nbSeq,1)*2,...
        'trTyFq',zeros(nbSeq,1), 'fqLoc',strings(nbSeq,1),...
        'fqFace',ones(nbSeq,1)*randi(2), 'cueFq',ones(nbSeq,1),...
        'cueLoc',strings(nbSeq,1), 'nbCyCue',zeros(nbSeq,1),...
        'nbCyExt',zeros(nbSeq,1), 'nbCyRota',zeros(nbSeq,1));
end

if nargin < 6 || isempty(faceStim) == 1  % location Faces
    rootStim = fullfile(pwd, 'FlickerFaces.stim');
    faceStim = FlickerFaces_LoadStim(fullfile(rootStim, 'Faces'));
end

if nargin < 7 || isempty(animStim) == 1  % location Animals
    rootStim = fullfile(pwd, 'FlickerFaces.stim');
    animStim = FlickerFaces_LoadStim(fullfile(rootStim, 'Animals'));
end

if nargin < 8 || isempty(cloudStim) == 1  % location Cloud
    rootStim = fullfile(pwd, 'FlickerFaces.stim');
    cloudStim = FlickerFaces_LoadStim(fullfile(rootStim, 'Cloud'));
end

if nargin < 9 || isempty(squareStim) == 1 % location Square
    rootStim = fullfile(pwd, 'FlickerFaces.stim');
    squareStim = FlickerFaces_LoadStim(fullfile(rootStim, 'Square'));
end

if nargin < 10 || isempty(pairShuf) == 1
    pairShuf = 0;      % 1 = shuffle in pairs; 0 = shuffle randomly
end

%% number stimuli

nbFaceStim = size(faceStim);
nbFaceStim = nbFaceStim(2);

nbAnimStim = size(animStim);
nbAnimStim = nbAnimStim(2);

nbCloudStim = size(cloudStim);
nbCloudStim = nbCloudStim(2);

nbSquareStim = size(squareStim);
nbSquareStim = nbSquareStim(2);

%% order stimuli

% order Face stim - shuffle Face images in pairs
trTyFqMax = max(trTyBySeq.trTyFq);
[orderF1Tmp,orderF2Tmp] = ShuffleStim(trTyFqMax,nbSeq,nbFaceStim,pairShuf); 
orderF1 = orderF1Tmp; % face
orderF2 = orderF2Tmp; % noise
for i = 1:nbSeq
   if trTyBySeq.fqFace(i) == 2  % if noise face for fq1 disc, flip the F1 and F2 stimuli   
       orderF1(i,1) = orderF2Tmp(i,1);
       orderF2(i,1) = orderF1Tmp(i,1);
   end
end

% order Anim stim - shuffle Anim images randomly
nbPrsMax = max(trTyBySeq.nbPrs);
[orderA1,orderA2] = ShuffleStim(nbPrsMax,nbSeq,nbAnimStim-1);

% add Dog stim
for i = 1:nbSeq
    if trTyBySeq.trTyDog(i,1) == 1
        if trTyBySeq.nbPrs(i,1) == 1
            orderA1(i,1) = nbAnimStim;
        else
            if randi(1) < .5
                orderA1(i,1) = nbAnimStim;
            else
                orderA2(i,1) = nbAnimStim;
            end
        end
    end
end

% order Cloud stim - shuffle Cloud images randomly
orderC = ones(nbSeq,1);
if nbCloudStim > 1
    orderC = randi([1,nbCloudStim],[nbSeq,1]); % orderC = [1,2,2,1,1,...nbSeq]
end

% order Square stim
orderS = ones(nbSeq,1)*nbSquareStim;

%% StimOrder structure

% create structure
stimOrdBySeq = struct('tr',(1:nbSeq)','cloud',orderC,'A1',orderA1,...
    'A2',orderA2,'square',orderS,'F1',orderF1,'F2',orderF2);

% structure to table
trTyBySeqT = struct2table(trTyBySeq);
stimOrdBySeqT = struct2table(stimOrdBySeq);
stimOrdByTrTyBySeqT = join(trTyBySeqT,stimOrdBySeqT);

end

function [orderStim1,orderStim2] = ShuffleStim(nbUniqStim,nbSeq,nbLdStim,pairShuf)
%% defaults

if nargin < 1 || isempty(nbUniqStim) == 1
    nbUniqStim = 1;     % if 2 images shown at the same tine, then select 2 unique images
end

if nargin < 2 || isempty(nbSeq) == 1
    nbSeq = 1;           % 1 trial
end

if nargin < 3 || isempty(nbLdStim) == 1
    nbLdStim = 2;        % 2 loaded images
end

if nargin < 4 || isempty(pairShuf) == 1
    pairShuf = 0;      % 1 = shuffle in pairs; 0 = shuffle randomly
end

%% shuffle loaded images

nbShuffles = ceil(nbSeq/nbLdStim)*2;     % shuffle images more than 2x if more trials than images

if pairShuf == 0     % shuffle randomly
    orderTmp = zeros(nbLdStim,nbShuffles);   % create a matrix with rows = nb images; col = shuffle set
    for i = 1:nbShuffles
        orderTmp(:,i) = randperm(nbLdStim)'; % shuffle each set individually
    end
    orderTmp = orderTmp(:);   % matrix to vector;  a = [1 2 3; 4 5 6] >> b = [1 4 2 5 3 6];

elseif pairShuf == 1 % shuffle in pairs
    orderTmp = zeros(2,nbLdStim/2*nbShuffles); % initialize orderTmp matrix
    orderT = 1:nbLdStim;                       % vector number images
    orderT = reshape(orderT,2,[]);             % change vector to matrix with 2 rows to make img pairs
    for i = 1:nbShuffles
        cSta = (i*nbLdStim/2+1) - nbLdStim/2;   
        cEnd = ((i+1)*nbLdStim/2) - nbLdStim/2;  
        orderTmp(:,cSta:cEnd) = orderT(:,randperm(nbLdStim/2)); % store shuffled image pairs
    end
    orderTmp = orderTmp(:);   % matrix to vector to avoid repetition
end

%% select images

if nbUniqStim == 2 % if 2 images shown at the same time, then select 2 unique images   
    orderStim1 = orderTmp(rem(orderTmp,2)==1);  % odd images Stim1 (Stim1 = FACES)
    orderStim1 = orderStim1(1:nbSeq,1);
    orderStim2 = orderTmp(rem(orderTmp,2)==0);  % even images Stim2 (Stim2 = NOISE)
    orderStim2 = orderStim2(1:nbSeq,1);
else
    orderStim1 = orderTmp(1:nbSeq,1);         % 1st half Stim1
    orderStim2 = orderTmp(nbSeq+1:nbSeq*2,1); % 2nd half Stim2
end

end
