function [TextGridStruct,tierNames,TierStartLineNum, IsPointTier]= ReadTextGrid(tgFName, whichTier)
% This function reads TextGrid file and returns a struct of TextGrid.
% INPUT: 
%      'tgFName' :  TextGrid filename.
%      'whichTier' :  Specify which tier will be parsed and returned. Leave blank to output all tiers.  
% Output : 
%   'TextGridStruct' : TextGrid structure with the following format: 
%       TextGrid(i).NAME : tier name
%       TextGrid(i).segs :
%            n Intervals x 2 ([StartTime EndTime]) matrix, if  this tier is interval tier; 
%            n Intervals x 1 ([Time]) array, if  this tier is point tier; 
%       TextGrid(i).labs=labs : n Intervals x 1 cell array
%       TextGrid(i).IsPointTier= 0 : if this tier is interval tier; 
%                                         1 : if this tier is point tier; 
% 
% Wei-rong Chen  Apr-19-2016
% Update:  Aug-1-2018:  Fix the issue of double quotation marks. 
%                      double quotation " is stored as duplication: ""
%                      in Praat TextGrid internally. 
%                Aug-2021: Added tier selection

[~,~,e]=fileparts(tgFName); 
if isempty(e), tgFName=[tgFName '.TextGrid'];end
if ~exist(tgFName, 'file'), error('File NOT exist!');end

[lines, isShort, startTime, totalDur, nTiers] = ReadValidateDataProc(tgFName); %#ok<ASGLU>
[tierNames,TierStartLineNum, IsPointTier] = GetTierNamesAndTypes(lines);

if nargin < 2 || isempty(whichTier)
    tierInd = 1:numel(tierNames);
elseif isnumeric(whichTier)
    tierInd = whichTier;
elseif ischar(whichTier) 
    tierInd = find(ismember(tierNames, whichTier));
elseif iscell(whichTier)
    j = 1;
    for i = 1:numel(whichTier)
        k = find(ismember(tierNames, whichTier{i}));
        if isempty(k),  continue; end
        tierInd(j) = k;  j = j+1;
    end
else 
    tierInd = 1:numel(tierNames);
end
k = 1; 
for i=tierInd
    tierName=tierNames{i};
    isPoint = IsPointTier(i); tierStart = TierStartLineNum(i);
    [segs, labs]=ParseOneTier(lines, isShort, isPoint, tierStart);
    TextGridStruct(k).NAME=tierName;
    TextGridStruct(k).segs=segs; %#ok<*AGROW>
    TextGridStruct(k).labs=labs;
    TextGridStruct(k).IsPointTier=isPoint;
    k = k+1;
end
end %ReadTextGrid()


%% 
function [segs, labs]=ParseOneTier(lines, isShort, isPoint, tierStart)
    nSegs = str2double(lines{tierStart+3}(regexp(lines{tierStart+3},'\d'):end));
    M = 4 - isShort - isPoint;
    StartLineNum = tierStart + 4;  EndLineNum = nSegs*M + StartLineNum - 1;
    nIntervals = (EndLineNum - StartLineNum + 1) / M;
    items = reshape(lines(StartLineNum:EndLineNum),M,nIntervals)';
    labs = items(:,M);
    kk = cellfun(@strfind, labs,repmat({'"'}, length(labs),1), 'UniformOutput',false);
    idx1 = num2cell(cellfun(@(x) x(1), kk)+1); idx2 = num2cell(cellfun(@(x) x(end), kk)-1);
    labs = cellfun(@(x, a,b) x(a:b), labs, idx1, idx2, 'UniformOutput',false);
    for i = 1:numel(labs)
        lab = labs{i};  labs{i} = strrep(lab, '""', '"');
    end
    lines1 = items(:,2-isShort:(M-1));
    segs = cellfun(@str2double,regexprep(lines1, '[^0-9.]', ''));
end %ParseOneTier
%%
function [lines, isShort, startTime, totalDur, nTiers] = ReadValidateDataProc(fName)
    encoding = DetectTextGridEncoding(fName);
    try
        lines = txt2cell(fName, encoding);
    catch
        error('error attempting to load from %s', fName);
    end
    lines=DetectStrainedQuotationSybol(lines);
    % format checking
    if length(lines)<15 || isempty(strfind(lines{1},'ooTextFile')) || isempty(strfind(lines{2},'"TextGrid"')) || isempty(strfind(lines{6},'exists'))    
        error('%s : unrecognized file format', fName);
    end
    [isShort, startTime, totalDur, nTiers]=DetectTextGridCellsLongOrShort(lines);
