function pixel_seg = spseg2seg(superpixels,seg)
superpixels = double(superpixels);
pixel_seg = seg(superpixels);