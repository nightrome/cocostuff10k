classdef pdf_gm_sp
	
	properties
		n
		mu
		sigma
		weight
        accem_outer
	end;
	
	methods % constructor
		
		function this = pdf_gm_sp(mu,sigma,weight,n)
			if exist('n','var'),
				this.n = n;
			else
				this.n = NaN;
			end
			this.mu = mu;
			this.sigma = sigma;
			this.weight = weight;
            this.accem_outer = [];
		end;

	end;
	
	methods (Static=true) % static constructors
		
		function [gm labels llh] = fit_given_K(data,K)
			assert(isscalar(K));
			[labels,model,llh] = emgm(data',K);
			gm = pdf_gm_sp(model.mu',model.Sigma,model.weight,size(data,1));
		end;
        
        function gm = fit_given_components(component_n,component_sum,component_crossp)
            component_n = double(component_n);
            n = sum(component_n);
            mu = bsxfun(@rdivide,component_sum,component_n);
            sigma = component_crossp;
            for i=1:size(sigma,3),
                sigma(:,:,i) = sigma(:,:,i)/component_n(i) - mu(i,:)'*mu(i,:);
            end
            weight = component_n/n;
            gm = pdf_gm_sp(mu,sigma,weight,n);

        end
		
		function gm = fit_given_labels(data,labels,K,old)
			% reestimating the cluster for each k = 1:K
			% old needs to be for the same k, for empty clusters, keeping old model with small weight (epsilon)
			if ~exist('K','var'),
				labels = labels(:)-min(labels(:))+1;
				K = max(labels(:));
			end
			if ~exist('old','var'),
				assert(all(unique(labels(:)')==1:K));
			end
			
			
			n = size(data,1);
			d = size(data,2);
			
			mu = zeros(K,d);
			sigma = zeros(d,d,K);
			weight = zeros(K,1);
			
			for k = 1:K
				x = data(labels==k,:);
				if isempty(x)
					assert(exist('old','var')==1);
					mu(k,:) = old.mu(k,:);
					sigma(:,:,k) = old.sigma(:,:,k);
					weight(k) = 1e-20;
				else
					mu(k,:) = mean(x,1);
					sigma(:,:,k) = cov(x);
					[~,tmp_p] = chol(sigma(:,:,k)); % TODO hack, it's only epsilon non psd, method cluster freaks out
					if det(sigma(:,:,k))<1e-20 || tmp_p>0, sigma(:,:,k) = sigma(:,:,k)+1e-5*eye(d); end;
					[~,tmp_p] = chol(sigma(:,:,k));
					assert(tmp_p==0);
					weight(k) = size(x,1);
				end;
			end;
			
			weight = weight ./ sum(weight);
			
			gm = pdf_gm_sp(mu,sigma,weight,n);
			
		end;
		
		function [gm labels llh] = fit_init_labels(data,labels)
			% might lose clusters, empty cluster will be removed
			assert(size(data,1)==length(labels));
			labels = reshape(labels,1,length(labels));
			[labels,model,llh] = emgm(data',labels);
			gm = pdf_gm_sp(model.mu',model.Sigma,model.weight,size(data,1));
		end;
		
		function [gm labels llh] = fit_init_mu(data,mu)
			[labels,model,llh] = emgm(data',mu');
			gm = pdf_gm_sp(model.mu',model.Sigma,model.weight,size(data,1));
		end;
		
		function gm = fit_using_vectorquantisation(data,K)
			% fit using vector quantisation
			[labels,~] = nema_vector_quantize(data',K);
			
			% fake old model, for empty clusters
			n = size(data,1);
			assert(n>0);
			old = pdf_gm_sp(repmat(data(randi(n),:),[K 1]),repmat(1e-5*eye(3),[1 1 K]),ones(K,1)/K);
			
			gm = pdf_gm_sp.fit_given_labels(data,labels',K,old);
			
			% originally
% 			for i = 1:nmixtures
% 			  idx = find( cluster == i );
% 			  if isempty(idx), idx = randi(length(cluster)); end; % initalize with random data
% 			  if isscalar(idx), idx = [ idx ; idx ]; end; % cov(.) on one sample thinks it's one dimensional data
% 			  gmm.mu( :, i ) = mean( C( :, idx ), 2 );
% 			  gmm.sigma( :, :, i ) = cov( C( :, idx )' );
% 			  gmm.pi( i ) = length( idx );
% 			end
% 			gmm.pi = gmm.pi / sum( gmm.pi );
		end;
		
		function sdata = replicate_soft(weight,data,nbins)
			% replicating data
			% nbins distributed over weights 0..1
			% first bin gets 0 repetition, last bin gets nbins-1 repetitions.
			
			binsize = 1/nbins;
			n = size(data,1);
			
			sdata = cell(n,1);
			
			for i = 1:n
				r = min(floor(weight(i)/binsize),nbins-1);
				sdata{i} = repmat(data(i,:),r,1);
			end;
			
			sdata = cell2mat(sdata);
			
		end;
        
	end;
	
	methods
		
		function [labels logpdf] = cluster(this,data)
			c = gmdistribution(this.mu,this.sigma,this.weight); % TODO faster when done directly?
			[labels,~,~,logpdf] = c.cluster(data);
		end;
		
		function [labels logpdf] = cluster_2d(this,data)
			h = size(data,1);
			w = size(data,2);
			data = reshape(data,[],size(data,3));
			[labels logpdf] = this.cluster(data);
			labels = reshape(labels,h,w);
			logpdf = reshape(logpdf,h,w);
		end;
		
		function p = pdf(this,data,k)
			% note: given the component k, it's not evaluated as a conditional, still multiplying with the component weight
			if exist('k','var')
				% TODO copy/evaluate directly, more efficient?
				p = nan(size(data,1),1);
				for i = 1:length(this.weight)
					c = gmdistribution(this.mu(i,:),this.sigma(:,:,i),1);
					idx = k==i;
					p(idx) = this.weight(i)*c.pdf(data(idx,:));
				end;
				assert(~any(isnan(p)));
			else
				c = gmdistribution(this.mu,this.sigma,this.weight); % TODO faster when done directly?
				p = c.pdf(data);
			end;
		end;
		
		function p = pdf_2d(this,data,k)
			h = size(data,1);
			w = size(data,2);
			data = reshape(data,[],size(data,3));
			if exist('k','var')
				k = reshape(k,[],1);
				p = this.pdf(data,k);
			else
				p = this.pdf(data);
			end;
			p = reshape(p,h,w);
		end;
        
        
        function this = simplify_set_outer(this)
            if isempty(this.accem_outer),
                N = size(this.mu,1);
                d = size(this.mu,2);
                this.accem_outer = this.sigma;
                for i=1:N,
                    this.accem_outer(:,:,i) = this.accem_outer(:,:,i) + this.mu(i,:)'*this.mu(i,:);
                end
                this.accem_outer = reshape(this.accem_outer,d*d,[]);
            end
        end
        
        function [gm2,c] = simplify_accem(this,K,init) % simplify GMM using "Accelerated EM"
%             assert(false); % todo: check correctness of E and M (wrt weights and R)
            if ~exist('init','var'),     init = 'rnd'; end
            assert(K<length(this.weight));
             llh = -Inf;
             this = this.simplify_set_outer();
              while isinf(llh),
                [c, model, llh] = simplify_accem(this, K, init);
%                 fprintf('.');
              end
%             fprintf('\n');
            llh
            gm2 = pdf_gm_sp(model.mu',model.Sigma,model.weight,this.n);
        end
        
        function [gm1,gm2] = split(this,idx)
            assert(islogical(idx));
            assert(length(idx)==size(this.mu,1));
            w1 = this.weight(idx);
            W1 = sum(w1);
            w2 = this.weight(~idx);
            W2 = sum(w2);
            gm1 = pdf_gm_sp(this.mu(idx,:),this.sigma(:,:,idx),w1/W1,round(this.n*W1));
            gm2 = pdf_gm_sp(this.mu(~idx,:),this.sigma(:,:,~idx),w2/W2,round(this.n*W2));
        end
        
	end;
	
end


function [label, model, llh] = emgm(X, init)
% Perform EM algorithm for fitting the Gaussian mixture model.
%   X: d x n data matrix
%   init: k (1 x 1) or label (1 x n, 1<=label(i)<=k) or center (d x k)
% Written by Michael Chen (sth4nth@gmail.com).
% initialization
% fprintf('EM for Gaussian mixture: running ... \n');
R = initialization(X,init);
[~,label(1,:)] = max(R,[],2);
R = R(:,unique(label));

tol = 1e-6;
maxiter = 500;
llh = -inf(1,maxiter);
converged = false;
t = 1;
while ~converged && t < maxiter
    t = t+1;
    model = maximization(X,R);
    [R, llh(t)] = expectation(X,model);
    
    [~,label(1,:)] = max(R,[],2);
    idx = unique(label);   % non-empty components
    if size(R,2) ~= size(idx,2)
        R = R(:,idx);   % remove empty components
    else
        converged = llh(t)-llh(t-1) < tol*abs(llh(t));
    end

end
llh = llh(2:t);
if converged
%     fprintf('Converged in %d steps.\n',t-1);
else
    fprintf('Not converged in %d steps.\n',maxiter);
end

end


function R = initialization(X, init)
[d,n] = size(X);
if isstruct(init)  % initialize with a model
    R  = expectation(X,init);
elseif length(init) == 1  % random initialization
    k = init;
%     idx = randsample(n,k,true); % TODO added replacement, for really few samples, does it matter?
%     m = X(:,idx);
%     [~,label] = max(bsxfun(@minus,m'*X,sum(m.^2,1)'/2),[],1);
%     while k ~= unique(label)
%         idx = randsample(n,k,true); % TODO added replacement, for really few samples, does it matter?
%         m = X(:,idx);
%         [~,label] = max(bsxfun(@minus,m'*X,sum(m.^2,1)'/2),[],1);
%     end
    label = kmeans(X', k);
    R = full(sparse(1:n,label,1,n,k,n));
elseif size(init,1) == 1 && size(init,2) == n  % initialize with labels
    label = init;
    k = max(label);
    R = full(sparse(1:n,label,1,n,k,n));
elseif size(init,1) == d  %initialize with only centers
    k = size(init,2);
    m = init;
    [~,label] = max(bsxfun(@minus,m'*X,sum(m.^2,1)'/2),[],1);
    R = full(sparse(1:n,label,1,n,k,n));
else
    error('ERROR: init is not valid.');
end

end


function [R, llh] = expectation(X, model)
mu = model.mu;
Sigma = model.Sigma;
w = model.weight;

n = size(X,2);
k = size(mu,2);
logR = zeros(n,k);

for i = 1:k
    logR(:,i) = loggausspdf(X,mu(:,i),Sigma(:,:,i));
end
logR = bsxfun(@plus,logR,log(w));
T = logsumexp(logR,2);
llh = sum(T)/n; % loglikelihood
logR = bsxfun(@minus,logR,T);
R = exp(logR);

end

function model = maximization(X, R)
[d,n] = size(X);
k = size(R,2);

s = sum(R,1);
w = s/n;
mu = bsxfun(@times, X*R, 1./s);
Sigma = zeros(d,d,k);
for i = 1:k
    Xo = bsxfun(@minus,X,mu(:,i));
    Xo = bsxfun(@times,Xo,sqrt(R(:,i)'));
    Sigma(:,:,i) = Xo*Xo'/s(i);
    Sigma(:,:,i) = Sigma(:,:,i)+eye(d)*(1e-6); % add a prior for numerical stability
end

model.mu = mu;
model.Sigma = Sigma;
model.weight = w;

end


function [c, model, lk] = simplify_accem(this, K, init)
% Perform Accelerated EM simplification for fitting a Gaussian mixture model.
% input = finer GMM. outer = coarser GMM with K components

% DEBUG=false;
% if DEBUG,  figure(); end

[c,R] = simplify_initialization(this,K,init);
maxiter = 100;
converged = false;
t = 1;
while ~converged && t < maxiter
    t = t+1;
    c_old = c;
    model = simplify_maximization(this,R);

%     if DEBUG,      
%         rng = [-8 8 -8 8];
%         color = 'rgbky';
%         theta=0:0.1:2*pi;
% %         subplot(4,4,t); 
%         hold on;
%         for n=1:length(c),
%             muk  = this.mu(n,:);
%             sigk = this.sigma(:,:,n);
%             g = bsxfun(@plus,2*[cos(theta); sin(theta)]'*chol(sigk),muk);
%             plot(g(:,1),g(:,2),color(c(n)));
%         end
%         theta=0:0.01:2*pi;
%         for k=1:K,
%             muk  = model.mu(:,k)';
%             sigk = model.Sigma(:,:,k);
%             g=bsxfun(@plus,2*[cos(theta); sin(theta)]'*chol(sigk),muk);
%             plot(g(:,1),g(:,2),color(k),'LineWidth',4);
%         end
%         
%         grid on;
%         axis(rng);
%         pause
%     end
    
    [c,R,lk] = simplify_expectation(this,model);
    [idx,~,ib] = unique(c);   % non-empty components
    if size(model.mu,2) ~= length(idx)
        %warning('empty cluster at iter %d',t);
        lk = -Inf;
%         close()
        return
    end
    converged = all(c==c_old);
end

end


function [c,R] = simplify_initialization(this,K,init)
if strcmp(init,'link'),
    c = clusterdata(this.mu,'linkage','median','MaxClust',K);
elseif strcmp(init,'kmeans'),
    c = kmeans(this.mu,K);
else
    c = randi(K,size(this.mu,1),1);
end
n = size(this.mu,1);
R = zeros(n,K);
R(sub2ind([n K],1:n,c'))=1;
%R = max(0,R+randn(n,K)/100);
%R = bsxfun(@rdivide,R,sum(R,2));
end

function [c,R,llh] = simplify_expectation(this,model) % Expectation of Gaussian centroids
mu = model.mu;
Sigma = model.Sigma;
w = model.weight;
n = size(this.mu,1);
d = size(this.mu,2);
k = size(mu,2);
logR = zeros(n,k);
% logR2 = zeros(n,k);
for i = 1:k
%     logR(:,i) = -(log(det(Sigma(:,:,i))) + mu(:,i)'/Sigma(:,:,i)*mu(:,i))/2;
    logR(:,i) = loggausspdf(this.mu',mu(:,i),Sigma(:,:,i));
    isigk = -inv(Sigma(:,:,i))/2; % to speed up trace(Sigma(:,:,i)\this.sigma(:,:,j))/2
%     tmp = 2*mu(:,i)'/Sigma(:,:,i);
    sigJ = reshape(this.sigma,d*d,[])';
    logR(:,i) = logR(:,i) + sigJ*isigk(:);
%    lr = zeros(n,1);
%    for j = 1:n,
        %logR(j,i) = loggausspdf(this.mu(j,:)',mu(:,i),Sigma(:,:,i)) - trace(Sigma(:,:,i)\this.sigma(:,:,i))/2;
        %logR(j,i) = logR(j,i) * this.weight(j);
%         logR(j,i) =  logR(j,i) - (trace(Sigma(:,:,i)\(this.sigma(:,:,j)+this.mu(j,:)'*this.mu(j,:))) - tmp*this.mu(j,:)')/2;
%        sigj = this.sigma(:,:,j);
%        lr(j) = lr(j) - trace(Sigma(:,:,i)\this.sigma(:,:,j))/2;
%    end
%    norm(lr-sigJ*isigk)
    %logR(:,i) = loggausspdf(this.mu',mu(:,i),Sigma(:,:,i));
end
logR = bsxfun(@plus,logR,log(w));
T = logsumexp(logR,2);
llh = sum(T)/n; % loglikelihood
logR = bsxfun(@minus,logR,T);
R = exp(logR);
[~,c] = max(R,[],2);
end

function model = simplify_maximization(this,R)
% Update model parameters from cell responsabilities
d = size(this.mu,2);
K = size(R,2);
sigma = zeros(d,d,K);
w_i = this.weight(:)';
mu_i = this.mu;
% s_i = this.sigma;
weight = w_i*R; % weight of the combined Gaussians
wR = bsxfun(@times,w_i,R');
mu = bsxfun(@rdivide,wR*mu_i,weight');
Sig = this.accem_outer * wR'; %zeros(d,d);
for k=1:K,
    %mu(k,:) = (wR*mu_i)/weight(k); % weighted average of Gaussian means
    %v = bsxfun(@minus,mu_i,mu(k,:));
    %for u=1:length(w_i),
    %    sig = sig + wR(k,u)*( this.accem_outer(:,:,u) ); %s_i(:,:,u) + mu_i(u,:)'*mu_i(u,:) );
    %end
    sig = reshape(Sig(:,k),d,d);
    sigma(:,:,k) = sig/weight(k) - mu(k,:)'*mu(k,:) + eye(d)*1e-6;
end
model.mu = mu';
model.Sigma = sigma;
model.weight = weight;
end


function y = loggausspdf(X, mu, Sigma)
d = size(X,1);
X = bsxfun(@minus,X,mu);
[R,p]= chol(Sigma);
if p ~= 0
    error('ERROR: Sigma is not PD.');
end
q = sum((R'\X).^2,1);  % quadratic term (M distance)
c = d*log(2*pi)+2*sum(log(diag(R)));   % normalization constant
y = -(c+q)/2;
end


function s = logsumexp(x, dim)
% Compute log(sum(exp(x),dim)) while avoiding numerical underflow.
%   By default dim = 1 (columns).
% Written by Michael Chen (sth4nth@gmail.com).
if nargin == 1, 
    % Determine which dimension sum will use
    dim = find(size(x)~=1,1);
    if isempty(dim), dim = 1; end
end

% subtract the largest in each column
y = max(x,[],dim);
x = bsxfun(@minus,x,y);
s = y + log(sum(exp(x),dim));
i = find(~isfinite(y));
if ~isempty(i)
    s(i) = y(i);
end

end


function [ MODEL, MAP ] = nema_vector_quantize( C, M, W )

% NEMA_VECTOR_QUANTIZE A vector quantization function that uses the
% binary split algorithm of Orchard and Bouman:
%
%  Color Quantization of Images, M. Orchard and C. Bouman, IEEE
%  Trans. on Signal Processing, Vol. 39, No. 12, pp, 2677--2690,
%  Dec. 1991.
%
%    [ MODEL, MAP ] = NEMA_COLOUR_QUANTIZE( C, M ) clusters the data
%    matrix C into M clusters.  Each column of the DxN matrix C is a
%    data point.  The output MODEL is a 1xN matrix that assigns
%    each data point to a cluster.  Each column i of MAP is the
%    mean of cluster i.
%
%    [ X, MAP ] = NEMA_COLOUR_QUANTIZE( I, M ) converts the RGB image
%    I into an indexed image X.  MAP contains at most M colours.
%
%    ... = NEMA_COLOUR_QUANTIZE( ..., W ) uses "subjectively weighted
%    TSE criteria" to quantize the data.

% Author: Nicholas Apostoloff <nema@robots.ox.ac.uk>
% Date: 23 May 05

DEBUG = 0;

if ~size( C, 2 )
  MODEL = [];
  MAP = [];
  return;
end

if DEBUG
  original_C = C;
end % if DEBUG

return_map = 0;
if size( C, 3 ) > 1
  [ nrows, ncols, ndims ] = size( C );
  C = reshape( C, [], ndims )';
  C = im2double( C );
  return_map = 1;
else
  [ndims, ncols] = size( C );
  C = double( C );
  nrows = 1;
end
npixels = nrows * ncols;

if nargin < 3 | isempty( W )
  W = ones( 1, size( C, 2 ) );
else
  W = W( : )';
end % if nargin
sumW = sum( W );

if sumW
  W = W / sumW;
else
  warning( 'Weights vector sums to zero.  Defaulting to ones' );
  W = ones( size( W ) ) / prod( size( W ) );
end

% remove data points with zero weight
%idxw = find( W );
%C = C( :, idxw );
%W = W( idxw );

if length( W ) ~= size( C, 2 )
  error( 'Weight vector does not match the data vector' );
end

% initial cluster
[R0, m0] = ncq_Rm( C, W );
N0 = sum( W );
idx0 = ones( 1, size( C, 2 ) );
[e0, lambda0] = ncq_e( C, R0, m0, W );

for m = 2:M
  
  % find the node to split
  [t1, n] = max( lambda0 );
  en = e0( :, n );
  
  if ~t1 % if max( lambda0 ) is 0 then there is no variation left
    break;
  end
  
  % split node n
  nidx = find( idx0 == n );
  Cn = C( :, nidx );
  Wn = W( nidx );
  
  Nn = N0( n );
  mn = m0( :, n );
  qn = mn / Nn;
  Rn = R0( :, :, n );
  t1 = en' * Cn;
  nidx1 = find( t1 <= en' * qn );
  nidx2 = find( t1 > en' * qn );
  
  %  if ~length( nidx1 ) | ~length( nidx2 )
  %  if sum( Wn( nidx1 ) ) < 1 | sum( Wn( nidx2 ) ) < 1
  if length( nidx1 ) < 1 | length( nidx2 ) < 1
    break;
  end
  
  % update cluster parameters
  idx0( nidx( nidx2 ) ) = m;
  [ R0( :, :, n ), m0( :, n ) ] = ncq_Rm( Cn( :,  nidx1 ), Wn( nidx1 ) );
  [ e0( :, n ), lambda0( n ) ] = ncq_e( Cn( :, nidx1 ), R0( :, :, n ), ...
					m0( :, n ), Wn( nidx1 ) );
  N0( n ) = sum( Wn( nidx1 ) );

  %[ R0( :, :, m ), m0( :, m ) ] = ncq_Rm( Cn( :,  nidx2 ), Wn( nidx2 ) );  
  %N0( m ) = sum( Wn( nidx2 ) );

  R0( :, :, m ) = Rn - R0( :, :, n );
  m0( :, m ) = mn - m0( :, n );
  N0( m ) = Nn - N0( n );
  
  [ e0( :, m ), lambda0( m ) ] = ncq_e( Cn( :, nidx2 ), R0( :, :, m ), ...
					m0( :, m ), Wn( nidx2 ) );
  
  if DEBUG
    blah = zeros( nrows, ncols, ndims );
    for d = 1:ndims
      t1 = zeros( nrows, ncols );
      t1( nidx( nidx1 ) ) = m0( d, n ) / N0( n );
      t1( nidx( nidx2 ) ) = m0( d, m ) / N0( m );
      blah( :, :, d ) = t1;
    end
    blah2 = zeros( nrows, ncols );
    blah3 = blah2;
    blah3( nidx ) = 1;
    blah2( nidx(nidx1) ) = 1;
    blah2( nidx( nidx2 ) ) = 0.5;
    subplot( 1,4,1);
    imshow( blah2 );
    subplot( 1,4,2 );
    imshow( original_C .* repmat( blah3, [1,1,3] ) );
    subplot( 1,4,3);
    imshow( blah );
    subplot( 1,4,4);
    pc( reshape( idx0, nrows, ncols ) ) ;
    pause;
  end % if DEBUG
  
end % for m
N0(N0==0) = 1;
MAP = ( m0./repmat( N0, [ndims, 1] ) );
if return_map
  MAP = MAP';
end
MODEL = reshape( idx0, nrows, ncols );

end

function [R, m] = ncq_Rm( C, W )
C2 = repmat( W, size( C, 1 ), 1 ) .* C;
R = C2 * C';
m = sum( C2, 2 );

end

function [en, lambda] = ncq_e( Cn, Rn, mn, Wn )  
Nn = sum( Wn );

qn = mn / Nn;

Rhat = Rn - mn * mn' / Nn;

% Rhat should be real symmetric - make is so
%  this should stop a bug where complex eigenvalues where returned
Rhat = (Rhat + Rhat') * 0.5;

[ V, D ] = eigs( Rhat );
if any( ~isreal( V( :, 1 ) ) )
  warning( 'Complex eigenvectors found in Rhat' );
end
en = V( :, 1 );

%%%% In their paper they do not specify that the variance of each
% mode should be calculated using the weighted points, however I
% think that this is incorrect.

% Their method
%lambda = sum((en' * (Cn - repmat( qn, [1, size( Cn, 2 )] ))).^2);

% My method
%lambda = sum((en' * (Cn - repmat( qn, [1, size( Cn, 2 )] ))).^2 .* Wn)

% However, the variance of the data points along an eigenvector is
% equal to the eigenvalue of that eigenvector
lambda = D( 1 );

end
