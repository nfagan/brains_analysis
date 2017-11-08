function cont = meas_mat2container(meas)

import shared_utils.assertions.*;

assert__isa( meas, 'struct' );
all_fields = fieldnames( meas );
unit_field = 'unit';
assert__are_fields( meas, unit_field );

lab_fields = setdiff( all_fields, unit_field );
lab_struct = struct();

for i = 1:numel(lab_fields)
  field_name = lab_fields{i};
  current = meas.(field_name);  
  assert__is_cellstr( current );
  assert__is_vector( current );
  lab_struct.(field_name) = current(:);
end

dat = meas.(unit_field);

assert__is_vector( dat );

cont = Container( dat(:), SparseLabels(lab_struct) );
  
end