from threading import Thread
import nidaqmx
from Phidget22.Devices.VoltageOutput import VoltageOutput as PhidgetVO
import socket
import select
import numpy as np
import subprocess
import time
import matlab.engine
import os


class FictracProcess:

    def __init__(self,
                 fictrac_path=r'C:\Users\fisherlab\Documents\FicTrac211\fictrac.exe',
                 config_file=r'C:\Users\fisherlab\Documents\FicTrac211\config.txt'):
        self.fictrac_path = fictrac_path
        self.config_file = config_file
        self.p = None

    def open(self, creationflags=subprocess.CREATE_NEW_CONSOLE):
        self.p = subprocess.Popen([self.fictrac_path, self.config_file], creationflags=creationflags)

    def close(self):
        self.p.kill()


# TODO: break down into two classes and a wrapper class
class PhidgetControl:

    def __init__(self, host='127.0.0.1', port=65413, phidget_timeout=5000):
        self.host = host
        self.port = port
        self.state = "idle"
        self.phidget_timeout = phidget_timeout

        self.max_pin_val = 10.
        # initialize pins
        self.aout_pins = {k: PhidgetVO() for k in ['yaw', 'x', 'y']}

    def run(self):
        self.open_channels()
        self.continuous_readwrite()
        self.close_channels()

    def open_channels(self):
        for channel_id, (key, pin) in enumerate(self.aout_pins.items()):
            pin.setChannel(channel_id)
            pin.openWaitForAttachment(self.phidget_timeout)
            pin.setVoltage(0.0)

    def wrapped_val_to_voltage(self, val):
        return self.max_pin_val * val / (2 * np.pi)

    @staticmethod
    def wrap_xy(val):
        return val % (2 * np.pi)

    def continuous_readwrite(self, fictrac_timeout=1):

        # TODO: ensure that fictrac is active

        # open socket to fictrac
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock, open("phidget_out.txt","a") as phidget_out:
            sock.bind((self.host, self.port))  # bind socket
            sock.setblocking(False)  # nonblocking -
            # TODO: check if blocking is safer

            # TODO: figure out how this string processing is working
            data = ""
            # while fictrack is running
            while ft.p.poll() is None:
                self.state = "reading"
                # Check to see whether there is data waiting
                ready = select.select([sock], [], [], fictrac_timeout)

                # Only try to receive data if there is data waiting
                if ready[0]:

                    # Receive one data frame
                    new_data = sock.recv(1024)  # new_data = 0 if no bytes sent
                    if not new_data:
                        break

                    # Decode received data
                    data += new_data.decode('UTF-8')

                    # Find the first frame of data
                    endline = data.find("\n")
                    line = data[:endline]  # copy first frame
                    data = data[endline + 1:]  # delete first frame

                    # Tokenise
                    toks = line.split(", ")

                    # Check that we have sensible tokens
                    if ((len(toks) < 24) | (toks[0] != "FT")):
                        print('Bad read')
                        continue

                    # extract fictrac variables
                    # (see https://github.com/rjdmoore/fictrac/blob/master/doc/data_header.txt for descriptions)
                    yaw = float(toks[17])
                    intx = float(toks[20])
                    inty = float(toks[21])

                    # write pins
                    self.aout_pins['yaw'].setVoltage(self.wrapped_val_to_voltage(yaw))
                    self.aout_pins['x'].setVoltage(self.wrapped_val_to_voltage(self.wrap_xy(intx)))
                    self.aout_pins['y'].setVoltage(self.wrapped_val_to_voltage(self.wrap_xy(inty)))
                    phidget_out.write("%f, %f, %f \n" % (yaw,intx,inty))
                else:
                    pass


    def close_channels(self):
        for (key, pin) in self.aout_pins.items():
            pin.close()

def run_phidget_thread():
    PhidgetControl().run()

def run_matlab_engine_thread():
    eng = matlab.engine.start_matlab()
    # eng.eval("C:\\Users\\fisherlab\\Documents\\repos\\FlyOnBall-Imaging-Code\\sample_daq_io.m",nargout=0)
    eng.eval("cd C:\\Users\\fisherlab\\Documents\\repos\\FlyOnBall-Imaging-Code",nargout=0)
    eng.eval("sample_daq_io",nargout=0)

if __name__ == "__main__":

    eng = matlab.engine.start_matlab()

    # start fictrac
    global ft
    ft = FictracProcess()
    ft.open()

    phidget_thread = Thread(target=run_phidget_thread)
    phidget_thread.start()



    eng.eval("cd C:\\Users\\fisherlab\\Documents\\repos\\FlyOnBall-Imaging-Code",nargout=0)
    eng.eval("sample_daq_io",nargout=0)


    ft.close()
    phidget_thread.join()
    eng.quit()


    # first process, open fictrac
