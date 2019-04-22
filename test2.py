# Test for heat.py.  Run using
#
#   python test2.py
#
# Run `futhark pyopencl --library heat.fut`
# to produce heat.py
#
import heat # import heat.py
import numpy as np

array = np.array([[0,0,0], [0,1,0], [0,0,0]], dtype=np.float32)

h = heat.heat()

res = h.main(1, 0.5, array)
print res

res2 = h.main(1, 0.5, res).reshape(1,9)
print res2
