function PlotStorm2D( fnameInfo, dir1C, dir2A, dirWwlln, outPath, outFname )

    %% read plot info from sector info file
    % ref below link to download YAMLMATLAB & add to path
    % https://code.google.com/archive/p/yamlmatlab/

    infoStruct = ReadYaml(fnameInfo);

    % plot range
    clat = infoStruct.clat;
    clon = infoStruct.clon;
    cCoord = [clat,clon];

    % get passtime as serial date num
    % in/sector-info/20210313_041146_SH242021_gmi_GPM_89pct_100kts_19p18_1p0.png.yaml
    passtimeSubstr = fnameInfo(16:30);
    passtimeDN  = datenum(passtimeSubstr, 'yyyymmdd_HHMMSS');
    twoMinDN = datenum(0,0,0,0,2,0);

    % get plot time range
    timeFrom = passtimeDN - twoMinDN;
    timeTo   = passtimeDN + twoMinDN;

    % name for title
    sName = infoStruct.storm_name;

    %%
    % world map and label

    % Create a figure
    bgColor = [0.95 0.95 0.95];
    figure( ...
        'Color',bgColor,'Position',[0 0 1024 1024],'visible','off' ...
    );

    % Create a figure
    f=figure('Color',    bgColor,         ...
             'Position', [0 0 1024 1024], ...
             'visible',  'off');

    % Load and plot the world map first
    load('Map.mat');

    % Draw world map in black line with the equator
    z = zeros(size(world(:,1)));
    plot3(world(:,1),world(:,2),z,'k-','LineWidth',1.0);

    hold on;

    % add labels to graph
    ax = gca;
    ax.Units = 'pixels';
    ax.Position = [150 200 700 700];
    ax.Box = 'off';
    ax.Layer = 'top';
    ax.ZAxis.Visible = 'off';
    ax.Color = [0.95 0.95 0.95];


    %%
    % 2D 89V plot

    [fname1C,fname1C2] = FindSatelliteFname(dir1C, timeFrom, timeTo);

    % plot range
    minlat = cCoord(1) - 11;
    maxlat = cCoord(1) + 11;
    minlon = cCoord(2) - 16;
    maxlon = cCoord(2) + 16;
    plotRange = [minlat,maxlat,minlon,maxlon];

    [lat_inRange,lon_inRange,tc89V] = GetPlotInfo(fname1C, plotRange);
    % if data is extended to next file
    if fname1C2
        [lat_inRange2,lon_inRange2,tc89V2] = GetPlotInfo(fname1C2, plotRange);

        % merge two data
        lat_inRange = horzcat(lat_inRange,lat_inRange2);
        lon_inRange = horzcat(lon_inRange,lon_inRange2);
        tc89V = horzcat(tc89V,tc89V2);
    end

    % plot 1C w/ data found
    pcolorCentered_old(lon_inRange,lat_inRange,tc89V);


    %%
    % Setup the Colormap and graph limits
    colormap(flipud(jet(64)));
    % TODO: smooth but less accurate
    % shading interp;

    min_data=120;
    max_data=260;

    % setup axes limits for the plot and colorbar
    xMin = cCoord(2) - 6;
    xMax = cCoord(2) + 6;
    yMin = cCoord(1) - 6;
    yMax = cCoord(1) + 6;
    xlim([xMin xMax]);
    ylim([yMin yMax]);
    caxis([min_data max_data]);

    % overlapping the original colorbar
    hAx=gca;                     % save axes handle main axes
    h=colorbar('Location','southoutside', ...
        'Position',[0.15 0.1 0.7 0.02]);% add colorbar, save its handle
    h.XAxisLocation = 'bottom';
    xlabel(h,'89V GHz (Tb)','HorizontalAlignment','center');

    % Set current back to the main one (done manually so that the other
    % properties such as visibility are not affected).
    % -- Connor Bracy 05/25/2020
    hGifFig = gcf;
    hGifFig.CurrentAxes = hAx;
    % Attmpt to speed up the processing by hiding all figures, setting the current figure to the one
    % that will be used to create the GIF images, and setting it to be the only visible figure
    % so that getframe isn't slowed down by 'capturing the frame of a figure not visible on the screen'
    % which supposedly greatly reduces the computational efficiency of the function.
    % -- Connor Bracy 05/27/2020
    set(findobj('Type', 'Figure'), 'Visible', 'off'); % Make all figures in this MATLAB workspace non-visible
    set(0, 'CurrentFigure', hGifFig); % Set the current figure of the workspace to the figure we will use to generate images.

    %%
    % Draw lightning

    % find .loc file from wwlln dir
    % passtimeSubstr = fnameInfo(16:30);
    dateWwlln = datenum(passtimeSubstr, 'yyyymmdd');
    fnameWwlln = FindWwllnFname(dirWwlln, dateWwlln);

    % format for .loc files is
    % year/month/day, hr:min:sec, latitude, longitude, error, number of stations
    % 2013/11/07,00:00:00.181689, 23.7676, -86.0661, 13.0, 14
    fidWwlln = fopen(fnameWwlln);
    lightningData = textscan(fidWwlln,'%s %s %f %f %f %d','Delimiter',',');
    fclose(fidWwlln);

    % split time data field
    lightningDateTime = append(lightningData{1}, lightningData{2});
    lightningLat = lightningData{3};
    lightningLon = lightningData{4};

    % org as serial date num
    lightningDN = datenum(lightningDateTime, 'yyyy/mm/ddHH:MM:SS');

    % get passtime as serial date num
    oneHour = datenum(0,0,0,1,0,0);
    lightningTimeFrom = passtimeDN - oneHour;
    lightningTimeTo = passtimeDN + oneHour;

    % find ind during storm
    indDuringStorm = find( ...
        lightningTimeFrom <= lightningDN & lightningDN < lightningTimeTo);

    % find all in geo & time range
    latDuringStorm = lightningLat(indDuringStorm);
    lonDuringStorm = lightningLon(indDuringStorm);

    % % THIS IS NO DURING STORM BUT THE WHOLE DAY
    % latDuringStorm = lightningLat;
    % lonDuringStorm = lightningLon;

    % minlat = cCoord(1) - 11;
    % maxlat = cCoord(1) + 11;
    % minlon = cCoord(2) - 16;
    % maxlon = cCoord(2) + 16;
    idxInRange = find(minlat <= latDuringStorm & latDuringStorm <= maxlat ...
                    & minlon <= lonDuringStorm & lonDuringStorm <= maxlon);

    % pruning lat/lon arrays to ind of during and in storm
    latWwlln = latDuringStorm(idxInRange);
    lonWwlln = lonDuringStorm(idxInRange);

    % scatter on 2D
    scatter( ...
        lonWwlln, latWwlln, ...
        16, ...
        'black', ...
        'filled', ...
        'LineWidth', .05, ...
        'MarkerEdgeColor', 'black' ...
    );

    hold off;


    %%
    % Set the title and view
    title(hAx, { sName; outFname; '/S1/Tc' }, ...
          'Interpreter', 'None', 'FontSize', 20,'FontWeight','bold');

    view(0,90);

    fullOutFname = fullfile(outPath, [outFname, '.jpg']); % gen full file name
    print(fullOutFname, '-djpeg'); % output to jpeg

