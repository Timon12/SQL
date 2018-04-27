CREATE FUNCTION SPAN_SCAN_RISK( IV_coef double, _strike_ double, _price_options_ double, _price_open_options_ double,
                                                          _price_futures_ double, _futures_cost_point_ double, _id_direction_ double,
                                                          _years_T_ double, _type_option_ varchar(20) )
  RETURNS double
  DETERMINISTIC
  SQL SECURITY INVOKER
  COMMENT 'Returns Span scan risk for Strike'
BEGIN
  DECLARE err_key int DEFAULT 0;
  DECLARE s_s_r double;
  DECLARE IV_in double;
  DECLARE IV_v0 double;
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET err_key = 1;
  SET IV_in = IV_coef;
  IF UPPER(_type_option_) = 'CALL' THEN
    SET s_s_r = (_price_futures_ * NormSDist((LN(_price_futures_ / _strike_) + 0.5 * (POW(IV_in, 2)) * _years_T_) / (IV_in * SQRT(_years_T_))) - 
                                _strike_ * NormSDist((LN(_price_futures_ / _strike_) + 0.5 * (POW(IV_in, 2)) * _years_T_) / (IV_in * SQRT(_years_T_)) - IV_in * SQRT(_years_T_)) - _price_open_options_) * _futures_cost_point_ * _id_direction_;
  ELSE
    SET s_s_r = (_price_futures_ * NormSDist((LN(_price_futures_ / _strike_) + 0.5 * (POW(IV_in, 2)) * _years_T_) / (IV_in * SQRT(_years_T_))) - 
                                _strike_ * NormSDist((LN(_price_futures_ / _strike_) + 0.5 * (POW(IV_in, 2)) * _years_T_) / (IV_in * SQRT(_years_T_)) - IV_in * SQRT(_years_T_)) + _strike_ - _price_futures_ - _price_open_options_) * _futures_cost_point_ * _id_direction_;
  END IF;
  IF err_key = 1 THEN
    RETURN 0.0;
  ELSE
    RETURN s_s_r;
  END IF;
END

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
