module Data.Quantities.Definitions where

import Control.Monad.State
import Data.Either (lefts, rights)
import qualified Data.Map as M
import qualified Text.ParserCombinators.Parsec as P

import Data.Quantities.Convert (convertBase')
import Data.Quantities.Data


makeDefinitions :: [Definition] -> Definitions
makeDefinitions ds = execState (mapM addDefinition ds) emptyDefinitions

addDefinition :: Definition -> State Definitions ()

addDefinition (PrefixDefinition sym fac syns) = modify $
  unionDefinitions emptyDefinitions {
    prefixes         = sym : syns
    , prefixValues   = M.singleton sym fac
    , prefixSynonyms = M.fromList $ zip (sym : syns) (repeat sym) }

addDefinition (BaseDefinition sym utype syns) = modify $
  unionDefinitions emptyDefinitions {
  bases         = M.singleton sym sym
  , conversions = M.singleton (sym, sym) 1
  , unitsList   = sym : syns
  , synonyms    = M.fromList $ zip (sym : syns) (repeat sym)
  , unitTypes   = M.singleton sym utype }

addDefinition (UnitDefinition sym q syns) = do
  -- First, we preprocess the quantity so all units are base units and
  -- prefixes are preprocessed. Then we do the standard Definitions
  -- modification like prefix and base definitions.
  d <- get
  let (Right pq) = preprocessQuantity d q
      (Quantity baseFac baseUnits _) = convertBase' d pq
      baseSym = symbol (head baseUnits)
  modify $ unionDefinitions emptyDefinitions {
    bases         = M.singleton sym baseSym
    , conversions = M.singleton (sym, baseSym) baseFac
    , synonyms    = M.fromList $ zip (sym : syns) (repeat sym)
    , unitsList   = sym : syns }

-- Convert prefixes and synonyms
preprocessQuantity :: Definitions -> Quantity -> Either QuantityError Quantity
preprocessQuantity d (Quantity x us _)
  | null errors = Right $ Quantity x goodUnits d
  | otherwise   = Left  $ head errors
    where ppUnits   = map (preprocessUnit d) us
          goodUnits = rights ppUnits
          errors    = lefts ppUnits

preprocessUnit :: Definitions -> SimpleUnit -> Either QuantityError SimpleUnit
preprocessUnit d (SimpleUnit s _ p)
  | rs `elem` unitsList d = Right $ SimpleUnit ns np p
  | otherwise             = Left  $ UndefinedUnitError s
  where (rp, rs) = prefixParser d s
        np       = prefixSynonyms d M.! rp
        ns       = synonyms d M.! rs


prefixParser :: Definitions -> String -> (String, String)
prefixParser d input = if input `elem` unitsList d then
                          ("", input) else
                          case P.parse (prefixParser' d) "arithmetic" input of
                            Left _ -> ("", input)
                            Right val -> splitAt (length val) input


prefixParser' :: Definitions -> P.Parser String
prefixParser' d = do
  pr <- P.choice $ map (P.try . P.string) (prefixes d)
  _  <- P.choice $ map (P.try . P.string) (unitsList d)
  return pr
