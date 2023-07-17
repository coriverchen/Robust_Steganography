function [rho_p,rho_m] = CostUR(rho1_P,rho1_M,VulnerableBlock,cover_Path,alpha,beta)
% 根据空域溢出信息调整失真
% 首先对所有的不鲁棒的块整体加上一个失真，由系数alpha和图像非0位置整体均值决定
% 对块内具体的位置，鼓励向参考矩阵方向的修改，由beta决定
% 参数设置
% alpha = 0.2;
% beta = 0.7;
wetConst = 10^13;
% 先计算去除湿点后的平均值
rho1_P_nw = rho1_P(rho1_P~=wetConst);
rho1_M_nw = rho1_M(rho1_M~=wetConst);
rhoPMean = mean(rho1_P_nw);
rhoMMean = mean(rho1_M_nw);
% 读取载体图像的系数
C_STRUCT = jpeg_read(cover_Path);
C_COEFFS = C_STRUCT.coef_arrays{1};
% 根据图像块的鲁棒性调整失真
rho_p = rho1_P;
rho_m = rho1_M;
VBsize = size(VulnerableBlock,2);
for i = 1 : VBsize
    if isempty(VulnerableBlock{i})
        break;
    end
    % 读取弱鲁棒块的位置和参考图像
    bm = VulnerableBlock{i}{1,1};
    bn = VulnerableBlock{i}{1,2};
    ref = VulnerableBlock{i}{1,3};
    rho_p_part = rho_p((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8);
    rho_m_part = rho_m((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8);
    % 首先加上一个常量
    rho_p_part = rho_p_part + alpha*rhoPMean;
    rho_m_part = rho_m_part + alpha*rhoMMean;
    % 再根据参考图像指导修改
    rho_p_part(C_COEFFS((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)<ref) = beta*rho_p_part(C_COEFFS((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)<ref);
    rho_m_part(C_COEFFS((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)>ref) = beta*rho_m_part(C_COEFFS((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)>ref);
    % 修改结束
    rho_p((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8) = rho_p_part;
    rho_m((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8) = rho_m_part;
end
    




