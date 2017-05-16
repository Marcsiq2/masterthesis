function score_s = midi2ds2_poly(nmat,nstruct)

%% Create a score structure
score_s= struct;

%% Create labels to structure according to midi data
score_s.onset_b = nmat(:,1);
score_s.duration_b = nmat(:,2);
score_s.ch = nmat(:,3);
score_s.pitch = nmat(:,4);
score_s.vel = nmat(:,5);
score_s.onset_s= nmat(:,6);
score_s.dur_s = nmat(:,7);

%% Measure at which bar the note occurs
score_s.measure=floor((nmat(:,1)./4))+1;

%% Create "previous duration" column
score_s.pre_dur_b = circshift(score_s.duration_b,1);
score_s.pre_dur_b(1) = 0; %initial value is zero as it is the first note
score_s.pre_dur_s=score_s.pre_dur_b*60/nstruct.tempo;

%% Create "Next duration" column
score_s.nxt_dur_b = circshift(score_s.duration_b,-1);
score_s.nxt_dur_b(length (score_s.nxt_dur_b)) = 0;%last value is zero as it is the last note
score_s.nxt_dur_s=score_s.nxt_dur_b*60/nstruct.tempo;


%% Onset beat mod (beat onset at current measure)
score_s.onset_b_mod=rem((score_s.onset_b),4);%check out if summing 1 or not

%% We decided not to sume zero to the beat, so defeinition remains:
% beat 1=0
% beat 2=1
% beat 3=2
% beat 4=3

%% Note pitch mod
score_s.pitch_mod=rem(score_s.pitch,12);
%C=0
%C#=1...etc
%B=11

%% Number of simultaneous note:
% 0 = single note
score_s.n_simult=zeros(size(nmat,1),1);
int = zeros(size(nmat,1),size(nmat,1));
for i=1:size(nmat,1)
    
    for j = 1:10
        if i+j < size(nmat,1)
            if nmat(i,6)+nmat(i,7) > nmat(i+j,6)
                score_s.n_simult(i) = score_s.n_simult(i)+1;
                int (i,j) = nmat(i,4) - nmat(i+j,4);
            end
        end
        if i-j > 0
            if nmat(i,6) < nmat(i-j,6)+nmat(i-j,7)
                score_s.n_simult(i) = score_s.n_simult(i)+1;
                int (i,j+10) = nmat(i,4) - nmat(i-j,4);
            end
        end
    end
    
end
int = int(:, any(int));
%% Previous and next interval
score_s.prev_int = -(score_s.pitch - circshift(score_s.pitch,1));
score_s.next_int = -(score_s.pitch - circshift(score_s.pitch,-1));

%% Find key (numeric representation) using info from bb file
%      if (strcmp(info{1,2}{4}(2),'b'))%If the root is flattern
%          key=strfind(notes,info{1,2}{4}(1))-1;%search for the key note in notes vector minus 1 semitone
%      else if (strcmp(info{1,2}{4}(2),'#'));%if the root is sharp
%          key=strfind(notes,info{1,2}{4}(1))+1; %search for the key note in notes vector plus one semitone
%      else
%          key=strfind(notes,info{1,2}{4}(1));%search for the key in vector
%          end 
%      end
%      key=key-1;%to set note C as zero index

%Key is indexed by cicle of fifts from xml format so we have to get it indexed in
%linear representation (ej. CDEFG... etc)
%create notes vector

score_s=addAttribute(score_s, nstruct.keyFifths, 'keyFifits');%Set key in the cycle of fifths
%score_s=addAttribute(score_s, nstruct.keyMode, 'keyMode');%set mode major or minor

%% Melodic analysis respect to key

%notes='CsDsEFsGsAsB';%%'s' character is used to handle enarmonics
fifthsCircle=[12 7 2 9 4 11 6 1 8 3 10 5 12 7 2]; %indexes to vetor notes
key=fifthsCircle(nstruct.keyFifths+8)-1;%hey indexed in vector notes minos one so C is zero index
score_s.note2key = abs(score_s.pitch_mod - key);%key context

%% Read chords from band in a box file (function)
%ene/2014. This part will be read from the xml file. We need a function to
%read chords and return a matrix of bar x number of beats in a bar. We are
%assuming maximum one chord per beat.

chords=chordBeatMat(nstruct);

%order chords in a column by beat
chord_beat_col=chords.mat';
chord_beat_col=chord_beat_col(1:end)';

%same for chords indexes: no chord indexes needed!!!
chord_id_beat_col=chords.id';
chord_id_beat_col=chord_id_beat_col(1:end)';

%NOT WORKING
%index the note chord by note beat...
%score_s.chord=chord_beat_col(floor(score_s.onset_b)+1);%chord to each note(plus one as beats are zero indexed)
%score_s.chord=[score_s.chord{:}]';
%score_s.chord_id=chord_id_beat_col(floor(score_s.onset_b)+1);%chord idx to each note

%MARC FIX
indxs = floor((score_s.onset_b/max(score_s.onset_b))*length(chord_beat_col));
indxs(indxs==0) = 1;
score_s.chord = chord_beat_col(indxs);
score_s.chord_id=chord_id_beat_col(indxs);

