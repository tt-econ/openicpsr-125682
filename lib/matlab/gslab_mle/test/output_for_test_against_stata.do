 /**********************************************************
 *
 *  OUTPUT_FOR_TEST_AGAINST_STATA.DO
 * 
 **********************************************************/ 

version 11
set more off
adopath + ../external/gslab_misc
preliminaries

program main
    import_raw_data, obs(10000)
    run_mle, model(linear) rhscount(3)
    run_mle, model(linear) rhscount(3) cons(rhs_var1 + rhs_var2 = 1)
    run_mle, model(logit) rhscount(3) added_vcov(cluster robust opg)
    run_mle, model(logit) rhscount(3) cons(rhs_var1 + rhs_var2 = 1) added_vcov(cluster robust opg)
    run_mle, model(xtlogit) rhscount(3)
    run_mle, model(xtlogit) rhscount(3) cons(rhs_var1 + rhs_var2 = 1)
end


program import_raw_data
    syntax, obs(int)
    
    insheet using "../external/data/test_data.csv", clear
    keep x1 x2 x3 x4 x1_logit xclust_logit group
    drop if _n > `obs'
      
    rename x2 rhs_var1
    rename x3 rhs_var2
    rename x4 rhs_var3
    rename x1 lhs_var
    rename x1_logit lhs_logit
    rename xclust_logit lhsclust_logit 
end

program run_mle
    syntax, model(str) rhscount(str) [cons(str)] [added_vcov(str)]
    
    if "`cons'" != "" {
        constraint 1 `cons'
        local consswitch constraints(1)
        local consfile _cons
    }

    execute_ml, model(`model') rhscount(`rhscount') vcov(oim) consswitch(`consswitch')

    create_matrices, rhscount(`rhscount') vcovmat(vcov) parammat(params)
    
    if "`cons'" == "" {
        delta_method, rhscount(`rhscount') outfile(stataout_`model'`consfile'.txt)
        wald_test, rhscount(`rhscount') outfile(stataout_`model'`consfile'.txt)
    }
    else {
        lr_test, outfile(stataout_`model'.txt)
    }

    save_output, vcovmat(vcov) parammat(params) loglik_model(e(ll)) outfile(stataout_`model'`consfile'.txt)
    
    if "`added_vcov'" != "" {
        foreach extravcov in `added_vcov' {
            alternate_vcov_estimator, vcov(`extravcov') model(`model') rhscount(`rhscount') consswitch(`consswitch') consfile(`consfile')
        }        
    }
end
    
    program execute_ml
        syntax, model(str) rhscount(str) vcov(str) [consswitch(str)]
   
        if "`model'" == "linear" {
            ml model d0 ll_linear (linear_reg: lhs_var = rhs_var*) (lnsigma:), diparm(lnsigma, exp label(sigma)) `consswitch' vce(`vcov')
            ml maximize
        }
        
        if "`model'" == "logit" {
            if "`vcov'" == "cluster" {
                local vcov cluster group
                logit lhsclust_logit rhs*, nocnsnotes `consswitch' vce(`vcov')				
            }
            else {
                logit lhs_logit rhs*, nocnsnotes `consswitch' vce(`vcov')
            }
        }
        
        if "`model'" == "xtlogit" {
            xtlogit lhs_logit rhs*, i(group) re nocnsnotes `consswitch' vce(`vcov')
        }
        
        save_estimates, constraint(`consswitch')
    end

        *  log likelihood function for linear regression
        program ll_linear
            args todo vars lnf
            
            tempname lnsigma sigma
            tempvar mu 
            mleval `mu' = `vars', eq(1)
            mleval `lnsigma' = `vars', eq(2) scalar
            quietly {
                scalar `sigma' = exp(`lnsigma')
                mlsum `lnf' = ln( normalden($ML_y1,`mu',`sigma') )
            }
        end

        * save estimates for LR Test
        program save_estimates
            syntax, [constraint(str)]
            
            if "`constraint'" == "" {
                estimates store UNRES
            }
            else {
                estimates store RES
            }
        end
    
    * create parameter vector and vcov matrix
    program create_matrices
        syntax, rhscount(str) [vcovmat(str) parammat(str)]
        
        if "`parammat'" != "" {
            cap matrix drop `parammat' 
            forval num=1(1)`rhscount' {       
                matrix `parammat'=(nullmat(params), (_b[rhs_var`num']))
            }
            matrix `parammat'=(nullmat(`parammat'), (_b[_cons] ))   // parameter vector
        }
        
        if "`vcovmat'" != "" {
            local nparam=1+`rhscount'
            matrix `vcovmat' = e(V)
            matrix `vcovmat' = `vcovmat'[1..`nparam',1..`nparam']     // vcov matrix
        }
    end
    
    * compute vcov matrix of three arbitrary transformations of parameters
    program delta_method
        syntax, rhscount(str) outfile(str)
        
        assert `rhscount' >= 3
        nlcom (_b[rhs_var1] - _b[rhs_var2]) ///
            (5*_b[rhs_var2] + (_b[rhs_var2])^2) ///
            (_b[rhs_var1]*_b[rhs_var2]*_b[rhs_var3])
            
        matrix vcov_delta=r(V)
        matrix_to_txt, matrix(vcov_delta) saving(deltamethod_`outfile') format(%19.0g) replace
    end
    
    * perform linear & nonlinear hypothesis tests
    program wald_test
        syntax, rhscount(str) outfile(str)
        
        assert `rhscount' >= 3
        testnl (_b[rhs_var1] = _b[rhs_var2]) (1/_b[rhs_var2] = _b[rhs_var3]^2)
        
        matrix wald_out = [r(chi2),r(df),r(p)]
        matrix_to_txt, matrix(wald_out) saving(waldtest_`outfile') format(%19.0g) replace
    end
    
    * perform likelihood ratio test
    program lr_test
        syntax, outfile(str)

        lrtest RES UNRES

        matrix lr_out = [r(chi2),r(df),r(p)]
        matrix_to_txt, matrix(lr_out) saving(lrtest_`outfile') format(%19.0g) replace
    end
        
    program save_output
        syntax, vcovmat(str) parammat(str) loglik_model(str) outfile(str)
        
        matrix loglik = (`loglik_model')
        
        matrix_to_txt, matrix(loglik) saving(loglik_`outfile') format(%19.0g) replace
        matrix_to_txt, matrix(`parammat') saving(parammat_`outfile') format(%19.0g) replace
        matrix_to_txt, matrix(`vcovmat') saving(vcovmat_`outfile') format(%19.0g) replace
    end

    program alternate_vcov_estimator
        syntax, vcov(str) model(str) rhscount(str) [consswitch(str) consfile(str)]
        
        di "calculating additional vcov `vcov' for model `model'"
        quietly {
            execute_ml, model(`model') rhscount(`rhscount') vcov(`vcov') consswitch(`consswitch')
            create_matrices, rhscount(`rhscount') vcovmat(`vcov')
            matrix_to_txt, matrix(`vcov') saving(`vcov'_stataout_`model'`consfile'.txt) format(%19.0g) replace
        }
    end
    
* EXECUTE
main

