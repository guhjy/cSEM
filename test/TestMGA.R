#############################################
# Test File for MULTIGROUP ANALYSIS
# 2018-10-19
# (c) Manuel Rademaker, Florian Schuberth,
# Michael Klesel
#############################################

#############################################
# PART A: COMPOSITE MODEL
#############################################

# Path model
comp.pathModel <- '
A <~ x11 + x12 + x13
B <~ x21 + x22 + x23
C <~ x31 + x32 + x33
D <~ x41 + x42 + x43

C ~ A + B
D ~ A + C'

comp.cor.group1 <- matrix(c(1,0.5,0.5,0,0,0,0.032625,0.0306,0.0333,0.24795,0.23256,0.25308,
                  0.5,1,0.5,0,0,0,0.029,0.0272,0.0296,0.2204,0.20672,0.22496,
                  0.5,0.5,1,0,0,0,0.025375,0.0238,0.0259,0.19285,0.18088,0.19684,
                  0,0,0,1,0.2,0,0.058,0.0544,0.0592,0.0348,0.03264,0.03552,
                  0,0,0,0.2,1,0.4,0.116,0.1088,0.1184,0.0696,0.06528,0.07104,
                  0,0,0,0,0.4,1,0.116,0.1088,0.1184,0.0696,0.06528,0.07104,
                  0.032625,0.029,0.025375,0.058,0.116,0.116,1,0.25,0.4,0.324573438,0.3044275,0.33128875,
                  0.0306,0.0272,0.0238,0.0544,0.1088,0.1088,0.25,1,0.16,0.3044275,0.285532,0.310726,
                  0.0333,0.0296,0.0259,0.0592,0.1184,0.1184,0.4,0.16,1,0.33128875,0.310726,0.338143,
                  0.24795,0.2204,0.19285,0.0348,0.0696,0.0696,0.324573438,0.3044275,0.33128875,1,0.25,0.4,
                  0.23256,0.20672,0.18088,0.03264,0.06528,0.06528,0.3044275,0.285532,0.310726,0.25,1,0.16,
                  0.25308,0.22496,0.19684,0.03552,0.07104,0.07104,0.33128875,0.310726,0.338143,0.4,0.16,1), 
                ncol = 12, nrow = 12)
colnames(comp.cor.group1) <- c("x11", "x12", "x13", "x21", "x22", "x23", "x31", "x32", "x33", "x41", "x42", "x43")
rownames(comp.cor.group1) <- colnames(comp.cor.group1)


comp.cor.group2 <- matrix(c(1,0.5,0.5,0,0,0,0.261,0.2448,0.2664,0.522,0.4896,0.5328,
                  0.5,1,0.5,0,0,0,0.232,0.2176,0.2368,0.464,0.4352,0.4736,
                  0.5,0.5,1,0,0,0,0.203,0.1904,0.2072,0.406,0.3808,0.4144,
                  0,0,0,1,0.2,0,0.1595,0.1496,0.1628,0.039875,0.0374,0.0407,
                  0,0,0,0.2,1,0.4,0.319,0.2992,0.3256,0.07975,0.0748,0.0814,
                  0,0,0,0,0.4,1,0.319,0.2992,0.3256,0.07975,0.0748,0.0814,
                  0.261,0.232,0.203,0.1595,0.319,0.319,1,0.25,0.4,0.27858125,0.26129,0.284345,
                  0.2448,0.2176,0.1904,0.1496,0.2992,0.2992,0.25,1,0.16,0.26129,0.245072,0.266696,
                  0.2664,0.2368,0.2072,0.1628,0.3256,0.3256,0.4,0.16,1,0.284345,0.266696,0.290228,
                  0.522,0.464,0.406,0.039875,0.07975,0.07975,0.27858125,0.26129,0.284345,1,0.25,0.4,
                  0.4896,0.4352,0.3808,0.0374,0.0748,0.0748,0.26129,0.245072,0.266696,0.25,1,0.16,
                  0.5328,0.4736,0.4144,0.0407,0.0814,0.0814,0.284345,0.266696,0.290228,0.4,0.16,1), 
                ncol = 12, nrow = 12)
colnames(comp.cor.group2) <- c("x11", "x12", "x13", "x21", "x22", "x23", "x31", "x32", "x33", "x41", "x42", "x43")
rownames(comp.cor.group2) <- colnames(comp.cor.group2)


# Generate Data
require(MASS)
comp.data.group1 <- MASS::mvrnorm(200,  mu = rep(0, ncol(comp.cor.group1)), Sigma = comp.cor.group1, empirical = F)
comp.data.group2 <- MASS::mvrnorm(200,  mu = rep(0, ncol(comp.cor.group1)), Sigma = comp.cor.group1, empirical = F)

comp.data.combined <- list(comp.data.group1, comp.data.group2)

# Estimate
require(cSEM)
comp.out <- cSEM::csem(.data = comp.data.combined, .model = comp.pathModel)
comp.out

