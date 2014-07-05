(asdf:defsystem #:cypress
  :depends-on (:xelf)
  :components ((:file "package")
	       (:file "world" :depends-on ("package"))
	       (:file "status" :depends-on ("world"))
	       (:file "objects" :depends-on ("status"))
	       (:file "enemy" :depends-on ("objects"))
	       (:file "gumps" :depends-on ("enemy"))
	       (:file "monk" :depends-on ("gumps"))
	       (:file "magic" :depends-on ("monk"))
	       (:file "geoffrey" :depends-on ("magic"))
	       (:file "lucius" :depends-on ("geoffrey"))
	       (:file "arturo" :depends-on ("lucius"))
	       (:file "alistair" :depends-on ("arturo"))
	       (:file "terrain" :depends-on ("alistair"))
	       (:file "scene" :depends-on ("terrain"))
	       (:file "town" :depends-on ("scene"))
	       (:file "ancients" :depends-on ("town"))
	       (:file "alonso" :depends-on ("ancients"))
	       (:file "hamlet" :depends-on ("alonso"))
	       (:file "owl" :depends-on ("hamlet"))
	       (:file "wizards" :depends-on ("owl"))
	       (:file "amalia" :depends-on ("wizards"))
	       (:file "map" :depends-on ("amalia"))
	       (:file "lore" :depends-on ("map"))
	       (:file "story" :depends-on ("lore"))
	       (:file "cypress" :depends-on ("story"))))
