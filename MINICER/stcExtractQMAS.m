function [stc_decoded_msg] = stcExtractQMAS(afterchannel_stego_Path, stc_n_msg_bits, cover_QF, stego_step,attack_QF)
% 
if attack_QF==0
C_QUANT = quantizationTable(cover_QF);
% 
S_STRUCT = jpeg_read(afterchannel_stego_Path);
S_COEFFS = S_STRUCT.coef_arrays{1};
S_QUANT = S_STRUCT.quant_tables{1}; %
% 
fun = @(x) (x.data.*S_QUANT);
coeffs_uq = blockproc(S_COEFFS,[8 8],fun);
fun = @(x) round(x.data./C_QUANT);
coeffs_q = blockproc(coeffs_uq,[8 8],fun);
fun = @(x) round(x.data ./ stego_step);
stego = blockproc(coeffs_q,[8 8],fun);
H = 10;
stc_decoded_msg = stc_ml_extract(int32(reshape(stego,1,[])), stc_n_msg_bits, H);
elseif cover_QF<=attack_QF
C_QUANT = quantizationTable(cover_QF);
% 
S_STRUCT = jpeg_read(afterchannel_stego_Path);
S_COEFFS = S_STRUCT.coef_arrays{1};
S_QUANT = S_STRUCT.quant_tables{1}; %
% -----------------------
% 
% fun = @(x) idct2(x.data.*S_QUANT);
% spa_uq = blockproc(S_COEFFS,[8 8],fun);
% spa_uq(spa_uq>127) = 127;
% spa_uq(spa_uq<-128) = -128;
% fun = @(x) dct2(x.data);
% coeffs_real = blockproc(round(spa_uq),[8 8],fun);
% % 
% fun = @(x) round(x.data ./C_QUANT);
% stego_dct = blockproc(coeffs_real,[8 8],fun);
% % fix
% % stego = fix(stego_dct/stego_step);
% % round
% fun = @(x) round(x.data ./ stego_step);
% stego = blockproc(stego_dct,[8 8],fun);
% ----------------
% 
fun = @(x) (x.data.*S_QUANT);
coeffs_uq = blockproc(S_COEFFS,[8 8],fun);
fun = @(x) round(x.data./C_QUANT);
coeffs_q = blockproc(coeffs_uq,[8 8],fun);
fun = @(x) round(x.data ./ stego_step);
stego = blockproc(coeffs_q,[8 8],fun);
% % 
% stego = round(S_COEFFS/stego_step);
% stego = S_COEFFS;
% stego = fix(S_COEFFS/stego_step);
% 
% stego = S_COEFFS;
H = 10;
stc_decoded_msg = stc_ml_extract(int32(reshape(stego,1,[])), stc_n_msg_bits, H);
elseif cover_QF>attack_QF
C_QUANT = quantizationTable(cover_QF);
% 
S_STRUCT = jpeg_read(afterchannel_stego_Path);
S_COEFFS = S_STRUCT.coef_arrays{1};
S_QUANT = S_STRUCT.quant_tables{1}; %
% -----------------------
% 
% fun = @(x) idct2(x.data.*S_QUANT);
% spa_uq = blockproc(S_COEFFS,[8 8],fun);
% spa_uq(spa_uq>127) = 127;
% spa_uq(spa_uq<-128) = -128;
% fun = @(x) dct2(x.data);
% coeffs_real = blockproc(round(spa_uq),[8 8],fun);
% % 
% fun = @(x) round(x.data ./C_QUANT);
% stego_dct = blockproc(coeffs_real,[8 8],fun);
% % fix
% % stego = fix(stego_dct/stego_step);
% % round
% fun = @(x) round(x.data ./ stego_step);
% stego = blockproc(stego_dct,[8 8],fun);
% ----------------
% 
fun = @(x) (x.data.*S_QUANT);
coeffs_uq = blockproc(S_COEFFS,[8 8],fun);
fun = @(x) round(x.data./S_QUANT);
coeffs_q = blockproc(coeffs_uq,[8 8],fun);
fun = @(x) round(x.data ./ stego_step);
stego = blockproc(coeffs_q,[8 8],fun);
% % 
% stego = round(S_COEFFS/stego_step);
% stego = S_COEFFS;
% stego = fix(S_COEFFS/stego_step);
% 
% stego = S_COEFFS;
H = 10;
stc_decoded_msg = stc_ml_extract(int32(reshape(stego,1,[])), stc_n_msg_bits, H);
end

