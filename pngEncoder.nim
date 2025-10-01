

import sequtils
import helpers

type
    Palette = ref array[256, Colour]
    Image8Bit[S: static[int]] = ref array[S, uint8]

func toSeq(p: Palette): seq[Colour]=
    result = @[]
    for i in 0..<256:
        result.add(p[i])

func isIndexed[S: static[int]](image: ref array[S, Colour]) : (bool, Palette, Image8Bit[S], int)=
    var
        colours: Palette
        indices: Image8Bit[S]
        paletteIndex: int = 0
    new(colours)
    new(indices)
    func getColour (col: Colour): int=
        for i in 0..<paletteIndex:
            if colours[i] == col: return i
        return -1
    for i in 0..<S:
        if (getColour(image[i]) >= 0): indices[i] = getColour(image[i]).uint8
        elif paletteIndex >= 256: return (false, colours, indices, 0)
        else: colours[paletteIndex] = image[i]; indices[i] = paletteIndex.uint8; paletteIndex += 1
    return (true, colours, indices, paletteIndex)

func isGreyscale[S: static[int]](image: ref array[S, Colour]) : tuple[isGreyscale: bool, image: Image8Bit[S]]=
    var
        outImage: Image8Bit[S]
    new(outImage)
    for i in 0..<S:
        if (image[i].r == image[i].g) and (image[i].r == image[i].b): outImage[i] = image[i].r
        else: return (false, outImage)
    return (true, outImage)

func minBitDepth[S: static[int]](image: Image8Bit[S]) : int=
    var min = 1
    for i in 0..<S:
        let
            bitDepth = if image[i] mod 255 == 0: 1
                        elif image[i] in @[0.uint8, 85.uint8, 170.uint8, 255.uint8]: 2
                        elif image[i] mod 17 == 0: 4
                        else: 8
        if bitDepth > min: min = bitDepth
        if min == 8: return min
    return min

func imageType(indexed, greyscale: bool, indexedDepth, greyscaleDepth: int): int=
    if indexed and not greyscale:
        return 3
    if greyscale and not indexed:
        return 0
    if not greyscale and not indexed:
        return 2
    if greyscale and indexed:
        if indexedDepth < greyscaleDepth:
            return 3
        return 0

func CRC(chunk: seq[uint8]): seq[uint8]=
    const crcConst: uint32 = 0xEDB88320.uint32
    let crcData = drop(4, chunk)
    var crcValue: uint32 = cast[uint32](-1)
    for i in crcData:
        crcValue = crcValue xor i.uint32
        for j in 0..<8:
            if (crcValue and 1.uint32) == 1.uint32:
                crcValue = (crcValue shr 1) xor crcConst
            else:
                crcValue = crcValue shr 1
    crcValue = not crcValue
    let crcFooter: seq[uint8] = @[((crcValue and 0xFF000000.uint32) shr 24).uint8, ((crcValue and 0x00FF0000.uint32) shr 16).uint8, ((crcValue and 0x0000FF00.uint32) shr 8).uint8, (crcValue and 0x000000FF.uint32).uint8]
    return chunk & crcFooter

func getColourLines[S: static[int]](image: ref array[S, Colour], width: int) : seq[seq[uint8]]=
    let height = S div width
    assert S == width*height
    var output: seq[seq[uint8]] = newSeq[seq[uint8]](height)
    for i in 0..<height:
        output[i] = @[]
        for j in 0..<width:
            output[i].add(image[i*width+j].r)
            output[i].add(image[i*width+j].g)
            output[i].add(image[i*width+j].b)
    return output

func to4bit(a: uint8): uint8 = (a.int / 17).uint8

func to2bit(a: uint8): uint8 =
    if a == 0.uint8:
        return 0.uint8
    elif a == 85.uint8:
        return 1.uint8
    elif a == 170.uint8:
        return 2.uint8
    else: 3.uint8

func to1bit(a: uint8): uint8 = a shr 7

