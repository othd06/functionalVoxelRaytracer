


import helpers
import math


func traceRayInWorld(model: Model, dimensions: tuple[x, y, z: int], position: Vector3, normDir: Vector3, hitFunctions: array[256, hitFunction], hits: int, gridPosition: tuple[x, y, z: int], distances: Vector3, perBlockDistances: Vector3, directions: tuple[x, y, z: bool], time: int): Colour=
    if distances.x < distances.y and distances.x < distances.z:
        if directions.x:
            let
                newGridPosition: tuple[x, y, z: int] = (gridPosition.x+1, gridPosition.y, gridPosition.z)
                newDistances: Vector3 = Vector3(x: perBlockDistances.x, y: distances.y-distances.x, z: distances.z-distances.x)
                newPosition: Vector3 = position + normDir*distances.x
            if newGridPosition.x >= dimensions.x:
                return hitFunctions[0](model, dimensions, UP, Vector2(x: 0, y: 0), newPosition, normDir, hits, time)
            elif model.data[][modelIndex(newGridPosition.x, newGridPosition.y, newGridPosition.z, model)] != 0:
                return hitFunctions[model.data[][modelIndex(newGridPosition.x, newGridPosition.y, newGridPosition.z, model)]](model, dimensions, WEST, Vector2(x: 1-(newPosition.z - floor(newPosition.z)), y: newPosition.y - floor(newPosition.y)), newPosition, normDir, hits, time)
            else:
                return traceRayInWorld(model, dimensions, newPosition, normDir, hitFunctions, hits, newGridPosition, newDistances, perBlockDistances, directions, time)
        else:
            let
                newGridPosition: tuple[x, y, z: int] = (gridPosition.x-1, gridPosition.y, gridPosition.z)
                newDistances: Vector3 = Vector3(x: perBlockDistances.x, y: distances.y-distances.x, z: distances.z-distances.x)
                newPosition: Vector3 = position + normDir*distances.x
            if newGridPosition.x < 0:
                return hitFunctions[0](model, dimensions, UP, Vector2(x: 0, y: 0), newPosition, normDir, hits, time)
            elif model.data[][modelIndex(newGridPosition.x, newGridPosition.y, newGridPosition.z, model)] != 0:
                return hitFunctions[model.data[][modelIndex(newGridPosition.x, newGridPosition.y, newGridPosition.z, model)]](model, dimensions, EAST, Vector2(x: (newPosition.z - floor(newPosition.z)), y: (newPosition.y - floor(newPosition.y))), newPosition, normDir, hits, time)
            else:
                return traceRayInWorld(model, dimensions, newPosition, normDir, hitFunctions, hits, newGridPosition, newDistances, perBlockDistances, directions, time)
    elif distances.y < distances.z:
        if directions.y:
            let
                newGridPosition: tuple[x, y, z: int] = (gridPosition.x, gridPosition.y+1, gridPosition.z)
                newDistances: Vector3 = Vector3(x: distances.x - distances.y, y: perBlockDistances.y, z: distances.z - distances.y)
                newPosition: Vector3 = position + normDir*distances.y
            if newGridPosition.y >= dimensions.y:
                return hitFunctions[0](model, dimensions, UP, Vector2(x: 0, y: 0), newPosition, normDir, hits, time)
            elif model.data[][modelIndex(newGridPosition.x, newGridPosition.y, newGridPosition.z, model)] != 0:
                return hitFunctions[model.data[][modelIndex(newGridPosition.x, newGridPosition.y, newGridPosition.z, model)]](model, dimensions, DOWN, Vector2(x: newPosition.x - floor(newPosition.x), y: newPosition.z - floor(newPosition.z)), newPosition, normDir, hits, time)
            else:
                return traceRayInWorld(model, dimensions, newPosition, normDir, hitFunctions, hits, newGridPosition, newDistances, perBlockDistances, directions, time)
        else:
            let
                newGridPosition: tuple[x, y, z: int] = (gridPosition.x, gridPosition.y-1, gridPosition.z)
                newDistances: Vector3 = Vector3(x: distances.x - distances.y, y: perBlockDistances.y, z: distances.z - distances.y)
                newPosition: Vector3 = position + normDir*distances.y
            if newGridPosition.y < 0:
                return hitFunctions[0](model, dimensions, UP, Vector2(x: 0, y: 0), newPosition, normDir, hits, time)
            elif model.data[][modelIndex(newGridPosition.x, newGridPosition.y, newGridPosition.z, model)] != 0:
                return hitFunctions[model.data[][modelIndex(newGridPosition.x, newGridPosition.y, newGridPosition.z, model)]](model, dimensions, UP, Vector2(x: (newPosition.x - floor(newPosition.x)), y: (newPosition.z - floor(newPosition.z))), newPosition, normDir, hits, time)
            else:
                return traceRayInWorld(model, dimensions, newPosition, normDir, hitFunctions, hits, newGridPosition, newDistances, perBlockDistances, directions, time)
    else:
        if directions.z:
            let
                newGridPosition: tuple[x, y, z: int] = (gridPosition.x, gridPosition.y, gridPosition.z+1)
                newDistances: Vector3 = Vector3(x: distances.x - distances.z, y: distances.y - distances.z, z: perBlockDistances.z)
                newPosition: Vector3 = position + normDir*distances.z
            if newGridPosition.z >= dimensions.z:
                return hitFunctions[0](model, dimensions, UP, Vector2(x: 0, y: 0), newPosition, normDir, hits, time)
            elif model.data[][modelIndex(newGridPosition.x, newGridPosition.y, newGridPosition.z, model)] != 0:
                return hitFunctions[model.data[][modelIndex(newGridPosition.x, newGridPosition.y, newGridPosition.z, model)]](model, dimensions, SOUTH, Vector2(x: newPosition.x - floor(newPosition.x), y: newPosition.y - floor(newPosition.y)), newPosition, normDir, hits, time)
            else:
                return traceRayInWorld(model, dimensions, newPosition, normDir, hitFunctions, hits, newGridPosition, newDistances, perBlockDistances, directions, time)
        else:
            let
                newGridPosition: tuple[x, y, z: int] = (gridPosition.x, gridPosition.y, gridPosition.z-1)
                newDistances: Vector3 = Vector3(x: distances.x - distances.z, y: distances.y - distances.z, z: perBlockDistances.z)
                newPosition: Vector3 = position + normDir*distances.z
            if newGridPosition.z < 0:
                return hitFunctions[0](model, dimensions, UP, Vector2(x: 0, y: 0), newPosition, normDir, hits, time)
            elif model.data[][modelIndex(newGridPosition.x, newGridPosition.y, newGridPosition.z, model)] != 0:
                return hitFunctions[model.data[][modelIndex(newGridPosition.x, newGridPosition.y, newGridPosition.z, model)]](model, dimensions, NORTH, Vector2(x: 1-(newPosition.x - floor(newPosition.x)), y: (newPosition.y - floor(newPosition.y))), newPosition, normDir, hits, time)
            else:
                return traceRayInWorld(model, dimensions, newPosition, normDir, hitFunctions, hits, newGridPosition, newDistances, perBlockDistances, directions, time)

