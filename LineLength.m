function [len, dist] = LineLength(input_line)
    % This function calculates the length of a line by using Euclidean distance. 
    % 'input_line':  n(Points) x m (dimensions) matrix for the coordinates of the points of the input line.
    %  'len' : length of input_line;   'dist' : distances of each segment along the line
    d = diff(input_line); dist = sqrt(sum(d.^2,2)); len =sum(dist);
end %function [len, dist] = LineLength(input_line)