import Control.Monad.State
import Data.Fixed
import qualified Data.Vector as V

newtype Point = Point { fromPoint :: Float } deriving Show

type Index           = Int
type Key             = Float
type SupportDistance = Float
type Grid            = V.Vector [Key]

iParam :: Float
iParam = 16

key :: Index -> Point -> Key
key index (Point point) = (fromIntegral index) + (2 ** iParam) * point

fromKey :: Key -> Index
fromKey key = round $ mod' key (2 ** iParam)

cell :: SupportDistance -> Point -> Int
cell h (Point point) = floor $ (point / h)

makeGrid :: Float -> SupportDistance -> [Point] -> Grid
makeGrid size h points = snd $ runState (distinct cells) $ initial
  where
    toCell (x, i) = (cell h x, key i x)
    cells = map toCell (points `zip` [0..])

    count = length points
    initial = V.generate (ceiling $ size / h) $ \_ -> []

    distinct :: [(Int, Key)] -> State Grid ()
    distinct ((cell, key):cells) = do
      grid <- get
      let row = grid V.! cell
      put $ grid V.// [(cell, row ++ [key])]
      distinct cells
    distinct [] = get >>= put

findNeighbours :: SupportDistance -> Grid -> [Point] -> Index -> [Point]
findNeighbours h grid points index = toPoints (lefts ++ middles ++ rights)
  where
    curPoint = points !! index
    curCell = cell h $ points !! index
    toPoints = map (points!!)
             . map fromKey

    lefts = if curCell > 0 then (grid V.! (curCell - 1)) else []
    middles = grid V.! curCell
    rights = if curCell < ((V.length grid) - 1) then (grid V.! (curCell + 1)) else []

naiveNeighbours :: SupportDistance -> [Point] -> Index -> [Point]
naiveNeighbours h points index = filter close points
  where
    curPoint = fromPoint $ points !! index
    close x = (abs $ curPoint - (fromPoint x)) <= h

main :: IO ()
main = do 
  let points = [ 
                 Point 20,  -- 0
                 Point 30,  -- 1
                 Point 80,  -- 2
                 Point 90,  -- 3
                 Point 10,  -- 4
                 Point 90,  -- 5
                 Point 30,  -- 6
                 Point 120, -- 7
                 Point 160, -- 8
                 Point 50,  -- 9
                 Point 170, -- 10
                 Point 123  -- 11
               ]

  let grid = makeGrid 200 20 points
  let neighbours = findNeighbours 20 grid points 3
  print $ neighbours
  print $ naiveNeighbours 20 points 3
