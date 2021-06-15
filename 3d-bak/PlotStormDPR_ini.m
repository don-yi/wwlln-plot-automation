fnameInfo = ...
'in/sector-info/20210311_174019_SH242021_gmi_GPM_89pct_125kts_7p50_1p0.png.yaml';
% fnameInfo = ...
% 'in/sector-info/20210313_041146_SH242021_gmi_GPM_89pct_100kts_19p18_1p0.png.yaml';
% fnameInfo = ...
% 'in/sector-info/20210316_162757_SH242021_gmi_GPM_89pctClean_30kts_5p03_1p0.png.yaml';

dir1C    = 'data-files-dir/1c/';
dir2A    = 'data-files-dir/2a/';
dirWwlln = 'data-files-dir/wwlln/';
% dir1C    = 'D:\nrt\1c';
% dir2A    = 'D:\nrt\2a';
% dirWwlln = 'D:\wwlln';

outPath  = 'out/';
outFname = 'test-out';

PlotStormDPR( fnameInfo, dir1C, dir2A, dirWwlln, outPath, outFname )
