function [stc_decoded_msg] = stc3Extract(afterchannel_stego_Path, stc_n_msg_bits, C_QUANT)
% 利用量化dct系数提取数据
% 首先计算信道处理后图像的非量化dct系数
bits = 8;
stego_spa = imread(afterchannel_stego_Path);
stego_spa = double(stego_spa) - 2^(round(bits)-1);
t = dctmtx(8);
fun = @(xl) (t*xl*(t'));
stego_dct_uq = blkproc(stego_spa,[8 8],fun);%分块DCT变换
% 接着计算在原始量化表下的量化的dct系数
fun = @(xl) (xl./C_QUANT);
stego_dct = round(blkproc(double(stego_dct_uq),[8 8],fun));
% 直接从量化后的dct系数中进行stc解码
H = 10;
stc_decoded_msg = stc_ml_extract(int32(reshape(stego_dct,1,[])), stc_n_msg_bits, H);

