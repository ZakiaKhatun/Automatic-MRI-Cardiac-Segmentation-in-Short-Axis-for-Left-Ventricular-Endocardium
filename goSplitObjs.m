function cc_full_split = goSplitObjs(cc_full, px2d_full, info_core, px2d_core, conn_grp, core2full)
% split "full" objects in the remaining cases where there are still core
% connections
sz_x = cc_full.ImageSize(2);  sz_y = cc_full.ImageSize(1);  sz_t = cc_full.ImageSize(4);
cc_full_split = cc_full;
[xx, yy] = meshgrid(1:sz_x, 1:sz_y);
for n_grp = 1:length(conn_grp)
    idx_core = conn_grp{n_grp};
    idx_full = core2full(idx_core, :);
    for n_t = 1:sz_t
        idx_phase = idx_full(:, n_t);
        for idx_f = unique(idx_phase)'
            arr = idx_f == idx_phase;
            idx_c = idx_core(arr);
            if length(idx_c) <= 1;  continue;  end  % no "shared / connecting" cores
            
            % split "full" object by calculating per-pixel distance to
            % "core" object centroids, and also 
            px2d = px2d_full{idx_f};
            dist_table = zeros(length(px2d), length(idx_c));
            for n = 1:length(idx_c)
                Cxy = info_core(idx_c(n)).Cxy;
                dist_table(:,n) = sqrt( (xx(px2d) - Cxy(1)).^2 + (yy(px2d) - Cxy(2)).^2 );
                arr = ismember(px2d, px2d_core{idx_c(n)});
                dist_table(arr,n) = -1;  % make sure "full" pixels which coincide with the "core" object are set to minimum
            end
            [~, dist_table] = min(dist_table, [], 2);
            n_full_num = cc_full_split.NumObjects;
            n_full_new = length(idx_c);
            for n = 1:n_full_new
                cc_full_split.PixelIdxList{n_full_num + n} = cc_full_split.PixelIdxList{idx_f}(dist_table == n);
            end
            cc_full_split.PixelIdxList(idx_f) = {[]};
            cc_full_split.NumObjects = n_full_num + n_full_new;
        end
    end
end
arr = cellfun(@isempty, cc_full_split.PixelIdxList);
cc_full_split.PixelIdxList(arr) = [];
cc_full_split.NumObjects = sum(~arr);