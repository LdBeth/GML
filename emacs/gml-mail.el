;;; gml-mail.el --- Write e-mail as GML memos, send it with Wanderlust  -*- lexical-binding: t; -*-

;; Keywords: mail, wp
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1

;;; Commentary:

;; A mail message written as a GML memo (the `memo' tag set,
;; share/gmlapp/memo) becomes a Wanderlust draft whose body is HTML:
;;
;;   multipart/alternative
;;     text/plain                made here from the HTML with shr
;;     multipart/related         when the memo has images (:logo)
;;       text/html
;;       image/...               Content-ID, inline
;;   attachments                 (:attach), after the alternative
;;
;; The memo is run through `gmlfmt -app memo -to mail', which writes
;; one line of JSON (the header fields, the inline images and the
;; attachments) followed by the HTML; the body is written into the draft
;; in SEMI's mime-edit tags, which Wanderlust translates when it sends
;; or saves the draft.  The HTML part goes in already base64-encoded
;; (hidden, like any binary part in mime-edit) so that nothing in the
;; draft buffer can change it; see `gml-mail-encode-html'.
;;
;; Commands, in a memo buffer (`gml-mail-mode'):
;;  - C-c , c  `gml-mail-compose': a new draft with the memo's header
;;    fields and body;
;;  - C-c , e  `gml-mail-export': the memo's body into an existing
;;    draft (a reply, say), replacing the draft's body; with C-u, the
;;    memo's Subject, To, Cc and Bcc replace the draft's too;
;;  - C-c , d  `gml-mail-select-draft': choose the draft to export to;
;;  - C-c , v  `gml-mail-preview': the memo's HTML in a browser.
;; In a Wanderlust draft:
;;  - `gml-mail-memo-from-draft': a memo with the draft's To, Cc and
;;    Subject, and its citation as long quotations; exporting the memo
;;    replaces the draft's body.
;;
;; Setup:
;;   (add-to-list 'load-path "/path/to/GML/emacs")
;;   (autoload 'gml-mail-maybe-enable "gml-mail")
;;   (autoload 'gml-mail-memo-from-draft "gml-mail" nil t)
;;   (add-hook 'gml-mode-hook #'gml-mail-maybe-enable)
;;   (setq gml-root "/path/to/GML")   ; for memos outside the project
;;   (with-eval-after-load 'wl-draft
;;     (define-key wl-draft-mode-map (kbd "C-c , m") #'gml-mail-memo-from-draft))

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'seq)
(require 'dom)
(require 'shr)
(require 'mail-parse)
(require 'mail-utils)
(require 'rfc2047)
(require 'compile)
(require 'url-util)
(require 'gml-mode)

;; Wanderlust, SEMI, FLIM and APEL are loaded when a command needs them.
(declare-function wl-draft "wl-draft"
                  (&optional header-alist content-type content-transfer-encoding
                             body edit-again parent-folder parent-number))
(declare-function mime-find-file-type "mime-edit" (file))
(declare-function mime-edit-insert-file-parameters "mime-edit"
                  (parameters file &optional verbose))
(declare-function mime-create-tag "mime-edit" (contype &optional encoding))
(declare-function mime-insert-encoded-file "mel" (filename encoding))
(declare-function invisible-region "invisible" (start end))
(defvar mime-auto-hide-body)
(defvar mime-edit-tag-regexp)
(defvar mime-edit-quoted-single-part-tag-regexp)
(defvar wl-mail-setup-hook)
(defvar mail-header-separator)

(defgroup gml-mail nil
  "Writing e-mail as GML memos, sent with Wanderlust."
  :group 'gml
  :prefix "gml-mail-")

;;;; Customisation

(defcustom gml-mail-app "memo"
  "The tag set of memos: passed to gmlfmt as -app."
  :type 'string)

(defcustom gml-mail-alternative t
  "Non-nil: the message has a text/plain alternative of the HTML.
It is made from the HTML with shr, `gml-mail-text-width' wide."
  :type 'boolean)

(defcustom gml-mail-text-width 72
  "Width of the lines of the text/plain alternative."
  :type 'natnum)

(defcustom gml-mail-encode-html t
  "Non-nil: the HTML part goes into the draft base64-encoded.
It is then hidden (when `mime-auto-hide-body' is non-nil) and
nothing done in the draft buffer can change it.  When nil it goes in
as text and mime-edit encodes it (quoted-printable) when the draft is
sent; it is encoded here anyway if it contains something mime-edit
would take for one of its tags."
  :type 'boolean)

(defcustom gml-mail-export-headers nil
  "Header fields that `gml-mail-export' sets in the draft from the memo.
nil: the draft's own header fields are kept (a reply's are right);
with a prefix argument the export sets Subject, To, Cc and Bcc."
  :type '(set (const "Subject") (const "To") (const "Cc") (const "Bcc")))

(defcustom gml-mail-directory (locate-user-emacs-file "gml-mail/")
  "Directory of the memos that `gml-mail-memo-from-draft' makes.
A memo is a file there (made when it is first saved); file names in
its :attach and :logo tags are relative to it."
  :type 'directory)

(defcustom gml-mail-citation-regexp "[ \t]*[>|]"
  "Regexp for one level of citation at the start of a line of a draft.
`gml-mail-memo-from-draft' makes a long quotation of the lines that
begin with it, nested once for each repetition."
  :type 'regexp)

;;;; Memo tags

(defconst gml-mail-tags
  '(("logo" line "the logo: an image file shown in the memo" "logoname")
    ("to" line "a receiver: the To field (one tag each)"
     "name email company addr1 addr2")
    ("from" line "the sender: the From field"
     "name email title dept phone addr1 addr2")
    ("cc" line "a copy: the Cc field (one tag each)" "name email addr1 addr2")
    ("bcc" line "a blind copy: the Bcc field only" "name email")
    ("attach" line "a file sent with the message" "name")
    ("memodate" text "date of the memo (one line)")
    ("security" text "security classification (one line)")
    ("subject" text "subject: the Subject field (one line)")
    ("ref" text "reference (one line)")
    ("memotxt" line "the text of the memo follows" "memtype")
    ("sign" text "the signature: ends the text (one line)")
    ("link" inline "a hypertext link" "href"))
  "The memo tags, in the format of `gml-starter-tags'.")

(defconst gml-mail--eol-tags '("memodate" "security" "subject" "ref" "sign")
  "Memo tags that take the rest of their line.")

;;;; Running gmlfmt

(defun gml-mail--directory ()
  "Directory of the memo: of its file, else `default-directory'."
  (file-name-as-directory
   (expand-file-name (if buffer-file-name (file-name-directory buffer-file-name)
                       default-directory))))

(add-to-list 'compilation-error-regexp-alist-alist
             '(gml-mail
               "^\\([^ :\n]+\\):\\([0-9]+\\)\\(?: ([^)\n]*)\\)?: \\+\\+\\+[A-Z]+[0-9]+\\(?:\\(W\\)\\|\\(I\\)\\|[A-Z]\\)\\_>"
               1 2 nil (3 . 4)))

(define-derived-mode gml-mail-diagnostics-mode compilation-mode "GML-Mail"
  "Diagnostics of gmlfmt for a memo; RET or \\[next-error] visits them."
  (setq-local compilation-error-regexp-alist '(gml gml-mail)))

(defconst gml-mail--diagnostics-buffer "*gml-mail*"
  "Name of the buffer of gmlfmt's diagnostics.")

(defun gml-mail--show-diagnostics (to status text dir)
  "Show TEXT, the diagnostics of gmlfmt -to TO that ended with STATUS.
File names in it are relative to DIR."
  (let ((buf (get-buffer-create gml-mail--diagnostics-buffer)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (setq default-directory dir)
        (insert text)
        (unless (bolp) (insert "\n"))
        (insert (format "\ngmlfmt -app %s -to %s exited with status %s\n"
                        gml-mail-app to status)))
      (gml-mail-diagnostics-mode)
      (goto-char (point-min)))
    (display-buffer buf)))

(defun gml-mail--run (to)
  "Run gmlfmt -app memo -to TO on the current buffer; return its output.
The buffer's contents are used, saved or not: if it is modified (or
visits no file) they are written to a temporary file, and the
directory of the memo is passed with -I.  Diagnostics are shown in
the buffer `gml-mail--diagnostics-buffer'.  Exit status 0 and 4 give
the output, 8 (errors) gives it if the user agrees; any other status
is an error."
  (let* ((dir (gml-mail--directory))
         (direct (and buffer-file-name (not (buffer-modified-p))
                      (file-regular-p buffer-file-name)))
         (shown (or buffer-file-name (buffer-name)))
         (program (gml--gmlfmt))
         (env (gml--gmlfmt-environment))
         (input (if direct (expand-file-name buffer-file-name)
                  (make-temp-file "gml-mail" nil ".gml")))
         (errfile (make-temp-file "gml-mail" nil ".err"))
         (args (append (list "-app" gml-mail-app "-to" to)
                       (gml--set-args)
                       (list "-I" dir input)))
         status out diag)
    (unwind-protect
        (progn
          (unless direct
            (save-restriction
              (widen)
              (let ((coding-system-for-write 'utf-8-unix))
                (write-region nil nil input nil 'silent))))
          (with-temp-buffer
            (let ((default-directory dir)
                  (process-environment env)
                  (coding-system-for-read 'utf-8))
              (setq status
                    (condition-case err
                        (apply #'call-process program nil (list t errfile) nil args)
                      (file-error
                       (user-error "Cannot run %s: %s" program
                                   (error-message-string err))))))
            (setq out (buffer-string)))
          (setq diag (with-temp-buffer
                       (let ((coding-system-for-read 'utf-8))
                         (insert-file-contents errfile))
                       (buffer-string)))
          (unless direct
            (setq diag (string-replace input shown diag))))
      (unless direct (delete-file input))
      (delete-file errfile))
    (let ((usable (and (memq status '(0 4 8)) (not (string-empty-p out)))))
      (when (or (not (eql status 0)) (not (string-blank-p diag)))
        (gml-mail--show-diagnostics to status diag dir))
      (cond
       ((not usable)
        (user-error "gmlfmt -to %s gave no output (status %s); see %s"
                    to status gml-mail--diagnostics-buffer))
       ((and (eql status 8)
             (not (y-or-n-p "gmlfmt found errors in the memo; use its output anyway? ")))
        (user-error "Cancelled; the errors are in %s" gml-mail--diagnostics-buffer))
       ((eql status 4)
        (message "gmlfmt: warnings, see %s" gml-mail--diagnostics-buffer))))
    out))

;;;; The output of -to mail

(defun gml-mail--parse-output (output dir)
  "Parse OUTPUT of gmlfmt -to mail: a JSON line, then the HTML.
File names are made absolute against DIR.  Return a plist:
 :headers      alist of (FIELD . VALUE), strings, as the memo gives them
 :inline       list of (CID . FILE)
 :attachments  list of FILE
 :html         the HTML document."
  (let* ((nl (or (string-search "\n" output)
                 (user-error "The output of gmlfmt is not a mail description")))
         (json (condition-case nil
                   (json-parse-string (substring output 0 nl)
                                      :object-type 'alist :array-type 'list
                                      :null-object nil :false-object nil)
                 (json-error
                  (user-error "The first line of gmlfmt's output is not JSON"))))
         (html (substring output (1+ nl))))
    (unless (let ((case-fold-search t))
              (string-match-p "\\`[ \t\r\n]*<!DOCTYPE html" html))
      (user-error "The output of gmlfmt has no HTML after the JSON line"))
    (list :headers (mapcar (lambda (h) (cons (symbol-name (car h)) (cdr h)))
                           (alist-get 'headers json))
          :inline (mapcar (lambda (i)
                            (cons (alist-get 'cid i)
                                  (expand-file-name (alist-get 'file i) dir)))
                          (alist-get 'inline json))
          :attachments (mapcar (lambda (a) (expand-file-name (alist-get 'file a) dir))
                               (alist-get 'attachments json))
          :html html)))

(defun gml-mail--check-files (msg)
  "Signal a `user-error' if a file of message MSG cannot be read."
  (let ((missing (seq-remove (lambda (f) (and (file-regular-p f) (file-readable-p f)))
                             (append (mapcar #'cdr (plist-get msg :inline))
                                     (plist-get msg :attachments)))))
    (when missing
      (user-error "Cannot read %s: %s"
                  (if (cdr missing) "these files" "this file")
                  (mapconcat #'abbreviate-file-name missing ", ")))))

;;;; The text/plain alternative

(defun gml-mail--dom-text (node)
  "The text of the DOM NODE."
  (if (stringp node) node (mapconcat #'gml-mail--dom-text (dom-children node) "")))

(defun gml-mail--text-dom (node)
  "NODE of an HTML DOM made ready for the text alternative.
The head goes, images become their alt text (or nothing), and
links are followed by their URL when the text does not show it."
  (if (stringp node)
      node
    (pcase (dom-tag node)
      ((or 'head 'script 'style 'title) nil)
      ('img (let ((alt (string-trim (or (dom-attr node 'alt) ""))))
              (and (not (string-empty-p alt)) (format "[%s]" alt))))
      (tag
       (let ((children (delq nil (mapcar #'gml-mail--text-dom (dom-children node))))
             (href (and (eq tag 'a) (dom-attr node 'href))))
         (when (and href (not (string-prefix-p "#" href)))
           (let ((url (string-remove-prefix "mailto:" href))
                 (text (string-trim (gml-mail--dom-text node))))
             (unless (member text (list href url))
               (setq children (append children (list (format " <%s>" url)))))))
         `(,tag ,(dom-attributes node) ,@children))))))

(defun gml-mail--shr-blockquote (dom)
  "Render the blockquote DOM, its lines marked for `gml-mail--quote-lines'.
Each level indents by 2, the width of the `> ' that replaces it."
  (let ((start (point))
        (shr-block-indentation-pixel-width 2))
    (shr-tag-blockquote dom)
    (let ((pos start) (end (point)))
      (while (< pos end)
        (let ((next (next-single-property-change pos 'gml-mail-depth nil end)))
          (put-text-property pos next 'gml-mail-depth
                             (1+ (or (get-text-property pos 'gml-mail-depth) 0)))
          (setq pos next))))))

(defun gml-mail--quote-lines ()
  "Prefix the lines of quotations in the buffer with `> ' for each level."
  (let (depths)
    (goto-char (point-min))
    (while (not (eobp))
      (push (save-excursion
              (skip-chars-forward " \t" (line-end-position))
              (and (not (eolp)) (or (get-text-property (point) 'gml-mail-depth) 0)))
            depths)
      (forward-line 1))
    (setq depths (vconcat (nreverse depths)))
    ;; a blank line is in a quotation as deep as the lines around it
    (let ((n (length depths)))
      (dotimes (i n)
        (unless (aref depths i)
          (let ((prev (cl-loop for j downfrom (1- i) to 0
                               thereis (and (numberp (aref depths j)) (aref depths j))))
                (next (cl-loop for j from (1+ i) below n
                               thereis (and (numberp (aref depths j)) (aref depths j)))))
            (aset depths i (list (min (or prev 0) (or next 0))))))))
    (goto-char (point-min))
    (seq-doseq (d depths)
      (let* ((blank (consp d)) (d (if blank (car d) d)))
        (when (> d 0)
          ;; the indentation shr made (not that of a <pre> line)
          (let ((n (min (* 2 d) (or (get-text-property (point) 'shr-prefix-length) 0))))
            (while (and (> n 0) (eq (char-after) ?\s))
              (delete-char 1)
              (cl-decf n)))
          (let ((prefix (apply #'concat (make-list d "> "))))
            (insert (if blank (string-trim-right prefix) prefix)))))
      (forward-line 1))))

(defun gml-mail--html-to-text (html)
  "The text of HTML for the text/plain alternative, as a string.
Lines are `gml-mail-text-width' wide; no images, no faces; links show
their URL; quotations are prefixed with `> '."
  (unless (and (fboundp 'libxml-available-p) (libxml-available-p))
    (user-error "Making the text alternative needs Emacs with libxml2"))
  (with-temp-buffer
    (insert html)
    (let ((dom (gml-mail--text-dom
                (libxml-parse-html-region (point-min) (point-max)))))
      (erase-buffer)
      (let ((shr-width gml-mail-text-width)
            (shr-max-width nil)
            (shr-use-fonts nil)
            (shr-use-colors nil)
            (shr-inhibit-images t)
            (shr-external-rendering-functions
             (cons (cons 'blockquote #'gml-mail--shr-blockquote)
                   shr-external-rendering-functions)))
        (shr-insert-document dom)))
    (gml-mail--quote-lines)
    (let ((delete-trailing-lines t))
      (delete-trailing-whitespace (point-min) nil))
    (goto-char (point-min))
    (skip-chars-forward "\n")
    (delete-region (point-min) (point))
    (goto-char (point-max))
    (unless (bolp) (insert "\n"))
    (buffer-substring-no-properties (point-min) (point-max))))

;;;; The body in mime-edit tags

(defconst gml-mail--related "related; type=\"text/html\""
  "The multipart tag of the HTML with its images (RFC 2387 wants type=).")

(defun gml-mail--require-semi ()
  "Load SEMI's mime-edit, or signal a `user-error'."
  (unless (require 'mime-edit nil t)
    (user-error "gml-mail needs SEMI (mime-edit), which is not installed")))

(defun gml-mail--tag-like-p (text)
  "Non-nil if TEXT contains something mime-edit takes for a tag."
  (or (string-match-p mime-edit-tag-regexp text)
      (string-match-p mime-edit-quoted-single-part-tag-regexp text)))

(defun gml-mail--insert-encoded (contype encoding inserter)
  "Insert a part of CONTYPE whose content INSERTER inserts, ENCODING encoded.
The content is hidden as mime-edit hides it, unless it is 7bit,
8bit or binary."
  (insert (mime-create-tag contype encoding) "\n")
  (let ((tagend (1- (point))))
    (funcall inserter)
    (unless (bolp) (insert "\n"))
    (when (and mime-auto-hide-body
               (not (member (downcase encoding) '("7bit" "8bit" "binary"))))
      (invisible-region tagend (point)))))

(defun gml-mail--insert-text-part (subtype text encode)
  "Insert TEXT as a text/SUBTYPE part in UTF-8.
With ENCODE, or if TEXT looks like a mime-edit tag, it goes in
base64-encoded; else as text, which mime-edit encodes when sending."
  (let ((text (if (string-suffix-p "\n" text) text (concat text "\n")))
        (contype (concat "text/" subtype "; charset=utf-8")))
    (if (or encode (gml-mail--tag-like-p text))
        (gml-mail--insert-encoded
         contype "base64"
         (lambda () (insert (base64-encode-string
                             (encode-coding-string text 'utf-8-unix)))))
      (insert (mime-create-tag contype) "\n" text))))

(defun gml-mail--file-tag-like-p (file)
  "Non-nil if the contents of FILE look like a mime-edit tag."
  (with-temp-buffer
    (insert-file-contents-literally file)
    (gml-mail--tag-like-p (buffer-string))))

(defun gml-mail--insert-file-part (file disposition &optional cid)
  "Insert FILE as a part with DISPOSITION (\"inline\" or \"attachment\").
The type and encoding are guessed by `mime-find-file-type' (base64
when it has none, as mime-edit does); CID, if non-nil, is the
part's Content-ID."
  (let* ((guess (mime-find-file-type file))
         (params (nth 2 guess))
         (encoding (or (nth 3 guess) "base64"))
         (dparams (or (nth 5 guess) '(("filename" . file)))))
    (when (and (member (downcase encoding) '("7bit" "8bit" "binary"))
               (gml-mail--file-tag-like-p file))
      (setq encoding "base64"))
    (gml-mail--insert-encoded
     (concat (or (nth 0 guess) "application") "/" (or (nth 1 guess) "octet-stream")
             (and (consp params) (mime-edit-insert-file-parameters params file))
             "\nContent-Disposition: " disposition
             (mime-edit-insert-file-parameters dparams file)
             (and cid (format "\nContent-ID: <%s>" cid)))
     encoding
     (lambda () (mime-insert-encoded-file file encoding)))))

(defun gml-mail--mime-body (msg)
  "The body of message MSG (see `gml-mail--parse-output') in mime-edit tags.
A string, with the encoded parts hidden by text properties."
  (gml-mail--require-semi)
  (let* ((html (plist-get msg :html))
         (text (and gml-mail-alternative (gml-mail--html-to-text html)))
         (inline (plist-get msg :inline)))
    (with-temp-buffer
      (when text
        (insert "--<<alternative>>-{\n")
        (gml-mail--insert-text-part "plain" text nil))
      (when inline
        (insert "--<<" gml-mail--related ">>-{\n"))
      (gml-mail--insert-text-part "html" html gml-mail-encode-html)
      (dolist (i inline)
        (gml-mail--insert-file-part (cdr i) "inline" (car i)))
      (when inline
        (insert "--}-<<" gml-mail--related ">>\n"))
      (when text
        (insert "--}-<<alternative>>\n"))
      (dolist (f (plist-get msg :attachments))
        (gml-mail--insert-file-part f "attachment"))
      (buffer-string))))

(defun gml-mail--message ()
  "The message of the memo in the current buffer, as a plist.
That of `gml-mail--parse-output', plus :body, the body in mime-edit
tags.  Errors (gmlfmt's, missing files) are signalled here, before
any draft is touched."
  (let ((msg (gml-mail--parse-output (gml-mail--run "mail") (gml-mail--directory))))
    (gml-mail--check-files msg)
    (plist-put msg :body (gml-mail--mime-body msg))))

;;;; Drafts

(defvar-local gml-mail--state nil
  "In a draft: what gml-mail put into its body, a plist.
 :beg :end  markers around the body of the last export
 :text      the text between them then
 :outside   the body's text before and after them then (a list of two)
 :consumed  the body when a memo was made from the draft.")
(put 'gml-mail--state 'permanent-local t)

(defvar-local gml-mail--memo nil
  "In a draft: the memo buffer made from it or exported into it.")
(put 'gml-mail--memo 'permanent-local t)

(defvar-local gml-mail--draft nil
  "In a memo: the draft buffer it is exported into.")
(put 'gml-mail--draft 'permanent-local t)

(defun gml-mail--require-wl ()
  "Load Wanderlust's draft library, or signal a `user-error'."
  (unless (and (require 'mime-edit nil t) (require 'wl-draft nil t))
    (user-error "gml-mail needs Wanderlust (with SEMI, FLIM and APEL), which is not installed")))

(defun gml-mail--draft-p (buffer)
  "Non-nil if BUFFER is a live Wanderlust draft that is being edited."
  (and (buffer-live-p buffer)
       (not (string-prefix-p " " (buffer-name buffer)))
       (eq (buffer-local-value 'major-mode buffer) 'wl-draft-mode)))

(defun gml-mail--header-end ()
  "Position of the header separator line of the current draft."
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward (concat "^" (regexp-quote mail-header-separator) "$") nil t)
        (match-beginning 0)
      (error "No header separator in %s" (buffer-name)))))

(defun gml-mail--body-start ()
  "Position of the start of the body of the current draft."
  (save-excursion
    (goto-char (gml-mail--header-end))
    (forward-line 1)
    (point)))

(defun gml-mail--field (name)
  "The header field NAME of the current draft (all of them, joined), or nil."
  (save-excursion
    (save-restriction
      (narrow-to-region (point-min) (gml-mail--header-end))
      (let ((v (mail-fetch-field name nil t)))
        (and v (not (string-blank-p v)) (string-trim v))))))

(defun gml-mail--set-field (name value &optional append)
  "Set header field NAME of the current draft to VALUE.
Every NAME field goes; with APPEND their values come first, joined
with VALUE by commas."
  (save-excursion
    (save-restriction
      (narrow-to-region (point-min) (gml-mail--header-end))
      (goto-char (point-min))
      (let ((case-fold-search t)
            (re (concat "^" (regexp-quote name) ":[ \t]*"))
            old at)
        (while (re-search-forward re nil t)
          (let ((beg (match-beginning 0)) (vbeg (match-end 0)))
            (forward-line 1)
            (while (and (not (eobp)) (looking-at "[ \t]")) (forward-line 1))
            (push (replace-regexp-in-string
                   "[ \t]*\n[ \t]*" " "
                   (string-trim (buffer-substring-no-properties vbeg (point))))
                  old)
            (delete-region beg (point))
            (unless at (setq at beg))))
        (goto-char (or at (point-max)))
        (setq old (delete "" (nreverse old)))
        (insert name ": "
                (if (and append old) (string-join (append old (list value)) ", ") value)
                "\n")))))

(defun gml-mail--blank-p (strings)
  "Non-nil if every string of STRINGS is blank."
  (seq-every-p #'string-blank-p strings))

(defun gml-mail--region (state)
  "The region (BEG . END) of the last export in STATE, if it is intact.
It is intact when its markers are in the body of the current buffer
and its text is the one exported."
  (let ((beg (plist-get state :beg)) (end (plist-get state :end)))
    (and (markerp beg) (markerp end)
         (eq (marker-buffer beg) (current-buffer))
         (eq (marker-buffer end) (current-buffer))
         (<= (gml-mail--body-start) beg end)
         (equal (buffer-substring-no-properties beg end) (plist-get state :text))
         (cons (marker-position beg) (marker-position end)))))

(defun gml-mail--outside (beg end)
  "The body text of the current draft before BEG and after END."
  (list (buffer-substring-no-properties (gml-mail--body-start) beg)
        (buffer-substring-no-properties end (point-max))))

(defun gml-mail--remember (beg end)
  "Record in `gml-mail--state' that BEG..END holds the exported body."
  (let ((old gml-mail--state))
    (dolist (k '(:beg :end))
      (when (markerp (plist-get old k)) (set-marker (plist-get old k) nil))))
  (setq gml-mail--state
        (list :beg (copy-marker beg) :end (copy-marker end)
              :text (buffer-substring-no-properties beg end)
              :outside (gml-mail--outside beg end))))

(defun gml-mail--put-body (body)
  "Put BODY, the exported body in mime-edit tags, into the current draft.
The body of the last export is replaced.  Other text of the body is
kept if it is the text that was there after the last export (a
signature added then, say), and discarded if it is blank or the
text a memo was made from; any other text is discarded only if the
user agrees."
  (save-excursion
    (goto-char (gml-mail--header-end))
    (end-of-line)
    (when (eobp) (insert "\n")))
  (let* ((start (gml-mail--body-start))
         (region (gml-mail--region gml-mail--state))
         (beg (if region (car region) start))
         (end (if region (cdr region) start))
         (outside (gml-mail--outside beg end))
         (keep (and region (equal outside (plist-get gml-mail--state :outside)))))
    (unless (or keep
                (gml-mail--blank-p outside)
                (equal (apply #'concat outside) (plist-get gml-mail--state :consumed))
                (y-or-n-p (format "Discard the text in %s that gml-mail did not put there? "
                                  (buffer-name))))
      (user-error "Export cancelled; %s is unchanged" (buffer-name)))
    (let ((inhibit-read-only t))
      (if keep
          (delete-region beg end)
        (delete-region start (point-max))
        (setq beg start))
      (goto-char beg)
      (insert body)
      (gml-mail--remember beg (point)))))

(defun gml-mail--drafts ()
  "The Wanderlust draft buffers, most recently used first."
  (seq-filter #'gml-mail--draft-p (buffer-list)))

(defun gml-mail--choose-draft (&optional prompt)
  "Choose a draft buffer: the only one, or ask with PROMPT."
  (let ((drafts (gml-mail--drafts)))
    (cond
     ((null drafts)
      (user-error "No Wanderlust draft; `gml-mail-compose' makes a new one"))
     ((and (null (cdr drafts)) (not prompt)) (car drafts))
     (t (get-buffer
         (completing-read (or prompt "Export the memo into draft: ")
                          (mapcar #'buffer-name drafts) nil t nil nil
                          (buffer-name (if (memq gml-mail--draft drafts)
                                           gml-mail--draft (car drafts)))))))))

(defun gml-mail--associate (memo draft)
  "Remember that MEMO is exported into DRAFT."
  (with-current-buffer memo (setq gml-mail--draft draft))
  (with-current-buffer draft (setq gml-mail--memo memo)))

(defun gml-mail--header-alist (headers)
  "The `wl-draft' header alist of HEADERS, from the memo; not Bcc."
  (delq nil (mapcar (lambda (f)
                      (let ((v (cdr (assoc f headers))))
                        (and v (cons (intern f) v))))
                    '("From" "To" "Cc" "Subject"))))

;;;###autoload
(defun gml-mail-compose ()
  "Make a new Wanderlust draft from the memo in the current buffer.
Its header fields are the memo's (From only if the memo gives one;
else Wanderlust's), its body the memo as HTML, with a text
alternative, images and attachments.  The draft is remembered as the
memo's, so that `gml-mail-export' updates it after the memo changes."
  (interactive)
  (gml-mail--require-wl)
  (let* ((memo (current-buffer))
         (msg (gml-mail--message))
         (headers (plist-get msg :headers))
         (draft (wl-draft (gml-mail--header-alist headers))))
    (with-current-buffer draft
      (when-let* ((bcc (cdr (assoc "Bcc" headers))))
        (gml-mail--set-field "Bcc" bcc 'append))
      (gml-mail--put-body (plist-get msg :body))
      (run-hooks 'wl-mail-setup-hook)
      ;; what the hook added (a signature, say) stays on export
      (when-let* ((region (gml-mail--region gml-mail--state)))
        (gml-mail--remember (car region) (cdr region)))
      (goto-char (gml-mail--body-start)))
    (gml-mail--associate memo draft)
    (message "Draft %s made from the memo" (buffer-name draft))))

;;;###autoload
(defun gml-mail-export (&optional headers)
  "Put the memo of the current buffer into its Wanderlust draft.
The draft is the one the memo was last exported into, or made by
`gml-mail-compose' or `gml-mail-memo-from-draft'; else the only
draft, or one chosen (see `gml-mail-select-draft').  The memo's body
replaces the draft's (the previous export, or, if the user agrees,
text the draft had); the draft's header fields are kept, except those
of `gml-mail-export-headers', or, with a prefix argument HEADERS,
Subject, To, Cc and Bcc, which the memo sets if it gives them."
  (interactive "P")
  (gml-mail--require-wl)
  (let* ((memo (current-buffer))
         (draft (if (gml-mail--draft-p gml-mail--draft) gml-mail--draft
                  (gml-mail--choose-draft)))
         (msg (gml-mail--message))
         (fields (if headers '("Subject" "To" "Cc" "Bcc") gml-mail-export-headers)))
    (with-current-buffer draft
      (gml-mail--put-body (plist-get msg :body))
      (dolist (f fields)
        (when-let* ((v (cdr (assoc f (plist-get msg :headers)))))
          (gml-mail--set-field f v))))
    (gml-mail--associate memo draft)
    (pop-to-buffer draft)
    (goto-char (gml-mail--body-start))
    (message "Memo exported into %s" (buffer-name draft))))

;;;###autoload
(defun gml-mail-select-draft ()
  "Choose the Wanderlust draft that `gml-mail-export' writes into."
  (interactive)
  (let ((draft (gml-mail--choose-draft "Export the memo into draft: ")))
    (gml-mail--associate (current-buffer) draft)
    (message "The memo is exported into %s" (buffer-name draft))))

;;;; A memo from a draft

(defun gml-mail--attr (value)
  "VALUE as a quoted GML attribute value."
  (concat "'" (string-replace "'" "''" (string-replace "&" "&amp." value)) "'"))

(defun gml-mail--escape-text (text)
  "TEXT with `&' and a `:' that would start a tag written as symbols."
  (replace-regexp-in-string ":\\([A-Za-z@#$]\\)" "&gml.\\1"
                            (string-replace "&" "&amp." text) t))

(defun gml-mail--address-tags (tag value)
  "GML lines `:TAG name=... email=...' for the addresses of field VALUE."
  (when value
    (mapconcat
     (lambda (a)
       (concat ":" tag
               (and (cdr a) (not (string-blank-p (cdr a)))
                    (concat " name=" (gml-mail--attr (rfc2047-decode-string (cdr a)))))
               " email=" (gml-mail--attr (car a)) ".\n"))
     (seq-filter (lambda (a) (stringp (car a))) (mail-header-parse-addresses value))
     "")))

(defun gml-mail--cited (line)
  "LINE without one level of citation, or nil if it is not cited."
  (and (string-match (concat "\\`\\(?:" gml-mail-citation-regexp "\\) ?") line)
       (substring line (match-end 0))))

(defun gml-mail--paragraph (lines)
  "GML lines of a paragraph of the text LINES, in order."
  (let (out)
    (dolist (l lines)
      (let ((l (gml-mail--escape-text (string-trim l))))
        (if (null out)
            (push (concat ":p." l) out)
          ;; a line that begins with `.' would be a control word
          (when (string-prefix-p "." l) (push ".li" out))
          (push l out))))
    (nreverse out)))

(defun gml-mail--text-to-gml (lines)
  "GML lines for the text LINES: paragraphs, citations as long quotations."
  (let (out para)
    (cl-flet ((flush ()
                (dolist (l (gml-mail--paragraph (nreverse para))) (push l out))
                (setq para nil)))
      (while lines
        (let ((line (car lines)))
          (cond
           ((gml-mail--cited line)
            (flush)
            (let (run)
              ;; the cited lines, with blank lines between them
              (while (and lines
                          (or (gml-mail--cited (car lines))
                              (and (string-blank-p (car lines))
                                   (let ((next (seq-find (lambda (l) (not (string-blank-p l)))
                                                         (cdr lines))))
                                     (and next (gml-mail--cited next))))))
                (push (or (gml-mail--cited (car lines)) "") run)
                (setq lines (cdr lines)))
              (when-let* ((inner (gml-mail--text-to-gml (nreverse run))))
                (push ":lq." out)
                (dolist (l inner) (push l out))
                (push ":elq." out))))
           ((string-blank-p line)
            (flush)
            (setq lines (cdr lines)))
           (t
            (push line para)
            (setq lines (cdr lines))))))
      (flush))
    (nreverse out)))

(defun gml-mail--body-lines (body)
  "The lines of the text of draft BODY.
A leading text/plain tag goes; the text ends at the next mime-edit
tag, or at the signature separator `-- '."
  (let ((lines (seq-drop-while #'string-blank-p (split-string body "\n"))))
    (when (and lines (string-match-p "\\`--\\[\\[text/plain[];]" (car lines)))
      (setq lines (cdr lines)))
    (seq-take-while
     (lambda (l)
       (not (or (string-match-p "\\`--\\(?:\\[\\[\\|<<[^<>\n]+>>-{\\|}-<<\\)" l)
                (member l '("-- " "--")))))
     lines)))

(defun gml-mail--memo-skeleton (to cc subject body)
  "The text of a memo to TO, copy CC, with SUBJECT, quoting the draft BODY.
TO and CC are header field values (or nil); the citation in BODY
becomes long quotations, the other text paragraphs."
  (concat
   (gml-mail--address-tags "to" to)
   (gml-mail--address-tags "cc" cc)
   (if (and subject (not (string-blank-p subject)))
       (concat ":subject." (gml-mail--escape-text (string-trim subject)) "\n")
     "")
   ":memotxt.\n"
   (mapconcat (lambda (l) (concat l "\n"))
              (gml-mail--text-to-gml (gml-mail--body-lines (or body "")))
              "")
   ":p.\n"))

(defun gml-mail--new-memo-file ()
  "A new file name for a memo in `gml-mail-directory'."
  (let* ((dir (file-name-as-directory (expand-file-name gml-mail-directory)))
         (base (format-time-string "memo-%Y%m%d-%H%M%S"))
         (n 0) file)
    (make-directory dir t)
    (while (progn (setq file (expand-file-name
                              (format "%s%s.gml" base (if (> n 0) (format "-%d" n) ""))
                              dir))
                  (or (file-exists-p file) (get-file-buffer file)))
      (cl-incf n))
    file))

;;;###autoload
(defun gml-mail-memo-from-draft (&optional new)
  "Make a memo from the current Wanderlust draft.
The memo (a new file in `gml-mail-directory', not yet saved) has the
draft's To, Cc and Subject, and the draft's text: cited lines become
long quotations, nested as the citation is, other text paragraphs (an
attribution line, say).  Exporting the memo (\\[gml-mail-export])
replaces the draft's body.  If the draft already has a memo, go to
it, unless NEW (a prefix argument)."
  (interactive "P")
  (unless (gml-mail--draft-p (current-buffer))
    (user-error "Not in a Wanderlust draft"))
  (let ((draft (current-buffer)))
    (if (and (not new) (buffer-live-p gml-mail--memo))
        (pop-to-buffer gml-mail--memo)
      (let* ((body (buffer-substring-no-properties (gml-mail--body-start) (point-max)))
             (text (gml-mail--memo-skeleton (gml-mail--field "To") (gml-mail--field "Cc")
                                            (gml-mail--field "Subject") body))
             (memo (find-file-noselect (gml-mail--new-memo-file))))
        (with-current-buffer memo
          (erase-buffer)
          (insert text)
          (unless (derived-mode-p 'gml-mode) (gml-mode))
          (gml-mail-mode 1)
          (goto-char (point-max))
          (backward-char))
        (setq gml-mail--state (plist-put gml-mail--state :consumed body))
        (gml-mail--associate memo draft)
        (pop-to-buffer memo)))))

;;;; Preview

(defun gml-mail--add-base (html dir)
  "HTML with a <base> element for DIR, so that file names resolve."
  (let ((base (format "<base href=\"%s\">" (url-encode-url (concat "file://" dir))))
        (case-fold-search t))
    (if (string-match "<head[^>]*>" html)
        (concat (substring html 0 (match-end 0)) "\n" base (substring html (match-end 0)))
      (concat base "\n" html))))

;;;###autoload
(defun gml-mail-preview ()
  "Show the memo of the current buffer as HTML in a browser.
The HTML (gmlfmt -to html) is written next to the memo's file, or
to a temporary file if the buffer visits none."
  (interactive)
  (let* ((html (gml-mail--run "html"))
         (file (if buffer-file-name
                   (concat (file-name-sans-extension buffer-file-name) ".html")
                 (make-temp-file "gml-mail" nil ".html"))))
    (unless buffer-file-name
      (setq html (gml-mail--add-base html (gml-mail--directory))))
    (let ((coding-system-for-write 'utf-8-unix))
      (write-region html nil file nil 'silent))
    (browse-url-of-file file)))

;;;; The minor mode

(defun gml-mail--profile ()
  "The profile of the memo tag set, or nil if the project is not found."
  (when-let* ((root (gml--root)))
    (let ((p (expand-file-name (format "share/gmlapp/%s/profile.gml" gml-mail-app)
                               root)))
      (and (file-readable-p p) p))))

(defvar-local gml-mail--saved-profile nil
  "`gml-profile' of the buffer before `gml-mail-mode', as (VALUE).")

(defvar-keymap gml-mail-mode-map
  :doc "Keymap of `gml-mail-mode'."
  "C-c , c" #'gml-mail-compose
  "C-c , e" #'gml-mail-export
  "C-c , d" #'gml-mail-select-draft
  "C-c , v" #'gml-mail-preview)

(easy-menu-define gml-mail-mode-menu gml-mail-mode-map "Menu of `gml-mail-mode'."
  '("Memo"
    ["New draft from the memo" gml-mail-compose]
    ["Export into the draft" gml-mail-export]
    ["Export with header fields" (gml-mail-export t)]
    ["Choose the draft..." gml-mail-select-draft]
    "---"
    ["Preview HTML" gml-mail-preview]))

;;;###autoload
(define-minor-mode gml-mail-mode
  "Minor mode for GML memos that are sent as mail.
The memo tags are known to completion, eldoc and filling, the memo
profile is used by flymake and gml-format (when `gml-root' finds
the project), and the memo becomes a Wanderlust draft.

\\{gml-mail-mode-map}"
  :lighter " Memo"
  (cond
   (gml-mail-mode
    (setq-local gml-tagset-tags gml-mail-tags)
    (setq-local gml-eol-tags (seq-union gml-eol-tags gml-mail--eol-tags))
    (when-let* ((p (gml-mail--profile)))
      (unless gml-mail--saved-profile
        (setq gml-mail--saved-profile (list gml-profile)))
      (setq-local gml-profile p)))
   (t
    (kill-local-variable 'gml-tagset-tags)
    (setq-local gml-eol-tags (seq-difference gml-eol-tags gml-mail--eol-tags))
    (when gml-mail--saved-profile
      (setq-local gml-profile (car gml-mail--saved-profile))
      (setq gml-mail--saved-profile nil))))
  (when (derived-mode-p 'gml-mode)
    (setq-local paragraph-separate (gml--paragraph-separate))))

(defun gml-mail--memo-file-p ()
  "Non-nil if the buffer visits a file in `gml-mail-directory'."
  (and buffer-file-name gml-mail-directory
       (file-in-directory-p buffer-file-name gml-mail-directory)))

;;;###autoload
(defun gml-mail-maybe-enable ()
  "Turn on `gml-mail-mode' if the buffer is a memo.
It is if it has a line beginning with :memotxt, or visits a file in
`gml-mail-directory'.  For `gml-mode-hook'."
  (when (or (gml-mail--memo-file-p)
            (save-excursion
              (save-restriction
                (widen)
                (goto-char (point-min))
                (let ((case-fold-search t))
                  (re-search-forward "^:memotxt\\_>" nil t)))))
    (gml-mail-mode 1)))

(provide 'gml-mail)

;;; gml-mail.el ends here
