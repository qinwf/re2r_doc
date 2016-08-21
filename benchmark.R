## ----options, echo = FALSE, message = FALSE------------------------------
knitr::opts_chunk$set(
  comment = "#>",
  error = FALSE,
  tidy = FALSE
)

options(digits = 3, microbenchmark.unit = "ms")

## ----library, echo = FALSE, message = FALSE------------------------------
library(re2r)
library(stringi)
library(microbenchmark)
library(ggplot2)
library(directlabels)
library(knitr)

parallel = T
fail = T
others = T
redos = T
stringi_bench = T

linear.legend <- function(times, 
                          ylab_name = "seconds", 
                          xlab_name = "subject/pattern size",
                          limit = c(1, 30), 
                          breaks = c(1, 5, 10, 15, 20, 25),
                          title = "Timing regular expressions in R, linear scale") 
{
  ggplot()+
  ggtitle(title)+
  scale_y_continuous(ylab_name)+
  scale_x_continuous(xlab_name,
                     limits=limit,
                     breaks=breaks)+
  geom_point(aes(N, time/1e9, color=expr),
             shape=1,
             data=times)
}

log.legend <- function(times, ylab_name = "log scale seconds",
                       xlab_name = "subject/pattern size",
                       limit = c(1, 30), 
                       breaks = c(1, 5, 10, 15, 20, 25),
                       title = "Timing regular expressions in R, log scale") 
{ 
  ggplot()+
  ggtitle(title)+
  scale_y_log10(ylab_name)+
  scale_x_log10(xlab_name,
                limits=limit,
                breaks=breaks)+
  geom_point(aes(N, time/1e9, color=expr),
             shape=1,
             data=times)
}


## ---- include=FALSE------------------------------------------------------
all_txt = c()

if(redos==T){
    all_txt = c(all_txt,knit_expand(file = "./bench/bench-redos.Rmd"))
}

if(fail==T){
    all_txt = c(all_txt,knit_expand(file = "./bench/bench-fail.Rmd"))
}

if(stringi_bench==T){
    all_txt = c(all_txt,knit_expand(file = "./bench/bench-stringi.Rmd"))
}

if(others==T){
    all_txt = c(all_txt,knit_expand(file = "./bench/bench-others.Rmd"))
}

if(parallel==T){
    all_txt = c(all_txt,knit_expand(file = "./bench/bench-parallel.Rmd"))
}



## ------------------------------------------------------------------------

pattern = enc2utf8("^[\\s\u200c]+|[\\s\u200c]+$")

times.list <- list()
index = 1
seq_ = seq(1000,9000,by = 1000)
for(N in seq_){
    # string and pattern
    string = paste0("-- play happy sound for player to enjoy. ", paste0(rep(" ",N), collapse = ""),"boom!")
    
    # pre-compiled RE2
    regexp = re2(pattern)
    
    # run gc
    invisible(gc())
    
    # benchmark
    N.times <- microbenchmark(
        ICU = stri_detect_regex(string, pattern = pattern),
        PCRE = grepl(pattern, string, perl = TRUE),
        TRE = grepl(pattern, string, perl = FALSE),
        RE2n = re2_detect(string, pattern),
        RE2c = re2_detect(string, regexp),
        times = 4)
    
    times.list[[index]] <- data.frame(N, N.times)
    index= index+1
}

times <- do.call(rbind, times.list)

direct.label(linear.legend(times, limit=c(0,9000), breaks = seq_,xlab_name = "string size", title = "StackOverflow.com Outage"), "last.polygons")



## ------------------------------------------------------------------------

pattern = "^(([a-z])+.)+[A-Z]([a-z])+$"

times.list <- list()
index = 1
seq_ = seq(1,24,by = 1)
for(N in seq_){
    # string and pattern
    string = paste0(paste0(rep("a",N), collapse = ""),"boom!")
    
    # pre-compiled RE2
    regexp = re2(pattern)
    
    # run gc
    invisible(gc())
    
    # benchmark
    N.times <- microbenchmark(
        ICU = stri_detect_regex(string, pattern = pattern),
        PCRE = grepl(pattern, string, perl = TRUE),
        TRE = grepl(pattern, string, perl = FALSE),
        RE2n = re2_detect(string, pattern),
        RE2c = re2_detect(string, regexp),
        times = 4)
    
    times.list[[index]] <- data.frame(N, N.times)
    index= index+1
}

times <- do.call(rbind, times.list)

