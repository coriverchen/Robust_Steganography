function [stc_n_msg_bits] = generateStegoGISS(rhoM,rhoP,msg,cover_path,stego_path,is_cover,R3)
%GENERATESTEGOUNICORE generate final stego images
% sharedConst = 1;
wetConst = 10^13;

C_STRUCT = jpeg_read(cover_path);
COEFFS = C_STRUCT.coef_arrays{1};
QUANT = C_STRUCT.quant_tables{1}; 
if R3==0
    cover_index = (find(is_cover==1))';
else
    cover_index = (find(is_cover>0))';
end
cover = COEFFS(cover_index);
rhoMc = rhoM(cover_index);
rhoPc = rhoP(cover_index);


costs = zeros(3,size(cover,2),'single');
costs(1,:) = rhoMc;
costs(3,:) = rhoPc;
H = 10;

[~, stc_msg,stc_n_msg_bits,~] = stc_pm1_pls_embed(int32(cover), costs, uint8(msg), H);

stego = reshape(COEFFS,1,[]);
stego(cover_index) = stc_msg;
stego = reshape(stego,size(COEFFS,1),size(COEFFS,2));
stego = double(stego);
SOEFFS = stego;
C_STRUCT.coef_arrays{1} = SOEFFS;
jpeg_write(C_STRUCT,stego_path);
end

