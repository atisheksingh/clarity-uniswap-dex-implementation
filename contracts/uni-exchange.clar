(define-constant contract-owner tx-sender)
(define-constant err-zero-stx (err u200))
(define-constant err-zero-tokens (err u201))
(define-constant err-majority-only (err u202))


(define-data-var fee-basis-points uint u30);; protocol fee uni 0.3%

(define-public (set-fee (fee uint))
  (let (
        (supply (contract-call? .uni-lp get-total-supply ))
        (balance-sender (contract-call? .uni-lp get-balance tx-sender ))
      )
      (begin
      (asserts! (> balance-sender (/ supply u2)) err-majority-only)
      ;; #[allow(unchecked_data)]
      (ok (var-set fee-basis-points fee))
    )
  )
)

(define-read-only (get-stx-balance)
  (stx-get-balance (as-contract tx-sender))
)

;; Get contract token balance
(define-read-only (get-token-balance)
  (contract-call? .uni get-balance (as-contract tx-sender))
)

;; Get fee
(define-read-only (get-fee) 
    (ok (var-get fee-basis-points))
)


;; ####################   LIQUIDITY   #################

(define-private (provide-liquidity-first (stx-amount uint) (token-amount uint) (provider principal))
    (begin
      ;; send STX from tx-sender to the contract
      (try! (stx-transfer? stx-amount tx-sender (as-contract tx-sender)))
      ;; send tokens from tx-sender to the contract
      (try! (contract-call? .uni transfer token-amount tx-sender (as-contract tx-sender)))
      ;; mint LP tokens to tx-sender
      ;; inside as-contract the tx-sender is the exchange contract, so we use provider passed into the function
      (as-contract (contract-call? .uni-lp mint stx-amount provider))
    )
)

(define-private (provide-liquidity-additional (stx-amount uint))
  (let (
      ;; new tokens = additional STX * existing token balance / existing STX balance
      (contract-address (as-contract tx-sender))
      (stx-balance (get-stx-balance))
      (token-balance (get-token-balance))
      (tokens-to-transfer (/ (* stx-amount token-balance) stx-balance))
      
      ;; new LP tokens = additional STX / existing STX balance * total existing LP tokens
      (liquidity-token-supply (contract-call? .uni-lp get-total-supply))
      ;; I've reversed the direction a bit here: we need to be careful not to do a division that floors to zero
      ;; additional STX / existing STX balance is likely to!
      ;; Then we end up with zero LP tokens and a sad tx-sender
      (liquidity-to-mint (/ (* stx-amount liquidity-token-supply) stx-balance))

      (provider tx-sender)
    )
    (begin 
      ;; transfer STX from liquidity provider to contract
      (try! (stx-transfer? stx-amount tx-sender contract-address))
      ;; transfer tokens from liquidity provider to contract
      (try! (contract-call? .uni transfer tokens-to-transfer tx-sender contract-address))
      ;; mint LP tokens to tx-sender
      ;; inside as-contract the tx-sender is the exchange contract, so we use tx-sender passed into the function
      (as-contract (contract-call? .uni-lp mint liquidity-to-mint provider))
    )
  )
)

(define-public (provide-liquidity (stx-amount uint) (token-amount uint))
  (begin
    (asserts! (> stx-amount u0) err-zero-stx)
    (asserts! (> token-amount u0) err-zero-tokens)

    (if (is-eq (get-stx-balance) u0) 
      (provide-liquidity-first stx-amount token-amount tx-sender)
      (provide-liquidity-additional stx-amount)
    )
  )
)

(define-public (remove-liquidity (liquidity-burned uint))
  (begin
    (asserts! (> liquidity-burned u0) err-zero-tokens)

      (let (
        (stx-balance (get-stx-balance))
        (token-balance (get-token-balance))
        (liquidity-token-supply (contract-call? .uni-lp get-total-supply))

        ;; STX withdrawn = liquidity-burned * existing STX balance / total existing LP tokens
        ;; Tokens withdrawn = liquidity-burned * existing token balance / total existing LP tokens
        (stx-withdrawn (/ (* stx-balance liquidity-burned) liquidity-token-supply))
        (tokens-withdrawn (/ (* token-balance liquidity-burned) liquidity-token-supply))

        (contract-address (as-contract tx-sender))
        (burner tx-sender)
      )
      (begin 
        ;; burn liquidity tokens as tx-sender
        (try! (contract-call? .uni-lp burn liquidity-burned))
        ;; transfer STX from contract to tx-sender
        (try! (as-contract (stx-transfer? stx-withdrawn contract-address burner)))
        ;; transfer tokens from contract to tx-sender
        (as-contract (contract-call? .uni transfer tokens-withdrawn contract-address burner))
      )
    )
  )
)


;; ####################   SWAP   #################

(define-public (stx-to-token-swap (stx-amount uint))
  (begin 
    (asserts! (> stx-amount u0) err-zero-stx)
    
    (let (
      (stx-balance (get-stx-balance))
      (token-balance (get-token-balance))
      ;; constant to maintain = STX * tokens
      (constant (* stx-balance token-balance))
      ;; charge the fee. Fee is in basis points (1 = 0.01%), so divide by 10,000
      (fee (/ (* stx-amount (var-get fee-basis-points)) u10000))
      (new-stx-balance (+ stx-balance stx-amount))
      ;; constant should = (new STX - fee) * new tokens
      (new-token-balance (/ constant (- new-stx-balance fee)))
      ;; pay the difference between previous and new token balance to user
      (tokens-to-pay (- token-balance new-token-balance))
      ;; put addresses into variables for ease of use
      (user-address tx-sender)
      (contract-address (as-contract tx-sender))
    )
      (begin
        ;; transfer STX from user to contract
        (try! (stx-transfer? stx-amount user-address contract-address))
        ;; transfer tokens from contract to user
        (as-contract (contract-call? .uni transfer tokens-to-pay contract-address user-address))
      )
    )
  )
)

(define-public (token-to-stx-swap (token-amount uint))
  (begin 
    (asserts! (> token-amount u0) err-zero-tokens)
    
    (let (
      (stx-balance (get-stx-balance))
      (token-balance (get-token-balance))
      ;; constant to maintain = STX * tokens
      (constant (* stx-balance token-balance))
      ;; charge the fee. Fee is in basis points (1 = 0.01%), so divide by 10,000
      (fee (/ (* token-amount (var-get fee-basis-points)) u10000))
      (new-token-balance (+ token-balance token-amount))
      ;; constant should = new STX * (new tokens - fee)
      (new-stx-balance (/ constant (- new-token-balance fee)))
      ;; pay the difference between previous and new STX balance to user
      (stx-to-pay (- stx-balance new-stx-balance))
      ;; put addresses into variables for ease of use
      (user-address tx-sender)
      (contract-address (as-contract tx-sender))
    )
      (begin
        (print fee)
        (print new-token-balance)
        (print (- new-token-balance fee))
        (print new-stx-balance)
        (print stx-to-pay)
        ;; transfer tokens from user to contract
        (try! (contract-call? .uni transfer token-amount user-address contract-address))
        ;; transfer tokens from contract to user
        (as-contract (stx-transfer? stx-to-pay contract-address user-address))
      )
    )
  )
)
