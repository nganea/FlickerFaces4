%% Drift check/correction

% drift check/correction videos
driftVidList = {'calibVid.mp4' 'dotsGrey.mp4' 'wheelGrey.mp4'};% Provide drift-check video file list for 2 trials

% Change animated calibration target path for drift-check/correction
driftVidID = randi(length(driftVidList));
calMovieName = char(driftVidList(driftVidID));
el.calAnimationTargetFilename = [pwd '/EyelinkAnimation/' calMovieName];

% You must call this function to apply the changes made to the el structure above
EyelinkUpdateDefaults(el);

% Perform a drift check/correction (screen centre)
EyelinkDoDriftCorrection(el,round(width/2), round(height/2));

%% Message to EDF file

% Write TRIALID message to EDF file: marks the start of a trial for DataViewer
% See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Defining the Start and End of a Trial
Eyelink('Message', 'TRIALID %d', ss);
% Write !V CLEAR message to EDF file: creates blank backdrop for DataViewer
% See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Simple Drawing
Eyelink('Message', '!V CLEAR %d %d %d', back(1), back(2), back(3));

%% Draw on EyeLink Host PC

% Draw graphics on the EyeLink Host PC display. See COMMANDS.INI in the Host PC's exe folder for a list of commands
% Supply the trial number as a line of text on Host PC screen
Eyelink('Command', 'record_status_message "TRIAL %d/%d"', ss, nbSeq);

Eyelink('SetOfflineMode');% Put tracker in idle/offline mode before drawing Host PC graphics and before recording

Eyelink('Command', 'clear_screen 8'); % Clear Host PC display (Gray) from any previus drawing

% peripheral stim
if nbPerifStim > 0
    Eyelink('Command', 'draw_box %d %d %d %d 0',... % Draw box (Black) on the Host PC for the Cloud
        rectAnim(ss).rect(1), rectAnim(ss).rect(2),...  % top left corner
        rectAnim(ss).rect(3), rectAnim(ss).rect(4));    % bottom right corner
end

% central stim flickering
if nbPerifStim == 2           % 2 flickers
    Eyelink('Command', 'draw_box %d %d %d %d 1', ... % Draw box (Blue) on the Host PC for the Fq
        rectFace(ss).rect(1,1), rectFace(ss).rect(2,1),...
        rectFace(ss).rect(3,1), rectFace(ss).rect(4,1));
    Eyelink('Command', 'draw_box %d %d %d %d 2', ... % Draw box (Green) on the Host PC for the Fq2
        rectFace(ss).rect(1,2), rectFace(ss).rect(2,2),...
        rectFace(ss).rect(3,2), rectFace(ss).rect(4,2));
else                          % 1 flicker
    if iAlpha == 1 % fq
        Eyelink('Command', 'draw_box %d %d %d %d 1', ... % Draw box (Blue) on the Host PC for the Fq
            rectFace(ss).rect(1), rectFace(ss).rect(2),...
            rectFace(ss).rect(3), rectFace(ss).rect(4));
    elseif iAlpha == 2 % fq2
        Eyelink('Command', 'draw_box %d %d %d %d 2', ... % Draw box (Green) on the Host PC for the Fq2
            rectFace(ss).rect(1), rectFace(ss).rect(2),...
            rectFace(ss).rect(3), rectFace(ss).rect(4));
    end
end

%% Start recording

Eyelink('SetOfflineMode');% Put tracker in idle/offline mode before drawing Host PC graphics and before recording
Eyelink('StartRecording'); % Start tracker recording
WaitSecs(0.1); % Allow some time to record a few samples before presenting first stimulus