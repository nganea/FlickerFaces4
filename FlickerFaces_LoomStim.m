function [loomStimRect] = FlickerFaces_LoomStim(nbSeq, nbCyReq, nbItemFade,...
    screenWidthPx, screenHeightPx, screenWidthCm, screenHeightCm,...
    stimOnsetBySeq, stimRectBySeq)

if nargin < 1 || isempty(nbSeq) == 1
    nbSeq = 1;
end

if nargin < 2 || isempty(nbCyReq) == 1
    nbCyReq = 8;
end

if nargin < 3 || isempty(nbItemFade) == 1
    nbItemFade = 5;
end

nbCyFade = nbCyReq*nbItemFade;

if nargin < 4 || isempty(screenWidthPx) == 1
    screenWidthPx = 640; % 640 px
end

if nargin < 5 || isempty(screenHeightPx) == 1
    screenHeightPx = 500; % 500 px
end

if nargin < 6 || isempty(screenWidthCm) == 1
    screenWidthCm = 15;   % 15 cm
end

if nargin < 7 || isempty(screenHeightCm) == 1
    screenHeightCm = 15;  % 15 cm
end

if nargin < 8 || isempty(stimOnsetBySeq) == 1
    stimOnsetBySeq = struct('tr',(1:nbSeq)',...
        'cyStaSeq',ones(1:nbSeq,1),...
        'cyEndPr1C',ones(1:nbSeq,1)*2*nbCyFade,...
        'cyEndPr1A',ones(1:nbSeq,1)*4*nbCyFade,...
        'cyEndBlnk',zeros(1:nbSeq,1),...
        'cyEndPr2C',ones(1:nbSeq,1)*6*nbCyFade,...
        'cyEndPr2A',ones(1:nbSeq,1)*9*nbCyFade,...
        'cyEndSeq',ones(1:nbSeq,1)*9*nbCyFade,...
        'cyEndTr',ones(1:nbSeq,1)*11*nbCyFade);
end

if nargin < 9 || isempty(stimRectBySeq) == 1
    wT = round(screenWidthPx/2);   % half screen width (px)
    hT = round(screenHeightPx/2);  % half screen height (px)
    stimW = 200/2;  % width (px)
    stimH = 200/2; % height (px)
    rect = [wT-stimW, hT-stimH, wT+stimW, hT+stimH];
    stimRectBySeq = strcut('nbSeq',(1:nbSeq)','rect',rect,'ecc',0,'loc',{'Centre'});
end

%%
cyEndPr1A = stimOnsetBySeq.cyEndPr1A(:);
cyEndBlnk = stimOnsetBySeq.cyEndBlnk(:);
cyEndPr2A = stimOnsetBySeq.cyEndPr2A(:);

rectTmp = stimRectBySeq(1).rect; % left top right bottom

wPxPerCm = round(screenWidthPx/screenWidthCm);
hPxPerCm = round(screenHeightPx/screenHeightCm);

x = 1:nbCyFade;
y = nbCyFade/pi;
cosX = cos(x/y);
cosX1 = [cosX,cosX*(-1)]';
cosX2 = [cosX*(-1),cosX]';

loomStimRect = struct('rect',zeros(1,4));
for i = 1:nbSeq
    
    nbCyPr1 = cyEndPr1A(i,1);
    rep = ceil(nbCyPr1/nbCyFade);
    loomPr1 = repmat(cosX1,rep,1);
    loomPr1 = loomPr1(1:nbCyPr1,1);
    
    nbCyBlnk = cyEndBlnk(i,1) - cyEndPr1A(i,1);
    loomBlnk = zeros(nbCyBlnk,1);
    
    nbCyPr2 = cyEndPr2A(i,1) - cyEndBlnk(i,1);
    rep = ceil(nbCyPr2/nbCyFade);
    loomPr2 = repmat(cosX2,rep,1);
    loomPr2 = loomPr2(1:nbCyPr2,1);
    
    loomR = [loomPr1; loomBlnk; loomPr2];
    
    wLoomR = round(wPxPerCm*loomR);
    hLoomR = round(hPxPerCm*loomR);
    L = rectTmp(1) - wLoomR; % left
    T = rectTmp(2) - hLoomR; % top
    R = rectTmp(3) + wLoomR; % right
    B = rectTmp(4) + hLoomR; % bottom
    loomStimRect(i).rect = [L,T,R,B];
end
end
