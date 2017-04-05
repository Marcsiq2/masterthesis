
function vout = linmap(vin,rout)
% function for linear mapping between two ranges
% inputs:
% vin: the input vector you want to map, range [min(vin),max(vin)]
% rout: the range of the resulting vector
% output:
% vout: the resulting vector in range rout

a = min(vin);
b = max(vin);
c = rout(1);
d = rout(2);
vout = ((c+d) + (d-c)*((2*vin - (a+b))/(b-a)))/2;
end
