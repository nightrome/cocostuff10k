function stat = sp_stats_for_grabcut(img,labels)
% stat = sp_stats_for_grabcut(img,superpixels)
%
% Compute connectivity graph and color statistics for superpixels
%
% INPUTS:
% img: the input image (uint8)
% superpixels: a superpixel segmentation
%

img = im2double(img);
assert(ndims(img)==3);
assert(size(img,3)==3);
labels = double(labels);
assert(all(size(labels)==size(img(:,:,1))));

stat.imsize = size(img(:,:,1));

C = max(labels(:));
stat.n    = zeros(C,1);
stat.mean = zeros(C,3);
stat.cov  = zeros(3,3,C);

data = reshape(img,[],3);
for i=1:C,
    x=data(labels==i,:);
    stat.n(i) = size(x,1);
    stat.mean(i,:) = mean(x,1);
    stat.cov(:,:,i) = cov(x);
end
[stat.connectivity, stat.A, stat.K] = getPairwiseSp(img,labels);

end

% function [A,K] = getPairwise(img)
% 
% % pg_message('getPairwise');
% 
% [h,w,~] = size(img);
% n = h*w;
% 
% imgr = img(:,:,1); imgr = imgr(:);
% imgg = img(:,:,2); imgg = imgg(:);
% imgb = img(:,:,3); imgb = imgb(:);
% 
% % locations
% [x,y] = meshgrid(1:w,1:h);
% x = x(:); y = y(:);
% 
% % neighbors down -> y+1 -> idx+1
% n1_i1 = 1:n; n1_i1 = n1_i1(y<h);
% n1_i2 = n1_i1+1;
% 
% % neighbors right-down -> x+1,y+1 -> idx+1+h
% n2_i1 = 1:n; n2_i1 = n2_i1(y<h & x<w);
% n2_i2 = n2_i1+1+h;
% 
% % neighbors right -> x+1 -> idx+h
% n3_i1 = 1:n; n3_i1 = n3_i1(x<w);
% n3_i2 = n3_i1+h;
% 
% % neighbors right-up -> x+1,y-1 -> idx+h-1
% n4_i1 = 1:n; n4_i1 = n4_i1(x<w & h>1);
% n4_i2 = n4_i1+h-1;
% 
% from = [n1_i1 n2_i1 n3_i1 n4_i1];
% to = [n1_i2 n2_i2 n3_i2 n4_i2];
% 
% gamma = 50; % TODO could be trained
% invdis = 1./sqrt((x(from)-x(to)).^2+(y(from)-y(to)).^2);
% dz2 = (imgr(from)-imgr(to)).^2 + (imgg(from)-imgg(to)).^2 + (imgb(from)-imgb(to)).^2;
% beta = (2*mean(dz2.*invdis))^-1; % TODO changed, .*invdis is not in paper, but in gco
% expb = exp(-beta*dz2);
% c = gamma * invdis .* expb;
% 
% A = sparse([from to],[to from],[c c]); % TODO do i need to explicitely make it symmetric?
% 
% K = 1+max(sum(A,2)); % TODO changed, gco seems to have only half of this, not correct


function [Conn,A,K] = getPairwiseSp(img,sp_labels)
% compute the pairwise terms at pixel level and aggregate (sum)
% over pixels in the same superpixels

[H,W,~] = size(img);
C = max(sp_labels(:));
imgr = img(:,:,1); imgr = imgr(:);
imgg = img(:,:,2); imgg = imgg(:);
imgb = img(:,:,3); imgb = imgb(:);
N=W*H;
[X,Y] = meshgrid(1:W,1:H);
X = X(:); Y = Y(:);
% neighbors down -> y+1 -> idx+1
n1_i1 = 1:N; n1_i1 = n1_i1(Y<H);
n1_i2 = n1_i1+1;
% neighbors right-down -> x+1,y+1 -> idx+1+h
n2_i1 = 1:N; n2_i1 = n2_i1(Y<H & X<W);
n2_i2 = n2_i1+1+H;
% neighbors right -> x+1 -> idx+h
n3_i1 = 1:N; n3_i1 = n3_i1(X<W);
n3_i2 = n3_i1+H;
% neighbors right-up -> x+1,y-1 -> idx+h-1
n4_i1 = 1:N; n4_i1 = n4_i1(X<W & H>1);
n4_i2 = n4_i1+H-1;
pix_from = [n1_i1 n2_i1 n3_i1 n4_i1];
pix_to = [n1_i2 n2_i2 n3_i2 n4_i2];

% TODO: find and correct this bug!! This should speed-up things because we
% don't need to compute pairwise terms within a superpixel
% now aggregate over superpixels
%idx = sp_labels(pix_from)~=sp_labels(pix_to); % only those connections cross a superpixel border
%pix_from = pix_from(idx);
%pix_to   = pix_to(idx);

sup_from = sp_labels(pix_from);
sup_to   = sp_labels(pix_to);
Conn = sumConnections(sup_from,sup_to,ones(numel(sup_from),1),C);

gamma = 50; % TODO could be trained
invdis = 1./sqrt((X(pix_from)-X(pix_to)).^2+(Y(pix_from)-Y(pix_to)).^2);
dz2 = (imgr(pix_from)-imgr(pix_to)).^2 + (imgg(pix_from)-imgg(pix_to)).^2 + (imgb(pix_from)-imgb(pix_to)).^2;
beta = (2*mean(dz2.*invdis))^-1; % TODO changed, .*invdis is not in paper, but in gco
expb = exp(-beta*dz2);
c = gamma * invdis .* expb;
% c(c<1e-5) = 0;
% forget zero connections
% pix_from = pix_from(c>0);
% pix_to   = pix_to(c>0);
% c        = c(c>0);
% get label pairs of each pixel connection
%sup_from = sp_labels(pix_from);
%sup_to   = sp_labels(pix_to);
A = sumConnections(sup_from,sup_to,c,C);
% row_idx  = double((sup_from-1)*C+sup_to);
% D = mg_sparseFromLabels(row_idx,C*C,c);
% % sum over pixel pairs
% D = sum(D,2);
% % reshape to CxC matrix and make it symmetric
% A = reshape(D,C,C);
% A = A+A';

% keyboard % naive method, to check correctness
% A2 = zeros(C);
% for i=1:length(sup_from),
%     A2(sup_from(i),sup_to(i)) = A2(sup_from(i),sup_to(i)) + c(i);
% end
% A2 = sparse(A2+A2');
% A2 = sparse(A);
K = 1+max(sum(A,2)); % TODO changed, gco seems to have only half of this, not correct
end

function S = sumConnections(sup_from,sup_to,c,C)
% efficiently build a sparse matrix with weights of each label pair aligned
% in rows (C*C rows)
C = double(C);
c = double(c);
sup_to=double(sup_to);
sup_from=double(sup_from);
row_idx  = (sup_to-1)*C+sup_from;
S = sparseFromLabels(row_idx,C*C,c);
% sum over pixel pairs
S = sum(S,2);
% reshape to CxC matrix and make it symmetric
S = reshape(S,C,C);
S = S+S';
end
