oauthlib
========



[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Build Status](https://travis-ci.com/ropenscilabs/oauthlib.svg?branch=master)](https://travis-ci.com/ropenscilabs/oauthlib)

oauthlib: build and validate OAuth headers, following Ruby's <https://github.com/laserlemon/simple_oauth>

**BEWARE: VERY ALPHA - & NOT FUNCTIONAL YET**

## Installation


```r
remotes::install_github("ropenscilabs/oauthlib")
```


```r
library("oauthlib")
```

## example


```r
(x <- OAuth$new("get", "https://api.twitter.com/1/statuses/friends.json", list()))
#> <oauth> 
#>   method: GET
#>   url: https://api.twitter.com/1/statuses/friends.json
x
#> <oauth> 
#>   method: GET
#>   url: https://api.twitter.com/1/statuses/friends.json
x$url()
#> [1] "https://api.twitter.com/1/statuses/friends.json"
x$as_string()
#> [1] "OAuth oauth_nonce=\"7b05716aedd2421bdc733517e527f9c4\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1551903013.2116\", oauth_version=\"1.0\", oauth_signature=\"ZGQ4ZGE1MTE3MDg2NTg2YWQ1YWIwOGU4YTA2OTNlOTI1YTRmZWZiNg==\""
x$signed_attributes()
#> $oauth_nonce
#> [1] "7b05716aedd2421bdc733517e527f9c4"
#> 
#> $oauth_signature_method
#> [1] "HMAC-SHA1"
#> 
#> $oauth_timestamp
#> [1] 1551903013
#> 
#> $oauth_version
#> [1] "1.0"
#> 
#> $oauth_signature
#> [1] "ZGQ4ZGE1MTE3MDg2NTg2YWQ1YWIwOGU4YTA2OTNlOTI1YTRmZWZiNg=="
```

## Meta

* Please [report any issues or bugs](https://github.com/ropenscilabs/oauthlib/issues).
* License: MIT
* Get citation information for `oauthlib` in R doing `citation(package = 'oauthlib')`
* Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

[![rofooter](https://ropensci.org/public_images/github_footer.png)](https://ropensci.org)
