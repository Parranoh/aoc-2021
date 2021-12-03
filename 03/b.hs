-- Turns out this particular task is very hard in SQL when DBMSs don't implement
-- mutually recursive CTEs.
import Numeric (readInt)

main = interact $ show . solve . lines

solve :: [String] -> Integer
solve = (\xs -> go (==) xs * go (/=) xs) . map (\x -> (x,x))
    where
        go _ [(x,_)] = readBin x
        go p xs      = go p . (map $ fmap tail) . filter (p (mode . map (head . snd) $ xs) . head . snd) $ xs

readBin :: String -> Integer
readBin = fst . head . readInt 2 (const True) (\c -> if c == '1' then 1 else 0)

mode :: [Char] -> Char
mode = go (0,0)
    where
        go (n0,n1) []
            | n0 > n1   = '0'
            | otherwise = '1'
        go (n0,n1) ('0':xs) = go (succ n0,n1) xs
        go (n0,n1) (_  :xs) = go (n0,succ n1) xs
