##
## Function to compute the unadjusted estimator
## Input: y (binary outcome vector) and trt (0/1 treatment indicator)
##
unadjusted <- function(y,trt) {
  list(mean(y[trt==0],na.rm=T),mean(y[trt==1],na.rm=T))
}

##
## Function to compute the TMLE sequential outcome regression estimator
## Input: d (dataframe), K (the number of follow-ups after baseline),
## form (contains the model formula for the propensity score, dropout,
## and outcome regressionmodels), outcomeModelType ("lm" for linear model
## or "lg" for logistic) and cutoff (creates a trimming of the weights)
##
compute.tmle = function(d,K,form,outcomeModelType,cutoff=20) {

    ## Create an output list that stores convergence information and model warnings
    convgSummary = vector("list",3)
    names(convgSummary) = c("A","R","Y")
    
    ## First fit the models for the propensity score for treatment and drop-out
    for.wts = vector("list",2)
    assign("last.warning",NULL,envir=baseenv())
    fitA = glm(formula(paste(form$A)),data=d,family="binomial") 
    prA = fitA$fitted
    convgSummary$A = list(fitA$converged,warnings())
    convgR = vector("list",2)
    for(a in 0:1) {
        convgR.out = vector("list",K)
	out = NULL
	if(a==0) out = cbind(out,1-prA)
	if(a==1) out = cbind(out,prA)
	for(i in 1:K) {
            if(i==1) ss = d$A==a else ss = d$A==a & d[,paste("R",i-1,"",sep="")]==1
            assign("last.warning",NULL,envir=baseenv())
            fit = glm(formula(paste(form$R[i])),data=d,subset=ss,family="binomial")
            out = cbind(out,predict(fit,d,type="response"))
            convgR.out[[i]] = list(fit$converged,warnings())
	}
	for.wts[[a+1]] = out
        convgR[[a+1]] = convgR.out
    }
    convgSummary$R = convgR

    ## Generate a new variable paste("Ystar",K+1,"",sep="")
    ## That contains values for the final outcome at the final follow-up
    for(i in 2:(K+1)) d[,paste("Ystar",i,"",sep="")] = d[,paste("Y",i,"",sep="")]
    if(outcomeModelType=="lm") ff = "gaussian" else ff = "binomial"

    ## For t = K+1, K, ..., 1
    ## - Compute the weights
    ## - Fit the weighted regression
    ## - Do the prediction
    results = vector("list",2)
    convgY = vector("list",2)
    for(a in 0:1) {
        ## Initialize the final value of Y0, we will estimate this separately for each a
	d[,"Ystar1"] = d[,"Y1"]

	## Generate output vectors that will save the weights, etc.
	out = vector("list",K+1)
        convgY.out = vector("list",K)
	for(i in seq(K+1,3,-1)) {
            ## Compute the weights
            wts = pmin(1/apply(for.wts[[a+1]][,1:i],1,prod),cutoff)
            ## Fit the weighted regression
            assign("last.warning",NULL,envir=baseenv())
            ss = d$A==a & d[,paste("R",i-1,"",sep="")]==1
            fit = suppressWarnings(glm(formula(paste(form$Y[i-1])),data=d,subset=ss,weight=wts,family=ff,na.action=na.omit))
            convgY.out[[i-1]] = list(fit$converged,warnings())
            ## Predict Ystar for participants with paste("R",i-1)==1
            ss0 = d$A==a & d[,paste("R",i-2,"",sep="")]==1
            d[ss0,paste("Ystar",i-1,"",sep="")] = predict(fit,d[ss0,],type="response")
            out[[i-1]] = list(wts,fit)
        }
	## For t = 1
	wts = pmin(1/apply(for.wts[[a+1]][,1:2],1,prod),cutoff)
	## Fit the weighted regression
	ss = d$A==a & d$R1==1
	fit = suppressWarnings(glm(formula(paste(form$Y[1])),data=d,subset=ss,weight=wts,family=ff,na.action=na.omit))
        convgY.out[[1]] = list(fit$converged,warnings())
	## Predict Ystar1 for all participants
	d$Ystar1 = predict(fit,d,type="response")
	out[[1]] = list(wts,fit)
	out[[K+1]] = mean(d$Ystar1)
	results[[a+1]] = out
	convgY[[a+1]] = convgY.out
    }
    convgSummary$Y = convgY

    ## Return the results
    list(results = results,for.wts=for.wts,convgSummary=convgSummary)
}

