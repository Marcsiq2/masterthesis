function cell_class=struct_class(s)
%This function retrieves a vector of the same length of the number of
%fields of a structure, containing and indicator of the class of the cells
%of a particular field, being 1 for cell class, and zero other wise.
header=fieldnames(s);
cell_class=zeros(length(header),1);
for i=1:length(header)
    switch class(s.(header{i}))
        case 'cell'
            cell_class(i)=1;
        otherwise
            cell_class(i)=0;
    end
end
end
        