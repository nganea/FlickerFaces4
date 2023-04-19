function [alpha, alphaFadeIn, alphaFadeOut] = ...
    FlickerFaces_Transparency(squareWaveP, nbCyReq, nbItemFade)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Function for computing transparency values for SSVEP experiments
%
% Fabienne Chetail - August 2015 - Fabienne.Chetail@ulb.be
% Natasa Ganea - March 2022 - natasa.ganea@gmail.com
%
% Copyright © 2022 Fabienne Chetail & Natasa Ganea. All Rights Reserved.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Defaults (assuming screen RR = 60Hz):
% - squareWaveP = 0   0 = sine wave; 1 = square wave
% - nbCyReq = 8       number of refresh cycles per item; 60Hz/7.5Hz = 8 cycles;
% - nbItemFade = 5    number of items for fade in/out (to avoid ERP); 
%                     5 item * 8 cycles = 40 cycles; fadeInDur = 0.667
%
% Output:
% - alpha = transparency values for each refresh cycle in ONE Exp Item
% - alphaFadeIn = transparency values for each refresh cycle in ALL FadeIn
%                 Items, calculated like this because the max visibility
%                 increases item by item
% - alphaFadeOut = yransparency values for each refresh cycle in ALL
%                 FadeOut Items, calculated like this because the max
%                 visibility decrease item by item
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% if nbCyReq is even, there are nbCyReq/2 different values of alpha in both ascending and descending):
%   - horizontal bar = level
%   - vertical bar = limit of a period
%
%      g h           i j
%      _ _           _ _
%     _   _         _   _
%    _     _       _     _
%   _       _     _       _
%  _         _   _         _
% _           _|_           _|_ ...
% a           c d           e f
%
%
% - a & c = item 1 invisible (alpha = 1)
% - d & e = item 2 invisible
% - f = item 3 invisible
% - g & h = item 1 visible (alpha = 0)
% - i & j = item 2 visible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% if nbCyReq is odd, there are nbCyReq/2 different values of alpha in ascending and nbCyReq/2-1 in descending):
%   - horizontal bar = level
%   - vertical bar = limit of a period
%
%      g           i
%      _           _
%     _ _         _ _
%    _   _       _   _
%   _     _     _     _
%  _       _   _       _
% _         _|_         _|_ ...
% a         c d         e f
%
% - a & c = item 1 invisible (alpha = 1)
% - d & e = item 2 invisible
% - f = item 3 invisible
% - g = item 1 visible (alpha = 0)
% - i = item 2 visible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Create alpha values for fadeIn / fadeOut
%
%                       _
%              _       _ _
%       _     _ _     _   _
%  _   _ _   _   _   _     _
% _ _|_   _|_     _|_       _|_ ... // x (10) trials (nbItemFade) to reach the base of an experiment trial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% for pictures
%   - alpha = 0 => invisible
%   - alpha = 1 => visible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default (assuming screen refresh rate = 60 Hz)
if nargin < 1 || isempty(squareWaveP) == 1
    squareWaveP = 0;
end

if nargin < 2 || isempty(nbCyReq) == 1
    nbCyReq = 8;
end

if nargin < 3 || isempty(nbItemFade) == 1
    nbItemFade = 5;
end

%% Initialising Variables 
alphaFadeIn = zeros(nbItemFade, nbCyReq); 
alphaFadeOut = zeros(nbItemFade, nbCyReq);

% Max transparency value that each of the fadeIn/fadeOut items will reach
baseLin=linspace(0,pi/2,nbItemFade+2); % because we don't want to consider the two extreme values of peak
baseLin=baseLin(2:nbItemFade+1); % for FadeIn
baseLinR=fliplr(baseLin); % for FadeOut

%% Compute Alpha Values

