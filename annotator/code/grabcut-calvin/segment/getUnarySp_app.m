function T = getUnarySp_app(sp_stats,fg,bg,fk,bk)
% TODO: do this properly
% pg_message('getUnary');

T = cat(3,fg.pdf(sp_stats.mean,fk),bg.pdf(sp_stats.mean,bk));

