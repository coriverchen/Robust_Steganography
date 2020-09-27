function test_compression_J2_JUNIWARD_15()
% Ƶ������ͼ�񹥻�����    
    clear all;
    clc;
%%  Setting
    addpath(genpath('F:\DMAS'));
    boot_dir = 'F:\DMAS';
  
    tab_65 = [11 8 7 11 17 28 36 43   %tab_65 ����ƽ���� tab_95 �� 7 ��
              8 8 10 13 18 41 42 39
              10 9 11 17 28 40 48 39
              10 12 15 20 36 61 56 43
              13 15 26 39 48 76 72 54
              17 25 39 45 57 73 79 64
              34 45 55 61 72 85 84 71
              50 64 67 69 78 70 72 69];        
    tab_75 = [8 6 5 8 12 20 26 31     %tab_75 ����ƽ���� tab_95 �� 5 ��
              6 6 7 10 13 29 30 28
              7 7 8 12 20 29 35 28
              7 9 11 15 26 44 40 31
              9 11 19 28 34 55 52 39
              12 18 28 32 41 52 57 46
              25 32 39 44 52 61 60 51
              36 46 48 49 56 50 52 50];
    tab_85 = [5 3 3 5 7 12 15 18     %tab_85 ����ƽ���� tab_95 �� 3 ��
              4 4 4 6 8 17 18 17
              4 4 5 7 12 17 21 17
              4 5 7 9 15 26 24 19
              5 7 11 17 20 33 31 23
              7 11 17 19 24 31 34 28
              15 19 23 26 31 36 36 30
              22 28 29 29 34 30 31 30];          
     tab_95 = [2 1 1 2 2 4 5 6     
               1 1 1 2 3 6 6 6
               1 1 2 2 4 6 7 6
               1 2 2 3 5 9 8 6
               2 2 4 6 7 11 10 8
               2 4 6 6 8 10 11 9
               5 6 8 9 10 12 12 10
               7 9 10 10 11 10 10 10];     
    cover_num = 1000;
    QF = 65; %�������������
    QF_attack = 95; %��������ʱʹ�õ��ŵ�JPEGѹ����������    
%%  %���ͼ��  ���������Ҹ��Ƶ�cover�ļ���
    BOSS_dir = fullfile(['F:\BOSS_QF',num2str(QF),'_1000']);
    cover_dir = fullfile(['F:\DMAS\database\BOSS_cover_',num2str(QF),'_STC2']);if ~exist(cover_dir,'dir'); mkdir(cover_dir); end
    for ii=1:cover_num
        cov_img = [BOSS_dir,'\',num2str(ii),'.jpg'];
        ste_img = [cover_dir,'\',num2str(ii),'.jpg'];
        cov = imread(cov_img);
        imwrite(uint8(cov),ste_img);
    end
%% ����
    sum_img = zeros(1,10);
    for i = 1:10
        sum_img(1,i) = cover_num;
    end
    error_rate = zeros(10,cover_num);
    ave_error_rate = zeros(1,10);   
    for i_img = 1:cover_num
        cover_Path = fullfile([cover_dir,'\',num2str(i_img),'.jpg']);        
        C_STRUCT = jpeg_read(cover_Path);
        C_COEFFS = C_STRUCT.coef_arrays{1};  
        nzAC = nnz(C_COEFFS) - nnz(C_COEFFS(1:8:end,1:8:end));
        if (nzAC<1000)  %��0ϵ�����٣�ͼ���ʺ�Ƕ��
            for i = 1:5
                sum_img(1,i) = sum_img(1,i)-1;
            end
            continue;
        end
        cover = imread(cover_Path);   
%%     % ���� +-1 ʧ��
        [rho1_P,rho1_M] = J_UNIWARD_D(cover_Path,1);         
%%     % Ԥ����֪�Ĺ�����������
        [cover_lsb75,rho75,change75,rhoP75,rhoM75] = ycl(cover,rho1_P,rho1_M,tab_65);    %%%%%%%%%%%����%%%%%%%%
        for payload = 0.01:0.01:0.1
            try
                % ����������ȷֲ��Ķ�������Ϣ
                msg_len = ceil(payload*nzAC);
                msg = round( rand(1,msg_len) );  % ������
               
%%            % Ƕ��
                xh = round( payload *100);
                stego_dir = fullfile(['F:\DMAS\database\BOSS_',num2str(payload),'_stego_',num2str(QF),'_STC2']);if ~exist(stego_dir,'dir'); mkdir(stego_dir); end
                stego_Path = fullfile([stego_dir,'\',num2str(i_img),'.jpg']);                
                [suc,real_msg,rs_encoded_msg_len] = dmas(msg,msg_len,cover_Path,cover_lsb75,rho75,change75,QF,stego_Path);
%%            % JPEGѹ������            
                attack_stego_dir = fullfile(['F:\DMAS\database\BOSS_',num2str(payload),'_stego_',num2str(QF),'_attack_',num2str(QF_attack),'_STC2']);if ~exist(attack_stego_dir,'dir'); mkdir(attack_stego_dir); end
                attack_stego_Path = fullfile([attack_stego_dir,'\',num2str(i_img),'.jpg']);          
                suc = img_attack_J(stego_Path,attack_stego_Path,7,QF_attack,QF_attack);    %%%%%%%%%%����%%%%%%%%%%%%
%%            % ��ȡ    
                error_rate(xh,i_img) = extract(attack_stego_Path,real_msg,rs_encoded_msg_len,tab_65);   %%%%%%%%%%����%%%%%%%%%%%%
                
                fprintf('%s\n',['payload: ',num2str(payload),'  image_number: ',num2str(i_img),'  Done!']);  
            catch
                sum_img(1,xh) = sum_img(1,xh) - 1;
                fprintf('%s\n',['payload: ',num2str(payload),'  image_number: ',num2str(i_img),'  Error!']);  
                continue;
            end
        end
    end
    
    for payload = 0.01:0.01:0.1
        xh = round( payload *100);
        ave_error_rate(1,xh) = mean(error_rate(xh,:))*cover_num/sum_img(1,xh);
    end    
%% ���Խ�����

fid=fopen(['F:\DMAS\output\result_STC2.txt'], 'at');
fprintf(fid,'%s\n','*******************************');
fprintf(fid,'%s\n',datestr(now,31));
fprintf(fid,'%s\n',['���ݿ�: ','BOSS_',num2str(QF)]);
fprintf(fid,'%s\n',['ѹ��QF: ',num2str(QF_attack)]);
fprintf(fid,'%s\n',['ʵ������: ','BOSS���ѡ',num2str(cover_num),'��']);
fprintf(fid,'%s\n',['Ƕ����ԭͼ��������ȡʱ��ԭͼ������   STC��ԪǶ']);
fprintf(fid,'%s\n',['ʧ��: ','J_UNIWARD   15 ��DCT�ɸ� ']);
fprintf(fid,'%s\n','���:');
fprintf(fid,'%s\n','payload: ');
fprintf(fid,'%s\n',num2str([0.10:0.01:0.1]));
fprintf(fid,'%s\n','ave_error_rate: ');
fprintf(fid,'%s\n',num2str(ave_error_rate));
fclose(fid);

disp([0.01:0.01:0.1]);
disp(ave_error_rate);

save(['F:\DMAS\output\STC2_cover',num2str(QF),'_attack',num2str(QF_attack),'_a.mat'],'error_rate','ave_error_rate');    
end