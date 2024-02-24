function [rhoP,rhoM] = costGISS(pcover_path,cover_path,R3,is_cover,distortion)
%COSTGISS 
% distortion = 2;
wetConst = 10^13;

C_STRUCT = jpeg_read(cover_path);
COEFFS = C_STRUCT.coef_arrays{1};
QUANT = C_STRUCT.quant_tables{1}; 

spa = double(imread(pcover_path));
fun = @(x) dct2(x.data-128)./QUANT;
coeffs_real = blockproc(spa,[8 8],fun);

%% calculate
if distortion
    % J_UNIWARD
    [rhoP,rhoM] = J_UNIWARD_cost(spa,coeffs_real,QUANT);
else
    % UERD
    [rhoP,rhoM] = UERDcost(coeffs_real,QUANT);
end
if distortion<=1
%% real side-information guided distortion adjustment
e = coeffs_real - COEFFS;
e(e>0.5) = 0.5; e(e<-0.5) = -0.5; % image compressed with imwrite(imread) is different form that with idct(dct)
gamma = (1 - 2*abs(e));
rhoP(e > 0) = gamma(e > 0).*rhoP(e > 0);
rhoM(e < 0) = gamma(e < 0).*rhoM(e < 0);
end
%% distortion adjustment for non-robust modification
if R3 ~=0
% rhoP(is_cover==2) = R3*rhoP(is_cover==2);
% rhoM(is_cover==3) = R3*rhoM(is_cover==3);
rhoP(is_cover==2) = wetConst;
rhoM(is_cover==3) = wetConst;
end


rhoP(rhoP > wetConst) = wetConst;
rhoP(isnan(rhoP)) = wetConst;    
rhoP(COEFFS > 1023) = wetConst;
    
rhoM(rhoM > wetConst) = wetConst;
rhoM(isnan(rhoM)) = wetConst;
rhoM(COEFFS < -1023) = wetConst;
end

