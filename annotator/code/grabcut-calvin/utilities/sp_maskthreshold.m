function seg = sp_maskthreshold(mask,labels,threshold)
% stat = sp_maskthreshold(mask,superpixels,threshold)
%
% Compute, for superpixels, if at least half of the pixels are above the
% given threshold
%
% INPUTS:
% mask: the input mask (1-channel image, ie matrix)
% superpixels: a superpixel segmentation (HxW)
% threshold: double value.
%

assert(ismatrix(mask));
assert(ismatrix(labels));
assert(isscalar(threshold));

mask=double(mask);
if any(size(mask)~=size(labels)),
    mask = imresize(mask,size(labels),'nearest');
end
if max(mask(:))<1 && max(mask(:))>0,
    mask = mask./max(mask(:));
end
mask = double(mask>=threshold);
labels = double(labels);

lbl_pos = full(sum(sparseFromLabels(double(labels),max(labels(:)),mask),2));
lbl_neg = full(sum(sparseFromLabels(double(labels),max(labels(:)),1-mask),2));
seg = lbl_pos>=lbl_neg;

end
