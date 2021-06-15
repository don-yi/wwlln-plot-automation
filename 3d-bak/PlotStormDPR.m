function PlotStormDPR( fnameInfo, dir1C, dir2A, dirWwlln, outPath, outFname )

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
    % TODO
    % grid(ax, 'off');


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
    % 3D DPR plot

    [fname2A,fname2A2] = FindSatelliteFname(dir2A, timeFrom, timeTo);

    heightDs = '/NS/PRE/heightStormTop';
    fillVal = h5readatt(fname2A,heightDs,'_FillValue');

    height = h5read(fname2A,heightDs);
    % TOASK: done this for smoothness and more consistent 3D plotting
    %   (less max/min diff)
    % Change fill value to -9
    % to get a closed graph that touches the ground ???
    height(height==fillVal) = -9;

    % read from hdf5 data
    lat2A = h5read(fname2A,'/NS/Latitude');
    lon2A = h5read(fname2A,'/NS/Longitude');

    % Using a 16X16 degree grid around the center to plot
    latMin2A = cCoord(1) - 6;
    latMax2A = cCoord(1) + 6;
    lonMin2A = cCoord(2) - 6;
    lonMax2A = cCoord(2) + 6;

    % Check if any dpr data falls in the required range
    inRange2A = find(  ...
          (lat2A(1,:) > latMin2A) ...
        & (lat2A(1,:) < latMax2A) ...
        & (lon2A(1,:) > lonMin2A) ...
        & (lon2A(1,:) < lonMax2A) ...
    );

    if (isempty(inRange2A))
        disp('WARNING: 2A lat/lon data not in range');
    end

    % scale down to km
    heightKM = height(:,inRange2A)./ 1000;

    inRange2A2 = false;
    if fname2A2
        height2 = h5read(fname2A2,heightDs);
        height2(height2==fillVal) = -9;
        lat2A2 = h5read(fname2A2,'/NS/Latitude');
        lon2A2 = h5read(fname2A2,'/NS/Longitude');

        inRange2A2 = find(  ...
            (lat2A2(1,:) > latMin2A) ...
            & (lat2A2(1,:) < latMax2A) ...
            & (lon2A2(1,:) > lonMin2A) ...
            & (lon2A2(1,:) < lonMax2A) ...
        );

        if (isempty(inRange2A2))
            disp('WARNING: 2A2 lat/lon data not in range');
        end

        heightKM2 = height2(:,inRange2A2)./ 1000;

        % merge two data
        heightKM = horzcat(heightKM,heightKM2);

    end

    % gaussian kernel of width 3 and sigma 2km on the data to smooth
    heightKM = imgaussfilt(heightKM, 2, 'filtersize', 3);

    % since rows are always 49
    extrapRows = 59;
    extrapCols = length(inRange2A);
    if inRange2A2
        extrapCols = extrapCols + length(inRange2A2);
    end

    extrapLat = zeros(extrapRows, extrapCols);
    extrapLon = zeros(extrapRows, extrapCols);
    extrapHeight = zeros(extrapRows, extrapCols);

    % other helper sets of indices
    x = 6:54;
    y = 1:49;
    preIndices = 1:5;
    postIndices = 50:54;

    % put -9 into the extrapolated rows of height
    for I=1:5
    extrapHeight(I, :) = -9;
    extrapHeight(end-(I-1), :) = -9;
    end

    lat2A_inRange = lat2A(:,inRange2A);
    lon2A_inRange = lon2A(:,inRange2A);
    if inRange2A2
        lat2A2_inRange = lat2A2(:,inRange2A2);
        lon2A2_inRange = lon2A2(:,inRange2A2);

        lat2A_inRange = horzcat(lat2A_inRange, lat2A2_inRange);
        lon2A_inRange = horzcat(lon2A_inRange, lon2A2_inRange);
    end

    % extrapolate data for lat and long
    for I=1:extrapCols
        preLat = interp1(x, lat2A_inRange(:,I), preIndices, 'linear', 'extrap');
        preLon = interp1(x, lon2A_inRange(:,I), preIndices, 'linear', 'extrap');
        endLat = interp1(y, lat2A_inRange(:,I), postIndices, 'linear', 'extrap');
        endLon = interp1(y, lon2A_inRange(:,I), postIndices, 'linear', 'extrap');
        for J=1:5
            extrapLat(J,I) = preLat(J);
            extrapLon(J,I) = preLon(J);
            extrapLat(end-(J-1), I) = endLat(6-J);
            extrapLon(end-(J-1), I) = endLon(6-J);
        end
    end

    % copy old data back
    for I=1:extrapCols
        for J=1:49
            extrapHeight(J+5,I) = heightKM(J,I);
            extrapLon(J+5,I) = lon2A_inRange(J,I);
            extrapLat(J+5,I) = lat2A_inRange(J,I);
        end
    end

    % TODO: check back later for necessity (grid)
    % Create a 100x100 grid for each degree in the range and grid the data
    % on that range
    gridY = latMin2A:0.01:latMax2A;
    gridX = lonMin2A:0.01:lonMax2A;
    [xq, yq] = meshgrid(gridX, gridY);

    % grid the extrapolated data using the natural method
    gd = griddata(extrapLon, extrapLat, extrapHeight, xq, yq, 'natural');

    if inRange2A
        % Draw the plot using the surf commmand
        s = surf(xq,yq, gd, 'FaceColor', 'interp', 'FaceAlpha',0);
        s.EdgeColor = 'none';

        % % Compile the c-code functions
        % mex smoothpatch_curvature_double.c
        % mex smoothpatch_inversedistance_double.c
        % mex vertex_neighbours_double.c

        disp('Compiled C-code, proceeding to produce plot');

        ps = surf2patch(s);
        s2 = smoothpatch(ps, 0, 15);

        patch(s2, 'FaceColor','interp','EdgeAlpha',0, 'FaceAlpha', 0.5);
    end

    %%
    % Setup the Colormap and graph limits
    colormap(jet(64));
    min_data=0;
    max_data=20;

    % setup axes limits for the plot and colorbar
    xlim([lonMin2A lonMax2A]);
    ylim([latMin2A latMax2A]);
    zlim([min_data max_data]);
    caxis([min_data max_data]);

    % overlapping the original colorbar
    hAx=gca;                     % save axes handle main axes
    h=colorbar('Location','southoutside', ...
        'Position',[0.15 0.1 0.7 0.02]);% add colorbar, save its handle
    set(h, 'XDir', 'reverse'); % reverse axis
    h2Ax=axes('Position',h.Position,'color','none');  % add mew axes at same posn
    h2Ax.YAxis.Visible='off'; % hide the x axis of new
    h2Ax.XAxisLocation = 'top';
    h2Ax.Position = [0.15 0.11 0.7 0.01];  % put the colorbar back to overlay second axeix
    h2Ax.XLim=[120 260];       % alternate scale limits new axis
    xlabel(h, 'Height (km)','HorizontalAlignment','center');
    xlabel(h2Ax,'89V GHz (Tb)','HorizontalAlignment','center');

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

    % get and scale melting layer height (km)
    heightZero = h5read(fname2A,'/NS/VER/heightZeroDeg');
    heightZeroKM = heightZero(:, inRange2A) ./ 1000;
    if fname2A2
        heightZero2 = h5read(fname2A2,'/NS/VER/heightZeroDeg');
        heightZeroKM2 = heightZero2(:, inRange2A2) ./ 1000;
        heightZeroKM = horzcat(heightZeroKM,heightZeroKM2);
    end
    hMean = mean2(heightZeroKM);
    hWwlln = ones(length(latWwlln), 1) .* hMean;

    % scatter on 3D
    scatter3( ...
        lonWwlln, latWwlln, hWwlln, ...
        30, ...
        'magenta', ...
        'filled', ...
        'LineWidth', .05, ...
        'MarkerEdgeColor', 'k' ...
    );

    hold off;


    shg;


    %%
    % Set the view and lights

    % set light
    camlight('headlight');
    light('Position',[lonMax2A latMax2A 0],'Style','local');
    lighting gouraud

    % set title
    name = 'NS/PRE/heightStormTop';
    stormName = infoStruct.storm_name;
    title( ...
        hAx, {stormName; outFname; name}, ...
        'Interpreter', 'None', 'FontSize', 12, 'FontWeight', 'bold' ...
    );

    view(0, 90);

    % gen full file name
    fullOutFname = fullfile(outPath, [outFname, '.gif']);

    % Setup the variables needed to speed up the third frame generating loop,
    % which is simply the same frames as the first loop but in the reverse order.
    firstInterpCount = 15;                        %%%%%
    gifFrames        = cell(firstInterpCount, 1); %%%%%

    % Rotate from 90 to 45
    for J=1:firstInterpCount%15
        view(0, 90 - 3*J);
        frame = getframe(f);
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);
        % Store the frame data to be used in the third frame loop.
        gifFrames{J} = {imind; cm}; %%%%%
        if J == 1
            imwrite(imind,cm,fullOutFname,'gif', 'Loopcount',inf);
        else
            imwrite(imind,cm,fullOutFname,'gif','WriteMode','append');
        end
    end

    % Rotate 360 about y-axis
    for J=1:40
        view(9*J, 45);
        frame = getframe(f);
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);
        % keep appending to the same gif file
        imwrite(imind,cm,fullOutFname,'gif','WriteMode','append');
    end

    % Rotate back to 90 from 45
    % Draw the frames generated from the first loop to the GIF but in reverse
    % order. This reduces the computation time by avoiding redundant computation.
    for J=firstInterpCount:-1:1 %%%%%
        view(0, 45 + 3*J)

        prevFrame = gifFrames{J}; %%%%%
        imind     = prevFrame{1}; %%%%%
        cm        = prevFrame{2}; %%%%%

        % Write to the GIF File
        imwrite(imind,cm,fullOutFname,'gif','WriteMode','append');
    end
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
        % return;
    end

    % get data in plot range
    latInRange = lat(:,inRange);
    lonInRange = lon(:,inRange);
    tc89V = tc89V(:,inRange);

    % trim extreme high temp
    tc89V(tc89V > 265) = NaN;

    % scaling with 0.120 so that the data scales down to 0-20
    % and the same color bar can be used for both height and brightness temp.
    tc89V = abs(tc89V - 300) .* 0.120;

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