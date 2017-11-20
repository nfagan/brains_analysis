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

ITERATION_ID = 'B';
io = h5_api();
h5_file = fullfile( save_p, 'gaze_aligned_spikes.h5' );
io.require_file( h5_file );
io.h5_file = h5_file;
spike_grp_name = io.fullfile( '/Spikes', ITERATION_ID );
meta_grp_name = io.fullfile( '/Meta', ITERATION_ID );
io.require_group( spike_grp_name );
io.require_group( meta_grp_name );

props = struct();
props.look_back = -1;
props.look_amt = 2;
props.bin_size = .05;

%
%   get globals
%

plex_starts = add_pair_id( get_plex_starts() );

gaze_times = load( fullfile(load_p, 'gaze_times.mat') );
gaze_times = gaze_times.(char(fieldnames(gaze_times)));

meas = get_meas_xls();

res = meas_xls2mat( meas );
res = meas_mat2container( res );

I = plex_starts.get_indices( {'date', 'session'} );

for idx = 1:numel(I)

starts = plex_starts(I{idx});

%
%   get neural data
%

subset = res(['spike', starts.flat_uniques({'date', 'session'})]);
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

new_spikes = Container();

look_back = props.look_back;
look_amt = props.look_amt;
bin_size = props.bin_size;

psth_func = @brains_analysis.process.get_basic_psth;

for i = 1:size(C, 1)
  fprintf( '\n Processing %s (%d of %d)', strjoin(C(i, :), ', '), i, size(C, 1) );
  
  pair_id = C(i, strcmp(cmbs_within, 'pair_id'));
  
  matching_spikes = aligned(pair_id);
  matching_spikes = matching_spikes({'spike'});
  subset_times = matching_gaze_times(C(i, :));
  edf_times = subset_times.data;
  
  for k = 1:numel(cmbs_within)
    field = cmbs_within{k};
    matching_spikes = matching_spikes.require_fields( field );
    matching_spikes( field ) = C(i, strcmp(cmbs_within, field));
  end
  
  missing_fields = setdiff( subset_times.categories(), matching_spikes.categories() );
  
  for k = 1:numel(missing_fields)
    matching_spikes = matching_spikes.require_fields( missing_fields{k} );
  end
  
  psth_spikes = matching_spikes;
  psth_spikes.data = cellfun( @(x) x(x>=0), psth_spikes.data, 'un', false );

  for k = 1:numel(psth_spikes.data)
    current = psth_spikes(k);
    data = current.data{1};
    new_dat = [];
    new_labs = SparseLabels();
    for j = 1:numel(edf_times)
      [new_dat(j, :), bint] = psth_func( data, edf_times(j), look_back, look_amt, bin_size );
      labs = current.labels;
      for h = 1:numel(missing_fields)
        labs = labs.set_field( missing_fields{h}, subset_times(missing_fields{h}, j) );
      end
      new_labs = new_labs.append( labs );
    end
    new_spikes = new_spikes.append( Container(new_dat, new_labs) );
  end
end

props.bint = bint;

io.write( props, meta_grp_name );

combined = new_spikes;

fprintf( '\n Saving ... ' );
io.add( combined, spike_grp_name );
fprintf( 'Done.' );

end




