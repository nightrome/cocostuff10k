function seg = segment_superpixels_from_hardmask(superpixels_stats,initSpMask,constrainToInit,maxIterations,varargin)
% Segments the image using superpixels, initialized with user provided fb/bg.
%
% This is like segment_from_hardmask, but:
%   - labels are shared within superpixels (speeds-up optimization by
%   reducing the number of variables, but no big memory benefit per se)
%   - also speeding-up the learning of models, with memory benefits.
%
% arguments:
%   superpixels_stats = output of sp_stats_for_grabcut
%   initSpMask = boolean vector indicating which superpixels are used as init fg
%   constrainToInit = forbid segmentation to go beyong the initialization
%   maxIterations = maximum number of iterations for GrabCut
%
% returns:
%   seg = segmentation as logical vector, same size as initSpMask (one
%   binary value per superpixel). Transform this back to pixel-level
%   segmentation using seg=spseg2seg(superpixel_labels,seg).

% settings
doVisualize = false; % show plots with intermediate results
doSuperpixelsSpeedUp = true;

assert(any(initSpMask) && any(~initSpMask));

% output
segs = cell(1,maxIterations+1);
flows = zeros(1,maxIterations+1);
energies = zeros(1,maxIterations+1);
converged = false;

P = superpixels_stats.A;
C = size(P,1);
P(1:C+1:end) = 0; % remove diagonal
Pk = superpixels_stats.K;

U_mask = ones(C,1,2);
if constrainToInit,
    U_mask(~initSpMask,1) = exp(-Pk);
end

% initialization
if doSuperpixelsSpeedUp,
    
%     fprintf('Using superpixel speed-up\n');
    superpixels_stats.n = double(superpixels_stats.n);
    %superpixels_stats.mu = bsxfun(@rdivide,superpixels_stats.sum,superpixels_stats.n);
    [fgm,bgm] = initializeModelSp(superpixels_stats,initSpMask);
    
else
    
%     fprintf('Using only superpixel label sharing\n');
    img = varargin{1};
    sp = varargin{2};
    [img,h,w] = getImage(img);
    [fgm,bgm] = initializeModel(img,spseg2seg(sp,initSpMask)); % learn the model using all the pixels
    U_mask_tmp = spseg2seg(sp,U_mask(:,1,1));
    U_mask_tmp(:,:,2) = spseg2seg(sp,U_mask(:,1,2));
    U_mask = U_mask_tmp;
    
end

for i = 1:maxIterations
	
    %	pg_message('iteration %d/%d',i,maxIterations);

    if doSuperpixelsSpeedUp,
        
        [fgk,bgk] = assignComponentsSp(superpixels_stats,fgm,bgm);
        U_app = getUnarySp_app(superpixels_stats,fgm,bgm,fgk,bgk);
        U = getLogUnarySp(superpixels_stats,U_app,U_mask);
        [segs{i},flows(i),energies(i)] = getSegmentationSp(P,U);
        
    else
        
        [fgk,bgk] = assignComponents(img,fgm,bgm); % assign components
        U_app = getUnary_app(img,fgm,bgm,fgk,bgk);
        U = getLogUnary(U_app,U_mask);
        V = getUnarySpFromUnary(U,sp,C); % collect unaries inside each superpixel. do this after log!
        [segs{i},flows(i),energies(i)] = getSegmentationSp(P,V);
        
    end
	
    %	pg_message('flow = %g, energy = %g',flows(i),energies(i));
	
	% TODO assert energy/flow decrease

 	if doVisualize
        visualizeSp(img,sp,initfg,segs{i},i,energies(1:i));
 	end;

	if i>1 && all(segs{i-1}(:)==segs{i}(:))
%		pg_message('converged after %d/%d iterations',i,maxIterations);
		converged = true;
		break;
	end;
	
    if doSuperpixelsSpeedUp,
        [fgm,bgm] = learnModelSp(superpixels_stats,segs{i},fgm,bgm,fgk,bgk);
    else
        pix_seg = spseg2seg(sp,segs{i});
        [fgm,bgm] = learnModel(img,pix_seg,fgm,bgm,fgk,bgk);
    end
	
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

