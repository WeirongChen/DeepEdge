function [nnXY, tMask, probMask, nnXYlength, anchors] = predUSTC(net, im, nAnchors)
    % net: U-Net model;   im:  cropped image 
    h0=size(im,1); w0= size(im,2);
    hw=net.Layers(1).InputSize(1:2); h = hw(1); w = hw(2);  im3 = imresize(im, [h, w]); 
    pred1 = predict(net, im3); pred1 = pred1(:,:,1);  
    pred1_resize = imresize(pred1, [h0, w0]); probMask = pred1_resize;
    tMask0 = blob_analysis(pred1); 
    tMask = uint8(imresize(tMask0, [h0,w0]));
    nnXY0= skeleton_analysis(tMask0);  nnXY = (nnXY0 ./ [w,h]) .* [w0,h0];
    nnXYlength = LineLength(nnXY);
    anchors = nnXY(int8(linspace(1, size(nnXY,1), nAnchors)),:);
end % predUSTC

function xy = skeleton_analysis(tMask)
    nPts = 100; [h,w] = size(tMask); origin = [w/2, h];  tMask = tMask > 0; 
    out = bwskel(tMask,'MinBranchLength', round(h*0.1)); % set 'MinBranchLength' as 10% of image height to reduce branches.
    [y, x] = find(out); xy = [x,y];  xy=polarSort(origin, xy); xy = interpLine(xy, nPts); 
end  % function xy = skeleton_analysis

function xy3=polarSort(origin, xy)
    xy1 = xy - origin; x1 =xy1(:,1); y1 = xy1(:,2);
    [th,r] = cart2pol(x1,y1); B = sortrows([th, r], [1 2]);
    th1 = B(:,1); r1 = B(:,2); [x2,y2] = pol2cart(th1,r1); xy2 = [x2,y2]; xy3 = xy2 + origin;
end %function xy3=polarSort

function tMask = blob_analysis(originalImage)
    [h, w] = size(originalImage); origin = [w/2, h]; thresholdValue = 0.30;
    blobAreaCutOff = 0.20; % Blobs that has the area larger than this blobAreaCutOff(%) of the largest blob will be retained. 
    binaryImage = originalImage > thresholdValue; % Bright objects will be chosen if you use >.
    binaryImage = imfill(binaryImage, 'holes'); [labeledImage, nLabels] = bwlabel(binaryImage);     % Label each blob so we can make measurements of it
    coloredLabels = label2rgb (labeledImage, 'hsv', 'k', 'shuffle'); % pseudo random color labels
    % imshow(coloredLabels);
    blobMeasurements = regionprops(labeledImage, originalImage, 'all');
    numberOfBlobs = size(blobMeasurements, 1);
    for k = 1 : numberOfBlobs           % Loop through all blobs.
        % Find the mean of each blob.  (R2008a has a better way where you can pass the original image
        % directly into regionprops.  The way below works for all versions including earlier versions.)
        thisBlobsPixels{k} = blobMeasurements(k).PixelIdxList;  % Get list of pixels in current blob.
        meanGL(k) = mean(originalImage(thisBlobsPixels{k})); % Find mean intensity (in original image!)
        meanGL2008a(k) = blobMeasurements(k).MeanIntensity; % Mean again, but only for version >= R2008a
        blobArea(k) = blobMeasurements(k).Area;		% Get area.
        blobPerimeter(k) = blobMeasurements(k).Perimeter;		% Get perimeter.
        blobCentroid(k,1:2) = blobMeasurements(k).Centroid;		% Get centroid one at a time
        blobECD(k) = sqrt(4 * blobArea(k) / pi);					% Compute ECD - Equivalent Circular Diameter.
    end
    maxBlobArea = max(blobArea); [sortedBlobArea, areaOrder] = sort(blobArea, 'descend');
    blobArea1 = blobArea ./ maxBlobArea;
    I = find(blobArea1 >= blobAreaCutOff); n = numel(I);  tMask = zeros(h,w,n);
    for i = 1:n,  lab =areaOrder(i); tMask(:,:,i) = (labeledImage == lab) * i; end
    if n==1, return;end
    %% Remove any blob underneath or above larger blobs
    removeIdx = false(n,1);  overlappThresh = 0.05; % tolerance threshold of blob overlapping
    for i =2:n
        mask = tMask(:,:,i)>0; [y1, x1] = find(mask); xy1 = [x1, y1] - origin; [th1,r1] = cart2pol(xy1(:,1),xy1(:,2));
        th1= th1*-1; B1 = sortrows([th1, r1], [1 2]); th1 = B1(:,1); r1 = B1(:,2); th1Min = min(th1); th1Max = max(th1); th1Length = th1Max-th1Min; 
        for j = 1:i-1
            preMask = tMask(:,:,j)>0; [y0, x0] = find(preMask); xy0 = [x0, y0] - origin; [th0,r0] = cart2pol(xy0(:,1),xy0(:,2));
            th0 = th0*-1; B0 = sortrows([th0, r0], [1 2]); th0 = B0(:,1); r0 = B0(:,2); th0Min = min(th0); th0Max = max(th0);
            overlapped = th1(th1 > th0Min & th1 < th0Max);
            if ~isempty(overlapped)
                overlappedLength = max(overlapped) - min(overlapped);  overlappedPercent = overlappedLength / th1Length;
                if overlappedPercent > overlappThresh, removeIdx(i) = true;end
            end
    %         plot([th0Min, th0Max], 0,'bo');hold on; plot([th1Min, th1Max], 0,'ro');
        end
    end
    tMask = tMask(:,:,~removeIdx); tMask = sum(tMask,3);
    % imshow(tMask)
end % function tMask = blob_analysis(originalImage)