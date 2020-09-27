function [decoded_msg,decoded_msg_len] = rs_decode(MSG,MSG_len)
% Reed-Solomon decoder,����RS��31,15��,

m = 5; %ÿ�����ŵı�����  Number of bits per symbol
n = 2^m - 1; %��������ֳ���  Codeword and message word lengths
k = 15;  %��Ϣ����
%% ��������ϢԤ����
message_word = floor(MSG_len / m / n);  % ��������Ϣ����������Ϣ�ֵ�������
 
%% ����������Ϣת���������� or ٤������
func = @(x) (x(1)*2^(m-1) + x(2)*2^(m-2) + x(3)*2^(m-3) + x(4)*2^(m-4) + x(5 )*2^(m-5));
real_msg_31 = blkproc(MSG,[1 5],func);  %ʵ��Ƕ��Ķ�������Ϣת��Ϊ 31 ������

real_msg_31_reshape = reshape(real_msg_31,[n,message_word]);
real_msg_31_reshape = real_msg_31_reshape';
real_msg_31_gf = gf(real_msg_31_reshape,m);  % message_word * n �� symbol message words  
%% RS����
decoded_msg_31_gf = rsdec(real_msg_31_gf,n,k);    

%% ���������Ϣת��Ϊ��������Ϣ
decoded_msg_len = message_word * m * k;  
decoded_msg = zeros(1,decoded_msg_len);
for ii=1:message_word
    for jj=1:k
        encoded_msg_31_gf_x = double(decoded_msg_31_gf.x);
        each_msg = dec2bin(encoded_msg_31_gf_x(ii,jj));
        len_each_msg = length(each_msg); %�����Ƴ���
        copy_len_each_msg = len_each_msg;
        index = (ii-1)*k*m + (jj-1)*m;  % 
        while copy_len_each_msg < m   %���һ�����ŵĶ����Ƴ���С��5����ǰ����
            index = index + 1;
            decoded_msg(1,index) = 0;
            copy_len_each_msg = copy_len_each_msg + 1;            
        end        
        for kk=1:len_each_msg
            index = index + 1;
            decoded_msg(1,index) = double(str2num(each_msg(kk)));            
        end
    end
end
end


        