;;; mijia.el ---                               -*- lexical-binding: t; -*-

;; Copyright (C) 2025  Qiqi Jin

;; Author: Qiqi Jin <ginqi7@gmail.com>
;; Keywords:

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
(require 'ctable)

;;; Custom Variables
(defcustom mijia-command "mijiaAPI"
  "Command used to interact with the MiJia API.")

;;; Internal Functions
(cl-defun mijia--command-run (&key option alist)
  "Execute a MiJia command and optionally parse its output.

OPTION is the command-line option string passed to `mijia-command'.
ALIST is an association list mapping output keys to prefixes for parsing."
  (let ((output (shell-command-to-string (format "%s %s" mijia-command option))))
   (when alist
     (mijia--parse-output output alist))))

(cl-defun mijia--run-scene (scene-id-or-name)
  "Run a MiJia scene by its ID or name.

SCENE-ID-OR-NAME is the identifier or name of the scene to execute."
  (mijia--command-run :option (format "--run_scene %s" scene-id-or-name)))

(defun mijia--parse-output (text alist)
  "Parse MiJia command output into a list of hash tables.

TEXT is the raw output from the shell command.
ALIST is an association list where each element maps a key symbol
to a prefix string used to identify and extract values from TEXT.
Returns a list of hash tables, each containing parsed key-value pairs."
  (let ((lines (split-string text "\n" t))
        (idx 0)
        (current (make-hash-table))
        (result)
        (prefix)
        (key))
    (dolist (line lines)
      (setq prefix (cdr (nth idx alist)))
      (setq key (car (nth idx alist)))
      (if (string-prefix-p prefix (string-trim line))
          (progn
            (puthash key (substring (string-trim line) (length prefix)) current)
            (setq idx (1+ idx))
            (when (>= idx (length alist))
              (setq result (append result (list current)))
              (setq current (make-hash-table))
              (setq idx 0)))
        (setq idx 0)))
    result))

(defun mijia--list-devices ()
  "Retrieve and parse the list of MiJia devices.
Returns a list of hash tables containing device information
including name, did, model, and online status."
  (mijia--command-run :option "-l"
              :alist '((name . "- ")
                       (did . "did: ")
                       (model . "model: ")
                       (online . "online: "))))

(defun mijia--list-scenes ()
  "Retrieve and parse the list of MiJia scenes.
Returns a list of hash tables containing scene information
including name, id, and created-time."
  (mijia--command-run :option "--list_scenes"
              :alist '((name . "- ")
                       (id . "ID: ")
                       (created-time . "创建时间: "))))

(cl-defun mijia-ctable-render (&key buffer-name table actions)
  "Render data as a ctable in a buffer.

BUFFER-NAME is the name of the buffer to create or display.
TABLE is a list of hash tables containing the data to display.
ACTIONS is an optional function to call when a table row is clicked."
  (with-current-buffer (get-buffer-create buffer-name)
    (let* ((devices table)
           (column-model (mapcar (lambda (key) (make-ctbl:cmodel :title (symbol-name key) :align 'left)) (hash-table-keys (car devices))))
           (data (mapcar (lambda (device) (hash-table-values device)) devices))
           (model (make-ctbl:model :column-model column-model :data data))
           (component)
           (inhibit-read-only t))
      (erase-buffer)
      (setq component (ctbl:create-table-component-region :model model))
      (switch-to-buffer (current-buffer))
      (when actions
        (ctbl:cp-add-click-hook component (lambda () (funcall actions)))))))

;;; Interactive Functions
(defun mijia-run-scene ()
  "Run the MiJia scene selected in the current ctable buffer."
  (interactive)
  (let* ((cp (ctbl:cp-get-component))
         (row (ctbl:cp-get-selected-data-row cp)))
   (mijia--run-scene (nth 1 row))))

(defun mijia-list-devices ()
  "Display a list of all MiJia devices in a ctable buffer."
  (interactive)
  (mijia-ctable-render :buffer-name "*mijia-devices*"
                       :table (mijia--list-devices)))

(defun mijia-list-scenes ()
  "Display a list of all MiJia scenes in a ctable buffer.
Clicking on a scene in the table will execute it."
  (interactive)
  (mijia-ctable-render :buffer-name "*mijia-scenes*"
                       :table (mijia--list-scenes)
                       :actions #'mijia-run-scene))

(provide 'mijia)
;;; mijia.el ends here