end


%% time matching hdf5 getter fn
function [fnameData1,fnameData2] = FindSatelliteFname(dirPath, timeFrom, timeTo)

    files = dir(fullfile(dirPath, '*.RT-H5')); % gets all files in struct
    for index = 1:length(files)

        % get str to parse time
        basefname = files(index).name;

        % get date info from fname
        % 1c.gpm.gmi.xcal2016-c.20210310-s011518-e012016.v05a.rt-h5
        y = str2double(basefname(23:26));
        m = str2double(basefname(27:28));
        d = str2double(basefname(29:30));
        starth  = str2double(basefname(33:34));
        startmn = str2double(basefname(35:36));
        starts  = str2double(basefname(37:38));
        endh  = str2double(basefname(41:42));
        endmn = str2double(basefname(43:44));
        ends  = str2double(basefname(45:46));

        % transfer to serial date num
        starttime = datenum( y, m, d, starth, startmn, starts );
        endtime   = datenum( y, m, d, endh,   endmn,   ends   );

        % find file in range
        if starttime <= timeFrom && timeFrom < endtime
            fnameData1 = fullfile(dirPath, basefname);

            % check if it's wrapping data
            fnameData2 = false;
            if timeTo > endtime
                basefname2 = files(index+1).name;
                fnameData2 = fullfile(dirPath, basefname2);
            end
            break;
        end
    end
end


%% 1c plot info getter fn
function [latInRange,lonInRange,tc89V] = GetPlotInfo(inFile1c, plotRange)

    % read 1C S1 lat and lon
    lat = h5read(inFile1c,'/S1/Latitude');
    lon = h5read(inFile1c,'/S1/Longitude');

    % read tc 89V from tc
    tc89V = zeros(size(lon));
    tc = h5read(inFile1c,'/S1/Tc');
    tc89V(:,:) = tc(8,:,:);

    % plot range
    minlat = plotRange(1);
    maxlat = plotRange(2);
    minlon = plotRange(3);
    maxlon = plotRange(4);

    % The 89V data needs to be scaled to be in the same range
    % as the DPR data so that it can use the same colormap
    inRange = find( ...
          (lat(1,:) > minlat)  ...
        & (lat(1,:) < maxlat)  ...
        & (lon(1,:) > minlon) ...
        & (lon(1,:) < maxlon) ...
    );

    if (isempty(inRange))
        disp('WARNING: 1C lat/lon data not in range');
    end

    % get data in plot range
    latInRange = lat(:,inRange);
    lonInRange = lon(:,inRange);
    tc89V = tc89V(:,inRange);

    % trim extreme high temp
    tc89V(tc89V > 265) = NaN;

end


%% time matching .loc getter fn
function fnameWwlln = FindWwllnFname(dirWwlln, dateWwlln)

    files = dir(fullfile(dirWwlln, '*.loc')); % gets all files in struct
    for index = 1:length(files)

        % get str to parse time
        basefname = files(index).name;

        % get date info from fname to serial date num
        % Daily WWLLN data: e.g., A20131103.loc
        baseSubstr = basefname(2:9);
        dateFile = datenum(baseSubstr, 'yyyymmdd');

        % find file in range
        if dateFile == dateWwlln
            fnameWwlln = fullfile(dirWwlln, basefname);
            break;
        end
    end
end