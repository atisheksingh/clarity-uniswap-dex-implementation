# CLARITY Dex On STACKS

This project demonstrates a basic DEX on stacks blockchain.

A Decentralized Exchange on Stacks where users can provide liquidity and earn a LP token. Users can then swap their STX for fungible tokens, and vice versa, paying a small fee in the process. Liquidity provider can then burn their LP tokens to recover their liquidity plus the fees charged to users who swap their STX for fungible token.

we have three contracts in clairty as follows : 

1)uni.clar 
    An sip-010 standard token that can be used to provide liquidity. 
    
    Function list :- 
    1) mint 
    2) Burn 

2)uni-lp.clar 
    An sip010 standard token that can be sent to address providing liquidity. 
    
    Function list :- 
    1) mint 
    2) Burn 

3)Uni-exchange.clar 
    A smart contract of dex with swap ,  
    
    Function list : - 
    3.1) Protocol Fee : 0.3%

    3.2) Swap Function 
        1) StxToToken
        2) TokenToSTX 

    3.3) Add liquidity
        -Adding liquidity to protocol  
        -Getting Uni-LP token while adding uni token.
    3.4) Remove liquidity 
        Removing liquidity from protocol 
        
        
  
Command Line insturctions : - 

To start console:-
`clarinet console`

To mint custom token :-
`(contract-call? .uni  mint u5000 tx-sender)`

To call function 
`(contract-call? .uni-lp  mint u5000 tx-sender)`


