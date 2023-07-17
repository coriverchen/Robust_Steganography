function TestRobustnessURA_JUNIWARD(precover_dir,cover_dir,stego_dir,attack_QF,payload)
% 检验向上鲁棒隐写的隐写正确率

%% 参数设置
%     cover_dir = '.\cover_QF65'; %载体图像所在文件夹
%     stego_dir = ['.\stego_dir',num2str(Facebook_attack_QF)]; if ~exist(stego_dir,'dir'); mkdir(stego_dir); end  %载密图像所在文件夹
afterchannel_stego_dir = ['.\afterchannel_stego_dir',num2str(attack_QF)]; if ~exist(afterchannel_stego_dir,'dir'); mkdir(afterchannel_stego_dir); end  %信道处理后载密图像所在文件夹
cover_num = 10000; %测试载体图像个数
% cover_QF = 65; %载体图像的质量因子
%     Facebook_attack_QF; %模拟Facebook信道质量因子，因Facebook对质量因子QF低于71的图像都进行QF为71的压缩
%     payload; %嵌入率

% bit_error_rate = zeros(1,cover_num); %记录测试图像的误码率

%     poolnum = str2double(getenv('SLURM_CPUS_PER_TASK'))
%     parpool(poolnum);
parfor i_img = 1:cover_num
    precover_Path = fullfile([precover_dir,'\',num2str(i_img),'.jpg']);
    cover_Path = fullfile([cover_dir,'\',num2str(i_img),'.jpg']);
    stego_Path = fullfile([stego_dir,'\',num2str(i_img),'.jpg']);
    afterchannel_stego_Path = fullfile([afterchannel_stego_dir,'\',num2str(i_img),'.jpg']);
    %%  消息嵌入
    PC_STRUCT = jpeg_read(precover_Path);
    PC_COEFFS = PC_STRUCT.coef_arrays{1};
    C_QUANT = PC_STRUCT.quant_tables{1}; %载体图像量化表
    nzAC = nnz(PC_COEFFS) - nnz(PC_COEFFS(1:8:end,1:8:end));
    
     % 对图像进行预处理，产生最终载体
    [VulnerableBlock] = PreprocessURA(precover_Path,cover_Path);
    
     if payload
    %  随机产生均匀分布的二进制原始秘密信息，并进行补零操作
    raw_msg_len = ceil(payload*nzAC);
    raw_msg = round( rand(1,raw_msg_len) ); %原始秘密信息的行向量
    % RS校验编码
    nn = 31; kk = 15; mm = 5;   %利用RS（31,15）分组纠错码时，秘密信息的长度需是 kk*mm=75 的整数倍
    zeros_padding_num = ceil(raw_msg_len/kk/mm)*kk*mm - raw_msg_len; %需要补零的个数
    zeros_padding_msg = zeros(1, raw_msg_len + zeros_padding_num); %不够 kk*mm=75 的整数倍，后边补零
    zeros_padding_msg(1:raw_msg_len) = raw_msg;
    zeros_padding_msg(raw_msg_len+1 : raw_msg_len + zeros_padding_num) = 0;  %补零操作后得到的秘密信息，即实际要嵌入的秘密信息
    %  利用 RS（31,15）对秘密信息编码
    [rs_encoded_msg] = rs_encode_yxz(zeros_padding_msg,nn,kk);
%     % 暂时不使用RS校验码
%     rs_encoded_msg = raw_msg;
    %  利用改进的非对称失真框架计算载体元素的 +-1 非对称失真
    [rho1_P, rho1_M] = J_UNIWARD_Asy_cost(cover_Path);
    % 根据鲁棒性调制失真
    [rho_p,rho_m] = CostUR(rho1_P,rho1_M,VulnerableBlock,cover_Path,0,1);
    
   try 
    %  利用三元STC进行消息嵌入
    [stc_n_msg_bits] = stc3Embed(cover_Path,stego_Path,rho_p,rho_m,rs_encoded_msg);
    %%  模拟 Facebook 压缩  Facebook_attack_QF = 71
    imwrite(imread(stego_Path),afterchannel_stego_Path,'quality',attack_QF);
    % 高斯滤波
%     suc = img_attack_J(stego_Path,afterchannel_stego_Path,2,0.3,Facebook_attack_QF);
    %%  实际的社交网络平台Facebook上测试
    %         breakpoint = 1; %程序运行时在此处设置断点
    %         %将载密图像 stego_Path 上传到实际的社交网络平台Facebook上，在进行下载，下载后的图像命名为：afterchannel_stego_Path
    %         %继续执行程序即可。
    %%  消息提取
    %  利用三元STC进行消息提取
    [stc_decoded_msg] = stc3Extract(afterchannel_stego_Path, stc_n_msg_bits, C_QUANT);
    %  利用 RS（31,15）对秘密信息解码
    [rs_decoded_msg] = rs_decode_yxz(double(stc_decoded_msg), nn, kk);
%     %  去掉消息末尾所补的零
    extract_raw_msg = rs_decoded_msg(1:raw_msg_len); %去掉补零
%     % 暂时不用RScode
%     extract_raw_msg = stc_decoded_msg;
    %%  计算每张图像的误码率
    bit_error = double(raw_msg) - double(extract_raw_msg);
    bit_error_number = sum(abs(bit_error));
    bit_error_rate(1,i_img) = bit_error_number/raw_msg_len;
%      输出每张图像的误码率
%     fprintf('%s\n',['payload: ',num2str(payload),'  image_number: ',num2str(i_img),'  error_rate: ',num2str(bit_error_rate(1,i_img))]);
    catch
        bit_error_rate(1,i_img) = 0;
        fprintf('%s\n',['error at  image_number: ',num2str(i_img),', stc extracted wrong msg ']);
    end
    end
end

    poolobj = gcp('nocreate');
        delete(poolobj);

%  输出所有图像的平均误码率
ave_error_rate = mean(bit_error_rate);
fprintf('%s\n',['payload: ',num2str(payload),'  ave_error_rate: ',num2str(ave_error_rate)]);
