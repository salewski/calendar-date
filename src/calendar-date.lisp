(in-package :cl-user)
(defpackage calendar-date
  (:use :cl)
  (:export :calendar-date
           :calendar-date-year
           :calendar-date-month
           :calendar-date-day
           :calendar-date-day-of-week
           :calendar-date-values
           :calendar-date=
           :next-day
           :previous-day
           :next-week
           :previous-week
           :next-month
           :previous-month
           :beginning-of-next-month
           :nth-of-the-month
           :nth-of-the-month-in-business
           :last-day-of-the-month))
(in-package :calendar-date)


(defstruct (calendar-date (:constructor %make-calendar-date))
  (year :year :type integer :read-only t)
  (month :month :type integer :read-only t)
  (day :day :type integer :read-only t))

(defun leap-year-p (year)
  (and (= (mod year 4) 0)
       (or (/= (mod year 100) 0)
           (= (mod year 400) 0))))

(defun last-day-of-year-month (year month)
  (ecase month
    ((1 3 5 7 8 10 12) 31)
    ((4 6 9 11) 30)
    (2 (if (leap-year-p year) 29 28))))

(defun month-name (month)
  (check-type month (integer 1 12))
  (nth (1- month) '("Jan." "Feb." "Mar." "Apr." "May." "Jun."
                    "Jul." "Aug." "Sep." "Oct." "Nov." "Dec.")))

(defun calendar-date (year month day)
  (check-type year (integer 0 9999))
  (check-type month (integer 1 12))
  (check-type day (integer 1 31))
  (unless (<= day (last-day-of-year-month year month))
    (error "~A ~S does not have day ~S." (month-name month) year day))
  (%make-calendar-date :year year :month month :day day))

(defun calendar-date-day-of-week (calendar-date)
  nil)

(defun calendar-date-values (calendar-date)
  (values (calendar-date-year calendar-date)
          (calendar-date-month calendar-date)
          (calendar-date-day calendar-date)))

(defun calendar-date= (calendar-date1 calendar-date2)
  (multiple-value-bind (year1 month1 day1)
      (calendar-date-values calendar-date1)
    (multiple-value-bind (year2 month2 day2)
        (calendar-date-values calendar-date2)
      (and (= year1 year2)
           (= month1 month2)
           (= day1 day2)))))

(defmethod print-object ((object calendar-date) stream)
  (print-unreadable-object (object stream :type t)
    (multiple-value-bind (year month day) (calendar-date-values object)
      (format stream "~4,'0d-~2,'0d-~2,'0d" year month day))))

(defun next-day (calendar-date)
  (multiple-value-bind (year month day) (calendar-date-values calendar-date)
    (incf day)
    (when (> day (last-day-of-year-month year month))
      (setf day 1)
      (incf month))
    (when (> month 12)
      (setf month 1)
      (incf year))
    (calendar-date year month day)))

(defun previous-day (calendar-date)
  (multiple-value-bind (year month day) (calendar-date-values calendar-date)
    (decf day)
    (when (< day 1)
      (decf month)
      (if (< month 1)
          (progn
            (decf year)
            (setf month 12)
            (setf day 31))
          (setf day (last-day-of-year-month year month))))
    (calendar-date year month day)))

(defun next-week (calendar-date)
  (loop repeat 7
     do (setf calendar-date (next-day calendar-date)))
  calendar-date)

(defun previous-week (calendar-date)
  (loop repeat 7
     do (setf calendar-date (previous-day calendar-date)))
  calendar-date)

(defun next-month (calendar-date)
  (let ((day (calendar-date-day calendar-date)))
    (let ((calendar-date1 (next-day
                           (last-day-of-the-month calendar-date))))
      (loop
         until (multiple-value-bind (year1 month1 day1)
                   (calendar-date-values calendar-date1)
                 (or (= day day1)
                     (= day1 (last-day-of-year-month year1 month1))))
         do (setf calendar-date1 (next-day calendar-date1)))
      calendar-date1)))

(defun previous-month (calendar-date)
  (let ((day (calendar-date-day calendar-date)))
    (let ((calendar-date1 (beginning-of-the-month
                           (previous-day
                            (beginning-of-the-month calendar-date)))))
      (loop
         until (multiple-value-bind (year1 month1 day1)
                   (calendar-date-values calendar-date1)
                 (or (= day day1)
                     (= day1 (last-day-of-year-month year1 month1))))
         do (setf calendar-date1 (next-day calendar-date1)))
      calendar-date1)))

(defun beginning-of-the-month (calendar-date)
  (multiple-value-bind (year month day)
      (calendar-date-values calendar-date)
    (declare (ignore day))
    (calendar-date year month 1)))

(defun beginning-of-next-month (calendar-date)
  (beginning-of-the-month
   (next-month calendar-date)))

(defun nth-of-the-month (nth calendar-date)
  (check-type nth (integer 1 31))
  (multiple-value-bind (year month day) (calendar-date-values calendar-date)
    (declare (ignore day))
    (unless (<= nth (last-day-of-year-month year month))
      (error "~A ~S does not have day ~S." (month-name month) year nth)))
  (let ((calendar-date1 (beginning-of-the-month calendar-date)))
    (loop
       until (= nth (calendar-date-day calendar-date1))
       do (setf calendar-date1 (next-day calendar-date1)))
    calendar-date1))

(defun nth-of-the-month-in-business (nth calendar-date)
  (check-type nth (integer 1 31))
  (multiple-value-bind (year month day) (calendar-date-values calendar-date)
    (declare (ignore day))
    (unless (<= nth (last-day-of-year-month year month))
      (error "~A ~S does not have day ~S." (month-name month) year nth)))
  (let ((calendar-date1 (nth-of-the-month nth calendar-date)))
    (loop
       until (business-day-p calendar-date1)
       do (setf calendar-date1 (previous-day calendar-date1)))
    calendar-date1))

(defun last-day-of-the-month (calendar-date)
  (loop
     until (multiple-value-bind (year month day)
               (calendar-date-values calendar-date)
             (= day
                (last-day-of-year-month year month)))
     do (setf calendar-date (next-day calendar-date)))
  calendar-date)
