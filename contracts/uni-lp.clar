;; sip010 fungible token 
(define-fungible-token uni-lp)

;; defining errors 
(define-constant err-minter-only (err u300))
(define-constant err-amount-zero (err u301))


(define-data-var allowed-minter principal tx-sender)

;;getting symbol of the 
(define-read-only (get-symbol)
  (ok "uni-LP")
)
;;get decimal of the uni-lp 
(define-read-only (get-decimals) 
  (ok u6)
)
;; getting balance of the sender 
(define-read-only (get-balance (sender principal))
  (ft-get-balance uni-lp sender)
)
;; for getting total-supply
(define-read-only (get-total-supply)
  (ft-get-supply uni-lp)
)

;;allowing anyone to be minter. "admin controll"
(define-public (set-minter (sender principal))
  (begin
    (asserts! (is-eq tx-sender (var-get allowed-minter)) err-minter-only)

    (ok (var-set allowed-minter sender))
  )
)

;;function to mint token on "sender's" principal 
(define-public (mint (amount uint) (sender principal))
  (begin
    ;;(asserts! (is-eq tx-sender (var-get allowed-minter)) err-minter-only)
    (asserts! (> amount u0) err-amount-zero)
 
    (ft-mint? uni-lp amount sender)
  )
)

;;function to burn token of "tx-sender"
(define-public (burn (amount uint))
  (ft-burn? uni-lp amount tx-sender)
)