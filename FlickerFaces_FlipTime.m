clearvars
s = 93;
fileMat = sprintf('FF1_%d.mat', s);
fileTime = sprintf('FF1_%d_Time.csv', s); 
fileEvt = sprintf('FF1_%d_Evt.csv', s);
fileGaze = sprintf('FF1_%d_GAZA_SAMPLE.csv', s);
folderPs = sprintf('FF1_%d', s);

root = pwd;
rootData = fullfile(pwd, 'FlickerFaces.data', folderPs);
fileMat = fullfile(rootData, fileMat);
fileTime = fullfile(rootData, fileTime); 
fileEvt = fullfile(rootData, fileEvt);

load(fileMat,'dDiag')

rrScr = 60;
durRefCy = 1000/rrScr;

rrEt = 500;
durSplEt = 1000/rrEt;

rrEegFq = 7.5;
durSplEegFq = 1000/rrEegFq;

rrEegFq2 = 12;
durSplEegFq2 = 1000/rrEegFq2;

comScrEt = gcd(rrScr,rrEt);

flipMiss = zeros(length(dDiag),1);
flipDur = zeros(length(dDiag),1);

dd = 0;
for i = 1:length(dDiag)
    d = dDiag(i).d;
    for ii = 1:length(d)
        
        % missed flips
        if d(ii,4) > 0
            dd = dd + 1;
        end
        
        if d(ii,1) > 0
            timeRefCy = 0;           
        end
        
        % flip duration
        if ii > 2 && d(ii,1) > 0 && d(ii-1,1) > 0
            flipDurTmp = 0;
        else
            flipDurTmp = -1;
        end
        
        if flipDurTmp == 0    
            flipDurTmp = round(d(ii,1) - d(ii-1,1),3);
            if flipDurTmp > 0.017
                ddd = ddd + 1;              
            end
        end       
    end
    flipMiss(i,1) = dd;
    flipDur(i,1) = ddd;
        
end


T = readtable(fileEvt,'TextType','string');
T = renamevars(T,["mff","Var5","Var7","Var8"],...
    ["evt","time","evtTy","cy"]);
evt = T.evt;
timeStr = T.time;
evtTy = T.evtTy;
cy = T.cy;

timeMs = zeros(length(timeStr),1);
for i = 1:length(timeStr)
    t = char(timeStr(i,1));
    timeMs(i,1) = milliseconds(duration(t(2:13)));
end

c = 0;
trTy = strings(length(dDiag),1); 
tr = zeros(length(dDiag),1);
trTyDog = zeros(length(dDiag),1);
trDur = zeros(length(dDiag),1);
dif = zeros(100,1);
dinItemMean = zeros(length(dDiag),1);
dinItemStd = zeros(length(dDiag),1);
dinItemSta = zeros(length(dDiag),1);
dinItemEnd = zeros(length(dDiag),1);
dinDiffSta = zeros(length(dDiag),1);
for i = 1:length(evt)
    e = char(evt(i,1));
    if strcmp(e(1),'S') == 1
        c = c + 1;
        cc = 0;
        dif(:,1) = 0;
        trTy(c,1) = e;
        trTyTmp = e;
        tr(c,1) = cy(i,1);
        trSta = timeMs(i,1);
        if strcmp(e(4),'1') == 1
            trTyDog(c,1) = 1;
        else
            trTyDog(c,1) = 0;
        end
    elseif strcmp(e(1),'D') == 1
        cc = cc + 1;
        if cc == 1
            dif(cc,1) = 0;
            itemSta = timeMs(i,1);
            dinDiffSta(c,1) = itemSta-trSta;
        else
            dif(cc,1) = timeMs(i,1)-timeMs(i-1,1);
            if cc == 2
                dinItemSta(c,1) = dif(cc,1);
            elseif strcmp(trTyTmp(3),'R') == 1 && cc == 90
                itemEnd = timeMs(i,1);
                trDur(c,1) = itemEnd - itemSta + durRefCy;
                dinItemMean(c,1) = mean(dif(3:89,1));
                dinItemStd(c,1) = std(dif(3:89,1));
                dinItemEnd(c,1) = dif(cc,1);  
            elseif strcmp(trTyTmp(3),'L') == 1 && cc == 57
                itemEnd = timeMs(i,1);
                trDur(c,1) = itemEnd - itemSta + durRefCy;
                dinItemMean(c,1) = mean(dif(3:56,1));
                dinItemStd(c,1) = std(dif(3:56,1));
                dinItemEnd(c,1) = dif(cc,1);                
            end
        end
    end
end

summary = [tr, trDur, flipMiss, flipDur,...
    dinItemMean, dinItemStd, dinItemSta, dinItemEnd, dinDiffSta];
TT = table(tr, trDur, flipMiss, flipDur,...
    dinItemMean, dinItemStd, dinItemSta, dinItemEnd, dinDiffSta); 
TT = renamevars(TT, ["tr", "trDur", "flipMiss", "flipDur"],...
    ["Tr", "TrDurPhotodiode", "MissedFlips", "FlipsOver16ms"]);
writetable(TT, fileTime);
        