(define-constant contract-owner tx-sender)
(define-constant err-zero-stx (err u200))
(define-constant err-zero-tokens (err u201))
(define-constant err-majority-only (err u202))


(define-data-var fee-basis-points uint u30);; protocol fee uni 0.3%

(define-public (setFee (fee uint))
  (let (
        (supply (contract-call? .uni-lp get-total-supply ))
        (balance-sender (contract-call? .uni-lp get-balance tx-sender ))
      )
      (begin
      (asserts! (> balance-sender (/ supply u2)) err-majority-only)
      (ok (var-set fee-basis-points fee))
    )
  )
)

;; get stx balance of the contract 
(define-read-only (getSTXbalance)
  (stx-get-balance (as-contract tx-sender))
)

;; get uni-token balance of the contract 
(define-read-only (get-token-balance)
  (contract-call? .uni get-balance (as-contract tx-sender))
)

;; get fee the of the protocol 
(define-read-only (get-fee) 
    (ok (var-get fee-basis-points))
)



(define-private (provideliquidityfirstinternal (stx-amount uint) (token-amount uint) (provider principal))
    (begin
  
      (try! (stx-transfer? stx-amount tx-sender (as-contract tx-sender))) ;; fetching stx to contract from tx-sender 
      (try! (contract-call? .uni transfer token-amount tx-sender (as-contract tx-sender)))  ;; send tokens from tx-sender to the contract
      (as-contract (contract-call? .uni-lp mint stx-amount provider)) ;; mint uni-lp tokens to tx-sender
    )
)

(define-private (provideLiquidityinternal (stx-amount uint))
  (let (
    ;;definig the data variable to be used 
      (contract-address (as-contract tx-sender))
      (stx-balance (getSTXbalance))
      (token-balance (get-token-balance))
      (tokens-to-transfer (/ (* stx-amount token-balance) stx-balance))
      (liquidity-token-supply (contract-call? .uni-lp get-total-supply)) 
      (liquidity-to-mint (/ (* stx-amount liquidity-token-supply) stx-balance))
      (provider tx-sender) ;; defining user as `provider`
    )
    (begin 
      (try! (stx-transfer? stx-amount tx-sender contract-address))  ;; transfer STX from liquidity provider to contract
      (try! (contract-call? .uni transfer tokens-to-transfer tx-sender contract-address))  ;; transfer uni-tokens from liquidity provider to contract
      (as-contract (contract-call? .uni-lp mint liquidity-to-mint provider)) ;;minting token to provider/user 
    )
  )
)

(define-public (provideliquidity (stx-amount uint) (token-amount uint))
  (begin
    (asserts! (> stx-amount u0) err-zero-stx)
    (asserts! (> token-amount u0) err-zero-tokens)

    (if (is-eq (getSTXbalance) u0)  ;; conditin to check wether the user is depositing first time 
      (provideliquidityfirstinternal stx-amount token-amount tx-sender) ;;if true we are using this function 
      (provideLiquidityinternal stx-amount)  ;; if check fails we will be using this function 
    )
  )
)

(define-public (removeliquidity (liquidity-burned uint))
  (begin
    (asserts! (> liquidity-burned u0) err-zero-tokens)

      (let (
        (stx-balance (getSTXbalance))
        (token-balance (get-token-balance))
        (liquidity-token-supply (contract-call? .uni-lp get-total-supply))
        (stx-withdrawn (/ (* stx-balance liquidity-burned) liquidity-token-supply))
        (tokens-withdrawn (/ (* token-balance liquidity-burned) liquidity-token-supply))
        (contract-address (as-contract tx-sender))
        (burner tx-sender)
      )
      (begin 
     
        (try! (contract-call? .uni-lp burn liquidity-burned))   ;; burn liquidity uni-tokens as tx-sender
        (try! (as-contract (stx-transfer? stx-withdrawn contract-address burner)))  ;; transfer STX from contract to tx-sender using internal function of stx-transfer 
        (as-contract (contract-call? .uni transfer tokens-withdrawn contract-address burner))   ;; transfer tokens from contract to tx-sender
      )
    )
  )
)



(define-public (STXtoToken (stx-amount uint))
  (begin 
    (asserts! (> stx-amount u0) err-zero-stx)
    
    (let (
      (stx-balance (getSTXbalance))
      (token-balance (get-token-balance))
      (constant (* stx-balance token-balance))
      (fee (/ (* stx-amount (var-get fee-basis-points)) u10000))
      (new-stx-balance (+ stx-balance stx-amount))
      (new-token-balance (/ constant (- new-stx-balance fee)))
      (tokens-to-pay (- token-balance new-token-balance))
      (user-address tx-sender)
      (contract-address (as-contract tx-sender))
    )
      (begin
       
        (try! (stx-transfer? stx-amount user-address contract-address))  ;; transfer STX from user to contract
     
        (as-contract (contract-call? .uni transfer tokens-to-pay contract-address user-address)) ;; transfer tokens from contract to user
      )
    )
  )
)

(define-public (TokentoSTX (token-amount uint))
  (begin 
    (asserts! (> token-amount u0) err-zero-tokens)
    
    (let (
      (stx-balance (getSTXbalance))
      (token-balance (get-token-balance))
      (constant (* stx-balance token-balance))
      (fee (/ (* token-amount (var-get fee-basis-points)) u10000))
      (new-token-balance (+ token-balance token-amount))
      (new-stx-balance (/ constant (- new-token-balance fee)))
      (stx-to-pay (- stx-balance new-stx-balance))
      (user-address tx-sender)
      (contract-address (as-contract tx-sender))
    )
      (begin
        (print fee)  ;; protocol fee 
        (print new-token-balance)
        (print (- new-token-balance fee))
        (print new-stx-balance)
        (print stx-to-pay)
        (try! (contract-call? .uni transfer token-amount user-address contract-address))  ;; transfer tokens from user to contract
        (as-contract (stx-transfer? stx-to-pay contract-address user-address))   ;; transfer tokens from contract to user
      )
    )
  )
)
