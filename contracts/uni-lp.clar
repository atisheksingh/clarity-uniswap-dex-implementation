
(define-fungible-token uni-lp)


(define-constant err-minter-only (err u300))
(define-constant err-amount-zero (err u301))


(define-data-var allowed-minter principal tx-sender)

(define-read-only (get-symbol)
  (ok "uni-LP")
)
(define-read-only (get-decimals) 
  (ok u6)
)

(define-read-only (get-balance (who principal))
  (ft-get-balance uni-lp who)
)

(define-read-only (get-total-supply)
  (ft-get-supply uni-lp)
)


(define-public (set-minter (who principal))
  (begin
    (asserts! (is-eq tx-sender (var-get allowed-minter)) err-minter-only)

    (ok (var-set allowed-minter who))
  )
)


(define-public (mint (amount uint) (who principal))
  (begin
    (asserts! (is-eq tx-sender (var-get allowed-minter)) err-minter-only)
    (asserts! (> amount u0) err-amount-zero)
 
    (ft-mint? uni-lp amount who)
  )
)


(define-public (burn (amount uint))
  (ft-burn? uni-lp amount tx-sender)
)