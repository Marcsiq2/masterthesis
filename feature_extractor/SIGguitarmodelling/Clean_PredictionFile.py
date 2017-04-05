#!/usr/bin/env python
import sys, os

if __name__ == "__main__":
	pred_file = sys.argv[1]
	clean_file = sys.argv[2]
	file_out = open(clean_file,'w')
	output = file(pred_file).readlines()
	output = output[5:-1] #wondering why? open tmpFile and look.
	timeframe = []
	prediction = []
	for i in output:
		parts = i.split()
		timeframe.append(int(parts[0]))
		temp = parts[2].split(":")
		prediction.append(temp[1])
		file_out.write(temp[1]+'\n')
	  
	#print prediction
	file_out.close()

