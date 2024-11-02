module Main (main) where

import System.IO

import Statistics.Distribution
import Statistics.Distribution.StudentT

import Analysis
import LabParameters


colorRed = "\ESC[31m" :: String
colorGreen = "\ESC[32m" :: String
colorDefault = "\ESC[0m" :: String


weightedAverage :: [(Float,Float)] -> (Float,Float)
weightedAverage l = ( avg, err )
  where (xs,ws) = unzip $ map (\(x,y) -> (x, 1 / (y**2))) l
        avg = (sum (zipWith (*) xs ws)) / (sum ws)
        err = sqrt (1 / (sum ws))


stdAverage :: [(Float,Float)] -> (Float,Float)
stdAverage l = ( avg, sqrt $ var / (fromIntegral $ length xs) )
  where (xs,_) = unzip l
        avg = (sum xs) / (fromIntegral $ length xs)
        var = (sum $ map (\x -> (x - avg)**2) xs) / ((fromIntegral $ length xs) - 1)



singleTailCriticalTValue :: Float -> Int -> Float
singleTailCriticalTValue significance df = realToFrac $ quantile (studentT $ fromIntegral df) (1 - realToFrac significance)

doubleTailCriticalTValue :: Float -> Int -> Float
doubleTailCriticalTValue significance df = realToFrac $ q2 - q1
  where alpha = significance / 2
        q1 = quantile (studentT $ fromIntegral df) (realToFrac alpha)
        q2 = quantile (studentT $ fromIntegral df) (1 - realToFrac alpha)



simpleParser :: String -> [[Float]]
simpleParser = filter (not . null) . map (map read) . (map words) . lines



data TTest = ConfidenceInterval Float | SignificanceTest Float Float | NoTest

-- makeTTest :: Int -> Float -> IO ()
-- makeTTest df scaleFactor = {- ... -}



processFile :: String ->                               -- filename
               (String -> [[Float]]) ->                -- parser
               ([[Float]] -> [Float]) ->               -- operation on dataset
               ([[Float]] -> [Float]) ->               -- dataset errors
               ([(Float,Float)] -> (Float,Float)) ->   -- avg+-err statistical estimator
               String ->                               -- measurement units
               Float ->                                -- scale factor
               TTest ->                                -- t-test
               IO (Float, Float)                       -- return (avg,err)
processFile path parseContents processData calcErrors bestEstimate units scaleFactor ttest = do
  putStrLn $ colorGreen ++ "\n[*] Processing " ++ path ++ colorDefault

  withFile path ReadMode (\handle -> do
    -- read file, get the data and calculate stuff
    contents <- hGetContents handle
    let rawData = parseContents contents
        processedData = processData rawData
        errors = calcErrors rawData
        (avg, err) = bestEstimate $ zip processedData errors
        degOfFreedom = (length processedData) - 1 -- 1 because average is the only constraint

    putStrLn "\nResults:"
    _ <- sequence $ map
      (\(x,e) -> putStrLn $ (show $ scaleFactor * x) ++ " +- " ++ (show $ scaleFactor * e) ++ " " ++ units)
      $ zip processedData errors

    putStrLn "\nFinal Measure:"
    putStrLn $ (show $ scaleFactor * avg) ++ " +- " ++ (show $ scaleFactor * err) ++ " " ++ units

    case ttest of
      -- consider implementing a way of testing against multiple significance levels
      SignificanceTest expectedValue significance -> do
        let t0 = (abs $ avg - expectedValue) / err
            tc = singleTailCriticalTValue significance degOfFreedom
            p0 = cumulative (studentT $ fromIntegral degOfFreedom) (realToFrac $ -t0)
            pc = cumulative (studentT $ fromIntegral degOfFreedom) (realToFrac $ -tc)
        putStrLn $ "\nStatistical Significance at " ++ (show $ 100 * significance) ++ "% for expected value of " ++ (show $ scaleFactor * expectedValue) ++ ":"
        putStrLn $ "t0:  P(-inf <= -" ++ (show t0) ++ ") = " ++ (show $ 100 * p0) ++ "%"
        putStrLn $ "t_c: P(-inf <= -" ++ (show tc) ++ ") = " ++ (show $ 100 * pc) ++ "%" -- just to check: P(<=tc) should be equal to significance
      ConfidenceInterval confidence -> do
        let tc = doubleTailCriticalTValue confidence degOfFreedom
            lowerBound = avg - tc * err
            upperBound = avg + tc * err
        putStrLn $ "\nMargins of error for confidence level of " ++ (show $ 100 * confidence) ++ "%:"
        putStrLn $ "tc = " ++ (show tc) ++ ": (" ++ (show $ scaleFactor * lowerBound) ++ ", " ++ (show $ scaleFactor * upperBound) ++ ")"
      NoTest -> do putStrLn "\nNo test to see here..."

    -- return results of calculations
    return (avg, err))



