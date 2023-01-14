function [rhoP1,rhoM1] = UERDcost(dct_coef,q_tab)
dct_coef2 = dct_coef;
% remove DC coefs;
dct_coef2(1:8:end,1:8:end) = 0;
wetConst = 10^13;
[X,Y] = size(dct_coef);


q_tab(1,1) = 0.5*(q_tab(2,1)+q_tab(1,2));
q_matrix = repmat(q_tab,[X/8 Y/8]);

dct_coef2 = im2col(q_matrix.*dct_coef2,[8 8],'distinct');

J2 = sum(abs(dct_coef2));
J = ones(64,1)*J2;
J = col2im(J,[8 8], [X Y], 'distinct'); 

pad_size = 8;
im2 = padarray(J,[pad_size pad_size],'symmetric'); % energies of eight-neighbor blocks
size2 = 2*pad_size;
im_l8 = im2(1+pad_size:end-pad_size,1:end-size2);
im_r8 = im2(1+pad_size:end-pad_size,1+size2:end);
im_u8 = im2(1:end-size2,1+pad_size:end-pad_size);
im_d8 = im2(1+size2:end,1+pad_size:end-pad_size);
im_l88 = im2(1:end-size2,1:end-size2);
im_r88 = im2(1+size2:end,1+size2:end);
im_u88 = im2(1:end-size2,1+size2:end);
im_d88 = im2(1+size2:end,1:end-size2);
JJ = ( J + 0.25*(im_l8+im_r8+im_u8+im_d8) + 0.25*(im_l88+im_r88+im_u88+im_d88) );
decide = q_matrix./JJ; % version 2
decide = decide/min(decide(:));
rhoP1 = decide;
rhoM1 = decide;
%             
rhoP1(rhoP1 > wetConst) = wetConst;
rhoP1(isnan(rhoP1)) = wetConst;    
rhoP1(dct_coef > 1023) = wetConst;

rhoM1(rhoM1 > wetConst) = wetConst;
rhoM1(isnan(rhoM1)) = wetConst;
rhoM1(dct_coef < -1023) = wetConst;
end