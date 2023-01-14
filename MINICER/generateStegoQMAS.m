function generateStegoQMAS(cover_Path,stego_Path,cover,stego,stego_step,cover_QF,attack_QF)
% �������յ���дͼ��
if attack_QF==0
cover = double(cover);
stego = double(stego);
% ��д���޸�
diff = stego - cover;
% ��ȡ����ͼ��
C_STRUCT = jpeg_read(cover_Path);
C_COEFFS = C_STRUCT.coef_arrays{1};
C_QUANT = C_STRUCT.quant_tables{1}; %����ͼ��������
% ��д���ϵ���仯
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
% ��д���޸�
diff = stego - cover;
% ��ȡ����ͼ��
C_STRUCT = jpeg_read(cover_Path);
C_COEFFS = C_STRUCT.coef_arrays{1};
C_QUANT = C_STRUCT.quant_tables{1}; %����ͼ��������
% ��д���ϵ���仯
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
% ��д���޸�
diff = stego - cover;
% ��ȡ����ͼ��
C_STRUCT = jpeg_read(cover_Path);
C_COEFFS = C_STRUCT.coef_arrays{1};
C_QUANT = C_STRUCT.quant_tables{1}; %����ͼ��������
% ��д���ϵ���仯
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

