function drawStim(W, STIM, FONT, SIZE, STYLE, COL, SX, SY)
    Screen(W, 'TextFont', FONT);
    Screen(W, 'TextSize', SIZE);
    Screen(W, 'TextStyle', STYLE); % 0 = bold; 1 = normal
    %DrawFormattedText(W, STIM, 'center', 'center', COL);
    
    if nargin < 7
        SX = 'center';
    end
      
    if nargin < 8
        SY = 'center';
    end   

    DrawFormattedText(W, STIM, SX, SY, COL);
end

