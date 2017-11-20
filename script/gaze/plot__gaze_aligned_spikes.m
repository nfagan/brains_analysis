import brains_analysis.io.get_fv_h5;
import brains_analysis.process.add_unit_id;
import brains_analysis.process.add_tile_id;
import shared_utils.io.require_dir;

conf = brains_analysis.config.load();
root_p = conf.PATHS.data.root;
save_p = fullfile( root_p, 'free_viewing', 'plots' );

ITERATION_ID = 'B';
io = get_fv_h5( conf, fullfile('plex', 'gaze_aligned_spikes.h5') );

spikes = add_unit_id( io.read(io.fullfile('Spikes', ITERATION_ID)) );
meta = io.read( io.fullfile('Meta', ITERATION_ID) );

if ( strcmp(ITERATION_ID, 'A') )
  spikes = spikes({'norm_method__none'});
end
spikes = spikes.require_fields( 'tile_id' );

formats = { 'epsc', 'png', 'fig' };
format_names = { 'eps', 'png', 'fig' };

%%  AVERAGE NON-MUTUAL GAZE FREQUENCIES

do_save = false;
base_fname = 'mutual';
gaze_type = sprintf( 'gaze_type__%s', base_fname );

sub_dir = fullfile( 'gaze_frequencies', 'per_session' );

count_within = { 'session', 'date', 'monkey', 'roi', 'gaze_type' };
counts_exclusive = set_data( spikes, ones(shape(spikes, 1), 1) );
counts_exclusive = counts_exclusive.for_each( count_within, @(x) set_data(one(x), sum(x.where(gaze_type))) );

counts_exclusive = counts_exclusive({gaze_type});

figs_are = { 'session', 'date' };
[fig_i, fig_c] = counts_exclusive.get_indices( figs_are );

for i = 1:numel(fig_i)

  subset = counts_exclusive(fig_i{i});
  
  figure(1); clf(); colormap('default');
  subset.bar( 'monkey', 'roi', 'gaze_type');

  if ( do_save )
    fname = sprintf( '%s_%s', base_fname, strjoin(fig_c(i, :), '_') );
    for j = 1:numel(formats)
      full_p = fullfile( save_p, sub_dir, format_names{j} );
      require_dir( full_p );
      saveas( gcf, sprintf('%s.%s', fullfile(full_p, fname), format_names{j}), formats{j} );
    end
  end
end

%%  NORMALIZE TO EACH TRIAL'S MAX

norm1 = get_data( spikes );

for i = 1:size(norm1, 1)
  curr = norm1(i, :);
  norm1(i, :) = curr ./ max(curr);
end
norm1 = set_data( spikes, norm1 );

meaned = spikes.each1d( 'unit_id', @rowops.nanmean );
meaned_data = meaned.data;
spk_unit_ids = spikes( 'unit_id', : );
meaned_unit_ids = meaned( 'unit_id', : );
norm2 = get_data( spikes );
for i = 1:size(norm2, 1)
  unit_id_ind = strcmp( meaned_unit_ids, spk_unit_ids{i} );
  assert( sum(unit_id_ind) == 1 );
  norm2(i, :) = norm2(i, :) ./ max(meaned_data(unit_id_ind, :));
end
norm2 = set_data( spikes, norm2 );

norm_within = { 'unit_id', 'gaze_type', 'roi' };
meaned = spikes.each1d( norm_within, @rowops.nanmean );
meaned_data = meaned.data;
spk_unit_ids = spikes.full_fields( norm_within );
meaned_unit_ids = meaned.full_fields( norm_within );
norm3 = get_data( spikes );
for i = 1:size(norm3, 1)
  unit_id_ind = true( shape(meaned, 1), 1 );
  for j = 1:numel(norm_within)
    unit_id_ind = unit_id_ind & strcmp(meaned_unit_ids(:, j), spk_unit_ids{i, j});
  end
  assert( sum(unit_id_ind) == 1 );
  norm3(i, :) = norm3(i, :) ./ max(meaned_data(unit_id_ind, :));
end
norm3 = set_data( spikes, norm3 );

%%  ADD TILE ID

% habit = add_tile_id( spikes, 4 );
habit = add_tile_id( norm3, 4 );

%%  PLOT EACH UNIT AS SEPARATE PLOT

plt = norm3;
do_save = true;
collapse_units = true;
is_raw = false;
is_over_time = true;
shape = [ 2, 2 ];

unit_ids = [ 13, 18, 55, 79, 49, 59, 19, 28, 61, 80, 87, 5, 10, 44, 70, 71, 86 ];
unit_ids = arrayfun( @(x) sprintf('unit_id__%d', x), unit_ids, 'un', false );
if ( ~collapse_units )
  plt = plt(unit_ids);
end

figs_are = { 'unit_id', 'gaze_type', 'region', 'roi', 'monkey' };
panels_are = { 'region', 'gaze_type', 'monkey', 'roi', 'tile_id' };

if ( collapse_units )
  plt = plt.collapse( {'date', 'session'} );
  sub_dir_base = 'across_units';
