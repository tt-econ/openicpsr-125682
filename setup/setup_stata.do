clear all
set more off, perm

program main
    * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    * Add required packages from SSC and ttstata misc to this list
    * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    local ssc_packages "mmerge geonear geodist parmest eclplot"
    local misc_packages "matrix_to_txt preliminaries loadglob load_and_append oo ooo oooo rankunique save_data sortunique"

    if !missing("`ssc_packages'") {
        foreach pkg in `ssc_packages' {
            capture which `pkg'
            if _rc == 111 {
                dis "Installing `pkg'"
                quietly ssc install `pkg', replace
            }
        }
    }

    if !missing("`misc_packages'") {
        foreach pkg in `misc_packages' {
            capture which `pkg'
            if _rc == 111 {
                dis "Installing `pkg'"
                quietly net from "https://raw.githubusercontent.com/ttecon/ttstata/master/misc/ado"
                net install `pkg', replace
            }
        }
    }

    * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    * Other packages from other sources
    * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    capture which grc1leg
    if _rc == 111 {
        quietly net from "http://www.stata.com/users/vwiggins"
        quietly net install grc1leg, replace
    }

    /*
    * This is how to install old mmerge if necessary
    net from http://www.stata.com
    net cd stb
    net cd stb53
    net describe dm75
    net install dm75, replace
    */
end

main

