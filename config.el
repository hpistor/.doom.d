;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Hans Pistor"
      user-mail-address "hpistor@fastmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
(setq doom-font (font-spec :family "monospace" :size 14))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

(setq-default evil-escape-key-sequence "fd")

(direnv-mode)

(setq rustic-format-trigger 'on-save)

(defun cargo-xcommand (command)
  "Run cargo x command."
  (rustic-compilation-process-live)
  (rustic-compilation-start (split-string command))
  )

(defun cargo-xbuild ()
  "Run xbuild with cargo."
  (interactive)
  (cargo-xcommand "cargo xbuild")
)

(defun cargo-xrun()
  "Run xrun with cargo."
  (interactive)
  (cargo-xcommand "cargo xrun")
)

(defun cargo-xtest()
  "Run xrun with cargo."
  (interactive)
  (cargo-xcommand "cargo xtest")
)


(map! "C-c C-b" #'cargo-xbuild
      "C-c C-r" #'cargo-xrun
      "C-c C-t" #'cargo-xtest
      )

(add-to-list 'load-path "usr/share/emacs/site-lisp/mu4e")

(setq
 mu4e-maildir "~/Maildir"
 )

(setq mu4e-headers-date-format "%Y-%m-%d %H:%M")
(setq mu4e-get-mail-command "offlineimap")


(setq message-send-mail-function 'smtpmail-send-it)
(setq smtpmail-smtp-server "smtp.fastmail.com")
(setq smtpmail-stream-type 'starttls)
(setq smtpmail-smtp-service 587)

(after! org
  (setq
   org-todo-keywords '((sequence "TODO(t)" "INPROGRESS(i)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)"))
   org-todo-keyword-faces '(
                            ("TODO" :foreground "#7c7c75" :weight normal :underline t)
                            ("INPROGRESS" :foreground "#9f7efe" :weight normal :underline t)
                            ("WAITING" :foreground "#0098dd" :weight normal :underline t)
                            ("DONE" :foreground "#50a14f" :weight normal :underline t)
                            ("CANCELLED" :foreground "#ff6480" :weight normal :underline t)
                            )
   )
  )

(setq org-log-done 'time)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; (require 'ox-gfm)                                                             ;;
;;                                                                               ;;
;; (defun org-gfm-publish-to-md (plist filename pub-dir)                         ;;
;;   (org-publish-org-to 'gfm filename ".md" plist pub-dir)                      ;;
;;   )                                                                           ;;
;;                                                                               ;;
;; (setq org-publish-project-alist                                               ;;
;;       '(                                                                      ;;
;;         ("blog-notes"                                                         ;;
;;          :base-directory "~/Documents/braindump/org/"                         ;;
;;          :base-extensoin "org"                                                ;;
;;          :publishing-directory "~/Documents/braindump/content/"               ;;
;;          :recursive t                                                         ;;
;;          :publishing-function org-gfm-publish-to-md                           ;;
;;          :headline-levels 4                                                   ;;
;;          :auto-preamble t                                                     ;;
;;          )                                                                    ;;
;;         ("blog-static"                                                        ;;
;;          :base-directory "~/Documents/braindump/org/images/"                  ;;
;;          :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|mp3\\|ogg\\|swf" ;;
;;          :publishing-directory "~/Documents/braindump/static/images/"         ;;
;;          :recursive t                                                         ;;
;;          :publishing-function org-publish-attachment                          ;;
;;          )                                                                    ;;
;;         ("blog" :components ("blog-notes" "blog-static"))                     ;;
;;         ))                                                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq geiser-active-implementations '(racket))
(setq geiser-default-implementation 'racket)

(use-package! org-roam
  :commands (org-roam-insert org-roam-find-file org-roam)
  :init
  (setq org-roam-directory "~/Documents/hpistor.github.io/org/")
  (map! :leader
        :prefix "n"
        :desc "Org-Roam-Insert" "i" #'org-roam-insert
        :desc "Org-Roam-Find"   "/" #'org-roam-find-file
        :desc "Org-Roam-Buffer" "r" #'org-roam)
  :config
  (org-roam-mode +1))

(map! :map org-mode-map :g "C-c C-b" #'org-mark-ring-goto)

(after! (company org-roam)
  (set-company-backend! 'org-mode
    '(company-org-roam :with company-dabbrev :with company-yasnippet)))

(after! (org org-roam)
    (defun my/org-roam--backlinks-list (file)
      (if (org-roam--org-roam-file-p file)
          (--reduce-from
           (concat acc (format "- [[file:%s][%s]]\n"
                               (file-relative-name (car it) org-roam-directory)
                               (org-roam--get-title-or-slug (car it))))
           "" (org-roam-sql [:select [file-from]
                             :from file-links
                             :where (= file-to $s1)
                             :and file-from :not :like $s2] file "%private%"))
        ""))
    (defun my/org-export-preprocessor (_backend)
      (let ((links (my/org-roam--backlinks-list (buffer-file-name))))
        (unless (string= links "")
          (save-excursion
            (goto-char (point-max))
            (insert (concat "\n* Backlinks\n" links))))))
    (add-hook 'org-export-before-processing-hook 'my/org-export-preprocessor))

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c g k').
;; This will open documentation for it, including demos of how they are used.

;; You can also try 'gd' (or 'C-c g d') to jump to their definition and see how
;; they are implemented.
