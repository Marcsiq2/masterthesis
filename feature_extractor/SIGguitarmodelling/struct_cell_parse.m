function s=struct_cell_parse(t)


s=t;

header=fieldnames(s);
for i=1:numel(header)
            if iscell(s.(header{i})(1))
                if iscell(s.(header{i}){1})
                    s.(header{i})=[s.(header{i}){:}]';
                end
            end
end
end
