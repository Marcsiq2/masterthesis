function p=hz2midi_sig(f,tuning)
%A function to calculate the midi number of a given frequency in hz. 
%f:Frequency (hz)
%tuning: standar tuning, usually 440hz but can variate +/- 4hz depending on
%the tuning of the instrument.
p=69+12*log2(f/tuning);
end