function [fg,bg] = initializeModelSp(sp_stats,fgbg)
% TODO: remove hack, cf ijcv paper

% pg_message('initializeModel');

assert(any(fgbg(:)));
assert(any(~fgbg(:)));

K = 5;

fg = pdf_gm.fit_using_vectorquantisation(sp_stats.mean(fgbg,:),K);
bg = pdf_gm.fit_using_vectorquantisation(sp_stats.mean(~fgbg,:),K);
%fg = pdf_gm_sp.fit_given_components(sp_stats.n(fgbg),sp_stats.sum(fgbg,:),sp_stats.crossp(:,:,fgbg));
%fg = fg.simplify_accem(K);
%bg = pdf_gm_sp.fit_given_components(sp_stats.n(~fgbg),sp_stats.sum(~fgbg,:),sp_stats.crossp(:,:,~fgbg));
%bg = bg.simplify_accem(K);


