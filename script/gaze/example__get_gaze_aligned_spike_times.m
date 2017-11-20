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
save_p = fullfile( root_p, 'free_viewing', 'processed', 'plex', 'spike_times' );
require_dir( save_p );

%
%   get globals
%

plex_starts = add_pair_id( get_plex_starts() );

gaze_times = load( fullfile(load_p, 'gaze_times.mat') );
gaze_times = gaze_times.(char(fieldnames(gaze_times)));

meas = get_meas_xls();

res = meas_xls2mat( meas );
res = meas_mat2container( res );

[I, sesh_combs] = plex_starts.get_indices( {'date', 'session'} );

% for idx = 1:numel(I)
for idx = numel(I)

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

all_binned = Container();

for i = 1:size(C, 1)
  fprintf( '\n Processing %s (%d of %d)', strjoin(C(i, :), ', '), i, size(C, 1) );
  
  pair_id = C(i, strcmp(cmbs_within, 'pair_id'));
  
  matching_spikes = aligned(pair_id);
  matching_spikes = matching_spikes({'spike'});
  subset_times = matching_gaze_times(C(i, :));
  
  for k = 1:numel(cmbs_within)
    field = cmbs_within{k};
    matching_spikes = matching_spikes.require_fields( field );
    matching_spikes( field ) = C(i, strcmp(cmbs_within, field));
  end
  
  psth_spikes = matching_spikes;
  psth_spikes.data = cellfun( @(x) x(x>=0), psth_spikes.data, 'un', false );
  
  binned = brains_analysis.process.bin_spikes( psth_spikes, subset_times, -1, 1, .15, .05 );
  all_binned = all_binned.append( binned );
end

fname = sprintf( '%s.mat', strjoin(sesh_combs(idx, :), '_') );
save( fullfile(save_p, fname), 'all_binned' );

end