direct.label(linear.legend(times, limit=c(0,24), breaks = seq_,xlab_name = "string size", title = "Java Classname Malicious Regex"), "last.polygons")


## ---- echo=TRUE----------------------------------------------------------

times.list <- list()

for(N in c(1:25)){
    # string and pattern
    string <- paste(rep("a", N), collapse="")
    pattern <- paste(rep(c("a?", "a"), each=N), collapse="")
    
    # pre-compiled RE2
    regexp = re2(pattern)
    
    # run gc
    invisible(gc())
    
    # benchmark
    N.times <- microbenchmark(
        ICU = stri_detect_regex(string, pattern = pattern),
        PCRE = grepl(pattern, string, perl = TRUE),
        TRE = grepl(pattern, string, perl = FALSE),
        RE2n = re2_detect(string, pattern),
        RE2c = re2_detect(string, regexp),
        times = 5)
    
    times.list[[N]] <- data.frame(N, N.times)
}

times <- do.call(rbind, times.list)

direct.label(linear.legend(times, xlab_name = "Pattern size", title = "pattern: 'a?a?aa' 'a?a?a?aaa' ..."), "last.polygons")
direct.label(log.legend(times, xlab_name = "pattern size", title = "Pattern: 'a?a?aa' 'a?a?a?aaa' ... log scale"), "last.polygons")


## ------------------------------------------------------------------------
string <- paste(rep("a", 27), collapse="")
pattern <- paste(rep(c("a?", "a"), each=27), collapse="")

system.time(re2_detect(string,pattern))
system.time(stri_detect_regex(string,pattern))

## ------------------------------------------------------------------------
gen_bench = function(range_, pattern) {
    times.list <- list()
    index = 1
    for (N in range_) {
        # pre-compiled RE2
        regexp = re2(pattern)
        string = stringi::stri_rand_strings(1, N,
                                            pattern = "[a-zA-Z0-9 !@#$%()*Ω≈ç√∫˜µåœ∑†¨ˆ˙©ƒ]")
        
        # run gc
        invisible(gc())
        
        # benchmark
        N.times <- microbenchmark(
            ICU = stri_detect_regex(string, pattern = pattern),
            PCRE = grepl(pattern, string, perl = TRUE),
            TRE = grepl(pattern, string, perl = FALSE),
            RE2n = re2_detect(string, pattern),
            RE2c = re2_detect(string, regexp),
            times = 5
        )
        
        times.list[[index]] <- data.frame(N, N.times)
        index = index + 1
    }
    
    times <- do.call(rbind, times.list)
    return(times)
}

plot_bench = function(pattern) {
    res = gen_bench(seq(from = 10000, to = 70000, by = 10000), pattern)
    
    direct.label(
        linear.legend(
            res,
            limit = c(0, 71000),
            breaks = seq(from = 10000, to = 70000, by = 10000),
            xlab_name = "string size"
        ),
        "last.polygons"
    )
}

## ------------------------------------------------------------------------
EASY0 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ$"
plot_bench(EASY0)

EASY1 = "A[AB]B[BC]C[CD]D[DE]E[EF]F[FG]G[GH]H[HI]I[IJ]J$"
plot_bench(EASY1)

## ------------------------------------------------------------------------
MEDIUM = "[XYZ]ABCDEFGHIJKLMNOPQRSTUVWXYZ$"
plot_bench(MEDIUM)

## ------------------------------------------------------------------------
HARD = "[ -~]*ABCDEFGHIJKLMNOPQRSTUVWXYZ$"
plot_bench(HARD)

## ------------------------------------------------------------------------
PARENS = "([ -~])*(A)(B)(C)(D)(E)(F)(G)(H)(I)(J)(K)(L)(M)(N)(O)(P)(Q)(R)(S)(T)(U)(V)(W)(X)(Y)(Z)$"
plot_bench(PARENS)

## ------------------------------------------------------------------------
FANOUT = "(?:[\\x{80}-\\x{10FFFF}]?){100}[\\x{80}-\\x{10FFFF}]"
range_ = seq(from = 10000, to = 80000, by = 10000)
times.list <- list()
index = 1
for(N in range_){
    # pre-compiled RE2
    regexp = re2(FANOUT)
    pattern = FANOUT
    string = stringi::stri_rand_strings(1,N, 
                                        pattern="[a-zA-Z0-9 !@#$%()*Ω≈ç√∫˜µåœ∑†¨ˆ˙©ƒ]")
    
    # run gc
    invisible(gc())
    
    # benchmark
    N.times <- microbenchmark(
        ICU = stri_detect_regex(string, pattern = pattern),
        PCRE = grepl(pattern, string, perl = TRUE),
        RE2n = re2_detect(string, pattern),
        RE2c = re2_detect(string, regexp),
        times = 5)
    
    times.list[[index]] <- data.frame(N, N.times)
    index = index+1
}

