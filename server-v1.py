
#!/usr/bin/env python

"""
server.py starts up by creating an instance
`myData` of the class Data.  This class has
one instance variable, `state`, which is initialized
with a 2D numpy array of float32.  It also has
one method, `step`, which applies a transformation
`state -> f(state)` to update the state variable.

When `server.py` receives a GET request at
http://localhost:8000, it (1) replies with a string
representation of `myData.state,` (2) updates
`myData.state` using the `step` method. (This
process needs to be improved, e.g., by sending
binary data rather than a string so as not to
incur conversion costs.)

The update function is the discrete heat kernel.
It is implemented in `heat.futhark`  To make the
code in this file available to server.py, run the
command

   $ futhark pyopencl --library heat.fut

It will create a file `heat.py` which is imported
here.

PLANS: the next step is to write an Elm client
that will talk to server.py and produce a visual
display (heat map) of the data received.  See
https://jxxcarlson.github.io/app/heat-model.html
for a pure Elm version.  The Elm + Python + Futhark
implementation will allow one to work with much
larger heat fields (say, 100x100). All this is really 
a test for other models based on the
state -> f(state) idea which are computationally
more expensive. If there were a pure Elm bridge
to Futhark, that would be awesome.

"""



"""
Source: https://gist.github.com/bradmontgomery/2219997
Very simple HTTP server in python.
Usage::
    ./dataServer.py 8000
Send a GET request::
    curl http://localhost:8000/n=1000
Send a HEAD request::
    curl -I http://localhost:8000
Send a POST request::
    curl -d "foo=bar&bin=baz" http://localhost:8000
"""

## http://introtopython.org/classes.html

from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer

import SocketServer
import os
import numpy as np
import heat # import heat.py

#### MANIPULATE DATA USING FUTHARK ####

# Run `futhark pyopencl --library heat.fut`
# to produce heat.py

heatKernel = heat.heat()

# Set up test data.  In future version,
# the test data will be received from the
# client by HTTP.
n = 10
data = np.zeros(n*n).reshape(n,n)
data[3,3]=1
array = np.array(data, dtype=np.float32)

# The class which manages state
class Data():
  def __init__(self):
        self.state = array

  def step(self):
        self.state = heatKernel.main(1, 0.5, self.state)

myData = Data()

### END: MANIPULATE DATA USING FUTHARK ####

class S(BaseHTTPRequestHandler):

    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()

    def do_GET(self):
        self._set_headers()
        self.wfile.write(str(myData.state))
        myData.step()

    def do_HEAD(self):
        self._set_headers()

    def do_POST(self):
        # Doesn't do anything with posted data
        self._set_headers()
        self.wfile.write("<html><body><h1>POST!</h1></body></html>")

def run(server_class=HTTPServer, handler_class=S, port=8001):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print 'Starting httpd on port ' + str(port)
    httpd.serve_forever()

if __name__ == "__main__":
    from sys import argv

    if len(argv) == 2:
        run(port=int(argv[1]))
    else:
        run()
