(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-agenda-files '("/home/alice/Documents/org-docs/")))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(font-lock-comment-face ((t (:slant italic))))
 '(font-lock-keyword-face ((t (:slant italic)))))

 ;; insert wakatime-api-key from sops file
(setq! wakatime-api-key
   (shell-command-to-string "cat /home/alice/.config/doom/wakatime"))

(setq! lsp-enable-suggest-server-download nil)

;; (keychain-refresh-environment)
