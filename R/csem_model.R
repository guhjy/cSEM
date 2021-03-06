#' Parse lavaan model
#'
#' Turns a model written in [lavaan model syntax][lavaan::model.syntax] into a
#' [cSEMModel] list.
#'
#' @usage parseModel(.model)
#'
#' @inheritParams csem_arguments
#
#' @return A [cSEMModel] list that may be passed to any function requiring
#'   `.csem_model` as a mandatory argument.
#'
#' @examples
#' model <- '
#' # Structural model
#' y1 ~ y2 + y3
#'
#' # Measurement model
#' y1 =~ x1 + x2 + x3
#' y2 =~ x4 + x5
#' y3 =~ x6 + x7
#'
#' # Error correlation
#' x1 ~~ x2
#' '
#'
#' (m <- parseModel(model))
#'
#' # If the model is already a cSEMModel object, the model is returned as is.
#'
#' identical(m, parseModel(m)) # TRUE
#' @export
#'
parseModel <- function(.model) {

  ### Check if already a cSEMModel list  
  if(class(.model) == "cSEMModel") {
    # .model <- model
    return(.model)
  
    ## Check if list contains necessary elements
  } else if(all(c("structural", "measurement") %in% names(.model))) {
    
    # x <- setdiff(names(.model), c("structural", "measurement", "error_cor", 
    #                               "construct_type", "construct_order", "model_type", "vars_endo", 
    #                               "vars_exo", "vars_explana", "explained_by_exo"))
    x <- setdiff(names(.model), c("structural", "measurement", "error_cor", 
                                  "construct_type", "construct_order", 
                                  "model_type"))
    if(length(x) == 0) {
      
      class(.model) <- "cSEMModel"
      return(.model)
      
    } else {
      
      stop("The model you provided contains element names unknown to cSEM (", 
           paste0("'", x, "'", collapse = ", "), ").\n", 
           "See ?cSEMModel for a list of valid component names.", call. = FALSE)
    }
  } else {
    
    ### Convert to lavaan partable ---------------------------------------------
    m_lav <- lavaan::lavaanify(model = .model, fixed.x = FALSE)
    
    ### Extract relevant information -------------------------------------------
    # s := structural
    # m := measurement
    # e := error
    tbl_s  <- m_lav[m_lav$op == "~", ] # structural 
    tbl_m  <- m_lav[m_lav$op %in% c("=~", "<~"), ] # measurement 
    tbl_e  <- m_lav[m_lav$op == "~~" & m_lav$user == 1, ] # error 
    
    ## Get all relevant subsets of constructs and/or indicators
    # i := indicators
    # c := constructs
    
    # Construct names of the structural model (including nonlinear terms)
    names_c_s_lhs    <- unique(tbl_s$lhs)
    names_c_s_rhs    <- unique(tbl_s$rhs)
    names_c_s        <- union(names_c_s_lhs, names_c_s_rhs)
    
    # Construct names of the structural model including the names of the 
    # individual components of the interaction terms
    names_c_s_lhs_l  <- unique(unlist(strsplit(names_c_s_lhs, "\\.")))
    names_c_s_rhs_l  <- unique(unlist(strsplit(names_c_s_rhs, "\\.")))
    names_c_s_l      <- union(names_c_s_lhs_l, names_c_s_rhs_l)
    
    # Nonlinear construct names of the the structural model 
    names_c_s_lhs_nl <- names_c_s_lhs[grep("\\.", names_c_s_lhs)] # must be empty
    names_c_s_rhs_nl <- names_c_s_rhs[grep("\\.", names_c_s_rhs)]
    
    # Construct names of the structural model without nonlinear terms
    names_c_s_no_nl  <- setdiff(names_c_s, names_c_s_rhs_nl)
    
    # Indicator names (including constructs that serve as indicators for a 
    # 2nd order construct)
    names_i          <- unique(tbl_m$rhs)
    
    # Indicator names that contain a "."
    names_i_nl       <- names_i[grep("\\.", names_i)] # this catches all terms 
                                                      # with a "."!
    
    # Construct names of the measurement model (including nonlinear terms)
    names_c_m_lhs    <- unique(tbl_m$lhs)
    names_c_m_rhs    <- intersect(names_i, c(names_c_m_lhs, names_i_nl))
    names_c_m        <- union(names_c_m_lhs, names_c_m_rhs)
    
    # Construct names of the measurement model including the names of the 
    # individual components of the interaction terms
    names_c_m_lhs_l  <- unique(unlist(strsplit(names_c_m_lhs, "\\.")))
    names_c_m_rhs_l  <- unique(unlist(strsplit(names_c_m_rhs, "\\.")))
    names_c_m_l      <- union(names_c_m_lhs_l, names_c_m_rhs_l)
    
    # Nonlinear construct names of the measurement model 
    names_c_m_lhs_nl <- names_c_m_lhs[grep("\\.", names_c_m_lhs)] # must be empty
    names_c_m_rhs_nl <- names_c_m_lhs[grep("\\.", names_c_m_lhs)]
    
    # Construct names of the measurement model without nonlinear terms
    names_c_m_no_nl  <- setdiff(names_c_s, names_c_s_rhs_nl)
    
    # 2nd order construct names
    names_c_2nd      <- unique(tbl_m[tbl_m$rhs %in% names_c_m_rhs, "lhs"])
    
    # Higher order construct names
    names_c_higher   <- intersect(names_c_2nd, names_c_m_rhs) # must be empty
    
    # All construct names (including nonlinear terms)
    names_c_all      <- union(names_c_s, names_c_m) 
    
    # All linear construct names
    names_c          <- names_c_all[!grepl("\\.", names_c_all)] 
    
    # All nonlinear construct names
    names_c_nl       <- names_c_all[grepl("\\.", names_c_all)]
  

    ## The the number of...
    number_of_constructs_all  <- length(names_c_all)
    number_of_constructs      <- length(names_c)
    number_of_indicators      <- length(names_i)
    
    ## Order
    construct_order <- rep("First order", length(names_c))
    names(construct_order) <- names_c
    construct_order[names_c_2nd] <- "Second order"
    
    ### Checks, errors and warnings --------------------------------------------
    ## Stop if any interaction/nonlinear term is used as an endogenous (lhs) variable in the
    ## structural model 
    if(length(names_c_s_lhs_nl)) {
      
      stop("Interaction terms cannot appear on the left-hand side of a structural equation.", 
           call. = FALSE)
    }
    
    ## Stop if any interaction/nonlinear term is used as an endogenous (lhs) variable in the
    ## measurement model 
    if(length(names_c_m_lhs_nl)) {
      
      stop("Interaction terms cannot appear on the left-hand side of a measurement equation.", 
           call. = FALSE)
    }
    
    ## Stop if any construct has no obervables/indicators attached
    tmp <- setdiff(c(names_c_s_l, names_c_m_rhs_l), names_c_m_lhs)
    if(length(tmp) != 0) {
      
      stop("No measurement equation provided for: ",
           paste0("`", tmp,  "`", collapse = ", "), call. = FALSE)
    }
    
    ## Stop if any construct appears in the measurement but not in the 
    ## structural model
    tmp <- setdiff(names_c_m_lhs, c(names_c_s_l, names_c_m_rhs_l))
    if(length(tmp) != 0) {
      
      stop("Construct(s): ",
           paste0("`", tmp, "`", collapse = ", "), " of the measurement model",
           ifelse(length(tmp) == 1, " does", " do"), 
           " not appear in the structural model.",
           call. = FALSE)
    }
    
    ## Stop if any construct has a higher order than 2 (currently not allowed)
    if(length(names_c_higher) != 0) {
      stop(paste0("`", names_c_higher, "`"), " has order > 2.", 
           " Currently, only first and second-order constructs are supported.",
           call. = FALSE)
    }
    
    ## Stop if at least one of the components of an interaction term does not appear
    ## in any of the structural equations.
    tmp <- setdiff(names_c_s_l, names_c_s_no_nl)
    if(length(tmp) != 0) {
        
      stop("The nonlinear terms containing ", paste0("`", tmp, "`", collapse = ", "), 
           " are not embeded in a nomological net.", call. = FALSE)
    }
    
    ## Construct type
    tbl_m$op <- ifelse(tbl_m$op == "=~", "Common factor", "Composite")
    construct_type  <- unique(tbl_m[, c("lhs", "op")])$op
    names(construct_type) <- unique(tbl_m[, c("lhs", "op")])$lhs
    construct_type <- construct_type[names_c]
    
    ## Type of model (linear or non-linear)
    
    type_of_model <- if(length(names_c_nl) != 0) {
      "Nonlinear"
    } else {
      "Linear"
    }
    ### Construct matrices specifying the relationship between constructs,
    ### indicators and errors ----------------------------------------------------
    model_structural  <- matrix(0,
                                nrow = number_of_constructs,
                                ncol = number_of_constructs_all,
                                dimnames = list(names_c, names_c_all)
    )
    
    model_measurement <- matrix(0,
                                nrow = number_of_constructs,
                                ncol = number_of_indicators,
                                dimnames = list(names_c, names_i)
    )
    
    model_error       <- matrix(0,
                                nrow = number_of_indicators,
                                ncol = number_of_indicators,
                                dimnames = list(names_i, names_i)
    )
    
    ## Structural model
    row_index <- match(tbl_s$lhs, names_c)
    col_index <- match(tbl_s$rhs, names_c_all)
    
    model_structural[cbind(row_index, col_index)] <- 1
    
    ## Measurement model
    row_index <- match(tbl_m$lhs, names_c)
    col_index <- match(tbl_m$rhs, names_i)
    
    model_measurement[cbind(row_index, col_index)] <- 1
    
    ## Error model
    row_index <- match(tbl_e$lhs, names_i)
    col_index <- match(tbl_e$rhs, names_i)
    
    model_error[cbind(c(row_index, col_index), c(col_index, row_index))] <- 1
    
    ### Order model ==============================================================
    # Order the structual equations in a way that every equation depends on
    # exogenous variables and variables that have been explained in a previous equation
    # This is necessary for the estimation of models containing non-linear structual
    # relationships.
    
    ### Preparation --------------------------------------------------------------
    temp <- model_structural
    
    ## Extract endogenous and exogenous variables
    vars_endo <- rownames(temp)[rowSums(temp) != 0]
    var_exo  <- setdiff(colnames(temp), vars_endo)
    
    ## Return error if the structural model contains feedback loops
    if(any(temp[vars_endo, vars_endo] + t(temp[vars_endo, vars_endo]) == 2)) {
      stop("The structural model contains feedback loops.",
           " Currently no feedback loops are allowed.",
           call. = FALSE)
    }
    
    # Endo variables that are explained by exo and endo variables
    explained_by_exo_endo <- vars_endo[rowSums(temp[vars_endo, vars_endo, drop = FALSE]) != 0]
    
    # Endo variables explained by exo variables only
    explained_by_exo <- setdiff(vars_endo, explained_by_exo_endo)
    
    ### Order =======================
    # First the endo variables that are soley explained by the exo variables
    model_ordered <- temp[explained_by_exo, , drop = FALSE]
    
    # Add variables that have already been ordered/taken care of to a vector
    # (including exogenous variables and interaction terms)
    already_ordered <- c(var_exo, explained_by_exo)
    
    ## Order in a way that the current structural equation does only depend on
    ## exogenous variables and/or variables that have already been ordered
    counter <- 1
    explained_by_exo_endo_temp <- explained_by_exo_endo
    if(length(explained_by_exo_endo) > 0) {
      repeat {
        
        counter <- counter + 1
        
        for(i in explained_by_exo_endo_temp) {
          names_temp <- colnames(temp[i, temp[i, ] == 1, drop = FALSE])
          endo_temp  <- setdiff(names_temp, already_ordered)
          
          if(length(endo_temp) == 0) {
            model_ordered <- rbind(model_ordered, temp[i, , drop = FALSE])
            already_ordered <- c(already_ordered, i)
            explained_by_exo_endo_temp <- setdiff(explained_by_exo_endo_temp, already_ordered)
          }
        } # END for-loop
        if(counter > 50)
          stop("Reordering the structural equations was not succesful. Something is wrong.",
               call. = FALSE)
        if(length(explained_by_exo_endo_temp) == 0) break
      } # END repeat
    } # END if-statement
    
    ## Return a cSEMModel object.
    # A cSEMModel objects contains all the information about the model and its
    # components such as the type of construct used. 
    n <- c(setdiff(names_c, rownames(model_ordered)), rownames(model_ordered))
    m <- order(which(model_measurement[n, ] == 1, arr.ind = TRUE)[, "row"])
    structural_ordered <- model_structural[n, c(n, setdiff(colnames(model_ordered), n))]
    
    model_ls <- list(
      "structural"         = structural_ordered,
      "measurement"        = model_measurement[n, m],
      "error_cor"          = model_error[m, m],
      "construct_type"     = construct_type[match(n, names(construct_type))],
      "construct_order"    = construct_order[match(n, names(construct_order))],
      "model_type"         = type_of_model
      # "vars_endo"          = rownames(model_ordered),
      # "vars_exo"           = var_exo,
      # "vars_explana"       = colnames(structural_ordered)[colSums(structural_ordered) != 0],
      # "explained_by_exo"   = explained_by_exo
    )
    class(model_ls) <- "cSEMModel"
    return(model_ls) 
  } # END else
}

