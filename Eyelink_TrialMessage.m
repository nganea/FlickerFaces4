% Draw boxes to EDF file
if nbPerifStim > 0
    Eyelink('Message', '!V DRAWBOX %d %d %d %d %d %d %d',... % Draw Black box for Cloud for the EDF file
        0, 0, 0,...                                     % colour RGB black = [0 0 0]
        rectAnim(ss).rect(1), rectAnim(ss).rect(2),...  % top left corner
        rectAnim(ss).rect(3), rectAnim(ss).rect(4));    % bottom right corner
end

if nbPerifStim == 2
    Eyelink('Message', '!V DRAWBOX %d %d %d %d %d %d %d',... % Draw Blue box for Fq Disc for the EDF file
        0, 0, 255,...                                   % colour RGB blue = [0 0 255]
        rectFace(ss).rect(1,1), rectFace(ss).rect(2,1),...
        rectFace(ss).rect(3,1), rectFace(ss).rect(4,1));
    Eyelink('Message', '!V DRAWBOX %d %d %d %d %d %d %d',... % Draw Green box for Fq2 Disc for the EDF file
        0, 255, 0,...                                   % colour RGB green = [0 255 0]
        rectFace(ss).rect(1,2), rectFace(ss).rect(2,2),...
        rectFace(ss).rect(3,2), rectFace(ss).rect(4,2));
else
    if iAlpha == 1
        Eyelink('Message', '!V DRAWBOX %d %d %d %d %d %d %d',... % Draw Blue box for Fq Disc for the EDF file
            0, 0, 255,...                                   % colour RGB blue = [0 0 255]
            rectFace(ss).rect(1), rectFace(ss).rect(2),...
            rectFace(ss).rect(3), rectFace(ss).rect(4));
    elseif iAlpha == 2
        Eyelink('Message', '!V DRAWBOX %d %d %d %d %d %d %d',... % Draw Green box for Fq2 Disc for the EDF file
            0, 255, 0,...                                   % colour RGB green = [0 255 0]
            rectFace(ss).rect(1), rectFace(ss).rect(2),...
            rectFace(ss).rect(3), rectFace(ss).rect(4));
    end
end

% Allow time between messages to the EDF file
WaitSecs(0.001);

% Draw AOIs to EDF file
if nbPerifStim > 0
    Eyelink('Message', '!V IAREA RECTANGLE 1 %d %d %d %d Cloud',... % AOI_1 Cloud for the EDF file
        rectAnim(ss).rect(1), rectAnim(ss).rect(2),...
        rectAnim(ss).rect(3), rectAnim(ss).rect(4));
end

if nbPerifStim == 2
    Eyelink('Message', '!V IAREA RECTANGLE 2 %d %d %d %d DiscFq',... % AOI_2 DiscFq for the EDF file
        rectFace(ss).rect(1,1), rectFace(ss).rect(2,1),...
        rectFace(ss).rect(3,1), rectFace(ss).rect(4,1));
    Eyelink('Message', '!V IAREA RECTANGLE 3 %d %d %d %d DiscFq2',... % AOI_3 DiscFq2 for the EDF file
        rectFace(ss).rect(1,2), rectFace(ss).rect(2,2),...
        rectFace(ss).rect(3,2), rectFace(ss).rect(4,2));
else
    if iAlpha == 1
        Eyelink('Message', '!V IAREA RECTANGLE 2 %d %d %d %d DiscFq',... % AOI_2 DiscFq for the EDF file
            rectFace(ss).rect(1), rectFace(ss).rect(2),...
            rectFace(ss).rect(3), rectFace(ss).rect(4));
    elseif iAlpha == 2
        Eyelink('Message', '!V IAREA RECTANGLE 3 %d %d %d %d DiscFq2',... % AOI_3 DiscFq2 for the EDF file
            rectFace(ss).rect(1), rectFace(ss).rect(2),...
            rectFace(ss).rect(3), rectFace(ss).rect(4));
    end
end

% Allow time between messages to the EDF file
WaitSecs(0.001);