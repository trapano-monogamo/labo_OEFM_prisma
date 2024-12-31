module LabParameters
( angleError
, lambdas
) where

-- dalle slide... ma non dovrebbe essere 1/(360*60),
-- cioe' un errore di un minuto ?

angleError :: Float
angleError = 1/120


lambdas :: [(String,Float,Float)]
lambdas = [
  ("viola1",  4034.436, 7.582883),
  ("viola2",  4075.0574, 6.112966),
  ("blu",     4353.3726, 7.5737147),
  ("azzurro", 4960, 0), -- tabulato
  ("verde",   5439.302, 13.413318),
  ("giallo1", 5740.5723, 15.568485),
  ("giallo2", 5760.4624, 15.508129),
  ("rosso",   6150, 0)] -- tabulato
