function [core2full, full2core, f2c_num, core2core] = mapCore2Full(info_core, info_full, px2d_core, cc_full, sz_t)
% map out relationships between the "core" and "full" objects
core2full = zeros(length(info_core), sz_t);
full2core = zeros(length(info_full), 30);  % maximum 30 "core" objects in each "full" object
f2c_num = zeros(length(info_full), 1);  % counter for full2core
L4d = labelmatrix(cc_full);
for n_core = 1:length(info_core)
    n_z = info_core(n_core).slice;
    for n_t = 1:sz_t
        % map "core objects" to "full objects"
        L = L4d(:,:,n_z,n_t);
        n_full = L(px2d_core{n_core}(1));  % just one pixel should be enough
        core2full(n_core, n_t) = n_full;
        
        % map "full objects" to "core objects"
        f2c_num(n_full) = f2c_num(n_full) + 1;
        full2core(n_full, f2c_num(n_full)) = n_core;
    end
end

% trim full2core size
max_objs = max( sum(full2core ~= 0, 2) );
full2core = full2core(:, 1:max_objs);

% map out which "core" objects connect or "leak" to each other
core2core = cell(length(info_core), sz_t);
idx_conn = find(f2c_num > 1);  % find "full" objects with >1 "core" counterparts
for n_full = idx_conn(:)'
    n_t = info_full(n_full).phase;
    idx = full2core(n_full, :);  idx = idx(idx > 0);  % get list of connected "core" objects
    for n_core = idx(:)'
        core2core{n_core, n_t} = idx(idx ~= n_core);  % add to list (omit parent object)
    end
end