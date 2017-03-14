function [train_ds,test_ds]=subset_ds(score_ds,index,k)

% This function rearrange the data of a structure gigen a range of
% instances that will be used as training set. This range is set to test
% structure array and the rest of the data is concatenated in one structur
% data train. 

if isfield(score_ds,'tempo')
    score_ds=rmfield(score_ds,'tempo');
end
header=fieldnames(score_ds);
for i=1:numel(header)
    if strcmp(header{i},'nar')
        test_ds.nar(:,1)=score_ds.nar(index(k,1):index(k,2),1);
        test_ds.nar(:,2)=score_ds.nar(index(k,1):index(k,2),2);
        test_ds.nar(:,3)=score_ds.nar(index(k,1):index(k,2),3);
        train_ds.nar(:,1)=score_ds.nar(index(k,2)+1:end,1);
        train_ds.nar(:,2)=score_ds.nar(index(k,2)+1:end,2);
        train_ds.nar(:,3)=score_ds.nar(index(k,2)+1:end,3);
    else
    test_ds.(header{i})=score_ds.(header{i})(index(k,1):index(k,2));
    train_ds.(header{i})=score_ds.(header{i})(index(k,2)+1:end);
    end
end
end