times <- do.call(rbind, times.list)

direct.label(linear.legend(times, limit = c(0,90000), breaks = range_, xlab_name = "string size"), "last.polygons")

## ------------------------------------------------------------------------

if (!file.exists('./test1.csv.gz')) {
    # don't change the URL!
    download.file('http://cran-logs.rstudio.com/2014/2014-03-18.csv.gz',
                  './test1.csv.gz')
}

f <- gzfile('./test1.csv.gz')
data <- enc2native(readLines(f, encoding="ASCII"))
close(f)
regexp = re2(',\\"stringi\\",')
invisible(gc(reset=TRUE))
res = microbenchmark(
    ICU = stri_detect_regex(data, ',\\"stringi\\",'),
    RE2c = re2_detect(data, ',\\"stringi\\",'),
    RE2n = re2_detect(data, regexp),
    TRE = grepl(',\\"stringi\\",', data),
    PCRE = grepl(',\\"stringi\\",', data, perl=TRUE),
    times=15L, control=list(order='inorder', warmup=3L)
)
autoplot(res) + ggtitle("detect methods: CRAN logs")

pattern = '^\\"(.*)\\",\\"(.*)\\",(.*),\\"(.*)\\",\\"(.*)\\",\\"(.*)\\",\\"(.*)\\",\\"(.*)\\",\\"(.*)\\",(.*)$'
microbenchmark(
    ICU = stri_match_first_regex(data,pattern),
    RE2n = re2_match(data,pattern),
    times = 1
)

## ---- include=FALSE------------------------------------------------------
try({rm(data);rm(f)})

## ------------------------------------------------------------------------

if (!file.exists('./pan_tadeusz_15.txt')) {
    # don't change the URL!
    download.file('https://raw.githubusercontent.com/gagolews/stringi/master/devel/benchmarks/pan_tadeusz_15.txt',
                  './pan_tadeusz_15.txt')
}
pan_tadeusz <- enc2native(readLines('./pan_tadeusz_15.txt', encoding="UTF-8"))
sie <- enc2native(stri_enc_fromutf32(c(115,105,281)))
regexp = re2(sie)
invisible(gc(reset=TRUE))

res = microbenchmark(
    ICU = stri_detect_regex(pan_tadeusz, sie),
    RE2c = re2_detect(pan_tadeusz, regexp),
    RE2n = re2_detect(pan_tadeusz, sie),
    TRE = grepl(sie, pan_tadeusz),
    PCRE = grepl(sie, pan_tadeusz, perl=TRUE),
    times = 20
)
plot(autoplot(res) + ggtitle("detect methods: Pan Tadeusz"))

pan_tadeusz <- readLines('./pan_tadeusz_15.txt', encoding="UTF-8")
invisible(gc(reset=TRUE))
autoplot(
    microbenchmark(
        ICU = stri_count_regex(pan_tadeusz, sie),
        RE2c = re2_count(pan_tadeusz, regexp),
        RE2n = re2_count(pan_tadeusz, sie),
        times = 20 
    )
) + ggtitle("count methods: Pan Tadeusz")

regexp = re2("\\P{L}")
autoplot(microbenchmark(
    ICU = stri_split_regex(pan_tadeusz, "\\P{L}"),
    RE2c = re2_split(pan_tadeusz, regexp),
    RE2n = re2_split(pan_tadeusz, "\\P{L}")
)) + ggtitle("split methods: Pan Tadeusz")


## ------------------------------------------------------------------------
s <- c("Lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipisicing",
       "elit", "Proin", "nibh", "augue", "suscipit", "a", "scelerisque",
       "sed", "lacinia", "in", "mi", "Cras", "vel", "lorem", "Etiam",
       "pellentesque", "aliquet", "tellus", "Phasellus", "pharetra",
       "nulla", "ac", "diam", "Quisque", "semper", "justo", "at", "risus",
       "Donec", "venenatis", "turpis", "vel", "hendrerit", "interdum",
       "dui", "ligula", "ultricies", "purus", "sed", "posuere", "libero",
       "dui", "id", "orci", "Nam", "congue", "pede", "vitae", "dapibus",
       "aliquet", "elit", "magna", "vulputate", "arcu", "vel", "tempus",
       "metus", "leo", "non", "est", "Etiam", "sit", "amet", "lectus",
       "quis", "est", "congue", "mollis", "Phasellus", "congue", "lacus",
       "eget", "neque")

