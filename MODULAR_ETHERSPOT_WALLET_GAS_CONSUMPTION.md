# MODULAR ETHERSPOT WALLET IMPLEMENTATION GAS CONSUMPTION

<!-- ### aa-benchmark results - OLD

|                   | Creation | Native transfer | ERC20 transfer | Total  |
| ----------------- | -------- | --------------- | -------------- | ------ |
| ERC7579 reference | 289438   | 103811          | 93213          | 486462 |
| Etherspot ERC7579 | 319604   | 105012          | 94402          | 519018 | -->

### complete gas usage by function (11/03/2024)

| MultipleOwnerECDSAValidator.sol |   |       |        |       |         |
|-------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost   | Deployment Size |       |        |       |         |
| 471705            | 2388            |       |        |       |         |
| Function Name     | min             | avg   | median | max   | # calls |
| onInstall         | 22812           | 22812 | 22812  | 22812 | 48      |
| validateUserOp    | 6568            | 7176  | 7244   | 7515  | 6       |

| ERC20SessionKeyValidator.sol    |                 |        |        |        |         |
|---------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                 | Deployment Size |        |        |        |         |
| 1297006                         | 6014            |        |        |        |         |
| Function Name                   | min             | avg    | median | max    | # calls |
| checkSessionKeyPaused           | 744             | 744    | 744    | 744    | 2       |
| disableSessionKey               | 30926           | 30926  | 30926  | 30926  | 2       |
| enableSessionKey                | 67518           | 132245 | 138694 | 138754 | 11      |
| getAssociatedSessionKeys        | 1309            | 1309   | 1309   | 1309   | 1       |
| getSessionKeyData               | 1609            | 1609   | 1609   | 1609   | 7       |
| rotateSessionKey                | 124571          | 124571 | 124571 | 124571 | 1       |
| toggleSessionKeyPause           | 27002           | 27002  | 27002  | 27002  | 1       |

| ModularEtherspotWallet.sol      |                 |        |        |        |         |
|---------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                 | Deployment Size |        |        |        |         |
| 3638796                         | 16660           |        |        |        |         |
| Function Name                   | min             | avg    | median | max    | # calls |
| addGuardian                     | 2666            | 53902  | 38154  | 82311  | 67      |
| addOwner                        | 2666            | 21847  | 33824  | 33824  | 10      |
| changeProposalTimelock          | 2569            | 13595  | 13595  | 24622  | 2       |
| discardCurrentProposal          | 4754            | 13426  | 13849  | 18574  | 5       |
| execute                         | 28900           | 35672  | 28900  | 64182  | 7       |
| executeFromExecutor             | 14852           | 34298  | 31885  | 62932  | 7       |
| getProposal                     | 406             | 1829   | 2014   | 2517   | 6       |
| getValidatorPaginated           | 2154            | 2462   | 2462   | 2771   | 2       |
| guardianCosign                  | 2489            | 37991  | 30750  | 75300  | 8       |
| guardianCount                   | 407             | 407    | 407    | 407    | 2       |
| guardianPropose                 | 2619            | 104797 | 146827 | 146827 | 20      |
| initializeAccount               | 22129           | 157242 | 152821 | 225206 | 317     |
| installModule                   | 33403           | 70212  | 70214  | 107018 | 4       |
| isGuardian                      | 624             | 1024   | 624    | 2624   | 5       |
| isModuleInstalled               | 1184            | 1184   | 1184   | 1184   | 9       |
| isOwner                         | 601             | 976    | 601    | 2601   | 16      |
| ownerCount                      | 386             | 386    | 386    | 386    | 2       |
| proposalId                      | 407             | 407    | 407    | 407    | 1       |
| proposalTimelock                | 340             | 340    | 340    | 340    | 1       |
| removeGuardian                  | 2688            | 10014  | 4916   | 18775  | 5       |
| removeOwner                     | 2667            | 7426   | 4956   | 14542  | 6       |
| transferERC20Action             | 47042           | 47042  | 47042  | 47042  | 1       |
| uninstallModule                 | 22368           | 23465  | 23465  | 24563  | 2       |
| validateUserOp                  | 15567           | 37311  | 40493  | 53590  | 12      |


| ModularEtherspotWalletFactory.sol |     |        |        |        |         |
|-----------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost       | Deployment Size |        |        |        |         |
| 239733                | 1380            |        |        |        |         |
| createAccount         | 1754            | 243094 | 249694 | 249694 | 55      |
| getAddress            | 1644            | 1654   | 1656   | 1656   | 7       |
| implementation        | 216             | 216    | 216    | 216    | 1       |

| SessionKeyValidator.sol       |                 |        |        |         |         |
|-------------------------------|-----------------|--------|--------|---------|---------|
| Deployment Cost               | Deployment Size |        |        |         |         |
| 2912129                       | 13270           |        |        |         |         |
| Function Name                 | min             | avg    | median | max     | # calls |
| addPermission                 | 26801           | 160379 | 169980 | 170544  | 268     |
| disableSessionKey             | 24171           | 66488  | 80594  | 80594   | 4       |
| enableSessionKey              | 26961           | 388750 | 364043 | 1532971 | 3992    |
| getSessionKeyData             | 1346            | 1346   | 1346   | 1346    | 1546    |
| getSessionKeyPermissions      | 730             | 4343   | 4019   | 20783   | 2060    |
| getSessionKeysByWallet        | 758             | 1430   | 1103   | 3570    | 517     |
| getUsesLeft                   | 682             | 682    | 682    | 682     | 259     |
| isInitialized                 | 574             | 1240   | 574    | 2574    | 3       |
| isModuleType                  | 347             | 347    | 347    | 347     | 3       |
| isSessionLive                 | 715             | 715    | 715    | 715     | 6195    |
| isValidSignatureWithSender    | 733             | 733    | 733    | 733     | 1       |
| modifyPermission              | 25262           | 64480  | 64544  | 66363   | 261     |
| removePermission              | 24148           | 63992  | 64220  | 82468   | 261     |
| rotateSessionKey              | 233698          | 249491 | 249695 | 249944  | 257     |
| toggleSessionKeyPause         | 24174           | 36677  | 25982  | 47882   | 6196    |
| updateUses                    | 24389           | 31047  | 31122  | 31434   | 259     |
| updateValidUntil              | 24289           | 29313  | 29336  | 29360   | 261     |