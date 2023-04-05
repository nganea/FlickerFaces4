function [alphaBySeq] = FlickerFaces_StimAlpha(nbSeq, RR, fq, fq2,...
    alphaByCyTot, alphaByCyTot2, cyStaSeq, cyEndSeq)

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

if nargin < 5 || isempty(alphaByCyTot) == 1
    alpha = Alpha(RR,fq);
    alphaByCyTot = repmat(alpha,1,RR/fq2);
end

if nargin < 6 || isempty(alphaByCyTot2) == 1
    alpha2 = Alpha(RR,fq2);
    alphaByCyTot2 = repmat(alpha2,1,RR/fq);
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

%% main function

alphaBySeq = struct('alpha', zeros(nbSeq,1),'item',zeros(nbSeq,1),'cy',zeros(nbSeq,1));
for i = 1:nbSeq
    
    % define cycle start and end 
    cySta = cyStaSeq(i,1);
    cyEnd = cyEndSeq(i,1);
    
    % alpha for each refresh cycle in the sequence
    if cySta > 1
        alphaT = zeros(1,cySta-1); % during attention getter, square transparent (alpha = 0)
    else
        alphaT = [];
    end
    
    alphaTmp = [alphaT,alphaByCyTot]';
    alphaTmp = alphaTmp(1:cyEnd,1);
    
    alphaTmp2 = [alphaT,alphaByCyTot2]';
    alphaTmp2 = alphaTmp2(1:cyEnd,1);   

    % item number for each refresh cycle in the sequence
    itemT = 0;
    itemT2 = 0;
    item = zeros(cyEndSeq(i,1),1);
    item2 = zeros(cyEndSeq(i,1),1);
    
    % for each refresh cycle until the end of the flickering
    for ii = 1:cyEnd
        
        % flicker item 1
        if ii == cySta
            itemT = itemT + 1;
            itemT2 = itemT2 + 1;
        end
        
        % for each refresh cycle after flickering starts
        if ii > cySta  
            
            % nb refesh cycles since the flickering started
            j = ii - cySta; 
            
            % nb cycles needed for one Fq1 item or full flicker cycle
            if mod(j,round(RR/fq)) == 0
                itemT = itemT + 1;
            end
            
            % nb cycles needed for one Fq2 item
            if mod(j,round(RR/fq2)) == 0
                itemT2 = itemT2 + 1;
            end
        end
        
        % save the number of items
        item(ii,1) = itemT;     
        item2(ii,1) = itemT2;      
    end
    
    % cycle number for each refresh cycle in the sequence
    cy = zeros(cyEnd,1);
    rep = (1+cyEnd-cySta)/round(RR/fq);                     % Matlab starts counting from 1
    cy(cySta:end,1) = repmat((1:round(RR/fq))', rep, 1); 
    
    cy2 = zeros(cyEnd,1);
    rep2 = (1+cyEnd-cySta)/round(RR/fq2);                   % Matlab starts counting from 1
    cy2(cySta:end,1) = repmat((1:round(RR/fq2))', rep2, 1);
    
    % store alpha, item number, and cycle number for each sequence
    alphaBySeq(i).alpha = [alphaTmp,alphaTmp2];
    alphaBySeq(i).item = [item,item2];
    alphaBySeq(i).cy = [cy,cy2];

end

end


function [alpha] = Alpha(RR,fq)

% defaults
if nargin < 1 || isempty(RR) == 1
    RR = 60;
end

if nargin < 2 || isempty(fq) == 1
    fq = 7.5;
end

%%
% refresh cycles required to display one item
nbCyReq = round(RR/fq);

% refresh cycles is an even number
if mod((RR/fq),2) == 0
    % Create alpha values for experimental trials - sine wave
    pondNiveau = sin(linspace(0,pi/2,nbCyReq/2)); % for linear values, apply 'pondNiveau = linspace(0,1,(nbCyReq/2))'
    pondNiveau = 1-pondNiveau; % We want the sine in a given direction... Here, the square is the most visible (= item is invisible) and it becomes increasingly invisible
    alpha = [pondNiveau,fliplr(pondNiveau)];
    
    % refresh cycles is an odd number
elseif mod((RR/fq),2) == 1
    % Create alpha values for experimental trials - sine wave
    pondNiveau = sin(linspace(0,pi/2,round(nbCyReq/2))); % if 7 cycles in total, here computations are made for 4 values
    pondNiveau = 1-pondNiveau;
    alpha = [pondNiveau,fliplr(pondNiveau(1:(round(nbCyReq/2)-1)))];
end

end