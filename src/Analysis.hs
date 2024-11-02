module Analysis
( calcAlphas
, calcAlphaErrors
, calcDeltaMins
, calcDeltaMinErrors
, calcMidPoints
, calcMidPointErrors
, calcRefractionIndex
, calcRefractionIndexError
) where

import LabParameters



getRadians :: Float -> Float -> Float
getRadians degs mins = (2 * pi / 360) * (degs + mins / 60)

onlyAngleError :: [[Float]] -> [Float]
onlyAngleError = map (\_ -> angleError * (sqrt 2))



calcAlphas :: [[Float]] -> [Float]
calcAlphas = map op
  where op (d1:m1:d2:m2:[]) = abs $ pi - (abs $ angle1 - angle2)
          where angle1 = getRadians d1 m1
                angle2 = getRadians d2 m2
        op _ = 0

calcAlphaErrors :: [[Float]] -> [Float]
calcAlphaErrors = onlyAngleError



calcMidPoints :: [[Float]] -> [Float]
calcMidPoints = map op
  where op (degs:mins:[]) = getRadians degs mins
        op _ = 0

calcMidPointErrors :: [[Float]] -> [Float]
calcMidPointErrors = onlyAngleError



calcDeltaMins :: Float -> [[Float]] -> [Float]
calcDeltaMins midPoint = map (op midPoint)
  where op t0 (degs:mins:[]) = abs $ t0 - getRadians degs mins
        op _ _ = 0

calcDeltaMinErrors :: Float -> [[Float]] -> [Float]
calcDeltaMinErrors _ = onlyAngleError



calcRefractionIndex :: Float -> Float -> Float
calcRefractionIndex alpha deltaMin = (sin $ (alpha + deltaMin) / 2) / (sin $ alpha / 2)

calcRefractionIndexError :: Float -> Float -> Float -> Float -> Float
calcRefractionIndexError alpha alphaErr deltaMin deltaMinErr = sqrt $ (alphaErr * term1)**2 + (deltaMinErr * term2)**2
  where term1 = (1 / (sin ahalf) ** 2) * term12
        term12 = (1/2) * ((cos aplusdhalf) * (sin ahalf) - (cos ahalf) * (sin aplusdhalf))
        term2 = (1/2) * (1 / (sin ahalf)) * (cos aplusdhalf)
        aplusdhalf = (alpha + deltaMin) / 2
        ahalf = alpha / 2
