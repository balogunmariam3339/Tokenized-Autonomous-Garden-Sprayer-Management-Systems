;; Calibration Service Contract
;; Manages spray pattern and volume control calibration

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_INVALID_SPRAYER (err u201))
(define-constant ERR_CALIBRATION_NOT_FOUND (err u202))
(define-constant ERR_INVALID_PARAMETERS (err u203))
(define-constant ERR_CALIBRATION_EXPIRED (err u204))

;; Data Variables
(define-data-var next-calibration-id uint u1)
(define-data-var calibration-validity-period uint u1000) ;; blocks

;; Data Maps
(define-map sprayer-calibrations
  { sprayer-id: uint }
  {
    current-calibration: uint,
    last-calibrated: uint,
    calibration-due: uint,
    status: (string-ascii 20)
  }
)

(define-map calibrations
  { calibration-id: uint }
  {
    sprayer-id: uint,
    spray-pattern: (string-ascii 50),
    volume-rate: uint, ;; ml per minute
    pressure: uint, ;; PSI
    nozzle-type: (string-ascii 30),
    calibrated-by: principal,
    timestamp: uint,
    valid-until: uint,
    certified: bool
  }
)

(define-map calibration-standards
  { standard-id: uint }
  {
    name: (string-ascii 50),
    min-volume: uint,
    max-volume: uint,
    min-pressure: uint,
    max-pressure: uint,
    pattern-type: (string-ascii 30)
  }
)

;; Public Functions

;; Register sprayer for calibration
(define-public (register-sprayer-calibration (sprayer-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set sprayer-calibrations
      { sprayer-id: sprayer-id }
      {
        current-calibration: u0,
        last-calibrated: u0,
        calibration-due: (+ block-height (var-get calibration-validity-period)),
        status: "pending"
      }
    )
    (ok true)
  )
)

;; Perform calibration
(define-public (perform-calibration
  (sprayer-id uint)
  (spray-pattern (string-ascii 50))
  (volume-rate uint)
  (pressure uint)
  (nozzle-type (string-ascii 30))
)
  (let (
    (calibration-id (var-get next-calibration-id))
    (valid-until (+ block-height (var-get calibration-validity-period)))
  )
    (asserts! (> volume-rate u0) ERR_INVALID_PARAMETERS)
    (asserts! (> pressure u0) ERR_INVALID_PARAMETERS)

    (map-set calibrations
      { calibration-id: calibration-id }
      {
        sprayer-id: sprayer-id,
        spray-pattern: spray-pattern,
        volume-rate: volume-rate,
        pressure: pressure,
        nozzle-type: nozzle-type,
        calibrated-by: tx-sender,
        timestamp: block-height,
        valid-until: valid-until,
        certified: false
      }
    )

    (map-set sprayer-calibrations
      { sprayer-id: sprayer-id }
      {
        current-calibration: calibration-id,
        last-calibrated: block-height,
        calibration-due: valid-until,
        status: "calibrated"
      }
    )

    (var-set next-calibration-id (+ calibration-id u1))
    (ok calibration-id)
  )
)

;; Certify calibration
(define-public (certify-calibration (calibration-id uint))
  (let ((calibration (map-get? calibrations { calibration-id: calibration-id })))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some calibration) ERR_CALIBRATION_NOT_FOUND)

    (map-set calibrations
      { calibration-id: calibration-id }
      (merge (unwrap-panic calibration) { certified: true })
    )
    (ok true)
  )
)

;; Set calibration standard
(define-public (set-calibration-standard
  (standard-id uint)
  (name (string-ascii 50))
  (min-volume uint)
  (max-volume uint)
  (min-pressure uint)
  (max-pressure uint)
  (pattern-type (string-ascii 30))
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (< min-volume max-volume) ERR_INVALID_PARAMETERS)
    (asserts! (< min-pressure max-pressure) ERR_INVALID_PARAMETERS)

    (map-set calibration-standards
      { standard-id: standard-id }
      {
        name: name,
        min-volume: min-volume,
        max-volume: max-volume,
        min-pressure: min-pressure,
        max-pressure: max-pressure,
        pattern-type: pattern-type
      }
    )
    (ok true)
  )
)

;; Check if calibration is valid
(define-public (is-calibration-valid (sprayer-id uint))
  (let ((sprayer-cal (map-get? sprayer-calibrations { sprayer-id: sprayer-id })))
    (if (is-some sprayer-cal)
      (let ((cal-data (unwrap-panic sprayer-cal)))
        (ok (< block-height (get calibration-due cal-data)))
      )
      (ok false)
    )
  )
)

;; Update calibration validity period
(define-public (set-validity-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set calibration-validity-period new-period)
    (ok true)
  )
)

;; Read-only Functions

;; Get sprayer calibration status
(define-read-only (get-sprayer-calibration (sprayer-id uint))
  (map-get? sprayer-calibrations { sprayer-id: sprayer-id })
)

;; Get calibration details
(define-read-only (get-calibration (calibration-id uint))
  (map-get? calibrations { calibration-id: calibration-id })
)

;; Get calibration standard
(define-read-only (get-calibration-standard (standard-id uint))
  (map-get? calibration-standards { standard-id: standard-id })
)

;; Get validity period
(define-read-only (get-validity-period)
  (var-get calibration-validity-period)
)
