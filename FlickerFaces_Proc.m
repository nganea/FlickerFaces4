function [TT_Markup, TT_FlipDiag, TT_FixAll, err] = FlickerFaces_Proc(s)

% default
if nargin < 1 || isempty(s) == 1
    s = 1;
end

% some participants had different DIN rate
if s <= 0 
    nbDinPerTr = 11;    % 11 DINs during the trial
    DIN2 = 2;           % Covert Att ep 2s DIN2:DIN5 
    DIN7 = 7;           % Overt Att ep 2s DIN7:DIN10 
    dinDiff = 667;      % ms; time diff between DINs 667 ms
else
    nbDinPerTr = 21;    % 21 DINs during the trial
    DIN2 = 3;           % Covert Att ep 2s DIN3:DIN9 
    DIN7 = 13;          % Overt Att ep 2s DIN13:DIN19 
    dinDiff = 333;      % ms; time diff between DINs 333 ms
end

% run functions
[TT_FlipDiag] = FlickerFaces_Proc_FlipDiag(s, [], nbDinPerTr, DIN2, DIN7);
WaitSecs(1);
[TT_FixAll, err] = FlickerFaces_Proc_GazeData(s);
WaitSecs(1);
[TT_Markup] = FlickerFaces_Proc_EGImarkup(s, [], [], [], [],...
    dinDiff);

% notification
fprintf('FF2_%d done\n',s);

end