#' Convert second order cSEMModel
#'
#' Uses a [cSEMModel] containg second order constructs and turns it into an
#' estimable model using either the "repeated indicators" approach or a 
#' two-step procedure (TODO; link to literature)
#'
#' @usage convertModel(.csem_model)
#'
#' @inheritParams csem_arguments
#
#' @return A [cSEMModel] list that may be passed to any function requiring
#'   `.csem_model` as a mandatory argument.
#'
#' @keywords internal
#'
convertModel <- function(
  .csem_model        = args_default()$.csem_model, 
  .approach_2ndorder = args_default()$.approach_2ndorder,
  .stage             = args_default()$.stage
) {
  
  ### Check if a cSEMModel list  
  if(!class(.csem_model) == "cSEMModel") {
    stop("`.model` must be of model of class `cSEMModel`.")
  }
  
  # All linear constructs of the original model
  c_linear_original <- rownames(.csem_model$structural)
  # All constructs used in the first step (= all first order constructs)
  c_linear_1step <- names(.csem_model$construct_order[.csem_model$construct_order == "First order"])
  # All second order constructs
  c_2nd_order <- setdiff(c_linear_original, c_linear_1step)
  # All indicators of the original model (including linear and nonlinear 
  # constructs that form/measure a second order construct)
  i_original <- colnames(.csem_model$measurement)
  i_linear_original <- intersect(c_linear_original, i_original)
  i_nonlinear_original <- grep("\\.", i_original, value = TRUE) 
  # Linear constructs that serve as indicators and need to be replaced
  i_linear_1step <- setdiff(i_original, c(c_linear_original, i_nonlinear_original))
  
  if(.stage %in% c("second")) {
    # Linear constructs that dont form/measure a second order construct
    c_not_attached_to_2nd <- setdiff(c_linear_1step, i_linear_original)
    c_2step <- c(c_not_attached_to_2nd, c_2nd_order)
    
    ## Second step structural model
    x1 <- c()
    for(i in c_2step) {
      col_names <- colnames(.csem_model$structural[i, .csem_model$structural[i, , drop = FALSE] == 1, drop = FALSE])
      # col_names_linear <- intersect(c_linear_original, col_names)
      # col_names_nonlinear <- setdiff(col_names, col_names_linear)
      temp <- if(!is.null(col_names)) {
        ## Modify terms
        temp <- strsplit(x = col_names, split = "\\.")
        temp <- lapply(temp, function(x) {
          x[x %in% c_not_attached_to_2nd] <- paste0(x[x %in% c_not_attached_to_2nd], "_temp")
          paste0(x, collapse = ".")
        })
        # col_names_nonlinear <- unlist(temp)
        # col_names <- c(col_names_linear, col_names_nonlinear)
        col_names <- unlist(temp)
        # col_names[col_names %in% nc_not_to_2nd] <- paste0(col_names[col_names %in% nc_not_to_2nd], "_temp")
        paste0(ifelse(i %in% c_not_attached_to_2nd, paste0(i, "_temp"), i), "~", paste0(col_names, collapse = "+")) 
      } else {
        "\n"
      }
      x1 <- paste(x1, temp, sep = "\n")
    }
    
    ## Measurement model + second order structural equation 
    # Constructs that dont form/measure a second order construct
    x2a <- c()
    for(i in c_not_attached_to_2nd) {
      temp <- paste0(paste0(i, "_temp"), ifelse(.csem_model$construct_type[i] == "Composite", "<~", "=~"), i)
      x2a <- paste(x2a, temp, sep = "\n")
    }
    # Second order constructs
    x2b <- c()
    for(i in c_2nd_order) {
      col_names <- colnames(.csem_model$measurement[i, .csem_model$measurement[i, , drop = FALSE ] == 1, drop = FALSE])
      temp  <- paste0(i, ifelse(.csem_model$construct_type[i] == "Composite", "<~", "=~"), paste0(col_names, collapse = "+"))
      x2b <- paste(x2b, temp, sep = "\n")
    }
    
    ## Model to be parsed
    lav_model <- paste(x1, x2a, x2b, sep = "\n")
  } else { # BEGIN: first step
    
    if(.approach_2ndorder == "repeated_indicators") {
      
      ## Structural model
      # First order equations
      x1 <- c()
      for(i in c_linear_original) {
        col_names <- colnames(.csem_model$structural[i, .csem_model$structural[i, , drop = FALSE] == 1, drop = FALSE])
        temp <- if(!is.null(col_names)) {
          paste0(i, "~", paste0(col_names, collapse = "+")) 
        } else {
          "\n"
        }
        x1 <- paste(x1, temp, sep = "\n")
      }
      
      ## Measurement model + second order structural equation 
      # First order constructs
      x2a <- c()
      for(i in c_linear_1step) {
        col_names <- colnames(.csem_model$measurement[i, .csem_model$measurement[i, , drop = FALSE ] == 1, drop = FALSE])
        temp  <- paste0(i, ifelse(.csem_model$construct_type[i] == "Composite", "<~", "=~"), paste0(col_names, collapse = "+"))
        x2a <- paste(x2a, temp, sep = "\n")
      }
      
      # Second order constructs
      x2b <- c()
      for(i in c_2nd_order) {
        # i <- c_2nd_order[1]
        col_names_1 <- colnames(.csem_model$measurement[i, .csem_model$measurement[i, , drop = FALSE ] == 1, drop = FALSE])
        col_names_1_nonlinear <- grep("\\.", col_names_1, value = TRUE) 
        col_names_1_linear <- setdiff(col_names_1, col_names_1_nonlinear)
        col_names_2 <- .csem_model$measurement[col_names_1_linear, colSums(.csem_model$measurement[col_names_1_linear, ,drop = FALSE]) != 0, drop = FALSE]
        temp <- paste0(i, "_2nd_", colnames(col_names_2))
        temp <- paste0(i, ifelse(.csem_model$construct_type[i] == "Composite", "<~", "=~"), paste0(temp, collapse = "+"))
        x2b <- paste(x2b, temp, sep = "\n")
        ## add second order structural equation
        x2b <- paste(x2b, paste0(i, "~", paste0(col_names_1, collapse = "+" )), sep = "\n")
      }
      
      ## Error_cor
      # First order
      x3 <- c()
      for(i in i_linear_1step) {
        # - Only upper triagular matrix as lavaan does not allow for double entries such
        #   as x11 ~~ x12 vs x12 ~~ x11
        # - Only 1st order construct indicators are allowed to correlate 
        error_cor <- .csem_model$error_cor
        error_cor[lower.tri(error_cor)] <- 0
        col_names <- colnames(error_cor[i, error_cor[i, , drop = FALSE] == 1, drop = FALSE])
        temp <- if(!is.null(col_names)) {
          paste0(i, "~~", paste0(col_names, collapse = "+"))
        } else {
          "\n"
        }
        x3 <- paste(x3, temp, sep = "\n")
      }
      ## Model to be parsed
      lav_model <- paste(x1, x2a, x2b, x3, sep = "\n")
      
    } else { # First step of the two step approach
      
      ## Structural model
      x1 <- c()
      for(i in 2:length(c_linear_1step)) {
        temp <- paste0(c_linear_1step[i], "~", paste0(c_linear_1step[1:(i-1)], collapse = "+"))
        x1   <- paste(x1, temp, sep = "\n")
      }
      ## Measurement model
      x2 <- c()
      for(i in c_linear_1step) {
        col_names <- colnames(.csem_model$measurement[i, .csem_model$measurement[i, , drop = FALSE] == 1, drop = FALSE])
        temp <- paste0(i, ifelse(.csem_model$construct_type[i] == "Composite", "<~", "=~"), paste0(col_names, collapse = "+"))
        x2   <- paste(x2, temp, sep = "\n")
      }
      ## Error_cor
      x3 <- c()
      for(i in i_linear_1step) {
        # only upper triagular matrix as lavaan does not allow for double entries such
        # as x11 ~~ x12 vs x12 ~~ x11
        error_cor <- .csem_model$error_cor
        error_cor[lower.tri(error_cor)] <- 0
        col_names <- colnames(error_cor[i, error_cor[i, , drop = FALSE] == 1, drop = FALSE])
        temp <- if(!is.null(col_names)) {
          paste0(i, "~~", paste0(col_names, collapse = "+"))
        } else {
          "\n"
        }
        x3 <- paste(x3, temp, sep = "\n")
      }
      ## Model to be parsed
      lav_model <- paste(x1, x2, x3, sep = "\n")
    } # END first step of the 3 step approach
  } # END first step

  ## Parse model
  model <- parseModel(lav_model)
  return(model)
}
