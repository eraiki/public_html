;;; 50recover-buffers-tramp.el --- load extra Tramp features for recover-buffers
;; era Thu May 27 09:10:56 EEST 2010

(eval-when-compile
  (require 'recover-buffers-tramp) )

(when (locate-library "tramp")

  (autoload 'recover-buffers-tramp-password-prefetch "recover-buffers-tramp")

  (add-hook 'recover-buffers-before-hook
	    #'recover-buffers-tramp-password-prefetch)
  (custom-add-option 'recover-buffers-before-hook
		     #'recover-buffers-tramp-password-prefetch)

  (add-hook 'recover-buffers-after-hook
	    #'recover-buffers-tramp-password-cleanup)
  (custom-add-option 'recover-buffers-after-hook
		     #'recover-buffers-tramp-password-cleanup) )

;;; 50recover-buffers-tramp.el ends here
