;;; early-init.el -*- lexical-binding: t; -*-

(defvar aj-config--early-init-el-start-time (current-time) "Time when early-init.el was started")

;; A big contributor to startup times is garbage collection. We up the gc
;; threshold to temporarily prevent it from running, then reset it later by
;; enabling `gcmh-mode'. Not resetting it will cause stuttering/freezes.
(setq gc-cons-threshold most-positive-fixnum)

;; Resizing the Emacs frame can be a terribly expensive part of changing the
;; font. By inhibiting this, we easily halve startup times with fonts that are
;; larger than the system default.
(setq frame-inhibit-implied-resize t)

;; We use straight.el, so do not enable packages
(setq package-enable-at-startup nil)

;; for native compilation
(setq native-comp-speed 2
      native-comp-async-jobs-number 4)

(setq aj-fixed-font "JetBrains Mono NL")
(setq aj-fixed-font-default-size 15)

(setq default-frame-alist
      (append
       (list
        `(font . ,(concat aj-fixed-font "-" (number-to-string aj-fixed-font-default-size)))
        '(min-height . 1) '(height . 45)
        '(min-width . 1) '(width . 81)
        '(vertical-scroll-bars . nil)
        '(internal-border-width . 8)
        '(left-fringe . 8)
        '(right-fringe . 8)
        '(tool-bar-lines . 0)
        '(menu-bar-lines . 0))
       default-frame-alist))

(setq ns-use-thin-smoothing t
      ns-use-proxy-icon nil)

;; (tool-bar-mode -1)
;; (tooltip-mode -1)
(global-display-line-numbers-mode 1)
