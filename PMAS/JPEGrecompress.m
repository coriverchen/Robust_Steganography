function S_STRUCT = JPEGrecompress(input_path,output_path,QF,save,color)
% ��matlabʵ�ֵ�JPEG��ѹ����������imwrite��imread�������Ĳ�һ��
% �������ɽ���ļ���Ȼ�����ϵ������
if color
    if isa(input_path,'char')
        imwrite(imread(input_path),output_path,'quality',QF);
        S_STRUCT = jpeg_read(output_path);
    elseif isa(input_path,'struct')
        jpeg_write(input_path,output_path);
        imwrite(imread(output_path),output_path,'quality',QF);
        S_STRUCT = jpeg_read(output_path);
    end
else
%% ����Ϊ�ļ�
if isa(input_path,'char')
    imwrite(imread(input_path),output_path,'quality',QF);
    
    C_STRUCT = jpeg_read(input_path);
    C_COEFFS = C_STRUCT.coef_arrays{1};
    C_QUANT = C_STRUCT.quant_tables{1}; %����ͼ��������
    % ���������dctϵ��
    fun = @(x) idct2(x.data.*C_QUANT);
    spa_uq = blockproc(C_COEFFS,[8 8],fun);
    spa_uq(spa_uq>127) = 127;
    spa_uq(spa_uq<-128) = -128;
    fun = @(x) dct2(x.data);
    coeffs_real = blockproc(round(spa_uq),[8 8],fun);
    
    S_STRUCT = jpeg_read(output_path);
    S_QUANT = S_STRUCT.quant_tables{1}; %����ͼ��������
    fun = @(x) round(x.data ./S_QUANT);
    S_COEFFS = blockproc(coeffs_real,[8 8],fun);
    S_STRUCT.coef_arrays{1} = S_COEFFS;
    if save   % ���Ҫ����
        jpeg_write(S_STRUCT,output_path);
    end
    
elseif isa(input_path,'struct')
    %% ����Ϊ�ṹ��
    C_STRUCT = input_path;
    
    jpeg_write(C_STRUCT,output_path);
    imwrite(imread(output_path),output_path,'quality',QF);
    
    C_COEFFS = C_STRUCT.coef_arrays{1};
    C_QUANT = C_STRUCT.quant_tables{1}; %����ͼ��������
    % ���������dctϵ��
    fun = @(x) idct2(x.data.*C_QUANT);
    spa_uq = blockproc(C_COEFFS,[8 8],fun);
    spa_uq(spa_uq>127) = 127;
    spa_uq(spa_uq<-128) = -128;
    fun = @(x) dct2(x.data);
    coeffs_real = blockproc(round(spa_uq),[8 8],fun);
    
    S_STRUCT = jpeg_read(output_path);
    S_QUANT = S_STRUCT.quant_tables{1}; %����ͼ��������
    fun = @(x) round(x.data ./S_QUANT);
    S_COEFFS = blockproc(coeffs_real,[8 8],fun);
    S_STRUCT.coef_arrays{1} = S_COEFFS;
    if save   % ���Ҫ����
        jpeg_write(S_STRUCT,output_path);
    end
end
end