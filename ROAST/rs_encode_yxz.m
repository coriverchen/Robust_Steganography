function [encoded_msg] = rs_encode_yxz(MSG,nn,kk)
% Reed-Solomon encoder,����RS��n,k��,

% MSG_len = 500;   MSGΪ������
% MSG = round( rand(1,MSG_len) );

n = nn; %��������ֳ���  Codeword and message word lengths
k = kk;  %��Ϣ����
mm = 0;
while nn > 1
    mm = mm + 1;
    nn = nn / 2;
end
m = mm; %ÿ�����ŵı�����  Number of bits per symbol
%% ��������ϢԤ����
MSG_len = length(MSG);
message_word = floor(MSG_len / m / k);  % ��������Ϣ����������Ϣ�ֵ�������
real_msg_len = message_word * m * k;        
real_msg = MSG(1,1:real_msg_len);       % ʵ��Ƕ��Ķ�������Ϣ����   

%% ����������Ϣת���������� or ٤������ 32����
func = @(x) (x(1)*2^(m-1) + x(2)*2^(m-2) + x(3)*2^(m-3) + x(4)*2^(m-4) + x(5 )*2^(m-5));
real_msg_31 = blkproc(real_msg,[1 5],func);  %ʵ��Ƕ��Ķ�������Ϣת��Ϊ 31 ������

real_msg_31_reshape = reshape(real_msg_31,[k,message_word]);
real_msg_31_reshape = real_msg_31_reshape';
real_msg_31_gf = gf(real_msg_31_reshape,m);  % message_word * k  �� symbol message words  

%% RS����
encoded_msg_31_gf = rsenc(real_msg_31_gf,n,k);    

%% ���������Ϣת��Ϊ��������Ϣ
encoded_msg_len = message_word * m * n;  
encoded_msg = zeros(1,encoded_msg_len);
for ii=1:message_word
    for jj=1:n
        encoded_msg_31_gf_x = double(encoded_msg_31_gf.x);
        each_msg = dec2bin(encoded_msg_31_gf_x(ii,jj));
        len_each_msg = length(each_msg); %�����Ƴ���
        copy_len_each_msg = len_each_msg;
        index = (ii-1)*n*m + (jj-1)*m;  % 
        while copy_len_each_msg < m   %���һ�����ŵĶ����Ƴ���С��5����ǰ����
            index = index + 1;
            encoded_msg(1,index) = 0;
            copy_len_each_msg = copy_len_each_msg + 1;            
        end        
        for kk=1:len_each_msg
            index = index + 1;
            encoded_msg(1,index) = double(str2num(each_msg(kk)));            
        end
    end
end

end   