Eyelink('SetOfflineMode'); % Put tracker in idle/offline mode
Eyelink('Command', 'clear_screen 0'); % Clear Host PC backdrop graphics at the end of the experiment
WaitSecs(0.1); % Allow some time before closing and transferring file
Eyelink('CloseFile'); % Close EDF file on Host PC
[statusET, errorET] = Eyelink_TransferFile(w, height,...
    back, dummymode, edfFile, root); % Transfer a copy of the EDF file to Display PC
Eyelink('Shutdown'); % Close EyeLink connection


function [status, error] = Eyelink_TransferFile(w, height, back, dummymode,...
    edfFile, root)
% Function for transferring copy of EDF file to the experiment folder on Display PC.
% Allows for optional destination path which is different from experiment folder

% if EXPWIN window is omitted or empty
if nargin < 1 || isempty(w)
    trialTest = 1;
    Screen('Preference','SkipSyncTests',0);
    screens = Screen('Screens');
    screenNum = max(screens);
    PsychDebugWindowConfiguration(0,0.5); % type "clear all" in the CmdWindow
    [w, wSz] = Screen('OpenWindow', screenNum);
    Screen('FillRect', w, [255 255 255]);
    Screen('Flip', w, [], 1);
else
    trialTest = 0;
end

% if EXPWINsize is omitted or empty
if nargin < 2 || isempty(height)
    if isempty(wSz)
        wSz = [0, 0, 800, 600];
        height = wSz(1,4);
    end
end

% if EXPWINcolour is omitted or empty
if nargin < 3 || isempty(back)
    back = [128 128 128]; % black (helps with photodiode)
end

if nargin < 4 || isempty(dummymode)
    dummymode = 1; % use dummy mode
end

if nargin < 5 || isempty(edfFile)
    edfFile = []; % leave this variable empty if no value provides
end

if nargin < 6 || isempty(root)
    root = pwd;
end

try
    if dummymode == 0 % If connected to EyeLink
        % Show 'Receiving data file...' text until file transfer is complete
        Screen('FillRect', w, back); % Prepare background on backbuffer
        Screen(w, 'TextSize', 50);
        Screen('DrawText', w, 'Receiving data file...', 5, height-150, 0); % Prepare text
        Screen('Flip', w); % Present text
        fprintf('Receiving data file ''%s.edf''\n', edfFile); % Print some text in Matlab's Command Window
        
        % Transfer EDF file to Host PC
        % [status =] Eyelink('ReceiveFile',['src'], ['dest'], ['dest_is_path'])
        status = Eyelink('ReceiveFile');
        % Optionally uncomment below to change edf file name when a copy is transferred to the Display PC
        % % If <src> is omitted, tracker will send last opened data file.
        % % If <dest> is omitted, creates local file with source file name.
        % % Else, creates file using <dest> as name.  If <dest_is_path> is supplied and non-zero
        % % uses source file name but adds <dest> as directory path.
        % newName = ['Test_',char(datetime('now','TimeZone','local','Format','y_M_d_HH_mm')),'.edf'];
        % status = Eyelink('ReceiveFile', [], newName, 0);
        
        % Check if EDF file has been transferred successfully and print file size in Matlab's Command Window
        if status > 0
            fprintf('EDF file size: %.1f KB\n', status/1024); % Divide file size by 1024 to convert bytes to KB
        end
        % Print transferred EDF file path in Matlab's Command Window
        error = fprintf('Data file ''%s.edf'' can be found in ''%s''\n', edfFile, root);
    else
        error = fprintf('No EDF file saved in Dummy mode\n');
    end
catch % Catch a file-transfer error and print some text in Matlab's Command Window
    error = fprintf('Problem receiving data file ''%s''\n', edfFile);
    psychrethrow(psychlasterror);
end

if trialTest == 1
    Screen('CloaseAll');
end

end
