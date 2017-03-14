function [ nmat ] = create_nmat_gt( filename, bpm, w_sec,thre)
%CREATE_NMAT Donat un arxiu .wav i un tempo, retorna la matriu nmat.
% L'exporta en format .mat i la guarda dins la carpeta on s'est?
% treballant.

% Filename = 'allTheThingsYouAre.wav';
% bpm = 120; Ha d'estar expressat en beats per minut

%%
[x,fs]=audioread(filename);

p.minf0=80;
p.maxf0=1175;
p.sr=fs;
r=yin(x,p);


% Convert to Hz
f0=440*2.^r.f0;

% Inside guitar!
f0(f0<p.minf0)=0; %E2
f0(f0>p.maxf0)=0;  %D6

%DELETE NaNs

f0(isnan(f0))=0;
r.pwr(isnan(r.pwr))=0.00001;

% Calculate energy
delay = round(r.wsize/r.hop); % pwr is delayed by half the analysis window
n = length(r.f0) - delay + 1;
t = [0:n-1]*r.hop/r.sr;
energy = 10*log10(r.pwr(delay:length(r.f0)));%---> Esto es para calcular energia en dB?

% Noise gate (from energy!)
thres=-35; %Es pot optimitzar...
noise=find(energy<thres);
f0(noise)=1;

% Convert to MIDI
F=hz2midi_sig(f0,440);

% REMOVE INF
F(isinf(F))=0;

% Quantize
F=round(F);

% Filter out small samples


frames=fs/r.hop; %Quants frames YIN hi ha en un segon
w=round(frames*w_sec); %w=30ms;----->esto no deberia tener un round?

% w: HAURIA DE BASAR-SE EN EL TEMPO! Tot el que sigui menys d'una
% fusa...fora---->Ok pero si hay un tremolo?
% semifusa=60/(bpm*16);
% w=round(frames*semifusa); %w basado en el valor de semifusa

%%%%FIRST FILTER%%%%%
filtered=filter_pitch(F,w);
filtered=filter_pitch(filtered(1,:),w);
filtered=filtered(1,:);

%filtered=F;% to test with no filter. If filter is enabled comment this line.


% Samples to seconds
%figure(1)
%plot((1:882:length(filtered)*882)/fs,filtered,xlabel('seconds'),ylabel('MIDI notes'));
%plot((1:882:length(F)*882)/fs,F,xlabel('seconds'),ylabel('MIDI notes'));



%% Get onset/offset (peaks diff(f0))
df=[0,diff(filtered)];  % df = detection function
%df(find(df==-inf))=0;

%plot diff over F profile
% plot(F);
% hold on
% plot(find(df),F(find(df)),'r*')

onsets=zeros(size(df));
offsets=zeros(size(df));

%onsets(df>0)=40;

%offsets(df<0)=45;

index=find(df);


%%%%%%%%%%%%%%%filter notes of one frame%%%%%%%%%%%%%%%%%%%%%%%
%this is done by first filter, if filter is enable commment this
% for i=1:length(index)
%     if df(index(i)+1)~=0 %if there is a note of one frame
%         filtered(index(i))=filtered(index(i)-1);%asign previous frequency value
%     end
% end
% df=[0,diff(filtered)]; 
% onsets=zeros(size(df));
% offsets=zeros(size(df));
% index=find(df);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  


for i=1:length(index)
    prev=filtered(index(i)-1);
    next=filtered(index(i)+1);
        if prev>0                % Si NO ve de 0, es un offset %%%cambio condicion
            offsets(index(i))=45;
        end
        if next>0                % Si NO va a 0, es un onset %%%%cambio condicion
            onsets(index(i))=40;
        end
end

%onsets=[0 onsets]; %Hi ha un delay d'una mostra!

% First and last samples of df which are a NOTE
%notnan=find(~isnan(df));
% first = notnan(1);
% last = notnan(length(notnan));


% Correct first/last onsets/offsets
if filtered(1)>0% if first sample is a note here we have an onset
    onsets(1)=40;
end
if filtered(end)>0
    offsets(end)=45;%if last sample is a note here we have an offset
end

off_idx=find(offsets==45);
on_idx=find(onsets==40);

% figure;
% plot(filtered)
% hold on
% plot(find(onsets),filtered(find(onsets)),'*r')
% plot(find(offsets),filtered(find(offsets)-1),'*g')

if length(off_idx)~=length(on_idx)
    error('length of onsets and offsets is not the same in song %s', filename);
    
end

%% Energy and velocity
for i=1:length(on_idx)
    frame=energy(on_idx(i):min(off_idx(i),length(energy)));
    power(i)=mean(frame);
end
energia=linmap(power,[10 100]);


% Create nmat
nmat=zeros(length(on_idx),7);

pitch=filtered(on_idx);

nmat(:,3) = ones(size(pitch)); %MIDI channel
nmat(:,4) = pitch;
nmat(:,5) = round(energia); %Velocity
nmat(:,6) = on_idx*r.hop/fs; %Onsets (time)
nmat(:,7) = (off_idx-on_idx)*r.hop/fs; %Duration (time)

nmat(:,1) = nmat(:,6)*bpm/60; %Onsets (beats)
nmat(:,2) = nmat(:,7)*bpm/60; %Duration (beats)

%%%%%%%%SECOND FILTER%%%%%

% Post filter: we miltiplicate duraton and energy, and define a thershold
% for this value. Notes below threshold are omited. The idea is that notes
% which are too short (but longer than 30 ms) and with low energy are
% prone to be errors.

% Adaptative threshold for energy*duration

    i=1;
    while i<=length(nmat)
        if (nmat(i,7)<0.1)%apply only for notes shorter than 100ms
            idx_in=i-2;
            idx_out=i+2;%we set a window of 5 notes, so we calculate mean of two previous notes and two next notes.

            %we calculate mean of vel*dur of two
            % surrounding notes and multyply it by a reducing factor (thre) of
            % 10%
            adap_th=mean(nmat(max(idx_in,1):min(idx_out,length(nmat)),5))*mean(nmat(max(idx_in,1):min(idx_out,length(nmat)),7))*thre;

            vel_dur_fac=nmat(i,5)*nmat(i,7);%Calculate vel*dur of current note
            if adap_th>vel_dur_fac%if vel*dur factor is smaller than a thresohold (10 %) equal to the mean of surrounding notes
                nmat(i,:)=[];%the note is considered noise
                i=i-1;
            end
        end
        i=i+1;
    end

%% plots
% figure(2)
% pianoroll(nmat,'vel','sec')
% %% dysplay note numbers
% for i=1:size(nmat,1)
%     text(nmat(i,1),nmat(i,4)+1,num2str(i));
% end

%sound(x,fs);
%playsound(nmat);

%pause;

% Save nmat
pat = '[.]';
s = regexp(filename, pat, 'split');

save(s{1},'nmat');
hold off;

end