else
  sub_dir_base = 'per_unit';
end
if ( is_raw )
  sub_dir = sprintf( '%s_raw', sub_dir_base );
else
  sub_dir = sprintf( '%s_normalized', sub_dir_base );
end
if ( is_over_time )
  sub_dir = sprintf( '%s_over_time', sub_dir );
end

mut = plt({'gaze_type__mutual'});
exc = plt({'gaze_type__exclusive'});
mut = mut.collapse( 'monkey' );

% exc = exc({'kuro'});
ind = exc.where( 'kuro' );
exc( 'monkey', ind ) = 'kuro_to_other';
exc( 'monkey', ~ind ) = 'other_to_kuro';

plt = append( mut, exc );
if ( collapse_units )
  plt = plt.collapse('unit_id');
end

plt = plt.replace( 'gaze_type__mutual', 'mutual' );
plt = plt.replace( 'gaze_type__exclusive', 'exclusive' );

pl = ContainerPlotter();
figure(1);
[fig_i, fig_c] = plt.get_indices( figs_are );


for i = 1:numel(fig_i)
  fprintf( '\n Saving %d of %d', i, numel(fig_i) );
  
  subset = plt(fig_i{i});
  
  clf();
  pl.default();
  pl.summary_function = @nanmean;
  pl.error_function = @ContainerPlotter.nansem;
  pl.add_ribbon = true;
  pl.shape = shape;
  pl.x = meta.bint;
  pl.vertical_lines_at = 0;
  
  subset.plot( pl, [], panels_are );
  
  if ( do_save )
    fname = strjoin( fig_c(i, :), '_' );    
    for j = 1:numel(formats)
      addtl = strjoin(subset.flat_uniques({'date', 'session'}), '_');
      full_p = fullfile( save_p, 'firing_rate', sub_dir, addtl, format_names{j} );
      require_dir( full_p );
      saveas( gcf, sprintf('%s.%s', fullfile(full_p, fname), format_names{j}), formats{j} );
    end
  end
end

%%

is_normalized = false;

if ( is_normalized )
  plt = norm3;
else
  plt = spikes;
end

mut = plt({'gaze_type__mutual'});
exc = plt({'gaze_type__exclusive'});

ind = exc.where( 'kuro' );
exc( 'monkey', ind ) = 'kuro_to_other';
exc( 'monkey', ~ind ) = 'other_to_kuro';

mut = mut.each1d( {'unit_id', 'roi'}, @rowops.nanmean );
exc = exc.each1d( {'unit_id', 'roi', 'monkey'}, @rowops.nanmean );

exc = exc({'kuro_to_other'});

existing_units_mutual = mut.pcombs( {'unit_id', 'roi'} );
existing_units_exc = exc.pcombs( {'unit_id', 'roi'} );

split_char = '____';

existing_units_mutual_ = cell( size(existing_units_mutual, 1), 1 );
for i = 1:size(existing_units_mutual, 1)
  existing_units_mutual_{i} = strjoin(existing_units_mutual(i, :), split_char);
end
existing_units_exc_ = cell( size(existing_units_exc, 1), 1 );
for i = 1:size(existing_units_exc, 1)
  existing_units_exc_{i} = strjoin(existing_units_exc(i, :), split_char);
end

shared = intersect( existing_units_mutual_, existing_units_exc_ );

rebuilt_existing = cell( numel(shared), 2 );
for i = 1:numel(shared)
  rebuilt_existing(i, :) = strsplit(shared{i}, split_char);
end

matched_mutual = Container();
for i = 1:size(rebuilt_existing, 1)
  matched_mutual = matched_mutual.append( mut(rebuilt_existing(i, :)) );
end

matched_exc = Container();
for i = 1:size(rebuilt_existing, 1)
  matched_exc = matched_exc.append( exc(rebuilt_existing(i, :)) );
end

%% mutual vs non mutual

cmbs = matched_mutual.pcombs( {'roi', 'region'} );

if ( is_normalized )
  base_p = fullfile( conf.PATHS.data.root, 'free_viewing', 'plots', 'firing_rate', 'scatter', 'mutual_v_non_mutual', 'normalized' );
  units = 'normalized';
else
  units = 'sps';
  base_p = fullfile( conf.PATHS.data.root, 'free_viewing', 'plots', 'firing_rate', 'scatter', 'mutual_v_non_mutual', 'raw' );
end

shared_utils.io.require_dir( base_p );

bint = meta.bint;

for i = 1:size(cmbs, 1)

matched_mutual_subset = matched_mutual(cmbs(i, :));
matched_exc_subset = matched_exc(cmbs(i, :));

assert( eq_ignoring(matched_mutual_subset.labels, matched_exc_subset.labels, {'monkey', 'gaze_type', 'pair_id'}) );

time_ind = bint > -.2 & bint < .2;

figure(1); clf();
scatter( nanmean(matched_mutual_subset.data(:, time_ind),2), nanmean(matched_exc_subset.data(:, time_ind), 2));
hold on;

