function Test_Robustness_GMAS_JUNIWARD()
%% Robustness test code of the robust steganography algorithm GMAS on the actual channel of the social network platform Facebook
    clear all;
    clc;
%%  parameter setting
    cover_dir = '.\cover_dir_QF65'; 
    stego_dir = '.\stego_dir'; if ~exist(stego_dir,'dir'); mkdir(stego_dir); end  
    afterchannel_stego_dir = '.\afterchannel_stego_dir'; if ~exist(afterchannel_stego_dir,'dir'); mkdir(afterchannel_stego_dir); end     
    cover_num = 10; 
    cover_QF = 65; 
    Facebook_attack_QF = 71; 
    payload = 0.1; 
    
    bit_error_rate = zeros(1,cover_num); 
%%  message embedding   
    for i_img = 1:cover_num
        cover_Path = fullfile([cover_dir,'\',num2str(i_img),'.jpg']);   
        stego_Path = fullfile([stego_dir,'\',num2str(i_img),'.jpg']);    
        afterchannel_stego_Path = fullfile([afterchannel_stego_dir,'\',num2str(i_img),'.jpg']);   
        
        C_STRUCT = jpeg_read(cover_Path);
        C_COEFFS = C_STRUCT.coef_arrays{1};  
        C_QUANT = C_STRUCT.quant_tables{1};
        nzAC = nnz(C_COEFFS) - nnz(C_COEFFS(1:8:end,1:8:end));
%  generating random message and padding
        raw_msg_len = ceil(payload*nzAC);
        raw_msg = round( rand(1,raw_msg_len) ); %original message    
        nn = 31; kk = 15; mm = 5;   %using RS（31,15）for message correction，the length of the message needs to be times of kk*mm=75      
        zeros_padding_num = ceil(raw_msg_len/kk/mm)*kk*mm - raw_msg_len; %the number of padding zero 
        zeros_padding_msg = zeros(1, raw_msg_len + zeros_padding_num); %padding
        zeros_padding_msg(1:raw_msg_len) = raw_msg;
        zeros_padding_msg(raw_msg_len+1 : raw_msg_len + zeros_padding_num) = 0;  %message to be embedded subsequently
%  The secret information is encoded using RS(31,15)    
        [rs_encoded_msg] = rs_encode_yxz(zeros_padding_msg,nn,kk); 
%  An improved asymmetric distortion is used to calculate the +-1 asymmetric distortion of the cover 
        [rho1_P, rho1_M] = J_UNIWARD_Asy_cost(cover_Path);         
%  Message embedded preprocessing (modifying distortion and modifying distance based on generalized dither modulation)
        [cover_round, change_p, change_m, rho_p, rho_m] = gmas(cover_Path, rho1_P, rho1_M, C_QUANT);       
%  STC embeding     
        [suc, stc_n_msg_bits] = stc3_embed(rs_encoded_msg, cover_Path, cover_round, rho_p, rho_m, change_p, change_m, cover_QF, stego_Path);
%%  mimic Facebook compression  Facebook_attack_QF = 71   
        imwrite(imread(stego_Path),afterchannel_stego_Path,'quality',Facebook_attack_QF);    

%  STC extraction
        [stc_decoded_msg] = stc3_extract(afterchannel_stego_Path, stc_n_msg_bits, C_QUANT);   
%  decode message by RS（31,15）
        [rs_decoded_msg] = rs_decode_yxz(double(stc_decoded_msg), nn, kk);
%  delete padding       
        extract_raw_msg = rs_decoded_msg(1:raw_msg_len); %delete padded zero
%%  calculate bit error rate        
        bit_error = double(raw_msg) - double(extract_raw_msg);
        bit_error_number = sum(abs(bit_error));
        bit_error_rate(1,i_img) = bit_error_number/raw_msg_len;              
        fprintf('%s\n',['payload: ',num2str(payload),'  image_number: ',num2str(i_img),'  error_rate: ',num2str(bit_error_rate(1,i_img))]);  

    end
%  give it error rate of all images
    ave_error_rate = mean(bit_error_rate);
    fprintf('%s\n',['payload: ',num2str(payload),'  ave_error_rate: ',num2str(ave_error_rate)]);  
  
end
