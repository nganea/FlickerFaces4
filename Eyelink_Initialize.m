% EyeLink eye tracker or "Dummy Mode"
dummymode = 0; % 0 = with Eyelink; 1 = without Eyelink; 

% Set IP address of Eyelink tracker computer
if dummymode == 0
    Eyelink('SetAddress', '10.10.10.5');
end

% Initialize EyeLink connection
EyelinkInit(dummymode);
statusET = Eyelink('IsConnected');
if statusET < 1 % If EyeLink not connected
    warning('Running in dummy mode');
    dummymode = 1;
end

% EyeLink EDF Data file name up to 8 characters
edfFile = strcat(exp,'_', SsID) ; % Save file name to a variable
if length(edfFile) > 8
    fprintf('Filename needs to be no more than 8 characters long (letters, numbers and underscores only)\n');
    error('Filename needs to be no more than 8 characters long (letters, numbers and underscores only)');
end

% Open an EDF file and name it
if statusET == 1 % if we have a live connection to a Host PC
    failOpen = Eyelink('OpenFile', edfFile);
    if failOpen ~= 0 % Abort if it fails to open
        fprintf('Cannot create EDF file %s', edfFile); % Print some text in Matlab's Command Window
        return
    end
end

% Get EyeLink tracker and software version
% <ver> returns 0 if not connected
% <versionstring> returns 'EYELINK I', 'EYELINK II x.xx', 'EYELINK CL x.xx' where 'x.xx' is the software version
ELsoftwareVersion = 0; % Default EyeLink version in dummy mode
[ver, versionstring] = Eyelink('GetTrackerVersion');
if dummymode == 0 % If connected to EyeLink
    [r1, vnumcell] = regexp(versionstring,'.*?(\d)\.\d*?','Match','Tokens'); % Extract EL version before decimal point
    ELsoftwareVersion = str2double(vnumcell{1}{1}); % Returns 1 for EyeLink I, 2 for EyeLink II, 3/4 for EyeLink 1K, 5 for EyeLink 1KPlus, 6 for Portable Duo
    % Print some text in Matlab's Command Window
    fprintf('Running experiment on %s version %d\n', versionstring, ver);
end

% Add a line of text in the EDF file to identify the current experimemt session.
% If your text starts with "RECORDED BY " it will be available in DataViewer's Inspector window by clicking
% the EDF session node in the top panel and looking for the "Recorded By:" field in the bottom panel of the Inspector.
preambleText = sprintf('RECORDED BY Psychtoolbox session: %s', edfFile);
Eyelink('Command', 'add_file_preamble_text "%s"', preambleText);

% See EyeLinkProgrammers Guide manual > Useful EyeLink Commands > File Data Control & Link Data Control
% Select which events are saved in the EDF file. Include everything just in case
Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
% Select which events are available online for gaze-contingent experiments. Include everything just in case
Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,BUTTON,FIXUPDATE,INPUT');
% Select which sample data is saved in EDF file or available online. Include everything just in case
if ELsoftwareVersion > 3  % Check tracker version and include 'HTARGET' to save head target sticker data for supported eye trackers
    Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,RAW,AREA,HTARGET,GAZERES,BUTTON,STATUS,INPUT');
    Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');
else
    Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,RAW,AREA,GAZERES,BUTTON,STATUS,INPUT');
    Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
end

% Calibration

% Provide EyeLink with some defaults, which are returned in the structure "el".
el = EyelinkInitDefaults(w);

% Set calibration/validation/drift-check(or drift-correct) size as well as background and target colors.
% It is important that this background colour is similar to that of the stimuli to prevent large luminance-based
% pupil size changes (which can cause a drift in the eye movement data)

el.backgroundcolour = back;% RGB grey
el.calibrationtargetcolour = fore;% RGB black
el.msgfontcolour = fore;% RGB black; "Camera Setup" instructions text colour

% Set calibration beeps (0 = sound off, 1 = sound on)
el.targetbeep = 0;  % sound a beep when a target is presented
el.feedbackbeep = 0;  % sound a beep after calibration or drift check/correction

% Target static
% el.calibrationtargetsize = 3; % Outer target size as percentage of the screen
% el.calibrationtargetwidth = 0.7;% Inner target size as percentage of the screen

% Required for macOS Catalina users to disable audio
% playback with animated calibration targets, otherwise causing
% freezing during playback.
el.calAnimationOpenSpecialFlags1 = 0; % 2 = most efficient; no sound; See Eyelink_SimpleVideo.m, see Screen('OpenMovie',...,specialFlags1) see http://psychtoolbox.org/docs/Screen-OpenMovie

% Configure animated calibration target path and properties
el.calTargetType = 'video';
calMovieName = ('calibVid.mp4');

el.calAnimationTargetFilename = [pwd '/EyelinkAnimation/' calMovieName];
el.calAnimationResetOnTargetMove = true; % false by default, set to true to rewind/replay video from start every time target moves
el.calAnimationAudioVolume = 0.4; % default volume is 1.0, but too loud on some systems. Setting volume lower to 0.4 (minimum is 0.0)

% Change calibration target for each corner of the screen
el.changeCalAnimation = 1;

% List of calibration targets
el.calAnimationList = {'calibVid.mp4' 'dotsGrey.mp4' 'wheelGrey.mp4'};
el.calAnimationList = strcat('EyelinkAnimation/',a);

% Apply the changes made to the el structure above
EyelinkUpdateDefaults(el);

% Set display coordinates for EyeLink data by entering left, top, right and bottom coordinates in screen pixels
Eyelink('Command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);

% Write DISPLAY_COORDS message to EDF file: sets display coordinates in DataViewer
% See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Pre-trial Message Commands
Eyelink('Message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);

% Set number of calibration/validation dots and spread: horizontal-only(H) or horizontal-vertical(HV) as H3, HV3, HV5, HV9 or HV13
Eyelink('Command', 'calibration_type = HV5'); % horizontal-vertical 9-points

% Allow a supported EyeLink Host PC button box to accept calibration or drift-check/correction targets via button 5
Eyelink('Command', 'button_function 5 "accept_target_fixation"');

% Start listening for keyboard input. Suppress keypresses to Matlab windows.
% ListenChar(-1);

% set sample rate in camera setup screen
Eyelink('Command', 'sample_rate = %d', 500); % same as NetSation sampling rate

% Clear Host PC display from any previus drawing
Eyelink('Command', 'clear_screen 0');

% Put EyeLink Host PC in Camera Setup mode for participant setup/calibration
EyelinkDoTrackerSetup(el,'c'); % to go into calibration mode directly, set el.callback = []; otherwise  it will show you the normal text

