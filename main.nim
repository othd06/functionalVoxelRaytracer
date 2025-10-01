

import weave
import math
import times

import helpers
import modelLoader
import materials
import raytracer
import qoiEncoder
#import pngEncoder2

# Start timing model loading
let t0 = now()
let (dims, model) = loadModel("dragon.binvox")
let t1 = now()
echo "Model loading took: ", inMilliseconds(t1 - t0), " ms"

# Prepare image buffer
var image: array[2560, array[1440, Colour]]

let hitFunctions = getHitFunctions()
let hitFuncs = addr hitFunctions

# Start timing rendering
let t2 = now()
init(Weave)
parallelFor i in 0..<2560:
  var col: array[1440, Colour]
  let colAdd: ptr array[1440, Colour] = addr col
  for j in 0..<1440:
    #let hitFunctions = getHitFunctions()

    var direction = normalise(Vector3(
      x: (i.float64 / 1279.5) - 1.0,
      y: (j.float64 / 1279.5) - (719.5 / 1279.5) - 0.2,
      z: 1.0
    ))
    let rotationMatrix: Matrix[3, 3] = [[1, 0             , 0              ],
                                        [0, cos(10*PI/180), -sin(10*PI/180)],
                                        [0, sin(10*PI/180),  cos(10*PI/180)]]
    colAdd[][j] = traceRay(model, dims, Vector3(x: 0, y: 150, z: -600), rotationMatrix*direction, hitFuncs, 0, inMilliseconds(now()-t0).int*i*j)
  for j in 0..<1440:
    image[i][j] = col[j]
exit(Weave)
let t3 = now()
echo "Rendering took: ", inMilliseconds(t3 - t2), " ms"

discard hitFunctions[0](model, dims, NORTH, Vector2(x: 0, y: 0), Vector3(x: 0, y: 0, z: 0), Vector3(x: 0, y: -1, z: 0), 0, 0)

# Start timing encoding
let t4 = now()
let qoiImage = encodeQOI(image)
let t5 = now()
echo "QOI Image encoding took: ", inMilliseconds(t5 - t4), " ms"

#let t6 = now()
#let pngImage = encodePNG(image)
#let t7 = now()
#echo "PNG Image encoding took: ", inMilliseconds(t7 - t6), " ms"

# Save the file
writeFile("output.qoi", qoiImage)
#writeFile("output.png", pngImage)
echo "Total time: ", inMilliseconds(t5 - t0), " ms"


