

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
    
    var model: seq[seq[seq[uint8]]] = newSeq[seq[seq[uint8]]](dims.x)

    for x in 0..<dims.x:
        model[x] = newSeq[seq[uint8]](dims.y)
        for y in 0..<dims.y:
            model[x][y] = newSeq[uint8](dims.z)
    
    for x in 0..<dims.x:
        for y in 0..<dims.y:
            for z in 0..<dims.z:
                model[x][y][z] = voxData[x*dims.z*dims.y + z*dims.y + y]
    return model

func raw(dims: tuple[x, y, z: int], data: seq[uint8]): seq[uint8]=
    var
        output: seq[uint8] = newSeq[uint8](dims.x*dims.y*dims.z)
        i = 0
        index = 0
    while i < data.high:
        for j in 0..<data[i+1].int:
            output[index] = data[i]
            index += 1
        i+=2
    return output


proc loadModel*(path: string) : tuple[dims: tuple[x, y, z: int], model: Model]=
    let
        (dimensions, voxData) = loadBinvox(path)
        voxModel = getModel(dimensions, raw(dimensions, voxData))
    return (dims: dimensions, model: toModel(voxModel))



