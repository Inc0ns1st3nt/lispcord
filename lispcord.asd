(asdf:defsystem :lispcord
    :description "A client library for the discordapp bot api"
    :author "MegaLoler"
    :license "yet-to-be-specified"
    :serial t
    :depends-on (:dexador :websocket-driver-client :jonathan)
    :components ((:module src
			  :serial t
			  :components ((:file "package")
				       (:file "util")
				       (:file "core")
				       (:file "http")
				       (:file "gateway")
				       (:file "lispcord")))))