x_lims = get( gca, 'xlim');
y_lims = get( gca, 'ylim' );

maxs = max( x_lims(2), y_lims(2) );
mins = min( x_lims(1), y_lims(1) );
set( gca, 'xlim', [mins, maxs] );
set( gca, 'ylim', [mins, maxs] );

plot( mins:.1:maxs, mins:.1:maxs, 'k' );

title( strjoin(matched_mutual_subset('region'), '_') );

ylabel( sprintf('Non-mutual gaze to %s (%s)', cmbs{i, 1}, units) );
xlabel( sprintf('Mutual gaze to %s (%s)', cmbs{i, 1}, units) );

saveas( gcf, fullfile(base_p, [strjoin(cmbs(i, :), '_'), '.eps']), 'epsc' );
saveas( gcf, fullfile(base_p, [strjoin(cmbs(i, :), '_'), '.png']), 'png' );
saveas( gcf, fullfile(base_p, [strjoin(cmbs(i, :), '_'), '.fig']), 'fig' );

end



%%

is_normalized = false;

if ( is_normalized )
  plt = norm3;
  units = 'normalized firing rate';
else
  plt = spikes;
  units = 'sps'; 
end

mut = plt({'gaze_type__mutual'});
mut = mut.each1d( {'unit_id', 'roi'}, @rowops.nanmean );

face_mut = mut({'face'});
eyes_mut = mut({'eyes'});

shared_ids = intersect( face_mut('unit_id'), eyes_mut('unit_id') );
face_mut = face_mut(shared_ids);
eyes_mut = eyes_mut(shared_ids);

if ( is_normalized )
  base_p = fullfile( conf.PATHS.data.root, 'free_viewing', 'plots', 'firing_rate', 'scatter', 'mutual_eyes_v_mutual_face', 'normalized' );
else
  base_p = fullfile( conf.PATHS.data.root, 'free_viewing', 'plots', 'firing_rate', 'scatter', 'mutual_eyes_v_mutual_face', 'raw' );
end
shared_utils.io.require_dir( base_p );

cmbs = face_mut( 'region' );

bint = meta.bint;

for i = 1:size(cmbs, 1)

matched_mutual_subset = eyes_mut(cmbs(i, :));
matched_exc_subset = face_mut(cmbs(i, :));

assert( eq_ignoring(matched_mutual_subset.labels, matched_exc_subset.labels, {'monkey', 'gaze_type', 'pair_id', 'roi'}) );

time_ind = bint > -.2 & bint < .2;

figure(1); clf();
scatter( nanmean(matched_mutual_subset.data(:, time_ind),2), nanmean(matched_exc_subset.data(:, time_ind), 2));
hold on;

x_lims = get( gca, 'xlim');
y_lims = get( gca, 'ylim' );

maxs = max( x_lims(2), y_lims(2) );
mins = min( x_lims(1), y_lims(1) );
set( gca, 'xlim', [mins, maxs] );
set( gca, 'ylim', [mins, maxs] );

plot( mins:.1:maxs, mins:.1:maxs, 'k' );

title( strjoin(matched_mutual_subset('region'), '_') );

ylabel( sprintf('Mutual gaze to %s (%s)', char(matched_exc_subset('roi')), units) );
xlabel( sprintf('Mutual gaze to %s (%s)', char(matched_mutual_subset('roi')), units) );

saveas( gcf, fullfile(base_p, [strjoin(cmbs(i, :), '_'), '.eps']), 'epsc' );
saveas( gcf, fullfile(base_p, [strjoin(cmbs(i, :), '_'), '.png']), 'png' );
saveas( gcf, fullfile(base_p, [strjoin(cmbs(i, :), '_'), '.fig']), 'fig' );

end

%%

subset = spikes;
subset.data = nanmean( subset.data, 2 );

cmbs = subset.pcombs( 'roi' );

stats = Container();

for i = 1:size(cmbs, 1)

  mut = subset([cmbs(i, :), 'gaze_type__mutual']);
  exc = subset([cmbs(i, :), 'gaze_type__exclusive']);
  exc = exc({'kuro'});
  shared_units = intersect( mut('unit_id'), exc('unit_id') );

  exc = exc(shared_units);
  mut = mut(shared_units);
  
  for k = 1:numel(shared_units)
    mut_activity = mut(shared_units(k));
    exc_activity = exc(shared_units(k));
    
%     [~, p, ci, stats] = ttest2( mut_activity.data, exc_activity.data );
    mean_mut = nanmean( mut_activity.data );
    mean_exc = nanmean( exc_activity.data );
    
    if ( isnan(mean_mut) || isnan(mean_exc) ), continue; end
    
    p = ranksum( mut_activity.data, exc_activity.data, 'tail', 'left' );
    
    clpsed = set_data( one(mut_activity), [mean_mut, mean_exc, p] );
    stats = stats.append( clpsed );
  end
end

perc_sig = stats.each1d( {'roi', 'region'}, @(x) perc(x(:, 3) < (.05/2)) );
disp( table(perc_sig) );












  