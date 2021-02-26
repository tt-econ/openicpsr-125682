function [nodes, weights, data_rep] = ComputeNodesAndWeights(obj, data, quadacc)
%
% Compute nodes and weights for numerical integration
%
% The complexity in the code here comes from the fact that different groups may have different
% numbers of unobservables (if there are individual-level unobservables and the panel is
% unbalanced), and we need to arrange the nodes for each unobservable into a single vector to
% speed numerical integration.
%
% The output num_nodes_by_group is a numgroups x 1 vector with ith element equal to the number of
% quadrature nodes generated for group i.
% 
% The outputs nodes and weights are arranged to match data in which the observations for group i have 
% been replicated nodes_by_group(i) times.
%
    if obj.numerical_integral
        if isempty(data.groupvar)
            data.groupvar = data.var.obsindex;
        end
        nobs_by_group = sumwithin(ones(data.nobs, 1), data.groupvar);
        unique_obs = unique(nobs_by_group);

        for nobs = unique_obs'
            [gnodes{nobs} inodes{nobs} weights{nobs} numnodes{nobs} nodeindex{nobs}] = ...
                get_raw(nobs, obj.nindiv_unobs, obj.ngroup_unobs, quadacc);
        end
        
        [gnodes inodes weights numnodes nodeindex] = ...
            allocate_to_groups(nobs_by_group, gnodes, inodes, weights, numnodes, nodeindex);

        weights = arrange_weights(data, weights, numnodes);
        nodes = arrange_nodes(obj, data, gnodes, inodes, numnodes, nodeindex);
        data_rep = data.Select(nodes.obs,':');

        data_rep.groupvar = groups([nodes.group nodes.nodenum]);
    else
        nodes.group = data.groupvar;
        nodes.nodenum = ones(data.nobs,1);
        nodes.obs = (1:data.nobs)';
        nodes.values = struct();
        weights.group = (1:data.ngroups)';
        weights.wgt = [];
        data_rep = data;
    end
end

function [gnodes, inodes, weights, num, nodeindex, obsindex] = get_raw(nobs, nindiv, ngroup, quadacc)
    dim = nobs*nindiv + ngroup;
    [nodearray, weights] = nwspgr('KPN', dim, quadacc);
    num = size(nodearray, 1);
    gnodes = reshape_nodemat(repmat(nodearray(:, 1:ngroup),1,nobs), num, nobs, ngroup);
    inodes = reshape_nodemat(nodearray(:, ngroup+1:end), num, nobs, nindiv);
    nodeindex = reshape_nodemat(repmat((1:num)', 1, nobs), num, nobs, 1);
end

function nodemat_out = reshape_nodemat(nodemat, nnodes, nobs, nvars)
% Take input nodemat with nnodes rows and nobs*nvars columns and output reshaped array with 
% rows*nobs rows and nvars columns, where the rows of the output are arranged in nnodes blocks of
% nobs
    temp = reshape(nodemat, [nnodes nvars nobs]);
    temp = permute(temp, [1 3 2]);
    nodemat_out = reshape(temp, [nnodes*nobs nvars]);
end

function varargout = allocate_to_groups(nobs_by_group, varargin)
    for i = 1:length(varargin)
        temp = varargin{i}';
        varargout{i} = cell2mat( temp(nobs_by_group) );
    end
end

function weights = arrange_weights(data, raw_weights, numnodes)
    weights.wgt = raw_weights;
    weights.group = expand_array((1:data.ngroups)', numnodes);
    weights.node = seqwithin(weights.group);
end

function nodes = arrange_nodes(obj, data, gnodes, inodes, numnodes, nodeindex)
    for i = 1:obj.ngroup_unobs
        name = obj.group_unobs_list{i};
        nodes.values.(name) = gnodes(:,i);
    end

    for i = 1:obj.nindiv_unobs
        name = obj.indiv_unobs_list{i};
        nodes.values.(name) = inodes(:,i);
    end

    nodes.nodenum = nodeindex;
    nodes.obs = expand_array(data.var.obsindex, numnodes(data.groupvar));
    nodes.group = expand_array(data.groupvar, numnodes(data.groupvar));

    % Until prodwithin() is rewritten to accept non-sorted data, resort by group-node-obs
    array = sortrows([nodes.group nodes.nodenum nodes.obs (1:length(nodes.group))']);
    index = array(:,4);
    nodes.nodenum = nodes.nodenum(index);
    nodes.obs = nodes.obs(index);
    nodes.group = nodes.group(index);
    for name = fieldnames(nodes.values)'
        nodes.values.(name{:}) = nodes.values.(name{:})(index);
    end

end



