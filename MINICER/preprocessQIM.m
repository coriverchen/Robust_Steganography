function [cover,rhoM,rhoP,wetratei] = preprocessQIM(cover_Path,stego_step,cover_QF,attack_QF,spatail)
% 根据量化修改进行预处理，生成载体和对应的失真
% 使用的失真函数 1：JUNIWARD，2：UERD
distortion = 1;
wetConst = 10^13;
% 读取图像数据
C_STRUCT = jpeg_read(cover_Path);
C_COEFFS = C_STRUCT.coef_arrays{1};
C_QUANT = C_STRUCT.quant_tables{1}; %载体图像量化表
% 验证计算的量化表的正确性
C_QUANT1 = quantizationTable(cover_QF);
S_QUANT = quantizationTable(attack_QF);
try all(C_QUANT1 == C_QUANT);
%     disp('Quantization table OK.');
catch
    fprintf('%s\n',['Quantization table error. QF: ',num2str(cover_QF)]);
end

% 直接使用量化系数来计算载体,在向上鲁棒的情况下表现较好
% fun = @(x) round(x.data ./ stego_step);
% cover = blockproc(C_COEFFS,[8 8],fun);
if attack_QF==0
%% test on facebook
% 计算失真 
if distortion
    % J_UNIWARD基础失真
    [rhoP1,rhoM1] = J_UNIWARDcost(cover_Path);
else
    % UERD基础失真
    [rhoP1,rhoM1] = UERDcost(C_COEFFS,C_QUANT);
end

% 非量化的失真
fun = @(x) x.data ./ C_QUANT;
rhop = blockproc(rhoP1,[8 8],fun);
rhom = blockproc(rhoM1,[8 8],fun);
% 在非量化系数上的修改
% 此时图像从空域得到的系数
fun = @(x) idct2(x.data.*C_QUANT);
spa_uq = blockproc(C_COEFFS,[8 8],fun);
spa_t = spa_uq;
spa_t(spa_uq>127) = 127;
spa_t(spa_uq<-128) = -128;
fun = @(x) dct2(x.data);
coeffs_real = blockproc(round(spa_t),[8 8],fun);
% 此时用信道处理后的图像来做载体，断点处将图像上传再下载
breakpoint = 1;
[~, name, x_ext] = fileparts(cover_Path);
after_facebook = ['H:\test&code\QMAS\facebook\',name,x_ext];
F_STRUCT = jpeg_read(after_facebook);
F_COEFFS = F_STRUCT.coef_arrays{1};
F_QUANT = F_STRUCT.quant_tables{1};
S_QUANT = quantizationTable(80);
try all(F_QUANT == S_QUANT);
%     disp('Quantization table OK.');
catch
    fprintf('%s\n',['Quantization table error. QF: ',num2str(cover_QF)]);
end
fun = @(x) round((x.data.*F_QUANT)./C_QUANT);
cover = blockproc(F_COEFFS,[8 8],fun);
% 由cover来表示的系数
fun = @(x) (x.data .* stego_step) .* C_QUANT;
coeffs_p = blockproc(cover+1,[8 8],fun);
coeffs_m = blockproc(cover-1,[8 8],fun);
% 最终的失真
rhoP = rhop.*abs(coeffs_p-coeffs_real);
rhoM = rhom.*abs(coeffs_m-coeffs_real);
% rhoM = 0.5*rhoM;
rhoP(rhoP1==wetConst) = wetConst;
rhoM(rhoM1==wetConst) = wetConst;
% 将有变化的点也设为湿点
overflow_p = zeros(size(spa_uq));
% fun = @(x) (x.data .* stego_step);
% cover_r = blockproc(C_COEFFS,[8 8],fun);
% overflow_p(cover_r~=cover) = 1;
% 将溢出的位置设为wetconst
overflow_p(spa_uq>127) = 1;
overflow_p(spa_uq<-128) = 1;
fun = @(x) sum(sum(abs(x.data)))*ones(8,8);
overflow_blk = blockproc(overflow_p,[8 8],fun);
rhoP(overflow_blk~=0) = wetConst;
rhoM(overflow_blk~=0) = wetConst;
% 将可能溢出的点设为湿点（检查每个块内的可能加减一）
[xm,xn] = size(spa_uq);
m_block = floor(xm/8);
n_block = floor(xn/8);
spatail_max = max(spatail,[],3);
maybe_overflowP = zeros(size(spa_uq));
maybe_overflowM = zeros(size(spa_uq));
for bm = 1:m_block
    for bn = 1:n_block
        if all(all(overflow_blk((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)==ones(8,8)))
            continue;
        end
        if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)+spatail_max)<127))
            for i = 1 : 8
                for j = 1 : 8
                    if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)+spatail(:,:,j+(i-1)*8))<127))
                        maybe_overflowP((bm-1)*8+i,(bn-1)*8+j) = 1;
                    end
                end
            end
        end
        if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)-spatail_max)>-128))
            for i = 1 : 8
                for j = 1 : 8
                    if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)-spatail(:,:,j+(i-1)*8))<127))
                        maybe_overflowM((bm-1)*8+i,(bn-1)*8+j) = 1;
                    end
                end
            end
        end
    end