func get8BitLines[S: static[int]](image: Image8Bit[S], width: int, bitDepth: uint8) : seq[seq[uint8]]=
    let height = S div width
    var output: seq[seq[uint8]] = newSeq[seq[uint8]](height)
    for i in 0..<height:
        output[i] = @[]
        for j in 0..<width:
            if bitDepth == 8:
                output[i].add(image[i*width+j])
            elif bitDepth == 4 and j mod 2 == 0:
                let newBit = if j<(width-1): (to4bit(image[i*width+j]) shl 4) or to4bit(image[i*width+j+1])
                                       else: (to4bit(image[i*width+j]) shl 4)
                output[i].add(newBit)
            elif bitDepth == 2 and j mod 4 == 0:
                let newBit = if j<(width-3): (to2bit(image[i*width+j]) shl 6) or (to2bit(image[i*width+j+1]) shl 4) or (to2bit(image[i*width+j+2]) shl 2) or to2bit(image[i*width+j+3])
                           elif j<(width-2): (to2bit(image[i*width+j]) shl 6) or (to2bit(image[i*width+j+1]) shl 4) or (to2bit(image[i*width+j+2]) shl 2)
                           elif j<(width-1): (to2bit(image[i*width+j]) shl 6) or (to2bit(image[i*width+j+1]) shl 4)
                                       else: (to2bit(image[i*width+j]) shl 6)
                output[i].add(newBit)
            elif bitDepth == 1 and j mod 8 == 0:
                let newBit = if j<(width-7): (to1bit(image[i*width+j]) shl 7) or (to1bit(image[i*width+j+1]) shl 6) or (to1bit(image[i*width+j+2]) shl 5) or (to1bit(image[i*width+j+3]) shl 4) or (to1bit(image[i*width+j+4]) shl 3) or (to1bit(image[i*width+j+5]) shl 2) or (to1bit(image[i*width+j+6]) shl 1) or to1bit(image[i*width+j+7])
                           elif j<(width-6): (to1bit(image[i*width+j]) shl 7) or (to1bit(image[i*width+j+1]) shl 6) or (to1bit(image[i*width+j+2]) shl 5) or (to1bit(image[i*width+j+3]) shl 4) or (to1bit(image[i*width+j+4]) shl 3) or (to1bit(image[i*width+j+5]) shl 2) or (to1bit(image[i*width+j+6]) shl 1)
                           elif j<(width-5): (to1bit(image[i*width+j]) shl 7) or (to1bit(image[i*width+j+1]) shl 6) or (to1bit(image[i*width+j+2]) shl 5) or (to1bit(image[i*width+j+3]) shl 4) or (to1bit(image[i*width+j+4]) shl 3) or (to1bit(image[i*width+j+5]) shl 2)
                           elif j<(width-4): (to1bit(image[i*width+j]) shl 7) or (to1bit(image[i*width+j+1]) shl 6) or (to1bit(image[i*width+j+2]) shl 5) or (to1bit(image[i*width+j+3]) shl 4) or (to1bit(image[i*width+j+4]) shl 3)
                           elif j<(width-3): (to1bit(image[i*width+j]) shl 7) or (to1bit(image[i*width+j+1]) shl 6) or (to1bit(image[i*width+j+2]) shl 5) or (to1bit(image[i*width+j+3]) shl 4)
                           elif j<(width-2): (to1bit(image[i*width+j]) shl 7) or (to1bit(image[i*width+j+1]) shl 6) or (to1bit(image[i*width+j+2]) shl 5)
                           elif j<(width-1): (to1bit(image[i*width+j]) shl 7) or (to1bit(image[i*width+j+1]) shl 6)
                                       else: (to1bit(image[i*width+j]) shl 7)
                output[i].add(newBit)
    return output

func filterScanlines(scanlines: seq[seq[uint8]], bpp: int): seq[seq[uint8]]=
    func paethPredictor(a, b, c: uint8): uint8=
        let
            p = a.int+b.int-c.int
            pa = abs((p-a.int))
            pb = abs((p-b.int))
            pc = abs((p-c.int))
        if pa < pb and pa < pc: return a
        elif pb < pc: return b
        else: return c
    func minSumAbsDiff(a: seq[uint8]): int=
        for i in a:
            result += cast[int8](i).int
    
    result = @[]

    if bpp == 0:
        return scanlines.map(func(s: seq[uint8]): seq[uint8] = @[0.uint8] & s)
    else:
        for i in 0..scanlines.high:
            let
                above: seq[uint8] = if i == 0: newSeq[uint8](scanlines[i].len())
                                         else: scanlines[i-1]
                prev: seq[uint8] = take(scanlines[i].len(), newSeq[uint8](bpp) & scanlines[i])
                abovePrev: seq[uint8] = take(scanlines[i].len(), newSeq[uint8](bpp) & above)
                NONE: seq[uint8] = scanlines[i]
                SUB: seq[uint8] = scanlines[i].sub(prev)
                UP: seq[uint8] = scanlines[i].sub(above)
                AVG: seq[uint8] = scanlines[i].sub(prev.mapG(func(a: uint8): int = a.int).sum(above.mapG(func(a: uint8): int = a.int)).mapG(func(a: int): uint8 = (a shr 1).uint8))
                PAETH: seq[uint8] = scanlines[i].sub(map3(above, prev, abovePrev, paethPredictor))

                scoreNONE = minSumAbsDiff(NONE)
                scoreSUB = minSumAbsDiff(SUB)
                scoreUP = minSumAbsDiff(UP)
                scoreAVG = minSumAbsDiff(AVG)
                scorePAETH = minSumAbsDiff(PAETH)
            if scoreNONE <= scoreSUB and scoreNONE <= scoreUP and scoreNONE <= scoreAVG and scoreNONE <= scorePAETH:
                result.add(@[0.uint8] & NONE)
            elif scoreSUB <= scoreUP and scoreSUB <= scoreAVG and scoreSUB <= scorePAETH:
                result.add(@[1.uint8] & SUB)
            elif scoreUP <= scoreAVG and scoreUP <= scorePAETH:
                result.add(@[2.uint8] & UP)
            elif scoreAVG <= scorePAETH:
                result.add(@[3.uint8] & AVG)
            else:
                result.add(@[4.uint8] & PAETH)
    return result