func traceRay*(model: Model, dimensions: tuple[x, y, z: int], position: Vector3, direction: Vector3, hitFunctionsP: ptr array[256, hitFunction], hits: int = 0, time: int): Colour {.gcsafe.}=
    let
        normDir = normalise(direction)
        hitFunctions = hitFunctionsP[]
    if (abs(position.x) > dimensions.x/2) or (abs(position.y) > dimensions.y/2) or (abs(position.z) > dimensions.z/2):
        #We are outside the world
        var
            distsAABB: array[6, float]
            minDist: float = (dimensions.x.float+dimensions.y.float+dimensions.z.float)*3
        if normDir.x != 0:
            distsAABB[0] = ((-dimensions.x/2)-position.x) / normDir.x
            distsAABB[1] = (( dimensions.x/2)-position.x) / normDir.x
        if normDir.y != 0:
            distsAABB[2] = ((-dimensions.y/2)-position.y) / normDir.y
            distsAABB[3] = (( dimensions.y/2)-position.y) / normDir.y
        if normDir.z != 0:
            distsAABB[4] = ((-dimensions.z/2)-position.z) / normDir.z
            distsAABB[5] = (( dimensions.z/2)-position.z) / normDir.z
        for i in 0..<6:
            if distsAABB[i] > 0 and distsAABB[i] < minDist:
                minDist = distsAABB[i]
        if minDist > (dimensions.x.float+dimensions.y.float+dimensions.z.float)*2:
            return hitFunctions[0](model, dimensions, UP #[This is arbitrary in the case that no voxel is hit]#, Vector2(x: 0, y: 0), position, direction, hits, time)
        return traceRay(model, dimensions, position + normDir*minDist, direction, hitFunctionsP, hits, time)
    else:
        let
            worldPosition: Vector3 = position + Vector3(x: dimensions.x/2, y: dimensions.y/2, z: dimensions.z/2)
            worldGridPosition: tuple[x, y, z: int] = (floor(worldPosition.x).int, floor(worldPosition.y).int, floor(worldPosition.z).int)
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
            perBlockDistances = Vector3(x: length(xDir), y: length(yDir), z: length(zDir))
        var
            initialDistances: Vector3
        if directions.x:
            initialDistances.x = perBlockDistances.x * (ceil(worldPosition.x) - worldPosition.x)
        else:
            initialDistances.x = perBlockDistances.x * (worldPosition.x - floor(worldPosition.x))
        if directions.y:
            initialDistances.y = perBlockDistances.y * (ceil(worldPosition.y) - worldPosition.y)
        else:
            initialDistances.y = perBlockDistances.y * (worldPosition.y - floor(worldPosition.y))
        if directions.z:
            initialDistances.z = perBlockDistances.z * (ceil(worldPosition.z) - worldPosition.z)
        else:
            initialDistances.z = perBlockDistances.z * (worldPosition.z - floor(worldPosition.z))
        
        return traceRayInWorld(model, dimensions, position, normDir, hitFunctions, hits, worldGridPosition, initialDistances, perBlockDistances, directions, time)



