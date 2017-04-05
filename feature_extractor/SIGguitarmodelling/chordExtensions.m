function [ext_id, ext_c]=chordExtensions(chord_ext_file)
%This function reads a chord type database was buildt with intervals describing note coposition. 

%get chord extensions description

fid2 = fopen(chord_ext_file);
%fid2 = fopen('data_sets/chords_extensions.txt');

ext=struct;
ext.a1 = textscan(fid2,'%s %f %f %f',1);%major
ext.b1 = textscan(fid2,'%s %f %f %f',1);%minor
ext.b2 = textscan(fid2,'%s %f %f %f',1);%2
ext.b3 = textscan(fid2,'%s %f %f %f',1);%sus
ext.b4 = textscan(fid2,'%s %f %f %f',1);%dim 
ext.b5 = textscan(fid2,'%s %f %f %f',1);%aug (+)
ext.c1 = textscan(fid2,'%s %f %f %f %f',1);%Maj7
ext.c2 = textscan(fid2,'%s %f %f %f %f',1);%6
ext.c3 = textscan(fid2,'%s %f %f %f %f',1);%m7
ext.c4 = textscan(fid2,'%s %f %f %f %f',1);%m6
ext.c5 = textscan(fid2,'%s %f %f %f %f',1);%mMaj7
ext.c6 = textscan(fid2,'%s %f %f %f %f',1);%m7b5
ext.c7 = textscan(fid2,'%s %f %f %f %f',1);%dim7
ext.c8 = textscan(fid2,'%s %f %f %f %f',1);%7
ext.c9 = textscan(fid2,'%s %f %f %f %f',1);%7#5 (+7?)
ext.c10 = textscan(fid2,'%s %f %f %f %f',1);%7b5
ext.c11 = textscan(fid2,'%s %f %f %f %f',1);%7sus
ext.d1 = textscan(fid2,'%s %f %f %f %f %f',1);%Maj9
ext.d2 = textscan(fid2,'%s %f %f %f %f %f',1);%69
ext.d3 = textscan(fid2,'%s %f %f %f %f %f',1);%m9
ext.d4 = textscan(fid2,'%s %f %f %f %f %f',1);%9
ext.d5 = textscan(fid2,'%s %f %f %f %f %f',1);%7b9
ext.d6 = textscan(fid2,'%s %f %f %f %f %f',1);%7#9
ext.e1 = textscan(fid2,'%s %f %f %f %f %f %f',1);%13
ext.e2 = textscan(fid2,'%s %f %f %f %f %f %f',1);%7b9b13 
ext.e3 = textscan(fid2,'%s %f %f %f %f %f %f',1);%7alt
frewind(fid2);%restart the file scaning from the beguining
ext_id = textscan(fid2,'%s %*[^\n]');%get chord types in a separate variable
fclose(fid2);
ext_c= struct2cell(ext);%convert everything in to a cell