;;; recover-buffers-tramp.el --- extra Tramp features for `recover-buffers'
;;
;;; Commentary:
;;
;; In order to improve the user experience of `recover-buffers' when
;; there are multiple remote Tramp files in the set of files to
;; revisit, preemptively prompt for the password for each remote
;; server before starting the actual recovery.
;;
;; The accompanying file 50recover-buffers-tramp.el contains a simple
;; set of autoloads to hook this into recover-buffers if you have
;; Tramp available on your system.
;;
;; The default behavior without password.el (included with Gnus) is
;; less than ideal.  If you have some other sort of secure password
;; caching, you should probably use that instead.  Better yet, use an
;; external password agent like ssh-agent or Pageant for Putty.  Then
;; you will need none of this nonsense.
;;
;;
;; License: dual GPL v2 / BSD without advertising clause
;;
;; Author: era eriksson <http://www.iki.fi/era>
;;
;;
;;; History:
;;
;; era Sat Feb  5 21:09:36 EET 2011 -- first public version
;;
;; See the version control logs for detailed history.
;;
;; http://porkmail.org/elisp/recover-buffers/

;;; Code:

(require 'recover-buffers)
(eval-when-compile
  (require 'tramp)
  ;; If password.el is unavailable, there will be a compilation warning below
  (require 'password nil 'noerror) )


(defcustom recover-buffers-tramp-password-prefetch-function
  (and (locate-library "tramp")
       (if (locate-library "password")
	   #'recover-buffers-tramp-password-prefetch-cached
	 #'recover-buffers-tramp-password-prefetch-dummy-file) )
  "Function to run from `recover-buffers-tramp-password-prefetch'.

The function is invoked with three string arguments, METHOD USER HOST.
See `tramp-file-name-structure' for the meaning of these fields in a Tramp
file name."
  :type '(function)
  :group 'recover-buffers)

(defvar recover-buffers-tramp-dummy-buffers nil
  "Temporary variable for `recover-buffers-tramp-password-prefetch-dummy-file'.
The buffers listed will be removed by `recover-buffers-tramp-password-cleanup',
assuming the function is properly hooked in via `recover-buffers-after-hook'.")


(defmacro prepend (value list) "Prepend VALUE to the front of LIST."
  `(setq ,list (cons ,value ,list)) )

(defsubst mapcar-unique (function list)
  "Apply FUNCTION to each element in LIST, returning a list of unique results.
That is, if several calls to FUNCTION return the same result, only one instance
of the result will be returned.

If there were any nil results, the first element of the returned list will be
nil.  This makes it easy to obtain only non-nil unique results."
  (let (i nilp cache result)
    (while list
      (setq i (apply function (list (car list)))
	    list (cdr list) )
      (if i (or (assoc i cache)
		(prepend (cons i nil) cache) )
	(setq nilp t) )	)
    (setq result (mapcar #'car cache))
    (if nilp (cons nil result)) result) )
(defsubst mapcar-unique-non-nil (function list)
  (let ((result (mapcar-unique function list)))
    (if (null (car result)) (cdr result)
      result) ) )

;;;###autoload
(defun recover-buffers-tramp-password-prefetch ()
  "Find remote hosts from `recover-buffers-list' and get password for each.

This is intended as a hook function to add to `recover-buffers-before-hook'
in order to improve the user experience when there are many files to recover
on different remote hosts.  Because Tramp is relatively verbose and somewhat
sensitive to timing issues, the remote password prompt may be lost if all
remote files are visited in batch.  Thus this is done interactively instead.

The variable `recover-buffers-tramp-password-prefetch-function' controls
which function will be run on each remote host."
  (mapc (function (lambda (triplet)
	       (apply recover-buffers-tramp-password-prefetch-function
		      triplet) ) )
	(mapcar-unique-non-nil
	 (function (lambda (file)
		     (and (tramp-tramp-file-p file)
			  (let ((f (tramp-dissect-file-name file)))
			    (list
			     (tramp-file-name-method f)
			     (tramp-file-name-user f)
			     (tramp-file-name-host f) ) )) ))
	 recover-buffers-list) ) )
 

(defun recover-buffers-tramp-password-prefetch-dummy-file (method user host)
  "Visit a dummy buffer using METHOD as USER on HOST, using Tramp.
This is intended to cause Tramp to prompt for a password (if necessary)
and otherwise set up the connection to the remote host.

The created dummy buffer is added to `recover-buffer-tramp-dummy-buffers',
which will be removed from `recover-buffers-tramp-password-cleanup'."
  (add-hook 'recover-buffers-after-hook
	    #'recover-buffers-tramp-password-cleanup)
  ;; Creating a temporary buffer which will never have any contents
  ;; and hopefully never seen by the user -- the security implications
  ;; mentioned in the documentation for `make-temp-name' are IMHO
  ;; acceptable in this scenario
  ;;;;;;;; FIXME: might break if remote is Windows and local is Unix, or v.v.
  (let ((b (find-file (concat "/" method ":" user "@" host ":"
			      (make-temp-name "tramp-recover") )) ))
    (prepend b recover-buffers-tramp-dummy-buffers)
    (bury-buffer b) ) )

(defun recover-buffers-tramp-password-cleanup ()
  "Kill all buffers listed in `recover-buffers-tramp-dummy-buffers'.
Intended to be invoked from `recover-buffers-after-hook' if using Tramp
password prefetching via `recover-buffers-tramp-password-prefetch'."
  (when recover-buffers-tramp-dummy-buffers
    (mapc #'kill-buffer recover-buffers-tramp-dummy-buffers) )
  (setq recover-buffers-tramp-dummy-buffers nil) )


(defun recover-buffers-tramp-password-prefetch-cached (method user host)
  "Read and `password-cache-add' Tramp password for METHOD USER HOST triplet
using `password-read' (which actually does not use METHOD)."
  (require 'password)
  (let ((key (concat user "@" host)))
    (password-cache-add key
			(password-read (format "Password for %s: " key)
				       key) ) ) )


(provide 'recover-buffers-tramp)


;;; recover-buffers-tramp.el ends here
