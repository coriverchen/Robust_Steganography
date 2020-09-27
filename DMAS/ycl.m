%Ԥ����
function [cover_lsb,rho,change,rho_P,rho_M] = ycl(cover_spa,rho1_P,rho1_M,tab_m)
bits = 8;            %��������ֵת��Ϊ������DCTϵ��Ҫ������ֵ����ƽ�ƣ�ʹ����ֵ�ķֲ���0�Գ�                       
cover_spa = double(cover_spa) - 2^(round(bits) - 1);
[xm,xn] = size(cover_spa);

% t = dctmtx(8);  % DCT�任����
% fun = @(xl) (t*xl*(t'));
% cover_DCT = blkproc(cover_spa,[8 8],fun);  %�ֿ�DCT�任  

fun = @(x)dct2(x.data);
cover_DCT = blockproc(cover_spa,[8 8],fun);

% y = blkproc(y,[8 8],'round(x./P1)',table);%����
m_block = floor(xm/8);
n_block = floor(xn/8);

G = 1;
n_lsb = 0;
cover_lsb = zeros(1,m_block*n_block*15); %8*8DCT����³��������15��Ԫ��
change = zeros(1,m_block*n_block*15);
rho = zeros(1,m_block*n_block*15);
rho_P  = zeros(1,m_block*n_block*15);
rho_M = zeros(1,m_block*n_block*15);

% wetConst = 10^13;

for bm = 1:m_block
    for bn = 1:n_block
        for i = 1:8
            for j = 1:8
                if (i+j==8)||(i+j==9) 
                    n_lsb = n_lsb + 1;
                    rho_P(n_lsb) = rho1_P((bm-1)*8+i,(bn-1)*8+j)/double(tab_m(i,j));  %������DCTϵ��+-1ʧ��
                    rho_M(n_lsb) = rho1_M((bm-1)*8+i,(bn-1)*8+j)/double(tab_m(i,j));
                    yd = cover_DCT((bm-1)*8+i,(bn-1)*8+j);  %��������DCTϵ��
                    tab_q = double(tab_m(i,j))/G;  %��������
                    dnum1 = round(yd/tab_q);
                    if mod(dnum1,2)==0
                        cover_lsb(n_lsb)=0;
                        dnum2 = floor(yd/tab_q);
                        if mod(dnum2,2)==1
                            change(n_lsb) = -1*(yd-dnum2*tab_q);%��ȥ��ô��
                            rho(n_lsb) = -1*change(n_lsb)*rho_M(n_lsb);
                        else
                            change(n_lsb) = ((dnum2+1)*tab_q-yd);%������ô��
                            rho(n_lsb) = change(n_lsb)*rho_P(n_lsb);
                        end                        
                    else
                        cover_lsb(n_lsb)=1;
                        dnum2 = floor(yd/tab_q);
                        if mod(dnum2,2)==1
                            change(n_lsb) = (dnum2+1)*tab_q-yd;%������ô��
                            rho(n_lsb) = change(n_lsb)*rho_P(n_lsb);
                        else
                            change(n_lsb) = -1*(yd-dnum2*tab_q);%������ô��
                            rho(n_lsb) = -1*change(n_lsb)*rho_M(n_lsb);
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