end
rhoP(maybe_overflowP~=0) = wetConst;
rhoM(maybe_overflowM~=0) = wetConst;

nzAC = nnz(C_COEFFS) - nnz(C_COEFFS(1:8:end,1:8:end));
rhoPc = rhoP; rhoPc(1:8:end,1:8:end) = 0; %为了计算与载体数目匹配的湿点率
rhoMc = rhoP; rhoMc(1:8:end,1:8:end) = 0; %为了计算与载体数目匹配的湿点率
wetratei = (nnz(rhoPc(C_COEFFS~=0)==wetConst)+nnz(rhoMc(C_COEFFS~=0)==wetConst))/(2*nzAC);
elseif cover_QF==attack_QF
%% Matching Robust
% 计算失真 
if distortion
    % J_UNIWARD基础失真
[rhoP1,rhoM1] = J_UNIWARDcost(cover_Path);
else
% UERD基础失真
[rhoP1,rhoM1] = UERDcost(C_COEFFS,C_QUANT);
end
% 非量化的失真
fun = @(x) x.data ./ C_QUANT;
rhop = blockproc(rhoP1,[8 8],fun);
rhom = blockproc(rhoM1,[8 8],fun);
% 在非量化系数上的修改
% 此时图像从空域得到的系数
fun = @(x) idct2(x.data.*C_QUANT);
spa_uq = blockproc(C_COEFFS,[8 8],fun);
spa_t = spa_uq;
spa_t(spa_uq>127) = 127;
spa_t(spa_uq<-128) = -128;
fun = @(x) dct2(x.data);
coeffs_real = blockproc(round(spa_t),[8 8],fun);
% 用real coefficient来计算载体，在matching robust时表现较好
fun = @(x) round(x.data ./C_QUANT);
cover_dct = blockproc(coeffs_real,[8 8],fun);
fun = @(x) round(x.data ./ stego_step);
cover = blockproc(cover_dct,[8 8],fun);
% 由cover来表示的系数
fun = @(x) (x.data .* stego_step) .* C_QUANT;
coeffs_p = blockproc(cover+1,[8 8],fun);
coeffs_m = blockproc(cover-1,[8 8],fun);
% 最终的失真
rhoP = rhop.*abs(coeffs_p-coeffs_real);
rhoM = rhom.*abs(coeffs_m-coeffs_real);
% rhoM = 0.5*rhoM;
rhoP(rhoP1==wetConst) = wetConst;
rhoM(rhoM1==wetConst) = wetConst;
% 将有变化的点也设为湿点
overflow_p = zeros(size(spa_uq));

% fun = @(x) round((x.data.*C_QUANT)./S_QUANT);
% cover_r = blockproc(C_COEFFS,[8 8],fun);
% cover_r = blockproc(C_COEFFS,[8 8],fun);
% overflow_p(cover_r~=cover) = 1;
% 将溢出的位置设为wetconst
overflow_p(spa_uq>127) = 1;
overflow_p(spa_uq<-128) = 1;
fun = @(x) sum(sum(abs(x.data)))*ones(8,8);
overflow_blk = blockproc(overflow_p,[8 8],fun);
rhoP(overflow_blk~=0) = wetConst;
rhoM(overflow_blk~=0) = wetConst;
% 将可能溢出的点设为湿点（检查每个块内的可能加减一）
[xm,xn] = size(spa_uq);
m_block = floor(xm/8);
n_block = floor(xn/8);
spatail_max = max(spatail,[],3);
maybe_overflowP = zeros(size(spa_uq));
maybe_overflowM = zeros(size(spa_uq));
for bm = 1:m_block
    for bn = 1:n_block
        if all(all(overflow_blk((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)==ones(8,8)))
            continue;
        end
        if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)+spatail_max)<127))
            for i = 1 : 8
                for j = 1 : 8
                    if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)+spatail(:,:,j+(i-1)*8))<127))
                        maybe_overflowP((bm-1)*8+i,(bn-1)*8+j) = 1;
                    end
                end
            end
        end
        if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)-spatail_max)>-128))
            for i = 1 : 8
                for j = 1 : 8
                    if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)-spatail(:,:,j+(i-1)*8))<127))
                        maybe_overflowM((bm-1)*8+i,(bn-1)*8+j) = 1;
                    end
                end
            end
        end
    end
