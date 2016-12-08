function [img,h,w] = getImage(img)

img = im2double(img);
assert(ndims(img)==3);

h = size(img,1);
w = size(img,2);
assert(size(img,3)==3);