func appendScanlines(scanlines: seq[seq[uint8]]): seq[uint8]=
    var output: seq[uint8] = newSeq[uint8](scanlines.len()*scanlines[0].len())
    for i in 0..scanlines.high:
        for j in 0..scanlines[i].high:
            output[i*scanlines[0].len()+j] = scanlines[i][j]
    return output

func adler32(data: seq[uint8]): seq[uint8]=
    var
        s1: uint64 = 1
        s2: uint64 = 0
    for i in 0..<data.len():
        s1 = (s1 + data[i].uint64)
        s2 = (s2 + s1)
        if s1 > 1.uint64 shl 60:
            s1 = s1 mod 65521
        if s2 > 1.uint64 shl 60:
            s2 = s2 mod 65521
    s1 = s1 mod 65521
    s2 = s2 mod 65521
    return @[uint8((s2 shr 8) and 0xFF), uint8(s2 and 0xFF), uint8((s1 shr 8) and 0xFF), uint8(s1 and 0xFF)]

type lz77Entry = tuple[isLit: bool, litLen: uint16, dist: uint16]

func lz77(data: seq[uint8]): seq[lz77Entry]=
    var
        windowAndLookAhead: seq[uint8] = newSeq[uint8](32768+305)
        dataIndex: int = 300
    result = @[]
    for i in 0..<300:
        windowAndLookAhead[32768+i] = data[i]
    while dataIndex < data.len()+300:
        #work out if there is a valid len/distance pair
        var
            longestLen: uint16 = 0
            longestLenDist: uint16 = 0
        if dataIndex > 302:
            for i in 1..(min(32768, dataIndex-301)):
                let dist = i.uint16
                var len: int = 0
                while windowAndLookAhead[32768-i+len] == windowAndLookAhead[32768+len] and len < 258:
                    len += 1
                if len > longestLen.int:
                    longestLen = len.uint16
                    longestLenDist = dist
                if longestLen == 258:
                    break
        #if the pair is of long enough len, emit, otherwise emit literal
        if longestLen >= 3:
            result.add((false, longestLen, longestLenDist))
        else:
            result.add((true, windowAndLookAhead[32768].uint16, 0.uint16))
        #drop len bytes from the windowAndLookAhead buffer then add len entries from data starting at index (and increment index by len)
        var newData: seq[uint8] = @[]
        if longestLen < 3:
            if dataIndex < data.len():
                newData = @[data[dataIndex]]
            else:
                newData = @[0.uint8]
            dataIndex += 1
            windowAndLookAhead = drop(1, windowAndLookAhead) & newData
        else:
            for i in 0..<longestLen.int:
                if dataIndex+i.int<data.len():
                    newData.add(data[dataIndex+i.int])
                else:
                    newData.add(0.uint8)
            dataIndex += longestLen.int
            windowAndLookAhead = drop(longestLen.int, windowAndLookAhead) & newData
    return result