end %ReadValidateDataProc
%%
function [tierNames,TierStartLineNum, IsPointTier] = GetTierNamesAndTypes(lines)
% get tier names and types
    pointTierNames = {};pointTiers=[];
    intTierNames = {};intTiers =[];
    
	k = find(~cellfun(@isempty,regexp(lines,'TextTier')));
    if ~isempty(k)
		pointTiers = k + 1;
        TierNameLines = lines(pointTiers);
        kk = cellfun(@strfind,TierNameLines,repmat({'"'}, length(TierNameLines),1), 'UniformOutput',false);
        idx1 = cellfun(@(x) x(1), kk); idx2 = cellfun(@(x) x(end), kk);
        pointTierNames = cellfun(@(x, a,b) x(a:b), TierNameLines,  num2cell(idx1+1), num2cell(idx2-1), 'UniformOutput',false);
    end
    
	k = find(~cellfun(@isempty,regexp(lines,'IntervalTier')));
    if ~isempty(k)
		intTiers = k + 1;
        TierNameLines = lines(intTiers);
        kk = cellfun(@strfind,TierNameLines,repmat({'"'}, length(TierNameLines),1), 'UniformOutput',false);
        idx1 = cellfun(@(x) x(1), kk); idx2 = cellfun(@(x) x(end), kk);
        intTierNames = cellfun(@(x, a,b) x(a:b), TierNameLines,  num2cell(idx1+1), num2cell(idx2-1), 'UniformOutput',false);
    end
    tierNames = [pointTierNames;intTierNames]; 
    TierStartLineNum = [pointTiers;intTiers]; 
    IsPointTier = [true(size(pointTiers)); false(size(intTiers))]; 
    [~, TierOrder]=sort(TierStartLineNum);
    tierNames = tierNames(TierOrder); 
    TierStartLineNum = TierStartLineNum(TierOrder);
    IsPointTier = IsPointTier(TierOrder);
end %GetTierNamesAndTypes
%%
function [isShort, startTime, totalDur, nTiers]=DetectTextGridCellsLongOrShort(TGlineCells)
try
    metaData = TGlineCells([4 5 7]);
    idx1 = ~isempty(strfind(lower(metaData{1}),'xmin')); %#ok<*STREMP>
    idx2 = ~isempty(strfind(lower(metaData{2}),'xmax'));
    idx3 = ~isempty(strfind(lower(metaData{3}),'size'));
    if idx1 && idx2 && idx3
        isShort = 0;
        data =str2double(regexprep(metaData,'(XMIN|XMAX|SIZE|xmin|xmax|size|=| )',''));
    elseif ~idx1 && ~idx2 && ~idx3
        isShort = 1;
        data = str2num(char(metaData)); %#ok<ST2NM>
%         data = cellfun(@str2double, metaData);
    else 
        error('%s has unrecognized file format', fName);
    end
catch
	error('%s has unrecognized file format', fName);
end
startTime = data(1); totalDur = data(2); nTiers = data(3);
end % end of DetectTextGridCellsLongOrShort

function outTextGridLines=DetectStrainedQuotationSybol(TextGridLines)
    outTextGridLines = TextGridLines;
    ToDelete=[];
    for i = 1:length(TextGridLines)-1
        thisLine = TextGridLines{i};
        nextLine = TextGridLines{i+1};
        thisLine = strrep(thisLine,' ','');
        nextLine = strrep(nextLine,' ','');
        if strcmp(thisLine,'text="') && strcmp(nextLine(end),'"')
            ToDelete = [ToDelete i+1]; 
            outTextGridLines{i} = [TextGridLines{i} TextGridLines{i+1}];
        end
    end
    outTextGridLines(ToDelete) = [];
end %DetectStrainedQuotationSybol2
%%
function encoding = DetectTextGridEncoding(TextGridFName)
% Detect the text encoding method of a PRAAT .TextGrid file.
% Usage: encoding = DetectTextGridEncoding(TextGridFName)
    [~,~,e]=fileparts(TextGridFName);
    if isempty(e), TextGridFName=[TextGridFName '.TextGrid'];end
    encodings{1}='UTF-8'; encodings{2}='UTF-16BE'; encodings{3}='UTF-16LE';
    encodingWeight=NaN*zeros(1,length(encodings));
    wid='MATLAB:iofun:UnsupportedEncoding';
    warning('off',wid);
    for i=1:length(encodings)
        fid = fopen(TextGridFName, 'r', 'l', encodings{i});
        S = fscanf(fid, '%c'); fclose(fid);
        out = strfind(S, 'Text'); encodingWeight(i)=length(out);
    end
    [~,idx]=max(encodingWeight);
    encoding=encodings{idx};
    warning('on',wid);
end %DetectTextGridEncoding
%%
function lines = txt2cell(filename, encoding)
    % Read text file into cell array. Each line is stored in one cell in a cell array.
    % Requires MATLAB R2016b or newer. 
    % W. Chen   APR-24-2021
    if ~exist(filename, 'file'), lines = {}; fprintf('txt2cell: file not found.\n'); return; end
    permission = 'r'; % read file in text mode. See 'help fopen'.
    machinefmt = 'n'; % reading or writing in bytes or bits. 'n' = 'native' {default}
    if nargin < 2 || isempty(encoding)
        % if encoding is not specified, fopen will automatically detect the characterset set. 
        fid = fopen(filename,permission, machinefmt);
    else
        fid = fopen(filename,permission, machinefmt, encoding);
    end
    s = fscanf(fid, '%c'); fclose(fid);
    % if the first character is BOM, then remove it:
    if unicode2native(s(1))==26, s = s(2:end);end 
    % 'splitlines' is a new funciton since R2016b, which handles different EOLs.
    lines = splitlines(s); 
end  % end of  txt2cell
%%