srep  <- rep(s, 100)
srep2 <- stri_dup(s, 1000)

pat1 = "^[A-Z]"
pat2 = "[a-z]$"
pat3 = "^[a-z]+$"

run_detect = function(s,pat){
    regexp = re2(pat)
    autoplot(microbenchmark(
    ICU = stri_detect_regex(s,pat1),
    RE2c = re2_detect(s, regexp),
    RE2n = re2_detect(s, pat),
    TRE = grepl(pat, s),
    PCRE = grepl(pat, s, perl = T),
    times = 20
    ))
}

run_detect(s, pat1)
run_detect(s, pat2)
run_detect(s, pat3)
run_detect(srep, pat1)
run_detect(srep, pat2)
run_detect(srep, pat3)
run_detect(srep2, pat1)
run_detect(srep2, pat2)
run_detect(srep2, pat3)

p <- c("^[A-Z]", ".{3}", ".{4}", "[^a]+")
srep2 <- rep(s, 10)
prep <- rep(p, 60)

run_detect = function(s,pat){
    regexp = re2(pat)
    autoplot(microbenchmark(
    ICU = stri_detect_regex(s,pat1),
    RE2c = re2_detect(s, regexp),
    RE2n = re2_detect(s, pat),
    times = 20
    ))
}

run_detect(s, p)
run_detect(srep2, p)
run_detect(s, prep)


## ------------------------------------------------------------------------

lettersdigits <- c(0:9, stri_enc_fromutf32(list(97L, 98L, 99L, 100L, 101L, 102L, 103L,
                                                104L, 105L, 106L, 107L,  108L, 109L, 110L, 111L, 112L, 113L, 114L, 115L,
                                                116L, 117L, 118L,  119L, 120L, 121L, 122L, 261L, 263L, 281L, 322L, 324L,
                                                243L, 347L,  378L, 380L)))
lettersdigits <- enc2native(lettersdigits)

set.seed(123)
letdig <- replicate(100000, {
    paste(sample(lettersdigits,
                 floor(abs(rcauchy(1, 10))+1), replace=TRUE), collapse='')
})

regexp = re2("[0-9]{3,}")
invisible(gc(reset=TRUE))
res = microbenchmark(
    TRE = grepl("[0-9]{3,}", letdig),
    PCRE = grepl("[0-9]{3,}", letdig, perl=TRUE),
    ICU = stri_detect_regex(letdig, "[0-9]{3,}"),
    RE2n = re2_detect(letdig, "[0-9]{3,}"),
    RE2c = re2_detect(letdig, regexp),
    times = 20
)
autoplot(res) + ggtitle("detect methods: letters & digits")


## ------------------------------------------------------------------------
str <- enc2native(stri_join(stri_dup("kaw\u0105", 100000), "law\u0105"))
firstword <- enc2native("kaw\u0105")

invisible(gc(reset=TRUE))
regexp = re2(firstword)
autoplot(microbenchmark(
    ICU = stri_detect_regex(str, firstword),
    TRE = grepl(firstword, str),
    PCRE = grepl(firstword, str, perl=TRUE),
    RE2c = re2_detect(str, regexp),
    RE2n = re2_detect(str, firstword)
, times = 20))

## ------------------------------------------------------------------------
str <- enc2native(stri_join(stri_dup("kaw\u0105", 100000), "law\u0105"))
lastword <- enc2native("law\u0105")
invisible(gc(reset=TRUE))
regexp = re2(lastword)
autoplot(microbenchmark(
    ICU = stri_detect_regex(str, lastword),
    TRE = grepl(lastword, str),
    PCRE = grepl(lastword, str, perl=TRUE),
    RE2c = re2_detect(str, regexp),
    RE2n = re2_detect(str, lastword),
    times = 20
))

## ------------------------------------------------------------------------
str <- enc2utf8(stri_dup("ab\u0105", 4000))
lastword <- enc2utf8(stri_join(stri_dup("ab\u0105", 400), "c"))
invisible(gc(reset=TRUE))
regexp = re2(lastword)
autoplot(microbenchmark(
    ICU = stri_detect_regex(str, lastword),
    TRE = grepl(lastword, str),
    PCRE = grepl(lastword, str, perl=TRUE),
    RE2c = re2_detect(str, regexp),
    RE2n = re2_detect(str, lastword),
    times = 20
))

