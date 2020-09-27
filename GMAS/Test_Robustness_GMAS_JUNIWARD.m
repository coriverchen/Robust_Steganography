function Test_Robustness_GMAS_JUNIWARD()
%% 鲁棒隐写算法GMAS在社交网络平台 Facebook 实际信道上的鲁棒性测试代码
    clear all;
    clc;
%%  参数设置
    cover_dir = '.\cover_dir_QF65'; %载体图像所在文件夹
    stego_dir = '.\stego_dir'; if ~exist(stego_dir,'dir'); mkdir(stego_dir); end  %载密图像所在文件夹
    afterchannel_stego_dir = '.\afterchannel_stego_dir'; if ~exist(afterchannel_stego_dir,'dir'); mkdir(afterchannel_stego_dir); end  %信道处理后载密图像所在文件夹     
    cover_num = 10; %测试载体图像个数
    cover_QF = 65; %载体图像的质量因子
    Facebook_attack_QF = 71; %模拟Facebook信道质量因子，因Facebook对质量因子QF低于71的图像都进行QF为71的压缩
    payload = 0.1; %嵌入率   
    
    bit_error_rate = zeros(1,cover_num); %记录测试图像的误码率
%%  消息嵌入    
    for i_img = 1:cover_num
        cover_Path = fullfile([cover_dir,'\',num2str(i_img),'.jpg']);   
        stego_Path = fullfile([stego_dir,'\',num2str(i_img),'.jpg']);    
        afterchannel_stego_Path = fullfile([afterchannel_stego_dir,'\',num2str(i_img),'.jpg']);   
        
        C_STRUCT = jpeg_read(cover_Path);
        C_COEFFS = C_STRUCT.coef_arrays{1};  
        C_QUANT = C_STRUCT.quant_tables{1}; %载体图像量化表
        nzAC = nnz(C_COEFFS) - nnz(C_COEFFS(1:8:end,1:8:end));
%  随机产生均匀分布的二进制原始秘密信息，并进行补零操作
        raw_msg_len = ceil(payload*nzAC);
        raw_msg = round( rand(1,raw_msg_len) ); %原始秘密信息的行向量    
        nn = 31; kk = 15; mm = 5;   %利用RS（31,15）分组纠错码时，秘密信息的长度需是 kk*mm=75 的整数倍     
        zeros_padding_num = ceil(raw_msg_len/kk/mm)*kk*mm - raw_msg_len; %需要补零的个数
        zeros_padding_msg = zeros(1, raw_msg_len + zeros_padding_num); %不够 kk*mm=75 的整数倍，后边补零
        zeros_padding_msg(1:raw_msg_len) = raw_msg;
        zeros_padding_msg(raw_msg_len+1 : raw_msg_len + zeros_padding_num) = 0;  %补零操作后得到的秘密信息，即实际要嵌入的秘密信息
%  利用 RS（31,15）对秘密信息编码        
        [rs_encoded_msg] = rs_encode_yxz(zeros_padding_msg,nn,kk); 
%  利用改进的非对称失真框架计算载体元素的 +-1 非对称失真
        [rho1_P, rho1_M] = J_UNIWARD_Asy_cost(cover_Path);         
%  消息嵌入预处理（根据广义抖动调制计算修改失真和修改距离）
        [cover_round, change_p, change_m, rho_p, rho_m] = gmas(cover_Path, rho1_P, rho1_M, C_QUANT);       
%  利用三元STC进行消息嵌入      
        [suc, stc_n_msg_bits] = stc3_embed(rs_encoded_msg, cover_Path, cover_round, rho_p, rho_m, change_p, change_m, cover_QF, stego_Path);
%%  模拟 Facebook 压缩  Facebook_attack_QF = 71   
        imwrite(imread(stego_Path),afterchannel_stego_Path,'quality',Facebook_attack_QF);    
%%  实际的社交网络平台Facebook上测试
%         breakpoint = 1; %程序运行时在此处设置断点
%         %将载密图像 stego_Path 上传到实际的社交网络平台Facebook上，在进行下载，下载后的图像命名为：afterchannel_stego_Path
%         %继续执行程序即可。        
%%  消息提取
%  利用三元STC进行消息提取
        [stc_decoded_msg] = stc3_extract(afterchannel_stego_Path, stc_n_msg_bits, C_QUANT);   
%  利用 RS（31,15）对秘密信息解码         
        [rs_decoded_msg] = rs_decode_yxz(double(stc_decoded_msg), nn, kk);
%  去掉消息末尾所补的零        
        extract_raw_msg = rs_decoded_msg(1:raw_msg_len); %去掉补零
%%  计算每张图像的误码率        
        bit_error = double(raw_msg) - double(extract_raw_msg);
        bit_error_number = sum(abs(bit_error));
        bit_error_rate(1,i_img) = bit_error_number/raw_msg_len;
%  输出每张图像的误码率               
        fprintf('%s\n',['payload: ',num2str(payload),'  image_number: ',num2str(i_img),'  error_rate: ',num2str(bit_error_rate(1,i_img))]);  

    end
%  输出所有图像的平均误码率
    ave_error_rate = mean(bit_error_rate);
    fprintf('%s\n',['payload: ',num2str(payload),'  ave_error_rate: ',num2str(ave_error_rate)]);  
  
end
