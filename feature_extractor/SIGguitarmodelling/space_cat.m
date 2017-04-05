function B=space_cat(A)
B=[];
for i=1:numel(A)
    if i<numel(A)%if not the last
        B=strcat(B, A{i}, {' '});%concatenate with a space
    else
        B=strcat(B, A{i});%concatenate last element
    end
end
end
    