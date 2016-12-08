close all;
clear;

run ../matlabtools-calvin/setup.m % adapt this line to your installation of matlabtools

image = imread('000013.jpg');
mask = im2double(rgb2gray(imread('000013_softmask.png'))); % a really stupid mask. replace this with an actual mask from segmentation transfer in the future.
threshold = 0.2;
maxiter = 3;


fprintf('Starting pixel-level GrabCut+location\n');
tt=tic;
seg = segment_with_softmask(image,mask,threshold,maxiter);
fprintf('GrabCut done in %fs\n',toc(tt));

figure;
subplot(2,2,1);
imshow(image,[]);
title('image');
subplot(2,2,2);
imshow(mask,[]);
title('mask');
subplot(2,2,3);
imshow(mask>=threshold,[]);
title('init');
subplot(2,2,4);
img = im2double(image);
img = bsxfun(@times,img,seg);
imshow(img,[]);
drawWindows(window);
title('converged');





fprintf('Pre-computing for superpixel-GrabCut\n');
tt=tic;
splabels = sp_pff(image,'k',10,'sigma',0.2,'minsize',50);
spstats  = sp_stats_for_grabcut(image,splabels);
maskstat = sp_maskstat(mask,splabels);
fprintf('done in %fs\n',toc(tt));

figure();
subplot(2,2,1);
imshow(image,[]);
title('original image');
subplot(2,2,2);
imshow(mask,[]);
title('original mask');
subplot(2,2,3);
imshow(label2image(splabels,'render','averagecolor','img',image),[]);
title('superpixels, render=averagecolor');
subplot(2,2,4);
imshow(spseg2seg(splabels,maskstat.mean),[]);
title('superpixels, average mask value');






fprintf('Starting superpixel-GrabCut with softmask\n');
tt=tic;
[seg,initseg] = segment_superpixels_with_softmask(spstats,maskstat,threshold,maxiter);
fprintf('superpixel-GrabCut done in %fs\n',toc(tt));
seg = spseg2seg(splabels,seg); % go back to pixel-level segmentation

figure();
subplot(2,2,1);
imshow(label2image(splabels,'render','averagecolor','img',image),[]);
title('superpixel image');
subplot(2,2,2);
imshow(spseg2seg(splabels,initseg),[]);
title('superpixel initialization');
subplot(2,2,3);
imshow(seg,[]);
title('converged');
subplot(2,2,4);
img = im2double(image);
img = bsxfun(@times,img,seg);
imshow(img,[]);
title('object');

