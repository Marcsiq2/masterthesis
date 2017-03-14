function sd=samedir(notewin)
%Given a set of three notes' pitch, this function returns 1 if the
%intervals betwen the two notes go in the same direction and zero
%otherwise. 

dif1=diff(notewin);
if dif1(1)*dif1(2)>0
    sd=1;
else
    sd=0;
end
end