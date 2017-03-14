function Q=filter_pitch(P,w)
%A function that quantices pitch according to the midi number notes. The
%input P is the midi number with decimal factors calculated by hz2midi
%function. It filters notes below 55hz (33 midi number), and notes shorter
%than w frames)

gap=1; %silence gap equal to one frame The idea is that notes and silences must be treated differently: their respective minimun duration is different
Q=P;
if w~=0
    
    %filter short notes =< w frames
    Q=[Q; [diff(Q)],0]; %differentiate to find onsets (diff>0) and offsets (diff<0)
    on_off_idx=find(Q(2,:));%find onset offset index for each note
    note_len=diff(on_off_idx);%find the length of each note
    
    for i=1:length(note_len)%search notes shorter than w
        %        if (note_len(i)<=w) && (Q(1,on_off_idx(i)+1 )>0)% if note is shorter than w and is a note (not a silence)
        if or(  ( Q(1,on_off_idx(i)+1)>0 )&&( note_len(i)<=w )   , (  ( Q(1,on_off_idx(i)+1)<=0 )&&( note_len(i)<=gap )  ) )
            %       if     { (is a note) and (note lenght<=w) } or {(is a silence) and (silence lenght <=0) }
            %             prova=note_len(i);
            %             plot(Q(1,:))
            %             hold on
            %             plot(on_off_idx(i)+1,Q(1,on_off_idx(i)+1 ),'r*')
            %             axis([on_off_idx(i)-1000 , min(length(Q),on_off_idx(i)+1000) , Q(1, on_off_idx(i))-6 , Q(1,on_off_idx(i))+6]);
            %             hold off
            
            %calculate interval to the previous note
            %on_off_idx(i) is the index last sample of previous note
            
            prev_int=(Q(1,on_off_idx(i)+1)-Q(1,on_off_idx(i))); %actual minus previous inteval
            
            %% calculate interval to te next note
            next_note_len=note_len(i); %actual note length
            j=i;%next note wich lenght>w index
            next_int=(Q(1,on_off_idx(i)+next_note_len+1)-Q(1,on_off_idx(i)+note_len(i))); %difference of last sample of current note and first sample of next note
            %% case1
            if prev_int==-next_int %compare previous interval and next interval
                %if abs(prev_int)>30 %if the interval is too big we asume is a onset
                %   Q(1,on_off_idx(i)+1:on_off_idx(i)+note_len(i))=-36;
                %else %If the interval is small then its a mistake, so the note is the previous(equal to next)
                Q(1,on_off_idx(i)+1:on_off_idx(i)+note_len(i))=Q(1,on_off_idx(i));
                %end
            else
                %% Calcualte new next interval based on next note length
                if(j~=length(note_len))
                    while (note_len(j+1)<w) && (Q(1,on_off_idx(j+1)+1 )>0) %if next note is too short and is not a rest
                        next_note_len=next_note_len+note_len(j+1); %add next note length to current note
                        j=j+1;
                        if numel(note_len)<(j+1)
                            break
                        end
                    end
                end
                next_int=(Q(1,on_off_idx(i)+next_note_len+1)-Q(1,on_off_idx(i)+note_len(i))); %difference of last sample of current note and first sample of next note
                %% case 2
                if prev_int==next_int%if the note is right in the middle betwen two notes
                    %half of the note is asigne to the previous note and half to the next note(ceil and
                    %floor are used in case the length of the note is odd
                    whb=floor(next_note_len/2);%half part that goes backward
                    Q(1,on_off_idx(i)+1:on_off_idx(i)+whb)=Q(1,on_off_idx(i));
                    whf=ceil(next_note_len/2);%half part that goes foward
                    Q(1,on_off_idx(i)+whb+1:on_off_idx(i)+whb+whf)=Q(1,on_off_idx(i)+whb+whf+1);
                else %the note is asigned to the closest note
                    %% case 3
                    if min(abs(prev_int),abs(next_int))==abs(prev_int)% if the shorter interval is with the previous note
                        Q(1,on_off_idx(i)+1:on_off_idx(i)+note_len(i))=Q(1,on_off_idx(i));%assign the prevoious note
                    else %assign the next note (no if required)
                        Q(1,on_off_idx(i)+1:on_off_idx(i)+note_len(i))=Q(1,on_off_idx(i)+next_note_len+1);%assign the next note
                    end
                end
            end
            
        end
    end
    
end
end