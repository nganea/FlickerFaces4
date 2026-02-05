FlickerFaces.m is the main script. It calls on all the other scripts and functions. 
FlickerFaces_Practice.m goes through the study instructions and 6 practice trials. 

Study records eye movements and SSVEP/EEG response when participants pay attention to something. 

Participant's Task:
Look at the Face in the centre of the screen, but attend to the Cartoon in the periphery. When the cartoon swings, press the Spacebar. 
Continue to look at the Face and pay attention to the Face. When the Face swings, press the Spacebar again. 

The Face image flickers, and the Cartoon image is static.

Participants attend to the peripheral img = NoAtt epoch.
Participants attend to the central img = Att epoch.

After each epoch, the Face/Cartoon moves for 500 ms. Motion onset is jittered (can be either 83 ms or 333 ms after NoAtt/Att epoch ends).  

The study is divided into 2 blocks. The user can make the Face flicker at different frequencies in each block, or can intermix trials.

The peripheral cartoon appears half of the time on the Left side of the screen, and half on the time on the Right side.

Created by Natasa Ganea, 2023, Haskins Laboratories, natasa.ganea@gmail.com
