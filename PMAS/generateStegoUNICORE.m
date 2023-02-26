function generateStegoUNICORE(cover_path,stego_path,cover,modification,stego,afterchannel_stego_path,attack_QF,T,mode)
%GENERATESTEGOUNICORE 生成真实载体
alpha = 4;
% 首先根据修改生成载体
steg_modify = double(stego)-double(cover);

C_STRUCT = jpeg_read(cover_path);
C_COEFFS = C_STRUCT.coef_arrays{1};
C_QUANT = C_STRUCT.quant_tables{1}; %载体图像量化表
S_COEFFS = C_COEFFS;
modificationP = modification(:,:,1);
modificationM = modification(:,:,2);
% modificationPP = modification(:,:,3);
S_COEFFS(steg_modify==1) = S_COEFFS(steg_modify==1) + modificationP(steg_modify==1);
S_COEFFS(steg_modify==-1) = S_COEFFS(steg_modify==-1) - modificationM(steg_modify==-1);
C_STRUCT.coef_arrays{1} = double(S_COEFFS);
jpeg_write(C_STRUCT,stego_path);

% 后处理
if mode
    for i = 1 : mode
        postprocessUNICORE(stego_path,stego,afterchannel_stego_path,attack_QF,T,mode-i);
    end
else
%     error_rate = 1;
% %     mode = 1;
%     while error_rate>=0.1^alpha
%         postprocessUNICORE(stego_path,stego,afterchannel_stego_path,attack_QF,T,mode);
% %         C_STRUCT = jpeg_read(stego_path);
% %         stego = C_STRUCT.coef_arrays{1};
%         
%         S_STRUCT = JPEGrecompress(stego_path,afterchannel_stego_path,attack_QF);
%         afterchannel_stego = S_STRUCT.coef_arrays{1};
%         comp_modify = double(stego)~=double(afterchannel_stego);
%         error_rate = nnz(comp_modify)/nnz(stego);
%     end
%     mode = 0;
%     postprocessUNICORE(stego_path,stego,afterchannel_stego_path,attack_QF,T,mode);
end
