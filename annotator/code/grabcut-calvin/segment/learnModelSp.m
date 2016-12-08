function [fg,bg] = learnModelSp(sp_stats,seg,fg,bg,fk,bk)
% TODO: fit this properly following ijcv

% pg_message('learnModel');

K = 5;

mu = sp_stats.mean;
fg = pdf_gm_sp.fit_given_labels(mu(seg,:),fk(seg),K,fg);
bg = pdf_gm_sp.fit_given_labels(mu(~seg,:),bk(~seg),K,bg);

