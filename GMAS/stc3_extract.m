function [stc_decoded_msg] = stc3_extract(afterchannel_stego_Path,stc_n_msg_bits,tab_m)
    
%% 根据广义抖动调制机制计算载密元素序列
    bits = 8;
    cover_spa = imread(afterchannel_stego_Path);
    cover_spa = double(cover_spa) - 2^(round(bits)-1);
    [xm,xn] = size(cover_spa);
    t = dctmtx(8);
    fun = @(xl) (t*xl*(t'));
    cover_DCT = blkproc(cover_spa,[8 8],fun);%分块DCT变换
    m_block = floor(xm/8);
    n_block = floor(xn/8);
    
    G = 1;
    n_msg = 0;
    code_n = m_block*n_block*21;  %中频21个DCT系数
    e_code = zeros(1,code_n);
    cover_round = zeros(1,code_n);%%%%%%%%%%%%%
    for bm = 1:m_block
        for bn = 1:n_block
            for i = 1:8
                for j = 1:8
                    if (i+j==7)||(i+j==8)||(i+j==9)  %中频21个DCT系数
                        n_msg = n_msg + 1;
                        if n_msg<=code_n
                            yd = cover_DCT((bm-1)*8+i,(bn-1)*8+j);
                            tab_q = double(tab_m(i,j))/G;
                            dnum1 = round(yd/tab_q);
                            cover_round(n_msg) = round(yd/tab_q);%%%%%%%%%%
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
    
%%  三元STCs 解码
    H = 10;
    stc_decoded_msg = stc_ml_extract(int32(cover_round), stc_n_msg_bits, H);

end
