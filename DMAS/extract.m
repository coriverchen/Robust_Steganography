function error_rate = extract(stegoPath,real_msg,rs_encoded_msg_len,tab_m)
    
%% 实际提取过程
    bits = 8;
    cover_spa = imread(stegoPath);
    cover_spa = double(cover_spa) - 2^(round(bits)-1);
    [xm,xn] = size(cover_spa);
    t = dctmtx(8);
    fun = @(xl) (t*xl*(t'));
    cover_DCT = blkproc(cover_spa,[8 8],fun);%分块DCT变换
    m_block = floor(xm/8);
    n_block = floor(xn/8);
    
    G = 1;
    n_msg = 0;
    code_n = m_block*n_block*15;  % 每个8*8DCT块只有中低频18个系数可 嵌入，故乘以 15
    e_code = zeros(1,code_n);
    for bm = 1:m_block
        for bn = 1:n_block
            for i = 1:8
                for j = 1:8
                    if (i+j==8)||(i+j==9)    
                        n_msg = n_msg + 1;
                        if n_msg<=code_n
                            yd = cover_DCT((bm-1)*8+i,(bn-1)*8+j);
                            tab = double(tab_m(i,j))/G;
                            dnum1 = round(yd/tab);
                            if mod(dnum1,2)==0
                                e_code(n_msg)=0;
                            else
                                e_code(n_msg)=1;
                            end
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
    
%%  STCs extract message
    H = 10;
    msg_J = stc_extract(uint8(e_code'),rs_encoded_msg_len,H); 
%%      
    [rs_decoded_msg,rs_decoded_msg_len] = rs_decode(double(msg_J'),rs_encoded_msg_len);
    bit_error = double(real_msg) - double(rs_decoded_msg);
    
    bit_error_number = sum( abs(bit_error) );
    error_rate = bit_error_number/rs_decoded_msg_len;
    
end
