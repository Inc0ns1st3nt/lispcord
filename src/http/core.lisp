(in-package :lispcord.http)

(defvar *client* nil
  "This is an empty dummy var to allow for implicits.
It may be set by make-bot!")

; send a message!
(defun send (bot channel-id content)
  (post-rq (str-concat "channels/" channel-id "/messages")
	   bot
	   `(("content" . ,content))))





(defgeneric from-id (type snowflake &optional bot)
  (:documentation "Retrieves the given object type via ID, either from the cache or through a REST call"))

(defgeneric create (content destination &optional bot)
  (:documentation "Sends a POST-request to create the given
object."))
