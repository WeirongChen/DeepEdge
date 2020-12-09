function [OutputLine, lineLength1] = interpLine(InputLine, density, method)
    %  Interpolation for a line.
    % InputLine: n (points) x m (dimenstions) data points
    % OutputLine: 'density' x m (dimenstions) data points
    % {'density' > n} 
    % 'method': interpolation method. default value = 'spline';
    %  
    % W. Chen   Nov-28-2020
    n=size(InputLine,1);
    if nargin<3, method='spline';end
    if nargin<2, density=50; end
    if isempty(InputLine), OutputLine = []; lineLength1 = []; return; end
    if n == 1, OutputLine = repmat(InputLine, density,1);return;end
    d = sqrt(sum(diff(InputLine).^2,2)); % Euclidean distances between each line segments
    cumDist = [0; cumsum(d)]; % cumulative distances along the line
    lineLength = cumDist(end);
    newCumDist = linspace(0, lineLength, density);
    OutputLine = interp1(cumDist, InputLine, newCumDist, method);
    d1 = sqrt(sum(diff(OutputLine).^2,2)); newCumDist1 = [0; cumsum(d1)];
    lineLength1 = newCumDist1(end);
end %function [OutputLine, lineLength1] =interpLine