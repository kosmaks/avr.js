import qualified Data.Vec as V
import Graphics.Gnuplot.Simple

type    Vec       = V.Vec2 Float
newtype Distance  = Distance  { getDistance  :: Float } deriving Show
newtype Mass      = Mass      { getMass      :: Float } deriving Show
newtype Density   = Density   { getDensity   :: Float } deriving Show
newtype GPressure = GPressure { getGPressure :: Vec   } deriving Show

data World = World { k  :: Float,
                     r0 :: Float } deriving Show

data Liquid = Liquid { m     :: Mass,
                       h     :: Distance,
                       parts :: [Vec] } deriving Show

-- Helpers

kernel :: Distance -> Vec -> Float
kernel (Distance h) dist = let
  length2 = (V.norm dist) ** 2
  coef    = (315.0 / (64.0 * pi * (h ** 9)))
  h2      = h ** 2
  in
  coef * (h2 - length2) ** 3

gradKernel :: Distance -> Vec -> Vec
gradKernel (Distance h) dist = let
  coef = -45.0 / (pi * (h ** 6))
  length = V.norm dist
  scaled = V.map (/length) dist
  mult = coef * ((h - length) ** 2)
  in
  V.map (*mult) scaled

grad2Kernel :: Distance -> Vec -> Float
grad2Kernel (Distance h) dist = let
  coef = 45.0 / (pi * (h ** 6))
  length = V.norm dist
  in
  coef * (h - length)

isNeighbour :: Liquid -> Vec -> Vec -> Bool
isNeighbour (Liquid _ (Distance h) _) curPart neiPart = 
  isntCurrent && isClose
  where isClose = (V.norm (neiPart - curPart)) < h
        isntCurrent = neiPart /= curPart

density :: Liquid -> Vec -> Density
density liquid curPart = 
  Density $ sum $ map process neis
  where 
    neis = filter (isNeighbour liquid curPart) (parts liquid)
    process neiPart = (getMass $ m liquid) 
                    * (kernel (h liquid) (curPart - neiPart))

densities :: Liquid -> [Density]
densities liquid = map (density liquid) (parts liquid)

gpressure :: World -> Liquid -> [Density] -> (Vec, Density) -> GPressure
gpressure world liquid densities (curPart, curDens) =
  GPressure $ sum $ map process neis
  where
    pairs = zip (parts liquid) densities
    neis = filter ((isNeighbour liquid curPart) . fst) pairs
    pres x = (k world) * (x - (r0 world))
    process (neiPart, neiDens) = let
      curDensF = getDensity curDens
      neiDensF = getDensity neiDens
      mult = (getMass $ m liquid)
           * (((pres curDensF) / (curDensF ** 2))
           +  ((pres neiDensF) / (neiDensF ** 2)))
      in
      V.map (*mult) (gradKernel (h liquid) (curPart - neiPart))

gpressures :: World -> Liquid -> [Density] -> [GPressure]
gpressures world liquid densities = map 
                                    (gpressure world liquid densities) 
                                    (zip (parts liquid) densities)

-- Main program

plotState :: [Vec] -> [GPressure] -> [Density] -> IO ()
plotState vecs pres dens = do
  plotPaths [] $ zipWith zipper vecsT presT
  where toTuple (x V.:. y V.:. _) = (x, y)
        vecsT = map toTuple vecs
        presT = map toTuple $ map getGPressure pres
        zipper x y = [x, y]

toVecs :: [Float] -> Vec
toVecs = V.fromList

main = do
  let points = map toVecs [[0.25, 0.25],
                           [0.25, 0.75],
                           [0.75, 0.25],
                           [0.75, 0.75]]

  let world = World { k  = 0.001,
                      r0 = 1.0 }

  let liquid = Liquid { m = Mass 1.0,
                        h = Distance 0.8,
                        parts = points }

  let dens = densities liquid
  let pres = gpressures world liquid dens
  print $ dens
  print $ pres

  plotState (parts liquid) pres dens

  -- dirty hack
  _ <- readLn :: IO String
  print "done"
