
-- Apply the transformation field -> updated field for
-- a discrete temperature field f)i,j)
--
--    f'(i,j) = (1-beta)*f(i,j) + beta*average(i,j)
--
-- where average(i,j) is the average of the
-- temperatures of the cells to the North, South,
-- East. and West.

-- This example is adapted from blur.fut

-- Compute the new value of the temperature field at the given cell.  The
-- cell must not be located on the edges or an out-of-bounds access
-- will occur.
let newValue [rows][cols]
             (beta: f32) (field: [rows][cols]f32) (row: i32) (col: i32): f32 =
  -- The Futhark compiler cannot prove that these accesses are safe,
  -- and cannot perform dynamic bounds checks in parallel code.  We
  -- use the 'unsafe' keyword to elide the bounds checks.  If we did
  -- not do this, the code generator would fail with an error message.
  unsafe
  let sum =
      field[row-1,col] + field[row+1,col]
    + field[row,  col-1] + field[row,  col+1]
  in (1-beta) * field[row,col] + beta * (sum / 4f32)

-- Compute the new field: call newValue on every cell in the interior,
-- leaving the edges unchanged.
let newField [rows][cols]
                (beta: f32) (field: [rows][cols]f32): [rows][cols]f32 =
  unsafe
  map (\row ->
        map(\col ->
              if row > 0 && row < rows-1 && col > 0 && col < cols-1
              then newValue beta field row col
              else field[row,col])
            (0...cols-1))
      (0...rows-1)


type pngElement = [4]u8

let f x = u8.f32 (255*x)

let ff x = [f x, 0, 0]:[3]u8

let pngRed [m][n] (data: [m][n]f32): [m][n][3]u8 =
  map (\row -> map ff row) data

let translate [rows][cols] (c: f32) (data: [rows][cols]f32): [rows][cols]f32 =
    map (map (\value -> value + c)) data

let rescale [rows][cols] (c: f32) (data: [rows][cols]f32): [rows][cols]f32 =
    map (map (\value -> c*value)) data

-- Perform the specified number of updates om the given temperature field.
--   SIMPLEST TEST:
--   [8]> let data = [[0, 0, 0], [0, 1, 0], [0, 0, 0]]:[3][3]f32
--   [9]> main 1 0.5 data
--       [[0.0f32, 0.0f32, 0.0f32], [0.0f32, 0.5f32, 0.0f32], [0.0f32, 0.0f32, 0.0f32]]
let main [rows][cols]
         (iterations: i32) (beta: f32) (field: [rows][cols]f32): ([rows][cols]f32, [rows][cols][3]u8) =
  let field = loop field for _i < iterations do newField beta field
  let pngData = pngRed field
  in (field, pngData)
