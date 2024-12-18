;; Title: DePo (Decentralized Price Oracle) Aggregator
;; depo-aggregator.clar

(impl-trait 'SP466FNC0P7JWTNM2R9T199QRZN1MYEDTAR0KP27.oracle-trait.oracle-trait)

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_STALE_PRICE (err u101))
(define-constant ERR_INSUFFICIENT_PROVIDERS (err u102))
(define-constant ERR_PRICE_TOO_LOW (err u103))
(define-constant ERR_PRICE_TOO_HIGH (err u104))
(define-constant ERR_PRICE_DEVIATION (err u105))

(define-constant PRICE_PRECISION u100000000)  ;; 8 decimal places
(define-constant MAX_PRICE_AGE u900)          ;; 15 minutes in blocks
(define-constant MIN_PRICE_PROVIDERS u3)      ;; Minimum required price providers
(define-constant MAX_PRICE_PROVIDERS u10)     ;; Maximum allowed price providers
(define-constant MAX_PRICE_DEVIATION u200)    ;; 20% maximum deviation from median
(define-constant MIN_VALID_PRICE u100000)     ;; Minimum valid price
(define-constant MAX_VALID_PRICE u1000000000) ;; Maximum valid price

;; Data Variables
(define-data-var current-price uint u0)
(define-data-var last-update-block uint u0)
(define-data-var active-providers uint u0)

;; Maps
(define-map price-providers principal bool)
(define-map provider-prices principal uint)
(define-map provider-last-update principal uint)
(define-map sorted-prices uint uint)  ;; Index -> Price mapping for sorting

;; Private Functions
(define-private (is-contract-owner)
    (is-eq tx-sender CONTRACT_OWNER))

(define-private (is-authorized-provider (provider principal))
    (default-to false (map-get? price-providers provider)))

(define-private (get-provider-price (provider principal))
    (map-get? provider-prices provider))

(define-private (get-all-provider-prices)
    (map unwrap-panic 
        (filter is-some 
            (map get-provider-price 
                (map-get? price-providers provider)))))

;; Simple direct sort implementation
(define-private (sort-price-list (prices (list 100 uint)))
    (begin
        ;; Clear previous sorted prices
        (map-delete sorted-prices u0)
        ;; Store prices in order
        (map-set sorted-prices u0 
            (fold check-min prices u0))
        (ok (map-get? sorted-prices u0))))

(define-private (check-min (price uint) (current-min uint))
    (if (or (is-eq current-min u0) (< price current-min))
        price
        current-min))

(define-private (calculate-median (prices (list 100 uint)))
    (let ((len (len prices)))
        (if (>= len MIN_PRICE_PROVIDERS)
            (match (sort-price-list prices)
                price (ok price)
                error ERR_INSUFFICIENT_PROVIDERS)
            ERR_INSUFFICIENT_PROVIDERS)))

(define-private (is-price-valid (price uint) (reference uint))
    (and 
        (>= price (/ (* reference (- u1000 MAX_PRICE_DEVIATION)) u1000))
        (<= price (/ (* reference (+ u1000 MAX_PRICE_DEVIATION)) u1000))))

;; Public Functions
(define-public (add-price-provider (provider principal))
    (begin
        (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
        (asserts! (< (var-get active-providers) MAX_PRICE_PROVIDERS) ERR_NOT_AUTHORIZED)
        (map-set price-providers provider true)
        (var-set active-providers (+ (var-get active-providers) u1))
        (ok true)))

(define-public (remove-price-provider (provider principal))
    (begin
        (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
        (map-delete price-providers provider)
        (map-delete provider-prices provider)
        (map-delete provider-last-update provider)
        (var-set active-providers (- (var-get active-providers) u1))
        (ok true)))

(define-public (submit-price (price uint))
    (begin
        (asserts! (is-authorized-provider tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (>= price MIN_VALID_PRICE) ERR_PRICE_TOO_LOW)
        (asserts! (<= price MAX_VALID_PRICE) ERR_PRICE_TOO_HIGH)
        
        (map-set provider-prices tx-sender price)
        (map-set provider-last-update tx-sender block-height)
        
        (let ((prices (get-all-provider-prices)))
            (match (calculate-median prices)
                median (begin 
                    (var-set current-price median)
                    (var-set last-update-block block-height)
                    (ok median))
                error error))))

(define-read-only (get-current-price)
    (begin
        (asserts! (< (- block-height (var-get last-update-block)) MAX_PRICE_AGE) 
                 ERR_STALE_PRICE)
        (ok (var-get current-price))))

(define-read-only (get-price-provider-count)
    (var-get active-providers))

(define-read-only (get-provider-status (provider principal))
    (map-get? price-providers provider))

(define-read-only (get-last-update-block)
    (var-get last-update-block))

;; Error Handling
(define-map error-messages (response uint uint) (string-ascii 64))
(map-insert error-messages ERR_NOT_AUTHORIZED "Not authorized to perform this action")
(map-insert error-messages ERR_STALE_PRICE "Price data is stale")
(map-insert error-messages ERR_INSUFFICIENT_PROVIDERS "Insufficient number of price providers")
(map-insert error-messages ERR_PRICE_TOO_LOW "Price is below minimum threshold")
(map-insert error-messages ERR_PRICE_TOO_HIGH "Price is above maximum threshold")
(map-insert error-messages ERR_PRICE_DEVIATION "Price deviates too much from median")