proc deflate(data: seq[uint8]): seq[uint8]=
    #window size: 32768
    let lz77Data: seq[lz77Entry] = lz77(data) & @[(true, 256.uint16, 0.uint16)]

    func getBits(bits, number: int): seq[bool]=
        result = @[]
        for i in 0..<bits:
            result.add(((number shr i) and 1) == 1)
        result = result.reverse()

    func litLenMapping(litLen: int): (int, seq[bool])=
        if litLen <= 256:
            return (litLen, @[])
        elif litLen.inRange(256+3, 256+10):
            return (litLen-2, @[])
        elif litLen.inRange(256+11, 256+12):
            return (265, @[litLen mod 2 == 0])
        elif litLen.inRange(256+13, 256+14):
            return (266, @[litLen mod 2 == 0])
        elif litLen.inRange(256+15, 256+16):
            return (267, @[litLen mod 2 == 0])
        elif litLen.inRange(256+17, 256+18):
            return (268, @[litLen mod 2 == 0])
        elif litLen.inRange(256+19, 256+22):
            return (269, getBits(2, litLen-(256+19)))
        elif litLen.inRange(256+23, 256+26):
            return (270, getBits(2, litLen-(256+23)))
        elif litLen.inRange(256+27, 256+30):
            return (271, getBits(2, litLen-(256+27)))
        elif litLen.inRange(256+31, 256+34):
            return (272, getBits(2, litLen-(256+31)))
        elif litLen.inRange(256+35, 256+42):
            return (273, getBits(3, litLen-(256+35)))
        elif litLen.inRange(256+43, 256+50):
            return (274, getBits(3, litLen-(256+43)))
        elif litLen.inRange(256+51, 256+58):
            return (275, getBits(3, litLen-(256+51)))
        elif litLen.inRange(256+59, 256+66):
            return (276, getBits(3, litLen-(256+59)))
        elif litLen.inRange(256+67, 256+82):
            return (277, getBits(4, litLen-(256+67)))
        elif litLen.inRange(256+83, 256+98):
            return (278, getBits(4, litLen-(256+83)))
        elif litLen.inRange(256+99, 256+114):
            return (279, getBits(4, litLen-(256+99)))
        elif litLen.inRange(256+115, 256+130):
            return (280, getBits(4, litLen-(256+115)))
        elif litLen.inRange(256+131, 256+162):
            return (281, getBits(5, litLen-(256+131)))
        elif litLen.inRange(256+163, 256+194):
            return (282, getBits(5, litLen-(256+163)))
        elif litLen.inRange(256+195, 256+226):
            return (283, getBits(5, litLen-(256+195)))
        elif litLen.inRange(256+227, 256+257):
            return (284, getBits(5, litLen-(256+227)))
        else:
            return (285, @[])

    func distMapping(dist: int): (int, seq[bool])=
        if dist.inRange(1, 4):
            return (dist-1, @[])
        elif dist.inRange(5, 6):
            return (4, getBits(1, dist-5))
        elif dist.inRange(7, 8):
            return (5, getBits(1, dist-7))
        elif dist.inRange(9, 12):
            return (6, getBits(2, dist-9))
        elif dist.inRange(13, 16):
            return (7, getBits(2, dist-13))
        elif dist.inRange(17, 24):
            return (8, getBits(3, dist-17))
        elif dist.inRange(25, 32):
            return (9, getBits(3, dist-25))
        elif dist.inRange(33, 48):
            return (10, getBits(4, dist-33))
        elif dist.inRange(49, 64):
            return (11, getBits(4, dist-49))
        elif dist.inRange(65, 96):
            return (12, getBits(5, dist-65))
        elif dist.inRange(97, 128):
            return (13, getBits(5, dist-97))
        elif dist.inRange(129, 192):
            return (14, getBits(6, dist-129))
        elif dist.inRange(193, 256):
            return (15, getBits(6, dist-193))
        elif dist.inRange(257, 384):
            return (16, getBits(7, dist-257))
        elif dist.inRange(385, 512):
            return (17, getBits(7, dist-385))
        elif dist.inRange(513, 768):
            return (18, getBits(8, dist-513))
        elif dist.inRange(769, 1024):
            return (19, getBits(8, dist-769))
        elif dist.inRange(1025, 1536):
            return (20, getBits(9, dist-1025))
        elif dist.inRange(1537, 2048):
            return (21, getBits(9, dist-1537))
        elif dist.inRange(2049, 3072):
            return (22, getBits(10, dist-2049))
        elif dist.inRange(3073, 4096):
            return (23, getBits(10, dist-3073))
        elif dist.inRange(4097, 6144):
            return (24, getBits(11, dist-4097))
        elif dist.inRange(6145, 8192):
            return (25, getBits(11, dist-6145))
        elif dist.inRange(8193, 12288):
            return (26, getBits(12, dist-8193))
        elif dist.inRange(12289, 16384):
            return (27, getBits(12, dist-12289))
        elif dist.inRange(16385, 24576):
            return (28, getBits(13, dist-16385))
        elif dist.inRange(24577, 32768):
            return (29, getBits(13, dist-24577))
    
    func huffmanDepths[T: static[int]](frequencies: array[T, int]): array[T, int]=
        type
            huffmanNode= tuple[frequency: int, indices: seq[int]]
        
        var
            output: array[T, int]
            nodes: seq[huffmanNode]
            inOutput: array[T, bool]
        for i in 0..<T:
            output[i] = 0
            inOutput[i] = frequencies[i] == 0
            if not inOutput[i]:
                nodes.add((frequencies[i], @[i]))
        if nodes.len() <= 1:
            if nodes.len() == 1:
                output[nodes[0].indices[0]] = 1
            return output
        nodes = nodes.quicksort(func(x, y: huffmanNode): bool = x.frequency > y.frequency)
        while nodes.len() >= 2:
            let newNode = (nodes[0].frequency+nodes[1].frequency, nodes[0].indices&nodes[1].indices)
            for i in newNode[1]:
                inOutput[i] = true
                output[i] += 1
            nodes = drop(2, nodes).insertOrdered(newNode, func(x, y: huffmanNode): bool = x.frequency > y.frequency)
        return output

    func huffmanDepthsSeq(frequencies: seq[int]): seq[int]=
        type
            huffmanNode = tuple[frequency: int, indices: seq[int]]
        
        var
            output: seq[int] = newSeq[int](frequencies.len())
            nodes: seq[huffmanNode]
            inOutput: seq[bool] = newSeq[bool](frequencies.len())
        for i in 0..<frequencies.len():
            output[i] = 0
            inOutput[i] = frequencies[i] == 0
            if not inOutput[i]:
                nodes.add((frequencies[i], @[i]))
        if nodes.len() <= 1:
            if nodes.len() == 1:
                output[nodes[0].indices[0]] = 1
            return output
        nodes = nodes.quicksort(func(x, y: huffmanNode): bool = x.frequency > y.frequency)
        while nodes.len() >= 2:
            let newNode = (nodes[0].frequency+nodes[1].frequency, nodes[0].indices&nodes[1].indices)
            for i in newNode[1]:
                inOutput[i] = true
                output[i] += 1
            nodes = drop(2, nodes).insertOrdered(newNode, func(x, y: huffmanNode): bool = x.frequency > y.frequency)
        return output

    func adjustDepths[T: static[int]](huffmanDepths: array[T, int], maxDepth: int): array[T, int]=
        var
            max = 0
            nodesOverDepth: seq[int] = @[]
            nodesUnderDepth: seq[int] = @[]
            nodesAtDepth: seq[int] = @[]
            nonLeavesAtMaxDepth: int = 1 shl maxDepth
            output: array[T, int] = huffmanDepths
        for i in 0..<T:
            if output[i] > max:
                max = output[i]
            if output[i] == 0:
                discard
            elif output[i] < maxDepth:
                nodesUnderDepth.add(i)
                nonLeavesAtMaxDepth -= 1 shl (maxDepth - output[i])
            elif output[i] > maxDepth:
                nodesOverDepth.add(i)
            else:
                nodesAtDepth.add(i)
                nonLeavesAtMaxDepth -= 1
        if max <= maxDepth: return huffmanDepths

        while nodesOverDepth.len() > 0:
            if nodesOverDepth.len() <= nonLeavesAtMaxDepth:
                for i in nodesOverDepth:
                    output[i] = maxDepth
                nodesOverDepth = @[]
                continue
            let newDepth = output[nodesUnderDepth[nodesUnderDepth.high]]+1
            output[nodesUnderDepth[nodesUnderDepth.high]] = newDepth
            output[nodesOverDepth[nodesOverDepth.high]] = maxDepth
            output[nodesAtDepth[0]] = newDepth
            if newDepth == maxDepth:
                nodesAtDepth = @[nodesUnderDepth[nodesUnderDepth.high]] & nodesAtDepth
                nodesUnderDepth.delete(nodesUnderDepth.high)
            else:
                nodesUnderDepth.add(nodesAtDepth[0])
                nodesAtDepth.delete(0)
            nodesAtDepth.add(nodesOverDepth[nodesOverDepth.high])
            nodesOverDepth.delete(nodesOverDepth.high)
        return output

    func adjustDepths(huffmanDepths: seq[int], maxDepth: int): seq[int]=
        var
            max = 0
            nodesOverDepth: seq[int] = @[]
            nodesUnderDepth: seq[int] = @[]
            nodesAtDepth: seq[int] = @[]
            nonLeavesAtMaxDepth: int = 1 shl maxDepth
            output: seq[int] = huffmanDepths
        for i in 0..<huffmanDepths.len():
            if output[i] > max:
                max = output[i]
            if output[i] == 0:
                discard
            elif output[i] < maxDepth:
                nodesUnderDepth.add(i)
                nonLeavesAtMaxDepth -= 1 shl (maxDepth - output[i])
            elif output[i] > maxDepth:
                nodesOverDepth.add(i)
            else:
                nodesAtDepth.add(i)
                nonLeavesAtMaxDepth -= 1
        if max <= maxDepth: return huffmanDepths

        while nodesOverDepth.len() > 0:
            if nodesOverDepth.len() <= nonLeavesAtMaxDepth:
                for i in nodesOverDepth:
                    output[i] = maxDepth
                nodesOverDepth = @[]
                continue
            let newDepth = output[nodesUnderDepth[nodesUnderDepth.high]]+1
            output[nodesUnderDepth[nodesUnderDepth.high]] = newDepth
            output[nodesOverDepth[nodesOverDepth.high]] = maxDepth
            output[nodesAtDepth[0]] = newDepth
            if newDepth == maxDepth:
                nodesAtDepth = @[nodesUnderDepth[nodesUnderDepth.high]] & nodesAtDepth
                nodesUnderDepth.delete(nodesUnderDepth.high)
            else:
                nodesUnderDepth.add(nodesAtDepth[0])
                nodesAtDepth.delete(0)
            nodesAtDepth.add(nodesOverDepth[nodesOverDepth.high])
            nodesOverDepth.delete(nodesOverDepth.high)
        return output

    func generateHuffman[T: static[int]](huffmanDepths: array[T, int], maxDepth: int): array[T, seq[bool]]=
        var
            output: array[T, seq[bool]]
            code: int = 0
            blCount: seq[int] = newSeq[int](maxDepth+1)
            nextCode: seq[int] = newSeq[int](maxDepth+1)
        for i in 0..<T:
            output[i] = @[]
            if huffmanDepths[i] == 0: continue
            blCount[huffmanDepths[i]] += 1
        for i in 1..maxDepth:
            code = (code + blCount[i-1]) shl 1
            nextCode[i] = code
        for i in 0..<T:
            if huffmanDepths[i] != 0:
                output[i] = getBits(huffmanDepths[i], nextCode[huffmanDepths[i]])
                nextCode[huffmanDepths[i]] += 1
    
    func generateHuffmanSeq(huffmanDepths: seq[int], maxDepth: int): seq[seq[bool]]=
        var
            output: seq[seq[bool]]
            code: int = 0
            blCount: seq[int] = newSeq[int](maxDepth+1)
            nextCode: seq[int] = newSeq[int](maxDepth+1)
        for i in 0..<huffmanDepths.len():
            output.add(@[])
            output[i] = @[]
            if huffmanDepths[i] == 0: continue
            blCount[huffmanDepths[i]] += 1
        for i in 1..maxDepth:
            code = (code + blCount[i-1]) shl 1
            nextCode[i] = code
        for i in 0..<huffmanDepths.len():
            if huffmanDepths[i] != 0:
                output[i] = getBits(huffmanDepths[i], nextCode[huffmanDepths[i]])
                nextCode[huffmanDepths[i]] += 1
        return output

    func maxNonZero[T: static[int]](a: array[T, int]): int=
        result = 0
        for i in 0..<T:
            if a[i] != 0:
                result = i+1

    func maxNonZero(a: seq[int]): int=
        result = 0
        for i in 0..<a.len():
            if a[i] != 0:
                result = i+1

    func appendArray[T, U: static[int], V](a: array[T, V], b: array[U, V]): array[T+U, V]=
        var output: array[T+U, V]
        for i in 0..<T:
            output[i] = a[i]
        for i in 0..<U:
            output[T+i] = b[i]
        return output

    func codeLenCompress(lens: seq[int]): seq[(int, seq[bool])]=
        result = @[]
        var
            run0s: int
            runLast: int = 0
            last: int
        for i in 0..<lens.len():
            if lens[i] == last:
                runLast += 1
                if runLast == 6:
                    result.add((16, @[true, true]))
                    runLast = 1
                continue
            if runLast == 2:
                result.add((last, @[]))
                result.add((last, @[]))
                runLast = 0
            elif runLast > 2:
                result.add((last, getBits(2, (runLast-3))))
            
            if lens[i] == 0:
                run0s += 1
                if run0s == 138:
                    result.add((18, @[true, true, true, true, true, true, true]))
                continue
            if run0s == 0:
                discard
            elif run0s == 1:
                result.add((0, @[]))
            elif run0s == 2:
                result.add((0, @[]))
                result.add((0, @[]))
            elif run0s <= 10:
                result.add((17, getBits(3, (run0s-3))))
            else:
                result.add((18, getBits(7, (run0s-11))))

            result.add((lens[i], @[]))

            last = lens[i]
        return result

    func reOrderLens[T](lens: seq[T]): seq[T]=
        assert lens.len() == 19
        return @[lens[16], lens[17], lens[18], lens[0], lens[8], lens[7], lens[9], lens[6], lens[10], lens[5], lens[11], lens[4], lens[12], lens[3], lens[13], lens[2], lens[14], lens[1], lens[15]]

    var
        frequenciesLitLen: array[286, int]
        frequenciesDist: array[30, int]
    for i in lz77Data:
        if not i.isLit:
            frequenciesDist[i.dist.int().distMapping()[0]] += 1
            frequenciesLitLen[(i.litLen+256).int().litLenMapping()[0]] += 1
        else:
            frequenciesLitLen[i.litLen.int().litLenMapping()[0]] += 1
    let
        litLenDepths: seq[int] = huffmanDepthsSeq(frequenciesLitLen.arrToSeq()).adjustDepths(15)
        distDepths: array[30, int] = huffmanDepths(frequenciesDist).adjustDepths(15)
        HLIT: seq[bool] = getBits(5, (max(257, maxNonZero(litLenDepths))-257)).reverse()
        hlit: int = max(257, maxNonZero(litLenDepths))
    echo HLIT
    echo hlit
    let
        HDIST: seq[bool] = getBits(5, (max(1, maxNonZero(distDepths))-1)).reverse()
        hdist: int = max(1, maxNonZero(distDepths))
    echo HDIST
    echo hdist
    let
        litLenHuffman: seq[seq[bool]] = litLenDepths.generateHuffmanSeq(15)
        distHuffman: array[30, seq[bool]] = distDepths.generateHuffman(15)
        codeLensSeq: seq[(int, seq[bool])] = (take(hlit, litLenDepths) & take(hdist, distDepths.arrToSeq())).codeLenCompress()
        codeLens: seq[int] = codeLensSeq.map(func(x: (int, seq[bool])): int = x[0])
    var
        codeLensFrequencies: seq[int] = newSeq[int](19)
    for i in codeLens:
        codeLensFrequencies[i] += 1
    let
        codeLensDepths: seq[int] = huffmanDepthsSeq(codeLensFrequencies).adjustDepths(7)
        codeLensHuffman: seq[seq[bool]] = codeLensDepths.generateHuffmanSeq(7)
        HCLEN = getBits(4, (max(4, maxNonZero(codeLensDepths.reOrderLens()))-4)).reverse()
        hclen = max(4, maxNonZero(codeLensDepths.reOrderLens()))
    echo HCLEN
    echo hclen
    let
        section4: seq[bool] = take(hclen, codeLensDepths.reOrderLens().mapG(func (x: int): seq[bool] = getBits(3, x).reverse())).promoteSeqs()
    echo codeLensDepths.reOrderLens()
    for i in 0..18:
        echo $i & ": " & $codeLensDepths.generateHuffmanSeq(15)[i]
    #echo codeLensDepths.reOrderLens().mapG(func (x: int): seq[bool] = getBits(3, x))
    echo section4
    #quit(1)
    
    let
        section5: seq[bool] = take(hlit, litLenDepths.map(func (x: int): seq[bool] = codeLensHuffman[x])).promoteSeqs()
    var litLenI: int = -1
    echo litLenDepths.toSeq().mapGsideEffects(proc (x: int): (int, int) = litLenI += 1; return((litLenI, x)))
    #echo hlit
    #echo litLenDepths.len()
    #echo litLenDepths.arrToSeq().map(func (x: int): seq[bool] = codeLensHuffman[x])
    #echo section5
    let
        section6: seq[bool] = take(hdist, distDepths.arrToSeq().map(func (x: int): seq[bool] = codeLensHuffman[x])).promoteSeqs()
    var distI: int = -1
    echo distDepths.toSeq().mapGsideEffects(proc (x: int): (int, int) = distI += 1; return((distI, x)))


    func mapLZ77(dataEntry: lz77Entry): seq[bool]=
        if dataEntry.isLit:
            return litLenHuffman[dataEntry.litLen]
        else:
            result.add(litLenHuffman[litLenMapping(dataEntry.litLen.int + 256)[0]])
            result.add(litLenMapping(dataEntry.litLen.int + 256)[1])
            result.add(distHuffman[distMapping(dataEntry.dist.int)[0]])
            result.add(distMapping(dataEntry.dist.int)[1])

    let
        data: seq[bool] = lz77Data.map(func(x: lz77Entry): seq[bool]= mapLZ77(x)).promoteSeqs()
    echo "lz77Data: "
    for i in lz77Data.runLengthEncode():
        echo i
    #echo lz77Data.filter(func(x: lz77Entry): bool = x.dist > 32000)
    

    
    

    let blck: seq[bool] = @[true, false, true] & HLIT & HDIST & HCLEN & section4 & section5 & section6 & data
    var output: seq[uint8]
    for i in 0..<(blck.len() shr 3):
        let index = i*8
        var bits: array[8, bool]
        for j in 0..<8:
            if index+j < blck.len():
                bits[j] = blck[index+j]
            else:
                bits[i] = false
        var newByte : uint8 = 0.uint8
        if bits[7]: newByte += 1.uint8
        if bits[6]: newByte += 2.uint8
        if bits[5]: newByte += 4.uint8
        if bits[4]: newByte += 8.uint8
        if bits[3]: newByte += 16.uint8
        if bits[2]: newByte += 32.uint8
        if bits[1]: newByte += 64.uint8
        if bits[0]: newByte += 128.uint8
        output.add(newByte)
    return output



