module Week6.Solution where

fib :: Integer -> Integer
fib 0 = 0
fib 1 = 1
fib n = fib (n-1) + fib (n-2)

fibs1 :: [Integer]
fibs1 = map fib [0..] 

fibs2 :: [Integer]
fibs2 = f 0 1
    where f a b = a : f b (a + b)

-----------------------------------------------------------