% refresh cycles required for stimulus display is even number
if mod(nbCyReq,2) == 0 
    
    % sine wave
    if squareWaveP == 0 
        % Create alpha values for experimental trials
        pondNiveau = sin(linspace(0,pi/2,nbCyReq/2)); % for linear values, apply 'pondNiveau = linspace(0,1,(nbCyReq/2))'
%         pondNiveau = 1-pondNiveau; % We want the sine in a given direction... Here, the square is the most visible (= item is invisible) and it becomes increasingly invisible
        alpha = [pondNiveau,fliplr(pondNiveau)];
        % Create alpha values for fade in/ fade out
        for i=1:nbItemFade
            pondNiveau = sin(linspace(0,baseLin(i),nbCyReq/2)); % fadeIn
%             pondNiveau = 1-pondNiveau;
            alphaTmp = [pondNiveau,fliplr(pondNiveau)];
            alphaFadeIn(i,:) = alphaTmp;
            pondNiveau = sin(linspace(0,baseLinR(i),nbCyReq/2)); % fadeOut
%             pondNiveau = 1-pondNiveau;
            alphaTmp = [pondNiveau,fliplr(pondNiveau)];
            alphaFadeOut(i,:) = alphaTmp;
        end
    
    % square wave
    elseif squareWaveP == 1
        % Create alpha values for experimental trials
        alpha = 1-[zeros(1,nbCyReq/2),ones(1,nbCyReq/2)];
        % Create alpha values for fade in / fade out
        for i=1:nbItemFade
            alphaTmp = 1-[zeros(1,nbCyReq/2),repmat(baseLin(i),1,nbCyReq/2)];
            alphaFadeIn(i,:) = alphaTmp;
            alphaTmp = 1-[zeros(1,nbCyReq/2),repmat(baseLinR(i),1,nbCyReq/2)];
            alphaFadeOut(i,:) = alphaTmp;
        end
    end

% refresh cycles required for stimulus display is odd number
elseif mod(nbCyReq,2) == 1 
    
    % sine wave
    if squareWaveP == 0
        % Create alpha values for experimental trials
        pondNiveau = sin(linspace(0,pi/2,round(nbCyReq/2))); % if 7 cycles in total, here computations are made for 4 values
%         pondNiveau = 1-pondNiveau;
        alpha = [pondNiveau,fliplr(pondNiveau(1:(round(nbCyReq/2)-1)))];
        % Create alpha values for fade in/ fade out
        for i=1:nbItemFade
            pondNiveau = sin(linspace(0,baseLin(i),round(nbCyReq/2))); % fadeIn
%             pondNiveau = 1-pondNiveau;
            alphaTmp = [pondNiveau,fliplr(pondNiveau(1:(round(nbCyReq/2)-1)))];
            alphaFadeIn(i,:)= alphaTmp;
            pondNiveau = sin(linspace(0,baseLinR(i),round(nbCyReq/2))); % fadeOut
%             pondNiveau = 1-pondNiveau;
            alphaTmp = [pondNiveau,fliplr(pondNiveau(1:(round(nbCyReq/2)-1)))];
            alphaFadeOut(i,:)= alphaTmp;
        end
        
    % square wave   
    elseif squareWaveP == 1
        % Create alpha values for experimental trials
        alpha = 1-[zeros(1,round(nbCyReq/2)-1),ones(1,round(nbCyReq/2))];
        % Create alpha values for fade in / fade out
        for i=1:nbItemFade
            alphaTmp = 1-[zeros(1,round(nbCyReq/2)-1),repmat(baseLin(i),1,round(nbCyReq/2))];
            alphaFadeIn(i,:)= alphaTmp;
            alphaTmp = 1-[zeros(1,round(nbCyReq/2)-1),repmat(baseLinR(i),1,round(nbCyReq/2))];
            alphaFadeOut(i,:)= alphaTmp;
        end
    end
end

%% Plot wanted:
% figure(1);
% t1 = reshape(alphaFadeIn.',1,[]); plot(t1);

end

