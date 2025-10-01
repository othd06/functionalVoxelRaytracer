
import helpers


var stbi_write_force_png_filter: int = -1
var stbi_write_png_compression_level: int = 8
const stbi_flip_vertically_on_write = false
const stbiw_ZHASH = 16384

type
  HuffCode = tuple[code: int, nbits: int]

var litlenTable = newSeq[HuffCode](288)  # 0..287
var distTable   = newSeq[HuffCode](32)   # 0..31 (only 0..29 used)

# Fill literal/length codes
for sym in 0..143:
  litlenTable[sym] = (sym + 48, 8)
for sym in 144..255:
  litlenTable[sym] = (sym - 144 + 400, 9)
for sym in 256..279:
  litlenTable[sym] = (sym - 256, 7)
for sym in 280..287:
  litlenTable[sym] = (sym - 280 + 192, 8)

# Fill distance codes (5 bits each)
for sym in 0..29:
  distTable[sym] = (sym, 5)


proc seqmove[T](index: var int, dest: var seq[T], src: seq[T], length: int = src.len()) =
    for i in 0..<length:
        dest[index] = src[i]
        index += 1

proc seqmoveR[T](index: var int, dest: var seq[T], src: seq[T], length: int = src.len()) =
    for i in 0..<length:
        dest[i] = src[index]
        index += 1

proc wp32(index: var int, dest: var seq[uint8], src: uint32)=
    dest[index] = (src shr 24).uint8
    dest[index+1] = ((src shr 16) mod 256).uint8
    dest[index+2] = ((src shr 8) mod 256).uint8
    dest[index+3] = (src mod 256).uint8
    index += 4

proc incWrite[T](index: var int, dest: var seq[T], src: T)=
    dest[index] = src
    index += 1

proc wptag(index: var int, dest: var seq[uint8], src: string)=
    for i in src:
        dest[index] = cast[uint8](i)
        index += 1

func CRC(crcData: seq[uint8]): uint32=
    const crcConst: uint32 = 0xEDB88320.uint32
    var crcValue: uint32 = cast[uint32](-1)
    for i in crcData:
        crcValue = crcValue xor i.uint32
        for j in 0..<8:
            if (crcValue and 1.uint32) == 1.uint32:
                crcValue = (crcValue shr 1) xor crcConst
            else:
                crcValue = crcValue shr 1
    crcValue = not crcValue
    return crcValue

proc crc32(index: int, buffer: seq[uint8], len: int): uint32=
    var crcSeq: seq[uint8] = newSeq[uint8](len)
    for i in 0..<len:
        crcSeq[i] = buffer[index+i]
    return CRC(crcSeq)

proc wpcrc(index: var int, data: var seq[uint8], len: int)=
    let crc = crc32(index - len - 4, data, len+4)
    wp32(index, data, crc)

proc zlib_add_bit(output: var seq[uint8], bit: uint8, bitpos: var uint8)=
    assert(bit == 0 or bit == 1)
    if bitpos == 0:
        output.add(bit)
    else:
        output[output.high] = output[output.high] or (bit shl bitpos)
    bitpos += 1
    if bitpos == 8:
        bitpos = 0

proc zlib_add_bits(output: var seq[uint8], a, b: int, bitpos: var uint8)=
    for i in 0..<b.int:
        zlib_add_bit(output, ((a shr i) and 1).uint8, bitpos)

func `^=`(a: var uint32, b: uint32)=
    a = a xor b

proc zhash(data: seq[uint8], index: int): uint32=
    var hash: uint32 = data[index] + (data[index+1] shl 8) + (data[index+2] shl 16);
    hash ^= hash shl 3
    hash += hash shr 5
    hash ^= hash shl 4
    hash += hash shr 17
    hash ^= hash shl 25
    hash += hash shr 6
    return hash

proc countm(data: seq[uint8], i: int, j: int): int=
    var c: int = 0
    while (j+c) < data.len() and c < 258 and data[i+c] == data[j+c]:
        inc(c)
    return c

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

proc stbi_zlib_compress(data: seq[uint8], quality: var int): seq[uint8]=
    var output: seq[uint8] = @[0x78, 0x5e]
    var j = 0
    while j < data.len():
        var blockLen = data.len() - j
        if blockLen > 32767: blockLen = 32767
        output.add(if data.len() - j == blockLen: 1 else: 0)
        output.add((blockLen and 0xFF).uint8)
        output.add(((blockLen shr 8) and 0xFF).uint8)
        let nlen = (not blockLen) and 0xFFFF
        output.add((nlen and 0xFF).uint8)
        output.add(((nlen shr 8) and 0xFF).uint8)
        for i in 0..<blockLen:
            output.add(data[j+i])
        j += blockLen
    
    let adler = adler32(data)
    return output&adler







proc paeth(a, b, c: int): uint8=
    var
        p: int = a+b-c
        pa: int = abs(p-a)
        pb: int = abs(p-b)
        pc: int = abs(p-c)
    if pa <= pb and pa <= pc:
        return a.uint8
    elif pb <= pc:
        return b.uint8
    else:
        return c.uint8

