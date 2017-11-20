import brains_analysis.process.add_pair_id;
import brains_analysis.process.match_pair_id_to_other;
import brains_analysis.io.get_plex_starts;
import brains_analysis.util.general.find_logical_starts;
import brains_analysis.io.get_rois;
import brains_analysis.process.get_in_bounds_index;
import brains_analysis.process.roi_file_to_container;
import brains_analysis.process.add_unit_id;
import brains_analysis.plot.eg__position_plot;
import shared_utils.io.dirnames;
import shared_utils.io.require_dir;

conf = brains_analysis.config.load();
data_p = fullfile( conf.PATHS.data.root, 'free_viewing', 'raw' );
save_p = fullfile( conf.PATHS.data.root, 'free_viewing', 'processed', 'plex' );

session_dirs = shared_utils.io.dirnames( data_p, 'folders', false );
% session_dirs = { '110617_1', '110617_2' };

for idx = 1:numel(session_dirs)
  
fprintf( '\nProcessing ''%s'' (%d of %d)', session_dirs{idx}, idx, numel(session_dirs) );
  
full_save_p = fullfile( save_p, session_dirs{idx} );
require_dir( full_save_p );

starts = add_pair_id( brains_analysis.io.get_plex_starts(conf, session_dirs{idx}) );

%%

meas = brains_analysis.io.get_meas_xls();

res = brains_analysis.process.meas_xls2mat( meas );
res = brains_analysis.process.meas_mat2container( res );

%%

subset = res(['spike', starts.flat_uniques({'date', 'session'})]);
neural_data = brains_analysis.io.get_neural_data( conf, subset );

%%  

aligned = brains_analysis.process.align_plex_by_pair_id( neural_data, starts );

%%  load position data

pos_io = brains_analysis.io.get_fv_h5( conf, fullfile('edf', 'raw_positions.h5') );
pos = pos_io.read( '/Position', 'only', aligned.flat_uniques({'date', 'session'}) );
key = pos_io.read( '/Key' );
pos = add_pair_id( pos );

%%  bounds

rois = roi_file_to_container( get_rois() );

subset = pos;
[in_bounds, bounds_key] = get_in_bounds_index( subset, rois, key );

%%

m1 = in_bounds({'kuro'});
m2 = in_bounds({'cronenberg'});

% eg__position_plot( m1, m2, bounds_key );

%%

cmbs_within = { 'pair_id', 'roi' };
C = in_bounds.pcombs( cmbs_within );

id_ns = cellfun( @(x) str2double(x(numel('pair_id__')+1:end)), C(:, 1) );
[~, index] = sort( id_ns );
C = C(index, :);

new_spikes = Container();

look_back = -1;
look_amt = 2;
bin_size = .05;

psth_func = @brains_analysis.process.get_basic_psth;

for i = 1:size(C, 1)
  fprintf( '\n Processing %d of %d', i, size(C, 1) );
  
  assert( any(strcmp(cmbs_within, 'roi')) );
  
  monks = in_bounds.uniques_where('monkey', C{i, 1});
  
  assert( numel(monks) == 2 );
  
  m1 = in_bounds([monks(1), C(i, :)]);
  m2 = in_bounds([monks(2), C(i, :)]);

  m1_in = m1.data(:, strcmp(bounds_key, 'in_bounds')) == 1;
  m2_in = m2.data(:, strcmp(bounds_key, 'in_bounds')) == 1;

  mutual = find_logical_starts( m1_in & m2_in, 3 );
  mutual_times = m1.data(mutual, strcmp(bounds_key, 'time'));
  mutual_times = mutual_times ./ 1e3;
  
  if ( isempty(mutual_times) )
    fprintf( '\n No mutual times found.' );
    continue;
  end

  matching_spikes = aligned(m1('pair_id'));
  matching_spikes = matching_spikes({'spike'});
  matching_spikes = matching_spikes.require_fields( 'roi' );
  matching_spikes( 'roi' ) = C{i, strcmp(cmbs_within, 'roi')};
  
  psth_spikes = matching_spikes;
  psth_spikes.data = cellfun( @(x) x(x>=0), psth_spikes.data, 'un', false );

  for k = 1:numel(psth_spikes.data)
    current = psth_spikes(k);
    data = current.data{1};
    new_dat = [];
    for j = 1:numel(mutual_times)
      [new_dat(j, :), bint] = psth_func( data, mutual_times(j), look_back, look_amt, bin_size );
    end
    pairs = current.field_label_pairs();
    new_spikes = new_spikes.append( Container(new_dat, pairs{:}) );
  end
end

%%

new_spikes = add_unit_id( new_spikes );
new_spikes = new_spikes.require_fields( 'norm_method' );

norm = new_spikes;
norm_dat = norm.data;
for i = 1:size(norm_dat, 1)
  norm_dat(i, :) = norm_dat(i, :) ./ max(norm_dat(i, :));
end
norm.data = norm_dat;

norm = norm.each1d( 'unit_id', @rowops.nanmean );

norm2 = new_spikes;
norm2 = norm2.each1d( 'unit_id', @rowops.nanmean );
for i = 1:size(norm2.data, 1)
  norm2.data(i, :) = norm2.data(i, :) ./ max(norm2.data(i, :));
end

new_spikes( 'norm_method' ) = 'norm_method__none';
norm( 'norm_method' ) = 'norm_method__per_trial_per_unit';
norm2( 'norm_method' ) = 'norm_method__per_unit';

combined = extend( new_spikes, norm, norm2 );

save( fullfile(full_save_p, 'spikes.mat'), 'combined' );

end

%%

% pl = ContainerPlotter();
% pl.add_ribbon = true;
% pl.vertical_lines_at = 0;
% pl.x = bint;
% figure(1); clf();
% % plt = norm2({'pair_id__1'});
% plt = new_spikes({'ACC'});
% % plt = plt.collapse( 'unit_id' );
% plt.plot( pl, [], {'unit_id', 'region'} );