##
## Define the function that will compute the unadjusted and TMLE
## estimates within the bootstrap procedure
##
tmle.boot <- function(data,x,K,form,outcomeModelType,cutoff) {
    newd = data[x,]
    out.unadj = unadjusted(y=newd[,paste0("Y",K+1)],trt=newd$A)
    out.tmle = compute.tmle(d=newd,K,form,outcomeModelType,cutoff)
    ## Pass back the following:
    ##
    ## unadjusted means + difference
    ## TMLE means + difference
    ## Indicators for convergence of the models
    cc = out.tmle$convgSummary$A[[1]][1]
    for(a in 0:1) for(i in 1:K) cc = c(cc,out.tmle$convgSummary$R[[a+1]][[i]][[1]][1])
    for(a in 0:1) for(i in 1:K) cc = c(cc,out.tmle$convgSummary$Y[[a+1]][[i]][[1]][1])

    c(out.unadj[[1]][1],out.unadj[[2]][1],out.unadj[[2]][1]-out.unadj[[1]][1],
           out.tmle$results[[1]][[K+1]][1],out.tmle$results[[2]][[K+1]][1],
           out.tmle$results[[2]][[K+1]][1]-out.tmle$results[[1]][[K+1]][1],cc)
}

##
## Create a function that will summarize the results including
## the treatment specific means and mean difference based on the
## unadjusted and TMLE estimators, confidence intervals and
## variances (relative efficiencies) are computed
##
ci.fun = function(boot.out,index,clevels) {
    c(boot.out$t0[index],var(boot.out$t[,index]),boot.ci(boot.out,index=index,type="bca",conf=clevels)$bca[1,4:5])
}


tmle.boot.summary = function(boot.out,clevels) {
    unadj = NULL
    for(i in 1:3) unadj = rbind(unadj,ci.fun(boot.out,i,clevels))
    tmle = NULL
    for(i in 4:6) tmle = rbind(tmle,ci.fun(boot.out,i,clevels))
    out = as.data.frame(cbind(unadj,tmle))
    names(out) = c("Unadj.est","Unadj.var","Unadj.LL","Unadj.UL",
             "TMLE.est","TMLE.var","TMLE.LL","TMLE.UL")
    row.names(out) = c("Control (A = 0)","Treatment (A = 1)","Difference (Treatment - Control")
    out$Rel.Eff = out$TMLE.var / out$Unadj.var
    round(out,4)
    }

    
