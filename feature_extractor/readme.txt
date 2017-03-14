% The code and the data was developed and collected by Sergio Giraldo, MTG, Pompeu Fabra University, 2016 (sergio.giraldo@upf.edu), Barcelona, Spain. If you make use of this code/data please refer to the following publications:

%Sergio Giraldo and Rafael Ramirez. A Machine Learning Approach to Ornamentation Modeling and Synthesis in Jazz Guitar. Journal of Mathematics and Music, 2016b. doi: 10.1080/17459737.2016.1207814. URL http://dx.doi.org/10.1080/17459737.2016.1207814.

% Giraldo, Sergio, and Ramirez, Rafael (2015). Computational modeling of ornamentation in jazz guitar music, In proc. of International Symposium in Performance Science, ISPS 2015, September, Kyoto, Japan.

% Giraldo, Sergio, and Ramirez, Rafael(2015) . Computational Generation and Synthesis of Jazz Guitar Ornaments using Machine Learning Modeling. In proc. of International Workshop in Machine Learning and Music MML 2015, August, Vancouver, Canada.

Instructions:

1)Save the files on a folder at the matlab toolbox folder (e.g. toolbox/jazzModelling)
2)Set a path to the folder at the matlab environment.
3)Set your working directory as follows:

	workingDir
	|
	|-runMainguitarModelling.m
	|-dataIn/
	| |-csv/bpm_all_manual.csv
	| |-performed/wav/(wav monophonic files here)
	| |-score/(xml score files here)
	| |-scoreMid/(midi score files here)
	|-dataOut
	| |-annotations/(song annotations will be placed by the program here)
	| |-arffs/(arff data base files will be created here)
	| |-beats_txt/(txt files with beats position in second will be created here)
	| |-files_to_anotate/(files for manual alignment will be created here)
	| |-learntSongs/(midi files created by the system will be placed here)
	| |-noteDB/(databases in mat file format will be created here)
	| |-p2sAlignment/(mat files with performance to score alignment data)
	| |-performanceNmat/(mat structures of performance data)
	| |-performanceNmat_alligned/(mat structures of performance data aligned with beat detection)
	| |-scoreNmat/(mat structures of score data)
	| |-weka_temp_files/(temporal files for weka library when run from matlab)

4)Aditional libraries:
4.1.)Midi toolbox: https://www.jyu.fi/hum/laitokset/musiikki/en/research/coe/materials/miditoolbox
4.2.)weka: www.cs.waikato.ac.nz/ml/weka/