# Multigroup Analysis
cSEM::testMGD(.object = comp.out, 
              .parallel = F,
              .runs = 100,
              .handle_inadmissibles = "drop")



#############################################
# PART B: COMMON FACTOR MODEL
#############################################

# Path model
factor.pathModel <- '
A =~ x11 + x12 + x13
B =~ x21 + x22 + x23
C =~ x31 + x32 + x33
D =~ x41 + x42 + x43

C ~ A + B
D ~ A + C'


# baseline
factor.cor.group1 <- matrix(c(1,0.56,0.63,0,0,0,0.0245,0.028,0.0315,0.1862,0.2128,0.2394,
                  0.56,1,0.72,0,0,0,0.028,0.032,0.036,0.2128,0.2432,0.2736,
                  0.63,0.72,1,0,0,0,0.0315,0.036,0.0405,0.2394,0.2736,0.3078,
                  0,0,0,1,0.56,0.63,0.098,0.112,0.126,0.0588,0.0672,0.0756,
                  0,0,0,0.56,1,0.72,0.112,0.128,0.144,0.0672,0.0768,0.0864,
                  0,0,0,0.63,0.72,1,0.126,0.144,0.162,0.0756,0.0864,0.0972,
                  0.0245,0.028,0.0315,0.098,0.112,0.126,1,0.56,0.63,0.302575,0.3458,0.389025,
                  0.028,0.032,0.036,0.112,0.128,0.144,0.56,1,0.72,0.3458,0.3952,0.4446,
                  0.0315,0.036,0.0405,0.126,0.144,0.162,0.63,0.72,1,0.389025,0.4446,0.500175,
                  0.1862,0.2128,0.2394,0.0588,0.0672,0.0756,0.302575,0.3458,0.389025,1,0.56,0.63,
                  0.2128,0.2432,0.2736,0.0672,0.0768,0.0864,0.3458,0.3952,0.4446,0.56,1,0.72,
                  0.2394,0.2736,0.3078,0.0756,0.0864,0.0972,0.389025,0.4446,0.500175,0.63,0.72,1), 
                ncol = 12, nrow = 12)
colnames(factor.cor.group1) <- c("x11", "x12", "x13", "x21", "x22", "x23", "x31", "x32", "x33", "x41", "x42", "x43")
rownames(factor.cor.group1) <- colnames(factor.cor.group1)

factor.cor.group2 <- matrix(c(1,0.56,0.63,0,0,0,0.196,0.224,0.252,0.392,0.448,0.504,
                  0.56,1,0.72,0,0,0,0.224,0.256,0.288,0.448,0.512,0.576,
                  0.63,0.72,1,0,0,0,0.252,0.288,0.324,0.504,0.576,0.648,
                  0,0,0,1,0.56,0.63,0.2695,0.308,0.3465,0.067375,0.077,0.086625,
                  0,0,0,0.56,1,0.72,0.308,0.352,0.396,0.077,0.088,0.099,
                  0,0,0,0.63,0.72,1,0.3465,0.396,0.4455,0.086625,0.099,0.111375,
                  0.196,0.224,0.252,0.2695,0.308,0.3465,1,0.56,0.63,0.2597,0.2968,0.3339,
                  0.224,0.256,0.288,0.308,0.352,0.396,0.56,1,0.72,0.2968,0.3392,0.3816,
                  0.252,0.288,0.324,0.3465,0.396,0.4455,0.63,0.72,1,0.3339,0.3816,0.4293,
                  0.392,0.448,0.504,0.067375,0.077,0.086625,0.2597,0.2968,0.3339,1,0.56,0.63,
                  0.448,0.512,0.576,0.077,0.088,0.099,0.2968,0.3392,0.3816,0.56,1,0.72,
                  0.504,0.576,0.648,0.086625,0.099,0.111375,0.3339,0.3816,0.4293,0.63,0.72,1), 
                ncol = 12, nrow = 12)
colnames(factor.cor.group2) <- c("x11", "x12", "x13", "x21", "x22", "x23", "x31", "x32", "x33", "x41", "x42", "x43")
rownames(factor.cor.group2) <- colnames(factor.cor.group2)

# Generate Data
require(MASS)
factor.data.group1 <- MASS::mvrnorm(200,  mu = rep(0, ncol(factor.cor.group1)), Sigma = factor.cor.group1, empirical = T)
factor.data.group2 <- MASS::mvrnorm(200,  mu = rep(0, ncol(factor.cor.group1)), Sigma = factor.cor.group1, empirical = T)

factor.data.combined <- list(factor.data.group1, factor.data.group2)

# Estimate
require(cSEM)
factor.out <- cSEM::csem(.data = factor.data.combined, .model = factor.pathModel)
factor.out

# Multigroup Analysis
test.out <- cSEM::testMGD(.object = factor.out, 
              .parallel = F,
              .runs = 20,
              .handle_inadmissibles = "fill")
test.out$Total_runs
test.out$Number_admissibles
