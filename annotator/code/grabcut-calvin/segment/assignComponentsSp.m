function [fk,bk] = assignComponentsSp(sp_stats,fg,bg)
% TODO: remove this hack, the assignement should not be hard

% pg_message('assignComponents');

fk = fg.cluster(sp_stats.mean);
bk = bg.cluster(sp_stats.mean);

