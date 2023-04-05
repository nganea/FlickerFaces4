%% clean up workspace
clc;
clearvars;
 
%% read & show image
img = '19F_HA_C';
i1=imread(sprintf('%s.png',img));
figure(1),imshow(i1);
 
%% do 2-dim Fourier Transform of the image & extract magnitude and phase
f1=fft2(i1);
mag1=real(abs(f1)); % extract magnitude %% I took the real component only
phase1 = real(angle(f1)); % extract phase %% I took the real component only
 
%% change the phase
%phase1=exp(normrnd(0,0.5).*phase1); % multiply phase with a random number -0.5 & 0.5, calculate exponential
 
%instead of the above, this is what we specified in the footnote
%phase1=(rand(size(phase1))-0.5)*pi; %if you comment out this line, you should get back the original image
s = randi(2000);
rng(s); % store randomization seed to reproduce the img later
r = randperm(size(phase1,1));
c = randperm(size(phase1,2));
d = randi(3);
phase1 = phase1(r,c,d);

%% reconstruct the image, then apply inverse Fourier Transform
 
ar = mag1.*cos(phase1); %calculate the real component with the new phase
ai = mag1.*sin(phase1); %calculate the imag compnent og the new phase
a3 = complex(ar,ai); %reconstruct the Fourier transform
 
a4=real(ifft2(a3)); %run the inverse transform
figure(2),imshow(uint8(a4))

%% save file with randomization seed number so it can be reproduced

imgNew = sprintf('%s_s%d.png', img, s);
saveas(figure(2),imgNew);