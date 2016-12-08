function [fg,bg] = learnModel(img,seg,fg,bg,fk,bk)

% pg_message('learnModel');

K = 5;

img = reshape(img,[],3);
seg = reshape(seg,[],1);
fk = reshape(fk,[],1);
bk = reshape(bk,[],1);

fg = pdf_gm.fit_given_labels(img(seg,:),fk(seg),K,fg);
bg = pdf_gm.fit_given_labels(img(~seg,:),bk(~seg),K,bg);

