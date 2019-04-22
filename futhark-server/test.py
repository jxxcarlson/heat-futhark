# Test for FFI.  By pepijndevos

import numpy as np
import _heat
from futhark_ffi import Futhark

data = np.zeros([3,3])
data[1,1] = 1

test = Futhark(_heat)
res = test.main(1, 0.5, data)
print(test.from_futhark(res))
