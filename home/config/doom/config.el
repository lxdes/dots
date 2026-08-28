;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(load! "modules/ui")
(load! "modules/dashboard")
(load! "modules/dired")
(load! "modules/org")
(load! "modules/treesit")
(load! "modules/lsp")
(load! "modules/writing")
(load! "modules/keybinds.el")
(setq initial-buffer-choice 'dashboard-open)

(after! flymake
  (defadvice! +flymake-truncate-diagnostic-text-a (text)
    :filter-return #'flymake--diag-text
    (if (and (stringp text) (> (length text) 300))
        (concat (substring text 0 300) "... [truncated]")
      text)))