%% create chord type descriptor
score_s.chord_type=cell(size(nmat,1),1);
for i=1:size(nmat,1)
    currentChord=char(score_s.chord{i});
    switch length(currentChord)
        case 0
        score_s.chord_type{i}='nc';%no chord
        case 1 %case of major chords only
            score_s.chord_type{i}='mayor';%mayor
        otherwise
            if strcmp(currentChord(2),'#')||strcmp(currentChord(2),'b')%if cord is flat or sharp
                 score_s.chord_type{i}=currentChord(3:end);%read type from the third index
            else
                 score_s.chord_type{i}=currentChord(2:end);%read type from the second index
            end
    end
end

%% Melodic analisys respect to chord:
%this is the interval from each note to its corresponding chord root. 
score_s.note2chord=abs(score_s.pitch_mod-score_s.chord_id);

%% Is a chord note?
%A chord type database was buildt with intervals describing note coposition. 

%Function to get chord extensions description
%CHECK OUT MAYOR CHORDS AS THEY HAVE NO TEXT TO REFER TO THE TYPE!!!
[ext_id, ext_c]=chordExtensions('Files/chord_extensions.txt');

%classify "Is a chord note y/n" by looking if the note2chord is in the chord description
score_s.isChordN=cell(size(nmat,1),1);%initialize cell array
for i=1:size(nmat,1),
    if strcmp(score_s.chord_type{i},'aug') 
        score_s.chord_type{i}='+';
    end
    if  strcmp(score_s.chord_type{i},'7+')%enramonic chord notation of + and 7#5
        score_s.chord_type{i}='7#5';
    end
%     if strcmp(score_s.chord_type{i},'dim')%enramonic chord notation of + and 7#5
%         score_s.chord_type{i}='dim7';
%     end
%     
    chtid=find(strcmp(ext_id{1},score_s.chord_type{i}));%get the chord type index of the current note    
    if numel(chtid)==0
         score_s.isChordN{i}='n';%if there is no chord note is labeled as not belonging to chord note... (think)
    else if ~isempty(find(cell2mat(ext_c{chtid}(2:end))==score_s.note2chord(i), 1))%if the note2chord is in the chord type description
            score_s.isChordN{i}='y';
        else
        score_s.isChordN{i}='n';
        end
    end
end

%mtr: this is the strength of the note in terms of the place in the bar: 
% 1st beat: Very strong (ss)
% 2nd beat: Weak (w)
% 3rd beat: Strong (s)
% 4th beat: Weak (w)
% 
% Up beats are calculated as beat fractions and their strength is set to very weak (ww) as follows:
% 
% 16th notes up beats:
% 1_1/2, 2_1/2, 3_1/2 and 4_1/2 beats: Very weak (ww)
% 
% 8th note triplets up beats:
% 1_1/3, 1_2/3,2_1/3,2_2/3,3_1/3,3_2/3,4_1/3,4_2/3 beats: Very weak (ww)

score_s.mtr=cell(size(nmat,1),1);%initialize cell array

for i=1:size(nmat,1)
    switch score_s.onset_b_mod(i)
        case 0 %note at first beat
            score_s.mtr{i}='ss';%very strong
        case 1 %note at second beat
            score_s.mtr{i}='w';%weak
        case 2 %note at third beat
            score_s.mtr{i}='s';%strong
        case 3 %note at fourth beat
            score_s.mtr{i}='w';%weak
        otherwise %intermediate values: half notes, triplets, etc
            score_s.mtr{i}='ww';%very weak
        end
end

%Narmour (MIDI toolbox)
% nar.rd=narmour(score_q,'rd');%registral direction (revised, Schellenberg 1997)
% nar.rr=narmour(score_q,'rd');%registral return (revised, Schellenberg 1997)
% nar.id=narmour(score_q,'id');%intervallic difference
% nar.cl=narmour(score_q,'cl');%closure
% nar.pr=narmour(score_q,'pr');%proximity (revised, Schellenberg 1997)
% nar.co=narmour(score_q,'cl');%consonance (Krumhansl, 1995)

%% narmour (mine)
score_s.nar=narmour_sig(nmat);

%% Get tempo
score_s=addAttribute(score_s, nstruct.tempo, 'tempo');

%% Phrase descriptor: 
%Is a descriptor based on the phrasse position. First we segement the
%melody using campolopous algorithm. Notes are then labeled as follows.
%i=beguining of phrase
%m=note in the middle of a phrase
%f=end of a phrase
%our theory is that a note is more probable to be embellished if is at the
%beguining or at the end of a phrase.

phrase=[];%initialize phrase
b=boundary(nmat,'fig');%find phrases boundarys
for i=1:length(b)-1%for each note (excep the last one which will be always end of phrase)
    if (b(i)>mean(b)*2)
        phrase{i}=['i'];%lable notes that are beguining of a phrase
    else if (b(i+1)>mean(b)*2)%if the next note is the beguining of a phrase, label prevous note as phrase end
        phrase{i}=['f'];%lable notes that are beguining of a phrase
    else
        phrase{i}=['m'];%lable notes as "in the middle of a phrase"
    end
    end
end

phrase{length(b)}=['f'];%lable last note as end of  phrase"
score_s.phrase=phrase';%assign resulting vector to score structure

end
