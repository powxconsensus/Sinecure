(define-constant err-invalid-entry-fee (err 400)) 
(define-constant err-only-owner (err 401))
(define-constant err-stx-transfer-failed (err 402)) 
(define-constant err-game-not-started (err 403))
(define-constant err-game-already-started (err 404))
(define-constant err-insufficient-balance (err 405))
(define-constant err-already-entered (err 406))
(define-constant err-noone-entered (err 407))
(define-constant err-game-not-completed (err 408))
(define-constant contract-owner tx-sender) 

(define-data-var entry-amount uint u0)
(define-data-var status uint u0) 
;; status : {0 : not-started, 1 : started-and-user-can-participate, 2 : end-and-declare-winner-transfer-stx-amount}
(define-map users-mp-data principal {entered : bool, idx : uint})
(define-map users-mp-idx uint principal)
(define-data-var total-participant uint u0)
(define-data-var winner-idx uint u0)
(define-data-var winner-principal principal tx-sender)


(define-public (start-game (e-m uint)) 
    (begin
        (asserts! (is-eq contract-owner tx-sender) err-only-owner)
        (asserts! (not (>= (var-get status) u1)) err-game-already-started)
        (asserts! (> e-m u0) err-invalid-entry-fee)
        (var-set status u1)
        (var-set entry-amount e-m)
        (ok u1)
    )
)

(define-public (enter-in-game) 
    (let 
        (
            (e-m (var-get entry-amount))
            (t-p (var-get total-participant))

        )
        (begin
            (asserts! (is-eq (var-get status) u1) err-game-not-started)
            (asserts! (is-eq (get entered (default-to {entered : false, idx : u0} (map-get? users-mp-data tx-sender))) false) err-already-entered)
            (asserts! (>= (stx-get-balance tx-sender) e-m) err-insufficient-balance)
            (asserts! (unwrap-panic (stx-transfer? e-m tx-sender (as-contract tx-sender))) err-stx-transfer-failed)
            (map-insert users-mp-data tx-sender {entered : true, idx : t-p})
            (map-insert users-mp-idx t-p tx-sender)
            (var-set total-participant (+ t-p u1))
            (ok u1)
        )
    )
)

(define-public (declare-winner) 
    (begin
        (asserts! (is-eq contract-owner tx-sender) err-only-owner)
        (asserts! (is-eq (var-get status) u1) err-game-not-started)
        (asserts! (>= (var-get total-participant) u1) err-noone-entered)
        (var-set winner-idx (unwrap-panic (contract-call? .random-number get-random (var-get total-participant))))
        (var-set status u2)
        (var-set winner-principal (default-to tx-sender (map-get? users-mp-idx (var-get winner-idx))))
        (unwrap! (as-contract (stx-transfer? (* (var-get entry-amount) (var-get total-participant)) (as-contract tx-sender) (var-get winner-principal))) err-stx-transfer-failed)
        (ok u1)
    )
)

(define-read-only (get-total-participant) 
    (var-get total-participant)
)

(define-read-only (get-entry-amount) 
    (var-get entry-amount)
)

(define-read-only (game-status) 
    (var-get status)
)

(define-read-only (get-winner) 
    (begin 
        (asserts! (is-eq (var-get status) u2) err-game-not-completed)
        (ok {winner-address : (var-get winner-principal), winner-idx : (var-get winner-idx)})
    )
)