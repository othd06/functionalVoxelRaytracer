


import helpers
import math


func ceil8(x: float): float=
    var output = ceil(x)
    while int(output) mod 8 != 0:
        output += 1
    return output

func floor8(x: float): float = ceil8(x)-8

func traceRayOverBlocks(model: Model, dimensions: tuple[x, y, z: int], position: Vector3, normDir: Vector3, hitFunctions: array[256, hitFunction], hits: int, gridPosition: tuple[x, y, z: int], distances: Vector3, perBlockDistances: Vector3, directions: tuple[x, y, z: bool]): Colour=
    if distances.x < distances.y and distances.x < distances.z:
        if directions.x:
            let
                newGridPosition: tuple[x, y, z: int] = (gridPosition.x+8, gridPosition.y, gridPosition.z)
                newDistances: Vector3 = Vector3(x: perBlockDistances.x, y: distances.y-distances.x, z: distances.z-distances.x)
                newPosition: Vector3 = position + normDir*distances.x
            if newGridPosition.x >= dimensions.x:
                return hitFunctions[0](model, UP, Vector2(x: 0, y: 0), newPosition, normDir, hits)
            elif model[newGridPosition.x shr 3][newGridPosition.y shr 3][newGridPosition.z shr 3][0] == false:
                return hitFunctions[1](model, WEST, Vector2(x: 1-(newPosition.z - floor(newPosition.z)), y: newPosition.y - floor(newPosition.y)), newPosition, normDir, hits)
            else:
                return traceRayOverBlocks(model, dimensions, newPosition, normDir, hitFunctions, hits, newGridPosition, newDistances, perBlockDistances, directions)
        else:
            let
                newGridPosition: tuple[x, y, z: int] = (gridPosition.x-8, gridPosition.y, gridPosition.z)
                newDistances: Vector3 = Vector3(x: perBlockDistances.x, y: distances.y-distances.x, z: distances.z-distances.x)
                newPosition: Vector3 = position + normDir*distances.x
            if newGridPosition.x < 0:
                return hitFunctions[0](model, UP, Vector2(x: 0, y: 0), newPosition, normDir, hits)
            elif model[newGridPosition.x shr 3][newGridPosition.y shr 3][newGridPosition.z shr 3][0] == false:
                return hitFunctions[1](model, EAST, Vector2(x: (newPosition.z - floor(newPosition.z)), y: (newPosition.y - floor(newPosition.y))), newPosition, normDir, hits)
            else:
                return traceRayOverBlocks(model, dimensions, newPosition, normDir, hitFunctions, hits, newGridPosition, newDistances, perBlockDistances, directions)
    elif distances.y < distances.z:
        if directions.y:
            let
                newGridPosition: tuple[x, y, z: int] = (gridPosition.x, gridPosition.y+8, gridPosition.z)
                newDistances: Vector3 = Vector3(x: distances.x - distances.y, y: perBlockDistances.y, z: distances.z - distances.y)
                newPosition: Vector3 = position + normDir*distances.y
            if newGridPosition.y >= dimensions.y:
                return hitFunctions[0](model, UP, Vector2(x: 0, y: 0), newPosition, normDir, hits)
            elif model[newGridPosition.x shr 3][newGridPosition.y shr 3][newGridPosition.z shr 3][0] == false:
                return hitFunctions[1](model, DOWN, Vector2(x: newPosition.x - floor(newPosition.x), y: newPosition.z - floor(newPosition.z)), newPosition, normDir, hits)
            else:
                return traceRayOverBlocks(model, dimensions, newPosition, normDir, hitFunctions, hits, newGridPosition, newDistances, perBlockDistances, directions)
        else:
            let
                newGridPosition: tuple[x, y, z: int] = (gridPosition.x, gridPosition.y-8, gridPosition.z)
                newDistances: Vector3 = Vector3(x: distances.x - distances.y, y: perBlockDistances.y, z: distances.z - distances.y)
                newPosition: Vector3 = position + normDir*distances.y
            if newGridPosition.y < 0:
                return hitFunctions[0](model, UP, Vector2(x: 0, y: 0), newPosition, normDir, hits)
            elif model[newGridPosition.x shr 3][newGridPosition.y shr 3][newGridPosition.z shr 3][0] == false:
                return hitFunctions[1](model, UP, Vector2(x: (newPosition.x - floor(newPosition.x)), y: (newPosition.z - floor(newPosition.z))), newPosition, normDir, hits)
            else:
                return traceRayOverBlocks(model, dimensions, newPosition, normDir, hitFunctions, hits, newGridPosition, newDistances, perBlockDistances, directions)
    else:
        if directions.z:
            let
                newGridPosition: tuple[x, y, z: int] = (gridPosition.x, gridPosition.y, gridPosition.z+8)
                newDistances: Vector3 = Vector3(x: distances.x - distances.z, y: distances.y - distances.z, z: perBlockDistances.z)
                newPosition: Vector3 = position + normDir*distances.z
            if newGridPosition.z >= dimensions.z:
                return hitFunctions[0](model, UP, Vector2(x: 0, y: 0), newPosition, normDir, hits)
            elif model[newGridPosition.x shr 3][newGridPosition.y shr 3][newGridPosition.z shr 3][0] == false:
                return hitFunctions[1](model, SOUTH, Vector2(x: newPosition.x - floor(newPosition.x), y: newPosition.y - floor(newPosition.y)), newPosition, normDir, hits)
            else:
                return traceRayOverBlocks(model, dimensions, newPosition, normDir, hitFunctions, hits, newGridPosition, newDistances, perBlockDistances, directions)
        else:
            let
                newGridPosition: tuple[x, y, z: int] = (gridPosition.x, gridPosition.y, gridPosition.z-1)
                newDistances: Vector3 = Vector3(x: distances.x - distances.z, y: distances.y - distances.z, z: perBlockDistances.z)
                newPosition: Vector3 = position + normDir*distances.z
            if newGridPosition.z < 0:
                return hitFunctions[0](model, UP, Vector2(x: 0, y: 0), newPosition, normDir, hits)
            elif model[newGridPosition.x shr 3][newGridPosition.y shr 3][newGridPosition.z shr 3][0] == false:
                return hitFunctions[1](model, NORTH, Vector2(x: 1-(newPosition.x - floor(newPosition.x)), y: (newPosition.y - floor(newPosition.y))), newPosition, normDir, hits)
            else:
                return traceRayOverBlocks(model, dimensions, newPosition, normDir, hitFunctions, hits, newGridPosition, newDistances, perBlockDistances, directions)

