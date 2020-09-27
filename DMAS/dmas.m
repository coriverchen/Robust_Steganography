function [suc,real_msg,encoded_msg_len] = dmas(msg,len,coverPath,cover_lsb,rho,change,QF,stegoPath)
%频域算法
% C_STRUCT = jpeg_read(coverPath);
% C_COEFFS = C_STRUCT.coef_arrays{1};  
% nzAC = nnz(C_COEFFS)-nnz(C_COEFFS(1:8:end,1:8:end));

%% RS 编码
[encoded_msg,encoded_msg_len,real_msg,real_msg_len] = rs_encode(msg,len);   % msg和encoded_msg 为行向量

%% STCs 编码
H = 10;
[min_cost, stc_msg] = stc_embed(uint8(cover_lsb'), uint8(encoded_msg'), rho', H); % embed message   二元嵌  量化索引调制机制
msg2 = stc_extract(stc_msg, encoded_msg_len, H); % extract message

if all(uint8(encoded_msg) == msg2')
    disp('Message can be extracted by STCS correctly.');
else
    error('Some error occured in the extraction process of STCs.');
end

stc_msg = stc_msg';
code = stc_msg;
code_n = length(stc_msg);

bits = 8;     
cover_spa = imread(coverPath);
cover_spa = double(cover_spa) - 2^(round(bits)-1);
[xm,xn] = size(cover_spa);

t = dctmtx(8);  %产生DCT矩阵
fun = @(xl) (t*xl*(t'));
cover_DCT = blkproc(cover_spa,[8 8],fun);%分块DCT变换
m_block = floor(xm/8);
n_block = floor(xn/8);

%% 实际嵌入过程
G = 1;
n_msg = 0;
for bm = 1:m_block
    for bn = 1:n_block
        for i = 1:8
            for j = 1:8
                if (i+j==8)||(i+j==9)   %只在中低频嵌入 每个8*8块15个系数可嵌入
                    n_msg = n_msg + 1;
                    if n_msg<=code_n
                        yd = cover_DCT((bm-1)*8+i,(bn-1)*8+j);
                        if cover_lsb(n_msg) ~= code(n_msg)   % 
                            yd = yd + change(n_msg);                            
                        end                                              
                        cover_DCT((bm-1)*8+i,(bn-1)*8+j) = yd;
                    else
                        break;
                    end
                end
            end
        end
        if n_msg>code_n break; end
    end
    if n_msg>code_n break; end
end

%% 图像生成
cover_spa = blkproc(cover_DCT,[8 8],'P1*x*P2',t',t);
cover_spa = cover_spa + double(2^(bits-1));
cover_spa = uint8(cover_spa);
imwrite(cover_spa,stegoPath,'quality',QF);
suc = 1;

end