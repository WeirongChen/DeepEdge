function transformed_ult = transult(ult, varargin)
% transform_ultrasuite
%  Transform raw ultrasound scanlines in UltraSuite format to tongue image on screen. 
%     (Replication of 'transform_ultrasound' in Aciel Eshky's UltraSuite-Tools)
%   
% INPUT: 
%       ult : raw scanlines in UltraSuite format:  
%              'ult' can be either a string, specifying the file path and name of the .ult file, 
%               or a 3D matrix of [size_scanline x num_scanlines x nFrames] 
%    NAME, VALUE paired arguments: 
%       'background_colour' : 0~255; Default: 0 = black
%       'num_scanlines' : number of scanlines. Default: 63
%       'size_scanline' :  pixels per scanline. Default: 412
%       'angle' : angle per scanline (in radian). Default: 0.038
%       'zero_offset' : length from origin to start of scanline (in pixel). Default: 51
%       'pixels_per_mm' : scaling factor; rescale frame to the size of 1/pixels_per_mm. Default: 1 = no rescale. 
% OUTPUT: 
%       transformed_ult :  [height x width x nFrames]  3D image matrix 
%
%  W.R. Chen  01-AUG-2021

    if nargin<1 || isempty(ult), ult = 'sample.ult'; end
    background_colour =0; num_scanlines = 63; size_scanline = 412; angle = 0.038; zero_offset = 51; pixels_per_mm = 1;  %Default   
    % Input parser
    pars = inputParser;  addParameter(pars,'background_colour', background_colour); 
    addParameter(pars,'num_scanlines', num_scanlines); addParameter(pars,'size_scanline',size_scanline); 
    addParameter(pars,'angle',angle); addParameter(pars,'zero_offset',zero_offset); 
    addParameter(pars,'pixels_per_mm', pixels_per_mm);  parse(pars,varargin{:}); p = pars.Results;
    %%
    if ischar(ult), filename = ult;  fid = fopen(filename, 'rb'); ult = fread(fid, inf, 'uint8'); fclose(fid); end
    ult = uint8(ult);
    ult = reshape(ult, p.size_scanline, p.num_scanlines, []);
    nFrames = size(ult,3);
%     width = sqrt(p.num_scanlines .^ 2 + p.size_scanline .^2) .* 2 + p.zero_offset;
%     height = p.size_scanline + p.zero_offset * 1.5;
    r = p.size_scanline + p.zero_offset; % arm length;
    fieldView = p.angle * p.num_scanlines; % Prove field of view in radian
    width = r * sin(fieldView/2)*2 + 10;
    height = r + 10; h_offset = round(p.zero_offset * cos(fieldView/2) /  p.pixels_per_mm);
    output_shape = floor([width /  p.pixels_per_mm, height /  p.pixels_per_mm]); % for UltraSuite: [884, 488] 
    origin = floor([output_shape(1)/2,0]);
    [Xq, Yq] = get_cart2pol_coordinates_vectorised(output_shape, ...
        'origin', origin, 'num_scanlines', p.num_scanlines, 'angle', p.angle, 'zero_offset', p.zero_offset, 'pixels_per_mm',  p.pixels_per_mm);
    Xq = Xq(h_offset:end,:); Yq = Yq(h_offset:end,:);
    transformed_ult = zeros(output_shape(2)- h_offset+1, output_shape(1), nFrames, 'uint8');
    [x, y]=meshgrid(1:p.num_scanlines, 1:p.size_scanline);
    for i = 1:nFrames
        frame = single(ult(:,:,i));   trans = flipud(interp2(x, y,frame, Xq, Yq)); 
        trans(isnan( trans)) = p.background_colour; transformed_ult(:,:,i) = trans;
    end
end % transform_ultrasuite

%%
function [Xq, Yq] = get_cart2pol_coordinates_vectorised(frame_shape, varargin)
% Replication of  the same function in Aciel Eshky's UltraSuite-Tools.
% INPUT: 
%      frame_shape: [width, height] (pixels). Shape of output frame. Default: [884, 488]
%  NAME, VALUE paired arguments: 
%     'origin' :  coordinate of origin (in pixel). Default : [442,0]
%     'num_scanlines' : number of scanlines. Default: 63
%     'angle' : angle per scanline (in radian). Default: 0.038
%     'zero_offset' : length from origin to start of scanline (in pixel). Default: 51
%     'pixels_per_mm' : scaling factor; rescale frame to the size of 1/pixels_per_mm. Default: 1 = no rescale. 
% OUTPUT: 
%     Xq: x coordinates_in_input
%     Yq: y coordinates_in_input
%
    if nargin < 1 || isempty(frame_shape), frame_shape = [884, 488]; end
    origin=[442, 0]; num_scanlines=63; angle=0.038; zero_offset=51; pixels_per_mm=1; % Default parameters
    % Input parser
    pars = inputParser;addParameter(pars,'origin',origin); addParameter(pars,'num_scanlines',num_scanlines); 
    addParameter(pars,'angle',angle); addParameter(pars,'zero_offset',zero_offset); addParameter(pars,'pixels_per_mm', pixels_per_mm);  parse(pars,varargin{:}); p = pars.Results;
    % Generate meshgrid:
    [xx,yy]=meshgrid(1:frame_shape(1), 1:frame_shape(2));
    x = xx - p.origin(1); y =  yy - p.origin(2); [th, r] = cart2pol(x, y);
    r = r .* p.pixels_per_mm; cl = floor(p.num_scanlines ./2);
    Xq = cl - ((th - pi/2) ./ p.angle);  Yq = r - p.zero_offset;
end %get_cart2pol_coordinates_vectorised
 
 