end
rhoP(maybe_overflowP~=0) = wetConst;
rhoM(maybe_overflowM~=0) = wetConst;

nzAC = nnz(C_COEFFS) - nnz(C_COEFFS(1:8:end,1:8:end));
rhoPc = rhoP; rhoPc(1:8:end,1:8:end) = 0; %为了计算与载体数目匹配的湿点率
rhoMc = rhoP; rhoMc(1:8:end,1:8:end) = 0; %为了计算与载体数目匹配的湿点率
wetratei = (nnz(rhoPc(C_COEFFS~=0)==wetConst)+nnz(rhoMc(C_COEFFS~=0)==wetConst))/(2*nzAC);
elseif cover_QF<attack_QF
%% Upward Robust
% 计算失真 
if distortion
    % J_UNIWARD基础失真
[rhoP1,rhoM1] = J_UNIWARDcost(cover_Path);
else
% UERD基础失真
[rhoP1,rhoM1] = UERDcost(C_COEFFS,C_QUANT);
end
% 非量化的失真
fun = @(x) x.data ./ C_QUANT;
rhop = blockproc(rhoP1,[8 8],fun);
rhom = blockproc(rhoM1,[8 8],fun);
% 在非量化系数上的修改
% 此时图像从空域得到的系数
fun = @(x) idct2(x.data.*C_QUANT);
spa_uq = blockproc(C_COEFFS,[8 8],fun);
spa_t = spa_uq;
spa_t(spa_uq>127) = 127;
spa_t(spa_uq<-128) = -128;
fun = @(x) dct2(x.data);
coeffs_real = blockproc(round(spa_t),[8 8],fun);
% 使用信道质量因子压缩并做载体恢复后作为载体
fun = @(x) round(x.data ./S_QUANT);
channel_dct = blockproc(coeffs_real,[8 8],fun);
fun = @(x) (x.data.*S_QUANT);
channel_dct_uq = blockproc(channel_dct,[8 8],fun);
fun = @(x) round(x.data ./C_QUANT);
cover_dct = blockproc(channel_dct_uq,[8 8],fun);
fun = @(x) round(x.data ./ stego_step);
cover = blockproc(cover_dct,[8 8],fun);
% 由cover来表示的系数
fun = @(x) (x.data .* stego_step) .* C_QUANT;
coeffs_p = blockproc(cover+1,[8 8],fun);
coeffs_m = blockproc(cover-1,[8 8],fun);
% 最终的失真
rhoP = rhop.*abs(coeffs_p-coeffs_real);
rhoM = rhom.*abs(coeffs_m-coeffs_real);
% rhoM = 0.5*rhoM;
rhoP(rhoP1==wetConst) = wetConst;
rhoM(rhoM1==wetConst) = wetConst;
% 将溢出的位置设为wetconst
overflow_p = zeros(size(spa_uq));
overflow_p(spa_uq>127) = 1;
overflow_p(spa_uq<-128) = 1;
fun = @(x) sum(sum(abs(x.data)))*ones(8,8);
overflow_blk = blockproc(overflow_p,[8 8],fun);
rhoP(overflow_blk~=0) = wetConst;
rhoM(overflow_blk~=0) = wetConst;
% 将可能溢出的点设为湿点（检查每个块内的可能加减一）
[xm,xn] = size(spa_uq);
m_block = floor(xm/8);
n_block = floor(xn/8);
spatail_max = max(spatail,[],3);
maybe_overflowP = zeros(size(spa_uq));
maybe_overflowM = zeros(size(spa_uq));
for bm = 1:m_block
    for bn = 1:n_block
        if all(all(overflow_blk((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)==ones(8,8)))
            continue;
        end
        if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)+spatail_max)<127))
            for i = 1 : 8
                for j = 1 : 8
                    if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)+spatail(:,:,j+(i-1)*8))<127))
                        maybe_overflowP((bm-1)*8+i,(bn-1)*8+j) = 1;
                    end
                end
            end
        end
        if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)-spatail_max)>-128))
            for i = 1 : 8
                for j = 1 : 8
                    if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)-spatail(:,:,j+(i-1)*8))<127))
                        maybe_overflowM((bm-1)*8+i,(bn-1)*8+j) = 1;
                    end
                end
            end
        end
    end
