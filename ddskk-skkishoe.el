;;; ddskk-skkishoe.el --- skkishoe integration for ddskk  -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Cj-bc/陽鞠莉桜

;; Author:  Cj-bc/陽鞠莉桜 <cj.bc-sd@outlook.jp>
;; Keywords: 
;; Package-Requires: (request-deferred deferred ddskk)

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; 

;;; Code:

(require 'request-deferred)
(require 'ddskk)

;; skk-search-prog-list に載せればいいぽい？

(defgroup ddskk-skkishoe nil
  "Customizations for ddskk-skkishoe"
  :prefix "ddskk-skkishoe/"
  :group 'skk-server
  )

(defcustom ddskk-skkishoe/host "localhost"
  "skkishoeサーバーのあるホスト名又は IP アドレス。"
  :type 'string
  :group 'ddskk-skkishoe)


(defun ddskk-skkishoe/server-version ()
  "Skkishoe implementation of `skk-server-version'
"
  (interactive))

(defun ddskk-skkishoe/search-server ()
  "Find candidates and return as list.
Equivalent to `skk-search-server'

最終的に、候補のリストを返せばよいみたい。annotationは ';' で繋げる

(let ((skk-henkan-key \"きr\"))
    (skk-search-server-1 skk-large-jisyo 10000))
(\"切\" \"着\" \"斬;人を斬る\" \"伐;木を伐る\" \"剪;盆栽を剪る\" \"截;布地を截る\" \"鑽;<rare> 火を鑽る(=火打ち石で火を起こす)\" \"著;<rare> ≒着る\" \"[れ\" \"]\" \"[る\" \"[り\" ...)

"
  (let* ((key
         (if skk-use-numeric-conversion
             (skk-num-compute-henkan-key skk-henkan-key)
           skk-henkan-key))
        (okurigana (or skk-henkan-okurigana
                       skk-okuri-char))
	(response
	 (request "http://localhost:8080/candidates"
		      :params `(("midashi" . ,key))
		      :headers '(("Content-Type" . "application/json"))
		      :sync t
		      :parser (lambda ()
		       		(let ((json-object-type 'plist))
		       		  (json-read))))))
     (seq-map '(lambda (entry)
		 (let ((annotation (plist-get entry :annotation))
		       (candidate (plist-get entry :candidate)))
		   (if (string= annotation "")
		       candidate
		     (format "%s;%s" candidate annotation)))) (request-response-data response))))

(defun ddskk-skkishoe/setup
    (push '(ddskk-skkishoe/search-server) skk-search-prog-list))

(defun skkishoe/teadown
    (setq skk-search-prog-list (remove '(ddskk-skkishoe/search-server) skk-search-prog-list)))

(provide 'ddskk-skkishoe)
;;; ddskk-skkishoe.el ends here
