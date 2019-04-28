
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

import glob, os, os.path
import numpy as np
from scipy import misc
import png
import heat # import heat.py
import time

def round_to(k, x):
    return round(x*(10**k))/(10**k)

# png.from_array([[255, 0, 0, 255],
#                 [0, 255, 255, 0]], 'L').save("small_smiley.png")
#
# f = open('ramp.png', 'wb')      # binary mode is important
# w = png.Writer(256, 1, greyscale=True)
# w.write(f, [range(256)])
# f.close()


#### MANIPULATE DATA USING FUTHARK ####

# Run `futhark pyopencl --library heat.fut`
# to produce heat.py

heatKernel = heat.heat()


# The class which manages state
class Data():
  def __init__(self, n):
        self.n = n
        data = np.random.rand(self.n,self.n)
        for i in range(self.n//2, 4*self.n//5):
           for j in range(self.n//2, 4*self.n//5):
              data[i,j] = 0
        for i in range(self.n//5, 2*self.n/5):
           for j in range(self.n//5, 2*self.n//5):
            data[i,j] = 1.0
        array = np.array(data, dtype=np.float32)
        self.state = array
        self.png = []
        self.count = 0
        self.iterations = 1
        self.beta = 0.5

  ## def save(self):

  # n = 1000, t = 4 ms
  # n = 2000, t = 14 ms (x 3.5)
  # n = 4000, t = 50 ms (x 3.57)

  def step(self):
        print "STEP, iterations = "  + str(self.iterations)
        start = time.time()
        (self.state, self.png) = heatKernel.main(self.iterations,self.beta, self.state)
        end = time.time()
        print "gpu: " + str(round_to(2,1000*(end - start)))
        # print self.png.get().astype(np.uint8)
        # print type(self.png.get().astype(np.uint8))
        outfile = "image/heat_image" + str(self.count) + ".png"
        misc.imsave(outfile, self.png.get().astype(np.uint8))

  def play(self):
      print "PLAY"


  def reset(self):
      data = np.random.rand(self.n,self.n)
      for i in range(self.n//2, 4*self.n//5):
          for j in range(self.n//2, 4*self.n//5):
              data[i,j] = 0
      for i in range(self.n//5, 2*self.n/5):
          for j in range(self.n//5, 2*self.n//5):
              data[i,j] = 1.0
      array = np.array(data, dtype=np.float32)
      self.state = array
      (self.state, self.png) = heatKernel.main(1,0, self.state)
      outfile = "./image/heat_image0.png"
      misc.imsave(outfile, self.png.get().astype(np.uint8))
      self.count = 0
      print "beta = " + str(self.beta) + ", iterations = " + str(self.iterations)



  def set_beta(self, beta):
      self.beta = beta

  def set_n(self, n):
      self.n = n

  def set_iterations(self, n):
    self.iterations = n
    print ("In set_iterations (X), iterations = " + str(self.iterations))


myData = Data(400)

### END: MANIPULATE DATA USING FUTHARK ####


def parse(str):
    parts = str.lstrip("/").split("=")
    if len(parts) == 2:
        return { 'cmd': parts[0], 'arg': parts[1], 'arity': 1}
    else:
        return { 'cmd': parts[0], 'arg': "", 'arity': 0}

def step(count):
    myData.count = int(count)
    myData.step()
    return "image: " + str(myData.count)

def play(count):
    myData.count = int(count)
    myData.play()
    return "image: " + str(myData.count)

def reset():
    filelist = glob.glob(os.path.join("./image", "*.png"))
    for f in filelist:
        os.remove(f)

    myData.reset()
    return "server: reset"


def data():
    nn = myData.n * myData.n
    if myData.count == 0:
        dd = myData.state.reshape(1,nn)[0]
        print "(0)"
    else:
        dd = myData.state.reshape(1,nn).get()[0]
        print "(>0)"
    return dd.tobytes()

def beta(beta):
    myData.set_beta(float(beta))
    return "beta = " + beta

def do_set_n(n):
    myData.set_n(int(n))
    return "n = " + n

def do_set_iterations(n):
    print ("In do_set_iterations, n = " + n)
    myData.set_iterations(int(n))
    return "iterations = " + n

def defaultResponse():
    return "unknown command"

op = { 'step':  step,
       'data':  data,
       'reset': reset,
       'beta': beta,
       'n': do_set_n,
       'iterations': do_set_iterations}


def response(command_string):
    c = parse(command_string)
    print "command = " + c['cmd']
    if c['cmd'] in op:
       if c['arity'] == 0:
           print "cmd = " + c['cmd']
           return op[c['cmd']]()
       else:
           print "cmd = " + c['cmd'] + ", arg = " + c['arg']
           return op[c['cmd']](c['arg'])
    else:
        file_path = c['cmd']
        while  !(os. path. isfile(file_path)):
            time.sleep(0.05)
        with open(file_path , "rb") as binaryfile :
           myArr = bytearray(binaryfile.read())
           print "length(myArr) = " + str(len(myArr))
           return myArr # defaultResponse()



class S(BaseHTTPRequestHandler):

    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()

    def do_GET(self):
        self._set_headers()
        data = response(self.path)
        start = time.time()
        self.wfile.write(data)
        end = time.time()
        print "save file: " + str(round_to(2, 1000*(end - start)))
        print "count: " + str(myData.count)
        print "------------"

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
