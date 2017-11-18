

(defpackage :lispcord.pipes
  (:use :cl :lispcord.util)
  (:export #:make-pipe
	   #:pipep
	   #:pipe-along
	   #:watch
	   #:watch-do
	   #:drop
	   #:pmap
	   #:pfilter
	   #:pjoin

	   #:taggedp
	   #:from-origin-p

	   #:make-cargo
	   #:open-cargo
	   #:with-cargo
	   #:watch-with-cargo
	   #:watch-with-case
	   #:cargo-send))



(defpackage :lispcord.constants
  (:use :cl :lispcord.util)
  (:export #:+os+
	   #:+lib+
	   #:+base-url+
	   #:+api-suffix+
	   #:+gw-rate-limit+
	   #:+gw-rate-limit-connection+
	   #:+gw-rate-limit-game-status+))

(defpackage :lispcord.ratelimits
  (:use :cl :lispcord.util :lispcord.constants)
  (:export #:rl-parse
	   #:rl-buffer))

(defpackage :lispcord.core
  (:use :cl
	:lispcord.util
	:lispcord.pipes
	:lispcord.ratelimits
	:lispcord.constants)
  (:export #:bot
	   #:primitive-make-bot
	   #:bot-token
	   #:bot-os
	   #:bot-lib
	   #:bot-version
	   #:bot-seq
	   #:bot-session-id
	   #:bot-conn
	   #:bot-done
	   #:bot-heartbeat-thread
	   #:bot-callbacks
	   #:bot-user
	   #:bot-afk-since

	   #:>message>
	   #:>user>
	   #:>guild>
	   #:>status>
	   #:>channel>
	   
	   #:bot-url
	   #:base-url
	   #:api-suffix
	   #:discord-req
	   #:get-rq
	   #:post-rq))

(defpackage :lispcord.cache
  (:use :cl :lispcord.util :lispcord.pipes :lispcord.core)
  (:export #:cache-guild
	   #:cache-channel
	   #:cache-user))

(defpackage :lispcord.gateway
  (:use :bordeaux-threads
	:cl
	:lispcord.util
	:lispcord.pipes
	:lispcord.core
	:lispcord.cache
	:lispcord.classes
	:lispcord.constants)
  (:export #:connect))

(defpackage :lispcord.http
  (:use :cl
	:lispcord.constants
	:lispcord.util
	:lispcord.cache
	:lispcord.core)
  (:export #:send))

(defpackage :lispcord
  (:use :cl
	:lispcord.util
	:lispcord.classes
	:lispcord.constants
	:lispcord.gateway
	:lispcord.http
	:lispcord.core
	:lispcord.pipes)
  (:export #:make-bot
	   #:connect
	   #:disconnect
	   #:reply
	   #:with-handler
	   #:watch-with-case
	   #:!!))


