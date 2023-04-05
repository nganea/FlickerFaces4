Eyelink('SetOfflineMode'); % Put tracker in idle/offline mode
Eyelink('Command', 'clear_screen 0'); % Clear Host PC backdrop graphics at the end of the experiment
WaitSecs(0.1); % Allow some time before closing and transferring file
Eyelink('CloseFile'); % Close EDF file on Host PC
[statusET, errorET] = Eyelink_TransferFile(w, height,...
    back, dummymode, edfFile, root); % Transfer a copy of the EDF file to Display PC
Eyelink('Shutdown'); % Close EyeLink connection