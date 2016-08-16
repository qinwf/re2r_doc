if(!require("re2r")){
    install.packages("devtools", quiet = TRUE)
    devtools::install_github("qinwf/re2r")
}
if(!require("stringr",quietly = TRUE)){
    install.packages("stringr")
}
if(suppressPackageStartupMessages(!require("swirl",quietly = TRUE))){
    install.packages("swirl")
}

swirl::install_course_github("qinwf","re2r_doc", multi = TRUE)

swirl()
