function [seg,initfg] = segment_superpixels_with_softmask(superpixels_stats,softmask_stats,threshold,maxIterations,varargin)
% Segments the image using superpixels, initialized with mask and using mask as location potential.
%
% This is like segment_with_softmask, but:
%   - labels are shared within superpixels (speeds-up optimization by
%   reducing the number of variables, but no big memory benefit per se)
%   - also speeding-up the learning of models, with memory benefits.
%
% arguments:
%   superpixels_stats = output of sp_stats_for_grabcut
%   softmask_stats = superpixel softmask used for initialization
%    (output of sp_maskstat(softmask,superpixel_labels) )
%   threshold = mask threshold for init
%   maxIterations = maximum number of iterations for GrabCut
%
% returns:
%   seg = segmentation as logical vector, same size as initSpMask (one
%   binary value per superpixel). Transform this back to pixel-level
%   segmentation using seg=spseg2seg(superpixel_labels,seg).

% settings
doVisualize = false; % show plots with intermediate results

% output
segs = cell(1,maxIterations+1);
flows = zeros(1,maxIterations+1);
energies = zeros(1,maxIterations+1);
converged = false;

P = superpixels_stats.A;
C = size(P,1);
P(1:C+1:end) = 0; % remove diagonal
Pk = superpixels_stats.K;

if C==1, % in case the image has only one superpixel..
    seg=false;
    return
end


initfg = softmask_stats.median>=threshold; % more than half of the pixels have a mask value above the threshold
if all(~initfg), % make sure at least one positive
    initfg(argmax(softmask_stats.mean)) = true;
end
if all(initfg), % and one negative
    initfg(argmin(softmask_stats.mean)) = false;
end

U_loc = -[softmask_stats.meanlog(:) softmask_stats.mean1mlog(:)];
U_loc = reshape(U_loc,[],1,2);

% initialization
[fgm,bgm] = initializeModelSp(superpixels_stats,initfg);



for i = 1:maxIterations
	
    %	pg_message('iteration %d/%d',i,maxIterations);

    [fgk,bgk] = assignComponentsSp(superpixels_stats,fgm,bgm);
    U_app = getUnarySp_app(superpixels_stats,fgm,bgm,fgk,bgk);
    U_app = -log(U_app);
    U = getWeightedLogUnarySp(superpixels_stats,ones(1,2),U_loc,U_app);
    
    [segs{i},flows(i),energies(i)] = getSegmentationSp(P,U);
	
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
	
    [fgm,bgm] = learnModelSp(superpixels_stats,segs{i},fgm,bgm,fgk,bgk);
	
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



