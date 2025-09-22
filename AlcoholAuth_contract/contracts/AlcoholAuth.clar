
;; title: AlcoholAuth
;; version: 1.0.0
;; summary: Supply chain tracking smart contract for alcoholic beverage authentication and age verification
;; description: This contract enables tracking of alcoholic beverages through the supply chain,
;;              from production to retail, with built-in age verification and authentication features.

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-EXISTS (err u409))
(define-constant ERR-INVALID-BATCH (err u400))
(define-constant ERR-INVALID-LOCATION (err u402))
(define-constant ERR-INVALID-AGE (err u403))
(define-constant ERR-PRODUCT-CONSUMED (err u410))
(define-constant ERR-INVALID-VERIFICATION-CODE (err u411))

;; Minimum legal drinking age (in years)
(define-constant MIN-DRINKING-AGE u21)

;; data vars
;;
(define-data-var next-batch-id uint u1)
(define-data-var next-location-id uint u1)

;; data maps
;;

;; Batch information for alcoholic beverages
(define-map batches
  uint ;; batch-id
  {
    producer: principal,
    product-name: (string-ascii 100),
    alcohol-content: uint, ;; in basis points (e.g., 1250 = 12.5%)
    production-date: uint, ;; block height
    expiry-date: uint, ;; block height
    quantity: uint,
    remaining-quantity: uint,
    verification-code: (string-ascii 32),
    is-active: bool
  }
)

;; Supply chain locations (producers, distributors, retailers)
(define-map locations
  uint ;; location-id
  {
    owner: principal,
    name: (string-ascii 100),
    location-type: (string-ascii 20), ;; "producer", "distributor", "retailer"
    license-number: (string-ascii 50),
    is-verified: bool
  }
)

;; Track batch movements through supply chain
(define-map batch-movements
  {batch-id: uint, movement-id: uint}
  {
    from-location: uint,
    to-location: uint,
    quantity: uint,
    timestamp: uint, ;; block height
    handler: principal
  }
)

;; Track movement count per batch
(define-map batch-movement-count
  uint ;; batch-id
  uint ;; movement count
)

;; Age verification records
(define-map age-verifications
  principal ;; user
  {
    birth-date: uint, ;; block height representing birth date
    verification-date: uint, ;; block height when verified
    verifier: principal,
    is-verified: bool
  }
)

;; Product consumption records (for end consumers)
(define-map product-consumptions
  {batch-id: uint, consumer: principal}
  {
    quantity: uint,
    consumption-date: uint, ;; block height
    location-id: uint
  }
)

;; public functions
;;

