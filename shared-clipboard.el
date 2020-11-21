;; to enable the adhoc clipboard
;; M-x shared-clipboard-enable
;; to disable it
;; M-x shared-clipboard-disable


;;;###autoload
(defvar  shared-clipboard-file-name
  (expand-file-name "~/.shared.clipboard")
  "adhoc clipboard's content is stored in this file")
;;;###autoload
(defun  shared-clipboard-cut (start end)
  "cut text to the adhoc clipboard"
  (interactive "r")
  (shared-clipboard-save-content
   (delete-and-extract-region start end)))
;;;###autoload
(defun  shared-clipboard-copy (start end)
  "copy text to the adhoc clipboard"
  (interactive "r")
  (shared-clipboard-save-content
   (buffer-substring start end)))
;;;###autoload
(defun  shared-clipboard-paste (&optional arg)
  "paste text to the adhoc clipboard"
  (interactive "p")
  (let ((text (shared-clipboard-content)))
    (dotimes (_ arg)
      (insert text))))

;;; helper functions

(defvar shared-clipboard-paste-md5 "")
(defun shared-clipboard-content ()
  (with-temp-buffer
    (insert-file-contents shared-clipboard-file-name)
    (buffer-string)))
(defun shared-clipboard-save-content (text)
  (with-temp-file shared-clipboard-file-name
    (insert text)))


(defun wcy-darwin-copy (start end)
  "cut text to the adhoc clipboard"
  (interactive "r")
  (let ((text (buffer-substring start end)))
    (with-temp-file shared-clipboard-file-name
      (insert text))
    (call-process-shell-command
     "pbcopy"
     shared-clipboard-file-name
     nil nil)))
(defun wcy-darwin-paste ()
  "paste text to the adhoc clipboard"
  (interactive)
  (insert (shell-command-to-string "LANG=en_US.UTF-8 pbpaste")))

;; Return the value of the current wcy adhoc clipboard
;; If this function is called twice and finds the same text,
;; it returns nil the second time.  This is so that a single
;; selection won't be added to the kill ring over and over.
;;;###autoload
(defun shared-clipboard-get ()
  (let* ((content (shared-clipboard-content))
         (current-md5 (md5 content)))
    (if (string= shared-clipboard-paste-md5 current-md5)
        nil ;; return nil if it is called twice
      (setq shared-clipboard-paste-md5 current-md5)
      content)))
;;;###autoload
(defun shared-clipboard-save (text &optional push)
  (shared-clipboard-save-content text))

(require 'simple)
(defvar wcy-adhoc-orig-interprogram-paste-function
  interprogram-paste-function)
(defvar wcy-adhoc-orig-interprogram-cut-function
  interprogram-cut-function)

;;;###autoload
(defun shared-clipboard-enable ()
  (interactive)
  (setq wcy-adhoc-orig-interprogram-paste-function
        (or interprogram-paste-function #'ignore)
        wcy-adhoc-orig-interprogram-cut-function
        (or interprogram-cut-function #'ignore))
  (setq interprogram-paste-function
	#'(lambda (&rest args)
	    (let ((x (apply wcy-adhoc-orig-interprogram-paste-function args)))
	      (if x x
		(apply 'shared-clipboard-get args)))))
  (setq interprogram-cut-function
	#'(lambda (&rest args)
	    (apply 'shared-clipboard-save args)
	    (apply wcy-adhoc-orig-interprogram-cut-function args))))

;;;###autoload
(defun shared-clipboard-disable ()
  (interactive)
  (setq interprogram-paste-function
	wcy-adhoc-orig-interprogram-paste-function
	interprogram-cut-function
	wcy-adhoc-orig-interprogram-cut-function))



(provide 'shared-clipboard)
;; Local Variables:
;; mode:emacs-lisp
;; coding: utf-8-unix
;; End:
