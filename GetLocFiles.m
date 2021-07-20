function locFiles = GetLocFiles(StormYear, varargin)
    % Optional Arguments (date): mm, dd, HH, MM
    optionalArgs = {'', '', '', ''};
    optionalArgCount = length(optionalArgs);
    varargCount = length(varargin);

    if (varargCount > optionalArgCount)
        error('GetLocFiles:TooManyInputs',                     ...
              ['requires at most ', num2str(optionalArgCount), ...
               ' optional inputs!']);
    end

    optionalArgs(1:varargCount) = varargin(:);
    [StormMonth, StormDay, StormHour, StormMinute] = optionalArgs{:};

    %namePattern = [StormYear, varargin{:}, '*.loc'];
    %for i =
    %namePattern = [namePattern, '*.loc'];
    wwlln_data_path__ = evalin('base', 'wwlln_data_path__');
    AEFilePrefix = 'AE';
    AFilePrefix  = 'A';
    AEFilename = @(stormYear, stormMonth, stormDay)([AEFilePrefix, stormYear, stormMonth, stormDay, '*.loc']);
    AFilename = @(stormYear, stormMonth, stormDay, stormHour, stormMinute)([AFilePrefix, stormYear, stormMonth, stormDay, stormHour, stormMinute, '*.loc']);
    AEFilesDirectory = fullfile(wwlln_data_path__, 'AEFiles');
    AFilesDirectory1 = fullfile(wwlln_data_path__, 'AFiles');
    AFilesDirectory2 = fullfile(wwlln_data_path__, 'AFiles', 'AFiles');

    %filename = fullfile(AEFilesDirectory, ['AE', namePattern]);
    aeFilename  = AEFilename(StormYear, StormMonth, StormDay);
    locFolder   = AEFilesDirectory;
    filename    = fullfile(locFolder, aeFilename);
    locFiles    = dir(filename);
    locFileType = AEFilePrefix;
    locFormat   = struct('formatString',                             ...
                         '%g/%g/%g,%g:%g:%g,%g,%g,%g,%g,%g,%g,%g\n', ...
                         'inputCount', 13);

    % Check for the AE file for the StormDay
    if (size(locFiles, 1) == 0)
        % Check for the A files for the StormDay
        disp(['Could not find file(s): ', filename]);
        aFilename   = AFilename(StormYear, StormMonth, StormDay, StormHour, StormMinute);
        locFolder   = AFilesDirectory1;
        filename    = fullfile(locFolder, aFilename);
        locFiles    = dir(filename);
        locFileType = AFilePrefix;
        locFormat   = struct('formatString',                    ...
                             '%g/%g/%g,%g:%g:%g,%g,%g,%g,%g\n', ...
                             'inputCount', 10);

        if (size(locFiles, 1) == 0)
            % Check the alternative location for the A files for the StormDay
            disp(['Could not find file(s): ', filename]);
            locFolder = fullfile(AFilesDirectory2, StormYear);
            filename  = fullfile(locFolder, aFilename);
            locFiles  = dir(filename);
            % If we couldn't find the .loc files in any form for the
            % current StormDay, move on to the next StormDay.
            if (size(locFiles, 1) == 0)
                disp(['Could not find file(s): ', filename]);
                disp(['Could not find the .loc files for the given ', ...
                      'timestamp (', StormYear, varargin{:}, '). ',   ...
                      'Moving on to the next file.']);
            end
        end
    end

    for i = 1:size(locFiles, 1)
        locFiles(i).folder      = locFolder;
        locFiles(i).locFileType = locFileType;
        locFiles(i).locFormat   = locFormat;
    end
