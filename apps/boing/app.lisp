;imports
(import "sys/lisp.inc")
(import "class/lisp.inc")
(import "gui/lisp.inc")

(structure '+event 0
	(byte 'close+ 'max+ 'min+))

(defq id t index 0 xv 4 yv 0
	frames (map (lambda (_) (Canvas-from-file (cat "apps/boing/taoball_" (str _) ".cpm") +load_flag_shared+)) (range 1 12))
	sframes (map (lambda (_) (Canvas-from-file (cat "apps/boing/taoball_s_" (str _) ".cpm") +load_flag_shared+)) (range 1 12)))

(ui-window mywindow ()
	(ui-title-bar _ "Boing" (0xea19 0xea1b 0xea1a) +event_close+)
	(ui-backdrop mybackdrop (:color +argb_black+ :ink_color +argb_white+ :min_width 640 :min_height 480)
		(ui-element frame (elem 0 frames))
		(ui-element sframe (elem 0 sframes))))

(defun main ()
	(bind '(x y w h) (apply view-locate (. mywindow :pref_size)))
	(gui-add (view-change mywindow x y w h))
	(while id
		(bind '(_ _ backdrop_width backdrop_height) (. mybackdrop :get_bounds))
		(defq index (% (inc index) (length frames))
			old_frame frame frame (elem index frames)
			old_sframe sframe sframe (elem index sframes))
		(bind '(x y w h) (. old_frame :get_bounds))
		(bind '(sx sy sw sh) (. old_sframe :get_bounds))
		(. (. mybackdrop :add_dirty sx sy sw sh) :add_dirty x y w h)
		(setq x (+ x xv) y (+ y yv) yv (inc yv))
		(if (> y (- backdrop_height h)) (setq y (- backdrop_height h) yv -22))
		(if (< x 0) (setq x 0 xv (abs xv)))
		(if (> x (- backdrop_width w)) (setq x (- backdrop_width w) xv (neg (abs xv))))
		(view-set-bounds frame x y w h)
		(view-set-bounds sframe (+ x 8) (+ y 64) sw sh)
		(. old_sframe :sub)
		(. old_frame :sub)
		(. (. mybackdrop :add_back sframe) :add_front frame)
		(. sframe :dirty)
		(. frame :dirty)
		(while (mail-poll (array (task-mailbox)))
			(cond
				((= (setq id (get-long (defq msg (mail-read (task-mailbox))) ev_msg_target_id)) +event_close+)
					(setq id nil))
				((= id +event_min+)
					;min button
					(bind '(x y w h) (apply view-fit (cat (. mywindow :get_pos) (. mywindow :pref_size))))
					(. mywindow :change_dirty x y w h))
				((= id +event_max+)
					;max button
					(bind '(x y) (. mywindow :get_pos))
					(bind '(w h) (. mywindow :pref_size))
					(bind '(x y w h) (view-fit x y (/ (* w 5) 3) (/ (* h 5) 3)))
					(. mywindow :change_dirty x y w h))
				(t (. mywindow :event msg))))
		(task-sleep 40000))
	(. mywindow :hide))
