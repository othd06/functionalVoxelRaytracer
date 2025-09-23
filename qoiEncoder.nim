
import helpers


func encodeQOI*[W: static[int], H: static[int]](rawImage: array[W, array[H, Colour]]): seq[uint8]=
    let header: seq[uint8] = @[113.uint8, 111.uint8, 105.uint8, 102.uint8, uint8(W shr 24), uint8(W shr 16), uint8(W shr 8), uint8(W), uint8(H shr 24), uint8(H shr 16), uint8(H shr 8), uint8(H), 3.uint8, 0.uint8]

    var rawImageR : ref array[H, array[W, Colour]] = new array[H, array[W, Colour]]
    for y in 0..<H:
        for x in 0..<W:
            rawImageR[][H-1-y][x] = rawImage[x][y]

    let
        rawPixels = cast[ptr array[W*H, Colour]](rawImageR[].addr)
    
    var
        data : seq[uint8] = @[0xFE.uint8, rawPixels[][0].r, rawPixels[][0].g, rawPixels[][0].b]
        lastColour: Colour = rawPixels[][0]
        runLength: uint8 = 0
        pixelArray: array[64, Colour]
    pixelArray[(rawPixels[][0].r.int*3 + rawPixels[][0].g.int*5 + rawPixels[][0].b.int*7 + 255*11) mod 64] = rawPixels[][0]
    for i in 1..<(W*H):
        if rawPixels[][i] == lastColour:
            if runLength == 62:
                data.add(0b11111101)
                runLength = 1
            else:
                runLength += 1
            continue
        if runLength > 0:
            data.add(0b11000000 + (runLength-1))
            runLength = 0
        if pixelArray[(rawPixels[][i].r.int*3 + rawPixels[][i].g.int*5 + rawPixels[][i].b.int*7 + 255*11) mod 64] == rawPixels[][i]:
            data.add(((rawPixels[][i].r.int*3 + rawPixels[][i].g.int*5 + rawPixels[][i].b.int*7 + 255*11) mod 64).uint8)
            lastColour = rawPixels[][i]
            continue
        let
            dr: int = ((int(rawPixels[][i].r)-int(lastColour.r)+128) mod 256) - 128
            dg: int = ((int(rawPixels[][i].g)-int(lastColour.g)+128) mod 256) - 128
            db: int = ((int(rawPixels[][i].b)-int(lastColour.b)+128) mod 256) - 128
        if dr >= -2 and dr <= 1 and dg >= -2 and dg <= 1 and db >= -2 and db <= 1:
            data.add(0b01000000.uint8 + (((dr+2) mod 4) shl 4).uint8 + (((dg+2) mod 4) shl 2).uint8 + ((db+2) mod 4).uint8)
            pixelArray[(rawPixels[][i].r.int*3 + rawPixels[][i].g.int*5 + rawPixels[][i].b.int*7 + 255*11) mod 64] = rawPixels[][i]
            lastColour = rawPixels[][i]
            continue
        if dg >= -32 and dg <= 31 and (dr-dg) >= -8 and (dr-dg) <= 7 and (db-dg) >= -8 and (db-dg) <= 7:
            data.add(0b10000000.uint8 + ((dg+32) mod 64).uint8)
            data.add((((dr-dg+8) mod 16) shl 4).uint8 + ((db-dg+8) mod 16).uint8)
            pixelArray[(rawPixels[][i].r.int*3 + rawPixels[][i].g.int*5 + rawPixels[][i].b.int*7 + 255*11) mod 64] = rawPixels[][i]
            lastColour = rawPixels[][i]
            continue
        
        data.add(0b11111110)
        data.add(rawPixels[][i].r)
        data.add(rawPixels[][i].g)
        data.add(rawPixels[][i].b)
        lastColour = rawPixels[][i]
        pixelArray[(rawPixels[][i].r.int*3 + rawPixels[][i].g.int*5 + rawPixels[][i].b.int*7 + 255*11) mod 64] = rawPixels[][i]
        
    if runLength > 0:
        data.add(0b11000000 + (runLength-1))
        runLength = 0
    
    return header & data & @[0.uint8, 0.uint8, 0.uint8, 0.uint8, 0.uint8, 0.uint8, 0.uint8, 1.uint8]






