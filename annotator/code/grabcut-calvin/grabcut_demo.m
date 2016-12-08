close all;
clear;

run ../matlabtools-calvin/setup.m % adapt this line to your installation of matlabtools

image = imread('000013.jpg');
constrain = true;
maxiter = 3;


% Grabcut from a single window (very good one actually)

window = [293.0000  156.0000 451.0000  260.000];

fprintf('Starting GrabCut\n');
tt=tic;
seg = segment_from_windows(image,window,constrain,maxiter);
fprintf('GrabCut done in %fs\n',toc(tt));

figure;
subplot(2,2,1);
imshow(image,[]);
drawWindows(window);
title('image');
subplot(2,2,2);
imshow(maskFromWindows(size(image,1),size(image,2),window),[]);
drawWindows(window);
title('init from window');
subplot(2,2,3);
imshow(seg,[]);
drawWindows(window);
title('converged');
subplot(2,2,4);
img = im2double(image);
img = bsxfun(@times,img,seg);
imshow(img,[]);
drawWindows(window);
title('object');



% Grabcut from a centered window

init_frac = 0.5; % 50% of surface.

fprintf('Starting GrabCut\n');
tt=tic;
seg = segment_from_center(image,init_frac,constrain,maxiter);
fprintf('GrabCut done in %fs\n',toc(tt));

window2 = windowFromCenter(size(image,1),size(image,2),sqrt(init_frac));

figure;
subplot(2,2,1);
imshow(image,[]);
drawWindows(window2);
title('image');
subplot(2,2,2);
imshow(maskFromWindows(size(image,1),size(image,2),window2),[]);
drawWindows(window2);
title('init from center');
subplot(2,2,3);
imshow(seg,[]);
drawWindows(window2);
title('converged');
subplot(2,2,4);
img = im2double(image);
img = bsxfun(@times,img,seg);
imshow(img,[]);
drawWindows(window2);
title('object');


% Grabcut for superpixels

fprintf('Pre-computing for superpixel-GrabCut\n');
tt=tic;
splabels = sp_pff(image,'k',10,'sigma',0.2,'minsize',50);
spstats  = sp_stats_for_grabcut(image,splabels);
fprintf('done in %fs\n',toc(tt));

figure();
subplot(2,2,1);
imshow(image,[]);
title('original image');
subplot(2,2,2);
imshow(label2image(splabels,'render','blend','img',image),[]);
title('superpixels, render=blend');
subplot(2,2,3);
imshow(label2image(splabels,'render','thinborder','img',image),[]);
title('superpixels, render=thinborder');
subplot(2,2,4);
imshow(label2image(splabels,'render','averagecolor','img',image),[]);
title('superpixels, render=averagecolor');


fprintf('Starting superpixel-GrabCut\n');
tt=tic;
[seg,initseg] = segment_superpixels_from_windows(splabels,spstats,window,constrain,maxiter);
fprintf('superpixel-GrabCut done in %fs\n',toc(tt));
seg = spseg2seg(splabels,seg); % go back to pixel-level segmentation

figure();
subplot(2,2,1);
imshow(label2image(splabels,'render','averagecolor','img',image),[]);
drawWindows(window);
title('superpixel image');
subplot(2,2,2);
imshow(spseg2seg(splabels,initseg),[]);
drawWindows(window);
title('superpixel initialization');
subplot(2,2,3);
imshow(seg,[]);
drawWindows(window);
title('converged');
subplot(2,2,4);
img = im2double(image);
img = bsxfun(@times,img,seg);
imshow(img,[]);
drawWindows(window);
title('object');




fprintf('Starting superpixel-GrabCut\n');
tt=tic;
[seg,initseg] = segment_superpixels_from_windows(splabels,spstats,window2,constrain,maxiter);
fprintf('superpixel-GrabCut done in %fs\n',toc(tt));
seg = spseg2seg(splabels,seg); % go back to pixel-level segmentation

figure();
subplot(2,2,1);
imshow(label2image(splabels,'render','averagecolor','img',image),[]);
drawWindows(window2);
title('superpixel image');
subplot(2,2,2);
imshow(spseg2seg(splabels,initseg),[]);
drawWindows(window2);
title('superpixel initialization');
subplot(2,2,3);
imshow(seg,[]);
drawWindows(window2);
title('converged');
subplot(2,2,4);
img = im2double(image);
img = bsxfun(@times,img,seg);
imshow(img,[]);
drawWindows(window2);
title('object');





