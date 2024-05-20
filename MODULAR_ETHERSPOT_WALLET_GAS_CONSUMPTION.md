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

| ModularEtherspotWallet.sol |                 |        |        |        |         |
|----------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost            | Deployment Size |        |        |        |         |
| 3225771                    | 16143           |        |        |        |         |
| Function Name              | min             | avg    | median | max    | # calls |
| addGuardian                | 710             | 34332  | 27008  | 48908  | 67      |
| addOwner                   | 710             | 16945  | 27002  | 27002  | 10      |
| changeProposalTimelock     | 2636            | 12662  | 12662  | 22689  | 2       |
| discardCurrentProposal     | 3179            | 4539   | 4732   | 5571   | 5       |
| execute                    | 28878           | 35650  | 28878  | 64160  | 7       |
| executeFromExecutor        | 3511            | 16089  | 5152   | 39605  | 3       |
| getProposal                | 384             | 1807   | 1992   | 2495   | 6       |
| guardianCosign             | 1356            | 21726  | 14940  | 45916  | 8       |
| guardianCount              | 407             | 407    | 407    | 407    | 2       |
| guardianPropose            | 759             | 100762 | 142892 | 142892 | 20      |
| initializeAccount          | 145306          | 173487 | 175292 | 175292 | 54      |
| isGuardian                 | 624             | 1024   | 624    | 2624   | 5       |
| isOwner                    | 601             | 851    | 601    | 2601   | 16      |
| ownerCount                 | 386             | 386    | 386    | 386    | 2       |
| proposalId                 | 407             | 407    | 407    | 407    | 1       |
| proposalTimelock           | 406             | 406    | 406    | 406    | 1       |
| removeGuardian             | 2264            | 2596   | 2666   | 2894   | 5       |
| removeOwner                | 1018            | 2363   | 2510   | 2895   | 6       |
| validateUserOp             | 39084           | 39533  | 39722  | 39723  | 8       |

| ModularEtherspotWalletFactory.sol |     |        |        |        |         |
|-----------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost       | Deployment Size |        |        |        |         |
| 239733                | 1380            |        |        |        |         |
| createAccount         | 1754            | 243094 | 249694 | 249694 | 55      |
| getAddress            | 1644            | 1654   | 1656   | 1656   | 7       |
| implementation        | 216             | 216    | 216    | 216    | 1       |
