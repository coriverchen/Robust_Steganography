
cover_Path = ['C:\Users\VVD\Desktop\1001.jpg'];    
% channel_Path = ['C:\Users\VVD\Desktop\1c.jpg'];  
% stego_Path = ['C:\Users\VVD\Desktop\',num2str(aa),'s.jpg'];  
stego_Path = ['C:\Users\VVD\Desktop\100b.jpg'];  


% imwrite(imread(cover_Path),channel_Path,'quality',71);
% imwrite(imread(channel_Path),stego_Path,'quality',65);

C_STRUCT = jpeg_read(cover_Path);
C_COEFFS = C_STRUCT.coef_arrays{1};  
C_QUANT = C_STRUCT.quant_tables{1};

S_STRUCT = jpeg_read(stego_Path);
S_COEFFS = S_STRUCT.coef_arrays{1};  
S_QUANT = S_STRUCT.quant_tables{1};

Diff = double(C_COEFFS ~= S_COEFFS);

Diff_location = zeros(8,8);
for i=1:8
    for j=1:8
        Diff_location(i,j) = sum(sum(Diff(i:8:end,j:8:end)));
    end
end

figure(2);
bar3(Diff_location);
colormap(jet);
colorbar;

