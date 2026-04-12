function batch_contours2csv(myPath, nOut)
%BATCH_CONTOURS2CSV Convert all valid contour .mat files in a folder to CSV.
%
%   BATCH_CONTOURS2CSV()              uses pwd and 20 resample points.
%   BATCH_CONTOURS2CSV(myPath)        uses the specified folder path.
%   BATCH_CONTOURS2CSV(myPath, nOut)  resamples contours to nOut points.
%
%   Input:
%       myPath - (optional) folder path to scan. Defaults to pwd if omitted
%                or empty.
%       nOut   - (optional) number of equally spaced resample points.
%                Default: 20.
%
%   Validation criteria:
%       1. The .mat file must contain exactly one variable.
%       2. The variable must be a struct array.
%       3. The struct must have at least the fields: FRAME, TIME, NOTE, XY.
%       4. The XY field of the first element must be an N x 2 numeric matrix.
%
%   Output:
%       For each valid file, a UTF-8 encoded CSV is saved in the same folder
%       with the same base name (e.g., recording.mat -> recording.csv).
%       Skipped files are reported with a reason in the command window.
%
%   Example:
%       batch_contours2csv();                        % pwd, 20 points
%       batch_contours2csv('C:\data\contours');      % specific folder, 20 points
%       batch_contours2csv('C:\data\contours', 50);  % specific folder, 50 points
%       batch_contours2csv('', 10);                  % pwd, 10 points
%
%   See also WRITETABLE, DIR.

    if nargin < 1 || isempty(myPath), myPath = pwd; end
    if nargin < 2 || isempty(nOut),   nOut = 20;     end
    reqFields = {'FRAME','TIME','NOTE','XY'};
    matFiles  = dir(fullfile(myPath, '*.mat'));
    if isempty(matFiles), fprintf('No .mat files found in %s\n', myPath); return; end

    for k = 1:numel(matFiles)
        mname = matFiles(k).name;
        fname = fullfile(myPath, mname);
        [~, baseName] = fileparts(fname);

        % Load and validate
        vars = whos('-file', fname);
        if numel(vars) ~= 1,                fprintf('SKIP  %s  (contains %d variables, expected 1)\n', mname, numel(vars)); continue; end
        S = load(fname); varName = fieldnames(S); data = S.(varName{1});
        if ~isstruct(data),                  fprintf('SKIP  %s  (variable "%s" is not a struct)\n', mname, varName{1}); continue; end
        miss = setdiff(reqFields, fieldnames(data));
        if ~isempty(miss),                   fprintf('SKIP  %s  (missing fields: %s)\n', mname, strjoin(miss,', ')); continue; end
        if ~isnumeric(data(1).XY) || size(data(1).XY,2) ~= 2
                                             fprintf('SKIP  %s  (XY is not an N x 2 numeric matrix)\n', mname); continue; end

        % Convert and save as UTF-8 CSV
        T = contours2table(data, nOut);
        writetable(T, fullfile(myPath, [baseName '.csv']), 'Encoding', 'UTF-8');
        fprintf('SAVED %s  (%d rows, %d columns)\n', [baseName '.csv'], height(T), width(T));
    end

    %% ---- nested functions --------------------------------------------------
    function T = contours2table(contours, nPts)
    %CONVERT Convert contours struct array to a table with resampled XY.
        n = numel(contours);
        FRAME = arrayfun(@(c) c.FRAME, contours(:));
        TIME  = arrayfun(@(c) c.TIME,  contours(:));
        NOTE  = strings(n, 1);
        for i = 1:n
            if isempty(contours(i).NOTE), NOTE(i) = ""; else, NOTE(i) = string(contours(i).NOTE); end
        end
        X = zeros(n, nPts); Y = zeros(n, nPts);
        for i = 1:n
            xy = resample_xy(contours(i).XY, nPts);
            X(i,:) = xy(:,1)'; Y(i,:) = xy(:,2)';
        end
        X = round(X, 2); Y = round(Y, 2);
        T = [table(FRAME, TIME, NOTE), ...
             array2table(X, 'VariableNames', compose("x_%d", 1:nPts)), ...
             array2table(Y, 'VariableNames', compose("y_%d", 1:nPts))];
    end

    function xy = resample_xy(XY, nPts)
    %RESAMPLE_XY Resample contour to nPts equally spaced points along arc length.
        d  = [0; cumsum(sqrt(sum(diff(XY).^2, 2)))];
        dq = linspace(0, d(end), nPts)';
        xy = interp1(d, XY, dq, 'makima');
    end

end % batch_contours2csv