##
## TMLE sequential outcome regression estimator
##
## This function will take the required inputs, create the model forms
## and then compute the TMLE estimator, in addition, it will compute
## bootstrap confidence intervals
##
TMLE = function(data,A="trt",outcomeVars=NULL,treatmentModel=NULL,dropoutModel=NULL,outcomeModel=NULL,
    lagdropout=NULL,outcomeModelType="lm",lagoutcome=NULL,lag=1,ModelData=NULL,
    nreps=1,seed=123,strata=NULL,clevels=0.95,cutoff=20,...) {

    ## Create a list of additionally passed arguments
    args = list(...)
    
    ## Identify the number of follow-ups:
    K = length(outcomeVars)-1

    ## If the outcomes are labeled as "y1", etc convert the variable names to "Y1"
    foo = match(outcomeVars,names(data))
    names(data)[foo[!is.na(foo)]] = toupper(outcomeVars)
    outcomeVars = toupper(outcomeVars)

    ## Rename the treatment variable to A
    data$A = data[,A]
    data[,A] = NULL

    ## Create the indicators for non-missing data
    for(i in 1:K) data[,paste0("R",i)] = ifelse(!is.na(data[,paste0("Y",i+1)]),1,0)
    for(i in 2:K) data[,paste0("R",i)][data[,paste0("R",i-1)]==0] = 0
       
    ## Create the model formula as a list named "form"
    form = vector("list",3)
    names(form) = c("Y","R","A")

    ## Create text that contains the lagged outcomes for the
    ## outcome regression models
    lagYs = vector("list",K)
    for(i in 2:(K+1)) {
        if(is.null(lagoutcome)) use.lag = lag else use.lag = lagoutcome
        if(use.lag>0) {
            keep = outcomeVars[!is.na(match(seq(1,K+1),seq(i-use.lag,i-1)))]
            hold = keep[1]
            if(length(keep)>1) for(j in 2:length(keep)) hold = paste0(hold,"+",keep[j])
            lagYs[[i-1]] = hold
        }
    }
        
    ## Create text that contains the lagged outcomes for the
    ## dropout regression models
    lagRs = vector("list",K)
    for(i in 2:(K+1)) {
        if(is.null(lagdropout)) use.lag = lag else use.lag = lagdropout
        if(use.lag>0) {
            keep = outcomeVars[!is.na(match(seq(1,K+1),seq(i-use.lag,i-1)))]
            hold = keep[1]
            if(length(keep)>1) for(j in 2:length(keep)) hold = paste0(hold,"+",keep[j])
            lagRs[[i-1]] = hold
        }
    }

    # Create the propensity score model for treatment
    form$A = chartr("y","Y",paste0("A~",gsub(" ","+",treatmentModel)))

    # Create the list of outcome regression models
    form$Y = vector("list",K)
    for(i in 2:(K+1)) {
        if(is.null(ModelData)) {
            alt.model = args[[paste0("outcomeModel",i)]]
            if(is.null(alt.model)) hold = paste0("Ystar",i,"~",gsub(" ","+",outcomeModel),"+",lagYs[[i-1]])
            else hold = paste0("Ystar",i,"~",gsub(" ","+",alt.model))
        }
        if(!is.null(ModelData)) hold = paste0("Ystar",i,"~",gsub(" ","+",ModelData$rhs[ModelData$Modeltype=="outcome" & ModelData$tpt==i]))
        form$Y[[i-1]] = chartr("y","Y",hold)
    }
    
    # Create the list of drop-out regression models
    form$R = vector("list",K)
    for(i in 1:(K)) {
        if(is.null(ModelData)) {
            alt.model = args[[paste0("dropoutModel",i)]]
            if(is.null(alt.model)) hold = paste0("R",i,"~",gsub(" ","+",dropoutModel),"+",lagRs[[i]])
            else hold = paste0("R",i,"~",gsub(" ","+",alt.model))
        }
        if(!is.null(ModelData)) hold = paste0("R",i,"~",gsub(" ","+",ModelData$rhs[ModelData$Modeltype=="dropout" & ModelData$tpt==i]))
        form$R[[i]] = chartr("y","Y",hold)
    }

    ## Now ready to compute the TMLE estimator and the unadjusted estimator
    out.unadj = unadjusted(y=data[,paste0("Y",K+1)],trt=data$A)
    out.tmle = compute.tmle(d=data,K,form,outcomeModelType,cutoff=20)

    ## Compute the bootstrap standard errors and CI
    if(!is.null(strata)) if(strata=="trt") strata="A"
    set.seed(seed)
    if(is.null(strata)) boot.out = boot(data,tmle.boot,R=nreps,K=K,form=form,outcomeModelType=outcomeModelType,cutoff=cutoff)
    if(!is.null(strata)) boot.out = boot(data,tmle.boot,R=nreps,strata=data[,strata],K=K,form=form,outcomeModelType=outcomeModelType,cutoff=cutoff)

    ## From the results of the bootstrap, compute an output summary table
    out.table = tmle.boot.summary(boot.out,clevels)

    
    list(out.unadj=out.unadj,out.tmle=out.tmle,boot.out=boot.out,out.table=out.table,form=form)
}

