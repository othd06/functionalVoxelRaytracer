
import random
import math


type
    Face* = enum
        UP
        DOWN
        NORTH
        SOUTH
        EAST
        WEST
    Vector3* = object
        x*: float64
        y*: float64
        z*: float64
    Matrix*[R: static[int], C: static[int]] = array[R, array[C, float]] 
    Vector2* = object
        x*: float64
        y*: float64
    Colour* = object
        r*: uint8
        g*: uint8
        b*: uint8
    #Model* = seq[seq[seq[uint8]]]
    Model* = object
        w*, h*, l*: int
        data*: ptr[UncheckedArray[uint8]]
    SimpleModel* = seq[seq[seq[uint8]]]
    FatalError* = object of CatchableError
    hitFunction* = proc(voxelGrid: Model, dimensions: tuple[x, y, z: int], face: Face, location: Vector2, position: Vector3, incidentAngle: Vector3, hits: int, time: int): Colour {.noSideEffect.}

func modelIndex*(w, h, l: int, m: Model): int=
    return l + h*m.l + w*m.l*m.h

proc toModel*(simple: SimpleModel): Model=
    var output: Model
    output.w = len(simple)
    output.h = len(simple[0])
    output.l = len(simple[0][0])
    output.data = cast[ptr UncheckedArray[uint8]](alloc(output.w * output.h * output.l))
    for i in 0..<output.w:
        for j in 0..<output.h:
            for k in 0..<output.l:
                output.data[][modelIndex(i, j, k, output)] = simple[i][j][k]
    return output

func normalise*(input: Vector3): Vector3=
    if input == Vector3(x: 0, y: 0, z: 0):
        raise newException(FatalError, "\aError: cannot normalise zero Vector")
    let length = sqrt (input.x*input.x + input.y*input.y + input.z*input.z)
    return Vector3(x: input.x/length, y: input.y/length, z: input.z/length)

func normalise*(input: Vector2): Vector2=
    if input == Vector2(x: 0, y: 0):
        raise newException(FatalError, "\aError: cannot normalise zero Vector")
    let length = sqrt (input.x*input.x + input.y*input.y)
    return Vector2(x: input.x/length, y: input.y/length)

func dot*(a, b: Vector3): float64=
    return a.x*b.x + a.y*b.y + a.z*b.z

func dot*(a, b: Vector2): float64=
    return a.x*b.x + a.y*b.y

func cross*(a, b: Vector3): Vector3=
    return Vector3(x: a.y*b.z-a.z*b.y, y: a.z*b.x-a.x*b.z, z: a.x*b.y-b.x*a.y)

func cross*(a, b: Vector2): float64=
    return cross(Vector3(x: a.x, y: a.y, z: 0), Vector3(x: b.x, y: b.y, z: 0)).z

func `+`*(a, b: Vector3): Vector3=
    return Vector3(x: a.x+b.x, y: a.y+b.y, z: a.z+b.z)

func `+`*(a, b: Vector2): Vector2=
    return Vector2(x: a.x+b.x, y: a.y+b.y)

func `+`*(a, b: Colour): Colour=
    return Colour(r: a.r+b.r, g: a.g+b.g, b: a.b+b.b)

func `-`*(a, b: Vector3): Vector3=
    return Vector3(x: a.x-b.x, y: a.y-b.y, z: a.z-b.z)

func `-`*(a, b: Vector2): Vector2=
    return Vector2(x: a.x-b.x, y: a.y-b.y)

func `*`*(a: Vector3, b: float64): Vector3=
    return Vector3(x: a.x*b, y: a.y*b, z: a.z*b)

func `*`*(a: Vector2, b: float64): Vector2=
    return Vector2(x: a.x*b, y: a.y*b)

func `*`*(a: Colour, b: float64): Colour=
    return Colour(r: uint8(a.r.float64*b), g: uint8(a.g.float64*b), b: uint8(a.b.float64*b))

func `*`*(a, b: Colour): Colour=
    return Colour(r: uint8(a.r.float64*b.r.float64/255), g: uint8(a.g.float64*b.g.float64/255), b: uint8(a.b.float64*b.b.float64/255))

func `*`*[C: static[int], RC: static[int], R: static[int]](a: Matrix[R, RC], b: Matrix[RC, C]): Matrix[R, C]=
    var output: Matrix[R, C]
    for i in 0..<R:
        for j in 0..<C:
            output[i][j] = 0
            for k in 0..<RC:
                output[i][j] += a[i][k]*b[k][j]

func `*`*(a: Matrix[3, 3], b: Vector3): Vector3=
    Vector3(x: b.x*a[0][0] + b.y*a[0][1] + b.z*a[0][2], y: b.x*a[1][0] + b.y*a[1][1] + b.z*a[1][2], z: b.x*a[2][0] + b.y*a[2][1] + b.z*a[2][2])

func `*`*(a: Matrix[2, 2], b: Vector2): Vector2=
    Vector2(x: b.x*a[0][0] + b.y*a[0][1], y: b.x*a[1][0] + b.y*a[1][1])

