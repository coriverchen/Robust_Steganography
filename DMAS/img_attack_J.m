function suc = img_attack_J(img_path,img_wpath,style,value,q)
% 图像攻击
    img = imread(img_path);
    %不攻击
    if (style==0)
        img2 = img;
    end
    %中值滤波 value为窗口大小
    if (style==1)
        xx = medfilt2(img,[value value]);
        img2=double(xx);
    end
    %高斯噪声,value为强度参数
    if (style==2)
        sigma1 = value;
        gausFilter = fspecial('gaussian',[3 3],sigma1);
        xx = imfilter(img,gausFilter,'replicate');
        img2 = double(xx);
    end
    %椒盐噪声，value为强度参数
    if (style==3)
        xx = imnoise(img,'salt & pepper',value);
        img2 = double(xx);
    end
    %旋转，value为旋转角度
    if (style==4)
        angle=value;   %旋转角度
        xx = imrotate(img,angle,'bicubic','crop');
        img2 = xx;
    end
    %缩放，放大两倍的操作 value=2,放大四倍的操作 value=4
    %缩放，缩小1/4的操作 value=3/4，缩小1/2的操作 value=2/4
    if (style==5)
        xx = imresize(img,value,'bicubic');
        xx = imresize(xx,1/value,'bicubic');
        img2 = double(xx);
    end
    %裁剪
    if (style==6)        
        img2 = img;
        if (value == 1)%中心1/4
            for i = 129:1:384
                for j = 129:1:384
                   img2(i,j) =0;
                end
            end
            img2 = double(img2);
        else
            if (value ==2)%左上1/4
                for i = 1:1:256
                    for j = 1:1:256
                        img2(i,j) = 0;
                    end
                end
                img2 = double(img2);
            else%底边1/4
                for i = 385:1:512
                    for j = 1:1:512
                        img2(i,j) = 0;
                    end
                end
                img2 = double(img2);
            end
        end
    end
    %JPEG压缩
    if (style==7)
        imwrite(uint8(img),img_wpath,'quality',value);
    end
    %直方图均衡
    if (style==8)
    end
    if (style~=7)
        imwrite(uint8(img2),img_wpath,'quality',q);
    end
    suc = 1;
end