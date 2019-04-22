# Discrete Heat Equation

## Introduction

This little project is a test-of-concept for integration of [Futhark](https://futhark-lang.org) with [Elm](https://elm-lang.org)  The idea is to off-load computationally expensive work to Futhark, which can use the host's GPU.  The current idea is to run a Python server which calls Futhark code to do the expensive work.  This work is done on demand when the server receives a GET request from the client.  The server holds a `state` which in the example here is a 2D array of floats. On each request, the server sends the current value of `state` to the client, then uses Futhark to perform the update `state -> f(state)` for some function `f` of interest.

## Project structure

The Futhark and server files are in `./futhark-server`.  The files for (the start of) the Elm client are in `./src`

## Running the example

Do the following in `./futhark-server/`

```
$ futhark pyopencl --library heat.fut
$ python server.py
```
Then go to http://localhost:8001. Each time you referesh the browser, data will be sent from the server and the `state` will be updated.

## Server.py

Server.py starts up by creating an instance `myData` of the class `Data`.  This class has one instance variable, `state`, which is initialized with a 2D numpy array of float32.  It also has one method, `step`, which applies a transformation `state -> f(state)` to update the state variable.

When `server.py` receives a GET request at http://localhost:8000, it (1) replies with a string representation of `myData.state,` (2) updates `myData.state` using the `step` method. (This process needs to be improved, e.g., by sending binary data rather than a string so as not to incur conversion costs.)

The update function is the discrete heat kernel. It is implemented in `heat.futhark`  To make the code in this file available to server.py, run the command

   $ futhark pyopencl --library heat.fut

It will create a file `heat.py` which is imported
here.

PLANS: the next step is to write an Elm client that will talk to server.py and produce a visual display (heat map) of the data received.  See https://jxxcarlson.github.io/app/heat-model.html for a pure Elm version.  The Elm + Python + Futhark implementation will allow one to work with much larger heat fields (say, 100x100). All this is really a test for other models based on the state -> f(state) idea which are computationally more expensive. If there were a pure Elm bridge
 o Futhark, that would be awesome.

 ## Futhark repl

The Futhark repl allows one to easily test code:

 ```
 $ futhark repl
 [1]> :load heat.fut
 [1]> let data = [[0, 0, 0], [0, 1, 0], [0, 0, 0]]:[3][3]f32
 [2]>  main 1 0.5 data
 [[0.0f32, 0.0f32, 0.0f32], [0.0f32, 0.5f32, 0.0f32], [0.0f32, 0.0f32, 0.0f32]]

 ```

## Compiling Futhark code

Futhark code can be compiled to various targets:

```
$ futhark c heat.fut
$ futhark opencl heat.fut
$ futhark pyopencl --library heat
```

## Futhark FFI

```
futhark opencl --library  heat.fut
build_futhark_ffi heat
python test.py
```

Use `pip install futhark-ffi` for https://github.com/pepijndevos/futhark-pycffi


[pycffi Issue](https://github.com/pepijndevos/futhark-pycffi/issues/8)
