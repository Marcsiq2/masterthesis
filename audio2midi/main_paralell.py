# -*- coding: utf-8 -*-
 #!/usr/bin/env python -W ignore::DeprecationWarning
__author__ = 'Marcsiq2'


import sys
import os
import csv
import numpy as np
import midi_utils
import multiprocessing
from multiprocessing import Pool
import essentia_extractor_sig
from midiutil.MidiFile import MIDIFile

INPUT_FOLDER = '../Files/guitar_in/helena_song1/'
OUTPUT_FILE = '../Files/extracted_midi/helena_song1/output_channel.mid'

def main():

    folderName = INPUT_FOLDER
    if len(folderName ) <= 0:
        print "No folder selected!"
    else:
    
        files = [fileName for fileName in os.listdir(folderName) if ((fileName[-3:] == "wav") & (fileName != "all.wav"))]
        print "You chose %s with %s file" % (folderName, str(len(files)))
        MyMIDI = MIDIFile(numTracks=1, adjust_origin=False)
        MyMIDI.addTrackName(0,0, 'all')
        MyMIDI.addTempo(0, 0, 110)

        pool = NoDaemonPool(processes=len(files))

        for track in range(1,7): #Get files name list from performance folder (wavs)
            fileName = 'string%s.wav' % str(track)
            print '\nProcessing: %s' % fileName

            pool.apply_async(processtrack, args=(folderName, track, fileName, MyMIDI))

        #save midi files
        binfile = open(OUTPUT_FILE, 'wb')
        MyMIDI.writeFile(binfile)
        binfile.close()

        print "SUCCESS!!!"

    return



def processtrack(folderName, track, fileName, MyMidi):
    pitch_m, onset_b, dur_b, vel, bpm = extractionProcess(folderName, fileName)
    midi_utils.write_midi_notes(MyMIDI, track, pitch_m, onset_b, dur_b, vel)


def extractionProcess(folderName, fileName):

    # options

    filter_opt = True
    use_pitch_cont_seg = True  # With adaptative and euristic filters by Giraldo and Bantula
    plot_noise_filter = False
    plot_filters = False
    unvoice_detection = False
    bpm_estimation = False
    guitar_splitted = True

    # initial variables...

    #flag = 1
    #bpm_all = [['File Name','bpm', 'confidence']]
    string = int(fileName[6])
    freqs_guitar = [(320,660), (240,500), (190, 400), (140, 300), (100, 230), (80, 170)]
    minFrequency = 80  # E2 = 82.412Hz guitar lowest E
    maxFrequency = 2000  # D6 = 1175Hz guitar highest note
    bpm = 110

    if guitar_splitted:
        minFrequency, maxFrequency = freqs_guitar[string-1]
        print '--- Processing string %s with freqs %s to %s' % (str(string), str(minFrequency), str(maxFrequency))
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

class NoDaemonProcess(multiprocessing.Process):
    # make 'daemon' attribute always return False
    def _get_daemon(self):
        return False
    def _set_daemon(self, value):
        pass
    daemon = property(_get_daemon, _set_daemon)

class NoDaemonPool(multiprocessing.pool.Pool):
    Process = NoDaemonProcess


if __name__ == "__main__":
    main()