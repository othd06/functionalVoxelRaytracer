import helpers


func hitFunc0(voxelGrid: Model, face: Face, location: Vector2, position: Vector3, incidentAngle: Vector3, hits: int): Colour=
    Colour(r: 0, g: 0, b: 0)

func hitFunc1(voxelGrid: Model, face: Face, location: Vector2, position: Vector3, incidentAngle: Vector3, hits: int): Colour=
    if face == UP:
        return Colour(r: 255, g: 255, b: 255)
    elif face == DOWN:
        return Colour(r: 35, g: 35, b: 35)
    elif face == EAST:
        return Colour(r: 210, g: 210, b: 210)
    elif face == WEST:
        return Colour(r: 50, g: 50, b: 50)
    elif face == NORTH:
        return Colour(r: 90, g: 90, b: 90)
    elif face == SOUTH:
        return Colour(r: 160, g: 160, b: 160)

func getHitFunctions*(): array[256, hitFunction]=
    var output : array[256, hitFunction]
    for i in 0..<256:
        output[i] = hitFunc0
    output[0] = hitFunc0
    output[1] = hitFunc1
    return output