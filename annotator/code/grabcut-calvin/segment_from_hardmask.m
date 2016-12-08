function seg = segment_from_hardmask(image,initMask,constrainToInit,maxIterations)
% Segments the image using a mask to initialize and contrain the segmentation.
%
% arguments:
%   image = rgb uint8 image
%   mask = binary image (same size as image)
%   constrainToInit = true/false
%   maxIterations = maximum number of iterations for GrabCut
%
% returns:
%   seg = segmentation as logical image

% settings
doMorph = false; % apply morphological operations at the end (as in original GrabCut)
doVisualize = false; % show plots with intermediate results

% output
segs = cell(1,maxIterations+1);
flows = zeros(1,maxIterations+1);
energies = zeros(1,maxIterations+1);
converged = false;

% initialization
[img,h,w] = getImage(image);
[P,Pk] = getPairwise(img);
initseg = initMask; % use grabcut and initialize with full box.
[fgm,bgm] = initializeModel(img,initseg);
U_mask = ones(h*w,2);
if constrainToInit,
    U_mask(~initMask,1) = exp(-Pk);
end
U_mask = reshape(U_mask,h,w,2);

for i = 1:maxIterations
	
%	pg_message('iteration %d/%d',i,maxIterations);

	[fgk,bgk] = assignComponents(img,fgm,bgm);
	U_app = getUnary_app(img,fgm,bgm,fgk,bgk);
    U = getLogUnary(U_app,U_mask);
	[segs{i},flows(i),energies(i)] = getSegmentation(P,U,w,h);
	
%	pg_message('flow = %g, energy = %g',flows(i),energies(i));
	
	% TODO assert energy/flow decrease

	if doVisualize
		visualize(img,mask,initseg,segs{i},i,energies(1:i));
	end;

	if i>1 && all(segs{i-1}(:)==segs{i}(:))
%		pg_message('converged after %d/%d iterations',i,maxIterations);
		converged = true;
		break;
	end;
	
	[fgm,bgm] = learnModel(img,segs{i},fgm,bgm,fgk,bgk);
	
end;

if ~converged
%	pg_message('did not converge after %d iterations',maxIterations);
% 	fprintf('did not converge after %d iterations\n',maxIterations);
end;

segs = segs(1:i);
flows = flows(1:i);
energies = energies(1:i);

seg = segs{end};
energy = energies(end);

if doMorph
	seg = applyMorph(seg);
	if doVisualize
		visualize(img,mask,threshold,boxes,seg,energies);
	end;
end;



function visualize(img,mask,initseg,seg,iteration,energies)

clf();

subplot2d(5,1,1,1);
plot_image(img,'image');

subplot2d(5,2,2,1);
plot_image(mask,'prior');

subplot2d(5,2,2,2);
plot_image(initseg,'init');

subplot2d(5,1,3,1);
plot_image(img.*repmat(double(seg),[1 1 3]),'foreground');

subplot2d(5,1,4,1);
plot_image(seg,'segmentation');

subplot2d(5,1,5,1);
plot(energies);
title('convergence');
ylabel('energy');
xlabel('iteration');

drawnow();


function seg = applyMorph(seg)

seg = imclose(seg,strel('disk',3));
seg = imfill(seg,'holes');
seg = bwmorph(seg,'open'); % remove thin regions
[~,N] = bwlabel(seg); % select largest 8-connected region
h = hist(seg(:),1:N);
[~,i] = max(h);
seg = seg==i;

function plot_image(im,varargin)
imshow(im,[]);
