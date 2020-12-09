function d=udist(pt1,pt2)
% Calculate the Euclidean distance from pt2 (one or more points) to pt1 (multiple points)
%   If pt2 = 1 x n (dims) and pt1 = m (points) x n (dims), output 'd' is the distances from pt2 to each elements in pt1.
%   If both pt1 and pt2 are m (points) x n (dims), 'd' is an array of the point-to-point distance for each pair of [pt1i, pt2i]. 
% INPUT: 
%       pt1, pt2 : m (points) x n (dimensions)
%         pt1 must be m x n matrix 
%         while pt2 can be either 1 x n vector or m x n matrix.    
% OUTPUT: 
%        d : m (points) x 1 vector
% Weirong Chen   May-12-2014
nPointsPt2=size(pt2,1); nPointsPt1=size(pt1,1);
dimsPt1=size(pt1,2); dimsPt2=size(pt2,2);

if dimsPt1~=dimsPt2, error('dimensions not match!');end % if dimsPt1~=dimsPt2, return d=0.
if nPointsPt2==nPointsPt1
    d=sqrt(sum((pt1-pt2).^2,2));
elseif nPointsPt2==1 && nPointsPt1>1
    arr1=pt1; arr2=repmat(pt2,nPointsPt1,1);
    d=sqrt(sum((arr1-arr2).^2,2));
end
% end %udist