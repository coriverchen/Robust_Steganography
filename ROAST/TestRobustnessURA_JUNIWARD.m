function TestRobustnessURA_JUNIWARD(precover_dir,cover_dir,stego_dir,attack_QF,payload)
% ��������³����д����д��ȷ��

%% ��������
%     cover_dir = '.\cover_QF65'; %����ͼ�������ļ���
%     stego_dir = ['.\stego_dir',num2str(Facebook_attack_QF)]; if ~exist(stego_dir,'dir'); mkdir(stego_dir); end  %����ͼ�������ļ���
afterchannel_stego_dir = ['.\afterchannel_stego_dir',num2str(attack_QF)]; if ~exist(afterchannel_stego_dir,'dir'); mkdir(afterchannel_stego_dir); end  %�ŵ����������ͼ�������ļ���
cover_num = 10000; %��������ͼ�����
% cover_QF = 65; %����ͼ�����������
%     Facebook_attack_QF; %ģ��Facebook�ŵ��������ӣ���Facebook����������QF����71��ͼ�񶼽���QFΪ71��ѹ��
%     payload; %Ƕ����

% bit_error_rate = zeros(1,cover_num); %��¼����ͼ���������

%     poolnum = str2double(getenv('SLURM_CPUS_PER_TASK'))
%     parpool(poolnum);
parfor i_img = 1:cover_num
    precover_Path = fullfile([precover_dir,'\',num2str(i_img),'.jpg']);
    cover_Path = fullfile([cover_dir,'\',num2str(i_img),'.jpg']);
    stego_Path = fullfile([stego_dir,'\',num2str(i_img),'.jpg']);
    afterchannel_stego_Path = fullfile([afterchannel_stego_dir,'\',num2str(i_img),'.jpg']);
    %%  ��ϢǶ��
    PC_STRUCT = jpeg_read(precover_Path);
    PC_COEFFS = PC_STRUCT.coef_arrays{1};
    C_QUANT = PC_STRUCT.quant_tables{1}; %����ͼ��������
    nzAC = nnz(PC_COEFFS) - nnz(PC_COEFFS(1:8:end,1:8:end));
    
     % ��ͼ�����Ԥ����������������
    [VulnerableBlock] = PreprocessURA(precover_Path,cover_Path);
    
     if payload
    %  ����������ȷֲ��Ķ�����ԭʼ������Ϣ�������в������
    raw_msg_len = ceil(payload*nzAC);
    raw_msg = round( rand(1,raw_msg_len) ); %ԭʼ������Ϣ��������
    % RSУ�����
    nn = 31; kk = 15; mm = 5;   %����RS��31,15�����������ʱ��������Ϣ�ĳ������� kk*mm=75 ��������
    zeros_padding_num = ceil(raw_msg_len/kk/mm)*kk*mm - raw_msg_len; %��Ҫ����ĸ���
    zeros_padding_msg = zeros(1, raw_msg_len + zeros_padding_num); %���� kk*mm=75 ������������߲���
    zeros_padding_msg(1:raw_msg_len) = raw_msg;
    zeros_padding_msg(raw_msg_len+1 : raw_msg_len + zeros_padding_num) = 0;  %���������õ���������Ϣ����ʵ��ҪǶ���������Ϣ
    %  ���� RS��31,15����������Ϣ����
    [rs_encoded_msg] = rs_encode_yxz(zeros_padding_msg,nn,kk);
%     % ��ʱ��ʹ��RSУ����
%     rs_encoded_msg = raw_msg;
    %  ���øĽ��ķǶԳ�ʧ���ܼ�������Ԫ�ص� +-1 �ǶԳ�ʧ��
    [rho1_P, rho1_M] = J_UNIWARD_Asy_cost(cover_Path);
    % ����³���Ե���ʧ��
    [rho_p,rho_m] = CostUR(rho1_P,rho1_M,VulnerableBlock,cover_Path,0,1);
    
   try 
    %  ������ԪSTC������ϢǶ��
    [stc_n_msg_bits] = stc3Embed(cover_Path,stego_Path,rho_p,rho_m,rs_encoded_msg);
    %%  ģ�� Facebook ѹ��  Facebook_attack_QF = 71
    imwrite(imread(stego_Path),afterchannel_stego_Path,'quality',attack_QF);
    % ��˹�˲�
%     suc = img_attack_J(stego_Path,afterchannel_stego_Path,2,0.3,Facebook_attack_QF);
    %%  ʵ�ʵ��罻����ƽ̨Facebook�ϲ���
    %         breakpoint = 1; %��������ʱ�ڴ˴����öϵ�
    %         %������ͼ�� stego_Path �ϴ���ʵ�ʵ��罻����ƽ̨Facebook�ϣ��ڽ������أ����غ��ͼ������Ϊ��afterchannel_stego_Path
    %         %����ִ�г��򼴿ɡ�
    %%  ��Ϣ��ȡ
    %  ������ԪSTC������Ϣ��ȡ
    [stc_decoded_msg] = stc3Extract(afterchannel_stego_Path, stc_n_msg_bits, C_QUANT);
    %  ���� RS��31,15����������Ϣ����
    [rs_decoded_msg] = rs_decode_yxz(double(stc_decoded_msg), nn, kk);
%     %  ȥ����Ϣĩβ��������
    extract_raw_msg = rs_decoded_msg(1:raw_msg_len); %ȥ������
%     % ��ʱ����RScode
%     extract_raw_msg = stc_decoded_msg;
    %%  ����ÿ��ͼ���������
    bit_error = double(raw_msg) - double(extract_raw_msg);
    bit_error_number = sum(abs(bit_error));
    bit_error_rate(1,i_img) = bit_error_number/raw_msg_len;
%      ���ÿ��ͼ���������
%     fprintf('%s\n',['payload: ',num2str(payload),'  image_number: ',num2str(i_img),'  error_rate: ',num2str(bit_error_rate(1,i_img))]);
    catch
        bit_error_rate(1,i_img) = 0;
        fprintf('%s\n',['error at  image_number: ',num2str(i_img),', stc extracted wrong msg ']);
    end
    end
end

    poolobj = gcp('nocreate');
        delete(poolobj);

%  �������ͼ���ƽ��������
ave_error_rate = mean(bit_error_rate);
fprintf('%s\n',['payload: ',num2str(payload),'  ave_error_rate: ',num2str(ave_error_rate)]);
