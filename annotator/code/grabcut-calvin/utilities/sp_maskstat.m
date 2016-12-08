function stat = sp_maskstat(mask,labels)
% stat = sp_maskstat(mask,superpixels)
%
% Compute mask statistics for superpixels
%
% INPUTS:
% mask: the input image (double)
% superpixels: a superpixel segmentation
%

assert(ismatrix(mask));
assert(ismatrix(labels));

mask=double(mask);
if any(size(mask)~=size(labels)),
    mask = imresize(mask,size(labels),'nearest'); % 'nearest' avoids negative values in interpolation
end
labels = double(labels);

C = max(labels(:));
stat.n    = zeros(C,1,'uint16');
stat.mean = zeros(C,1);
stat.var  = zeros(C,1);
stat.median = zeros(C,1);
stat.max = zeros(C,1);
stat.min = zeros(C,1);
stat.meanlog = zeros(C,1);
stat.mean1mlog = zeros(C,1);

data = mask(:);
for i=1:C,
    x=data(labels==i,:);
    stat.n(i) = size(x,1);
    stat.mean(i) = mean(x);
    stat.var(i) = sum((x-mean(x)).^2);
    stat.median(i) = median(x);
    stat.max(i) = max(x(:));
    stat.min(i) = min(x(:));
    stat.meanlog(i) = mean(log(x)+1e-10);
    stat.mean1mlog(i) = mean(log(1-x)+1e-10);
end

end
