import brains_analysis.process.add_pair_id;
import brains_analysis.io.get_neural_data;
import brains_analysis.io.get_plex_starts;
import brains_analysis.io.get_gaze_times;
import brains_analysis.io.get_meas_xls;
import brains_analysis.process.add_unit_id;
import brains_analysis.process.align_plex_by_pair_id;
import brains_analysis.process.meas_xls2mat;
import brains_analysis.process.meas_mat2container;
import shared_utils.io.dirnames;
import shared_utils.io.require_dir;

conf = brains_analysis.config.load();
root_p = conf.PATHS.data.root;
load_p = fullfile( root_p, 'free_viewing', 'processed', 'edf' );
save_p = fullfile( root_p, 'free_viewing', 'processed', 'plex' );
require_dir( save_p );

is_wideband = true;

ITERATION_ID = 'A';
io = h5_api();
if ( is_wideband )
  h5_file = fullfile( save_p, 'gaze_aligned_wb.h5' );
  chan_spec = 'WB';
else
  h5_file = fullfile( save_p, 'gaze_aligned_lfp.h5' );
  chan_spec = 'FP';
end
io.require_file( h5_file );
io.h5_file = h5_file;
lfp_grp_name = io.fullfile( '/Signals', ITERATION_ID );
meta_grp_name = io.fullfile( '/Meta', ITERATION_ID );
io.require_group( lfp_grp_name );
io.require_group( meta_grp_name );

props = struct();
props.window_size = 150;
props.step_size = 50;
props.start = -500;
props.stop = 500;
props.adjusted_stop = props.stop + props.window_size;

%
%   get globals
%

plex_starts = add_pair_id( get_plex_starts() );

gaze_times = load( fullfile(load_p, 'gaze_times.mat') );
gaze_times = gaze_times.(char(fieldnames(gaze_times)));

meas = get_meas_xls();

res = meas_xls2mat( meas, 'WB' );
res = meas_mat2container( res );

[I, sesh_combs] = plex_starts.get_indices( {'date', 'session'} );

for idx = 1:numel(I)

fprintf( '\n\n\nProcessing %s (%d of %d)', strjoin(sesh_combs(idx, :), ', '), idx, numel(I) );

starts = plex_starts(I{idx});

%
%   get neural data
%

subset = res(['lfp', starts.flat_uniques({'date', 'session'})]);
neural_data = get_neural_data( conf, subset );
aligned = align_plex_by_pair_id( neural_data, starts );

%
%   get matching gaze times
%

matching_gaze_times = gaze_times(starts.flat_uniques({'date', 'session'}));
cmbs_within = { 'pair_id', 'roi', 'gaze_type', 'monkey' };
C = matching_gaze_times.pcombs( cmbs_within );

id_ns = cellfun( @(x) str2double(x(numel('pair_id__')+1:end)) ...
  , C(:, strcmp(cmbs_within, 'pair_id')) );
[~, index] = sort( id_ns );
C = C(index, :);

new_lfp = Container();

psth_func = @brains_analysis.process.get_lfp_mat;

for i = 1:size(C, 1)
  fprintf( '\n Processing %s (%d of %d)', strjoin(C(i, :), ', '), i, size(C, 1) );
  
  pair_id = C(i, strcmp(cmbs_within, 'pair_id'));
  
  matching_lfp = aligned(pair_id);
  matching_lfp = matching_lfp({'lfp'});
  assert( ~isempty(matching_lfp), 'No lfp data matched.' );
  subset_times = matching_gaze_times(C(i, :));
  edf_times = subset_times.data;
  
  for k = 1:numel(cmbs_within)
    field = cmbs_within{k};
    matching_lfp = matching_lfp.require_fields( field );
    matching_lfp( field ) = C(i, strcmp(cmbs_within, field));
  end
  
  psth_lfp = matching_lfp;

  for k = 1:numel(psth_lfp.data)
    current = psth_lfp(k);
    data = current.data{1};
    lfp = data.Values;
    id_times = data.time;
    fs = data.ADFreq;
    all_signals = psth_func( lfp, id_times, edf_times ...
      , [props.start, props.adjusted_stop] ...
      , props.window_size, fs );
    pairs = current.field_label_pairs();
    cont = Container( all_signals, pairs{:} );
    cont = SignalContainer( cont );
    cont.fs = fs;
    cont.window_size = props.window_size;
    cont.step_size = props.step_size;
    cont.start = props.start;
    cont.stop = props.stop;
    props.fs = fs;
    new_lfp = new_lfp.append( cont );
  end
end

io.write( props, meta_grp_name );

combined = new_lfp;

fprintf( '\n Saving ... ' );
io.add( combined, lfp_grp_name );
fprintf( 'Done.' );

end




