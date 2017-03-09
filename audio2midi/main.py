# -*- coding: utf-8 -*-
 #!/usr/bin/env python -W ignore::DeprecationWarning
__author__ = 'Marcsiq2'


import sys
import os
import csv
import numpy as np
import Tkinter, tkFileDialog
import midi_utils
import essentia_extractor_sig
from midiutil.MidiFile import MIDIFile

OUTPUT_FILE = os.getcwd() + '/Files/extracted_midi/output.mid'

def main():

    #get imput arguments (use Tkinter to get folder, and console to arguments)
    root = Tkinter.Tk()
    root.withdraw()
    folderName = tkFileDialog.askdirectory(parent=root,initialdir=os.getcwd(),
        title='Please select a directory')
    if len(folderName ) <= 0:
        print "No folder selected!"
    else:
        folderName = folderName + '/'
        print "You chose %s" % folderName
        files = [fileName for fileName in os.listdir(folderName) if fileName[-3:] == "wav"]
        MyMIDI = MIDIFile(numTracks=len(files), adjust_origin=False)
        for track, fileName in enumerate(files): #Get files name list from performance folder (wavs)
            print 'Processing: %s' % fileName
            MyMIDI.addTrackName(track, 0, fileName[:-4])
            pitch_m, onset_b, dur_b, vel, bpm = extractionProcess(folderName, fileName)
            midi_utils.write_midi_notes(MyMIDI, track, pitch_m, onset_b, dur_b, vel)
        binfile = open(OUTPUT_FILE, 'wb')
        MyMIDI.writeFile(binfile)
        binfile.close()

        print "SUCCESS!!!"

    return






def extractionProcess(folderName, fileName):

    # options

    filter_opt = True
    use_pitch_cont_seg = True  # With adaptative and euristic filters by Giraldo and Bantula
    plot_noise_filter = False
    plot_filters = False
    unvoice_detection = False
    bpm_estimation = False

    # initial variables...

    #flag = 1
    #bpm_all = [['File Name','bpm', 'confidence']]
    minFrequency = 80  # E2 = 82.412Hz guitar lowest E
    maxFrequency = 2000  # D6 = 1175Hz guitar highest note
    bpm = 110
    #monophonic = input('Is audio monophonic?')
    monophonic = True

    # If monophonic audio (use YIN)
    if monophonic:
        f0, pitch_confidence = essentia_extractor_sig.yin(folderName, fileName, minFrequency, maxFrequency)
    else:
    # If poliphonic audio (use Melodia)
        f0, pitch_confidence = essentia_extractor_sig.melody(folderName, fileName, minFrequency, maxFrequency)

    # Get pwr
    if monophonic: #(based on envelope for monophonic signals, nov 2015)
        pwr = essentia_extractor_sig.envelope(folderName, fileName, plot_noise_filter)
    else:
        pwr = pitch_confidence

    # Estimate bpm
    if bpm_estimation:
        bpm = essentia_extractor_sig.beatTrack(folderName, fileName, monophonic)

    # Create discrete note events (MIDI) from pitch profile
    if use_pitch_cont_seg:
        # create MIDI from pitch profile using filters (our approach)
        pitch_midi, onset_b, onset_s, dur_b, dur_s, vel = midi_utils.f02nmat(folderName, fileName, f0, pwr, bpm, filter_opt, plot_noise_filter, plot_filters, minFrequency, maxFrequency)
    else:
        # create MIDI from pitch profile using essentia (no energy information is obtained here...)
        onset_s, dur_s, pitch_midi = essentia_extractor_sig.pitchContSeg(folderName, fileName, f0)
        onset_b = onset_s * bpm / 60  # get onset in beats
        dur_b = dur_s * bpm / 60  # get duration in beats
        vel = np.ones(len(onset_b) * 70)  # create same velocity for each note (change this to rms val based on note segmentation)

    # return values to create guitar midi file
    return pitch_midi, onset_b, dur_b, vel, bpm

    print "done"

    return

if __name__ == "__main__":
    main()