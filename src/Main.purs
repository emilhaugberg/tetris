module Main where

import Prelude
import Config as Config

import Data.Maybe (Maybe(..))
import Data.Traversable
import Data.Unit
import Effect (Effect)
import Effect.Console (log)
import Effect.Random
import Effect.Ref
import Effect.Timer
import Graphics.Canvas
import Tetris.Shape  as Tetris
import Tetris.Draw   as Tetris
import Tetris.Move   as Tetris
import Tetris.Rotate as Tetris
import Web.Event.Event
import Web.Event.EventTarget
import Web.Event.Internal.Types

foreign import window  :: EventTarget
foreign import keyCode :: Event -> Int

type X =
  { shape    :: Tetris.Shape
  , pos      :: Tetris.Block Config.Coordinate
  , rotation :: Tetris.Rotation
  }

type State =
  { current :: X
  , previous:: Array X
  }

initialState :: State
initialState = {current: {shape: s, pos: Tetris.initialPos s, rotation: Tetris.Two}, previous: []}
  where
    s = Tetris.T

keydownEvent :: EventType
keydownEvent = EventType "keydown"

updatePos :: Tetris.Block Config.Coordinate -> Tetris.Block Config.Coordinate
updatePos = map \p -> {x: p.x, y: p.y + Config.blockHeight}

keyPress :: Ref State -> Event -> Effect Unit
keyPress ref e = void $ modify move' ref
  where
    move' c =
      { current: { shape   : c.current.shape
                 , pos     : Tetris.nextCoord (keyCode e) c.current.shape c.current.rotation c.current.pos
                 , rotation: Tetris.nextRotation c.current.rotation (keyCode e)}
      , previous: c.previous
      }

eventL :: Ref State -> Effect EventListener
eventL ref = eventListener (keyPress ref)

randomShape :: Unit -> Effect Tetris.Shape
randomShape _ = Tetris.intToShape <$> randomInt 1 7

main :: Partial => Effect Unit
main = void  do
  Just canvas <- getCanvasElementById "tetris-canvas"
  ctx         <- getContext2D canvas
  state       <- new initialState
  evF         <- eventL state

  addEventListener keydownEvent evF false window

  _ <- setInterval 50 $ void do
    clearRect ctx {x: 0.0, y: 0.0, width: Config.canvasWidth, height: Config.canvasHeight}
    Tetris.drawGrid  Config.numHorizontalBlocks Config.numVerticalBlocks ctx

    s <- read state

    Tetris.drawShape s.current.pos s.current.shape ctx

  setInterval 10000000 $ void do
    modify (\c -> {current: {shape: c.current.shape, pos: Tetris.moveBlocks Tetris.Down c.current.pos, rotation: c.current.rotation}, previous: c.previous}) state
