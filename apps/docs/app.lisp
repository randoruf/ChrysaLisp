;imports
(import "sys/lisp.inc")
(import "class/lisp.inc")
(import "gui/lisp.inc")
(import "lib/text/syntax.inc")

(structure '+event 0
	(byte 'close+ 'button+))

(defq margin_width (* 8 3)
	doc_list '("VM" "ASSIGNMENT" "STRUCTURE" "COMMS" "FUNCTIONS" "LISP" "ENVIRONMENT"
	"ITERATION" "TERMINAL" "COMMANDS" "DIARY" "SYNTAX" "CLASSES" "INTRO" "TAOS" "TODO"))

(defun normal-line ()
	(cond
		((starts-with "```lisp" line_str)
			(setq state :code))
		((starts-with "```vdu" line_str)
			(setq state :vdu))
		((starts-with "#### " line_str)
			(def (setq line_widget (Text)) :text (slice 5 -1 line_str)
				:font (create-font "fonts/OpenSans-Regular.ctf" 22)))
		((starts-with "### " line_str)
			(def (setq line_widget (Text)) :text (slice 4 -1 line_str)
				:font (create-font "fonts/OpenSans-Regular.ctf" 26)))
		((starts-with "## " line_str)
			(def (setq line_widget (Text)) :text (slice 3 -1 line_str)
				:font (create-font "fonts/OpenSans-Regular.ctf" 30)))
		((starts-with "# " line_str)
			(def (setq line_widget (Text)) :text (slice 2 -1 line_str)
				:font (create-font "fonts/OpenSans-Regular.ctf" 34)))
		((starts-with "* " line_str)
			(def (setq line_widget (Flow)) :flow_flags +flow_right_fill+)
			(def (defq bullet_widget (Text)) :text (cat " " (num-to-utf8 0xe979) " ") 
					:font (create-font "fonts/Entypo.ctf" 24))
			(def (defq text_widget (Text)) :text (slice 2 -1 line_str))
			(. line_widget :add_back bullet_widget)
			(. line_widget :add_back text_widget))
		((find-rev "`" line_str)
			(def (setq line_widget (Flow)) :flow_flags +flow_right_fill+)
			(defq word_lst (map trim (split (cat " " line_str " ") "`")))
			(each (lambda (word)
				(setq word_cnt (inc word_cnt))
				(cond
					((even? word_cnt)
						(def (defq word_widget (Text)) :text (cat " " word " ") :ink_color +argb_blue+))
					(t	(def (defq word_widget (Text)) :text word :ink_color +argb_black+)))
				(. line_widget :add_back word_widget)) word_lst)
			(setq word_cnt (inc word_cnt)))
		(t
			(def (setq line_widget (Text)) :text line_str))))

(defun lisp-line ()
	(cond
		((starts-with "```" line_str)
			(setq state :normal word_cnt 0))
		((defq tab_pos (find-rev (ascii-char 9) line_str))
			(def (setq line_widget (Flow)) :flow_flags +flow_right_fill+)
			(def (defq tab_widget (Text)) :text (pad "    " (* 4 (inc tab_pos))))
			(def (defq code_widget (Text)) :text (slice (inc tab_pos) -1 line_str)
				:font *env_terminal_font* :ink_color +argb_blue+)
			(. line_widget :add_back tab_widget)
			(. line_widget :add_back code_widget))
		(t
			(def (setq line_widget (Text)) :text line_str
				:font *env_terminal_font* :ink_color +argb_blue+))))

(defun vdu-line ()
	(cond
		((starts-with "```" line_str)
			(setq vdu_text (cat '("") vdu_text '("")))
			(def (defq vdu_widget (Vdu)) :font *env_terminal_font*
				:vdu_width 80 :vdu_height (length vdu_text) :color 0 :ink_color +argb_black+)
			(bind '(w h) (. vdu_widget :pref_size))
			(. vdu_widget :change 0 0 w h)
			(. coloriser :set_state :text)
			(. vdu_widget :load (map (# (. coloriser :colorise %0)) vdu_text) 0 0 0 1000)
			(def (setq line_widget (Backdrop)) :style 1 :color +argb_grey1+ :min_width w :min_height h)
			(. line_widget :add_child vdu_widget)
			(setq state :normal word_cnt 0 vdu_text (list)))
		((defq tab_pos (find-rev (ascii-char 9) line_str))
			(push vdu_text (cat (pad "    " (* 4 (inc tab_pos))) (slice (inc tab_pos) -1 line_str))))
		(t	(push vdu_text line_str))))

(defun populate-page (file)
	(ui-root page_flow (Flow) (:flow_flags (logior +flow_flag_right+ +flow_flag_fillh+)
			:font *env_window_font*)
		(ui-label _ (:min_width margin_width :color +argb_grey15+))
		(ui-flow page_widget (:flow_flags (logior +flow_flag_down+ +flow_flag_fillw+))))
	(defq state :normal word_cnt 0 vdu_text (list))
	(each-line (lambda (line_str)
		(task-sleep 0)
		(defq line_str (trim-end line_str (ascii-char 13)) line_widget nil)
		(case state
			(:normal (normal-line))
			(:code (lisp-line))
			(:vdu (vdu-line)))
		(if line_widget (. page_widget :add_child line_widget))) (file-stream (cat "docs/" file ".md")))
	(bind '(w h) (. page_flow :pref_size))
	(. page_flow :change 0 0 w h)
	(.-> page_scroll (:add_child page_flow) (:layout))
	(.-> doc_flow :layout :dirty_all))

(ui-window mywindow (:color +argb_grey15+)
	(ui-title-bar _ "Docs" (0xea19) +event_close+)
	(ui-flow doc_flow (:flow_flags +flow_right_fill+ :font *env_window_font* :color *env_toolbar_col*)
		(ui-flow index (:flow_flags (logior +flow_flag_down+ +flow_flag_fillw+))
			(each (lambda (p)
				(. (ui-button _
					(:text p :flow_flags (logior +flow_flag_align_vcenter+ +flow_flag_align_hleft+))) :connect +event_button+)) doc_list))
		(ui-scroll page_scroll +scroll_flag_vertical+ (:min_width 848 :min_height 800))))

(defun main ()
	(defq coloriser (Syntax))
	(populate-page (elem 0 doc_list))
	(bind '(x y w h) (apply view-locate (. mywindow :pref_size)))
	(gui-add (. mywindow :change x y w h))
	(while (cond
		((= (defq id (get-long (defq msg (mail-read (task-mailbox))) ev_msg_target_id)) +event_close+)
			nil)
		((= id +event_button+)
			(populate-page (get :text (. mywindow :find_id (get-long msg ev_msg_action_source_id)))))
		(t (. mywindow :event msg))))
	(. mywindow :hide))
