function trbk=createTbkFromAll_x_y(all_x,all_y)

%%put all pair points in ascending order (users may have pick points in one
%%direction or the other).

for i=1:length(all_x)
    if all_y(1,i)<all_y(2,i)
        %swap all_y
        swap=all_y(1,i);
        all_y(1,i)=all_y(2,i);
        all_y(2,i)=swap;
        %swap all_x
        swap=all_x(1,i);
        all_x(1,i)=all_x(2,i);
        all_x(2,i)=swap;
    end
end

        