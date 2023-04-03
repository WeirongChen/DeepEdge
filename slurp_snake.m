function [xy, energy, Egradient]=slurp_snake(im, anchors, Egradient, nAnchorPoints, Sigma, Delta, BandPenalty, Alpha, Lambda1, ROI, mask, UseBand)
    % Egradient : image gradient; if ommitted or empty, then calculate gradient within this function. 
    % im : imput image
    % anchors :  anchor points to start with
    % nPoints :  number of Points of output line (xy)
    % Sigma: Image gradient smoothness
    % Delta: Snake local search margin 
    % Alpha: Snake internal energy weight 
    % Beta:  Snake external energy weight (=1-Alpha), ...
    % Lambda1: Snake internal smoothness weight , ...
    % Lambda2: Snake internal segment evenness weight (=1-Lambda1)
    % BandPenalty:  Snake band penalty value
    imWidth =  size(im,2); imHeight =  size(im,1);
    % nAnchorPoints = size(anchors,1);
    if nargin < 4 || isempty(nAnchorPoints), nAnchorPoints = size(anchors,1); end 
    if nargin < 5 || isempty(Sigma), Sigma = 5; end 
    if nargin < 6 || isempty(Delta), Delta= 2; end
    if nargin < 7 || isempty(BandPenalty), BandPenalty = 2; end
    if nargin < 8 || isempty(Alpha), Alpha = 0.7; end
    if nargin < 9 || isempty(Lambda1), Lambda1 = 0.7; end
    if nargin < 10 || isempty(ROI), ROI = [1, 1, imWidth, imHeight]; end
    if nargin < 11 || isempty(mask), mask = ones(size(im)); end
    if nargin < 12 || isempty(UseBand), UseBand = 1;end
    if size(im,3) >1, im = rgb2gray(im); end % if color, convert to gray 
    if isinteger(im), im = im2double(uint8(im));end % if integer, convert to double
    if nargin < 3 || isempty(Egradient), Egradient = Egrad(im, Sigma, ROI, mask); end
    marginWidth = 200; % add extra margin in pixel
     [im_margin, Egradient1] = add_margin(im, marginWidth, Egradient);
     ptOffsets = [marginWidth, marginWidth];
    transIm = im_margin'; transEgrad = Egradient1';
    interpMethod = 'makima'; 
    if nAnchorPoints ~= size(anchors,1), anchors = interpLine_simple(anchors, nAnchorPoints, interpMethod); end
    pts = anchors + ptOffsets; DeltaArr = Delta*ones(nAnchorPoints,1);
    [xy, energy] = make_snake(transIm, transEgrad, pts, DeltaArr,  BandPenalty, Alpha, Lambda1, UseBand);
    xy = xy - ptOffsets; 
    % ensure XY defined increasing left to right (blows up below if right to left)
    if xy(1,1) > xy(end,1), xy = flipud(xy); end
    energy = single(energy);
end %function [xy, energy, Egradient]=slurp_snake

function [im2, Egradient2] = add_margin(im, mW, Egradient)
    % Add extra margin surrounding the image to prevent SNAKE from searching
    % out of boundary. 
    %   mW:  margin thickness
    w = size(im, 2); h = size(im,1);  
%     topM = zeros(mW, 2*mW+w);  leftM = zeros(h, mW);  
    topM = ones(mW, 2*mW+w);  leftM = ones(h, mW);  
    rightM = leftM;  bottomM = topM; 
    im2 = [topM; leftM, im, rightM; bottomM];  Egradient2 = [topM+1; leftM+1, Egradient, rightM+1; bottomM+1]; 
end %function [im2, Egradient2] = add_margin

function E = Egrad(Im, Sigma, ROI, mask, maskSigma)
    imWidth =  size(Im,2); imHeight =  size(Im,1);
    if nargin < 3 || isempty(ROI), ROI = [1, 1, imWidth, imHeight]; end
    if nargin < 4 || isempty(mask), mask = ones(size(Im)); end
    if nargin < 5 || isempty(maskSigma), maskSigma = Sigma;end
    % Energy related to image gradient
    GradMag = imageGradient(Im, Sigma);
    [Y,X]=meshgrid(ROI(2):ROI(4),ROI(1):ROI(3)); 
    ix = sub2ind([imHeight, imWidth],Y,X);
    [M, ~] = max(GradMag(ix(:)));
    normGradMag = GradMag /M;
    GradMagMask = imageGradient(im2double(mask), maskSigma);
    GradMagMask = GradMagMask./max(GradMagMask(:));
    negGradMagMask = 1- GradMagMask; 
    E = 1 - normGradMag.*mask.*negGradMagMask;
end %function E = Egrad

function grad = imageGradient(I, sigma)
    [x,y]=ndgrid(floor(-3*sigma):ceil(3*sigma),floor(-3*sigma):ceil(3*sigma)); 
    xGauss=-(x./(2*pi*sigma^4)).*exp(-(x.^2+y.^2)/(2*sigma^2));
    yGauss=-(y./(2*pi*sigma^4)).*exp(-(x.^2+y.^2)/(2*sigma^2));
    Ix  = imfilter(I,xGauss,'corr'); Iy  = imfilter(I,yGauss,'corr');
    grad = sqrt(Ix.^2 + Iy.^2);
end %function grad = imageGradient(I, sigma)

function out = interpLine_simple(in, density, method)
    in = unique(in, 'rows', 'stable'); n=size(in,1); if n == 1, out = repmat(in, density,1);return;end
    cumDist = [0; cumsum(sqrt(sum(diff(in).^2,2)))]; out = interp1(cumDist, in,linspace(0, cumDist(end), density), method);
end 