This function parses an XLM music file and extracts note information and
chord information in a ARFF file and MATLAB "mat" file. It is desingned to
parse a monophonic melody along with it respective chords. XML files must
include key, tempo, and time signature information. The ARFF file produced
is compatible to be evaluated with the respective expressive model
available at:

https://github.com/chechojazz/machineLearningAndJazz/tree/master/models

input arguments:
batch: [1,0]. Set to 1 if you want to bacth process several files in a
folder. Set to zero if you want to process only one file.

This code make use of some functions of the MIDItoolbox library. Please
download and install from:
https://www.jyu.fi/hum/laitokset/musiikki/en/research/coe/materials/miditoolbox

This code was created by Sergio Giraldo, MTG, Pompeu Fabra University, 2016
(sergio.giraldo@upf.edu). If you make use of this code please refer to the
following citattions:

Giraldo, S., & Ramírez, R. (2016). A machine learning approach to
ornamentation modeling and synthesis in jazz guitar. Journal of
Mathematics and Music, 10(2), 107-126. doi: 10.1080/17459737.2016.1207814,
URL: http://dx.doi.org/10.1080/17459737.2016.1207814

Sergio Giraldo, 2016, MTG.
