function testRobustGISS(pcover_dir,cover_dir,stego_dir,payload,cover_QF,attack_QF,R1,R2,R3,distortion)
% 
afterchannel_stego_dir = [stego_dir,'_attackBy',num2str(attack_QF)]; 
if ~exist(afterchannel_stego_dir,'dir'); mkdir(afterchannel_stego_dir); end  
% afterchannel_cover_dir = ['H:\test&code\RWPS\preCover\compressedBy',num2str(attack_QF)]; 
afterchannel_cover_dir = ['/public/zengkai/expcode/GISS/compressedCover/compressedBy',num2str(attack_QF)]; 
if ~exist(afterchannel_cover_dir,'dir'); mkdir(afterchannel_cover_dir); end 
% cover_num = 10000; 

dct0 = zeros(8,8);
spatail = zeros(8,8,64);
for i = 1 : 8
    for j = 1 : 8
        dct = dct0;
        dct(i,j) = dct(i,j) + 1;
        fun = @(x) idct2(x.data);
        spatail(:,:,j+(i-1)*8) = blockproc(double(dct.*quantizationTable(cover_QF)),[8 8],fun);
    end
end


imgs = dir([cover_dir,'/*.jpg']);

cover_num = length(imgs);

bit_error_rate = zeros(1,cover_num); %  bit_error_rate  coefficients_error   cover_rate cover_coefficients_error
coefficients_error = zeros(1,cover_num);
cover_rate = zeros(1,cover_num);

cover_coefficients_error = zeros(1,cover_num);


% poolnum = str2double(getenv('SLURM_CPUS_PER_TASK'));
% parpool(poolnum);

%% create a local cluster object
pc = parcluster('local');

% explicitly set the JobStorageLocation to the temp directory that was created in your sbatch script
pc.JobStorageLocation = strcat('/public/zengkai/.matlab/local_cluster_jobs/R2018b','/', getenv('SLURM_JOB_ID'));

% start the matlabpool with maximum available workers
% control how many workers by setting ntasks in your sbatch script
parpool(pc, str2num(getenv('SLURM_CPUS_ON_NODE')));

%% steganography and test robustness
parfor i_img = 1 : cover_num
    % image address

    cover_path = fullfile([cover_dir,'/',num2str(i_img),'.jpg']);
    stego_path = fullfile([stego_dir,'/',num2str(i_img),'.jpg']);
    pcover_path = fullfile([pcover_dir,'/',num2str(i_img), '.pgm']);
    afterchannel_stego_path = fullfile([afterchannel_stego_dir,'/',num2str(i_img),'.jpg']);
    afterchannel_cover_path = fullfile([afterchannel_cover_dir,'/',num2str(i_img),'.jpg']);
        
    try
    %% Steganography
    [is_cover] = coverSelect(cover_path,R1,R2,spatail);
    
    % 
    [msg,msg_len] = generateRandMsg(cover_path,payload);
    if msg_len>=1.5*nnz(is_cover==1) 
        fprintf('%s\n',['msg overlength at: ',num2str(i_img),', stc embedded wrong']);
        continue;
    end
        rs_encoded_msg = msg;
    
    %
    [rhoP,rhoM] = costGISS(pcover_path,cover_path,R3,is_cover,distortion);
    % 
    % embed message STCs
    [stc_n_msg_bits] = generateStegoGISS(rhoM,rhoP,rs_encoded_msg,cover_path,stego_path,is_cover,R3);
    
    % JPEG compression
    imwrite(imread(stego_path),afterchannel_stego_path,'quality',attack_QF);

%%      Message extration and test
    S_STRUCT = jpeg_read(afterchannel_stego_path);
    SOEFFS = S_STRUCT.coef_arrays{1};
    STRUCT = jpeg_read(stego_path);
    COEFFS = STRUCT.coef_arrays{1};
    C_STRUCT = jpeg_read(cover_path);
    C_COEFFS = C_STRUCT.coef_arrays{1};
    coefficients_error(1,i_img) = nnz(SOEFFS~=COEFFS)/numel(COEFFS);

        cover_rate(1,i_img) = nnz(is_cover==1)/numel(is_cover);

        cover_coefficients_error(1,i_img) = nnz(SOEFFS(is_cover==1)~=COEFFS(is_cover==1))/numel(SOEFFS);

    % extract message
    H = 10;
    cover_index = (find(is_cover==1))';
    stego = SOEFFS(cover_index);
    stc_decoded_msg = stc_ml_extract(int32(stego), stc_n_msg_bits, H);
    %% Decode and calculate message error rate  
    extract_raw_msg = stc_decoded_msg;
    % 
    bit_error = double(msg) - double(extract_raw_msg);
    bit_error_number = sum(abs(bit_error));
    bit_error_rate(1,i_img) = bit_error_number/msg_len;
    
    
%     
%     fprintf('%s\n',['payload: ',num2str(payload),'  image_number: ',num2str(i_img),'  image_name: ',name,'  error_rate: ',num2str(bit_error_rate(1,i_img))]);
%     fprintf('%s\n',['payload: ',num2str(payload),'  image_number: ',num2str(i_img),'  error_rate: ',num2str(bit_error_rate(1,i_img))]);
    catch
        bit_error_rate(1,i_img) = 0;
        fprintf('%s\n',['error at  image_number: ',num2str(i_img),', stc extracted wrong msg ']);
    end
end
    poolobj = gcp('nocreate');
        delete(poolobj);

% 
files = dir(stego_dir);
files_num = size(files,1)-2;
if files_num==0
    ave_error_rate = 0;
else
    ave_error_rate = mean(bit_error_rate,'omitnan')*cover_num/files_num;
    ave_0error_rate = (files_num-nnz(bit_error_rate))/cover_num;
end
fprintf('%s\n',['payload: ',num2str(payload),'  ave_error_rate: ',num2str(ave_error_rate),'  ave_0error_rate: ',num2str(ave_0error_rate)]); 
fprintf('%s\n',['coefficients_error: ',num2str(mean(coefficients_error,'omitnan')*cover_num/files_num),'  cover_rate: ',num2str(mean(cover_rate,'omitnan')*cover_num/files_num),'  cover_coefficients_error: ',num2str(mean(cover_coefficients_error,'omitnan')*cover_num/files_num)]);
