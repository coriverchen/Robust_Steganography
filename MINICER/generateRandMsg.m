function [msg,msg_len] = generateRandMsg(cover_Path,payload)
% 生成随机消息
C_STRUCT = jpeg_read(cover_Path);
C_COEFFS = C_STRUCT.coef_arrays{1};
nzAC = nnz(C_COEFFS) - nnz(C_COEFFS(1:8:end,1:8:end));
raw_msg_len = ceil(payload*nzAC);
raw_msg = round( rand(1,raw_msg_len) ); %原始秘密信息的行向量
msg = raw_msg;
msg_len = raw_msg_len;

