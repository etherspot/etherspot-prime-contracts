# MODULAR ETHERSPOT WALLET IMPLEMENTATION GAS CONSUMPTION

<!-- ### aa-benchmark results - OLD

|                   | Creation | Native transfer | ERC20 transfer | Total  |
| ----------------- | -------- | --------------- | -------------- | ------ |
| ERC7579 reference | 289438   | 103811          | 93213          | 486462 |
| Etherspot ERC7579 | 319604   | 105012          | 94402          | 519018 | -->

### complete gas usage by function (01/03/2024)

| MultipleOwnerECDSAValidator.sol |        |       |        |       |         |
|-------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost   | Deployment Size |       |        |       |         |
| 471705            | 2388            |       |        |       |         |
| Function Name     | min             | avg   | median | max   | # calls |
| onInstall         | 22812           | 22812 | 22812  | 22812 | 48      |
| validateUserOp    | 6568            | 7176  | 7244   | 7515  | 6       |

| ModularEtherspotWallet.sol |                 |        |        |        |         |
|----------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost            | Deployment Size |        |        |        |         |
| 2149487                    | 10768           |        |        |        |         |
| Function Name              | min             | avg    | median | max    | # calls |
| addGuardian                | 754             | 34376  | 27052  | 48952  | 67      |
| addOwner                   | 732             | 16967  | 27024  | 27024  | 10      |
| changeProposalTimelock     | 2591            | 12617  | 12617  | 22644  | 2       |
| discardCurrentProposal     | 3223            | 4583   | 4776   | 5615   | 5       |
| execute                    | 26565           | 33622  | 26565  | 61853  | 5       |
| executeFromExecutor        | 3110            | 3933   | 3933   | 4756   | 2       |
| getProposal                | 428             | 1851   | 2036   | 2539   | 6       |
| guardianCosign             | 1356            | 21726  | 14940  | 45916  | 8       |
| guardianCount              | 340             | 340    | 340    | 340    | 2       |
| guardianPropose            | 694             | 100697 | 142827 | 142827 | 20      |
| initializeAccount          | 144817          | 172907 | 174780 | 174780 | 52      |
| isGuardian                 | 591             | 991    | 591    | 2591   | 5       |
| isOwner                    | 590             | 875    | 590    | 2590   | 14      |
| ownerCount                 | 364             | 364    | 364    | 364    | 2       |
| proposalId                 | 407             | 407    | 407    | 407    | 1       |
| proposalTimelock           | 362             | 362    | 362    | 362    | 1       |
| removeGuardian             | 2281            | 2616   | 2688   | 2916   | 5       |
| removeOwner                | 1018            | 2363   | 2510   | 2895   | 6       |
| validateUserOp             | 39093           | 39557  | 39700  | 39710  | 6       |

| ModularEtherspotWalletFactory.sol |     |        |        |        |         |
|-----------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost       | Deployment Size |        |        |        |         |
| 239733                | 1380            |        |        |        |         |
| Function Name         | min             | avg    | median | max    | # calls |
| createAccount         | 1730            | 242515 | 249133 | 249133 | 54      |
| getAddress            | 1619            | 1628   | 1631   | 1631   | 5       |