(in-package :lispcord.core)

(defstruct (bot (:constructor primitive-make-bot))
  (token "" :type string :read-only t)
  (os (software-type) :type string)
  (lib "lispcord" :type string)
  (version "0.0.1" :type string)
  (seq 0 :type fixnum)
  (heartbeat-thread nil)
  conn)

(defparameter bot-url "N/A")
(defun bot-url (url)
  (setf bot-url url))

(defparameter base-url "https://discordapp.com/api/v6/")
(defun api-version (version)
  (str-concat "https://discordapp.com/api/" version "/"))

(defparameter api-suffix "/?v=6&encoding=json")


(defun user-agent (bot)
  (str-concat "DiscordBot (" bot-url ", " (bot-version bot) ")"))

;; i removed content length because i think it handles it automatically
(defun headers (bot)
  (list (cons "Authorization" (str-concat "Bot " (bot-token bot)))
        (cons "User-Agent" (user-agent bot))))


;; is 'get' reserved?
(defun get-rq (endpoint &optional bot)
  (dex:get (str-concat base-url "/" endpoint)
	   :headers (if bot (headers bot))))

;; i added -rq to make the name match get-rq for now
(defun post-rq (endpoint &optional bot content)
  (dex:post (str-concat base-url "/" endpoint)
	    :headers (if bot (headers bot))
	    :content content))
