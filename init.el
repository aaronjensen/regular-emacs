;;; init.el -*- lexical-binding: t; -*-

;; Borrowed from https://github.com/novoid/dot-emacs/blob/master/init.el
(defvar aj-config--init-el-start-time (current-time) "Time when init.el was started")
(defvar aj-config--init-el-split-time aj-config--init-el-start-time)

(defun aj-config/init-el-get-split-time ()
  "Return the time since the init or since the last time this was called."
  (let ((now (current-time)))
    (prog1
        (float-time (time-subtract now aj-config--init-el-split-time))
      (setq aj-config--init-el-split-time now))))

;; from: http://stackoverflow.com/questions/251908/how-can-i-insert-current-date-and-time-into-a-file-using-emacs
(defvar current-date-time-format "%a %b %d %Y-%m-%dT%H:%M:%S "
  "Format of date to insert with `insert-current-date-time' func
See help of `format-time-string' for possible replacements")

;; from: http://stackoverflow.com/questions/251908/how-can-i-insert-current-date-and-time-into-a-file-using-emacs
(defvar current-time-format "%a %H:%M:%S"
  "Format of date to insert with `insert-current-time' func.
Note the weekly scope of the command's precision.")

(let (file-name-handler-alist)
  ;; Ensure we are running out of this file's directory
  (setq dotemacs-directory (file-name-directory load-file-name)))

(defvar aj--init-el-previous-heading nil)

(defun aj-config/init-el-start-section (heading)
  "Print the split time for the previous heading."
  (when (and aj--init-el-previous-heading
             (not noninteractive))
    (let ((inhibit-message t)
          (time (* 1000 (aj-config/init-el-get-split-time))))
      (when (> time 3)
        (message "config • %4dms • %s" time aj--init-el-previous-heading))))
  (setq aj--init-el-previous-heading heading))

(defun aj-config/tangle-config-org ()
  "This function will write all source blocks from =config.org= into =config.el= that are ...
- not marked as =tangle: no=
- doesn't have the TODO state =DISABLED=
- have a source-code of =emacs-lisp="
  (require 'org)
  (let* ((body-list ())
         (output-file (concat dotemacs-directory "config.el"))
         (org-babel-default-header-args (org-babel-merge-params org-babel-default-header-args
                                                                (list (cons :tangle output-file)))))
    (let ((inhibit-message t)) (message "—————• Re-generating %s …" output-file))
    (save-restriction
      (save-excursion
        (org-babel-map-src-blocks (concat dotemacs-directory "config.org")
          (let* ((org_block_info (org-babel-get-src-block-info 'light))
                 ;;(block_name (nth 4 org_block_info))
                 (tfile (cdr (assq :tangle (nth 2 org_block_info))))
                 (match_for_TODO_keyword))
            (save-excursion
              (catch 'exit
                (org-back-to-heading t)
                (when (looking-at org-outline-regexp)
                  (goto-char (1- (match-end 0))))
                (when (looking-at (concat " +" org-todo-regexp "\\( +\\|[ \t]*$\\)"))
                  (setq match_for_TODO_keyword (match-string 1)))))
            (unless (or (string= "no" tfile)
                        (string= "DISABLED" match_for_TODO_keyword)
                        (not (string= "emacs-lisp" lang)))
              (add-to-list 'body-list (concat "\n\n;; #####################################################################################\n"
                                              "(aj-config/init-el-start-section \"" (org-get-heading) "\")\n\n"))
              (add-to-list 'body-list body)))))
      (with-temp-file output-file
        (insert ";;; config.el -*- lexical-binding: t; byte-compile-warnings: (not free-vars make-local noruntime); -*-\n")
        (insert ";; ============================================================\n")
        (insert ";; Don't edit this file, edit config.org instead.\n")
        (insert ";; Auto-generated at " (format-time-string current-date-time-format (current-time)) "on host " system-name "\n")
        (insert ";; ============================================================\n\n")
        (insert (apply 'concat (reverse body-list)))
        (insert "(aj-config/init-el-start-section nil)\n\n"))
      (let ((inhibit-message t)) (message "Wrote %s" output-file)))
    (when (fboundp #'aj-config/byte-compile)
      (aj-config/byte-compile))))

;; following lines are executed only when aj-config/tangle-config-org-hook-func()
;; was not invoked when saving config.org which is the normal case:
(let ((orgfile (concat dotemacs-directory "config.org"))
      (elfile (concat dotemacs-directory "config.el")))
  (when (or (not (file-exists-p elfile))
            (file-newer-than-file-p orgfile elfile))
    (aj-config/tangle-config-org)))

;; when config.org is saved, re-generate config.el:
(defun aj-config/tangle-config-org-hook-func ()
  (when (string= "config.org" (buffer-name))
    (let ((orgfile (concat dotemacs-directory "config.org"))
          (elfile (concat dotemacs-directory "config.el")))
      (aj-config/tangle-config-org))))
(add-hook 'after-save-hook 'aj-config/tangle-config-org-hook-func)

(defvar aj-config--init-file-loaded-p nil
  "Non-nil if the init-file has already been loaded.
This is important for Emacs 27 and above, since our early
init-file just loads the regular init-file, which would lead to
loading the init-file twice if it were not for this variable.")

(cond
 ;; If already loaded, do nothing. But still allow re-loading, just
 ;; do it only once during init.
 ((and (not after-init-time) aj-config--init-file-loaded-p))

 (t
  (setq aj-config--init-file-loaded-p t)

  (defvar aj-config-minimum-emacs-version "28.1"
    "This config does not support any Emacs version below this.")

  (defvar aj-config-local-init-file
    (expand-file-name "init.local.el" user-emacs-directory)
    "File for local customizations of Config.")

  ;; Prevent Custom from modifying this file.
  (setq custom-file (expand-file-name
                     (format "custom-%d-%d.el" (emacs-pid) (random))
                     temporary-file-directory))

  ;; Make sure we are running a modern enough Emacs, otherwise abort
  ;; init.
  (if (version< emacs-version aj-config-minimum-emacs-version)
      (error (concat "This config requires at least Emacs %s, "
                     "but you are running Emacs %s")
             aj-config-minimum-emacs-version emacs-version)

    (defvar aj-config-file (concat dotemacs-directory
                                   "config.el")
      "File containing main Emacs configuration.
This file is loaded by init.el.")

    (unless (file-exists-p aj-config-file)
      (error "Library file %S does not exist"))

    (defvar aj-config--finalize-init-hook nil
      "Hook run unconditionally after init, even if it fails.
Unlike `after-init-hook', this hook is run every time the
init-file is loaded, not just once.")

    (unwind-protect
        ;; Load the main Emacs configuration code. Disable
        ;; `file-name-handler-alist' to improve load time.
        ;;
        ;; Make sure not to load an out-of-date .elc file. Since
        ;; we byte-compile asynchronously in the background after
        ;; init succeeds, this case will happen often.
        (let ((file-name-handler-alist nil)
              (load-prefer-newer t)
              (stale-bytecode t))
          ;; Load local config, eventually I'll pull this out and do it the aj way
          (when (file-exists-p aj-config-local-init-file)
            (load aj-config-local-init-file nil t))
          (catch 'stale-bytecode
            ;; We actually embed the contents of the local
            ;; init-file directly into the compiled config.elc, so
            ;; that it can get compiled as well (and its
            ;; macroexpansion can use packages that only
            ;; loads at compile-time). So that means we have to go
            ;; the slow path if the local init-file has been
            ;; updated more recently than the compiled config.elc.
            (when (file-newer-than-file-p
                   aj-config-local-init-file
                   (concat aj-config-file "c"))
              (throw 'stale-bytecode nil))
            (load
             (file-name-sans-extension aj-config-file)
             nil 'nomessage)
            (setq stale-bytecode nil))
          (when stale-bytecode
            ;; Don't bother trying to recompile, unlike in
            ;; straight.el, since we are going to handle that
            ;; later, asynchronously.
            (ignore-errors
              (delete-file (concat aj-config-file "c")))
            (load aj-config-file nil 'nomessage 'nosuffix)))
      (run-hooks 'aj-config--finalize-init-hook)

      (unless noninteractive
        (let ((time (current-time)))
          (add-hook 'after-init-hook
                    (lambda ()
                      (let ((inhibit-message t))
                        (message "→★ loaded early-init.el: %4d ms, init.el: %4d ms, post: %4d ms, total: %4d ms"
                                 (* 1000 (float-time (time-subtract aj-config--init-el-start-time aj-config--early-init-el-start-time)))
                                 (* 1000 (float-time (time-subtract time aj-config--init-el-start-time)))
                                 (* 1000 (float-time (time-subtract (current-time) time)))
                                 (* 1000 (float-time (time-subtract (current-time) aj-config--early-init-el-start-time)))))) -90)))))))
