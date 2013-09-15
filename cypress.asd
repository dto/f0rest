(asdf:defsystem #:cypress
  :depends-on (:xelf)
  :components ((:file "package")
	       (:file "world" :depends-on ("package"))
	       (:file "mission" :depends-on ("world"))
	       (:file "objects" :depends-on ("mission"))
	       (:file "enemy" :depends-on ("objects"))
	       (:file "gumps" :depends-on ("enemy"))
	       (:file "dialogue" :depends-on ("gumps"))
	       (:file "monk" :depends-on ("dialogue"))
	       (:file "story" :depends-on ("monk"))
	       (:file "cypress" :depends-on ("story"))))