-- ..:: Entry Point ::..

lambdaMeasurements :: Float -> [IO (Float,Float)]
lambdaMeasurements midPoint = [
  (processFile "./data/misure_viola1.csv"  (simpleParser) (calcDeltaMins midPoint) (calcDeltaMinErrors midPoint) (stdAverage) "rad" (1) (NoTest)),
  (processFile "./data/misure_viola2.csv"  (simpleParser) (calcDeltaMins midPoint) (calcDeltaMinErrors midPoint) (stdAverage) "rad" (1) (NoTest)),
  (processFile "./data/misure_blu.csv"     (simpleParser) (calcDeltaMins midPoint) (calcDeltaMinErrors midPoint) (stdAverage) "rad" (1) (NoTest)),
  (processFile "./data/misure_azzurro.csv" (simpleParser) (calcDeltaMins midPoint) (calcDeltaMinErrors midPoint) (stdAverage) "rad" (1) (NoTest)),
  (processFile "./data/misure_verde.csv"   (simpleParser) (calcDeltaMins midPoint) (calcDeltaMinErrors midPoint) (stdAverage) "rad" (1) (NoTest)),
  (processFile "./data/misure_giallo1.csv" (simpleParser) (calcDeltaMins midPoint) (calcDeltaMinErrors midPoint) (stdAverage) "rad" (1) (NoTest)),
  (processFile "./data/misure_giallo2.csv" (simpleParser) (calcDeltaMins midPoint) (calcDeltaMinErrors midPoint) (stdAverage) "rad" (1) (NoTest)),
  (processFile "./data/misure_rosso.csv"   (simpleParser) (calcDeltaMins midPoint) (calcDeltaMinErrors midPoint) (stdAverage) "rad" (1) (NoTest))]

main :: IO ()
main = do
  (alpha,alphaErr)       <- processFile "./data/misure_alfa.csv"     (simpleParser) (calcAlphas)    (calcAlphaErrors)    (stdAverage) "rad" (1) (NoTest)
  (midPoint,midPointErr) <- processFile "./data/misure_midpoint.csv" (simpleParser) (calcMidPoints) (calcMidPointErrors) (stdAverage) "rad" (1) (NoTest)
  resultsTmp <- sequence (lambdaMeasurements midPoint)

  let (deltaMins,deltaMinErrs) = unzip resultsTmp
      refIdxs = map (calcRefractionIndex alpha) deltaMins
      refIdxErrs = map (\(dm,dmErr) -> calcRefractionIndexError alpha alphaErr dm dmErr) $ zip deltaMins deltaMinErrs

  putStrLn $ colorGreen ++ "\n[*] calculating delta mins" ++ colorDefault
  putStrLn "\nResults:"
  _ <- sequence $ map (\(v,e) -> putStrLn $ (show v) ++ " +- " ++ (show e)) $ zip deltaMins deltaMinErrs

  putStrLn $ colorGreen ++ "\n[*] calculating refraction indices" ++ colorDefault
  putStrLn "\nResults:"
  _ <- sequence $ map (\(v,e) -> putStrLn $ (show v) ++ " +- " ++ (show e)) $ zip refIdxs refIdxErrs

  return ()
