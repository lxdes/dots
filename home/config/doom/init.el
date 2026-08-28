;;; init.el -*- lexical-binding: t; -*-
(doom!
 :completion
 (company +auto)
 (vertico +icons)
 (embark +vertico)

 :app
 :ui
 doom
 doom-quit
 hl-todo
 modeline
 nav-flash
 ophints
 (popup +defaults)
 smooth-scroll
 treemacs
 window-select

 :editor
 (evil +everywhere)
 file-templates
 fold
 (format +onsave)
 multiple-cursors
 snippets
 :emacs
 tramp
 vc
 (dired +dirvish +icons)
 electric
 (ibuffer +icons)
 (undo +tree)
 
 :term
 ghostel
 
 :checkers
 (syntax +flymake)
 (spell +flyspell)
 grammar
 :tools
 
 (eval +overlay)
 (lookup +docsets)
 lsp
 (magit +forge)
 tree-sitter

 :lang
 sh
 docker
 json
 markdown
 (nix +tree-sitter +lsp)
 toml
 yaml
 (lua +lsp +tree-sitter)
 (python +lsp +tree-sitter)
 (emacs-lisp +lsp +tree-sitter)
 (org +dragndrop +hugo +pandoc +pomodoro +present +pretty +capture +journal)

 :config
 (default +bindings +smartparens))