end
rhoP(maybe_overflowP~=0) = wetConst;
rhoM(maybe_overflowM~=0) = wetConst;

nzAC = nnz(C_COEFFS) - nnz(C_COEFFS(1:8:end,1:8:end));
rhoPc = rhoP; rhoPc(1:8:end,1:8:end) = 0; %为了计算与载体数目匹配的湿点率
rhoMc = rhoP; rhoMc(1:8:end,1:8:end) = 0; %为了计算与载体数目匹配的湿点率
wetratei = (nnz(rhoPc(C_COEFFS~=0)==wetConst)+nnz(rhoMc(C_COEFFS~=0)==wetConst))/(2*nzAC);
elseif cover_QF>attack_QF
%% Downward Robust
% 计算失真 
if distortion
    % J_UNIWARD基础失真
[rhoP1,rhoM1] = J_UNIWARDcost(cover_Path);
else
% UERD基础失真
[rhoP1,rhoM1] = UERDcost(C_COEFFS,C_QUANT);
end
% 非量化的失真
fun = @(x) x.data ./ C_QUANT;
rhop = blockproc(rhoP1,[8 8],fun);
rhom = blockproc(rhoM1,[8 8],fun);
% 在非量化系数上的修改
% 此时图像从空域得到的系数
fun = @(x) idct2(x.data.*C_QUANT);
spa_uq = blockproc(C_COEFFS,[8 8],fun);
spa_t = spa_uq;
spa_t(spa_uq>127) = 127;
spa_t(spa_uq<-128) = -128;
fun = @(x) dct2(x.data);
coeffs_real = blockproc(round(spa_t),[8 8],fun);
% 使用信道质量因子压缩后的系数作为载体
fun = @(x) round(x.data ./S_QUANT);
cover_dct = blockproc(coeffs_real,[8 8],fun);
fun = @(x) idct2(x.data.*S_QUANT);
sspa_uq = blockproc(cover_dct,[8 8],fun);
fun = @(x) round(x.data ./ stego_step);
cover = blockproc(cover_dct,[8 8],fun);
% 由cover来表示的系数
fun = @(x) (x.data .* stego_step) .* S_QUANT;
coeffs_p = blockproc(cover+1,[8 8],fun);
coeffs_m = blockproc(cover-1,[8 8],fun);
% 最终的失真
rhoP = rhop.*abs(coeffs_p-coeffs_real);
rhoM = rhom.*abs(coeffs_m-coeffs_real);
% rhoM = 0.5*rhoM;
rhoP(rhoP1==wetConst) = wetConst;
rhoM(rhoM1==wetConst) = wetConst;
% 将有变化的点也设为湿点
overflow_p = zeros(size(spa_uq));
% fun = @(x) round((x.data.*C_QUANT)./S_QUANT);
% cover_r = blockproc(C_COEFFS,[8 8],fun);
% overflow_p(cover_r~=cover) = 1;
% 将溢出的位置设为wetconst
overflow_p(spa_uq>127) = 1;
overflow_p(spa_uq<-128) = 1;
fun = @(x) sum(sum(abs(x.data)))*ones(8,8);
overflow_blk = blockproc(overflow_p,[8 8],fun);
rhoP(overflow_blk~=0) = wetConst;
rhoM(overflow_blk~=0) = wetConst;

nzAC = nnz(C_COEFFS) - nnz(C_COEFFS(1:8:end,1:8:end));
rhoPc = rhoP; rhoPc(1:8:end,1:8:end) = 0; %为了计算与载体数目匹配的湿点率
rhoMc = rhoP; rhoMc(1:8:end,1:8:end) = 0; %为了计算与载体数目匹配的湿点率
wetratei = (nnz(rhoPc(C_COEFFS~=0)==wetConst)+nnz(rhoMc(C_COEFFS~=0)==wetConst))/(2*nzAC);
end