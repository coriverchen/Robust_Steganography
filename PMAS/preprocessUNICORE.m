function [cover,rhoM,rhoP,modification] = preprocessUNICORE(cover_path,cover_QF,attack_QF,T,mode,afterchannel_cover_path,spatail,distortion)
%PREPROCESSUNICORE 
% T: Threshold to control the robust region
% mode, mode(1): Use un- or post-compressed as a cover.
% mode(2): Distortion calculation method
% mode(3): Number of post-processing
% modification(:,:,1):+1. modification(:,:,2):-1. 

%% 相同的部分：失真以及压缩前后的载体的计算
% 使用的失真函数 1：JUNIWARD，2：UERD
% distortion = 1;
wetConst = 10^13;
% 读取图像数据
C_STRUCT = jpeg_read(cover_path);
C_COEFFS = C_STRUCT.coef_arrays{1};
C_QUANT = C_STRUCT.quant_tables{1}; %载体图像量化表
% 验证计算的量化表的正确性
C_QUANT1 = quantizationTable(cover_QF);
try all(C_QUANT1 == C_QUANT);
%     disp('Quantization table OK.');
catch
    fprintf('%s\n',['Quantization table error. QF: ',num2str(cover_QF)]);
end
fun = @(x) idct2(x.data.*C_QUANT);
spa_uq = blockproc(C_COEFFS,[8 8],fun);
if ~exist(afterchannel_cover_path,'file')
    S_STRUCT = JPEGrecompress(cover_path,afterchannel_cover_path,attack_QF);
else
    S_STRUCT = jpeg_read(afterchannel_cover_path);
end
S_COEFFS = S_STRUCT.coef_arrays{1};
S_QUANT = S_STRUCT.quant_tables{1};
% 计算失真 
if distortion
    % J_UNIWARD基础失真
    if mode(2)<=2
        [rhoP1,rhoM1] = J_UNIWARDcost(afterchannel_cover_path);
    else
        [rhoP1,rhoM1] = J_UNIWARDcost(cover_path);
    end
else
    % UERD基础失真
    if mode(2)<=2
        [rhoP1,rhoM1] = UERDcost(S_COEFFS,S_QUANT);
    else
        [rhoP1,rhoM1] = UERDcost(C_COEFFS,C_QUANT);
    end
end


%% mode1: Use uncompressed as a cover.
if mode(1)==1
    % 计算载体非量化系数，隐写载体，隐写载体的去量化系数，鲁棒性
    fun = @(x) x.data.*C_QUANT;
    cover_uq = blockproc(C_COEFFS,[8 8],fun);
    fun = @(x) round(x.data./S_QUANT);
    cover = blockproc(cover_uq,[8 8],fun);
    fun = @(x) x.data.*S_QUANT;
    cover_dq = blockproc(cover,[8 8],fun);
%     fun = @(x) abs(mod(x.data,S_QUANT) - S_QUANT/2);
%     cover_r = blockproc(cover_uq,[8,8],fun);
    % 开始计算所求东西
    [xm,xn] = size(spa_uq);
    m_block = floor(xm/8);
    n_block = floor(xn/8);
    rhoP = rhoP1;
    rhoM = rhoM1;
    modification = zeros(xm,xn,2);
    for bm = 1:m_block
        for bn = 1:n_block
            for i = 1 : 8
                for j = 1 : 8
                    modification((bm-1)*8+i,(bn-1)*8+j,1) = ceil((cover_dq((bm-1)*8+i,(bn-1)*8+j)+S_QUANT(i,j)/2+T )/C_QUANT(i,j))-C_COEFFS((bm-1)*8+i,(bn-1)*8+j);
                    modification((bm-1)*8+i,(bn-1)*8+j,2) = C_COEFFS((bm-1)*8+i,(bn-1)*8+j)-floor((cover_dq((bm-1)*8+i,(bn-1)*8+j)-S_QUANT(i,j)/2-T)/C_QUANT(i,j));
                    switch mode(2)
                        case 1
                            rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j);
                            rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j);