func `/`*(a: Vector3, b: float64): Vector3=
    return Vector3(x: a.x/b, y: a.y/b, z: a.z/b)

func `/`*(a: Vector2, b: float64): Vector2=
    return Vector2(x: a.x/b, y: a.y/b)

func `/`*(a: Colour, b: float64): Colour=
    return Colour(r: uint8(a.r.float64/b), g: uint8(a.g.float64/b), b: uint8(a.b.float64/b))

func length*(a: Vector3): float64=
    return sqrt(a.x*a.x + a.y*a.y + a.z*a.z)

func length*(a: Vector2): float64=
    return sqrt(a.x*a.x + a.y*a.y)

func distance*(a, b: Vector3): float64=
    return length(a-b)

func distance*(a, b: Vector2): float64=
    return length(a-b)


func filter*[T](a: seq[T], filterFunc: proc(b: T): bool {.noSideEffect.}): seq[T]=
    var output : seq[T] = @[]
    for i in a:
        if filterFunc(i):
            output.add(i)
    return output

func map*[T, U](a: seq[U], mapFunc: proc(b: U): T {.noSideEffect.}): seq[T]=
    var output : seq[T] = @[]
    for i in a:
        output.add(mapFunc(i))
    return output

func map*[L: static[int], T, U](a: array[L, U], mapFunc: proc(b: U): T {.noSideEffect.}): array[L, T]=
    var output : array[L, T]
    for i in 0..a.high:
        output[i] = mapFunc(a[i])
    return output

func reverse*[L: static[int], T](a: array[L, T]): array[L, T]=
    var output: array[L, T]
    for i in 0..<L:
        output[L-i-1] = a[i]
    return output

func quicksort*[T](a: seq[T], isHigher: proc(x, y: T): bool {.noSideEffect.}): seq[T]=
    if a.len == 0: return @[]
    let
        head = a[0]
        rest = a[1..a.high]
        lower = filter(rest, func(b: T): bool = isHigher(b, head) == false)
        upper = filter(rest, func(b: T): bool = isHigher(b, head))
    return quicksort(lower, isHigher) & @[head] & quicksort(upper, isHigher)


func seededRand*(seed: int, maxVal: float): float =
  var
    rng = initRand(seed)       # initialise RNG with your seed
  result = rng.rand(maxVal)      # random float in [0, maxVal)

func drop*[T](amount: int, input: seq[T]): seq[T] =
    if amount <= 0: return input
    if amount >= input.len: return @[]
    result = input[amount .. ^1]

func take*[T](amount: int, input: seq[T]): seq[T] =
    if amount <= 0: return input
    if amount > input.len: return @[]
    result = input[0..<amount]
    return result

func sub*[T](a, b: seq[T]): seq[T]=
    var output = a
    for i in 0..output.high:
        output[i] -= b[i]
    return output

func sum*[T](a, b: seq[T]): seq[T]=
    var output = a
    for i in 0..output.high:
        output[i] += b[i]
    return output

func mapG*[T, U](a: seq[T], b: proc(x: T): U {.noSideEffect.}): seq[U]=
    for i in a:
        result.add(i.b())

proc mapGsideEffects*[T, U](a: seq[T], b: proc(x: T): U): seq[U]=
    for i in a:
        result.add(i.b())

func map3*[T, U](a, b, c: seq[T], f: proc(x, y, z: T): U {.noSideEffect.}): seq[U]=
    for i in 0..a.high:
        result.add(f(a[i], b[i], c[i]))

func inRange*[T](a, b, c: T): bool=
    return (a >= b and a <= c)

func insertOrdered*[T](s: seq[T], v: T, isHigher: proc(a, b: T): bool {.noSideEffect.}): seq[T]=
    var output = s
    for i in 0..<output.len():
        if output[i].isHigher(v):
            output.insert(v, i)
            return output
    return output & @[v]

func reverse*[T](s: seq[T]): seq[T] =
  var r = newSeq[T](s.len)
  for i in 0 ..< s.len:
    r[i] = s[s.len - 1 - i]
  return r

func promoteSeqs*[T](a: seq[seq[T]]): seq[T]=
    result = @[]
    for i in a:
        result = result & i

func arrToSeq*[L: static[int], T](input: array[L, T]): seq[T]=
    result = @[]
    for i in 0..<L:
        result.add(input[i])
    return result

func runLengthEncode*[T](input: seq[T]): seq[tuple[value: T, runLength: int]]=
    var
        interim: seq[tuple[value: T, runLength: int]] = input.map(func(x: T): tuple[value: T, runLength: int] = (x, 1)).reverse()
        output: seq[tuple[value: T, runLength: int]] = @[]
    while interim.len()>1:
        if interim[interim.high].value == interim[interim.high-1].value:
            interim.delete(interim.high-1)
            interim[interim.high].runLength += 1
        else:
            output.add(interim[interim.high])
            interim.delete(interim.high)
    output.add(interim[0])
    return output
    