;; Register a new location in the supply chain
(define-public (register-location (name (string-ascii 100)) (location-type (string-ascii 20)) (license-number (string-ascii 50)))
  (let ((location-id (var-get next-location-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (map-set locations location-id {
      owner: tx-sender,
      name: name,
      location-type: location-type,
      license-number: license-number,
      is-verified: false
    })
    (var-set next-location-id (+ location-id u1))
    (ok location-id)
  )
)

;; Verify a location (only contract owner can verify)
(define-public (verify-location (location-id uint))
  (let ((location-data (unwrap! (map-get? locations location-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (map-set locations location-id (merge location-data {is-verified: true}))
    (ok true)
  )
)

;; Create a new batch of alcoholic beverages
(define-public (create-batch
    (product-name (string-ascii 100))
    (alcohol-content uint)
    (expiry-date uint)
    (quantity uint)
    (verification-code (string-ascii 32))
    (location-id uint))
  (let ((batch-id (var-get next-batch-id))
        (location-data (unwrap! (map-get? locations location-id) ERR-INVALID-LOCATION)))
    (asserts! (get is-verified location-data) ERR-INVALID-LOCATION)
    (asserts! (is-eq (get owner location-data) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get location-type location-data) "producer") ERR-UNAUTHORIZED)
    (asserts! (> quantity u0) ERR-INVALID-BATCH)

    (map-set batches batch-id {
      producer: tx-sender,
      product-name: product-name,
      alcohol-content: alcohol-content,
      production-date: block-height,
      expiry-date: expiry-date,
      quantity: quantity,
      remaining-quantity: quantity,
      verification-code: verification-code,
      is-active: true
    })
    (var-set next-batch-id (+ batch-id u1))
    (ok batch-id)
  )
)

;; Move batch between locations in supply chain
(define-public (move-batch (batch-id uint) (to-location-id uint) (quantity uint))
  (let ((batch-data (unwrap! (map-get? batches batch-id) ERR-NOT-FOUND))
        (to-location (unwrap! (map-get? locations to-location-id) ERR-INVALID-LOCATION))
        (movement-count (default-to u0 (map-get? batch-movement-count batch-id))))

    (asserts! (get is-active batch-data) ERR-INVALID-BATCH)
    (asserts! (get is-verified to-location) ERR-INVALID-LOCATION)
    (asserts! (<= quantity (get remaining-quantity batch-data)) ERR-INVALID-BATCH)
    (asserts! (> quantity u0) ERR-INVALID-BATCH)

    ;; Record the movement
    (map-set batch-movements
      {batch-id: batch-id, movement-id: movement-count}
      {
        from-location: u0, ;; Will be enhanced to track from-location
        to-location: to-location-id,
        quantity: quantity,
        timestamp: block-height,
        handler: tx-sender
      }
    )

    ;; Update movement count
    (map-set batch-movement-count batch-id (+ movement-count u1))

    ;; Update remaining quantity
    (map-set batches batch-id
      (merge batch-data {remaining-quantity: (- (get remaining-quantity batch-data) quantity)})
    )

    (ok true)
  )
)

;; Verify age for alcohol purchase
(define-public (verify-age (birth-date uint))
  (let ((current-age-blocks (- block-height birth-date))
        ;; Approximate blocks per year (assuming ~10 minute blocks, ~52,560 blocks/year)
        (age-in-years (/ current-age-blocks u52560)))
    (asserts! (>= age-in-years MIN-DRINKING-AGE) ERR-INVALID-AGE)

    (map-set age-verifications tx-sender {
      birth-date: birth-date,
      verification-date: block-height,
      verifier: tx-sender,
      is-verified: true
    })
    (ok true)
  )
)

;; Record product consumption (end consumer purchase/consumption)
(define-public (consume-product (batch-id uint) (quantity uint) (verification-code (string-ascii 32)) (location-id uint))
  (let ((batch-data (unwrap! (map-get? batches batch-id) ERR-NOT-FOUND))
        (location-data (unwrap! (map-get? locations location-id) ERR-INVALID-LOCATION))
        (age-verification (unwrap! (map-get? age-verifications tx-sender) ERR-INVALID-AGE)))

    (asserts! (get is-active batch-data) ERR-INVALID-BATCH)
    (asserts! (get is-verified location-data) ERR-INVALID-LOCATION)
    (asserts! (is-eq (get location-type location-data) "retailer") ERR-INVALID-LOCATION)
    (asserts! (get is-verified age-verification) ERR-INVALID-AGE)
    (asserts! (is-eq (get verification-code batch-data) verification-code) ERR-INVALID-VERIFICATION-CODE)
    (asserts! (<= quantity (get remaining-quantity batch-data)) ERR-INVALID-BATCH)
    (asserts! (> quantity u0) ERR-INVALID-BATCH)

    ;; Record consumption
    (map-set product-consumptions
      {batch-id: batch-id, consumer: tx-sender}
      {
        quantity: quantity,
        consumption-date: block-height,
        location-id: location-id
      }
    )

    ;; Update remaining quantity
    (map-set batches batch-id
      (merge batch-data {remaining-quantity: (- (get remaining-quantity batch-data) quantity)})
    )

    (ok true)
  )
)

;; Deactivate a batch (in case of recalls or issues)
(define-public (deactivate-batch (batch-id uint))
  (let ((batch-data (unwrap! (map-get? batches batch-id) ERR-NOT-FOUND)))
    (asserts! (is-eq (get producer batch-data) tx-sender) ERR-UNAUTHORIZED)
    (map-set batches batch-id (merge batch-data {is-active: false}))
    (ok true)
  )
)

;; read only functions
;;

;; Get batch information
(define-read-only (get-batch (batch-id uint))
  (map-get? batches batch-id)
)

;; Get location information
(define-read-only (get-location (location-id uint))
  (map-get? locations location-id)
)

;; Get batch movement history
(define-read-only (get-batch-movement (batch-id uint) (movement-id uint))
  (map-get? batch-movements {batch-id: batch-id, movement-id: movement-id})
)

;; Get total movements for a batch
(define-read-only (get-batch-movement-count (batch-id uint))
  (default-to u0 (map-get? batch-movement-count batch-id))
)

;; Get age verification status
(define-read-only (get-age-verification (user principal))
  (map-get? age-verifications user)
)

;; Get consumption record
(define-read-only (get-consumption-record (batch-id uint) (consumer principal))
  (map-get? product-consumptions {batch-id: batch-id, consumer: consumer})
)

;; Check if user meets minimum drinking age
(define-read-only (is-of-legal-age (user principal))
  (match (map-get? age-verifications user)
    verification (get is-verified verification)
    false
  )
)

;; Verify product authenticity using verification code
(define-read-only (verify-product (batch-id uint) (verification-code (string-ascii 32)))
  (match (map-get? batches batch-id)
    batch-data (and
      (is-eq (get verification-code batch-data) verification-code)
      (get is-active batch-data)
    )
    false
  )
)

;; Get current batch and location IDs for reference
(define-read-only (get-next-batch-id)
  (var-get next-batch-id)
)

(define-read-only (get-next-location-id)
  (var-get next-location-id)
)

;; private functions
;;

;; Helper function to validate location type
(define-private (is-valid-location-type (location-type (string-ascii 20)))
  (or
    (is-eq location-type "producer")
    (or
      (is-eq location-type "distributor")
      (is-eq location-type "retailer")
    )
  )
)

;; Helper function to check if batch is expired
(define-private (is-batch-expired (batch-id uint))
  (match (map-get? batches batch-id)
    batch-data (> block-height (get expiry-date batch-data))
    true
  )
)
