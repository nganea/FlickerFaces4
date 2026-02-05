
% Write !V CLEAR message to EDF file: creates blank backdrop for DataViewer
Eyelink('Message', '!V CLEAR %d %d %d', back(1), back(2), back(3));

% Stop recording eye movements at the end of each trial
WaitSecs(0.1); % Add 100 msec of data to catch final events before stopping
Eyelink('StopRecording'); % Stop tracker recording

% Write !V TRIAL_VAR messages to EDF file: creates trial variables in DataViewer
Eyelink('Message', '!V TRIAL_VAR trial %d', ss); % Trial number
Eyelink('Message', '!V TRIAL_VAR fqId %d', trTyBySeq.trTyFq(ss)); % Fq id (0 = [fq, fq2]; 1 = fq; 2 = fq2);
Eyelink('Message', '!V TRIAL_VAR fqLoc %s', fqLoc{ss,1}); % Fq disc location (Left or Right)
Eyelink('Message', '!V TRIAL_VAR fqFace %d', trTyBySeq.fqFace(ss)); % Fq face type (odd nr = face; even nr = noise)
Eyelink('Message', '!V TRIAL_VAR cueFq %d', trTyBySeq.cueFq(ss)); % flicker cued (1 = fq1; 2 = fq2)
Eyelink('Message', '!V TRIAL_VAR fqEcc %d', fqEcc(ss,1)); % Fq eccentricity (5cm, 10cm);
Eyelink('Message', '!V TRIAL_VAR nbPrs %d', trTyBySeq.nbPrs(ss)); % Cloud-Animal pairs (1 or 2)
Eyelink('Message', '!V TRIAL_VAR trDog %d', trTyBySeq.trTyDog(ss)); % Dog (0 or 1)

% Allow time between messages to the EDF file
WaitSecs(0.001);

% Write TRIAL_RESULT message to EDF file: marks the end of a trial for DataViewer
Eyelink('Message', 'TRIAL_RESULT 0');
WaitSecs(0.001); % Allow some time before ending the trial
