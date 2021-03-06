#' Cragg Donald Statistics
#'
#' @description Computes de Cragg Donald Statistics
#' @param endogenous The endogenous variables, a n by k matrix.
#' @param instruments The Instruments, a n by z matrix.
#' @return The Cragg Donald Statistics
#' @note The endogenous variables and instruments should be the columns of the matrix
#' @export

cragg_donald_stats <- function(endogenous, instruments){
  reg <- lm(endogenous ~ instruments)
  residuals <- resid(reg)
  Pz <- instruments %*% qr.solve(t(instruments) %*% instruments) %*% t(instruments)
  Sv <- cov(residuals)
  sqrt.Sv <- chol(Sv)
  inv.Sv <- qr.solve(sqrt.Sv)
  G <- t(inv.Sv) %*% t(endogenous) %*% Pz %*% endogenous %*% inv.Sv/ncol(instruments)
  g <- min(eigen(G)$values)
  return(g)
}

#'Stock-Yogo Test
#'
#' @description Computes the Stock-Yogo test for weak instruments detection, with critical values
#' @param X The Endogenous variables
#' @param Z The Instruments
#' @param bias The maximum bias accept. Current values are 0.05,0.1,0.2,0.3. Default is 0.1.
#' @return The value of the Donald Cragg Statistics and the critical value for the number of endogenous and the      number of instruments
#' @section Warning: Only work until 30 instruments or 3 endogenous variables
#' @export
#' @import rlang

stock_yogo_test <- function(X, Z, bias = 0.1){
  K <- ncol(Z)
  E <- ncol(X)
  if (K < (E + 2)) {
    abort("Not enough instruments")
  }
  if (E > 3) {
    warning("No available value for more than 3 endogenous variables. Showing critical value for 3.")}
  if(K > 30){
    warning("No available value for more than 30 instruments. Showing critical value for 30")
  }
  stat <- cragg_donald_stats(X,Z)
  E.aux <- ifelse(E > 3, 3, E)
  K.aux <- ifelse(K > 30, 30, K)
  crit_val_sy <- weakinstruments::crit_val[[E.aux]]
  row <- which(crit_val_sy[,1] == K.aux)
  crit_val_sy <- crit_val_sy[row,as.character(bias)]
  return(structure(list("stat" = stat, "critical_value" = crit_val_sy), class = "stockyogo"))
}

#'AR Test
#'
#' @description Hypothesis test that do not depends if the instrument is weak or strong
#' @param y The dependent variable of the second stage
#' @param X The Endogenous variables
#' @param Z The Instruments
#' @param beta0 The vector of the coefficients to be tested
#' @param intercept Logical. Should an intercept be included? Default is false.
#' @note Works with more than one endogenous variable.
#' If used with the coefficients from TSLS, it computes the J-statistic
#' @export

ar_test <- function(y,X,Z,beta0, intercept = F){
  if (length(beta0) == 1) {
    beta0 <- matrix(beta0,ncol = 1)
  }
  if (intercept == T) {
    X <- cbind(1,X)
  }
  k <- ncol(Z)
  n <- nrow(Z)
  u <- y - X %*% beta0
  Pz <- Z %*% solve(t(Z) %*% Z) %*% t(Z)
  Mz <- diag(nrow = nrow(Pz)) - Pz
  AR_num <- t(u) %*% Pz %*% u/k
  AR_den <- t(u) %*% Mz %*% u/(n - k)
  AR_stat <- AR_num/AR_den
  p_val <- pchisq(k*AR_stat, df = k, lower.tail = F)
  return(list("stat" = AR_stat,"p_val" = p_val))
}

