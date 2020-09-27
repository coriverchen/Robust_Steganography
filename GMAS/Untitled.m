%  cover_dir = 'C:\Users\VVD\Desktop\7.jpg';
%  stego_dir = 'C:\Users\VVD\Desktop\7s.jpg';
%  imwrite(imread(cover_dir),stego_dir,'quality',71);  
%  
 
 stego_dir = 'C:\Users\VVD\Desktop\a80.jpg';
 C_STRUCT = jpeg_read(stego_dir);
 C_QUANT = C_STRUCT.quant_tables{1}; 

 a=1;
 