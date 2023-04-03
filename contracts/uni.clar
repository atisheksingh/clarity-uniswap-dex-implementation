

(define-fungible-token uni)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-amount-zero (err u101))

(define-read-only (get-symbol)
  (ok "UNIISWAP")
)

(define-read-only (get-balance (who principal))
  (ft-get-balance uni who)
)
(define-read-only (get-total-supply)
  (ft-get-supply uni)
)



(define-public (mint (amount uint) (who principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> amount u0) err-amount-zero)
    
    (ft-mint? uni amount who)
  )
)

(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-owner-only)
    (asserts! (> amount u0) err-amount-zero)

    (ft-transfer? uni amount sender recipient)
  )
)