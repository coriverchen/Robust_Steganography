function suc = img_attack_J(img_path,img_wpath,style,value,q)
% ͼ�񹥻�
    img = imread(img_path);
    %������
    if (style==0)
        img2 = img;
    end
    %��ֵ�˲� valueΪ���ڴ�С
    if (style==1)
        xx = medfilt2(img,[value value]);
        img2=double(xx);
    end
    %��˹����,valueΪǿ�Ȳ���
    if (style==2)
        sigma1 = value;
        gausFilter = fspecial('gaussian',[3 3],sigma1);
        xx = imfilter(img,gausFilter,'replicate');
        img2 = double(xx);
    end
    %����������valueΪǿ�Ȳ���
    if (style==3)
        xx = imnoise(img,'salt & pepper',value);
        img2 = double(xx);
    end
    %��ת��valueΪ��ת�Ƕ�
    if (style==4)
        angle=value;   %��ת�Ƕ�
        xx = imrotate(img,angle,'bicubic','crop');
        img2 = xx;
    end
    %���ţ��Ŵ������Ĳ��� value=2,�Ŵ��ı��Ĳ��� value=4
    %���ţ���С1/4�Ĳ��� value=3/4����С1/2�Ĳ��� value=2/4
    if (style==5)
        xx = imresize(img,value,'bicubic');
        xx = imresize(xx,1/value,'bicubic');
        img2 = double(xx);
    end
    %�ü�
    if (style==6)        
        img2 = img;
        if (value == 1)%����1/4
            for i = 129:1:384
                for j = 129:1:384
                   img2(i,j) =0;
                end
            end
            img2 = double(img2);
        else
            if (value ==2)%����1/4
                for i = 1:1:256
                    for j = 1:1:256
                        img2(i,j) = 0;
                    end
                end
                img2 = double(img2);
            else%�ױ�1/4
                for i = 385:1:512
                    for j = 1:1:512
                        img2(i,j) = 0;
                    end
                end
                img2 = double(img2);
            end
        end
    end
    %JPEGѹ��
    if (style==7)
        imwrite(uint8(img),img_wpath,'quality',value);
    end
    %ֱ��ͼ����
    if (style==8)
    end
    if (style~=7)
        imwrite(uint8(img2),img_wpath,'quality',q);
    end
    suc = 1;
end