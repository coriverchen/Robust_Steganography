function [VulnerableBlock] = PreprocessURA(precover_Path,cover_Path)
%     ��ͼ�����Ԥ������³����ǿ���ͼ��洢Ϊ����ͼ�񣬶�³���Խ����Ŀ�����¼��
% Ϊʧ������ṩ�ο���
PC_STRUCT = jpeg_read(precover_Path);
PC_COEFFS = PC_STRUCT.coef_arrays{1};
C_COEFFS = PC_COEFFS;
C_QUANT = PC_STRUCT.quant_tables{1}; %����ͼ��������
VulnerableBlock = cell(1,10);
VBindex = 0;
% ³������ͼ��������ƽ�����(�̶�������
% T = 8;
% idct�任������
fun = @(xl) (xl.*C_QUANT);
PC_COEFFS_UQ = blkproc(double(PC_COEFFS),[8 8],fun);
fun = @idct2;
precover_spa = blkproc(double(PC_COEFFS_UQ),[8 8],fun);
% ����������Ŀ�
[xm,xn] = size(precover_spa);
m_block = floor(xm/8);
n_block = floor(xn/8);
for bm = 1:m_block
    for bn = 1:n_block
        vulnerable = 0;
        for i = 1:8
            for j = 1:8
                if precover_spa((bm-1)*8+i,(bn-1)*8+j)>127 || precover_spa((bm-1)*8+i,(bn-1)*8+j)<-128 % �������
                    vulnerable = 1;
                    % ����³���Ե���,�˴��Կ�����ֱ������Ŀ���д���Ҫ��ǿ³
                    % ���ԵĻ������Խ��ͱ�׼��ּ�����
                    cover_spa = precover_spa((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8);
                    % �˷�����ʹ�ÿ����ȡ��������ϵ������ϵ����
                    cover_spa_abs = abs(cover_spa);
                    v_max = max(max(cover_spa_abs));
                    if cover_spa(find(v_max==cover_spa_abs))>0
                        alpha = 127/v_max;
                    else
                        alpha = 128/v_max;
                    end
                    cover_spa = alpha*cover_spa; 
                    % ����³��dctϵ����������0ȡ��
                    fun = @dct2;
                    cover_dct_uq = blkproc(double(cover_spa),[8 8],fun);
                    cover_dct = fix(cover_dct_uq./C_QUANT);
                    % �������н��е���
                    C_COEFFS((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8) = cover_dct;
                    % Ϊ��֤����������Խ��У�ͬ������VB
                    fun = @idct2;
                    ref_spa = blkproc(double(cover_dct.*C_QUANT),[8 8],fun);
                    ref_spa_abs = abs(ref_spa);
                    v_max = max(max(ref_spa_abs));
                    if ref_spa(find(v_max==ref_spa_abs))>0
                        alpha = 127/v_max;
                    else
                        alpha = 128/v_max;
                    end
                    if v_max<=127 alpha=1; end
                    ref_spa = alpha*ref_spa;
                    ref_dct_uq = blkproc(double(ref_spa),[8 8],fun);
                    ref_dct = fix(ref_dct_uq./C_QUANT);
                    VBindex = VBindex + 1;
                    VulnerableBlock{VBindex} = {bm,bn,ref_dct};
                    break;
                end
            end
            if vulnerable break; end
        end
    end
end
% д����ͼ��
C_STRUCT = PC_STRUCT;
C_STRUCT.coef_arrays{1} = C_COEFFS;
jpeg_write(C_STRUCT,cover_Path);
                
                



