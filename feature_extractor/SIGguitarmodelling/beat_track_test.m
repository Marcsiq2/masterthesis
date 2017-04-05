function y=beat_track_test(x,fs,beat)
%this function gets a mono audio wave form as a vector (x) and beat
%information as a vector containinf the beat onsets in seconds. It outputs
%a wave form with the beats to be listened.

%x: monophonic audio vector
%fs: Sampling rate of audio file
%beat: vector of detected beats in seconds

beat_s=round(beat*fs);%convert beats to samples;
if beat_s(1)==0
    beat_s(1)=1;
end

[tick,fs2]=wavread('audio/tick.wav');%read tick audio wave
%note that tick and original audio wave must have the same sample rate. If
%not sample rate of tick should be converted to the sample rate of the
%signal.
y=x;%duplicate x on y
for i=1:length(beat_s)
    %for each beat: add the tick wave form at the correspponding sample
    %place on x, and save it on to y
    if beat_s(i)<length(y)%if more beats thans sound sample length
        %size of x and tic must coincide
%         %i
%                 if i==93
%                    a=0;
%                end
        y(beat_s(i):min(beat_s(i)+length(tick)-1,length(y)))=x(beat_s(i):min(beat_s(i)+length(tick)-1,length(x)))+tick(1:length(beat_s(i):min(beat_s(i)+length(tick)-1,length(x))));
    end
end


end