%                         case 2
%                             if cover_uq((bm-1)*8+i,(bn-1)*8+j)<cover_dq((bm-1)*8+i,(bn-1)*8+j)
%                                 rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j);
%                                 rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j)*(1-2*(cover_dq((bm-1)*8+i,(bn-1)*8+j)-cover_uq((bm-1)*8+i,(bn-1)*8+j))/S_QUANT(i,j));
%                             else
%                                 rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j);
%                                 rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j)*(1-2*(cover_uq((bm-1)*8+i,(bn-1)*8+j)-cover_dq((bm-1)*8+i,(bn-1)*8+j))/S_QUANT(i,j));
%                             end
                        case 2
                            rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j)*modification((bm-1)*8+i,(bn-1)*8+j,1);
                            rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j)*modification((bm-1)*8+i,(bn-1)*8+j,2);
                        case 3
                            rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j)*((exp(1))^(modification((bm-1)*8+i,(bn-1)*8+j,1))-1);
                            rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j)*((exp(1))^(modification((bm-1)*8+i,(bn-1)*8+j,2))-1);
                        case 4
                            rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j)*(log(1+modification((bm-1)*8+i,(bn-1)*8+j,1)));
                            rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j)*(log(1+modification((bm-1)*8+i,(bn-1)*8+j,2)));
                        case 5
                            rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j)*(log10(1+modification((bm-1)*8+i,(bn-1)*8+j,1)));
                            rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j)*(log10(1+modification((bm-1)*8+i,(bn-1)*8+j,2)));
                        case 6
                            rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j)*(modification((bm-1)*8+i,(bn-1)*8+j,1)^2);
                            rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j)*(modification((bm-1)*8+i,(bn-1)*8+j,2)^2);
                        case 7
                            rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j)*(modification((bm-1)*8+i,(bn-1)*8+j,1)^2);
                            rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j)*(modification((bm-1)*8+i,(bn-1)*8+j,2)^2);
                    end
                    % 防止修改落入危险区域
%                     if abs(mod(C_COEFFS((bm-1)*8+i,(bn-1)*8+j)+modification((bm-1)*8+i,(bn-1)*8+j,1),S_QUANT(i,j))-S_QUANT(i,j)/2)<T
%                         rhoP((bm-1)*8+i,(bn-1)*8+j) = wetConst;
%                     end
%                     if abs(mod(C_COEFFS((bm-1)*8+i,(bn-1)*8+j)-modification((bm-1)*8+i,(bn-1)*8+j,2),S_QUANT(i,j))-S_QUANT(i,j)/2)<T
%                         rhoM((bm-1)*8+i,(bn-1)*8+j) = wetConst;
%                     end
                    % 防止修改溢出
                    if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)+spatail(:,:,j+(i-1)*8)*modification((bm-1)*8+i,(bn-1)*8+j,1))<=127))
                        rhoP((bm-1)*8+i,(bn-1)*8+j) = wetConst;
                    end
                    if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)-spatail(:,:,j+(i-1)*8)*modification((bm-1)*8+i,(bn-1)*8+j,2))>=-128))
                        rhoM((bm-1)*8+i,(bn-1)*8+j) = wetConst;
                    end
%                     if cover_r((bm-1)*8+i,(bn-1)*8+j)>=T % 根据是否鲁棒元素区分处理
%                         continue;
%                     elseif S_COEFFS((bm-1)*8+i,(bn-1)*8+j)==cover((bm-1)*8+i,(bn-1)*8+j)
%                         continue;
%                     elseif S_COEFFS((bm-1)*8+i,(bn-1)*8+j)-cover((bm-1)*8+i,(bn-1)*8+j)==1
%                         rhoP((bm-1)*8+i,(bn-1)*8+j) = 0;
%                         modification((bm-1)*8+i,(bn-1)*8+j,3) = modification((bm-1)*8+i,(bn-1)*8+j,1);
%                         modification((bm-1)*8+i,(bn-1)*8+j,1) = 0;
%                     elseif S_COEFFS((bm-1)*8+i,(bn-1)*8+j)-cover((bm-1)*8+i,(bn-1)*8+j)==-1
%                         rhoM((bm-1)*8+i,(bn-1)*8+j) = 0;
%                         modification((bm-1)*8+i,(bn-1)*8+j,3) = modification((bm-1)*8+i,(bn-1)*8+j,2)*(-1);
%                         modification((bm-1)*8+i,(bn-1)*8+j,2) = 0;
%                     end
                end
            end
        end
    end
%% mode2: Use postcompressed as a cover.
elseif mode(1)==2
    % 计算载体非量化系数，隐写载体，隐写载体的去量化系数，鲁棒性
    fun = @(x) x.data.*C_QUANT;
    cover_uq = blockproc(C_COEFFS,[8 8],fun);
    cover = S_COEFFS;
    fun = @(x) x.data.*S_QUANT;
    cover_dq = blockproc(cover,[8 8],fun);
%     fun = @(x) abs(mod(x.data,S_QUANT) - S_QUANT/2);
%     cover_r = blockproc(cover_uq,[8,8],fun);
    % 开始计算所求东西
    [xm,xn] = size(spa_uq);
    m_block = floor(xm/8);
    n_block = floor(xn/8);
    rhoP = rhoP1;
    rhoM = rhoM1;
    modification = zeros(xm,xn,2);
    for bm = 1:m_block
        for bn = 1:n_block
            for i = 1 : 8
                for j = 1 : 8
                    modification((bm-1)*8+i,(bn-1)*8+j,1) = ceil((cover_dq((bm-1)*8+i,(bn-1)*8+j)+S_QUANT(i,j)/2+T )/C_QUANT(i,j))-C_COEFFS((bm-1)*8+i,(bn-1)*8+j);
                    modification((bm-1)*8+i,(bn-1)*8+j,2) = C_COEFFS((bm-1)*8+i,(bn-1)*8+j)-floor((cover_dq((bm-1)*8+i,(bn-1)*8+j)-S_QUANT(i,j)/2-T)/C_QUANT(i,j));
                    switch mode(2)
                        case 1
                            rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j);
                            rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j);
