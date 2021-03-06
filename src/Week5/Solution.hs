{-# LANGUAGE FlexibleInstances #-}
module Week5.Solution where

import Week5.ExprT
import Week5.Parser
import qualified Week5.StackVM as S
import qualified Data.Map as M
import Data.Maybe

eval :: ExprT -> Integer
eval (Lit l) = l
eval (Add exp1 exp2) = eval exp1 + eval exp2
eval (Mul exp1 exp2) = eval exp1 * eval exp2

test1 =
  print $ eval (Mul (Add (Lit 2) (Lit 3)) (Lit 4)) == 20
-----------------------------------------------------------

evalStr :: String -> Maybe Integer
evalStr s = case parseExp Lit Add Mul s of
            Nothing -> Nothing
            Just p -> Just $ eval p

test2 = do
  print $ evalStr "(2+3)*4" == Just 20
  print $ evalStr "2+3*4" == Just 14
  print $ evalStr "2+3*" == Nothing         
-----------------------------------------------------------

class Expr a where
    lit :: Integer -> a
    add :: a -> a -> a
    mul :: a -> a -> a

instance Expr ExprT where
    lit = Lit
    add = Add
    mul = Mul

reify :: ExprT -> ExprT
reify = id

test3 = do
  print $ (reify $ mul (add (lit 2) (lit 3)) (lit 4))
    == Mul (Add (Lit 2) (Lit 3)) (Lit 4)
-----------------------------------------------------------

instance Expr Integer where
    lit = id
    add = (+)
    mul = (*)

instance Expr Bool where
    lit x = x > 0
    add = (||)
    mul = (&&)

newtype MinMax = MinMax Integer deriving (Eq, Show)

instance Expr MinMax where
    lit = MinMax
    add (MinMax x) (MinMax y) = MinMax (x + y)
    mul (MinMax x) (MinMax y) = MinMax (x * y)

newtype Mod7 = Mod7 Integer deriving (Eq, Show)

instance Expr Mod7 where
    lit = Mod7 . (`mod` 7)
    add (Mod7 x) (Mod7 y) = Mod7 ((x+y) `mod` 7)
    mul (Mod7 x) (Mod7 y) = Mod7 ((x*y) `mod` 7)

testExp :: Expr a => Maybe a
testExp = parseExp lit add mul "(3 * -4) + 5"

test4 = do
  mapM_ print (testExp :: Maybe Integer)
  mapM_ print (testExp :: Maybe Bool)
  mapM_ print (testExp :: Maybe MinMax)
  mapM_ print (testExp :: Maybe Mod7)
-----------------------------------------------------------

instance Expr S.Program where
    lit i = [S.PushI i]
    add a b = a ++ b ++ [S.Add]
    mul a b = a ++ b ++ [S.Mul]

compile :: String -> Maybe S.Program
compile = parseExp lit add mul

evalStack :: String -> Either String S.StackVal
evalStack = S.stackVM . fromMaybe [] . compile

test5 = do
    let Just exp = compile "(2+3)*4"
    print exp

    let Right v = evalStack "(2+3)*4"
    print v
-----------------------------------------------------------
class HasVars a where
    var :: String -> a

data VarExprT = VLit Integer
              | VAdd VarExprT VarExprT
              | VMul VarExprT VarExprT
              | Var String
    deriving (Eq, Show)

instance HasVars VarExprT where
    var = Var

instance Expr VarExprT where
    lit = VLit
    add = VAdd
    mul = VMul

type MapExpr = M.Map String Integer -> Maybe Integer

instance HasVars MapExpr where
    var = M.lookup

instance Expr MapExpr where
    lit a = (\_ -> Just a)
    add a b = (\vs -> (+) <$> a vs <*> b vs)
    mul a b = (\vs -> (*) <$> a vs <*> b vs)

withVars :: [(String, Integer)]
         -> (M.Map String Integer -> Maybe Integer)
         -> Maybe Integer
withVars vs mexp = mexp $ M.fromList vs

test6 = do
  print $ withVars [("x", 6)] $ add (lit 3) (var "x")
  print $ withVars [("x", 6)] $ add (lit 3) (var "y")
  print $ withVars [("x", 6), ("y", 3)]
    $ mul (var "x") (add (var "y") (var "x"))