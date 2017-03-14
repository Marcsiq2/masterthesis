function tis=intsize2(notewin)

%Given three notes' pitch, this function classify each of the two intervals
%betuen the notes as large or small, defining the limit in 6 semitones. 

dif1=diff(notewin);
if abs(dif1(1))<6&&abs(dif1(2))<6
    tis='ss';
else if abs(dif1(1))<6&&abs(dif1(2))>=6
    tis='sl';
else if abs(dif1(1))>=6&&abs(dif1(2))<6
    tis='ls';
    else
        tis='ll';
    end
    end
end
end

    