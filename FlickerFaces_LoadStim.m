function [stim] = FlickerFaces_LoadStim(path)
%% load images .PNG_______________________________________________________________________

% cancel loading if no path given
if nargin < 1 || isempty(path) == 1
    disp('No path entered. Loading stimuli cancelled.')
    return
end

% read directory
DD = dir(path);

% count files in the directory
DDlength = 0;
for i = 1:length(DD)
    if ~strcmp(DD(i).name(1),'.')    
        DDlength = DDlength + 1;     
    end
end

% create stucture to store stimuli
stim = struct('name', cell(1, DDlength),...   % field: filename
    'stim', cell(1, DDlength),...                    % field: loaded stimuli
    'alpha', cell(1,DDlength));

% go through the directory
count = 0;
for j = 1:length(DD)
    
    % read filename & file extension
    largename = DD(j).name;                                          % read filename
    [~, ~, ext] = fileparts(fullfile(path,largename));      % read file extension
    
    % store filename & load stimuli if file valid
    if (strcmp(ext, '.png')) && ~(strcmp(largename(1),'.'))  
        count = count + 1;
        stim(count).name = largename;                           % store filename
        [stim(count).stim,~,stim(count).alpha] = imread(fullfile(path,largename));    % load stimuli   
    end
end
stim = stim(1:count);

clear -vars count DD DDlength ext i j largename name path pathstr

end

