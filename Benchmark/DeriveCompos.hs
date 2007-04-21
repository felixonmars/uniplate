{-# OPTIONS_GHC -fglasgow-exts #-}

module DeriveCompos where

import Data
import Data.Monoid
import Control.Monad.Identity


instance Compos GExpr where
    compos return ap f t = case t of
        CVal x -> return CVal `ap` return x
        CVar x -> return CVar `ap` return x
        CNeg x -> return CNeg `ap` f x
        CAdd x y -> return CAdd `ap` f x `ap` f y
        CSub x y -> return CSub `ap` f x `ap` f y
        CMul x y -> return CMul `ap` f x `ap` f y
        CDiv x y -> return CDiv `ap` f x `ap` f y


-- stuff from the Compos module

class Compos t where
    compos :: (forall a. a -> m a) -> (forall a b. m (a -> b) -> m a -> m b)
                                   -> (forall a. t a -> m (t a)) -> t c -> m (t c)

composOp :: Compos t => (forall a. t a -> t a) -> t c -> t c
composOp f = runIdentity . composOpM (Identity . f)

composOpM :: (Compos t, Monad m) => (forall a. t a -> m (t a)) -> t c -> m (t c)
composOpM = compos return ap

composOpM_ :: (Compos t, Monad m) => (forall a. t a -> m ()) -> t c -> m ()
composOpM_ = composOpFold (return ()) (>>)

composOpMonoid :: (Compos t, Monoid m) => (forall a. t a -> m) -> t c -> m
composOpMonoid = composOpFold mempty mappend

composOpMPlus :: (Compos t, MonadPlus m) => (forall a. t a -> m b) -> t c -> m b
composOpMPlus = composOpFold mzero mplus

composOpFold :: Compos t => b -> (b -> b -> b) -> (forall a. t a -> b) -> t c -> b
composOpFold z c f = unC . compos (\_ -> C z) (\(C x) (C y) -> C (c x y)) (C . f)

newtype C b a = C { unC :: b }
