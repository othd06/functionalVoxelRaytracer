

import times
import helpers
import modelLoader
import materials
import raytracer
import qoiEncoder

# Start timing model loading
let t0 = now()
let (dims, model) = loadModel("teapot.binvox")
let t1 = now()
echo "Model loading took: ", inMilliseconds(t1 - t0), " ms"

# Prepare image buffer
var image: array[1280, array[720, Colour]]

# Start timing rendering
let t2 = now()
for i in 0..<1280:
  for j in 0..<720:
    let direction = normalise(Vector3(
      x: (i.float64 / 639.5) - 1.0,
      y: (j.float64 / 639.5) - (359.5 / 639.5),
      z: 1.0
    ))
    image[i][j] = traceRay(model, dims, Vector3(x: 0, y: -10, z: -330), direction, getHitFunctions())
let t3 = now()
echo "Rendering took: ", inMilliseconds(t3 - t2), " ms"

# Start timing encoding
let t4 = now()
let qoiImage = encodeQOI(image)
let t5 = now()
echo "Image encoding took: ", inMilliseconds(t5 - t4), " ms"

# Save the file
writeFile("output.qoi", qoiImage)
echo "Total time: ", inMilliseconds(t5 - t0), " ms"


