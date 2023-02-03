function [img] = PCGrid2D20220115(point_xyz)
    path = '7';
    file = '2';
    filename = ['.\', path, '\d', path, '_', file, '.csv'];
    tic;
%     point_xyz=csvread(filename, 1,2);       % ��ȡcsv�ļ�
% %     save('datatmp.mat', 'point_xyz')
% %     load datatmp.mat
%     
%     % csv��ÿһ�ж���2048����x,z,y������Ԫ�����ݹ�2048*3=6144�����ݣ����Դӵ�һ�����ݿ�ʼ������3ȡ��x����
%     x = point_xyz(:,1:3:end);          
%     x = x(:);
%     z = point_xyz(:,2:3:end); 
%     z = z(:);
%     y = point_xyz(:,3:3:end); 
%     y = y(:);
%     % ȥ��zΪ0��ֵ
%     ind = find(z > 0);
%     x = x(ind);
%     y = y(ind);
%     z = z(ind);
%    %% Ԥ��������
%     x = x - min(x);
%     y = y - min(y);
%     point_xyz = [x,y,z];
%     point_xyz = roundn(point_xyz,-4);
%     [~,deleteRowIndex] = unique(point_xyz(:,1:2),'rows'); % ɾ��x,y������ͬ��z��ͬ�ĵ�
%     point_xyz = point_xyz(deleteRowIndex,:);
%     [d_x, d_y] = computeDxDy(point_xyz);
%     
%     %% �������ͼ
% %     figure();
% %     ptCloud = pointCloud(point_xyz);
% %     pcshow(ptCloud);
% %     title('��̥�����ͼ��');hold on;
%     %% ������ֵ����
%     newData = splineData(x, y ,z, d_x, d_y);
%     save([filename(1:end-3), 'mat'], 'd_x', 'd_y', 'newData');
%     toc;

    load([filename(1:end-3), 'mat'])
    newData = newDataPostProcessing(newData);
    
    imwrite(mat2gray(newData), [filename(1:end-3), 'png']);

%     figure();
%     imagesc(newData);
%     title('��̥ͼ��');hold on;
%     colormap(gca,jet);
%     colorbar;
%     axis equal;
end

%% 
function newData_ret = newDataPostProcessing(newData)
    newData = flipud(fliplr(newData));
    
    len = 20;
    [r, c] = size(newData);
    maxind = 200;
    newData_ret = zeros(r, c);
    peakmask = zeros(r, c);
    
    maxindex = zeros(r,1);
    f = ones(1,len*2)/(len*2);
    surface = zeros(r,c);
    for i = 1:r
        if i == 541
            kkk = 1;
        end
        inda = i-len/5;
        indb = i+len/5;
        if inda < 1
            inda = 1;
        end
        if indb > r
            indb = r;
        end
        patch = newData(inda:indb, :);
        patch(patch == 0) = max(patch(:));
        patchmin = min(patch,[],1);
        ptmp = conv(patchmin, f, 'same');
        ptmp = min(patchmin, ptmp);
        patchmin(len*2+1:end-len*2) = ptmp(len*2+1:end-len*2);
        surface(i, :) = patchmin;
%         maxind = find(patchmin ==max(patchmin(maxind-15:maxind+15)));
%         maxindex(i,1) = maxind(1);
        newData_ret(i, :) = newData(i, :) - patchmin;
    end
    
    f = f';
    surfacenew = zeros(size(surface));
    for i = 1:c
        if i == 1300
            kkk = 1;
        end
        tmp = surface(:,i);
        tmpf = conv(tmp, f, 'same');
        surfacenew(:,i) = max(tmp, tmpf);
    end
    peakmask(newData_ret > 1) = 1;

    data = newData - surfacenew;
    data(data<=0) = 0;
    data(data>0.5) = 0.5;

    newData_ret(newData_ret<=0) = 0;
    newData_ret(newData_ret>0.5) = 0.5;
    
    se = ones(15,15);
    peakmask =1 - imdilate(peakmask, se);
    newData_ret = newData_ret.*peakmask;
    
    data = data.*peakmask;
    kkk = 1;

end
%% ��ά������ֵ
function newData = splineData(x, y ,z, d_x, d_y)
    dxy = min(d_x, d_y);
    xUnitLength = dxy; % x����λ����
    yUnitLength = dxy; % y����λ����
    
    xMin = min(x);
    xMax = max(x);
    yMin = min(y);
    yMax = max(y);

    yIndex = yMin:yUnitLength:yMax; % ���վ����x������
    yIndex = roundn(yIndex,-4);
    xIndex = xMin:xUnitLength:xMax; % ���վ����y������
    xIndex = roundn(xIndex,-4);

    xNum = length(xIndex);
    yNum = length(yIndex);
%     newData = zeros(yNum,xNum);
    
    splineRange = 50; % ÿ�β�ֵ�������С
    xSplineTimes = ceil(xNum/splineRange); % x�����ֵ����
    ySplineTimes = ceil(yNum/splineRange); % y�����ֵ����
    newData = [];
%     newData = zeros(ySplineTimes*splineRange, xSplineTimes*splineRange);
    
    for i=1:ySplineTimes
        newRowData = [];
        for j =1:xSplineTimes
            xRangeMin = ((j-1)*splineRange-5)*xUnitLength; % �����ֵ��������
            xRangeMax = (j*splineRange+5)*xUnitLength;
            yRangeMin = ((i-1)*splineRange-5)*yUnitLength;
            yRangeMax = (i*splineRange+5)*yUnitLength;
            if xRangeMin<0
                xRangeMin=0;
            end
            if yRangeMin<0
                yRangeMin=0;
            end

            indx1 = find(x <= xRangeMax);
            indy1 = find(y <= yRangeMax);
            indx2 = find(x > xRangeMin);
            indy2 = find(y > yRangeMin);
            t1 = intersect(indx1, indx2);
            t2 = intersect(indy1, indy2);

            indxy = intersect(t1, t2);
            if length(indxy) <= 10
                vq = zeros(splineRange,splineRange);
            else
                xn = x(indxy);
                yn = y(indxy);
                zn = z(indxy);
                xqMin = (j-1)*splineRange*xUnitLength; % �����ֵ��
                xqMax = (j*splineRange-1)*xUnitLength;
                yqMin = (i-1)*splineRange*yUnitLength;
                yqMax = (i*splineRange-1)*yUnitLength;
                [xq,yq] = meshgrid(xqMin:xUnitLength:xqMax, yqMin:yUnitLength:yqMax);
                
                vq = griddata(xn,yn,zn,xq,yq);
            end
            newRowData = [newRowData, vq];
        end
        newData = [newData;newRowData];
    end
    newData = newData(1:yNum, 1:xNum);
    newData(find(isnan(newData))) = 0;
end



%% ��ȡdelta_x��delta_y
function [d_x, d_y] = computeDxDy(pc)
    x = pc(:,1);
    y = pc(:,2);
    yu = unique(y);
    yud = roundn(yu(2:end) - yu(1:end-1), -4);
    yuu = unique(yud);
    d_y = min(yuu);
    
    xrowmean = [];
    for i = 1:length(yu)
        ind = find(y == yu(i));
        xrow = x(ind);
        tmp = xrow(2:end) - xrow(1:end-1);
        tmps = sort(tmp);
        c = size(tmps,1);
        xrowmean(i) = tmps(floor(c/2));
    end
    [a,b] = hist(xrowmean, 100);
    d_x = b(a == max(a));
end


