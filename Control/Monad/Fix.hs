-----------------------------------------------------------------------------
-- 
-- Module      :  Control.Monad.Fix
-- Copyright   :  (c) Andy Gill 2001,
--		  (c) Oregon Graduate Institute of Science and Technology, 2001
-- License     :  BSD-style (see the file libraries/core/LICENSE)
-- 
-- Maintainer  :  libraries@haskell.org
-- Stability   :  experimental
-- Portability :  non-portable (reqruires multi-param type classes)
--
-- $Id: Fix.hs,v 1.1 2001/06/28 14:15:02 simonmar Exp $
--
-- The Fix monad.
--
--	  Inspired by the paper:
--	  \em{Functional Programming with Overloading and
--	      Higher-Order Polymorphism},
--	    \A[HREF="http://www.cse.ogi.edu/~mpj"]{Mark P Jones},
--		  Advanced School of Functional Programming, 1995.}
--
-----------------------------------------------------------------------------

module Control.Monad.Fix (
	MonadFix(
	   mfix	-- :: (a -> m a) -> m a
         ),
	fix	-- :: (a -> a) -> a
  ) where

import Prelude

import System.IO
import Control.Monad.ST


fix :: (a -> a) -> a
fix f = let x = f x in x

class (Monad m) => MonadFix m where
	mfix :: (a -> m a) -> m a

-- Perhaps these should live beside (the ST & IO) definition.
instance MonadFix IO where
	mfix = fixIO

instance MonadFix (ST s) where
	mfix = fixST

instance MonadFix Maybe where
	mfix f = let
		a = f $ case a of
			Just x -> x
			_      -> error "empty mfix argument"
		in a