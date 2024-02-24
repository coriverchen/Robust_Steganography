function [is_cover] = coverSelect(cover_path,R1,R2,spatail)
% select robust cover coefficients
C_STRUCT = jpeg_read(cover_path);
COEFFS = C_STRUCT.coef_arrays{1};
QUANT = C_STRUCT.quant_tables{1};


%% select cover coefficient according to their distance to border
is_cover = ones(size(COEFFS));
if R1>=0

    fun = @(x) (x.data .* QUANT);
    unquant_coeffs = blockproc(COEFFS,[8 8],fun);
    fun = @(x) idct2(x.data);
    spa_uq = blockproc(unquant_coeffs,[8 8],fun);
    %%%---------coefficient-wise cover select
    spa = spa_uq;
    spa(spa>127) = 127;
    spa(spa<-128) = -128;
    fun = @(x) dct2(x.data);
    lossy_coeffs = blockproc(round(spa),[8 8],fun);
    coeffs_dif = unquant_coeffs - lossy_coeffs;
    fun = @(x) (QUANT/2 - x.data);
    dis_to_border = blockproc(abs(coeffs_dif),[8 8],fun);
    is_cover(dis_to_border<R1) = 0;
    %% select cover coefficient according to the impact after their modification
    [xm,xn] = size(spa_uq);
    m_block = floor(xm/8);
    n_block = floor(xn/8);
    for bm = 1:m_block
        for bn = 1:n_block
            %         vulnerable = 0;
            for i = 1:8
                for j = 1:8
                    if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)+spatail(:,:,j+(i-1)*8))<=127-R2)) || ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)+spatail(:,:,j+(i-1)*8))>=-128+R2))
                        is_cover((bm-1)*8+i,(bn-1)*8+j) = 2;
                    end
                    if ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)-spatail(:,:,j+(i-1)*8))>=-128+R2)) || ~all(all((spa_uq((bm-1)*8+1:bm*8,(bn-1)*8+1:bn*8)-spatail(:,:,j+(i-1)*8))<=127-R2))
                        is_cover((bm-1)*8+i,(bn-1)*8+j) = 3;
                    end
                end
            end
        end
    end
end
end

