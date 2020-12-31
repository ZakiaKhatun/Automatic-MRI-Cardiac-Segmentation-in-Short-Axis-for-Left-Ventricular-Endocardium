function chains = goFindChains(scores, info_obj, px2d_obj, cc_obj, obj_filt, res_xy)
sz_z = cc_obj.ImageSize(end);

% create list of unassigned objects, and sort by score, descending
idx_search = 1:length(info_obj);
[~, I] = sort(scores, 'descend');
idx_search = idx_search(I);
L3d_search = labelmatrix(cc_obj);  % labelmatrix for matching objects

% start chaining through all objects, updating the list of unassigned
% objects as we go along
chains = cell(length(info_obj), 1);
n_chn = 1;
% continue until unassigned list is empty, or until none of the remaining
% objects have a score > 0 (i.e., don't search based on score 0 objects)
while ~isempty(idx_search)  &&  any(scores(idx_search) > 0)
    % start new chain search on (latest) highest scoring object
    idx_ref = idx_search(1);
    sl_ref = info_obj(idx_ref).slice;
    arr_chain = false(length(info_obj), 1);  % to keep track of current chain
    arr_chain(idx_ref) = true;
    
    % search up and down the slices
    slices = sl_ref+1 : +1 : sz_z;
    [idx_search, L3d_search, arr_chain] = goFindChains_step(idx_search, L3d_search, arr_chain, idx_ref, slices, info_obj, px2d_obj, obj_filt, res_xy);
    slices = sl_ref-1 : -1 : 1;
    [idx_search, L3d_search, arr_chain] = goFindChains_step(idx_search, L3d_search, arr_chain, idx_ref, slices, info_obj, px2d_obj, obj_filt, res_xy);
    chains(n_chn) = { find(arr_chain) };
    n_chn = n_chn + 1;
end
chains(n_chn:end) = [];