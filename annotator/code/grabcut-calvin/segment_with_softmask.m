function seg = segment_with_softmask(image,softmask,threshold,maxIterations)
% Segments the image, initialized with mask and using mask as location potential.
%
% arguments:
%   image = rgb uint8 image, or cell of ~
%   mask = transfer mask, or cell of ~, doesn't have to be the same size as the image(s)
%   threshold = threshold on the mask to initialize fg/bg appearance models
%   maxIterations = maximum number of iterations for GrabCut
%
% returns:
%   seg = segmentation as logical image, or cell of ~, same size as image(s)


% settings
doMorph = false; % apply morphological operations at the end (as in original GrabCut)
doVisualize = false; % show plots with intermediate results

mask = double(softmask);
if size(image,1)~=size(mask,1) || size(image,2)~=size(mask,2)
	mask = img_resize(mask,[size(image,1) size(image,2)]);
end;

% output
segs = cell(1,maxIterations+1);
flows = zeros(1,maxIterations+1);
energies = zeros(1,maxIterations+1);
converged = false;

% initialization
[img,h,w] = getImage(image);
[P,Pk] = getPairwise(img);
try
    assert(~isconstant(im2double(rgb2gray(img))));
    [fgm,bgm] = initializeModel(img,mask>=threshold);
catch e
    fprintf('CONSTANT IMAGE OR ERROR INITIALIZING THE MODEL\n');
    seg = false(size(mask));
    return
end
U_loc = cat(3,mask,1-mask);

for i = 1:maxIterations
	
%	pg_message('iteration %d/%d',i,maxIterations);

	[fgk,bgk] = assignComponents(img,fgm,bgm);
	U_app = getUnary_app(img,fgm,bgm,fgk,bgk);
	U = getLogUnary(U_loc,U_app);

	[segs{i},flows(i),energies(i)] = getSegmentation(P,U,w,h);
	
%	pg_message('flow = %g, energy = %g',flows(i),energies(i));
	
	% TODO assert energy/flow decrease

	if doVisualize
		visualize(img,mask,threshold,segs{i},i,energies(1:i));
	end;

	if i>1 && all(segs{i-1}(:)==segs{i}(:))
%		pg_message('converged after %d/%d iterations',i,maxIterations);
		converged = true;
		break;
	end;
	
	[fgm,bgm] = learnModel(img,segs{i},fgm,bgm,fgk,bgk);
	
end;

% if ~converged
%	pg_message('did not converge after %d iterations',maxIterations);
% 	fprintf('did not converge after %d iterations\n',maxIterations);
% end;

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

