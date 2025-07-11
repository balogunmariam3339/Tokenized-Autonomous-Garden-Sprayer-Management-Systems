;; Cleaning Protocol Contract
;; Manages sprayer sanitation between different applications

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_INVALID_SPRAYER (err u301))
(define-constant ERR_CLEANING_NOT_FOUND (err u302))
(define-constant ERR_INVALID_PROTOCOL (err u303))
(define-constant ERR_CLEANING_REQUIRED (err u304))

;; Data Variables
(define-data-var next-cleaning-id uint u1)
(define-data-var next-protocol-id uint u1)

;; Data Maps
(define-map sprayer-cleaning-status
  { sprayer-id: uint }
  {
    last-cleaning: uint,
    cleaning-required: bool,
    last-chemical-used: uint,
    contamination-level: uint,
    status: (string-ascii 20)
  }
)

(define-map cleaning-records
  { cleaning-id: uint }
  {
    sprayer-id: uint,
    protocol-id: uint,
    cleaning-agent: (string-ascii 50),
    duration: uint, ;; minutes
    temperature: uint, ;; celsius
    cycles: uint,
    operator: principal,
    timestamp: uint,
    verified: bool
  }
)

(define-map cleaning-protocols
  { protocol-id: uint }
  {
    name: (string-ascii 50),
    chemical-category: (string-ascii 50),
    required-agent: (string-ascii 50),
    min-duration: uint,
    min-temperature: uint,
    required-cycles: uint,
    active: bool
  }
)

(define-map contamination-matrix
  { from-chemical: uint, to-chemical: uint }
  { cleaning-required: bool, protocol-id: uint }
)

;; Public Functions

;; Register sprayer for cleaning management
(define-public (register-sprayer-cleaning (sprayer-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set sprayer-cleaning-status
      { sprayer-id: sprayer-id }
      {
        last-cleaning: u0,
        cleaning-required: false,
        last-chemical-used: u0,
        contamination-level: u0,
        status: "clean"
      }
    )
    (ok true)
  )
)

;; Create cleaning protocol
(define-public (create-cleaning-protocol
  (name (string-ascii 50))
  (chemical-category (string-ascii 50))
  (required-agent (string-ascii 50))
  (min-duration uint)
  (min-temperature uint)
  (required-cycles uint)
)
  (let ((protocol-id (var-get next-protocol-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> min-duration u0) ERR_INVALID_PROTOCOL)
    (asserts! (> required-cycles u0) ERR_INVALID_PROTOCOL)

    (map-set cleaning-protocols
      { protocol-id: protocol-id }
      {
        name: name,
        chemical-category: chemical-category,
        required-agent: required-agent,
        min-duration: min-duration,
        min-temperature: min-temperature,
        required-cycles: required-cycles,
        active: true
      }
    )

    (var-set next-protocol-id (+ protocol-id u1))
    (ok protocol-id)
  )
)

;; Record cleaning operation
(define-public (record-cleaning
  (sprayer-id uint)
  (protocol-id uint)
  (cleaning-agent (string-ascii 50))
  (duration uint)
  (temperature uint)
  (cycles uint)
)
  (let (
    (cleaning-id (var-get next-cleaning-id))
    (protocol (map-get? cleaning-protocols { protocol-id: protocol-id }))
    (sprayer-status (map-get? sprayer-cleaning-status { sprayer-id: sprayer-id }))
  )
    (asserts! (is-some protocol) ERR_INVALID_PROTOCOL)
    (asserts! (is-some sprayer-status) ERR_INVALID_SPRAYER)
    (asserts! (get active (unwrap-panic protocol)) ERR_INVALID_PROTOCOL)

    ;; Validate cleaning parameters meet protocol requirements
    (asserts! (>= duration (get min-duration (unwrap-panic protocol))) (err u305))
    (asserts! (>= temperature (get min-temperature (unwrap-panic protocol))) (err u306))
    (asserts! (>= cycles (get required-cycles (unwrap-panic protocol))) (err u307))

    (map-set cleaning-records
      { cleaning-id: cleaning-id }
      {
        sprayer-id: sprayer-id,
        protocol-id: protocol-id,
        cleaning-agent: cleaning-agent,
        duration: duration,
        temperature: temperature,
        cycles: cycles,
        operator: tx-sender,
        timestamp: block-height,
        verified: false
      }
    )

    (map-set sprayer-cleaning-status
      { sprayer-id: sprayer-id }
      (merge (unwrap-panic sprayer-status) {
        last-cleaning: cleaning-id,
        cleaning-required: false,
        contamination-level: u0,
        status: "clean"
      })
    )

    (var-set next-cleaning-id (+ cleaning-id u1))
    (ok cleaning-id)
  )
)

;; Mark sprayer as requiring cleaning
(define-public (require-cleaning (sprayer-id uint) (chemical-used uint) (contamination-level uint))
  (let ((sprayer-status (map-get? sprayer-cleaning-status { sprayer-id: sprayer-id })))
    (asserts! (is-some sprayer-status) ERR_INVALID_SPRAYER)

    (map-set sprayer-cleaning-status
      { sprayer-id: sprayer-id }
      (merge (unwrap-panic sprayer-status) {
        cleaning-required: true,
        last-chemical-used: chemical-used,
        contamination-level: contamination-level,
        status: "contaminated"
      })
    )
    (ok true)
  )
)

;; Verify cleaning completion
(define-public (verify-cleaning (cleaning-id uint))
  (let ((cleaning-record (map-get? cleaning-records { cleaning-id: cleaning-id })))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some cleaning-record) ERR_CLEANING_NOT_FOUND)

    (map-set cleaning-records
      { cleaning-id: cleaning-id }
      (merge (unwrap-panic cleaning-record) { verified: true })
    )
    (ok true)
  )
)

;; Set contamination requirements
(define-public (set-contamination-rule (from-chemical uint) (to-chemical uint) (cleaning-required bool) (protocol-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set contamination-matrix
      { from-chemical: from-chemical, to-chemical: to-chemical }
      { cleaning-required: cleaning-required, protocol-id: protocol-id }
    )
    (ok true)
  )
)

;; Check if cleaning is required
(define-public (check-cleaning-required (sprayer-id uint) (next-chemical uint))
  (let (
    (sprayer-status (map-get? sprayer-cleaning-status { sprayer-id: sprayer-id }))
    (contamination-rule (map-get? contamination-matrix {
      from-chemical: (get last-chemical-used (unwrap-panic sprayer-status)),
      to-chemical: next-chemical
    }))
  )
    (if (is-some contamination-rule)
      (ok (get cleaning-required (unwrap-panic contamination-rule)))
      (ok (get cleaning-required (unwrap-panic sprayer-status)))
    )
  )
)

;; Read-only Functions

;; Get sprayer cleaning status
(define-read-only (get-sprayer-cleaning-status (sprayer-id uint))
  (map-get? sprayer-cleaning-status { sprayer-id: sprayer-id })
)

;; Get cleaning record
(define-read-only (get-cleaning-record (cleaning-id uint))
  (map-get? cleaning-records { cleaning-id: cleaning-id })
)

;; Get cleaning protocol
(define-read-only (get-cleaning-protocol (protocol-id uint))
  (map-get? cleaning-protocols { protocol-id: protocol-id })
)

;; Get contamination rule
(define-read-only (get-contamination-rule (from-chemical uint) (to-chemical uint))
  (map-get? contamination-matrix { from-chemical: from-chemical, to-chemical: to-chemical })
)
