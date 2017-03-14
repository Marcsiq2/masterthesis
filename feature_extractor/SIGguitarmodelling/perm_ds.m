function score_ds_p=perm_ds(score_ds,rand_idx)

%This function reorganizes the data in a structure given an index of the
%initial order of the data, and a random index order of the data. Tempo
%field is not used, so is removed. Each field of the structure is
%reorganized by indexing each elemento to the rame field indexed by the 
%randomize index.

% if isfield(score_ds,'tempo')
%     score_ds=rmfield(score_ds,'tempo');
% end
header=fieldnames(score_ds);
idx=1:length(rand_idx);

for i=1:numel(header)
    if strcmp(header{i},'nar')
        score_ds_p.nar(idx,1)=score_ds.nar(rand_idx,1);
        score_ds_p.nar(idx,2)=score_ds.nar(rand_idx,2);
        score_ds_p.nar(idx,3)=score_ds.nar(rand_idx,3);
    else
    score_ds_p.(header{i})(idx)=score_ds.(header{i})(rand_idx);
    score_ds_p.(header{i})=score_ds_p.(header{i})';
    end
end
end