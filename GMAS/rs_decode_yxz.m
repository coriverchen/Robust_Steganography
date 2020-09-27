function [decoded_msg] = rs_decode_yxz(MSG,nn,kk)
% Reed-Solomon decoder,采用RS（n,k）,在GF(2^m)域中
% m:表示符号的大小
% n:表示码块长度
% k:表示码块中的信息长度
% K=n－k = 2t:表示校验码的符号数,t表示能够纠正的错误符号数目

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
message_word = floor(MSG_len / m / n);  % 二进制消息长度需是消息字的整数倍
 
%% 将二进制消息转换到有限域 or 伽罗瓦域
func = @(x) (x(1)*2^(m-1) + x(2)*2^(m-2) + x(3)*2^(m-3) + x(4)*2^(m-4) + x(5)*2^(m-5));%m~=5要改代码
real_msg_31 = blkproc(MSG,[1 5],func);  %实际嵌入的二进制消息转化为 31 进制数

real_msg_31_reshape = reshape(real_msg_31,[n,message_word]);
real_msg_31_reshape = real_msg_31_reshape';
real_msg_31_gf = gf(real_msg_31_reshape,m);  % message_word * n 个 symbol message words  
%% RS编码
decoded_msg_31_gf = rsdec(real_msg_31_gf,n,k);    

%% 将编码后消息转换为二进制消息
decoded_msg_len = message_word * m * k;  
decoded_msg = zeros(1,decoded_msg_len);
for ii=1:message_word
    for jj=1:k
        encoded_msg_31_gf_x = double(decoded_msg_31_gf.x);
        each_msg = dec2bin(encoded_msg_31_gf_x(ii,jj));
        len_each_msg = length(each_msg); %二进制长度
        copy_len_each_msg = len_each_msg;
        index = (ii-1)*k*m + (jj-1)*m;  % 
        while copy_len_each_msg < m   %如果一个符号的二进制长度小于5，则前补零
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