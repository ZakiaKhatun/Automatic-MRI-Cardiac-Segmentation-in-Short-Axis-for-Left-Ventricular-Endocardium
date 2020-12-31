function [core_conn, idx_conn, conn_grp] = getCoreConnections(f2c_num, core2full, core2core, info_core)
% collect the connecting core objects into groups. A previous
% implementation failed to account for 2nd level connections and above:
% i.e., object 3 connects to 4, but 4 also connects to 3 and 6.
% this implementation uses a more exhaustive search which should solve that
core_conn = f2c_num(core2full);  % number of connections at each phase (size: n_cores x n_t)
idx_conn = find( any(core_conn > 1, 2) );  % find cores with phase leaks / extra connections at any phase
conn_grp = cell(length(idx_conn), 1);  % keep track of connected groups
for n_grp = 1:length(idx_conn)  % first collect all "connected" cores
    n_core = idx_conn(n_grp);
    conn_grp{n_grp} = [ n_core  unique([ core2core{n_core, :} ]) ];  % get list of "connected" cores at any phase
end
do_merge = true;
while do_merge  % repeat until no more valid merges found
    do_merge = false;
    slices = cellfun(@(x) info_core(x(1)).slice, conn_grp);  % get slice index of each group
    for n_grp_A = 1:length(conn_grp)-1
        n_z = slices(n_grp_A);
        for n_grp_B = n_grp_A+1:length(conn_grp)
            if n_z ~= slices(n_grp_B);  continue;  end  % if different slice, members can't be connected, so skip
            if any(ismember(conn_grp{n_grp_A}, conn_grp{n_grp_B}))  % if matching members, merge group
                conn_grp{n_grp_A} = unique([ conn_grp{n_grp_A}  conn_grp{n_grp_B} ]);
                conn_grp(n_grp_B) = {[]};
                do_merge = true;
            end
        end
    end
    sz_grp = cellfun(@numel, conn_grp);  % remove empty groups (from merging)
    conn_grp(sz_grp == 0) = [];
end