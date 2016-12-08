function [seg,initfg] = segment_superpixels_from_windows(superpixel_labels,superpixels_stats,initWindows,varargin)
% Segments the image using superpixels, initialized with user provided fb/bg.
%
% This is like segment_from_windows, but:
%   - labels are shared within superpixels (speeds-up optimization by
%   reducing the number of variables, but no big memory benefit per se)
%   - also speeding-up the learning of models, with memory benefits.
%
% arguments:
%   superpixels_labels = output of sp_pff or other superpixel segmentation
%   superpixels_stats = output of sp_stat_for_grabcut applied on superpixels_labels
%   initWindows = N-by-4 matrix with windows
%   constrainToInit = forbid segmentation to go beyong the initialization
%   maxIterations = maximum number of iterations for GrabCut
%
% returns:
%   seg = segmentation as logical vector, same size as initSpMask (one
%   binary value per superpixel). Transform this back to pixel-level
%   segmentation using seg=spseg2seg(superpixel_labels,seg).
%
% arguments:
%   maxIterations = maximum number of iterations for GrabCut
%   doSuperpixelsSpeedUp = false=>mode(a), true=>mode(b)
%   img,sp = image and superpixel images. needed for mode (a) and vizualization
%
% returns:
%   seg = segmentation as logical vector, same size as number of superpixels

spmaskstat = sp_window2spmask(superpixel_labels,initWindows);
initfg = spmaskstat.mean==1; % those superpixel with 100% of pixels inside the window are used for initiallization

assert(any(initfg) && any(~initfg));

seg = segment_superpixels_from_hardmask(superpixels_stats,initfg,varargin{:});