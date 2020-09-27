function Test_Robustness_GMAS_JUNIWARD()
%% ³����д�㷨GMAS���罻����ƽ̨ Facebook ʵ���ŵ��ϵ�³���Բ��Դ���
    clear all;
    clc;
%%  ��������
    cover_dir = '.\cover_dir_QF65'; %����ͼ�������ļ���
    stego_dir = '.\stego_dir'; if ~exist(stego_dir,'dir'); mkdir(stego_dir); end  %����ͼ�������ļ���
    afterchannel_stego_dir = '.\afterchannel_stego_dir'; if ~exist(afterchannel_stego_dir,'dir'); mkdir(afterchannel_stego_dir); end  %�ŵ����������ͼ�������ļ���     
    cover_num = 10; %��������ͼ�����
    cover_QF = 65; %����ͼ�����������
    Facebook_attack_QF = 71; %ģ��Facebook�ŵ��������ӣ���Facebook����������QF����71��ͼ�񶼽���QFΪ71��ѹ��
    payload = 0.1; %Ƕ����   
    
    bit_error_rate = zeros(1,cover_num); %��¼����ͼ���������
%%  ��ϢǶ��    
    for i_img = 1:cover_num
        cover_Path = fullfile([cover_dir,'\',num2str(i_img),'.jpg']);   
        stego_Path = fullfile([stego_dir,'\',num2str(i_img),'.jpg']);    
        afterchannel_stego_Path = fullfile([afterchannel_stego_dir,'\',num2str(i_img),'.jpg']);   
        
        C_STRUCT = jpeg_read(cover_Path);
        C_COEFFS = C_STRUCT.coef_arrays{1};  
        C_QUANT = C_STRUCT.quant_tables{1}; %����ͼ��������
        nzAC = nnz(C_COEFFS) - nnz(C_COEFFS(1:8:end,1:8:end));
%  ����������ȷֲ��Ķ�����ԭʼ������Ϣ�������в������
        raw_msg_len = ceil(payload*nzAC);
        raw_msg = round( rand(1,raw_msg_len) ); %ԭʼ������Ϣ��������    
        nn = 31; kk = 15; mm = 5;   %����RS��31,15�����������ʱ��������Ϣ�ĳ������� kk*mm=75 ��������     
        zeros_padding_num = ceil(raw_msg_len/kk/mm)*kk*mm - raw_msg_len; %��Ҫ����ĸ���
        zeros_padding_msg = zeros(1, raw_msg_len + zeros_padding_num); %���� kk*mm=75 ������������߲���
        zeros_padding_msg(1:raw_msg_len) = raw_msg;
        zeros_padding_msg(raw_msg_len+1 : raw_msg_len + zeros_padding_num) = 0;  %���������õ���������Ϣ����ʵ��ҪǶ���������Ϣ
%  ���� RS��31,15����������Ϣ����        
        [rs_encoded_msg] = rs_encode_yxz(zeros_padding_msg,nn,kk); 
%  ���øĽ��ķǶԳ�ʧ���ܼ�������Ԫ�ص� +-1 �ǶԳ�ʧ��
        [rho1_P, rho1_M] = J_UNIWARD_Asy_cost(cover_Path);         
%  ��ϢǶ��Ԥ�������ݹ��嶶�����Ƽ����޸�ʧ����޸ľ��룩
        [cover_round, change_p, change_m, rho_p, rho_m] = gmas(cover_Path, rho1_P, rho1_M, C_QUANT);       
%  ������ԪSTC������ϢǶ��      
        [suc, stc_n_msg_bits] = stc3_embed(rs_encoded_msg, cover_Path, cover_round, rho_p, rho_m, change_p, change_m, cover_QF, stego_Path);
%%  ģ�� Facebook ѹ��  Facebook_attack_QF = 71   
        imwrite(imread(stego_Path),afterchannel_stego_Path,'quality',Facebook_attack_QF);    
%%  ʵ�ʵ��罻����ƽ̨Facebook�ϲ���
%         breakpoint = 1; %��������ʱ�ڴ˴����öϵ�
%         %������ͼ�� stego_Path �ϴ���ʵ�ʵ��罻����ƽ̨Facebook�ϣ��ڽ������أ����غ��ͼ������Ϊ��afterchannel_stego_Path
%         %����ִ�г��򼴿ɡ�        
%%  ��Ϣ��ȡ
%  ������ԪSTC������Ϣ��ȡ
        [stc_decoded_msg] = stc3_extract(afterchannel_stego_Path, stc_n_msg_bits, C_QUANT);   
%  ���� RS��31,15����������Ϣ����         
        [rs_decoded_msg] = rs_decode_yxz(double(stc_decoded_msg), nn, kk);
%  ȥ����Ϣĩβ��������        
        extract_raw_msg = rs_decoded_msg(1:raw_msg_len); %ȥ������
%%  ����ÿ��ͼ���������        
        bit_error = double(raw_msg) - double(extract_raw_msg);
        bit_error_number = sum(abs(bit_error));
        bit_error_rate(1,i_img) = bit_error_number/raw_msg_len;
%  ���ÿ��ͼ���������               
        fprintf('%s\n',['payload: ',num2str(payload),'  image_number: ',num2str(i_img),'  error_rate: ',num2str(bit_error_rate(1,i_img))]);  

    end
%  �������ͼ���ƽ��������
    ave_error_rate = mean(bit_error_rate);
    fprintf('%s\n',['payload: ',num2str(payload),'  ave_error_rate: ',num2str(ave_error_rate)]);  
  
end