func traceRay*(model: Model, dimensions: tuple[x, y, z: int], position: Vector3, direction: Vector3, hitFunctions: array[256, hitFunction], hits: int = 0): Colour=
    let normDir = normalise(direction)
    if (abs(position.x) > dimensions.x/2) or (abs(position.y) > dimensions.y/2) or (abs(position.z) > dimensions.z/2):
        #We are outside the world
        var distsAABB: seq[float] = @[]
        if normDir.x != 0:
            distsAABB.add(((-dimensions.x/2)-position.x) / normDir.x)
            distsAABB.add((( dimensions.x/2)-position.x) / normDir.x)
        if normDir.y != 0:
            distsAABB.add(((-dimensions.y/2)-position.y) / normDir.y)
            distsAABB.add((( dimensions.y/2)-position.y) / normDir.y)
        if normDir.z != 0:
            distsAABB.add(((-dimensions.z/2)-position.z) / normDir.z)
            distsAABB.add((( dimensions.z/2)-position.z) / normDir.z)
        distsAABB = filter(distsAABB, proc(a: float): bool = a>0)
        if distsAABB.len == 0:
            return hitFunctions[0](model, UP #[This is arbitrary in the case that no voxel is hit]#, Vector2(x: 0, y: 0), position, direction, hits)
        distsAABB = quicksort(distsAABB, proc(a, b: float): bool = a>b)
        return traceRay(model, dimensions, position + normDir*distsAABB[0], direction, hitFunctions, hits)
    else:
        let
            worldPosition: Vector3 = position + Vector3(x: dimensions.x/2, y: dimensions.y/2, z: dimensions.z/2)
            worldGridPosition: tuple[x, y, z: int] = (floor8(worldPosition.x).int, floor8(worldPosition.y).int, floor8(worldPosition.z).int)
            directions: tuple[x, y, z: bool] = (direction.x>0, direction.y>0, direction.z>0)
            xDir = if normDir.x != 0:
                    normDir / normDir.x
                else:
                    Vector3(x: dimensions.x.float64 * 2, y: 0, z: 0)
            yDir = if normDir.y != 0:
                    normDir / normDir.y
                else:
                    Vector3(x: dimensions.y.float64 * 2, y: 0, z: 0)
            zDir = if normDir.z != 0:
                    normDir / normDir.z
                else:
                    Vector3(x: dimensions.z.float64 * 2, y: 0, z: 0)
            perBlockDistances: Vector3 = Vector3(x: length(xDir)*8, y: length(yDir)*8, z: length(zDir)*8)
        var initialDistances: Vector3
        if directions.x:
            initialDistances.x = perBlockDistances.x * (ceil8(worldPosition.x) - worldPosition.x) / 8
        else:
            initialDistances.x = perBlockDistances.x * (worldPosition.x - floor8(worldPosition.x)) / 8
        if directions.y:
            initialDistances.y = perBlockDistances.y * (ceil8(worldPosition.y) - worldPosition.y) / 8
        else:
            initialDistances.y = perBlockDistances.y * (worldPosition.y - floor8(worldPosition.y)) / 8
        if directions.z:
            initialDistances.z = perBlockDistances.z * (ceil8(worldPosition.z) - worldPosition.z) / 8
        else:
            initialDistances.z = perBlockDistances.z * (worldPosition.z - floor8(worldPosition.z)) / 8
        
        return traceRayOverBlocks(model, dimensions, position, normDir, hitFunctions, hits, worldGridPosition, initialDistances, perBlockDistances, directions)



