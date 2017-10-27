(in-package :cl-harmony)

(defparameter bot-url "N/A")
(defun bot-url (url)
  (setf bot-url url))

(defparameter base-url "https://discordapp.com/api/v6/")
(defun api-version (version)
  (str-concat "https://discordapp.com/api/" version "/"))

(defparameter api-suffix "/?v=6&encoding=json")

(defstruct (bot (:constructor primitive-bot-make))
  (token "" :type string :read-only t)
  (version "0.0.1" :type string))

(defun make-bot (token &key (version "0.0.1"))
  (unless token (error "No token specified!"))
  (primitive-bot-make :token token
		      :version version))

(defun user-agent (bot)
  (str-concat "DiscordBot (" bot-url ", " (bot-version bot) ")"))

(defun headers (bot &optional (length 0))
  (list (cons "Authorization" (str-concat "Bot " (bot-token bot)))
        (cons "User-Agent" (user-agent bot))
        (cons "Content-length" (format nil "~a" length))))

;; is 'get' reserved?
(defun get-rq (endpoint)
  (dex:get (str-concat base-url "/" endpoint api-suffix)))

;; i added -rq to make the name match get-rq for now
(defun post-rq (bot endpoint)
  (dex:post (str-concat base-url "/" endpoint api-suffix)
	    :headers (headers bot)))

(defun gateway ()
  (get-rq "gateway"))

(defun fetch-gateway-url ()
  (cadr (jonathan:parse (gateway))))

;; should this be combined with the above?
(defun gateway-url ()
  (str-concat (fetch-gateway-url) api-suffix))


(defun make-ws-client (url)
  (wsd:make-client url))

;; i cant think off the top of my head the best way to structure these things
;; a lot of these can probably be merged
;; or better named
(defun get-ws-client ()
  (make-ws-client (gateway-url)))

;; im note sure what the *var* convention is, so im just going by the examples :p
(defun connect ()
  (defvar *client* (get-ws-client))
  (wsd:start-connection *client*)
  (wsd:on :message *client*
          (lambda (message)
	    (on-recv (jonathan:parse message)))))

;; on receive websock messages by opcode
;; opcode 0
(defun on-recv-dispatch (msg)
  nil)

;; opcode 1
(defun on-recv-heartbeat (msg)
  nil)

;; opcode 2
(defun on-recv-identify (msg)
  nil)

;; opcode 3
(defun on-recv-status-update (msg)
  nil)

;; opcode 4
(defun on-recv-voice-status-update (msg)
  nil)

;; opcode 5
(defun on-recv-voice-server-ping (msg)
  nil)

;; opcode 6
(defun on-recv-resume (msg)
  nil)

;; opcode 7
(defun on-recv-reconnect (msg)
  nil)

;; opcode 8
(defun on-recv-request-guild-members (msg)
  nil)

;; opcode 9
(defun on-recv-invalid-session (msg)
  nil)

;; opcode 10
(defun on-recv-hello (msg)
  (let ((heartbeat (getf (getf msg :|d|) :heartbeat_interval)))
    (print (str-concat "Heartbeat: " heartbeat))))

;; opcode 11
(defun on-recv-heartbeat-ack (msg)
  nil)

;; receive message from websock and dispatch to handler
(defun on-recv (msg)
  (print "Hello at all??")
  (let ((op (getf msg :|op|)))
    (case op
      (0  (on-recv-dispatch msg))
      (1  (on-recv-heartbeat msg))
      (2  (on-recv-identify msg))
      (3  (on-recv-status-update msg))
      (4  (on-recv-voice-status-update msg))
      (5  (on-recv-voice-server-ping msg))
      (6  (on-recv-resume msg))
      (7  (on-recv-reconnect msg))
      (8  (on-recv-request-guild-members msg))
      (9  (on-recv-invalid-session msg))
      (10 (on-recv-hello msg))
      (11 (on-recv-heartbeat-ack msg))
      (T ;; not sure if this should be an error to the user or not?
       (error "Received invalid opcode!")))))
