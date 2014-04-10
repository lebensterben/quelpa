(unless (require 'quelpa nil t)
  (load (concat quelpa-ci-dir "/bootstrap.el"))
  (require 'quelpa))

(require 'ert nil t)

(defmacro quelpa-deftest (name arglist &optional docstring &rest body)
  "Add `quelpa-setup-p' as initial test to the given test body."
  (declare (doc-string 3) (indent 2))
  (let ((args (when docstring (list name docstring) (list name))))
    `(ert-deftest ,@args ()
       (should (equal t (quelpa-setup-p)))
       ,@body)))

(quelpa-deftest quelpa-expand-recipe-test ()
  "Should be expanding correctly as return value and into buffer."
  (let ((package-build-rcp '(package-build :repo "milkypostman/melpa" :fetcher github :files ("package-build.el" "json-fix.el"))))
    (should
     (equal
      (quelpa-expand-recipe 'package-build)
      package-build-rcp))
    (should
     (equal
      (with-temp-buffer
        (cl-letf (((symbol-function 'quelpa-interactive-candidate)
                   (lambda ()
                     (interactive)
                     'package-build)))
          (call-interactively 'quelpa-expand-recipe))
        (buffer-string))
      (prin1-to-string package-build-rcp)))))

(quelpa-deftest quelpa-arg-rcp-test ()
  "Ensure `quelpa-arg-rcp' always returns the correct RCP format."
  (let ((quelpa-rcp '(quelpa :repo "quelpa/quelpa" :fetcher github))
        (package-build-rcp '(package-build :repo "milkypostman/melpa" :fetcher github :files ("package-build.el" "json-fix.el"))))
    (should
     (equal
      (quelpa-arg-rcp quelpa-rcp)
      quelpa-rcp))
    (should
     (equal
      (quelpa-arg-rcp 'package-build)
      package-build-rcp))
    (should
     (equal
      (quelpa-arg-rcp '(package-build))
      package-build-rcp))))

(quelpa-deftest quelpa-version>-p-test ()
  "Passed version should correctly tested against `package-alist'
and built-in packages."
  (let ((package-alist (if (functionp 'package-desc-vers)
                           ;; old package-alist format
                           '((quelpa . [(20140406 1613)
                                        ((package-build
                                          (0)))
                                        "Emacs Lisp packages built directly from source"]))
                         ;; new package-alist format
                         '((quelpa
                            [cl-struct-package-desc
                             quelpa
                             (20140406 1613)
                             "Emacs Lisp packages built directly from source"
                             ((package-build (0))) nil nil "test" nil nil])))))
    (should-not (quelpa-version>-p 'quelpa "0"))
    (should-not (quelpa-version>-p 'quelpa "20140406.1613"))
    (should (quelpa-version>-p 'quelpa "20140406.1614"))
    (cl-letf (((symbol-function 'package-built-in-p)
               (lambda (name version) (version-list-<= version '(20140406 1613)))))
      (should-not (quelpa-version>-p 'foobar "0"))
      (should-not (quelpa-version>-p 'foobar "20140406.1613"))
      (should (quelpa-version>-p 'foobar "20140406.1614")))))
