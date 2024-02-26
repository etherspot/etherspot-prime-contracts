# ERC7579 IMPLEMENTATION GAS CONSUMPTION

<!-- ### aa-benchmark results - OLD

|                   | Creation | Native transfer | ERC20 transfer | Total  |
| ----------------- | -------- | --------------- | -------------- | ------ |
| ERC7579 reference | 289438   | 103811          | 93213          | 486462 |
| Etherspot ERC7579 | 319604   | 105012          | 94402          | 519018 | -->

### complete gas usage by function (26/02/2024)

| src/modular-etherspot-wallet/modules/MultipleOwnerECDSAValidator.sol:MultipleOwnerECDSAValidator contract |                 |       |        |       |         |
|----------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost      | Deployment Size |       |        |       |         |
| 503737               | 2548            |       |        |       |         |
| Function Name        | min             | avg   | median | max   | # calls |
| onInstall            | 22835           | 22835 | 22835  | 22835 | 49      |
| validateUserOp       | 6591            | 7199  | 7267   | 7538  | 6       |


| src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol:ModularEtherspotWallet contract |                 |        |        |        |         |
|------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost        | Deployment Size |        |        |        |         |
| 2231463                | 11228           |        |        |        |         |
| Function Name  | min             | avg    | median | max    | # calls |
| addGuardian            | 754             | 34374  | 27050  | 48950  | 67      |
| addOwner               | 732             | 16970  | 27028  | 27028  | 10      |
| changeProposalTimelock | 2591            | 16861  | 23997  | 23997  | 3       |
| discardCurrentProposal | 1079            | 4523   | 4776   | 6281   | 5       |
| execute                | 26565           | 33622  | 26565  | 61853  | 5       |
| executeFromExecutor    | 3110            | 3933   | 3933   | 4756   | 2       |
| getProposal            | 428             | 1851   | 2036   | 2539   | 6       |
| guardianCosign         | 1381            | 22124  | 15282  | 46677  | 8       |
| guardianCount          | 340             | 340    | 340    | 340    | 2       |
| guardianPropose        | 694             | 101170 | 143491 | 143491 | 20      |
| initializeAccount      | 144821          | 172968 | 174807 | 174807 | 53      |
| isGuardian             | 591             | 991    | 591    | 2591   | 5       |
| isOwner                | 590             | 875    | 590    | 2590   | 14      |
| ownerCount             | 364             | 364    | 364    | 364    | 2       |
| proposalId             | 407             | 407    | 407    | 407    | 1       |
| proposalTimelock       | 362             | 362    | 362    | 362    | 1       |
| removeGuardian         | 737             | 2207   | 2324   | 2965   | 5       |
| removeOwner            | 716             | 2030   | 2394   | 2944   | 6       |
| validateUserOp         | 39116           | 39580  | 39723  | 39733  | 6       |


| src/modular-etherspot-wallet/wallet/ModularEtherspotWalletFactory.sol:ModularEtherspotWalletFactory contract |                 |        |        |        |         |
|---------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost     | Deployment Size |        |        |        |         |
| 239733              | 1380            |        |        |        |         |
| Function Name       | min             | avg    | median | max    | # calls |
| createAccount       | 1730            | 242540 | 249160 | 249160 | 54      |
| getAddress          | 1619            | 1628   | 1631   | 1631   | 5       |
| implementation      | 216             | 216    | 216    | 216    | 1       |