proc lenByte(a: seq[uint8]): seq[uint8]=
    let aLen: int = len(a) - 4
    #echo a
    #echo alen
    @[(aLen shr 24).uint8, ((aLen shr 16) mod 256).uint8, ((aLen shr 8) mod 256).uint8, (aLen mod 256).uint8] & a

proc reverseUint8(a: uint8): uint8=
    var input: uint8 = a
    var output: uint8 = 0
    for i in 0..<8:
        output = output shl 1
        output += input and 1
        input = input shr 1
    return output

proc encodePNG*[W: static[int], H: static[int]](rawImage: array[W, array[H, Colour]]): seq[uint8]=
    let header: seq[uint8] = @[0x89.uint8, 0x50.uint8, 0x4E.uint8, 0x47.uint8, 0x0D.uint8, 0x0A.uint8, 0x1A.uint8, 0x0A.uint8]
    var rawImageR : ref array[H, array[W, Colour]] = new array[H, array[W, Colour]]
    for y in 0..<H:
        for x in 0..<W:
            rawImageR[H-1-y][x] = rawImage[x][y]

    let
        rawPixels = cast[ref array[W*H, Colour]](rawImageR[0].addr)
        (indexed, palette, indexedPixels, paletteSize) = isIndexed(rawPixels)
        bitDepthIndexed: int = if paletteSize <= 2: 1
                             elif paletteSize <= 4: 2
                             elif paletteSize <= 16: 4
                               else: 8
        (greyscale, greyScaleImage) = isGreyscale(rawPixels)
        bitDepthGreyScale: int = if greyScale: minBitDepth(greyScaleImage)
                                 else: 8
        pngImageType: uint8 = imageType(indexed, greyscale, bitDepthIndexed, bitDepthGreyScale).uint8
        bitDepth: uint8 = if pngImageType == 0.uint8: bitDepthGreyScale.uint8
                        elif pngImageType == 3.uint8: bitDepthIndexed.uint8
                        else: 8
        unfilteredScanlines: seq[seq[uint8]] = if pngImageType == 2: getColourLines(rawPixels, W)
                                   elif pngImageType == 0: get8BitLines(greyScaleImage, W, bitDepth)
                                     else: get8BitLines(indexedPixels, W, bitDepth)
        bytesPerPixel: int = if pngImageType == 2: 3
                                             else: 1
        filteredScanlines = filterScanlines(unfilteredScanlines, bytesPerPixel)
        rawFilteredPixels: seq[uint8] = appendScanlines(filteredScanlines)
        deflateStream: seq[uint8] = deflate(rawFilteredPixels).map(reverseUint8)
        zlibStream: seq[uint8] = @[0b01111000.uint8, 0b11011010] & deflateStream & adler32(rawFilteredPixels)
        IHDR: seq[uint8] = CRC(lenByte(@[0x49.uint8, 0x48.uint8, 0x44.uint8, 0x52.uint8] & @[(W shr 24).uint8, ((W shr 16) mod 256).uint8, ((W shr 8) mod 256).uint8, (W mod 256).uint8] & @[(H shr 24).uint8, ((H shr 16) mod 256).uint8, ((H shr 8) mod 256).uint8, (H mod 256).uint8] & @[bitDepth] & @[pngImageType] & @[0.uint8] & @[0.uint8] & @[0.uint8]))
        sRGB: seq[uint8] = CRC(lenByte(@[0x73.uint8, 0x52.uint8, 0x47.uint8, 0x42.uint8] & @[0.uint8]))
        PLTE: seq[uint8] = if pngImageType == 3: CRC(lenByte(@[0x50.uint8,  0x4C.uint8,  0x54.uint8,  0x45.uint8] & take(paletteSize, palette.toSeq()).map(func(x: Colour): seq[uint8] = @[x.r, x.g, x.b]).promoteSeqs()))
                           else: @[] #correct
        IDAT: seq[uint8] = CRC(lenByte(@[0x49.uint8, 0x44.uint8, 0x41.uint8, 0x54.uint8] & zlibStream))
        IEND: seq[uint8] = CRC(lenByte(@[0x49.uint8, 0x45.uint8, 0x4E.uint8, 0x44.uint8]))
    
    return header & IHDR & sRGB & PLTE & IDAT & IEND
        





