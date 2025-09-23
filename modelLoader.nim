

import std/[strutils]
import helpers


proc loadBinvox(path: string): (tuple[x, y, z: int], seq[uint8]) =
    var dims: array[3, int]

    let f = open(path, fmRead)
    defer: f.close()

    # Parse ASCII header until "data"
    while true:
        if f.endOfFile():
            raise newException(IOError, "Unexpected EOF before 'data'")
        let line = f.readLine().strip()
        if line.len == 0: continue
        if line.startsWith("dim"):
            let parts = line.split()
            dims[0] = parseInt(parts[1])
            dims[1] = parseInt(parts[2])
            dims[2] = parseInt(parts[3])
        elif line == "data":
            break

    # Read the rest of the file as raw bytes
    let remaining = f.readAll()                     # returns a string
    let dataBytes = cast[seq[uint8]](remaining)    # reinterpret as bytes

    return ((dims[0], dims[1], dims[2]), dataBytes)

func getModel(dims: tuple[x, y, z: int], voxData: seq[uint8]) : SimpleModel=
    var
        i = 0
        output: SimpleModel = @[]
    for x in 0..<dims.x:
        output.add(@[])
        for z in 0..<dims.z:
            output[output.high].add(@[])
            for y in 0..<dims.y:
                output[output.high][output[output.high].high].add(voxData[i])
                i += 1
    return output

func raw(data: seq[uint8]): seq[uint8]=
    var
        output: seq[uint8] = @[]
        i = 0
    while i < data.high:
        for j in 0..<data[i+1].int:
            output.add(data[i])
        i+=2
    return output

func redimension(dims: tuple[x, y, z: int], inmodel: SimpleModel): SimpleModel=
    var outmodel : SimpleModel
    for x in 0..<dims.x:
        outmodel.add(@[])
        for y in 0..<dims.y:
            outmodel[outmodel.high].add(@[])
            for z in 0..<dims.z:
                outmodel[outmodel.high][outmodel[outmodel.high].high].add(inmodel[x][z][y])
    return outmodel


proc loadModel*(path: string) : tuple[dims: tuple[x, y, z: int], model: Model]=
    let
        (dimensions, voxData) = loadBinvox(path)
        voxModel = redimension(dimensions, getModel(dimensions, raw(voxData)))
    return (dims: dimensions, model: toModel(voxModel))



