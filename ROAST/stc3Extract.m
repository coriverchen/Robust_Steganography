function [stc_decoded_msg] = stc3Extract(afterchannel_stego_Path, stc_n_msg_bits, C_QUANT)
% ��������dctϵ����ȡ����
% ���ȼ����ŵ������ͼ��ķ�����dctϵ��
bits = 8;
stego_spa = imread(afterchannel_stego_Path);
stego_spa = double(stego_spa) - 2^(round(bits)-1);
t = dctmtx(8);
fun = @(xl) (t*xl*(t'));
stego_dct_uq = blkproc(stego_spa,[8 8],fun);%�ֿ�DCT�任
% ���ż�����ԭʼ�������µ�������dctϵ��
fun = @(xl) (xl./C_QUANT);
stego_dct = round(blkproc(double(stego_dct_uq),[8 8],fun));
% ֱ�Ӵ��������dctϵ���н���stc����
H = 10;
stc_decoded_msg = stc_ml_extract(int32(reshape(stego_dct,1,[])), stc_n_msg_bits, H);

