function [fk,bk] = assignComponents(img,fg,bg)

% pg_message('assignComponents');

fk = fg.cluster_2d(img);
bk = bg.cluster_2d(img);

