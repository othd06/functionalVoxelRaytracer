

import math

import raytracer
import helpers

func getHitFunctions*(): array[256, hitFunction]

func hitFunc0(voxelGrid: Model, dimensions: tuple[x, y, z: int], face: Face, location: Vector2, position: Vector3, incidentAngle: Vector3, hits: int): Colour=
    let theta = arctan(abs(incidentAngle.y)/sqrt(incidentAngle.x*incidentAngle.x + incidentAngle.z*incidentAngle.z))
    if incidentAngle.y < 0:
        const
            dullBrown = Colour(r: 0x87.uint8, g: 0x6E.uint8, b: 0x4B.uint8)
            dullOrange = Colour(r: 0xD8.uint8, g: 0x86.uint8, b: 0x3B.uint8)
        if theta < 15*PI/180:
            return dullBrown*(theta/(15*PI/180)) + dullOrange*(1-theta/(15*PI/180))
        return dullBrown
    const
        dullOrange = Colour(r: 0xD8.uint8, g: 0x86.uint8, b: 0x3B.uint8)
        skyBlue = Colour(r: 0x7B.uint8, g: 0xD9.uint8, b: 0xF6.uint8)
    if theta < 15*PI/180:
        return skyBlue*(theta/(15*PI/180)) + dullOrange*((1-theta/(15*PI/180)))
    return skyBlue
    

func hitFunc1(voxelGrid: Model, dimensions: tuple[x, y, z: int], face: Face, location: Vector2, position: Vector3, incidentAngle: Vector3, hits: int): Colour=
    if hits == 0:
        var
            reflectedDirection = incidentAngle
            baseColour: Colour
        if face == UP:
            baseColour = Colour(r: 255, g: 255, b: 255)
            reflectedDirection.y *= -1
        elif face == DOWN:
            baseColour = Colour(r: 35, g: 35, b: 35)
            reflectedDirection.y *= -1
        elif face == EAST:
            baseColour = Colour(r: 210, g: 210, b: 210)
            reflectedDirection.x *= -1
        elif face == WEST:
            baseColour = Colour(r: 50, g: 50, b: 50)
            reflectedDirection.x *= -1
        elif face == NORTH:
            baseColour = Colour(r: 90, g: 90, b: 90)
            reflectedDirection.z *= -1
        elif face == SOUTH:
            baseColour = Colour(r: 160, g: 160, b: 160)
            reflectedDirection.z *= -1
        return traceRay(voxelGrid, dimensions, position, reflectedDirection, getHitFunctions(), hits+1)*0.5 + baseColour*0.5
    else:
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


