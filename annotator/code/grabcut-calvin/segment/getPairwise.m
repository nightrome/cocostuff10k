function [A,K] = getPairwise(img)

% pg_message('getPairwise');

[h,w,~] = size(img);
n = h*w;

imgr = img(:,:,1); imgr = imgr(:);
imgg = img(:,:,2); imgg = imgg(:);
imgb = img(:,:,3); imgb = imgb(:);

% locations
[x,y] = meshgrid(1:w,1:h);
x = x(:); y = y(:);

% neighbors down -> y+1 -> idx+1
n1_i1 = 1:n; n1_i1 = n1_i1(y<h);
n1_i2 = n1_i1+1;

% neighbors right-down -> x+1,y+1 -> idx+1+h
n2_i1 = 1:n; n2_i1 = n2_i1(y<h & x<w);
n2_i2 = n2_i1+1+h;

% neighbors right -> x+1 -> idx+h
n3_i1 = 1:n; n3_i1 = n3_i1(x<w);
n3_i2 = n3_i1+h;

% neighbors right-up -> x+1,y-1 -> idx+h-1
n4_i1 = 1:n; n4_i1 = n4_i1(x<w & h>1);
n4_i2 = n4_i1+h-1;

from = [n1_i1 n2_i1 n3_i1 n4_i1];
to = [n1_i2 n2_i2 n3_i2 n4_i2];

gamma = 50; % TODO could be trained
invdis = 1./sqrt((x(from)-x(to)).^2+(y(from)-y(to)).^2);
dz2 = (imgr(from)-imgr(to)).^2 + (imgg(from)-imgg(to)).^2 + (imgb(from)-imgb(to)).^2;
beta = (2*mean(dz2.*invdis))^-1; % TODO changed, .*invdis is not in paper, but in gco
expb = exp(-beta*dz2);
c = gamma * invdis .* expb;

A = sparse([from to],[to from],[c c]); % TODO do i need to explicitely make it symmetric?

K = 1+max(sum(A,2)); % TODO changed, gco seems to have only half of this, not correct

