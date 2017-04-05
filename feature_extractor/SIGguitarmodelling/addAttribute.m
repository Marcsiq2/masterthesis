function score_s=addAttribute(score_s , attribute, attributeName)

fieldNames=fieldnames(score_s);
firstField=char(fieldNames(2));
for i=1:length(score_s.(firstField))
    switch class(attribute);
        case 'char'
            score_s.(attributeName){i}=attribute;
        case 'double'
            score_s.(attributeName)(i)=attribute;
    end
score_s.(attributeName)=score_s.(attributeName)';
end