## ------------------------------------------------------------------------
lorem_text <- "Lorem ipsum dolor sit amet, consectetur adipisicing elit. Proin
   nibh augue, suscipit a, scelerisque sed, lacinia in, mi. Cras vel
   lorem. Etiam pellentesque aliquet tellus. Phasellus pharetra nulla ac
   diam. Quisque semper justo at risus. Donec venenatis, turpis vel
   hendrerit interdum, dui ligula ultricies purus, sed posuere libero dui
   id orci. Nam congue, pede vitae dapibus aliquet, elit magna vulputate
   arcu, vel tempus metus leo non est. Etiam sit amet lectus quis est
   congue mollis. Phasellus congue lacus eget neque. Phasellus ornare,
   ante vitae consectetuer consequat, purus sapien ultricies dolor, et
   mollis pede metus eget nisi. Praesent sodales velit quis augue. Cras
   suscipit, urna at aliquam rhoncus, urna quam viverra nisi, in interdum
   massa nibh nec erat."

run_match = function(s,pat){
    regexp = re2(pat)
    
    stopifnot(all.equal(
        stri_match(s, regex = pat, cg_missing = ""),
        re2_match(s,pat),
        check.attributes = FALSE))
    
    autoplot(microbenchmark(
        ICU = stri_match(s, regex = pat1, cg_missing = ""),
        RE2c = re2_match(s, regexp),
        RE2n = re2_match(s, pat),
        times = 20
    ))
}

run_match_all = function(s,pat){
    regexp = re2(pat)
    
    stopifnot(all.equal(
        stri_match_all_regex(s,pat, cg_missing = ""),
        re2_match_all(s,pat),
        check.attributes = FALSE))
    
    autoplot(microbenchmark(
        ICU = stri_match_all_regex(s,pat1, cg_missing = ""),
        RE2c = re2_match_all(s, regexp),
        RE2n = re2_match_all(s, pat),
        times = 20
    ))
}
s <- lorem_text

run_match(s,"(a+)+")
run_match(s," ")

run_match_all(s,"(a+)+")
run_match_all(s," ")

## ------------------------------------------------------------------------
s <- lorem_text
srep <- rep(s,100)
srepdup <- stri_dup(srep,10)

#regex
pat1 <- " [[a-z]]*\\. Phasellus (ph|or|co)"
pat2 <- "(s|el|v)it"
pat3 <- c(pat1, pat2, "ell?(e|u| )", "(L|l)orem .*? nisi .*? nisi","123")

run_count = function(s,pat){
    regexp = re2(pat)
    autoplot(microbenchmark(
    ICU = stri_count_regex(s,pat1),
    RE2c = re2_count(s, regexp),
    RE2n = re2_count(s, pat),
    times = 20
    ))
}

run_count(s,pat1)
run_count(s,pat2)
run_count(s,pat3)

run_count(srep,pat1)
run_count(srep,pat2)
run_count(srep,pat3)

run_count(srepdup,pat1)
run_count(srepdup,pat2)
run_count(srepdup,pat3)


## ------------------------------------------------------------------------
run_locate = function(s,pat){
    regexp = re2(pat)
    
    stopifnot(all.equal(
        stri_locate_first_regex(s,pat),
        re2_locate(s,pat),
        check.attributes = FALSE))
    
    autoplot(microbenchmark(
    ICU = stri_locate_first_regex(s,pat),
    RE2c = re2_locate(s, regexp),
    RE2n = re2_locate(s, pat),
    times = 20
    ))
}

run_locate_all = function(s,pat){
    regexp = re2(pat)
    
    stopifnot(all.equal(
        stri_locate_all_regex(s,pat),
        re2_locate_all(s,pat),
        check.attributes = FALSE))
    
    autoplot(microbenchmark(
    ICU = stri_locate_all_regex(s,pat),
    RE2c = re2_locate_all(s, regexp),
    RE2n = re2_locate_all(s, pat),
    times = 20
    ))
}

x <- stri_dup('aba', c(100, 1000, 10000))
run_locate(x,"b")
run_locate_all(x,"b")

x <- stri_dup('aba', 1:10)
run_locate(x,"b")
run_locate_all(x,"b")

## ------------------------------------------------------------------------
s <- lorem_text
run_replace = function(s,pat,reps){
    regexp = re2(pat)
    
    stopifnot(all.equal(
        stri_replace_first_regex(s,pat,reps),
        re2_replace(s,pat,reps),
        check.attributes = FALSE))
    
    autoplot(microbenchmark(
    ICU = stri_replace_first_regex(s,pat, reps),
    RE2c = re2_replace(s, regexp, reps),
    RE2n = re2_replace(s, pat, reps),
    times = 20
    ))
}

