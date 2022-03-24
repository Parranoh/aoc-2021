import Data.List (foldl')
import qualified Data.Map.Strict as M

data State = State { w :: Int, x :: Int, y :: Int, z :: Int }
    deriving (Eq,Ord)

data Var = Var { get :: State -> Int, set :: Int -> State -> State }
vw, vx, vy, vz :: Var
vw = Var w (\iw (State _ ix iy iz) -> State iw ix iy iz)
vx = Var x (\ix (State iw _ iy iz) -> State iw ix iy iz)
vy = Var y (\iy (State iw ix _ iz) -> State iw ix iy iz)
vz = Var z (\iz (State iw ix iy _) -> State iw ix iy iz)
readVar :: String -> Var
readVar "w" = vw
readVar "x" = vx
readVar "y" = vy
readVar "z" = vz
readVar v   = error $ "unknown variable " ++ v

data Op = Imm Int | Reg Var
op :: Op -> State -> Int
op (Imm i) _ = i
op (Reg v) s = get v s
readOp :: String -> Op
readOp "w" = Reg vw
readOp "x" = Reg vx
readOp "y" = Reg vy
readOp "z" = Reg vz
readOp imm = Imm (read imm)

data Instr
    = Inp Var
    | Cal (Int -> Int -> Int) Var Op
readInstr :: String -> Instr
readInstr line = case words line of
    ["inp",v] -> Inp (readVar v)
    [f,v,o]   -> Cal (readFunc f) (readVar v) (readOp o)
    _         -> error $ "failed to read instruction" ++ line
readFunc :: String -> Int -> Int -> Int
readFunc "add" = (+)
readFunc "mul" = (*)
readFunc "div" = div
readFunc "mod" = mod
readFunc "eql" = ((.).(.)) fromEnum (==)
readFunc f = error $ "unknown function" ++ f

dedup :: [(State,Int)] -> [(State,Int)]
dedup = M.toList . M.fromListWith min

exec :: Instr -> [(State,Int)] -> [(State,Int)]
exec (Inp v)     ss = dedup [ (set v i s,10 * is + i) | (s,is) <- ss, i <- [1..9] ]
exec (Cal f v o) ss = dedup [ (set v (get v s `f` op o s) s,is) | (s,is) <- ss ]

solve :: [Instr] -> Int
solve = minimum . map snd . filter ((== 0) . z . fst) . foldl' (flip exec) [(State 0 0 0 0,0)]

main :: IO ()
main = interact $ show . solve . map readInstr . lines
