function [cover_round,change_p,change_m,rho_p,rho_m] = gmas(cover_Path,rho1_P,rho1_M,tab_m)
%% ���ݹ��嶶�����ƻ���(generalization dither modulation)��������Ԫ�ص��޸�ʧ����޸ľ���

cover_spa = imread(cover_Path);  
bits = 8;            %��������ֵת��Ϊ������DCTϵ��Ҫ������ֵ����ƽ�ƣ�ʹ����ֵ�ķֲ���0�Գ�                       
cover_spa = double(cover_spa) - 2^(round(bits) - 1);
[xm,xn] = size(cover_spa);

% t = dctmtx(8);  % DCT�任����
% fun = @(xl) (t*xl*(t'));
% cover_DCT = blkproc(cover_spa,[8 8],fun);  %�ֿ�DCT�任  

fun = @(x)dct2(x.data);
cover_DCT = blockproc(cover_spa,[8 8],fun);

m_block = floor(xm/8);
n_block = floor(xn/8);

%% ���嶶�����ƻ��Ƽ������
G = 1;
usable_DCT_num = 21;
n_lsb = 0;
cover_round = zeros(1,m_block*n_block* usable_DCT_num); %%%%%%%%%%%%%%
cover_lsb = zeros(1,m_block*n_block* usable_DCT_num);
change_p = zeros(1,m_block*n_block* usable_DCT_num); %GMAS Ƕ��ʱ����DCTϵ�� +- �ı���
change_m = zeros(1,m_block*n_block* usable_DCT_num);
rho_p = zeros(1,m_block*n_block* usable_DCT_num);   %GMAS Ƕ��ʱDCTϵ�� +-1 ��ʧ��
rho_m = zeros(1,m_block*n_block* usable_DCT_num);
rho1_P_deq  = zeros(1,m_block*n_block* usable_DCT_num); %������DCTϵ�� +-1 ��ʧ��
rho1_M_deq = zeros(1,m_block*n_block* usable_DCT_num);

for bm = 1:m_block
    for bn = 1:n_block
        for i = 1:8
            for j = 1:8
                if (i+j==7)||(i+j==8)||(i+j==9)  %��Ƶ21��DCTϵ��
                    n_lsb = n_lsb + 1;
                    rho1_P_deq(n_lsb) = rho1_P( (bm-1)*8+i,(bn-1)*8+j ) / double( tab_m(i,j) );  %������DCTϵ��+-1ʧ��
                    rho1_M_deq(n_lsb) = rho1_M((bm-1)*8+i,(bn-1)*8+j)/double(tab_m(i,j));
                    yd = cover_DCT((bm-1)*8+i,(bn-1)*8+j);  %��������DCTϵ��
                    tab_q = double(tab_m(i,j))/G;  %��������
                    cover_round(n_lsb)=round(yd/tab_q); 
                    dnum1 = round(yd/tab_q);
                    if mod(dnum1,2)==0
                        cover_lsb(n_lsb)=0;
                        dnum2 = floor(yd/tab_q);
                        if mod(dnum2,2)==1
                            change_p(n_lsb) = (dnum2+2)*tab_q-yd;  %������ô�ࣨ��������
                            rho_p(n_lsb) = change_p(n_lsb)*rho1_P_deq(n_lsb);
                            change_m(n_lsb) = -1*(yd-dnum2*tab_q); %������ô�ࣨ�Ӹ�����
                            rho_m(n_lsb) = -1*change_m(n_lsb)*rho1_M_deq(n_lsb);                            
                        else
                            change_p(n_lsb) = (dnum2+1)*tab_q-yd;  %������ô�ࣨ��������
                            rho_p(n_lsb) = change_p(n_lsb)*rho1_P_deq(n_lsb);
                            change_m(n_lsb) = -1*(yd-(dnum2-1)*tab_q); %������ô�ࣨ�Ӹ�����
                            rho_m(n_lsb) = -1*change_m(n_lsb)*rho1_M_deq(n_lsb); 
                        end                        
                    else
                        cover_lsb(n_lsb)=1;
                        dnum2 = floor(yd/tab_q);
                        if mod(dnum2,2)==1
                            change_p(n_lsb) = (dnum2+1)*tab_q-yd;  %������ô�ࣨ��������
                            rho_p(n_lsb) = change_p(n_lsb)*rho1_P_deq(n_lsb);
                            change_m(n_lsb) = -1*(yd-(dnum2-1)*tab_q); %������ô�ࣨ�Ӹ�����
                            rho_m(n_lsb) = -1*change_m(n_lsb)*rho1_M_deq(n_lsb);  
                        else
                            change_p(n_lsb) = (dnum2+2)*tab_q-yd;  %������ô�ࣨ��������
                            rho_p(n_lsb) = change_p(n_lsb)*rho1_P_deq(n_lsb);
                            change_m(n_lsb) = -1*(yd-dnum2*tab_q); %������ô�ࣨ�Ӹ�����
                            rho_m(n_lsb) = -1*change_m(n_lsb)*rho1_M_deq(n_lsb); 
                        end
                    end  
%                     if unstable((bm-1)*8+i,(bn-1)*8+j)~=0
%                         rho(n_lsb) = wetConst;
%                     end
                end
            end
        end
    end
end

end