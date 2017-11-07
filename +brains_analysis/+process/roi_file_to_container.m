function cont = roi_file_to_container(rois)

%   ROI_FILE_TO_CONTAINER -- Convert the roi struct to a Container object.
%
%     IN:
%       - `rois` (struct)
%     OUT:
%       - `cont` (Container)

import shared_utils.assertions.*;

assert__isa( rois, 'struct' );

monks = fieldnames( rois );

assert( ~isempty(monks), 'The roi struct was empty.' );
assert__isa( rois.(monks{1}), 'struct' );

cont = Container();

for i = 1:numel(monks)
  monk = monks{i};
  current = rois.(monk);
  per_monk_rois = fieldnames( current );
  for k = 1:numel(per_monk_rois)
    roi_lab = per_monk_rois{k};
    
    roi_data = current.(roi_lab);
    roi_data = roi_data(:)';
    
    C = Container( roi_data, 'monkey', monk, 'roi', roi_lab );
    
    cont = append( cont, C );
  end
end

end