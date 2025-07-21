;; Application Intake Contract
;; Manages birth certificate requests and required documentation

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-APPLICATION (err u101))
(define-constant ERR-APPLICATION-EXISTS (err u102))
(define-constant ERR-APPLICATION-NOT-FOUND (err u103))
(define-constant ERR-INVALID-STATUS (err u104))

;; Data Variables
(define-data-var next-application-id uint u1)

;; Data Maps
(define-map applications
  { application-id: uint }
  {
    applicant: principal,
    child-first-name: (string-ascii 50),
    child-last-name: (string-ascii 50),
    birth-date: uint,
    birth-location: (string-ascii 100),
    mother-name: (string-ascii 100),
    father-name: (string-ascii 100),
    hospital-name: (string-ascii 100),
    status: (string-ascii 20),
    created-at: uint,
    updated-at: uint,
    documents-submitted: bool,
    fee-paid: bool
  }
)

(define-map authorized-personnel principal bool)

;; Authorization Functions
(define-public (add-authorized-personnel (personnel principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-personnel personnel true))
  )
)

(define-public (remove-authorized-personnel (personnel principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-delete authorized-personnel personnel))
  )
)

;; Application Management Functions
(define-public (submit-application
  (child-first-name (string-ascii 50))
  (child-last-name (string-ascii 50))
  (birth-date uint)
  (birth-location (string-ascii 100))
  (mother-name (string-ascii 100))
  (father-name (string-ascii 100))
  (hospital-name (string-ascii 100))
)
  (let
    (
      (application-id (var-get next-application-id))
      (current-time block-height)
    )
    (asserts! (> (len child-first-name) u0) ERR-INVALID-APPLICATION)
    (asserts! (> (len child-last-name) u0) ERR-INVALID-APPLICATION)
    (asserts! (> birth-date u0) ERR-INVALID-APPLICATION)
    (asserts! (> (len birth-location) u0) ERR-INVALID-APPLICATION)
    (asserts! (> (len mother-name) u0) ERR-INVALID-APPLICATION)
    (asserts! (> (len hospital-name) u0) ERR-INVALID-APPLICATION)

    (map-set applications
      { application-id: application-id }
      {
        applicant: tx-sender,
        child-first-name: child-first-name,
        child-last-name: child-last-name,
        birth-date: birth-date,
        birth-location: birth-location,
        mother-name: mother-name,
        father-name: father-name,
        hospital-name: hospital-name,
        status: "submitted",
        created-at: current-time,
        updated-at: current-time,
        documents-submitted: false,
        fee-paid: false
      }
    )

    (var-set next-application-id (+ application-id u1))
    (ok application-id)
  )
)

(define-public (update-application-status (application-id uint) (new-status (string-ascii 20)))
  (let
    (
      (application (unwrap! (map-get? applications { application-id: application-id }) ERR-APPLICATION-NOT-FOUND))
      (current-time block-height)
    )
    (asserts! (default-to false (map-get? authorized-personnel tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (> (len new-status) u0) ERR-INVALID-STATUS)

    (ok (map-set applications
      { application-id: application-id }
      (merge application { status: new-status, updated-at: current-time })
    ))
  )
)

(define-public (mark-documents-submitted (application-id uint))
  (let
    (
      (application (unwrap! (map-get? applications { application-id: application-id }) ERR-APPLICATION-NOT-FOUND))
      (current-time block-height)
    )
    (asserts! (default-to false (map-get? authorized-personnel tx-sender)) ERR-NOT-AUTHORIZED)

    (ok (map-set applications
      { application-id: application-id }
      (merge application { documents-submitted: true, updated-at: current-time })
    ))
  )
)

(define-public (mark-fee-paid (application-id uint))
  (let
    (
      (application (unwrap! (map-get? applications { application-id: application-id }) ERR-APPLICATION-NOT-FOUND))
      (current-time block-height)
    )
    (asserts! (default-to false (map-get? authorized-personnel tx-sender)) ERR-NOT-AUTHORIZED)

    (ok (map-set applications
      { application-id: application-id }
      (merge application { fee-paid: true, updated-at: current-time })
    ))
  )
)

;; Read-only Functions
(define-read-only (get-application (application-id uint))
  (map-get? applications { application-id: application-id })
)

(define-read-only (get-next-application-id)
  (var-get next-application-id)
)

(define-read-only (is-authorized (personnel principal))
  (default-to false (map-get? authorized-personnel personnel))
)

(define-read-only (get-application-status (application-id uint))
  (match (map-get? applications { application-id: application-id })
    application (some (get status application))
    none
  )
)
