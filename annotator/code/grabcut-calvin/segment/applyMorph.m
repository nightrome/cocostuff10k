function seg = applyMorph(seg)

seg = imclose(seg,strel('disk',3));
seg = imfill(seg,'holes');
seg = bwmorph(seg,'open'); % remove thin regions
[~,N] = bwlabel(seg); % select largest 8-connected region
h = hist(seg(:),1:N);
[~,i] = max(h);
seg = seg==i;

