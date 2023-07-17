function [rho_p,rho_m] = CostUR(rho1_P,rho1_M,VulnerableBlock,cover_Path,alpha,beta)
% ���ݿ��������Ϣ����ʧ��
% ���ȶ����еĲ�³���Ŀ��������һ��ʧ�棬��ϵ��alpha��ͼ���0λ�������ֵ����
% �Կ��ھ����λ�ã�������ο���������޸ģ���beta����
% ��������
% alpha = 0.2;
% beta = 0.7;
wetConst = 10^13;
% �ȼ���ȥ��ʪ����ƽ��ֵ
rho1_P_nw = rho1_P(rho1_P~=wetConst);
rho1_M_nw = rho1_M(rho1_M~=wetConst);
rhoPMean = mean(rho1_P_nw);
rhoMMean = mean(rho1_M_nw);
% ��ȡ����ͼ���ϵ��
C_STRUCT = jpeg_read(cover_Path);
C_COEFFS = C_STRUCT.coef_arrays{1};
% ����ͼ����³���Ե���ʧ��
rho_p = rho1_P;
rho_m = rho1_M;
VBsize = size(VulnerableBlock,2);
for i = 1 : VBsize
    if isempty(VulnerableBlock{i})
        break;
    end
    % ��ȡ��³�����λ�úͲο�ͼ��
    bm = VulnerableBlock{i}{1,1};
    bn = VulnerableBlock{i}{1,2};
    ref = VulnerableBlock{i}{1,3};
    rho_p_part = rho_p((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8);
    rho_m_part = rho_m((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8);
    % ���ȼ���һ������
    rho_p_part = rho_p_part + alpha*rhoPMean;
    rho_m_part = rho_m_part + alpha*rhoMMean;
    % �ٸ��ݲο�ͼ��ָ���޸�
    rho_p_part(C_COEFFS((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)<ref) = beta*rho_p_part(C_COEFFS((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)<ref);
    rho_m_part(C_COEFFS((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)>ref) = beta*rho_m_part(C_COEFFS((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)>ref);
    % �޸Ľ���
    rho_p((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8) = rho_p_part;
    rho_m((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8) = rho_m_part;
end
    




