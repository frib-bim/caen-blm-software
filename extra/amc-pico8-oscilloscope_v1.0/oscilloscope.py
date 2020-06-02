#!/usr/bin/env python3
# -*- coding: utf-8 -*-

''' CAENels AMC-Pico8 Oscilloscope

Copyright (C) 2015 CAEN ELS d.o.o.

'''

import sys
import numpy as np
from PyQt5 import QtGui, uic
from PyQt5.QtCore import *
import pyqtgraph as pg
import re
import os

import DriverThread
import oscUtils


pos = np.array([0.0, 0.5, 1.0])
color = np.array([[0, 0, 0, 255], [255, 128, 0, 255], [255, 255, 0, 255]], dtype=np.ubyte)
cmap = pg.ColorMap(pos, color)

pg.setConfigOption('background', (50, 50, 50))
pg.setConfigOption('foreground', (200, 200, 200))
pg.setConfigOption('antialias', True)


def getScriptPath():
    return os.path.dirname(os.path.realpath(sys.argv[0]))


class UserWindow(QtGui.QDialog):

    closeThreadSignal = pyqtSignal()
    fsampChanged = pyqtSignal(float)
    rangesChanged = pyqtSignal(int)
    gateMuxChanged = pyqtSignal(int)
    convMuxChanged = pyqtSignal(int)
    ringBufChanged = pyqtSignal(int)
    triggerChanged = pyqtSignal(int, float, int, int)

    colors = ["#FFFF00", "#FF1493", "#00BFFF", "#00FF7F",
          "#FF8C00", "#BA55D3", "#87CEEB", "#BAFF00"]

    def __init__(self):
        QtGui.QDialog.__init__(self)

        self.ui = uic.loadUi(getScriptPath() + "/mainwindow.ui")
        self.ui.show()

        self.fft_sel = 0
        self.ch_enabled = [1 for i in range(8)]
        self.fsamp = int(1e6)
        self.paused = False
        self.avg = 1

        self.timer = QTimer()

        # Driver thread
        self.driver_thread = DriverThread.DriverThread()
        self.closeThreadSignal.connect(self.driver_thread.setExiting)
        self.driver_thread.newDataAvailable.connect(self.redrawGraphs)
        self.fsampChanged.connect(self.driver_thread.change_samp_freq)
        self.rangesChanged.connect(self.driver_thread.change_ranges)
        self.gateMuxChanged.connect(self.driver_thread.change_gate_mux)
        self.convMuxChanged.connect(self.driver_thread.change_conv_mux)
        self.ringBufChanged.connect(self.driver_thread.change_ring_buf)
        self.triggerChanged.connect(self.driver_thread.change_trigger_conf)
        self.ui.nrOfSamplesBox.currentIndexChanged[str].connect(
            self.driver_thread.set_nr_samp)
        self.driver_thread.start()

        # Mean and stdev lineedits, labels
        self.label_ch_stat = \
            [self.ui.findChild(QtGui.QLabel, 'ch' + str(i) + 'Label') for i in range(8)]
        self.lineedit_mean = \
            [self.ui.findChild(QtGui.QLineEdit, 'meanCh' + str(i)) for i in range(8)]
        self.lineedit_stdev = \
            [self.ui.findChild(QtGui.QLineEdit, 'stDevCh' + str(i)) for i in range(8)]
        self.label_ch_rng = \
            [self.ui.findChild(QtGui.QLabel, 'ch' + str(i) + 'RangeLabel') for i in range(8)]
        self.radio_rng1m = \
            [self.ui.findChild(QtGui.QRadioButton, 'rngCh' + str(i) + '_mA') for i in range(8)]
        self.checkbox_enable = \
            [self.ui.findChild(QtGui.QCheckBox, 'ch' + str(i) + 'EnableCheckbox') for i in range(8)]

        # Initialize ranges
        for i in range(8):
            self.radio_rng1m[i].setChecked(True)
        self.on_rangeSelectors_changed()

        # Color
        for i in range(8):
            self.label_ch_stat[i].setStyleSheet('QLabel{ background-color : ' +
                self.colors[i] + ' ; }')
            self.label_ch_rng[i].setStyleSheet('QLabel{ background-color : ' +
                self.colors[i] + ' ; }')

        # Initialize plots
        self.ui.currentsGraph.showGrid(x=True, y=True)

        # Prepare trigger cursors
        self.level_cursor = pg.InfiniteLine(pos=0, angle=0, pen=None, movable=True)
        self.delay_cursor = pg.InfiniteLine(pos=0, angle=90, pen=None, movable=True)

        # pen == None -> hidden
        self.level_cursor.setPen(None)
        self.delay_cursor.setPen(None)

        self.level_cursor.sigPositionChangeFinished.connect(self.level_position_changed)
        self.delay_cursor.sigPositionChangeFinished.connect(self.delay_position_changed)

        self.ui.currentsGraph.addItem(self.level_cursor)
        self.ui.currentsGraph.addItem(self.delay_cursor)

        self.ch_plot = []

        for i in range(8):
            self.ch_plot.append(self.ui.currentsGraph.plot(pen=self.colors[i]))

        self.ui.fftGraph.showGrid(x=True, y=True)
        self.fft_plot = self.ui.fftGraph.plot(pen='y')

        # Initialize buttons
        self.ui.pauseButton.setIcon(
            self.style().standardIcon(QtGui.QStyle.SP_MediaPause))
        self.ui.pauseButton.released.connect(
            self.on_pauseButton_released)
        self.ui.averagingSpinBox.valueChanged[int].connect(
            self.on_averagingSpinBox_changed)

        self.ui.fSampBox.editingFinished.connect(self.on_fSampBox_changed)

        # connect range radio buttons to slots
        for i in range(8):
            # Only one of the range button should be connected to slot
            self.radio_rng1m[i].toggled.connect(self.on_rangeSelectors_changed)

        # enable all channels at startup
        for i in range(8):
            self.checkbox_enable[i].stateChanged[int].connect(self.on_enableCheckbox_changed)

        self.ui.fftSelector.currentIndexChanged[int].connect(
            self.on_fftSelector_changed)
        self.ui.gateMuxBox.currentIndexChanged[int].connect(
            self.on_gateMuxBox_changed)

        self.ui.convMuxBox.currentIndexChanged[int].connect(
            self.on_convMuxBox_changed)

        # Trigger widget connections
        self.ui.trgEdgeBox.currentIndexChanged.connect(self.emit_trigger_control)
        self.ui.trgLevelBox.editingFinished.connect(self.level_boxes_changed)
        self.ui.trgLevelCombo.currentIndexChanged.connect(self.level_boxes_changed)
        self.ui.trgPosSpinBox.editingFinished.connect(self.delay_position_changed)
        self.ui.trgChComboBox.currentIndexChanged.connect(self.emit_trigger_control)
        self.ui.trgLengthSpinBox.editingFinished.connect(self.emit_trigger_control)

    def __del__(self):
        # print('mainwindow __del__')
        self.closeThreadSignal.emit()
        self.driver_thread.wait()

    @pyqtSlot(np.ndarray)
    def redrawGraphs(self, data):
        ''' Redraws plots

        Args:
            data: Numpy array of shape (8, N)
        '''
        if self.paused or len(data[0]) == 0:
            return

        self.set_trigger_status_triggered()
        self.timer.singleShot(500, self.set_trigger_status_waiting)

        for i in range(8):
            if self.ch_enabled[i]:
                self.ch_plot[i].setData(oscUtils.wind_avg(data[i], self.avg))
                self.lineedit_mean[i].setText(oscUtils.toSIstring(np.mean(data[i])) + 'A')
                self.lineedit_stdev[i].setText(oscUtils.toSIstring(np.std(data[i])) + 'A')
            else:
                self.ch_plot[i].setData([0])
                self.lineedit_mean[i].setText('')
                self.lineedit_stdev[i].setText('')

        # Calculate FFT
        fft_data = np.abs(np.fft.fft(data[self.fft_sel])) / self.fsamp
        fft_len = len(fft_data)
        fft_freq = np.linspace(0, self.fsamp, fft_len)

        self.fft_plot.setData(fft_freq[0:fft_len / 2], fft_data[0:fft_len / 2],
                              pen=self.colors[self.fft_sel])

    def on_fftSelector_changed(self, sel):
        ''' Changes fft selector '''
        self.fft_sel = sel

    def on_rangeSelectors_changed(self):
        ''' Converts the ranges to AMC-Pico8 range format and changes range '''
        ranges = 0
        for i in range(7, -1, -1):
            ranges <<= 1
            if not self.radio_rng1m[i].isChecked():
                ranges += 1

        self.rangesChanged.emit(ranges)

    def on_pauseButton_released(self):
        ''' Pauses currently displayed screen '''
        self.paused = not self.paused
        if self.paused:
            self.ui.pauseButton.setIcon(self.style().standardIcon(QtGui.QStyle.SP_MediaPlay))
            self.ui.pauseButton.setText('Start')
        else:
            self.ui.pauseButton.setIcon(self.style().standardIcon(QtGui.QStyle.SP_MediaPause))
            self.ui.pauseButton.setText('Pause')

    def on_averagingSpinBox_changed(self, avg):
        self.avg = avg

    def on_fSampBox_changed(self):
        ''' Changes the sampling frequency '''
        samp_freq = self.ui.fSampBox.value() * 1000  # UI has this value in kHz
        self.fsampChanged.emit(samp_freq)

    def on_enableCheckbox_changed(self, val):
        ''' Displays or hides certain channels '''
        chName = self.sender().objectName()
        ch_int = int(re.search(r'\d', chName).group())
        self.ch_enabled[ch_int] = val / 2

    def on_gateMuxBox_changed(self, val):
        # print('on_gateMuxBox_changed', val)
        if val == 2:
            # Show trigger controls
            self.ui.trgCtrlWidget.setEnabled(True)
            # Show cursors
            self.level_cursor.setPen(width=2, color='r')
            self.delay_cursor.setPen(width=2, color='r')
        else:
            # Disable trigger controls
            self.ui.trgCtrlWidget.setEnabled(False)
            # Hide cursors
            self.level_cursor.setPen(None)
            self.delay_cursor.setPen(None)

            self.ringBufChanged.emit(0)

        self.gateMuxChanged.emit(val)

    def on_convMuxBox_changed(self, val):
        if val != 0:
            self.ui.fSampBox.setDisabled(True)
        else:
            self.ui.fSampBox.setDisabled(False)
        # print('on_convMuxBox_changed', val)

        self.convMuxChanged.emit(val)

    def emit_trigger_control(self):
        ''' Fetches all trigger controls and passes it to driver layer '''
        mode = self.ui.trgEdgeBox.currentIndex()
        level = self.level_cursor.getYPos()
        channel = self.ui.trgChComboBox.currentIndex()
        length = self.ui.trgLengthSpinBox.value()

        #
        self.triggerChanged.emit(mode, level, length, channel)

    def level_position_changed(self):
        trg_limit = self.sender().getYPos()

        # Set the other (cursor)
        # print('limit', trg_limit)
        trg_pow = np.floor(np.log10(np.abs(trg_limit)))
        sel = (trg_pow // 3) + 3
        if sel > 2:
            sel = 2
        trg_unit = 10 ** (-(9 - 3 * sel))

        self.ui.trgLevelBox.setValue(trg_limit / trg_unit)
        self.ui.trgLevelCombo.setCurrentIndex(sel)

        # Emit the signal
        self.emit_trigger_control()

    def level_boxes_changed(self):
        trg_pow = self.ui.trgLevelCombo.currentIndex()
        trg_unit = 10 ** (-(9 - 3 * trg_pow))
        trg_limit = self.ui.trgLevelBox.value() * trg_unit

        # Set the other (cursor)
        self.level_cursor.setValue(trg_limit)

        # Emit the signal
        self.emit_trigger_control()

    def delay_position_changed(self):
        ''' Sets the number of samples before trigger '''
        # print(type(self.sender()))
        if type(self.sender()) == pg.graphicsItems.InfiniteLine.InfiniteLine:
            rb_delay = int(self.sender().getXPos())
        else:
            rb_delay = self.sender().value()

        if rb_delay < 0:
            rb_delay = 0

        if rb_delay > 1023:
            rb_delay = 1023

        self.delay_cursor.setValue(rb_delay)
        self.ui.trgPosSpinBox.setValue(rb_delay)
        self.ringBufChanged.emit(rb_delay)

    def set_trigger_status_waiting(self):
        self.ui.trgStatus.setText('Waiting...')
        self.ui.trgStatus.setStyleSheet('QLabel{ background-color : red ; }')

    def set_trigger_status_triggered(self):
        self.ui.trgStatus.setText('Triggered')
        self.ui.trgStatus.setStyleSheet('QLabel{ background-color : green ; }')


def main():
    app = QtGui.QApplication(sys.argv)
    window = UserWindow()

    app.exec_()
    sys.exit()


if __name__ == '__main__':
    main()
