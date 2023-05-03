function [TT_Markup, TT_FlipDiag, TT_FixAll, err] = FlickerFaces_Proc(s)

% default
if nargin < 1 || isempty(s) == 1
    s = 1;
end

% some participants had different DIN rate
nbDinPerTr = 10;    % 21 DINs during the trial
DIN2 = 2;           % Covert Att ep 2s DIN2
DIN6 = 6;           % Overt Att ep 2s DIN6
dinDiff = 834;      % ms; time diff between DINs 833.6 ms

% run functions
[TT_FlipDiag] = FlickerFaces_Proc_FlipDiag(s, [], nbDinPerTr, DIN2, DIN6);
WaitSecs(1);
[TT_FixAll, err] = FlickerFaces_Proc_GazeData(s);
WaitSecs(1);
[TT_Markup] = FlickerFaces_Proc_EGImarkup(s, [], [], [], [],...
    dinDiff);

% notification
fprintf('FF2_%d done\n',s);

end
