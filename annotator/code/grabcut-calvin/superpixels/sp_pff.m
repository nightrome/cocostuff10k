function sp = sp_pff(img,varargin)

imsize = size(img(:,:,1));
numpix = prod(imsize);

read_varargin
default sig 0.5
default k 300
default minsize round(double(numpix)/1000)

sp = segmentmex(img,sig,k,minsize);
[~,~,sp]=unique(sp);
sp = uint16(reshape(sp,imsize));

