{-# OPTIONS -fno-implicit-prelude #-}
-----------------------------------------------------------------------------
-- 
-- Module      :  System.IO
-- Copyright   :  (c) The University of Glasgow 2001
-- License     :  BSD-style (see the file libraries/core/LICENSE)
-- 
-- Maintainer  :  libraries@haskell.org
-- Stability   :  provisional
-- Portability :  portable
--
-- $Id: IO.hs,v 1.1 2001/06/28 14:15:04 simonmar Exp $
--
-- The standard IO library.
--
-----------------------------------------------------------------------------

module System.IO (
    Handle,		-- abstract, instance of: Eq, Show.
    HandlePosn(..),     -- abstract, instance of: Eq, Show.

    IOMode(ReadMode,WriteMode,AppendMode,ReadWriteMode),
    BufferMode(NoBuffering,LineBuffering,BlockBuffering),
    SeekMode(AbsoluteSeek,RelativeSeek,SeekFromEnd),

    stdin, stdout, stderr,   -- :: Handle

    openFile,		       -- :: FilePath -> IOMode -> IO Handle
    hClose,		       -- :: Handle -> IO ()
    hFileSize,		       -- :: Handle -> IO Integer
    hIsEOF,		       -- :: Handle -> IO Bool
    isEOF,		       -- :: IO Bool

    hSetBuffering,	       -- :: Handle -> BufferMode -> IO ()
    hGetBuffering,	       -- :: Handle -> IO BufferMode
    hFlush,		       -- :: Handle -> IO ()
    hGetPosn,		       -- :: Handle -> IO HandlePosn
    hSetPosn,		       -- :: HandlePosn -> IO ()
    hSeek,		       -- :: Handle -> SeekMode -> Integer -> IO ()
    hWaitForInput,	       -- :: Handle -> Int -> IO Bool
    hReady,		       -- :: Handle -> IO Bool
    hGetChar,		       -- :: Handle -> IO Char
    hGetLine,		       -- :: Handle -> IO [Char]
    hLookAhead,		       -- :: Handle -> IO Char
    hGetContents,	       -- :: Handle -> IO [Char]
    hPutChar,		       -- :: Handle -> Char -> IO ()
    hPutStr,		       -- :: Handle -> [Char] -> IO ()
    hPutStrLn,		       -- :: Handle -> [Char] -> IO ()
    hPrint,		       -- :: Show a => Handle -> a -> IO ()
    hIsOpen, hIsClosed,        -- :: Handle -> IO Bool
    hIsReadable, hIsWritable,  -- :: Handle -> IO Bool
    hIsSeekable,               -- :: Handle -> IO Bool

    isAlreadyExistsError, isDoesNotExistError,  -- :: IOError -> Bool
    isAlreadyInUseError, isFullError, 
    isEOFError, isIllegalOperation, 
    isPermissionError, isUserError, 

    ioeGetErrorString,	       -- :: IOError -> String
    ioeGetHandle,	       -- :: IOError -> Maybe Handle
    ioeGetFileName,	       -- :: IOError -> Maybe FilePath

    try,		       -- :: IO a -> IO (Either IOError a)
    bracket,		       -- :: IO a -> (a -> IO b) -> (a -> IO c) -> IO c
    bracket_,		       -- :: IO a -> (a -> IO b) -> IO c -> IO c

    -- Non-standard extension (but will hopefully become standard with 1.5) is
    -- to export the Prelude io functions via IO (in addition to exporting them
    -- from the prelude...for now.) 
    IO,
    FilePath,		       -- :: String
    IOError,
    ioError,		       -- :: IOError -> IO a
    userError,		       -- :: String  -> IOError
    catch,		       -- :: IO a    -> (IOError -> IO a) -> IO a
    interact,		       -- :: (String -> String) -> IO ()

    putChar,		       -- :: Char   -> IO ()
    putStr,		       -- :: String -> IO () 
    putStrLn,		       -- :: String -> IO ()
    print,		       -- :: Show a => a -> IO ()
    getChar,		       -- :: IO Char
    getLine,		       -- :: IO String
    getContents,	       -- :: IO String
    readFile,		       -- :: FilePath -> IO String
    writeFile,		       -- :: FilePath -> String -> IO ()
    appendFile,		       -- :: FilePath -> String -> IO ()
    readIO,		       -- :: Read a => String -> IO a
    readLn,		       -- :: Read a => IO a

    hPutBuf,		       -- :: Handle -> Ptr a -> Int -> IO ()
    hGetBuf,		       -- :: Handle -> Ptr a -> Int -> IO Int
 
    fixIO,		       -- :: (a -> IO a) -> IO a
  ) where

#ifdef __GLASGOW_HASKELL__
import GHC.Base
import GHC.IOBase	-- Together these four Prelude modules define
import GHC.Handle	-- all the stuff exported by IO for the GHC version
import GHC.IO
import GHC.ST		( fixST )
import GHC.Exception
import GHC.Num
import GHC.Read
import GHC.Show
#endif

import Data.Dynamic

-- -----------------------------------------------------------------------------
-- Typeable instance for Handle

#include "Dynamic.h"
INSTANCE_TYPEABLE0(Handle,handleTc,"Handle")

-- -----------------------------------------------------------------------------
-- Standard IO

putChar         :: Char -> IO ()
putChar c       =  hPutChar stdout c

putStr          :: String -> IO ()
putStr s        =  hPutStr stdout s

putStrLn        :: String -> IO ()
putStrLn s      =  do putStr s
                      putChar '\n'

print           :: Show a => a -> IO ()
print x         =  putStrLn (show x)

getChar         :: IO Char
getChar         =  hGetChar stdin

getLine         :: IO String
getLine         =  hGetLine stdin

getContents     :: IO String
getContents     =  hGetContents stdin

interact        ::  (String -> String) -> IO ()
interact f      =   do s <- getContents
                       putStr (f s)

readFile        :: FilePath -> IO String
readFile name	=  openFile name ReadMode >>= hGetContents

writeFile       :: FilePath -> String -> IO ()
writeFile name str = do
    hdl <- openFile name WriteMode
    hPutStr hdl str
    hClose hdl

appendFile      :: FilePath -> String -> IO ()
appendFile name str = do
    hdl <- openFile name AppendMode
    hPutStr hdl str
    hClose hdl

readLn          :: Read a => IO a
readLn          =  do l <- getLine
                      r <- readIO l
                      return r

-- raises an exception instead of an error
readIO          :: Read a => String -> IO a
readIO s        =  case (do { (x,t) <- reads s ;
			      ("","") <- lex t ;
                              return x }) of
			[x]    -> return x
			[]     -> ioError (userError "Prelude.readIO: no parse")
			_      -> ioError (userError "Prelude.readIO: ambiguous parse")

hReady		:: Handle -> IO Bool
hReady h 	=  hWaitForInput h 0

hPutStrLn	:: Handle -> String -> IO ()
hPutStrLn hndl str = do
 hPutStr  hndl str
 hPutChar hndl '\n'

hPrint		:: Show a => Handle -> a -> IO ()
hPrint hdl 	=  hPutStrLn hdl . show

-- ---------------------------------------------------------------------------
-- fixIO

#ifdef __GLASGOW_HASKELL__
fixIO 		:: (a -> IO a) -> IO a
fixIO m         = stToIO (fixST (ioToST . m))
#endif