run_replace_all = function(s,pat,reps){
    regexp = re2(pat)
    
    stopifnot(all.equal(
        stri_replace_all_regex(s,pat,reps),
        re2_replace_all(s,pat,reps),
        check.attributes = FALSE))
    
    autoplot(microbenchmark(
    ICU = stri_replace_all_regex(s, pat, reps),
    RE2c = re2_replace_all(s, regexp, reps),
    RE2n = re2_replace_all(s, pat, reps),
    times = 20
    ))
}
run_replace(s," ",1)
run_replace_all(s," ",1)
run_replace(s,' ',1:10)
run_replace_all(s,' ',1:10)

srep <- rep(s,10)
run_replace(srep," ",1)
run_replace_all(srep," ",1)

srepdup <- stri_dup(srep,26)
run_replace(srepdup," ",1:10)
run_replace_all(srepdup," ",1:10)

## ------------------------------------------------------------------------
sorig <- lorem_text
s <- sorig

run_split = function(s,pat){
    regexp = re2(pat)
    
    stopifnot(all.equal(
        stri_split_regex(s,pat),
        re2_split(s,pat),
        check.attributes = FALSE))
    
    autoplot(microbenchmark(
    ICU = stri_split_regex(s,pat),
    RE2c = re2_split(s, regexp),
    RE2n = re2_split(s, pat),
    times = 20
    ))
}

run_split(s, " ")
run_split(s, "(a+)+")

s <- stri_dup(rep(sorig,10),10)

run_split(s, " ")
run_split(s, "(a+)+")

## ------------------------------------------------------------------------
pattern = "([0-9]+)-([0-9]+)-([0-9]+)"
regexp = re2(pattern)
string = "650-253-0001"
autoplot(microbenchmark(
      TRE = grepl(pattern, string),
      PCRE = grepl(pattern, string, perl=TRUE),
      ICU = stri_detect_regex(string, pattern),
      RE2n =  re2_detect(string, pattern),
      RE2c = re2_detect(string, regexp)
    ))

## ------------------------------------------------------------------------
http_text =
  "GET /asdfhjasdhfasdlfhasdflkjasdfkljasdhflaskdjhfalksdjfhasdlkfhasdlkjfhasdljkfhadsjklf HTTP/1.1"
  
pattern = "(?-s)^(?:GET|POST) +([^ ]+) HTTP"
regexp = re2(pattern)

autoplot(microbenchmark(
      ICU = stri_match(http_text, regex = pattern),
      RE2n =  re2_match(http_text, pattern),
      RE2c = re2_match(http_text, regexp)
))

## ------------------------------------------------------------------------
dd =stri_rand_strings(100000,10, pattern = "[a-zA-Z0-9\"\']")
head(dd)

microbenchmark(sequential =  quote_meta(dd), parallel =  quote_meta(dd, parallel = T,grain_size = 10000), times = 1)

## ------------------------------------------------------------------------
dd =stri_rand_strings(100000, 10, pattern = "[a-zA-Z0-9\"\']")
head(dd)
regexp = re2("sd2er3")

microbenchmark(sequential = re2_replace(dd, regexp, ""), parallel = re2_replace(dd, regexp, "", parallel = T, grain_size = 1000) , times = 5)

microbenchmark(sequential = re2_replace_all(dd, regexp, ""), parallel = re2_replace_all(dd, regexp, "", parallel = T, grain_size = 1000) , times = 5)

## ------------------------------------------------------------------------
dd =stri_rand_strings(100000, 10, pattern = "[a-zA-Z0-9\"\']")
head(dd)
regexp = re2("(sd)")

invisible(gc())
microbenchmark(sequential =  re2_extract(dd, regexp), parallel = re2_extract(dd, regexp, parallel= T ,grain_size = 1000) ,times = 5)

microbenchmark(sequential =  re2_extract_all(dd, regexp), parallel = re2_extract_all(dd, regexp, parallel= T ,grain_size = 1000) ,times = 5)

## ------------------------------------------------------------------------
dd =stri_rand_strings(100000,10, pattern = "[a-zA-Z0-9\"\']")
head(dd)
regexp = re2("sd")

microbenchmark(sequential =  re2_match(dd, regexp), parallel = re2_match(dd, regexp, parallel= T , grain_size = 1000) ,times = 5)

