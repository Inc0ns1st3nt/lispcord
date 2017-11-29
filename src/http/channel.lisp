(in-package :lispcord.http)

(defmethod from-id (id (c (eql :channel))
		    &optional (bot *client*))
  (if (getcache-id id :channel)
      (getcache-id id :channel)
      (let* ((flake (sf-to-string id))
	     (req (handler-case (discord-req
				 (str-concat "channels/" flake)
				 :bot bot)
		    (dex:http-request-not-found (e)
		      (declare (ignore e))
		      nil))))
	(if req
	    (lc:cache :channel req)))))


(defclass new-msg ()
  ((content :initarg :content)
   (nonce   :initform (make-nonce))
   (tts     :initarg :tts)
   (file    :initarg :file)
   (embed   :initarg :embed)))

(defmethod %to-json ((m new-msg))
  (with-object
    (write-key-value "content" (slot-value m 'content))
    (write-key-value "nonce" (slot-value m 'nonce))
    (write-key-value "tts" (or (slot-value m 'tts) :false))
    (write-key-value "file" (or (slot-value m 'file) :false))
    (write-key-value "embed" (or (slot-value m 'embed) :false))))

(defun make-message (content &key tts file embed)
  (make-instance 'new-msg
		 :content content
		 :tts tts
		 :file file
		 :embed embed))




(defclass new-chnl ()
  ((name       :initarg :name)
   (position   :initarg :pos)
   (topic      :initarg :topic)
   (nsfw       :initarg :nsfw)
   (bitrate    :initarg :bitrate)
   (user-lim   :initarg :user-lim)
   (overwrites :initarg :overwrites)
   (parent-id  :initarg :parent)
   (type       :initarg :type)))

(defun make-channel (&key name position topic nsfw
		       bitrate user-limit overwrites
		       parent-id type)
  (make-instance 'new-chnl
		 :name name
		 :pos position
		 :topic topic
		 :nsfw nsfw
		 :bitrate bitrate
		 :user-lim user-limit
		 :overwrites overwrites
		 :parent parent-id
		 :type type))

(defmethod %to-json ((c new-chnl))
  (let ((name (slot-value c 'name))
	(pos (slot-value c 'position))
	(top (slot-value c 'topic))
	(nsfw (slot-value c 'nsfw))
	(bit (slot-value c 'bitrate))
	(lim (slot-value c 'user-lim))
	(ovw (slot-value c 'overwrites))
	(parent (slot-value c 'parent-id))
	(type (slot-value c 'type)))
    (with-object
      (if name (write-key-value "name" name))
      (if pos (write-key-value "position" pos))
      (if top (write-key-value "topic" top))
      (if nsfw (write-key-value "nsfw" nsfw))
      (if bit (write-key-value "bitrate" bit))
      (if lim (write-key-value "user_limit" lim))
      (if ovw (write-key-value "permission_overwrites"ovw))
      (if parent (write-key-value "parent_id" parent))
      (if type (write-key-value "type" type)))))






(defmethod edit ((c new-chnl) (chan lc:channel)
		 &optional (bot *client*))
  (cache :channel (discord-req
		   (str-concat "channels/" (lc:id chan))
		   :bot bot
		   :type :patch
		   :content (to-json c))))



(defmethod create ((m new-msg) (c lc:channel)
		   &optional (bot *client*))
  (when (< 2000 (length (slot-value m 'content)))
    (error "Message size exceeds maximum discord message size!~%"))
  (let* ((nonce (slot-value m 'nonce))
	 (path (str-concat "channels/" (lc:id c) "/messages"))
	 (response (discord-req
		    path
		    :bot bot
		    :type :post
		    :content (to-json m)
		    :content-type (if (slot-value m 'file)
				      "multipart/form-data"
				      "application/json")))
	 (reply-nonce (gethash "nonce" response)))
    (if (equal reply-nonce nonce)
	(from-json :message response)
	(error "Could not send message, nonce failure of ~a ~a"
	       nonce reply-nonce))))

(defmethod create ((s string) (c lc:channel)
		   &optional (bot *client*))
  (create (make-message s) c bot))


(defmethod erase ((c lc:channel) &optional (bot *client*))
  (let ((response (handler-case (discord-req
				 (str-concat "channels/" (lc:id c))
				 :bot bot
				 :type :delete)
		    (dex:http-request-not-found (e)
		      (declare (ignore e))
		      nil))))
    (if response
	(decache-id
	 (gethash "id" response)
	 :channel))))

(defun get-messages (channel &key around
			       before
			       after
			       (limit 50)
			       (bot *client*))
  (let ((final (cond ((and before (not after) (not around))
		      (format nil "before=~a" before))
		     ((and after (not around))
		      (format nil "after=~a" after))
		     (around
		      (format nil "around=~a" around))
		     ((or around before after)
		      (error ":BEFORE, :AROUND and :AFTER are exclusive to one another!~%"))
		     (t nil))))
    (mapvec (curry #'from-json :message)
	    (discord-req
	     (format nil "channels/~a/messages?limit=~a~@[&~a~]"
		     (sf-to-string (lc:id channel)) limit final)
	     :bot bot))))

(defmethod from-id (message-id (c lc:channel) &optional (bot *client*))
  (from-json :message (discord-req
		       (str-concat "channels/" (lc:id c)
				   "/messages/" message-id)
		       :bot bot)))





(defmethod create ((c character) (m lc:message)
		   &optional (bot *client*))
  (discord-req (str-concat "channels/" (lc:channel-id m)
			   "/messages/" (lc:id m)
			   "/reactions/"
			   (drakma:url-encode (string c) :utf8)
			   "/@me")
	       :bot bot
	       :content "{}"
	       :type :put))

(defmethod create ((e lc:emoji) (m lc:message)
		   &optional (bot *client*))
  (discord-req (str-concat "channels/" (lc:channel-id m)
			   "/messages/" (lc:id m)
			   "/reactions/" (lc:name e) ":" (lc:id e)
			   "/@me")
	       :bot bot
	       :content "{}"
	       :type :put))


(defun erase-reaction (emoji message
		       &optional user (bot *client*))
  (declare (type lc:message message)
	   (type (or character lc:emoji) emoji))
  (let ((e (if (characterp emoji)
	       (drakma:url-encode (string emoji) :utf8)
	       (str-concat (lc:name emoji) ":" (lc:id emoji)))))
    (discord-req (str-concat "channels/" (lc:channel-id message)
			     "/messages/" (lc:id message)
			     "/reactions/" e
			     (if user (lc:id user) "/@me"))
		 :bot bot
		 :type :delete)))



(defmethod edit ((s string) (m lc:message) &optional (bot *client*))
  (unless (< (length s) 2000) (error "Message content too long!"))
  (discord-req (str-concat "channels/" (lc:channel-id m)
			   "/messages/" (lc:id m))
	       :bot bot
	       :content (str-concat "{\"content\":\"" s "\"}")
	       :type :patch))

(defmethod edit ((e lc:embed) (m lc:message) &optional (bot *client*))
  (discord-req (str-concat "channels/" (lc:channel-id m)
			   "/messages/" (lc:id m))
	       :bot bot
	       :content (str-concat "{\"embed\":\"" (to-json e) "\"}")
	       :type :patch))


(defmethod erase ((m lc:message) &optional (bot *client*))
  (discord-req (str-concat "/channels/" (lc:channel-id m)
			   "/messages/" (lc:id m))
	       :bot bot
	       :type :delete))

(defun erase-messages (array-of-ids channel &optional (bot *client*))
  (when (typep channel 'lc:guild-channel)
    (discord-req (str-concat "channels/" (lc:id channel)
			     "/messages/bulk-delete")
		 :type :post
		 :bot bot
		 :content (str-concat "{\"messages\":"
				      (to-json array-of-ids) "}"))))


(defun make-overwrite (id &optional (allow 0) (deny 0) (type "role"))
  (make-instance 'lc:overwrite :id id :allow allow :deny deny :type type))

(defmethod edit ((o lc:overwrite) (c lc:channel)
		 &optional (bot *client*))
  (discord-req (str-concat "channels/" (lc:id c)
			   "/permissions/" (lc:id o))
	       :bot bot
	       :type :put
	       :content `(("allow" . ,(lc:allow o))
			  ("deny" . ,(lc:deny o))
			  ("type" . ,(lc:type o)))))

(defun erase-overwrite (overwrite channel &optional (bot *client*))
  (declare (type lc:channel channel)
	   (type (or snowflake lc:overwrite) overwrite))
  (let ((o (if (typep overwrite 'lc:overwrite)
	       (lc:id overwrite)
	       overwrite)))
    (discord-req (str-concat "channels/" (lc:id channel)
			     "/permissions/" o)
		 :bot bot
		 :type :delete)))

(defun start-typing (channel &optional (bot *client*))
  (declare (type lc:channel channel))
  (discord-req (str-concat "channels/" (lc:id channel)
			   "typing")
	       :bot bot
	       :type :post
	       :content "{}"))

(defun get-pinned (channel &optional (bot *client*))
  (declare (type lc:channel channel))
  (mapvec (curry #'from-json :message)
	  (discord-req (str-concat "channels/" (lc:id channel)
				   "/pins")
		       :bot bot)))

(defun pin (message channel &optional (bot *client*))
  (declare (type lc:channel channel)
	   (type lc:message message))
  (discord-req (str-concat "channels/" (lc:id channel)
			   "/pins/" (lc:id message))
	       :bot bot
	       :type :put
	       :content "{}"))

(defun unpin (message channel &optional (bot *client*))
  (declare (type lc:channel channel)
	   (type lc:message message))
  (discord-req (str-concat "channels/" (lc:id channel)
			   "/pins/" (lc:id message))
	       :bot bot
	       :type :delete))


