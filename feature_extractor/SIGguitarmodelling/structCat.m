function structAll= structCat(score_all,score_s)

fieldNames=fieldnames(score_s);

for i=1: length(fieldNames)
    d=size(score_s.(char(fieldNames(i))));%get item size
    if d(1)==1%if vector is horizontal
        score_s.(char(fieldNames(i)))=score_s.(char(fieldNames(i)))';%tranpose vetor
    end
    structAll.(char(fieldNames(i)))=[score_all.(char(fieldNames(i))); score_s.(char(fieldNames(i)))];
end

        
        
        