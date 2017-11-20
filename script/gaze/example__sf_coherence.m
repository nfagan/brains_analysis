import brains_analysis.io.get_fv_h5;
import brains_analysis.process.add_site_id;

conf = brains_analysis.config.load();

load_p = fullfile( conf.PATHS.data.root, 'free_viewing', 'processed', 'plex', 'spike_times' );
save_p = fullfile( conf.PATHS.data.root, 'free_viewing', 'processed', 'plex', 'sf_coherence' );

shared_utils.io.require_dir( save_p );

lfp_io = get_fv_h5( conf, fullfile('plex', 'gaze_aligned_lfp.h5') );
lfp_id = 'A';

meta_lfp = lfp_io.read( lfp_io.fullfile('Meta', lfp_id) );

spike_files = shared_utils.io.dirnames( load_p, '.mat', false );
spike_seshs = cellfun( @(x) x(1:end-4), spike_files, 'un', false );
dates = cellfun( @(x) x(1:6), spike_seshs, 'un', false );
seshs = cellfun( @(x) x(8:end), spike_seshs, 'un', false );

required_matching_cats = { 'gaze_type', 'monkey', 'roi', 'pair_id' };

for i = 1:numel(dates)
  fprintf( '\n\nProcessing date %d of %d', i, numel(dates) );
  all_lfp = lfp_io.read( lfp_io.fullfile('Signals', lfp_id), 'only', {dates{i}, seshs{i}} );

  all_lfp = SignalContainer( all_lfp.data, all_lfp.labels );
  all_lfp.fs = meta_lfp.fs;
  all_lfp.start = meta_lfp.start;
  all_lfp.stop = meta_lfp.stop;
  all_lfp.step_size = meta_lfp.step_size;
  all_lfp.window_size = meta_lfp.window_size;

  spikes = shared_utils.io.fload( fullfile(load_p, spike_files{i}) );

  [spike, all_lfp] = add_site_id( spikes, all_lfp );

  spk = spike({'unit__1'});
  lfp = all_lfp;

  shared_ids = intersect( spk('site_id'), lfp('site_id') );
  lfp = lfp(shared_ids);
  spk = spk(shared_ids);
  lfp = lfp.rm( lfp.make_collapsed_expression('site_id') );
  spk = spk.rm( spk.make_collapsed_expression('site_id') );
  
  assert( shape(spk, 1) == shape(lfp, 1), 'Shapes must match.' );
  
  regions = { 'ACC', 'BLA' };
  
  for j = 1:2
    fprintf( '\n Processing combination %d of %d', j, 2 );
    lfp_one_reg = lfp(regions(1));
    spk_one_reg = spk(regions(2));
    
    if ( isempty(lfp_one_reg) || isempty(spk_one_reg) ), continue; end
    
    matching_pairs = intersect( lfp_one_reg('pair_id'), spk_one_reg('pair_id') );
    
    if ( isempty(matching_pairs) ), continue; end
    
    lfp_one_reg = lfp_one_reg(matching_pairs);
    spk_one_reg = spk_one_reg(matching_pairs);
    
    cmbs = allcomb( {lfp_one_reg('site_id'), spk_one_reg('site_id')} );
    
    for h = 1:size(cmbs, 1)
      fprintf( '\n Processing channel combination %d of %d', h, size(cmbs, 1) );
      lfp_one_site = lfp_one_reg(cmbs(h, 1));
      spk_one_site = spk_one_reg(cmbs(h, 2));
      
      assert( shape(lfp_one_site, 1) == shape(spk_one_site, 1), 'Shapes must match.' );
      
      for hh = 1:numel(required_matching_cats)
        cat_ = required_matching_cats{hh};
        assert( isequal(lfp_one_site(cat_, :), spk_one_site(cat_, :)), 'Trial sets must match.' );
      end
      
      lfp_one_site_data = lfp_one_site.windowed_data();
      %   samples x trials
      lfp_one_site_data = cellfun( @(x) x', lfp_one_site_data, 'un', false );
      
      assert( shape(spk_one_site, 2) == numel(lfp_one_site_data), 'Number of data elements must match.' );
      
      time_series = zeros( [size(lfp_one_site_data{1}, 2), 129, numel(lfp_one_site_data)] );
      %   for each time window ...
      for hh = 1:numel(lfp_one_site_data)
        lfp_one_window_data = lfp_one_site_data{hh};
        spk_one_column_data = spk_one_site.data(:, hh);
        spk_one_column_struct_data = struct( char(fieldnames(spk_one_column_data{1})), [] );
        for hhh = 1:numel(spk_one_column_data)
          spk_one_column_struct_data(hhh) = spk_one_column_data{hhh};
        end
        
        chronux_params = struct( 'Fs', 1e3, 'tapers', [3 5] );
        
        [C,~,~,~,~,f] = coherencycpt( lfp_one_window_data, spk_one_column_struct_data, chronux_params );
        
        time_series(:, :, hh) = C';
      end
      
      current = set_data( spk_one_site, time_series );
      current = current.require_fields( {'lfp_region', 'spk_region'} );
      current( 'lfp_region' ) = sprintf( 'lfp_region__%s', regions{1} );
      current( 'spk_region' ) = sprintf( 'spk_region__%s', regions{2} );
      current( 'channel_type' ) = 'lfp_spike';
      current( 'channel' ) = strjoin( [lfp_one_site('channel'), spk_one_site('channel')], '_' );
      current( 'region' ) = strjoin( regions, '_' );
      
      row = strjoin( cmbs(h, :), '_' );
      regs = strjoin( regions, '_' );
      sesh = strjoin( {dates{i}, seshs{i}}, '_' );
      fname = sprintf( '%s_%s_%s.mat', row, regs, sesh );
      
      save( fullfile(save_p, fname), 'current' );
    end
    
    regions = fliplr( regions );
  end
end


