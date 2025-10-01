

import math

import raytracer
import helpers

func getHitFunctions*(): array[256, hitFunction]


func hitFunc0(voxelGrid: Model, dimensions: tuple[x, y, z: int], face: Face, location: Vector2, position: Vector3, incidentAngle: Vector3, hits: int, time: int): Colour=
    let
        rotationMatrix = [[cos(15*PI/180), -sin(15*PI/180), 0],
                          [sin(15*PI/180),  cos(15*PI/180), 0],
                          [0             , 0             , 1]]
        dir = rotationMatrix*incidentAngle 
        theta = arctan(abs(dir.y)/sqrt(dir.x*dir.x + dir.z*dir.z))
    if dir.y < 0:
        const
            dullBrown = Colour(r: 0x87.uint8, g: 0x6E.uint8, b: 0x4B.uint8)*0.3
            dullOrange = Colour(r: 0xD8.uint8, g: 0x86.uint8, b: 0x3B.uint8)*0.7
        if theta < 15*PI/180:
            return dullBrown*(theta/(15*PI/180)) + dullOrange*(1-theta/(15*PI/180))
        return dullBrown
    const
        dullOrange = Colour(r: 0xD8.uint8, g: 0x86.uint8, b: 0x3B.uint8)*0.7
        skyBlue = Colour(r: 0xB8.uint8, g: 0xC7.uint8, b: 0xCC.uint8)
    if theta < 15*PI/180:
        return skyBlue*(theta/(15*PI/180)) + dullOrange*((1-theta/(15*PI/180)))
    return skyBlue

func sampleCosineHemisphere(u1, u2: float): Vector3 =
    let
        r = sqrt(u1)
        phi = 2.0 * PI * u2
        x = r * cos(phi)
        y = r * sin(phi)
        z = sqrt(1.0 - u1)
    Vector3(x: x, y: y, z: z)

func hitFunc1(voxelGrid: Model, dimensions: tuple[x, y, z: int], face: Face, location: Vector2, position: Vector3, incidentAngle: Vector3, hits: int, time: int): Colour=
    const baseColour: Colour = Colour(r: 0xDD, g: 0x29, b: 0x10)
    if hits < 3:
        var
            reflectedDirection = incidentAngle
            normal: Vector3
        if face == UP:
            normal = Vector3(x: 0, y: 1, z: 0)
            reflectedDirection.y *= -1
        elif face == DOWN:
            normal = Vector3(x: 0, y: -1, z: 0)
            reflectedDirection.y *= -1
        elif face == EAST:
            normal = Vector3(x: 1, y: 0, z: 0)
            reflectedDirection.x *= -1
        elif face == WEST:
            normal = Vector3(x: -1, y: 0, z: 0)
            reflectedDirection.x *= -1
        elif face == NORTH:
            normal = Vector3(x: 0, y: 0, z: 1)
            reflectedDirection.z *= -1
        elif face == SOUTH:
            normal = Vector3(x: 0, y: 0, z: -1)
            reflectedDirection.z *= -1
        let
            cosTheta = max(0.0, normal.dot(normalise(incidentAngle*(-1))))
            R_0 = 0.2
            reflectionCoefficient = R_0 + (1-R_0)*pow((1-cosTheta), 5.0)
        var light: Colour
        for i in 0..20:
            let
                u1 = seededRand(time+i*3, 1.0)
                u2 = seededRand(time+1+i*3, 1.0)
                valueInLobe: Vector3 = sampleCosineHemisphere(u1, u2)
                u3 = seededRand(time+2+i*3, 1.0)
                perpNormal = incidentAngle.cross(normal).normalise()
            var direction: Vector3
            if u3 > reflectionCoefficient:
                direction = normal*valueInLobe.z + perpNormal*valueInLobe.x + normal.cross(perpNormal).normalise()*valueInLobe.z
            else:
                direction = reflectedDirection*valueInLobe.z + perpNormal*valueInLobe.x + perpNormal.cross(reflectedDirection).normalise()*valueInLobe.y
            let hitFunctions = getHitFunctions()
            let newLight: Colour = traceRay(voxelGrid, dimensions, position, direction, addr hitFunctions, hits+1, time)
            light = light*((i-1)/i) + newLight/i.float
        return baseColour*light
    else:
        return Colour(r: 0, g: 0, b: 0)
        #[
        if face == UP:
            return baseColour
            #return Colour(r: 255, g: 255, b: 255)
        elif face == DOWN:
            return baseColour*(35/255)
            #return Colour(r: 35, g: 35, b: 35)
        elif face == EAST:
            return baseColour*(210/255)
            #return Colour(r: 210, g: 210, b: 210)
        elif face == WEST:
            return baseColour*(50/255)
            #return Colour(r: 50, g: 50, b: 50)
        elif face == NORTH:
            return baseColour*(90/255)
            #return Colour(r: 90, g: 90, b: 90)
        elif face == SOUTH:
            return baseColour*(160/255)
            #return Colour(r: 160, g: 160, b: 160)
        ]#


#[
func hitFunc0(voxelGrid: Model, dimensions: tuple[x, y, z: int], face: Face, location: Vector2, position: Vector3, incidentAngle: Vector3, hits: int, time: int): Colour=
    return Colour(r: 0, g: 0, b: 0)

func hitFunc1(voxelGrid: Model, dimensions: tuple[x, y, z: int], face: Face, location: Vector2, position: Vector3, incidentAngle: Vector3, hits: int, time: int): Colour=
    return Colour(r: 255, g: 255, b: 255)
]#


#[
func hitFunc1(voxelGrid: Model, dimensions: tuple[x, y, z: int], face: Face, location: Vector2, position: Vector3, incidentAngle: Vector3, hits: int, time: int): Colour=
    if hits < 3:
        var
            reflectedDirection = incidentAngle
            baseColour: Colour
            normal: Vector3
        if face == UP:
            baseColour = Colour(r: 255, g: 255, b: 255)
            normal = Vector3(x: 0, y: 1, z: 0)
            reflectedDirection.y *= -1
        elif face == DOWN:
            baseColour = Colour(r: 35, g: 35, b: 35)
            normal = Vector3(x: 0, y: -1, z: 0)
            reflectedDirection.y *= -1
        elif face == EAST:
            baseColour = Colour(r: 210, g: 210, b: 210)
            normal = Vector3(x: 1, y: 0, z: 0)
            reflectedDirection.x *= -1
        elif face == WEST:
            baseColour = Colour(r: 50, g: 50, b: 50)
            normal = Vector3(x: -1, y: 0, z: 0)
            reflectedDirection.x *= -1
        elif face == NORTH:
            baseColour = Colour(r: 90, g: 90, b: 90)
            normal = Vector3(x: 0, y: 0, z: 1)
            reflectedDirection.z *= -1
        elif face == SOUTH:
            baseColour = Colour(r: 160, g: 160, b: 160)
            normal = Vector3(x: 0, y: 0, z: -1)
            reflectedDirection.z *= -1
        let
            cosTheta = max(0.0, normal.dot(normalise(incidentAngle*(-1))))
            R_0 = 0.2
            reflectionCoefficient = R_0 + (1-R_0)*pow((1-cosTheta), 5.0)
        return traceRay(voxelGrid, dimensions, position, reflectedDirection, getHitFunctions(), hits+1)*reflectionCoefficient + baseColour*(1-reflectionCoefficient)
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
]#


func getHitFunctions*(): array[256, hitFunction]=
    var output : array[256, hitFunction]
    for i in 0..<256:
        output[i] = hitFunc0
    output[0] = hitFunc0
    output[1] = hitFunc1
    return output


