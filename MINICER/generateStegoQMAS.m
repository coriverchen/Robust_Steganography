function generateStegoQMAS(cover_Path,stego_Path,cover,stego,stego_step,cover_QF,attack_QF)
% 生成最终的隐写图像
if attack_QF==0
cover = double(cover);
stego = double(stego);
% 隐写的修改
diff = stego - cover;
% 读取载体图像
C_STRUCT = jpeg_read(cover_Path);
C_COEFFS = C_STRUCT.coef_arrays{1};
C_QUANT = C_STRUCT.quant_tables{1}; %载体图像量化表
% 隐写后的系数变化
fun = @(x) (x.data .* stego_step);
coeffs_s = blockproc(stego,[8 8],fun);
coeffs_s(diff==0) = C_COEFFS(diff==0);
S_STRUCT = C_STRUCT;
S_COEFFS = coeffs_s;
S_STRUCT.coef_arrays{1} = double(S_COEFFS);
jpeg_write(S_STRUCT,stego_Path);
elseif cover_QF<=attack_QF
cover = double(cover);
stego = double(stego);
% 隐写的修改
diff = stego - cover;
% 读取载体图像
C_STRUCT = jpeg_read(cover_Path);
C_COEFFS = C_STRUCT.coef_arrays{1};
C_QUANT = C_STRUCT.quant_tables{1}; %载体图像量化表
% 隐写后的系数变化
fun = @(x) (x.data .* stego_step);
coeffs_s = blockproc(stego,[8 8],fun);
coeffs_s(diff==0) = C_COEFFS(diff==0);
S_STRUCT = C_STRUCT;
S_COEFFS = coeffs_s;
S_STRUCT.coef_arrays{1} = double(S_COEFFS);
jpeg_write(S_STRUCT,stego_Path);
elseif cover_QF>attack_QF
cover = double(cover);
stego = double(stego);
% 隐写的修改
diff = stego - cover;
% 读取载体图像
C_STRUCT = jpeg_read(cover_Path);
C_COEFFS = C_STRUCT.coef_arrays{1};
C_QUANT = C_STRUCT.quant_tables{1}; %载体图像量化表
% 隐写后的系数变化
S_QUANT = quantizationTable(attack_QF);
fun = @(x) (x.data.*S_QUANT);
coeffs_uq = blockproc(stego,[8 8],fun);
fun = @(x) round(x.data./C_QUANT);
coeffs_q = blockproc(coeffs_uq,[8 8],fun);
fun = @(x) (x.data .* stego_step);
coeffs_s = blockproc(coeffs_q,[8 8],fun);
coeffs_s(diff==0) = C_COEFFS(diff==0);
S_STRUCT = C_STRUCT;
S_COEFFS = coeffs_s;
S_STRUCT.coef_arrays{1} = double(S_COEFFS);
jpeg_write(S_STRUCT,stego_Path);
elseif cover_QF>attack_QF
end

