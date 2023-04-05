function [rotaAngBySeq] = FlickerFaces_RotaStim(nbSeq, nbCyReq, nbItemFade,...
    stimOnsetBySeq, RR, rotaDur, rotaAngleMax)
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

if nargin < 3 || isempty(stimOnsetBySeq) == 1
    nbCyFade = nbCyReq*nbItemFade;
    stimOnsetBySeq = struct('tr',(1:nbSeq)',...
        'cyStaSeq',ones(nbSeq,1),...
        'cyEndPr1C',ones(nbSeq,1)*2*nbCyFade,...
        'cyEndPr1A',ones(nbSeq,1)*4*nbCyFade,...
        'cyEndBlnk',zeros(nbSeq,1),...
        'cyEndPr2C',ones(nbSeq,1)*6*nbCyFade,...
        'cyEndPr2A',ones(nbSeq,1)*9*nbCyFade,...
        'cyEndSeq',ones(nbSeq,1)*9*nbCyFade,...
        'cyEndTr',ones(nbSeq,1)*11*nbCyFade,...
        'nbCyRota',ones(nbSeq,1)*9*nbCyFade);
end

if nargin < 4 || isempty(RR) == 1
    RR = 60;  % screen refresh rate 60 Hz
end

if nargin < 5 || isempty(rotaDur) == 1
    rotaDur = 0.25; % rotation duration 250 ms
end

if nargin < 6 || isempty(rotaAngleMax) == 1
    rotaAngleMax = 90; % maximum angle of rotation (left/right) 90 deg
end

%% initialize variables

cyEndPr1A = stimOnsetBySeq.cyEndPr1A(:);
cyStaRota = stimOnsetBySeq.cyStaRota(:);
cyEndTr = stimOnsetBySeq.cyEndTr(:);

nbCyRotaDur = RR*rotaDur;                                % number of refresh cycles swing
h = ceil(nbCyRotaDur/2);                                 % length of swing 0 >> 90 >> 0
a = round(cos(linspace(-pi/2,pi/2,h))*rotaAngleMax,0)';  % swing function starting/ending 0
dRota = [-1,1];                                          % direction of rotation (-1=left; 1=right)

%% rotate

ang = zeros(nbCyRotaDur,1);
rotaAngBySeq = struct('ang',zeros(nbSeq,1));
for i = 1:nbSeq
    
    % rotation angle
    d1 = dRota(randi(2));       % random direction of rotation
    d2 = d1*(-1);               % rotate in one direction, then the other direction
    if mod(nbCyRotaDur,2) == 0
        ang(:,1) = [a*d1;a*d2];        % even number of ref cy for rotaDur
    else
        ang(:,1) = [a*d1;a(2:end)*d2]; % odd number of ref cy for rotaDur
    end
    
    % rotation angle per refresh cycle
    rotaAng = zeros(cyEndTr(i),1);
    for j = 1:2    % 2 rotations
        if j == 1
            cySta = cyEndPr1A(i); % rota 1 when Anim 1 disappears
        else
            cySta = cyStaRota(i); % rota 2 during FadeOut
        end
        cyEnd = cySta + nbCyRotaDur - 1;   % Matlab starts counting from 1
        rotaAng(cySta:cyEnd,1) = ang(:,1);
    end
    rotaAngBySeq(i).ang = rotaAng;
end