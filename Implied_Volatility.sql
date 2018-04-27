CREATE FUNCTION ImpliedVolatility( CallOrPut varchar(20), S double, K double, r double, T double, q double, OptionValue double, guess double )
  RETURNS double
  DETERMINISTIC
  SQL SECURITY INVOKER
  COMMENT 'Returns Implied Volatility'
BEGIN
    DECLARE err_key INT DEFAULT 0;
    DECLARE epsilon Double;
    DECLARE dVol Double;
    DECLARE vol_1 Double; 
    DECLARE i Int; 
    DECLARE maxIter Int;
    DECLARE Value_1 Double;
    DECLARE vol_2 Double;
    DECLARE Value_2 Double;
    DECLARE dx Double;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET err_key = 1;
    
    SET dVol = 0.00001;
    SET epsilon = 0.00001;
    SET maxIter = 100;
    SET vol_1 = guess;
    SET i = 1;
    REPEAT
        SET Value_1 = Option_IV(CallOrPut, S, K, vol_1, r, T, q);
        SET vol_2 = vol_1 - dVol;
        SET Value_2 = Option_IV(CallOrPut, S, K, vol_2, r, T, q);
        SET dx = (Value_2 - Value_1) / dVol;
        SET vol_1 = vol_1 - (OptionValue - Value_1) / dx;
        SET i = i + 1;
    UNTIL ABS(dx) < epsilon OR i = maxIter
    END REPEAT;
    IF err_key = 1 THEN
       RETURN 0.0;
    ELSE
       -- out of range column (very big or small)
       RETURN CAST(vol_1 AS DECIMAL(12,4));
       IF err_key = 1 THEN
         RETURN 0.0;
       END IF;
    END IF;
END;


CREATE FUNCTION Option_IV( CallOrPut varchar(20), S double, K double, v double, r double, T double, q double )
  RETURNS double
  DETERMINISTIC
  SQL SECURITY INVOKER
  COMMENT 'Returns '
BEGIN
    DECLARE d1 Double;
    DECLARE d2 Double;
    DECLARE nd1 Double;
    DECLARE nd2 Double;
    DECLARE nnd1 Double;
    DECLARE nnd2 Double;

    SET d1 = (Log(S / K) + (r - q + 0.5 * POW(v, 2)) * T) / (v * SQRT(T));
    SET d2 = (Log(S / K) + (r - q - 0.5 * POW(v, 2)) * T) / (v * SQRT(T));
    SET nd1 = NormSDist(d1);
    SET nd2 = NormSDist(d2);
    SET nnd1 = NormSDist(-1 * d1);
    SET nnd2 = NormSDist(-1 * d2);
    IF UPPER(CallOrPut) = "CALL" THEN
        RETURN (S * Exp(-1 * q * T) * nd1 - K * Exp(-1 * r * T) * nd2);
    ELSE
        RETURN (-1 * S * Exp(-1 * q * T) * nnd1 + K * Exp(-1 * r * T) * nnd2);
    END IF;
END;


CREATE FUNCTION NormSDist( _X double)
  RETURNS double
  DETERMINISTIC
  SQL SECURITY INVOKER
  COMMENT 'Returns the standard normal cumulative distribution function. The distribution has a mean of 0 (zero) and a standard deviation of one.'
BEGIN
    SET @X = _X;
    SET @a1 = 0.31938153;
    SET @a2 = -0.356563782;
    SET @a3 = 1.781477937;
    SET @a4 = -1.821255978;
    SET @a5 = 1.330274429;
    SET @L = Abs(@X);
    SET @K = 1 / (1 + 0.2316419 * @L);
    SET @CND1 = 1 - 1 / Sqrt(2 * Pi()) * Exp(-power(@L,2) / 2) * (@a1 * @K + @a2 * power(@K,2) + @a3 * power(@K,3) + @a4 * power(@K,4) + @a5 * power(@K,5));
    IF @X < 0 THEN
        SET @CND1 = 1 - @CND1;
    END IF;
    RETURN @CND1;
  END
