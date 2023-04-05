function [pdBySeq] = FlickerFaces_PhotodiodeCy(nbSeq, RR, fq, fq2, trTyFq,...
    loc, cyStaSeq, cyEndSeq, cyEndTr)

% defaults
if nargin < 1 || isempty(nbSeq) == 1
    nbSeq = 1;
end

if nargin < 2 || isempty(RR) == 1
    RR = 60;
end

if nargin < 3 || isempty(fq) == 1
    fq = 7.5;
end

if nargin < 4 || isempty(fq2) == 1
    fq2 = 12;
end

if nargin < 5 || isempty(trTyFq) == 1
    trTyFq = zeros(nbSeq,1);
end

if nargin < 6 || isempty(loc) == 1
    loc = cell(nbSeq,1);
    loc(:,1) = {'Left'};
end

if nargin < 7 || isempty(cyStaSeq) == 1
    cyStaSeq = ones(nbSeq,1);
end

if nargin < 8 || isempty(cyEndSeq) == 1
    cyEndSeq = zeros(nbSeq,1);
    for i = 1:nbSeq
        cyEndSeq(i,1) = round(RR/fq * RR/fq2);
    end
end

if nargin < 8 || isempty(cyEndTr) == 1
    cyEndTr = zeros(nbSeq,1);
    for i = 1:nbSeq
        cyEndTr(i,1) = cyEndSeq(i,1) + cyStaSeq(i,1);
    end
end

% intialize variables
nbCyReq = round(RR/fq);
nbCyReq2 = round(RR/fq2);

% calculate nb refresh cy required for photodiode to turn on
nbCyReqT = zeros(nbSeq,1);
for i = 1:nbSeq
    if trTyFq(i,1) == 0
        if strcmp(loc(i,1),'Left') == 1
            nbCyReqT(i,1) = nbCyReq;
        else
            nbCyReqT(i,1) = nbCyReq2;
        end
    elseif trTyFq(i,1) == 1
        nbCyReqT(i,1) = nbCyReq;
    elseif trTyFq(i,1) == 2
        nbCyReqT(i,1) = nbCyReq2;
    end
end

% refresh cy when photodiode turns on
pdBySeq = struct('cyOn', zeros(nbSeq,1));
for i = 1:nbSeq
    
    % create variable with all the refresh cy in the trial
    cyOn = zeros(cyEndTr(i,1),1);
    
    % for each refresh cy
    for j = 1:cyEndTr(i,1)
        
        % if the refresh cy is part of the flickering sequence
        if j >= cyStaSeq(i,1) && j <= cyEndSeq(i,1)+1
            
            % seq start & end
            if j == cyStaSeq(i,1)
                cyOn(j,1) = 1; % switch PD sq to white at Seq start
            elseif j == cyEndSeq(i,1)+1 
                cyOn(j,1) = 1; % switch PD sq to white at Seq end
            end
            
            % calculate the refresh cy in the sequence
            jj = j - cyStaSeq(i,1);
            
            % every common multiple of refresh cycles, switch PD sq to white; NS evt limit
            if mod(jj, nbCyReq*nbCyReq2) == 0
                cyOn(j,1) = 1; % switch PD sq to white every nbCyReq
            end
        end
    end
    
    % save variable cyOn in the structure so it can be read
    pdBySeq(i).cyOn = cyOn;
    
end

end
