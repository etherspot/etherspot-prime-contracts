# ERC7579 IMPLEMENTATION GAS CONSUMPTION

### aa-benchmark results

|                   | Creation | Native transfer | ERC20 transfer | Total  |
| ----------------- | -------- | --------------- | -------------- | ------ |
| ERC7579 reference | 289438   | 103811          | 93213          | 486462 |
| Etherspot ERC7579 | 319604   | 105012          | 94402          | 519018 |

### complete gas usage by function

| src/ERC7579/modules/MultipleOwnerECDSAValidator.sol:MultipleOwnerECDSAValidator contract |                 |      |        |      |         |
|------------------------------------------------------------------------------------------|-----------------|------|--------|------|---------|
| Deployment Cost                                                                          | Deployment Size |      |        |      |         |
| 235275                                                                                   | 1207            |      |        |      |         |
| Function Name                                                                            | min             | avg  | median | max  | # calls |
| onInstall                                                                                | 408             | 408  | 408    | 408  | 52      |
| validateUserOp                                                                           | 5648            | 6318 | 5648   | 7658 | 3       |


| src/ERC7579/wallet/EtherspotWallet7579.sol:EtherspotWallet7579 contract |                 |        |        |        |         |
|-------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                         | Deployment Size |        |        |        |         |
| 2442309                                                                 | 12281           |        |        |        |         |
| Function Name                                                           | min             | avg    | median | max    | # calls |
| addGuardian                                                             | 732             | 35158  | 27028  | 50928  | 67      |
| addOwner                                                                | 1022            | 21516  | 33894  | 33894  | 10      |
| changeProposalTimelock                                                  | 2658            | 18262  | 26064  | 26064  | 3       |
| discardCurrentProposal                                                  | 1101            | 4545   | 4798   | 6303   | 5       |
| execute                                                                 | 26007           | 26007  | 26007  | 26007  | 2       |
| getProposal                                                             | 450             | 1873   | 2058   | 2561   | 6       |
| guardianCosign                                                          | 1403            | 23946  | 15304  | 51499  | 8       |
| guardianCount                                                           | 384             | 384    | 384    | 384    | 2       |
| guardianPropose                                                         | 716             | 101192 | 143513 | 143513 | 20      |
| initializeAccount                                                       | 123078          | 150183 | 150715 | 150715 | 52      |
| isExecutorInstalled                                                     | 2812            | 2812   | 2812   | 2812   | 1       |
| isGuardian                                                              | 635             | 1035   | 635    | 2635   | 5       |
| isOwner                                                                 | 678             | 1223   | 678    | 2678   | 11      |
| isValidatorInstalled                                                    | 2811            | 2811   | 2811   | 2811   | 1       |
| ownerCount                                                              | 430             | 430    | 430    | 430    | 2       |
| proposalId                                                              | 407             | 407    | 407    | 407    | 1       |
| proposalTimelock                                                        | 384             | 384    | 384    | 384    | 1       |
| removeGuardian                                                          | 2289            | 2967   | 2645   | 4922   | 5       |
| removeOwner                                                             | 2394            | 3737   | 3675   | 5067   | 6       |
| supportsInterface                                                       | 463             | 673    | 603    | 954    | 3       |
| validateUserOp                                                          | 37913           | 41530  | 42334  | 44344  | 3       |


| src/ERC7579/wallet/EtherspotWallet7579Factory.sol:EtherspotWallet7579Factory contract |                 |        |        |        |         |
|---------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                       | Deployment Size |        |        |        |         |
| 239733                                                                                | 1380            |        |        |        |         |
| Function Name                                                                         | min             | avg    | median | max    | # calls |
| createAccount                                                                         | 194219          | 222022 | 222568 | 222568 | 52      |
| getAddress                                                                            | 1280            | 1280   | 1280   | 1280   | 1       |