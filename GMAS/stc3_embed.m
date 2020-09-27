function [suc,n_msg_bits] = stc3_embed(rs_encoded_msg,coverPath,cover_round,rho_p,rho_m,change_p,change_m,cover_QF,stegoPath)

%% ��ԪSTCs ����
costs = zeros(3, 86016, 'single'); %��Ƶ21��DCTϵ��
costs(1,:) = rho_m;        
costs(3,:) = rho_p;        

H = 10;
[d stc_msg n_msg_bits l] = stc_pm1_pls_embed(int32(cover_round), costs, uint8(rs_encoded_msg), H); % embed message   ��ԪǶ  �����������ƻ���
stc_extract_msg2 = stc_ml_extract(int32(stc_msg), n_msg_bits, H); % extract message

%% ��֤��ԪSTC�����Ƿ���������
if all(uint8(rs_encoded_msg) == stc_extract_msg2)
    disp('Message can be extracted by STC3 correctly.');
else
    error('Some error occured in the extraction process of STC3.');
end

%%  DCT�任
code = stc_msg;
code_n = length(stc_msg);

bits = 8;     
cover_spa = imread(coverPath);
cover_spa = double(cover_spa) - 2^(round(bits)-1);
[xm,xn] = size(cover_spa);

t = dctmtx(8);  %����DCT����
fun = @(xl) (t*xl*(t'));
cover_DCT = blkproc(cover_spa,[8 8],fun);%�ֿ�DCT�任
m_block = floor(xm/8);
n_block = floor(xn/8);

%% ʵ��Ƕ�����
G = 1;
n_msg = 0;
for bm = 1:m_block
    for bn = 1:n_block
        for i = 1:8
            for j = 1:8
                if (i+j==7)||(i+j==8)||(i+j==9)  %��Ƶ21��DCTϵ��
                    n_msg = n_msg + 1;
                    if n_msg<=code_n
                        yd = cover_DCT((bm-1)*8+i,(bn-1)*8+j); %��������DCTϵ��
                        if code(n_msg) > cover_round(n_msg)   % ʵ���޸Ĳ���
                            yd = yd + change_p(n_msg); 
                        elseif code(n_msg) < cover_round(n_msg) 
                            yd = yd + change_m(n_msg);
                        else
                            yd = cover_DCT((bm-1)*8+i,(bn-1)*8+j); %%%% ע�� %%%
                        end
                        cover_DCT((bm-1)*8+i,(bn-1)*8+j) = yd; 
                    else
                        break;
                    end
                end
            end
        end
        if n_msg>code_n break; end
    end
    if n_msg>code_n break; end
end

%% ����ͼ������
cover_spa = blkproc(cover_DCT,[8 8],'P1*x*P2',t',t);
cover_spa = cover_spa + double(2^(bits-1));
cover_spa = uint8(cover_spa);
imwrite(cover_spa,stegoPath,'quality',cover_QF);
suc = 1;

end