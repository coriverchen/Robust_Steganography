function testRobustUNICORE(cover_dir,stego_dir,payload,cover_QF,attack_QF,T,mode,distortion)
% 
afterchannel_stego_dir = [stego_dir,'_attackBy',num2str(attack_QF)]; 
if ~exist(afterchannel_stego_dir,'dir'); mkdir(afterchannel_stego_dir); end  %信道处理后载密图像所在文件夹
afterchannel_cover_dir = [cover_dir,'_compressedBy',num2str(attack_QF)]; 
if ~exist(afterchannel_cover_dir,'dir'); mkdir(afterchannel_cover_dir); end  %信道处理后载密图像所在文件夹
cover_num = 10000; %测试载体图像个数

dct0 = zeros(8,8);
spatail = zeros(8,8,64);
for i = 1 : 8
    for j = 1 : 8
        dct = dct0;
        dct(i,j) = dct(i,j) + 1;
        fun = @(x) dct2(x.data);
        spatail(:,:,j+(i-1)*8) = blockproc(double(dct.*quantizationTable(cover_QF)),[8 8],fun);
    end
end

poolnum = str2double(getenv('SLURM_CPUS_PER_TASK'));
parpool(poolnum);
% i_img = randperm(2000,1);
bit_error_rate = zeros(1,cover_num);
parfor i_img = 1:cover_num
% i_img = randperm(2000,1);
    % 图片地址
    cover_path = fullfile([cover_dir,'/',num2str(i_img),'.jpg']);
    stego_path = fullfile([stego_dir,'/',num2str(i_img),'.jpg']);
    afterchannel_stego_path = fullfile([afterchannel_stego_dir,'/',num2str(i_img),'.jpg']);
    afterchannel_cover_path = fullfile([afterchannel_cover_dir,'/',num2str(i_img),'.jpg']);
    try
    % 隐写
    [cover,rhoM,rhoP,modification] = preprocessUNICORE(cover_path,cover_QF,attack_QF,T,mode,afterchannel_cover_path,spatail,distortion);
    % 生成随机消息
    [msg,msg_len] = generateRandMsg(cover_path,payload);
    % STCs隐写
    % 载体
    cover1 = int32(reshape(cover,1,[]));
    % 失真
    costs = zeros(3,size(cover1,2),'single');
    costs(1,:) = reshape(rhoM,1,[]);
    costs(3,:) = reshape(rhoP,1,[]);
    % embed message   三元嵌  量化索引调制机制
    H = 10;
    [~, stc_msg,stc_n_msg_bits,~] = stc_pm1_pls_embed(int32(cover1), costs, uint8(msg), H);

    stego = reshape(stc_msg,size(cover,1),size(cover,2));
    % 生成最终的隐写后的图片
    generateStegoUNICORE(cover_path,stego_path,cover,modification,stego,afterchannel_stego_path,attack_QF,T,mode(3));

    % imwrit(imread())方法
    imwrite(imread(stego_Path),afterchannel_stego_Path,'quality',attack_QF);

    [stc_decoded_msg] = stcExtractUNICORE(afterchannel_stego_path, stc_n_msg_bits);
    % 计算每张图像的误码率
    bit_error = double(msg) - double(stc_decoded_msg);
    bit_error_number = sum(abs(bit_error));
    bit_error_rate(1,i_img) = bit_error_number/msg_len;
%      输出每张图像的误码率
%     fprintf('%s\n',['payload: ',num2str(payload),'  image_number: ',num2str(i_img),'  error_rate: ',num2str(bit_error_rate(1,i_img))]);
    catch
        bit_error_rate(1,i_img) = 0;
        fprintf('%s\n',['error at  image_number: ',num2str(i_img),', stc extracted wrong msg ']);
    end
end
    poolobj = gcp('nocreate');
        delete(poolobj);

% 输出所有图像的平均误码率
ave_error_rate = mean(bit_error_rate);
fprintf('%s\n',['payload: ',num2str(payload),'  ave_error_rate: ',num2str(ave_error_rate)]);
