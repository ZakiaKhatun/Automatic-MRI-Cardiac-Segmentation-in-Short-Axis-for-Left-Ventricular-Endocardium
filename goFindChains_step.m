function [idx_search, L3d_search, arr_chain] = goFindChains_step(idx_search, L3d_search, arr_chain, idx_ref, slices, info_obj, px2d_obj, obj_filt, res_xy)
[sz_y, sz_x, ~] = size(L3d_search);
sl_ref = info_obj(idx_ref).slice;
px_ref = px2d_obj{idx_ref};
area_ref = info_obj(idx_ref).area;
area_all = vertcat( info_obj.area );
cxy_ref = info_obj(idx_ref).Cxy;
cxy_all = vertcat( info_obj.Cxy );
binrange = 1:length(info_obj);  % for object-matching histogram

% update list of unassigned objects
idx_search(idx_search == idx_ref) = [];
z_offset = sz_y*sz_x * (sl_ref - 1);
L3d_search(px2d_obj{idx_ref} + z_offset) = 0;

for n_z = slices
    z_offset = sz_y*sz_x * (n_z - 1);
    X = L3d_search(px_ref + z_offset);  % get overlapping pixels
    X = X(X > 0);  % remove zero-valued pixels (no object label)
    if isempty(X);  break;  end  % no overlapping objects, stop search
    
    F = histc(X, binrange);  % get list/labels of overlapping objects
    area_min = min(area_all, area_ref);  % get minimum areas of reference & comparison objects
    F = F(:) ./ area_min;  % normalized area of overlap (force vertical vector or will get error when X is length 1)
    cxy_diff = sqrt( (cxy_all(:,1) - cxy_ref(1)).^2 + (cxy_all(:,2) - cxy_ref(2)).^2 );  % difference in centrepoints
    arr = true(length(F), 1);
    arr = arr  &  F >= 0.6;  % minimum 60% intersection
    arr = arr  &  cxy_diff <= (15 / res_xy);  % maximum 15mm centrepoint difference
    arr = arr  &  ~obj_filt;  % ... and they must not have been filtered out due to other criteria
    if isempty(arr);  break;  end  % no matching objects, stop search
    
    % update list of assigned and unassigned objects
    % allow for multiple objects per slice (WARNING: may be buggy)
    arr_chain(arr) = true;
    px_ref = vertcat( px2d_obj{arr} );
    area_ref = sum([ info_obj(arr).area ]);
    cxy_ref = mean(vertcat( info_obj(arr).Cxy ), 1);
    L3d_search(px_ref + z_offset) = 0;
    for n_obj = find(arr)'
        idx_search(idx_search == n_obj) = [];
    end
end