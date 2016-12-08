function [fg,bg] = initializeModel(img,mask)

% pg_message('initializeModel');

assert(any(mask(:)));
assert(any(~mask(:)));

img = reshape(img,[],3);

K = 5;

fg = pdf_gm.fit_using_vectorquantisation(img(mask,:),K);
bg = pdf_gm.fit_using_vectorquantisation(img(~mask,:),K);

