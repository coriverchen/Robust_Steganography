function [encoded_msg] = rs_encode_yxz(MSG,nn,kk)
% Reed-Solomon encoder,采用RS（n,k）,

% MSG_len = 500;   MSG为行向量
% MSG = round( rand(1,MSG_len) );

n = nn; %编码后码字长度  Codeword and message word lengths
k = kk;  %信息长度
mm = 0;
while nn > 1
    mm = mm + 1;
    nn = nn / 2;
end
m = mm; %每个符号的比特数  Number of bits per symbol
%% 二进制消息预处理
MSG_len = length(MSG);
message_word = floor(MSG_len / m / k);  % 二进制消息长度需是消息字的整数倍
real_msg_len = message_word * m * k;        
real_msg = MSG(1,1:real_msg_len);       % 实际嵌入的二进制消息长度   

%% 将二进制消息转换到有限域 or 伽罗瓦域 32进制
func = @(x) (x(1)*2^(m-1) + x(2)*2^(m-2) + x(3)*2^(m-3) + x(4)*2^(m-4) + x(5 )*2^(m-5));
real_msg_31 = blkproc(real_msg,[1 5],func);  %实际嵌入的二进制消息转化为 31 进制数

real_msg_31_reshape = reshape(real_msg_31,[k,message_word]);
real_msg_31_reshape = real_msg_31_reshape';
real_msg_31_gf = gf(real_msg_31_reshape,m);  % message_word * k  个 symbol message words  

%% RS编码
encoded_msg_31_gf = rsenc(real_msg_31_gf,n,k);    

%% 将编码后消息转换为二进制消息
encoded_msg_len = message_word * m * n;  
encoded_msg = zeros(1,encoded_msg_len);
for ii=1:message_word
    for jj=1:n
        encoded_msg_31_gf_x = double(encoded_msg_31_gf.x);
        each_msg = dec2bin(encoded_msg_31_gf_x(ii,jj));
        len_each_msg = length(each_msg); %二进制长度
        copy_len_each_msg = len_each_msg;
        index = (ii-1)*n*m + (jj-1)*m;  % 
        while copy_len_each_msg < m   %如果一个符号的二进制长度小于5，则前补零
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