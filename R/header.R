#' OAuth
#'
#' @export
#' @details
#' **Methods**
#'   \describe{
#'     \item{`url()`}{
#'       get the url
#'     }
#'     \item{`as_string()`}{
#'       get the url
#'     }
#'     \item{`is_valid()`}{
#'       check if it's valid
#'     }
#'     \item{`signed_attributes()`}{
#'       get the signed attributes
#'     }
#'   }
#'
#' @format NULL
#' @usage NULL
#' @return an [OAuth] object
#' @examples \dontrun{
#' (x <- OAuth$new("get", "https://api.twitter.com/1/statuses/friends.json", list()))
#' x
#' x$url()
#' x$as_string()
#' x$signed_attributes()
#' x$is_valid()
#' 
#' (x <- OAuth$new("get", "https://api.twitter.com/1/statuses/friends.json?stuff=4", 
#'   list(), list(consumer_secret = "hello", token_secret = "world")))
#' x$options
#' x$.__enclos_env__$private$attributes()
#' x$.__enclos_env__$private$normalized_attributes()
#' x$.__enclos_env__$private$signature()
#' x$.__enclos_env__$private$hmac_sha1_signature()
#' x$.__enclos_env__$private$secret()
#' x$.__enclos_env__$private$signature_base()
#' x$.__enclos_env__$private$normalized_params()
#' x$.__enclos_env__$private$signature_params()
#' x$.__enclos_env__$private$url_params()
#' x$.__enclos_env__$private$rsa_sha1_signature()
#' x$.__enclos_env__$private$private_key()
#' }
OAuth <- R6::R6Class(
  'OAuth',
  public = list(
    callback = NULL,
    consumer_key = NULL,
    nonce = NULL,
    signature_method = NULL,
    timestamp = NULL,
    token = NULL,
    verifier = NULL,
    version = NULL,
    method = NULL,
    params = NULL,
    options = NULL,
    uri = NULL,
    uri_s = "",
    ignore_extra_keys = NULL,
    ATTRIBUTE_KEYS = c("callback", "consumer_key", 'nonce', "signature_method",
      "timestamp", "token", "verifier", "version"),
    IGNORED_KEYS = c("consumer_secret", "token_secret", "signature"),

    print = function(x, ...) {
      cat("<oauth> ", sep = "\n")
      cat(paste0("  method: ", self$method), sep = "\n")
      cat(paste0("  url: ", self$uri_s), sep = "\n")
      invisible(self)
    },

    initialize = function(method, url, params, oauth = list(), ignore_extra_keys = FALSE) {
      self$method <- toupper(method)
      uri <- private$url_parse(url)
      uri$scheme <- tolower(uri$scheme)
      # uri$normalize!
      uri$fragment <- NA
      self$uri <- uri
      self$uri_s <- private$make_url(uri)
      self$params <- params
      self$options <- if (inherits(oauth, "list")) c(private$default_options(), oauth) else self$parse(oauth)
      self$ignore_extra_keys <- ignore_extra_keys
    },

    url = function() self$uri_s,

    as_string = function() {
      paste0("OAuth ", private$normalized_attributes())
    },

    is_valid = function(secrets = list()) {
      original_options <- self$options
      self$options <- c(self$options, secrets)
      valid <- self$options[["signature"]] == private$signature()
      self$options <- original_options
      return(valid)
    },

    signed_attributes = function() {
      utils::modifyList(private$attributes(), list(oauth_signature = private$signature()))
    }
  ),

  private = list(
    default_options = function() {
      list(
        nonce = paste(openssl::rand_bytes(16), collapse = ""),
        signature_method = "HMAC-SHA1",
        timestamp = as.numeric(Sys.time()),
        version = "1.0"
      )
    },
    attributes = function() {     
      matching_keys <- extra_keys <- c()
      kys <- names(self$options)
      for (i in seq_along(kys)) {
        if (kys[i] %in% self$ATTRIBUTE_KEYS) {
          matching_keys <- c(matching_keys, kys[i])
        } else {
          extra_keys <- c(extra_keys, kys[i])
        }
      }
      extra_keys <- extra_keys[!extra_keys %in% self$IGNORED_KEYS]
      if (self$ignore_extra_keys || length(extra_keys) == 0) {
        tmp <- self$options
        names(tmp) <- paste0("oauth_", names(tmp))
        tmp
      } else {
        stop(sprintf("OAuth: Found extra option keys not matching ATTRIBUTE_KEYS:\n  [%s]",
          paste0(extra_keys, collapse = ', ')))
      }
    },
    normalized_attributes = function() {
      atts <- self$signed_attributes()
      paste(names(atts), sprintf("\"%s\"", unlist(unname(atts))),
        sep = "=", collapse = ", ")
    },
    signature = function() {
      method <- paste0("private$", 
        gsub("-", "_", tolower(self$options$signature_method)), "_signature")
      eval(parse(text = method))()
    },

    ## url methods
    # duped from crul::url_parse
    url_parse = function(url) {
      stopifnot(length(url) == 1, is.character(url))
      tmp <- urltools::url_parse(url)
      tmp <- as.list(tmp)
      if (!is.na(tmp$parameter)) {
        tmp$parameter <- unlist(lapply(strsplit(tmp$parameter,
          "&")[[1]], function(x) {
          z <- strsplit(x, split = "=")[[1]]
          as.list(stats::setNames(z[2], z[1]))
        }), FALSE)
      }
      return(tmp)
    },
    # modified from crul::url_build
    make_url = function(x) {
      url <- file.path(sprintf("%s://%s", x$scheme, x$domain), x$path)
      url <- gsub("\\s", "%20", url)
      private$add_query(x$parameter, url)
      # add_query(x$parameter, url)
    },
    # modified from crul:::add_query
    add_query = function(x, url) {
      if (length(x) && !all(is.na(x))) {
        quer <- list()
        for (i in seq_along(x)) {
          if (!inherits(x[[i]], "AsIs")) {
            x[[i]] <- curl::curl_escape(x[[i]])
          }
          quer[[i]] <- paste(curl::curl_escape(names(x)[i]),
            x[[i]], sep = "=")
        }
        parms <- paste0(quer, collapse = "&")
        paste0(url, "?", parms)
      } else {
        return(url)
      }
    },

    hmac_sha1_signature = function() {
      base64enc::base64encode(
        charToRaw(openssl::sha1(private$signature_base(), private$secret())))
    },

    secret = function() {
      paste(c(self$options$consumer_secret, self$options$token_secret), collapse = "&")
    },
    # alias_method :plaintext_signature, :secret

    signature_base = function() {
      paste(
        vapply(c(self$method, self$uri_s, private$normalized_params()), curl::curl_escape, ""),
        collapse = "&"
      )
    },

    normalized_params = function() {
      tmp <- private$signature_params()
      paste(names(tmp), curl::curl_escape(unlist(unname(tmp))),
        sep = "=", collapse = "&")
    },

    signature_params = function() {
      c(private$attributes(), self$params, private$url_params())
    },

    url_params = function() self$uri$parameter,

    # FIXME: not sure how to replicate what Ruby does
    rsa_sha1_signature = function() {
      # Base64.encode64(private_key.sign(OpenSSL::Digest::SHA1.new, signature_base)).chomp.gsub(/\n/, '')
    },

    # FIXME: not sure how to replicate what Ruby does
    private_key = function() {
      # self$options$consumer_secret
      # openssl::rsa_encrypt(tempkey, pubkey)
      # OpenSSL::PKey::RSA.new(options[:consumer_secret])
    }
  )
)
