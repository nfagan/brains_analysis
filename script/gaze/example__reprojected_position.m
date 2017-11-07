%%

import brains_analysis.gaze.process.*;
import brains_analysis.gaze.util.*;
import brains_analysis.process.get_plex_events;

conf = brains_analysis.config.load();
data_dir = fullfile( conf.PATHS.data.raw, conf.PATHS.data.free_viewing );
date_dir = '110217';

addpath( fullfile(conf.PATHS.repositories, 'shared_utils') );
addpath( genpath(fullfile(conf.PATHS.repositories, 'plexon')) );
addpath( genpath(fullfile(conf.PATHS.repositories, 'eyelink')) );

m1_edf_dir = fullfile( data_dir, date_dir, 'edf', 'm1' );
m2_edf_dir = fullfile( data_dir, date_dir, 'edf', 'm2' );
m1_plex_dir = fullfile( data_dir, date_dir, 'plex' );

m1_edf_files = shared_utils.io.dirnames( m1_edf_dir, '.edf', true );
m2_edf_files = shared_utils.io.dirnames( m2_edf_dir, '.edf', true );
pl2_files = shared_utils.io.dirnames( m1_plex_dir, '.pl2', true );

assert( numel(m1_edf_files) == numel(m2_edf_files) && ~isempty(m1_edf_files) );
assert( numel(pl2_files) == 1, 'Too many or too few .pl2 files.' );

pl2_fname = pl2_files{1};
distances_fname = fullfile( data_dir, date_dir, 'mat', 'distances.json' );
rois_fname = fullfile( data_dir, 'rois.json' );

m1_edf = Edf2Mat( m1_edf_files{1} );
m2_edf = Edf2Mat( m2_edf_files{1} );
distances = jsondecode( fileread(distances_fname) );
rois = jsondecode( fileread(rois_fname) );
pl2 = PL2GetFileIndex( pl2_fname );

plx_evts = get_plex_events( pl2_fname, {'AI02'}, 'AI02' );

m1_start_index = find( strcmpi(m1_edf.Events.Messages.info, 'SYNCH') );
m2_start_index = find( strcmpi(m2_edf.Events.Messages.info, 'SYNCH') );
assert( numel(m1_start_index) == 1 && numel(m2_start_index) == 1);

start_time_m1 = m1_edf.Events.Messages.time( m1_start_index );
start_time_m2 = m2_edf.Events.Messages.time( m2_start_index );

pos_m1 = [ m1_edf.Samples.posX, m1_edf.Samples.posY ];
pos_m2 = [ m2_edf.Samples.posX, m2_edf.Samples.posY ];
time__m1 = m1_edf.Samples.time;
time__m2 = m2_edf.Samples.time;
start_index_m1 = time__m1 == start_time_m1;
start_index_m2 = time__m2 == start_time_m2;

assert( sum(start_index_m1) == 1 && sum(start_index_m2) == 1 );

%%  get projected position

m1_opts = distances.m1;
m2_opts = distances.m2;

[pos_m1_on_m2, origin_m2_rel_to_m1] = get_projected_position_and_origin( m1_opts, m2_opts, pos_m1 );
[pos_m2_on_m1, origin_m1_rel_to_m2] = get_projected_position_and_origin( m2_opts, m1_opts, pos_m2 );

pos_m1_on_m2 = pos_m1_on_m2( find(start_index_m1):end, : );
pos_m2_on_m1 = pos_m2_on_m1( find(start_index_m2):end, : );

time_m1 = time__m1( find(start_index_m1):end );
time_m2 = time__m2( find(start_index_m2):end );

rows_m1 = size( pos_m1_on_m2, 1 );
rows_m2 = size( pos_m2_on_m1, 1 );

if ( rows_m1 > rows_m2 )
  pos_m1_on_m2 = pos_m1_on_m2( 1:rows_m2, : );
  time_m1 = time_m1( 1:rows_m2 );
elseif ( rows_m2 > rows_m1 )
  pos_m2_on_m1 = pos_m2_on_m1( 1:rows_m1, : );
  time_m2 = time_m2( 1:rows_m1 );
end

%%  bounds

ox_m2_rel_m1 = origin_m2_rel_to_m1(1);
oy_m2_rel_m1 = origin_m2_rel_to_m1(2);
ox_m1_rel_m2 = origin_m1_rel_to_m2(1);
oy_m1_rel_m2 = origin_m1_rel_to_m2(2);

rect_m2_rel_m1 = [ ox_m2_rel_m1-10, oy_m2_rel_m1-10, ox_m2_rel_m1+10, oy_m2_rel_m1+10 ];
rect_m1_rel_m2 = [ ox_m1_rel_m2-10, oy_m1_rel_m2-10, ox_m1_rel_m2+10, oy_m1_rel_m2+10 ];

in_bounds_m1_rel_m2 = rect_roi_in_bounds( pos_m1_on_m2, rect_m2_rel_m1 );
in_bounds_m2_rel_m1 = rect_roi_in_bounds( pos_m2_on_m1, rect_m1_rel_m2 );

fprintf( '\n %0.2f %% in bounds m1', sum(in_bounds_m1_rel_m2)/numel(in_bounds_m1_rel_m2) * 100 );
fprintf( '\n %0.2f %% in bounds m2', sum(in_bounds_m2_rel_m1)/numel(in_bounds_m1_rel_m2) * 100 );
fprintf( '\n %0.2f %% in bounds m1 + m2', sum(in_bounds_m1_rel_m2 & in_bounds_m2_rel_m1)/numel(in_bounds_m1_rel_m2) * 100 );

%%  scatter

figure(1); clf();
subplot( 1, 2, 1 ); 
plot( pos_m1_on_m2(:, 1), pos_m1_on_m2(:, 2), 'k*', 'markersize', .1 );

title( 'M1: Kuro looking to Ephron' );

o_x = origin_m2_rel_to_m1(1);
o_y = origin_m2_rel_to_m1(2);

min_x = o_x - 10;
max_x = o_x + 10;
min_y = o_y - 10;
max_y = o_y + 10;

hold on;
plot( [min_x; max_x], [min_y; min_y], 'r', 'linewidth', 2 );
plot( [min_x; min_x], [min_y; max_y], 'r', 'linewidth', 2 );
plot( [min_x; max_x], [max_y; max_y], 'r', 'linewidth', 2 );
plot( [max_x; max_x], [max_y; min_y], 'r', 'linewidth', 2 );

xlim( [-150, 150] );
ylim( [-150, 150] );

subplot( 1, 2, 2 );
plot( pos_m2_on_m1(:,1), pos_m2_on_m1(:,2), 'k*', 'markersize', .1 );

title( 'M2: Ephron Looking to Kuro' );

o_x = origin_m1_rel_to_m2(1);
o_y = origin_m1_rel_to_m2(2);

min_x = o_x - 10;
max_x = o_x + 10;
min_y = o_y - 10;
max_y = o_y + 10;

hold on;
plot( [min_x; max_x], [min_y; min_y], 'r', 'linewidth', 2 );
plot( [min_x; min_x], [min_y; max_y], 'r', 'linewidth', 2 );
plot( [min_x; max_x], [max_y; max_y], 'r', 'linewidth', 2 );
plot( [max_x; max_x], [min_y; max_y], 'r', 'linewidth', 2 );

xlim( [-150, 150] );
ylim( [-150, 150] );



