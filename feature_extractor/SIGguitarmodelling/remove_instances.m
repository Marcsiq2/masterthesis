function score_ds_p=remove_instances(score_ds,remove_idx)

%This function reremoves indexes given in remove_idx from each field of a
%structure. Each field of the structure have the same lenght and each
%element correspond to a desripto value of each instance. 


header=fieldnames(score_ds);% get field names


for i=1:numel(header)%for each field
    if strcmp(header{i},'nar') %if narmour
        score_ds.nar(remove_idx,:)=[];%remove rows

    else
    if strcmp(header{i},'p2s') %if narmour
        score_ds.p2s(remove_idx,:)=[];%remove rows

    else
        
    score_ds.(header{i})(remove_idx)=[];%remove row of current field
    end
end
    score_ds_p=score_ds;%return ds
end