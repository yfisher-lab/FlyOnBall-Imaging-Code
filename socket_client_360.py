# *********** LOAD TOOLS ***********
#!/usr/bin/env python3
from Phidget22.Devices.VoltageOutput import *
import socket
import select
import numpy as np

# *********** SET SOCKET INFO ***********
HOST = '127.0.0.1'  # The (receiving) host IP address (sock_host),
PORT = 65413  # 5661  # The (receiving) host port (sock_port)
# FicTrac sends out signals to this destination IP address when the
# config file has parameter sock_host set as HOST value (e.g. 127.0.0.1) and
# sock_port is set as PORT value (e.g. 5661)
# to an appropriate number.
# -- FicTrac readme --:
# "Destination socket port for socket data output.
# If unset or <= 0, FicTrac will not transmit data over sockets.
# Note that a number of ports are reserved and some might be in use.
# To avoid conflicts, you should check which UDP ports are available
# on your machine prior to launching FicTrac (try something like 1111)."


# HOST = '128.32.173.192.5661'  # The (receiving) host IP address (sock_host)



# *********** SET ANALOG OUTPUT CHANNELS ***********
# Setup analog output yaw
aout_yaw = VoltageOutput()
aout_yaw.setChannel(0)
aout_yaw.openWaitForAttachment(5000)
aout_yaw.setVoltage(0.0)

# Setup analog output x position
aout_x = VoltageOutput()
aout_x.setChannel(1)
aout_x.openWaitForAttachment(5000)
aout_x.setVoltage(0.0)

# Setup analog output y position
aout_y = VoltageOutput()
aout_y.setChannel(2)
aout_y.openWaitForAttachment(5000)
aout_y.setVoltage(0.0)

# (optional) Setup analog output yaw gain
aout_yaw_gain = VoltageOutput()
aout_yaw_gain.setChannel(3)
aout_yaw_gain.openWaitForAttachment(5000)
aout_yaw_gain.setVoltage(0.0)


# *********** BEGIN DATA TRANSMISSION ***********
# TCP
# Open the connection (ctrl-c / ctrl-break to quit)
#with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
#    sock.connect((HOST, PORT))

# UDP
# Open the connection (ctrl-c / ctrl-break to quit)
with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
    sock.bind((HOST, PORT))
    sock.setblocking(0)
    
    # Keep receiving data until FicTrac closes
    data = ""
    timeout_in_seconds = 1
    while True:
        # Check to see whether there is data waiting
        ready = select.select([sock], [], [], timeout_in_seconds)
    
        # Only try to receive data if there is data waiting
        if ready[0]:
            # Receive one data frame
            new_data = sock.recv(1024)
            
            # Uh oh?
            if not new_data:
                break
            
            # Decode received data
            data += new_data.decode('UTF-8')
            
            # Find the first frame of data
            endline = data.find("\n")
            line = data[:endline]       # copy first frame
            data = data[endline+1:]     # delete first frame
            
            # Tokenise
            toks = line.split(", ")
            
            # Check that we have sensible tokens
            if ((len(toks) < 24) | (toks[0] != "FT")):
                print('Bad read')
                continue

            # *********** EXTRACT FICTRAC VARIABLES ***********
            # (see https://github.com/rjdmoore/fictrac/blob/master/doc/data_header.txt for descriptions)
            #cnt = int(toks[1])
            #dr_cam = [float(toks[2]), float(toks[3]), float(toks[4])]
            #err = float(toks[5])
            #dr_lab = [float(toks[6]), float(toks[7]), float(toks[8])]
            #r_cam = [float(toks[9]), float(toks[10]), float(toks[11])]
            #r_lab = [float(toks[12]), float(toks[13]), float(toks[14])]
            #posx = float(toks[15])
            #posy = float(toks[16])
            heading = float(toks[17])
            #step_dir = float(toks[18])
            #step_mag = float(toks[19])
            intx = float(toks[20])
            inty = float(toks[21])
            #ts = float(toks[22])
            #seq = int(toks[23])
            
            # *********** CONVERT TO VOLTAGE SIGNALS ***********
            # Set analog output voltage YAW
            output_voltage_yaw = (heading) * 10. / (2 * np.pi)
            # output_voltage_yaw = clamp(output_voltage_yaw, aout_min_volt, aout_max_volt)
            aout_yaw.setVoltage(output_voltage_yaw)

            # Set analog output voltage X
            wrapped_intx = (intx % (2 * np.pi))  # transform into animal coordinates
            output_voltage_x = wrapped_intx * 10. / (2 * np.pi)
            # output_voltage_x = clamp(output_voltage_x, aout_min_volt,aout_max_volt)
            aout_x.setVoltage(output_voltage_x)

            # Set analog output voltage Y
            wrapped_inty = (inty % (2 * np.pi))  # transform into animal coordinates
            output_voltage_y = wrapped_inty * 10. / (2 * np.pi)
            # output_voltage_x = clamp(output_voltage_x, 0, 10)
            aout_y.setVoltage(output_voltage_y)

            # Set analog output voltage YAW_GAIN
            output_voltage_yaw_gain = (heading % (2 * np.pi)) * (10.) / (2 * np.pi)
            # output_voltage_yaw_gain = clamp(output_voltage_yaw_gain, aout_min_volt,aout_max_volt)
            aout_yaw_gain.setVoltage(output_voltage_yaw_gain)

            # print(heading)
            print(output_voltage_yaw)
        
        else:
            # Didn't find any data - try again
            print('retrying...')
