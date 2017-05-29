function [ cutted_struct ] = cut_struct( input_struct , offset, length )
    cutted_struct = struct;
    fields = fieldnames(input_struct);
    for i = 1:numel(fields)
      cutted_struct.(fields{i}) = input_struct.(fields{i})(offset+1:length,:);
    end

end

