function [stc_decoded_msg] = stcExtractUNICORE(afterchannel_stego_path, stc_n_msg_bits)
% 读取数据

S_STRUCT = jpeg_read(afterchannel_stego_path);
S_COEFFS = S_STRUCT.coef_arrays{1};
S_QUANT = S_STRUCT.quant_tables{1}; %载体图像量化表
% 提取消息
H = 10;
stc_decoded_msg = stc_ml_extract(int32(reshape(S_COEFFS,1,[])), stc_n_msg_bits, H);