proc stbiw_encode_png_line(pixels: var seq[uint8], stride_bytes: int, width: int, height: int, y: int, n: int, filter_type: int, line_buffer: var seq[int8])=
    var
        mapping: array[5, int] = [0, 1, 2, 3, 4]
        firstmap: array[5, int] = [0, 1, 0, 5, 6]
        mymap: array[5, int] = if y == 0: firstmap
                                    else: mapping
        filterType: int = mymap[filter_type]
        z: int = stride_bytes * (if stbi_flip_vertically_on_write: height - 1 - y else: y)
        signed_stride: int = if stbi_flip_vertically_on_write: -stride_bytes else: stride_bytes
    
    if filterType == 0:
        
        seqmoveR(z, line_buffer, cast[seq[int8]](pixels), width*n)
        return

    for i in 0..<n:
        case filterType:
            of 1: line_buffer[i] = cast[int8](pixels[z + i])
            of 2: line_buffer[i] = cast[int8](pixels[z + i] - pixels[z + i - signed_stride])
            of 3: line_buffer[i] = cast[int8](pixels[z + i] - (pixels[z + i - signed_stride] shr 1))
            of 4: line_buffer[i] = cast[int8](pixels[z + i] - paeth(0, pixels[z + i - signed_stride].int, 0))
            #of 5: line_buffer[i] = cast[int8](pixels[z + i])
            #of 6: line_buffer[i] = cast[int8](pixels[z + i])
            else: discard
    
    case filterType:
        of 1:
            for i in n..<width*n:
                line_buffer[i] = cast[int8](pixels[z + i] - pixels[z + i - n])
        of 2:
            for i in n..<width*n:
                line_buffer[i] = cast[int8](pixels[z + i] - pixels[z + i - signed_stride])
        of 3:
            for i in n..<width*n:
                line_buffer[i] = cast[int8](pixels[z + i] - ((pixels[z + i - n] + pixels[z + i - signed_stride]) shr 1))
        of 4:
            for i in n..<width*n:
                line_buffer[i] = cast[int8](pixels[z + i] - paeth(pixels[z + i - n].int, pixels[z + i - signed_stride].int, pixels[z + i - signed_stride - n].int))
        #of 5:
        #    for i in n..<width*n:
        #        line_buffer[i] = cast[int8](pixels[z + i] - (pixels[z + i - n] shr 1))
        #of 6:
        #    for i in n..<width*n:
        #        line_buffer[i] = cast[int8](pixels[z + i] - paeth(pixels[z + i - n].int, 0, 0))
        else: discard

proc stbi_write_png_to_mem(pixels: var seq[uint8], stride_bytes: var int, x, y, n: int): seq[uint8]=
    var
        force_filter: int = stbi_write_force_png_filter
        ctype: array[5, uint8] = [0xFF, 0, 4, 2, 6]
        sig: seq[uint8] = @[137, 80, 78, 71, 13, 10, 26, 10]
        output: seq[uint8]
        o: int
        filt: seq[uint8]
        zlib: seq[uint8]
        line_buffer: seq[int8]
        zlen: int
    
    if stride_bytes == 0:
        stride_bytes = x * n
    if force_filter >= 5:
        force_filter = -1
    
    line_buffer = newSeq[int8](x*n)

    for j in 0..<y:
        var filter_type: int
        if force_filter > -1:
            filter_type = force_filter
            stbiw_encode_png_line(pixels, stride_bytes, x, y, j, n, force_filter, line_buffer)
        else:
            var
                best_filter: int = 0
                best_filter_val: int = 0x7fffffff
                est: uint64
            filter_type = 0
            while filter_type < 5:
                stbiw_encode_png_line(pixels, stride_bytes, x, y, j, n, filter_type, line_buffer)
                est = 0
                for i in 0..<(x*n):
                    est += abs(line_buffer[i].int).uint64
                if est < best_filter_val.uint64:
                    best_filter_val = est.int
                    best_filter = filter_type
                filter_type += 1
            stbiw_encode_png_line(pixels, stride_bytes, x, y, j, n, best_filter, line_buffer)
            filter_type = best_filter
        
        filt.add(uint8(filter_type))
        filt = filt & cast[seq[uint8]](line_buffer)
    zlib = stbi_zlib_compress(filt, stbi_write_png_compression_level)
    zlen = zlib.len()

    output = newSeq[uint8](8 + 12+13 + 12+zlen + 12)

    o = 0
    seqmove(o, output, sig)
    wp32(o, output, 13)
    wptag(o, output, "IHDR")
    wp32(o, output, x.uint32)
    wp32(o, output, y.uint32)
    incWrite(o, output, 8)
    incWrite(o, output, ctype[n])
    incWrite(o, output, 0)
    incWrite(o, output, 0)
    incWrite(o, output, 0)
    wpcrc(o, output, 13)

    wp32(o, output, zlen.uint32)
    wptag(o, output, "IDAT")
    seqmove(o, output, zlib)
    wpcrc(o, output, zlen)

    wp32(o, output, 0)
    wptag(o, output, "IEND")
    wpcrc(o, output, 0)

    assert(o == output.len())

    return output
    



    
    

    

proc stb_encode_png(x, y, comp: int, data: var seq[uint8], stride_bytes: var int): seq[uint8]=
    return stbi_write_png_to_mem(data, stride_bytes, x, y, comp)


proc encodePNG*[W: static[int], H: static[int]](rawImage: array[W, array[H, Colour]]): seq[uint8]=
    var
        stride_bytes: int = W*3
        rawImageR : ref array[H, array[W, Colour]] = new array[H, array[W, Colour]]
    for y in 0..<H:
        for x in 0..<W:
            rawImageR[H-1-y][x] = rawImage[x][y]

    let
        rawPixels = cast[ref array[W*H, Colour]](rawImageR[0].addr)
    var
        rawPixelsSeq: seq[uint8]
    for i in 0..<(W*H):
        rawPixelsSeq.add(rawPixels[i].r)
        rawPixelsSeq.add(rawPixels[i].g)
        rawPixelsSeq.add(rawPixels[i].b)
    
    return stb_encode_png(W, H, 3, rawPixelsSeq, stride_bytes)
