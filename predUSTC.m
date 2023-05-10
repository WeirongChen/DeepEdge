function [nnXY, nnMask, probMask, nnXYlength, anchors, nnMask0] = predUSTC(net, im, nAnchors, blobProbThreshold)
% Updated: 25DEC2022  -- Added blobIntensThreshhold
% Wei-Rong Chen
if nargin < 4 || isempty(blobProbThreshold), blobProbThreshold = 0.5; end
if nargin < 3 || isempty(nAnchors), nAnchors = 20; end
    % net: U-Net model;   im:  cropped image 
     nnXY=[]; nnMask=[]; probMask=[]; nnXYlength=[]; anchors=[];
    h0=size(im,1); w0= size(im,2);
    hw=net.Layers(1).InputSize(1:2); h = hw(1); w = hw(2);  im3 = imresize(im, [h, w]); 
    pred1 = predict(net, im3); pred1 = pred1(:,:,1);  
    pred1_resize = imresize(pred1, [h0, w0]); probMask = pred1_resize;
    nnMask0 = blob_analysis(pred1, blobProbThreshold); 
    if isempty(nnMask0), return; end
    nnMask = uint8(imresize(nnMask0, [h0,w0]));
    try
        nnXY0= skeleton_analysis(nnMask0);  nnXY = (nnXY0 ./ [w,h]) .* [w0,h0];
        nnXYlength = sum(sqrt(sum(diff(nnXY).^2,2))); % LineLength(nnXY);
        anchorInds = uint8(linspace(1, size(nnXY,1), nAnchors));
        anchors = nnXY(anchorInds,:);
        nnXYlength = single(nnXYlength);
    catch
        return
    end
end % predUSTC

function xy = skeleton_analysis(tMask)
    nPts = 50; [h,w] = size(tMask); origin = [w/2, h];  tMask = tMask > 0; 
    out = bwskel(tMask,'MinBranchLength', round(h*0.2)); % set 'MinBranchLength' as 10% of image height to reduce branches.
    [y, x] = find(out); xy = [x,y];  
    if isempty(x) || isempty(y), xy = [];end
    n = size(xy,1);
    % If the output is just one point, SNAKE algorithm will crash.
    %  Add a dummy point 0.5 pixel away from the point to avoid SNAKE
    %  crashs.
    if n <2, xy = [xy; (xy +0.5)];end
    xy =  sortAnchors(xy);
    xy = interpLine(xy, nPts, 'makima'); 
end  % function xy = skeleton_analysis

function [OutputLine, lineLength] = interpLine(InputLine, density, method)
    %  Interpolation for a line.
    % InputLine: n (points) x m (dimenstions) data points
    % OutputLine: 'density' x m (dimenstions) data points
    % {'density' > n} 
    % 'method': interpolation method. default value = 'spline';
    % W. Chen   20JUL2021
    if nargin<3, method='spline';end; if nargin<2, density=50; end
    if isempty(InputLine), OutputLine = []; lineLength = []; return; end
    InputLine = unique(InputLine, 'rows', 'stable'); n=size(InputLine,1);
    if n == 1, OutputLine = repmat(InputLine, density,1);return;end
    cumDist = [0; cumsum(sqrt(sum(diff(InputLine).^2,2)))]; % cumulative distances along the line
    OutputLine = interp1(cumDist, InputLine,linspace(0, cumDist(end), density), method);
    d1 = sqrt(sum(diff(OutputLine).^2,2)); newCumDist1 = [0; cumsum(d1)]; lineLength = newCumDist1(end);
