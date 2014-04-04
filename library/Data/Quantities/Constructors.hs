module Data.Quantities.Constructors where

import Data.Quantities.Data (Definitions, CompositeUnit, Quantity(units),
                             QuantityError(..))
import Data.Quantities.DefaultUnits (defaultDefString)
import Data.Quantities.DefinitionParser (readDefinitions)
import Data.Quantities.Definitions (makeDefinitions)
import Data.Quantities.ExprParser (parseExprQuant)

defaultDefinitions :: Either QuantityError Definitions
defaultDefinitions = makeDefinitions $ readDefinitions defaultDefString

d :: Definitions
(Right d) = defaultDefinitions

-- | Create a Quantity by parsing a string. Uses an 'UndefinedUnitError' for
-- undefined units. Handles arithmetic expressions as well.
--
-- >>> fromString "25 m/s"
-- Right 25.0 meter / second
-- >>> fromString "fakeunit"
-- Left (UndefinedUnitError "fakeunit")
-- >>> fromString "ft + 12in"
-- Right 2.0 foot
--
-- Make sure not to use dimensional quantities in exponents.
--
-- >>> fromString "m ** 2"
-- Right 1.0 meter ** 2.0
-- >>> fromString "m ** (2s)"
-- Left (ParserError "Used non-dimensionless exponent in ( Right 1.0 meter ) ** ( Right 2.0 second )")
fromString :: String -> Either QuantityError Quantity
fromString = parseExprQuant d


-- | Parse units from a string. Equivalent to @fmap units . fromString@
--
-- >>> unitsFromString "N * s"
-- Right [newton,second]
unitsFromString :: String -> Either QuantityError CompositeUnit
unitsFromString = fmap units . fromString