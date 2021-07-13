% Make sure MATLAB knows where out main scripts folder is
path(path, 'C:\Users\k726t\src\repo\wwlln-plot-automation');
set(0, 'DefaultFigureVisible', 'off');

storm__ = 0;
storm_name__ = 'Laura';
date_time__ = datetime(2021, 07, 10, 15, 59, 41);
mission_sensor_map__ = containers.Map({'GPM', 'SSMIS', 'TRMM', 'SSMI'}, {{'GMI'}, {'F16', 'F17', 'F18', 'F19', 'F20'}, {'TMI'}, {'F10', 'F11', 'F12', 'F13', 'F14', 'F15'}});
resources__ = {0};
pipeline__ = 0;
product__ = 0;
product_name__ = 'Storm_Track_Map';
input_instances_lists__ = {containers.Map({'files', 'path'}, {{'ATL_20_13_Laura_Reduced_Trackfile.txt', 'ATL_20_13_Laura_WWLLN_Locations.txt'}, '/wd3/storms/wwlln/data/raw_data/20/ATL/13/'})};
output_instances_list__ = containers.Map({'files', 'path'}, {{'ATL_20_13_Laura_Track_Map.jpg', 'ATL_20_13_Laura_Track_Map.jpg'}, '/wd3/storms/wwlln/data/processed_data/20/ATL/13/track_map'});
success__ = true;
storm_trackfile__ = '/wd3/storms/wwlln/data/raw_data/20/ATL/13/ATL_20_13_Laura_Reduced_Trackfile.txt';
storm_wwlln_locations__ = '/wd3/storms/wwlln/data/raw_data/20/ATL/13/ATL_20_13_Laura_WWLLN_Locations.txt';
wwlln_data_path__ = '/wd3/storms/wwlln/lightning';
storm_filename_prefix__ = 'ATL_20_13_Laura_';
script__ = 0;
output_name_pattern__ = 'ATL_20_13_Laura_Track_Map';
output_file_count__ = 1;
