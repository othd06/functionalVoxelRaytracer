
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
    Vector2* = object
        x*: float64
        y*: float64
    Colour* = object
        r*: uint8
        g*: uint8
        b*: uint8
    Brick* = tuple[isEmpty: bool, brick: array[8, array[8, array[8, uint8]]]]
    Model* = seq[seq[seq[Brick]]]
    SimpleModel* = seq[seq[seq[uint8]]]
    FatalError* = object of CatchableError
    hitFunction* = proc(voxelGrid: Model, face: Face, location: Vector2, position: Vector3, incidentAngle: Vector3, hits: int): Colour {.noSideEffect.}

func isEmpty(input: array[8, array[8, array[8, uint8]]]): bool=
    for x in 0..<8:
        for y in 0..<8:
            for z in 0..<8:
                if input[x][y][z] != 0: return false
    return true

func toModel*(simple: SimpleModel, dims: tuple[x, y, z: int]): Model=
    var newSimple: SimpleModel
    for x in 0..<int(ceil(dims.x.float/8)*8):
        newSimple.add(@[])
        for y in 0..<int(ceil(dims.y.float/8)*8):
            newSimple[newSimple.high].add(@[])
            for z in 0..<int(ceil(dims.z.float/8)*8):
                if x<dims.x and y<dims.y and z<dims.z:
                    newSimple[newSimple.high][newSimple[newSimple.high].high].add(simple[x][y][z])
                else:
                    newSimple[newSimple.high][newSimple[newSimple.high].high].add(0.uint8)
    var output : Model
    for x in 0..<int(ceil(dims.x.float/8)):
        output.add(@[])
        for y in 0..<int(ceil(dims.y.float/8)):
            output[output.high].add(@[])
            for z in 0..<int(ceil(dims.z.float/8)):
                var newBrick : array[8, array[8, array[8, uint8]]]
                for i in 0..<8:
                    for j in 0..<8:
                        for k in 0..<8:
                            newBrick[i][j][k] = newSimple[x*8+i][y*8+j][z*8+k]
                output[output.high][output[output.high].high].add((isEmpty(newBrick), newBrick))
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

func `-`*(a, b: Vector3): Vector3=
    return Vector3(x: a.x-b.x, y: a.y-b.y, z: a.z-b.z)

func `-`*(a, b: Vector2): Vector2=
    return Vector2(x: a.x-b.x, y: a.y-b.y)

func `*`*(a: Vector3, b: float64): Vector3=
    return Vector3(x: a.x*b, y: a.y*b, z: a.z*b)

func `*`*(a: Vector2, b: float64): Vector2=
    return Vector2(x: a.x*b, y: a.y*b)

func `/`*(a: Vector3, b: float64): Vector3=
    return Vector3(x: a.x/b, y: a.y/b, z: a.z/b)

func `/`*(a: Vector2, b: float64): Vector2=
    return Vector2(x: a.x/b, y: a.y/b)

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

func map*[T](a: seq[T], mapFunc: proc(b: T): T {.noSideEffect.}): seq[T]=
    var output : seq[T] = @[]
    for i in a:
        output.add(mapFunc(i))

func map*[L: static[int], T](a: array[L, T], mapFunc: proc(b: T): T {.noSideEffect.}): array[L, T]=
    var output : array[L, T]
    for i in 0..a.high:
        output[i] = mapFunc(a[i])

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