end %function [OutputLine, lineLength1] =interpLine
function sortedAnchors = sortAnchors(anchors, ifAscend, ifDropLastEccentric)
            % Sort the anchor points (x,y coordinates) on ultrasound tongue contours. 
            % 'anchors' :  n x {x, y + other meta information} 
            % ' ifAscend'  set to true ->  sort points from left to right {default}
            %                     false ->  sort points from right to left
            % 'ifDropLastEccentric' :  Sometime a middle point is not
            % captured by nearest neighbor method; this will cause the last
            % point curling back long distance. If 'ifDropLastEccentric =
            % true', the last excursion will be evaluated and if it is too
            % far away, then drop the last point. 
            %  Weirong Chen   15MAR2023
            if nargin < 3, ifDropLastEccentric = true;end
            if nargin < 2 || isempty(ifAscend), ifAscend = true; end
            if nargin < 1 || isempty(anchors), anchors = load1var('anchors');end
            if isempty(anchors), sortedAnchors = [];return; end
            [~, ia,~] = unique(anchors(:,1:2),'rows', 'stable');
            anchors = anchors(ia,:);
            if size(anchors, 1) < 2, sortedAnchors = anchors; return; end
            x  = anchors(:,1); y = anchors(:,2); n = numel(x);
            xy = [x, y];
            lengthMat = NaN(n, 1);
            for startInd = 1:n
                 lengthMat(startInd) = LineLength(sortByMinDist(xy, startInd)); 
            end 
            [~, optInd] = min(lengthMat);  [~, orderInds] =sortByMinDist(xy, optInd); sortedAnchors = anchors(orderInds,:);
            % IF drop last point if the latest trip is too far:
             if ifDropLastEccentric
                 [~, dist] = LineLength(sortedAnchors);
                 medianDist = median(dist, 'omitnan'); 
                 if dist(end) > medianDist*3, sortedAnchors = sortedAnchors(1:end-1,:);end
             end %  if ifDropLastEccentric
            %% Set the direction of sorting:
            if ifAscend
                if  sortedAnchors(1,1) > sortedAnchors(end,1), sortedAnchors=flipud(sortedAnchors);end
            else
                if  sortedAnchors(1,1) < sortedAnchors(end,1), sortedAnchors=flipud(sortedAnchors);end
            end
            function [sortedAnchors,orderInds] = sortByMinDist(anchors, startInd)
                sortedAnchors = NaN(size(anchors)); tmpAnchors = anchors;  nn = size(anchors,1); orderInds = NaN(nn,1);
                pt = anchors(startInd,1:2); tmpAnchors(startInd,1:2) =[inf, inf]; sortedAnchors(1,:) = pt; orderInds(1) = startInd;
                for i = 2:nn
                    d = sqrt(sum((tmpAnchors(:,1:2)-pt(:,1:2)).^2,2));
                    [~, Ind] = min(d); pt = tmpAnchors(Ind,:);  sortedAnchors(i,:) = pt; 
                    tmpAnchors(Ind,1:2) = [inf, inf];  orderInds(i) = Ind;
                end
            end %sortByMinDist
            function [len, dist] = LineLength(input_line)
                d = diff(input_line); dist = sqrt(sum(d.^2,2)); len =sum(dist);
            end % LineLength 
    end %function sortedAnchors = sortAnchors(anchors, ifAscend)  

        
function tMask = blob_analysis(originalImage, blobProbThreshold)
    if nargin < 2, blobProbThreshold = 0.30; end
    [h, w] = size(originalImage); origin = [w/2, h]; 
    blobAreaCutOff = 0.20; % Blobs that has the area larger than this blobAreaCutOff(%) of the largest blob will be retained. 
    binaryImage = originalImage > blobProbThreshold; % Bright objects will be chosen if you use >.
    binaryImage = imfill(binaryImage, 'holes'); [labeledImage, nLabels] = bwlabel(binaryImage);     % Label each blob so we can make measurements of it
    coloredLabels = label2rgb (labeledImage, 'hsv', 'k', 'shuffle'); % pseudo random color labels
    % imshow(coloredLabels);
    blobMeasurements = regionprops(labeledImage, originalImage, 'all');
    numberOfBlobs = size(blobMeasurements, 1);
    if  numberOfBlobs==0, tMask=[]; return;end 
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
        end
    end
    tMask = tMask(:,:,~removeIdx); tMask = sum(tMask,3);
    % imshow(tMask)
end % function tMask = blob_analysis(originalImage)

