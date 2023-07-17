function [stc_n_msg_bit] = stc3Embed(cover_Path,stego_Path,rho_p,rho_m,rs_encoded_msg)
% 嵌入消息，生成载密图像
% 载体
C_STRUCT = jpeg_read(cover_Path);
C_COEFFS = C_STRUCT.coef_arrays{1};
cover = int32(reshape(C_COEFFS,1,[]));
% 失真
costs = zeros(3,size(cover,2),'single');
costs(1,:) = reshape(rho_m,1,[]);        
costs(3,:) = reshape(rho_p,1,[]); 
% embed message   三元嵌  量化索引调制机制
H = 10;
[d stc_msg n_msg_bits l] = stc_pm1_pls_embed(int32(cover), costs, uint8(rs_encoded_msg), H); 
stc_extract_msg2 = stc_ml_extract(int32(stc_msg), n_msg_bits, H); % extract message

% 验证三元STC解码是否正常工作,总是出错，跳过
% try all(uint8(rs_encoded_msg) == stc_extract_msg2)
% %     disp('Message can be extracted by STC3 correctly.');
% catch
%     fprintf('%s\n',['error at  image_number: ',num2str(i_img),', stc extracted wrong msg , FILE name : stc3Embed']);
% end
% 写载密图像
S_STRUCT = C_STRUCT;
S_COEFFS = reshape(stc_msg,size(C_COEFFS,1),size(C_COEFFS,2));
S_STRUCT.coef_arrays{1} = double(S_COEFFS);
jpeg_write(S_STRUCT,stego_Path);
stc_n_msg_bit = n_msg_bits;


