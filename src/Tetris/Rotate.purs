module Tetris.Rotate where

import Prelude
import Config

import Data.Foldable
import Data.Ord

import Tetris.Shape
import Tetris.Types
import Tetris.Rotation.Helper

rotation :: Shape -> Rotation -> Block Coordinate -> Block Coordinate
rotation sh rot bc = checkSides $ blocksToCoord x y coordNum
  where
    x        = coords.x
    y        = coords.y
    coordNum = rotationToCoords rot sh
    coords   = f3 bc sh rot

rotationToCoords :: Rotation -> Shape -> Block Number
rotationToCoords rt sh = case rt of
  One   -> tr.one
  Two   -> tr.two
  Three -> tr.three
  Four  -> tr.four

  where
    tr = rotations sh

nextRotation :: Rotation -> Int -> Rotation
nextRotation rt kc = if kc == 38 then nextRotation' rt else rt

nextRotation' :: Rotation -> Rotation
nextRotation' One   = Two
nextRotation' Two   = Three
nextRotation' Three = Four
nextRotation' Four  = One

rotationPointsFromShape :: Shape -> ShapesRotationPoints -> RotationPoints
rotationPointsFromShape L         srp = srp.l
rotationPointsFromShape Z         srp = srp.z
rotationPointsFromShape T         srp = srp.t
rotationPointsFromShape S         srp = srp.s
rotationPointsFromShape MirroredL srp = srp.mirrl
rotationPointsFromShape Line      srp = srp.line
rotationPointsFromShape Square    srp = srp.square

f2 :: RotationPoints -> Rotation -> { x :: Number, y :: Number }
f2 z One   = z.one
f2 z Two   = z.two
f2 z Three = z.three
f2 z Four  = z.four

f3 :: Block Coordinate -> Shape -> Rotation -> { x :: Number, y :: Number }
f3 bc sh rot = (flip f2) rot <<< rotationPointsFromShape sh <<< rotationCoords $ bc

moveOutOfBoundsX :: Number -> (Number -> Number -> Number) -> (Number -> Number -> Number) -> Block Coordinate -> Block Coordinate
moveOutOfBoundsX num f1 f2 (Block a b c d) = moveX
  where
    moveX       = Block {x: (xxx a.x), y: a.y}  {x: (xxx b.x), y: b.y} {x: (xxx c.x), y: c.y} {x: (xxx d.x), y: d.y}
    xxx         = if outOfBounds < 0.0 || outOfBounds >= canvasWidth then f2 ((((abs outOfBounds) - num) / blockWidth) * blockWidth) else identity
    outOfBounds = foldl (\a b -> f1 a b.x) num [a, b, c, d]

moveOutOfBoundsY :: Number -> (Number -> Number -> Number) -> (Number -> Number -> Number) -> Block Coordinate -> Block Coordinate
moveOutOfBoundsY num f1 f2 (Block a b c d) = moveX
  where
    moveX       = Block {x: a.x, y: xxx a.y}  {x: b.x, y: xxx b.y} {x: c.x, y: xxx c.y} {x: d.x, y: xxx d.y}
    xxx         = if outOfBounds < 0.0 || outOfBounds >= canvasHeight then f2 ((((abs outOfBounds) - num) / blockWidth) * blockWidth) else identity
    outOfBounds = foldl (\a b -> f1 a b.y) num [a, b, c, d]

moveOutOfBoundsXRight  = moveOutOfBoundsX (canvasWidth  - blockWidth)  max (flip (-))
moveOutOfBoundsXBottom = moveOutOfBoundsY (canvasHeight - blockHeight) max (flip (-))
moveOutOfBoundsXLeft   = moveOutOfBoundsX 0.0                          min (+)
moveOutOfBoundsXTop    = moveOutOfBoundsY 0.0                          min (+)

checkSides = moveOutOfBoundsXTop <<< moveOutOfBoundsXBottom <<< moveOutOfBoundsXLeft <<< moveOutOfBoundsXRight
