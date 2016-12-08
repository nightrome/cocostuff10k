function T = getUnary_app(img,fg,bg,fk,bk)

% pg_message('getUnary');

T = cat(3,fg.pdf_2d(img,fk),bg.pdf_2d(img,bk));

