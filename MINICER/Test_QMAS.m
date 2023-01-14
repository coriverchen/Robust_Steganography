function Test_QMAS(cover_dir,stego_dir,payload,cover_QF,attack_QF)
% 
afterchannel_stego_dir = [stego_dir,'_attackBy',num2str(attack_QF)]; if ~exist(afterchannel_stego_dir,'dir'); mkdir(afterchannel_stego_dir); end  %信道处理后载密图像所在文件夹
cover_num = 1; %number of test images

% cumpute DCT coefficients to spatial
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

% poolnum = str2double(getenv('SLURM_CPUS_PER_TASK'));
% parpool(poolnum);
for i_img = 1:cover_num
    % image address
    cover_Path = fullfile([cover_dir,'\',num2str(i_img),'.jpg']);
    stego_Path = fullfile([stego_dir,'\',num2str(i_img),'.jpg']);
    afterchannel_stego_Path = fullfile([afterchannel_stego_dir,'\',num2str(i_img),'.jpg']);
    %% stegaongraphy
    stego_step = ones(8,8); % 
    % pre-process
    try
    [cover,rhoM,rhoP,wetratei] = preprocessQIM(cover_Path,stego_step,cover_QF,attack_QF,spatail);
    % message
    [msg,msg_len] = generateRandMsg(cover_Path,payload);
    % STC embedding
    % cover
    cover1 = int32(reshape(cover,1,[]));
    % distortion
    costs = zeros(3,size(cover1,2),'single');
    costs(1,:) = reshape(rhoM,1,[]);
    costs(3,:) = reshape(rhoP,1,[]);
    % embed message   
    H = 10;
    [~, stc_msg,stc_n_msg_bits,~] = stc_pm1_pls_embed(int32(cover1), costs, uint8(msg), H);
    stc_extract_msg2 = stc_ml_extract(int32(stc_msg), stc_n_msg_bits, H); % extract message
    stego = reshape(stc_msg,size(cover,1),size(cover,2));
    % generate final embedded image
    generateStegoQMAS(cover_Path,stego_Path,cover,stego,stego_step,cover_QF,attack_QF);
    %%  Simulate JPEG compression 
    if attack_QF==0
     breakpoint = 1; % Here you can help with manual processing
    
    else
    % imwrit(imread())方法
    imwrite(imread(stego_Path),afterchannel_stego_Path,'quality',attack_QF);
   
    end
    %%  extract message
    [stc_decoded_msg] = stcExtractQMAS(afterchannel_stego_Path, stc_n_msg_bits, cover_QF, stego_step,attack_QF);
    %%  cumpute error rate
    bit_error = double(msg) - double(stc_decoded_msg);
    bit_error_number = sum(abs(bit_error));
    bit_error_rate(1,i_img) = bit_error_number/msg_len;
    wet_rate(1,i_img) = wetratei;
%      output error rate
%     fprintf('%s\n',['payload: ',num2str(payload),'  image_number: ',num2str(i_img),'  error_rate: ',num2str(bit_error_rate(1,i_img)),'  wet_rate:',num2str(wet_rate(1,i_img))]);
    catch
        bit_error_rate(1,i_img) = 0;
        fprintf('%s\n',['error at  image_number: ',num2str(i_img),', stc extracted wrong msg ']);
    end
end
%     poolobj = gcp('nocreate');
%         delete(poolobj);
%%  output error rate
ave_error_rate = mean(bit_error_rate);
ave_error_rate1 = nnz(bit_error_rate)/numel(bit_error_rate);
fprintf('%s\n',['payload: ',num2str(payload),'  ave_error_rate: ',num2str(ave_error_rate),'  ave_0error_rate: ',num2str(ave_error_rate1)]);
ave_wet_rate = mean(wet_rate);
ave_wet_rate1 = mean(wet_rate(bit_error_rate==0));
ave_wet_rate2 = mean(wet_rate(bit_error_rate~=0));
fprintf('%s\n',['ave_wet_rate: ',num2str(ave_wet_rate),'  0_wet_rate: ',num2str(ave_wet_rate1),'  n0_wet_rate: ',num2str(ave_wet_rate2)]);
