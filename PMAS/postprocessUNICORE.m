function postprocessUNICORE(stego_path,stego,afterchannel_stego_path,attack_QF,T,mode)
%POSTPROCESSUNICORE 针对stego中出错的点进行后处理
real_stego = double(stego);
% 寻找出错的点
C_STRUCT = jpeg_read(stego_path);
stego = C_STRUCT.coef_arrays{1};
C_QUANT = C_STRUCT.quant_tables{1}; 

S_STRUCT = JPEGrecompress(stego_path,afterchannel_stego_path,attack_QF);
afterchannel_stego = S_STRUCT.coef_arrays{1};
S_QUANT = S_STRUCT.quant_tables{1}; 
comp_modify = double(real_stego)~=double(afterchannel_stego);

comp_modify_rate0 = nnz(comp_modify)/nnz(real_stego);
% 计算载密非量化系数，隐写载体，信道处理后隐写载体的去量化系数，鲁棒性
fun = @(x) x.data.*C_QUANT;
stego_uq = blockproc(stego,[8 8],fun);
fun = @(x) x.data.*S_QUANT;
stego_dq = blockproc(real_stego,[8 8],fun);
fun = @(x) (mod(x.data,S_QUANT) - S_QUANT/2);
stego_r = blockproc(stego_uq,[8,8],fun);
% % 观察出错点的分布
% stego_r_e = abs(stego_r)<T;
% comp_modify_r = comp_modify;
% comp_modify_r(stego_r_e==0) = 0;
% error_part1 = nnz(comp_modify_r)/nnz(comp_modify);
% 对出错点进行调整
[xm,xn] = size(stego);
m_block = floor(xm/8);
n_block = floor(xn/8);
postprocess = zeros(xm,xn);
for bm = 1:m_block
    for bn = 1:n_block
        for i = 1 : 8
            for j = 1 : 8
                if abs(stego_r((bm-1)*8+i,(bn-1)*8+j))>=T
%                     if mode
%                         
%                     else
                        if sign(stego_r((bm-1)*8+i,(bn-1)*8+j))==1 % 此处可加上防止修改到危险区域的保护
                            if stego((bm-1)*8+i,(bn-1)*8+j)+1<1024
                                postprocess((bm-1)*8+i,(bn-1)*8+j) = 1;
                            end
                        else
                            if stego((bm-1)*8+i,(bn-1)*8+j)-1>-1024
                                postprocess((bm-1)*8+i,(bn-1)*8+j) = -1;
                            end
                        end
%                     end
                else
                    modifyP = floor((stego_dq((bm-1)*8+i,(bn-1)*8+j)+S_QUANT(i,j)/2-T)/C_QUANT(i,j))-stego((bm-1)*8+i,(bn-1)*8+j);
                    modifyM = ceil((stego_dq((bm-1)*8+i,(bn-1)*8+j)-S_QUANT(i,j)/2+T)/C_QUANT(i,j))-stego((bm-1)*8+i,(bn-1)*8+j);
                    if abs(modifyP)>=abs(modifyM)
                        postprocess((bm-1)*8+i,(bn-1)*8+j) = modifyM;
                    else
                        postprocess((bm-1)*8+i,(bn-1)*8+j) = modifyP;
                    end
                end
            end
        end
    end
end
stego(comp_modify==1) = stego(comp_modify==1) + postprocess(comp_modify==1);
C_STRUCT.coef_arrays{1} = double(stego);
jpeg_write(C_STRUCT,stego_path);