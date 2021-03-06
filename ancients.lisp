(in-package :cypress)

(defthing sextant :image "sextant.png" :scale 0.8)

(defparameter *megalith-images* (image-set "megalith" 2))

(defthing megalith 
  :scale 2.0
  :image (random-choose *megalith-images*)
  :tags '(:fixed)
  :description "giant stone block")

(defthing waystone 
  :scale 2.0
  :image (random-choose *megalith-images*)
  :tags '(:fixed)
  :description "ancient waystone")

(defmethod activate ((waystone waystone))
  ;; (cue-music (current-scene) "flutism.ogg")
  (narrate "You feel a sense of contact with ancient memories.")
  (mark-traversed (current-scene))
  (discuss waystone :confirm))

(defparameter *waystone-hint*
"You have discovered an 
ancient Waystone. Save your
quest progress here.")

(defmethod run :after ((waystone waystone))
  (when (< (distance-between waystone (geoffrey))
	   500)
    (show-hint *waystone-hint*)))

(define-topic confirm waystone
  "Would you like to save your quest?" :save-progress :cancel)

(define-topic save-progress waystone
  "Your progress has been saved." :ok)

(defmethod discuss :before ((waystone waystone) (topic (eql :save-progress))) 
  ;; (destroy-gump waystone)
  ;; (setf (field-value :gump waystone) nil)
  (save-quest))

(defmethod discuss :after ((waystone waystone) (topic (eql :save-progress))) 
  (with-fields (playtime) (geoffrey)
    (let ((seconds (/ playtime 30)))
      (narrate "Saved ~$ hours progress to ~A." (/ seconds (* 60 60)) (cypress-save-file)))))

(defthing small-ruin 
  :tags '(:fixed)
  :image "small-ruin.png"
  :description "strange stone ruin"
  :scale 1.6)

(defthing stone-patio 
  :tags '(:fixed)
  :image "ruined-patio.png"
  :description "stone patio"
  :scale 1.6)

(defthing stone-of-remembrance 
  :scale 1.5
  :image "curved-stone-1.png"
  :tags '(:fixed :solid)
  :description "stone of remembrance")

(defun save-file-exists ()
  (probe-file (cypress-save-file)))

(defmethod activate ((stone stone-of-remembrance))
  (if (save-file-exists)
      (progn (narrate "You feel as if Time itself is vibrating.")
	     (discuss stone :confirm))
      (narrate "There are no stored memories here.")))

(defmethod draw :after ((stone stone-of-remembrance))
  (when (save-file-exists)
    (with-fields (x y) stone
      (draw-string "Double-click the Stone of Remembrance to resume your quest."
		   (- x (units 2)) (- y (units 2))
		   :color "saddle brown"
		   :font "oldania-bold"))))

(define-topic confirm stone-of-remembrance 
  "Continue your saved quest?" :load-saved-quest :load-autosave :cancel)
  
(define-topic load-saved-quest stone-of-remembrance 
  "Loading quest...")

(defmethod discuss :after 
    ((stone stone-of-remembrance) (topic (eql :load-saved-quest)))
  (load-quest))

(define-topic load-autosave stone-of-remembrance 
  "Loading autosave file...")

(defmethod discuss :after 
    ((stone stone-of-remembrance) (topic (eql :load-autosave)))
  (load-quest (cypress-autosave-file)))

(defparameter *copper-gear-images* (image-set "copper-lock" 5))

(defthing copper-gear 
  :scale 0.7
  :image (random-choose *copper-gear-images*))

(defparameter *copper-seal-images* (image-set "copper-seal" 4))

(defthing copper-seal
  :scale 0.8
  :image (random-choose *copper-seal-images*)
  :tags '(:fixed))

(defthing copper-plate 
  :tags '(:fixed) 
  :channel 0
  :image (random-choose '("copper-plate-1.png" "copper-plate-2.png")))

(defthing copper-stairwell  :tags '(:fixed) :image (random-choose '("copper-stairwell-1.png" "copper-stairwell-2.png")))

(defmethod activate ((self copper-stairwell))
  (if *previous-scene*
      (restore-excursion-maybe)
      (switch-to-map)))

(defparameter *copper-door-closed-images* (image-set "copper-door-closed" 2))
(defparameter *copper-door-opening-images* (image-set "copper-door-opening" 2))
(defparameter *copper-door-open-images* (image-set "copper-door-open" 2))

(defthing copper-wall
  :image (random-choose *copper-door-closed-images*)
  :tags '(:solid :fixed))

(defmethod collide ((monk geoffrey) (wall copper-wall)) nil)

(defthing copper-door
  :image (random-choose *copper-door-closed-images*)
  :channel 0
  :open nil
  :tags '(:solid :fixed)
  :timer 0)

(defmethod lock ((door copper-door) (plate copper-plate) channel)
  (setf (field-value :channel door) channel)
  (setf (field-value :channel plate) channel))

(defmethod door-image ((door copper-door) n)
  (cond ((> n 90) "copper-door-open-2.png")
	((> n 80) "copper-door-open-1.png")
	((> n 60) "copper-door-opening-1.png")
	((> n 30) "copper-door-opening-2.png")
	((> n 10) "copper-door-closed-1.png")
	(t "copper-door-closed-2.png")))

(defmethod release-lock ((door copper-door) (gear copper-gear))
  (with-fields (channel open) door
    (setf open t)
    (destroy gear)
    (multiple-value-bind (x y) (at gear)
      (let ((seal (new 'copper-seal)))
	(drop-object (current-scene) seal x y)
	(bark (geoffrey) "It's opening!")
	(bring-to-front seal)))))

(defmethod activate ((plate copper-plate))
  (block colliding
    (dolist (thing (get-objects (current-scene)))
      (when (and (colliding-with plate thing)
		 (typep thing (find-class 'copper-gear)))
	(return-from colliding
	  (dolist (door (find-instances (current-scene) 'copper-door))
	    (when (= (field-value :channel plate) (field-value :channel door))
	      (release-lock door thing))))))))
		 
(defmethod activate ((gear copper-gear))
  (block colliding
    (dolist (thing (find-colliding-objects gear))
      (when (typep thing (find-class 'copper-plate))
	(activate thing)))))

(defmethod run ((door copper-door))
  (with-fields (y timer open image plate) door
    (when (not open)
      (setf (field-value :barrier-y (current-scene)) y))
    (when open
      (unless 
	  (block any-locked?
	    (dolist (door (find-instances (current-scene) 'copper-door))
	      (when (not (field-value :open door))
		(return-from any-locked? t))))
	(setf (field-value :barrier-y (current-scene)) nil))
      (setf timer 
	    (max 0 
		 (min (+ timer 1)
		      100)))
      (setf image (door-image door timer)))
    (if (plusp timer)
	(remove-tag door :solid)
	(progn (setf open nil)
	       (add-tag door :solid)))))

;;; Ancient garden

(defthing (garden scene)
  :background-image (random-choose *grassy-meadow-images*))

(defmethod find-description ((scene garden)) "forest")
(defmethod map-icon ((scene garden)) (random-choose *forest-icons*))

(defun some-ginseng () (spatter '(ginseng stone twig) :trim t :count (+ 2 (random 4))))

(defun some-snowdrops () (spatter 'snowdrop :trim t :count (+ 1 (random 4))))

(defun ginseng-garden ()
  (stacked-up
   (spray '(ruin-wall) :trim nil :count (+ 2 (random 3)))
   (randomly (some-ginseng)
	     (with-border (units 5) (singleton (new 'waystone))))
   (spray '(ruin-wall ginseng ruin-wall) :trim nil :count (+ 1 (random 4)))))

(defmethod make-terrain ((scene garden))
  (with-border (units 15)
    (lined-up-randomly 
     (lined-up-randomly (some-snowdrops) (some-trees))
     (lined-up-randomly (some-snowdrops) (ginseng-garden)))))

(defmethod begin-scene :after ((scene garden))
  (or (percent-of-time 50 (cue-music scene (random-choose '("believe-me2.ogg" "kosmium.ogg"))) t)
      (percent-of-time 20 (cue-music scene (random-choose '("mountain.ogg" "xolaros3.ogg"))))))
      
;;; Ancient caves

(defparameter *ancient-cave-images* (image-set "ancient-cave" 3))

(defthing (cave scene)
  :darkness-image "darkness.png"
  :background-image (random-choose *ancient-cave-images*))

(defmethod make-terrain ((scene cave))
  (with-border (units 10)
    (stacked-up (singleton (new 'crumbling-stairwell))
		(spray '(ruin-wall copper-seal stone) :trim nil :count (random-choose '(2 3 4 5))))))

(defmethod initialize :after ((scene cave) &key)
  (with-fields (height width) scene
    (percent-of-time 80
      (dotimes (n (1+ (random 5)))
	(drop-object scene (new 'bone-dust) (random width) (random height))))))

(defmethod begin-scene :after ((scene cave))
  (mark-traversed scene)
  (clear-excursion)
  (with-fields (height width) scene
    (resize-to-background-image scene)
    (percent-of-time 40 (cue-music scene (random-choose '("monks.ogg" "dusk.ogg" "spiritus.ogg"))))
    (percent-of-time 20 (drop-object scene (new 'cryptghast) (random width) (random height)))	
    (percent-of-time 20 (drop-object scene (new 'cryptghast) (random width) (random height)))
    (percent-of-time 40 (drop-object scene (make-box) (- width 200) (- height 200)))))

;;; First story cave

(defthing (southern-cave scene)
  :darkness-image "darkness.png"
  :background-image "ancient-cave-3.png")

(defmethod find-description ((scene southern-cave))
  "cave")

(defmethod starting-x ((self southern-cave) direction) (units 14))
(defmethod starting-y ((self southern-cave) direction) (units 8))

(defun wall () (singleton (new 'copper-wall)))

(defmethod make-terrain ((cave southern-cave))
  (let ((left-door (new 'copper-door))
	(right-door (new 'copper-door))
	(left-plate (new 'copper-plate))
	(right-plate (new 'copper-plate)))
    (lock left-door left-plate 1)
    (lock right-door right-plate 2)
    (stacked-up
     (with-border (units 3) (singleton (new 'copper-stairwell)))
     (with-border (units 15) (spatter 'bone-dust))
     (lined-up (with-border (units 10) (singleton left-plate))
	       (with-border (units 10) (singleton right-plate)))
     (lined-up (wall) (wall) (wall)  (singleton left-door) (wall) (wall) (wall) (wall))
     (lined-up (wall) (wall) (wall)  (singleton right-door) (wall) (wall) (wall) (wall))
     (with-border (units 10)
       (lined-up-randomly (singleton (new 'book))
			  (spatter '(book ruined-book silver-book) :trim t :count 14)
			  (singleton (new 'alistair)))))))
     
(defmethod begin-scene :after ((cave southern-cave))
  (mark-traversed cave)
  (clear-excursion)
  (resize-to-background-image cave)
  (cue-music cave (random-choose '("monks.ogg" "spiritus.ogg" "dusk.ogg" "3-against-2.ogg"))))

;; (defmethod run :after ((cave southern-cave))
;;   (setf (field-value :barrier-y (current-scene)) nil)

;;; Second story cave

(defthing (southeastern-cave scene)
  :darkness-image "darkness.png"
  :background-image "ancient-cave-2.png")

(defmethod find-description ((scene southeastern-cave))
  "cave")

(defmethod starting-x ((self southeastern-cave) direction) (units 14))
(defmethod starting-y ((self southeastern-cave) direction) (units 8))

(defmethod make-terrain ((cave southeastern-cave))
  (let ((left-door (new 'copper-door))
	(middle-door (new 'copper-door))
	(right-door (new 'copper-door))
	(left-plate (new 'copper-plate))
	(middle-plate (new 'copper-plate))
	(right-plate (new 'copper-plate)))
    (lock left-door left-plate 1)
    (lock right-door right-plate 2)
    (lock middle-door middle-plate 3)
    (stacked-up
     (with-border (units 3) (singleton (new 'copper-stairwell)))
     (with-border (units 15) (spatter '(bone-dust skull)))
     (lined-up (with-border (units 7) (singleton left-plate))
	       (with-border (units 8) (singleton middle-plate))
	       (with-border (units 7) (singleton right-plate)))
     (lined-up (wall) (wall) (wall)  (singleton left-door) (wall) (wall) (wall) (wall))
     (lined-up (wall) (wall) (wall)  (singleton middle-door) (wall) (wall) (wall) (wall))
     (lined-up (wall) (wall) (wall)  (singleton right-door) (wall) (wall) (wall) (wall))
     (stacked-up 
      (with-border (units 10)
	(spatter 'bone-dust))
      (spatter 'cryptghast :count 3)))))
       
(defthing (quine-item-box item-box) :description "ornate silver box")

(defmethod activate :after ((box quine-item-box))
  (add-event :visited-southern-cave))

(defmethod begin-scene :after ((cave southeastern-cave))
  (resize-to-background-image cave)
  (let ((box (new 'quine-item-box)))
    (drop-object cave box (units 30) (units 140))
    (add-inventory-item box (quantity-of 'copper-gear 2))
    (add-inventory-item box (quantity-of 'silver-elixir 2))
    (add-inventory-item box (quantity-of 'elixir 2))
    (add-inventory-item box (quantity-of 'green-elixir 1))
    (add-inventory-item box (tome-of 'hold-creature))
    (add-inventory-item box (new 'silver-armor))
    (add-inventory-item box (make-scroll "crumbling scroll" *wax-cylinder-letter*)))
  (clear-excursion)
  (cue-music cave (random-choose '("monks.ogg" "spiritus.ogg" "dusk.ogg" "3-against-2.ogg"))))

;;; Third story cave

(defthing (eastern-cave cave))

(defmethod find-description ((scene eastern-cave))
  "cave")

