function [cc_core_merged, cc_full_merged] = goMergeObjs(cc_core, cc_full, info_core, conn_grp, core2full)
% merge a subset of connected core objects together (targetting single
% objects which "break off" small chunks due to noise)
sz_t = cc_full.ImageSize(4);
cc_core_merged = cc_core;
cc_full_merged = cc_full;
for n_grp = 1:length(conn_grp)
    idx_core = conn_grp{n_grp};
    areas = [ info_core(idx_core).area ];
    [areas, idx] = sort(areas, 'descend');  % sort by largest area
    idx_core = idx_core(idx);
    
    arr = areas > areas(1) * 0.1;  % "significant" objects defined as >10% area
    idx_core_big = idx_core(arr);  idx_core_sm = idx_core(~arr);
    if length(idx_core_big) == 1  % only one primary object, merge all others
        idx_merge = { idx_core };
    else
        idx_merge = num2cell( idx_core_big(:) );
        if ~isempty(idx_core_sm)  % merge all "insignificant" objects to closest "significant" objects
            dist_table = zeros(length(idx_core_big), length(idx_core_sm));
            Cxy_sm = vertcat( info_core(idx_core_sm).Cxy );
            for n = 1:length(idx_core_big)
                Cxy = info_core(idx_core_big(n)).Cxy;
                dist_table(n, :) = sqrt( (Cxy_sm(:,1) - Cxy(1)).^2 + (Cxy_sm(:,2) - Cxy(2)).^2 );
            end
            [~, idx_sm2bg] = min(dist_table, [], 1);  % get closest "significant" object
            for n = 1:length(idx_core_sm)  % update merge table
                idx_merge{idx_sm2bg(n)} = [ idx_merge{idx_sm2bg(n)}  idx_core_sm(n) ];
            end
        end
    end
    
    % apply (partial) merge to "core" and "full" objects
    % NOTE: an earlier version tried to handle the complete "full" object
    % merge-and-split here as well, but there're too many complications
    for n = 1:length(idx_merge)
        idx = idx_merge{n};  % 1st index is primary "significant" object
        if length(idx) <= 1;  continue;  end
        
        px = vertcat(  cc_core_merged.PixelIdxList{idx} );
        cc_core_merged.PixelIdxList{idx(1)} = px;
        cc_core_merged.PixelIdxList(idx(2:end)) = {[]};
        
        idx_full = core2full(idx, :);  % get list of affected "full" objects
        for n_t = 1:sz_t  % merge "full" objects in the same phase
            idx = unique(idx_full(1, n_t), 'stable');
            if all(idx(1) == idx(2:end));  continue;  end
            cc_full_merged.PixelIdxList{idx(1)} = vertcat( cc_full_merged.PixelIdxList{idx} );
            cc_full_merged.PixelIdxList(idx(2:end)) = {[]};
        end
    end
end
arr = cellfun(@isempty, cc_core_merged.PixelIdxList);
cc_core_merged.PixelIdxList(arr) = [];
cc_core_merged.NumObjects = sum(~arr);
arr = cellfun(@isempty, cc_full_merged.PixelIdxList);
cc_full_merged.PixelIdxList(arr) = [];
cc_full_merged.NumObjects = sum(~arr);