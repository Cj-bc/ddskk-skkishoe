;;; ddskk-skkishoe.el --- skkishoe integration for ddskk  -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Cj-bc/陽鞠莉桜

;; Author:  Cj-bc/陽鞠莉桜 <cj.bc-sd@outlook.jp>
;; Keywords: 
;; Package-Requires: (request ddskk)

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

(require 'request)
(require 'ddskk)

;; skk-search-prog-list に載せればいいぽい？

(defgroup ddskk-skkishoe nil
  "Customizations for ddskk-skkishoe"
  :prefix "ddskk-skkishoe/"
  :group 'skk-server)

(defcustom ddskk-skkishoe/host "localhost"
  "skkishoeサーバーのあるホスト名又は IP アドレス。"
  :type 'string
  :group 'ddskk-skkishoe)

(defcustom ddskk-skkishoe/portnum 80
  "skkishoeサーバーのポート番号。"
  :type 'natnum
  :group 'ddskk-skkishoe)


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
	 (request (format "http://%s:%d/midashis/%s" ddskk-skkishoe/host ddskk-skkishoe/portnum key)
	   :headers '(("Content-Type" . "application/json"))
	   ;; `request' は処理中にエラーが起きた場合、メッセージに表示
	   ;; する。(正確には、内部で呼ばれている`request--callback')。
	   ;; 基本的にはそれで良いのだが、「サーバーと通信出来ない」場
	   ;; 合は単純にskkishoeを使えない状態なだけで異常とはしたくな
	   ;; い。そのためエラーメッセージを表示すると紛らわしい。そこ
	   ;; で、空のメッセージで上書きする
	   :error
	   (cl-function (lambda (&rest args &key error-thrown &allow-other-keys) ""
			  (when (string= (cdr error-thrown) "exited abnormally with code 7\n") (message ""))))
	   :sync t
	   :parser (lambda ()
		     (let ((json-object-type 'plist))
		       (json-read))))))

    ; `skk-okuri-search' の実装にて機能が無効であれば nil を返してい
    ; るので、無効な場合は nil を返せばいい模様。
    (if (request-response-error-thrown response) nil
      (seq-map '(lambda (entry)
		(pcase (cons (plist-get entry :annotation) (plist-get entry :candidate))
		  (`("" . ,cand) cand)
		  (`(,ann . ,cand) (format "%s;%s" cand ann))))
	     (request-response-data response)))))

(defun ddskk-skkishoe/setup ()
    (push '(ddskk-skkishoe/search-server) skk-search-prog-list))

(defun skkishoe/teadown ()
    (setq skk-search-prog-list (remove '(ddskk-skkishoe/search-server) skk-search-prog-list)))

(provide 'ddskk-skkishoe)
;;; ddskk-skkishoe.el ends here