%                         case 2
%                             if cover_uq((bm-1)*8+i,(bn-1)*8+j)<cover_dq((bm-1)*8+i,(bn-1)*8+j)
%                                 rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j);
%                                 rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j)*(1-2*(cover_dq((bm-1)*8+i,(bn-1)*8+j)-cover_uq((bm-1)*8+i,(bn-1)*8+j))/S_QUANT(i,j));
%                             else
%                                 rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j);
%                                 rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j)*(1-2*(cover_uq((bm-1)*8+i,(bn-1)*8+j)-cover_dq((bm-1)*8+i,(bn-1)*8+j))/S_QUANT(i,j));
%                             end
                        case 2
                            rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j)*modification((bm-1)*8+i,(bn-1)*8+j,1);
                            rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j)*modification((bm-1)*8+i,(bn-1)*8+j,2);
                        case 3
                            rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j)*((exp(1))^(modification((bm-1)*8+i,(bn-1)*8+j,1))-1);
                            rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j)*((exp(1))^(modification((bm-1)*8+i,(bn-1)*8+j,2))-1);
                        case 4
                            rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j)*(log(1+modification((bm-1)*8+i,(bn-1)*8+j,1)));
                            rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j)*(log(1+modification((bm-1)*8+i,(bn-1)*8+j,2)));
                        case 5
                            rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j)*(log10(1+modification((bm-1)*8+i,(bn-1)*8+j,1)));
                            rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j)*(log10(1+modification((bm-1)*8+i,(bn-1)*8+j,2)));
                        case 6
                            rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j)*(modification((bm-1)*8+i,(bn-1)*8+j,1)^2);
                            rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j)*(modification((bm-1)*8+i,(bn-1)*8+j,2)^2);
                        case 7
                            rhoP((bm-1)*8+i,(bn-1)*8+j) = rhoP1((bm-1)*8+i,(bn-1)*8+j)*(modification((bm-1)*8+i,(bn-1)*8+j,1)^2);
                            rhoM((bm-1)*8+i,(bn-1)*8+j) = rhoM1((bm-1)*8+i,(bn-1)*8+j)*(modification((bm-1)*8+i,(bn-1)*8+j,2)^2);
                    end
                    % 防止修改落入危险区域
%                     if abs(mod(C_COEFFS((bm-1)*8+i,(bn-1)*8+j)+modification((bm-1)*8+i,(bn-1)*8+j,1),S_QUANT(i,j))-S_QUANT(i,j)/2)<T
%                         rhoP((bm-1)*8+i,(bn-1)*8+j) = wetConst;
%                     end
%                     if abs(mod(C_COEFFS((bm-1)*8+i,(bn-1)*8+j)-modification((bm-1)*8+i,(bn-1)*8+j,2),S_QUANT(i,j))-S_QUANT(i,j)/2)<T
%                         rhoM((bm-1)*8+i,(bn-1)*8+j) = wetConst;
%                     end
                    % 防止修改溢出
                    if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)+spatail(:,:,j+(i-1)*8)*modification((bm-1)*8+i,(bn-1)*8+j,1))<=127))
                        rhoP((bm-1)*8+i,(bn-1)*8+j) = wetConst;
                    end
                    if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)-spatail(:,:,j+(i-1)*8)*modification((bm-1)*8+i,(bn-1)*8+j,2))>=-128))
                        rhoM((bm-1)*8+i,(bn-1)*8+j) = wetConst;
                    end
%                     if cover_r((bm-1)*8+i,(bn-1)*8+j)>=T % 根据是否鲁棒元素区分处理
%                         continue;
%                     elseif S_COEFFS((bm-1)*8+i,(bn-1)*8+j)==cover((bm-1)*8+i,(bn-1)*8+j)
%                         continue;
%                     elseif S_COEFFS((bm-1)*8+i,(bn-1)*8+j)-cover((bm-1)*8+i,(bn-1)*8+j)==1
%                         rhoP((bm-1)*8+i,(bn-1)*8+j) = 0;
%                         modification((bm-1)*8+i,(bn-1)*8+j,3) = modification((bm-1)*8+i,(bn-1)*8+j,1);
%                         modification((bm-1)*8+i,(bn-1)*8+j,1) = 0;
%                     elseif S_COEFFS((bm-1)*8+i,(bn-1)*8+j)-cover((bm-1)*8+i,(bn-1)*8+j)==-1
%                         rhoM((bm-1)*8+i,(bn-1)*8+j) = 0;
%                         modification((bm-1)*8+i,(bn-1)*8+j,3) = modification((bm-1)*8+i,(bn-1)*8+j,2)*(-1);
%                         modification((bm-1)*8+i,(bn-1)*8+j,2) = 0;
%                     end
                end
            end
        end
    end
end
