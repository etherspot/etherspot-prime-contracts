# ERC6900 IMPLEMENTATION GAS CONSUMPTION

| src/ERC6900/plugins/GuardianPlugin.sol:GuardianPlugin contract |                 |        |        |        |         |
|----------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                | Deployment Size |        |        |        |         |
| 2166805                                                        | 10912           |        |        |        |         |
| Function Name                                                  | min             | avg    | median | max    | # calls |
| addGuardian                                                    | 744             | 37034  | 26970  | 54976  | 67      |
| changeProposalTimelock                                         | 1434            | 17677  | 22742  | 23792  | 4       |
| discardCurrentProposal                                         | 1080            | 3833   | 4295   | 5929   | 5       |
| getAccountCurrentProposalId                                    | 582             | 1248   | 582    | 2582   | 3       |
| getAccountGuardianCount                                        | 655             | 1655   | 1655   | 2655   | 2       |
| getAccountProposalTimelock                                     | 627             | 1433   | 637    | 2637   | 5       |
| getOwnersForAccount                                            | 7905            | 12317  | 8592   | 19905  | 5       |
| getProposal                                                    | 2329            | 2420   | 2329   | 2603   | 3       |
| guardianCosign                                                 | 2033            | 38031  | 40042  | 71552  | 8       |
| guardianPropose                                                | 1598            | 121548 | 135704 | 135704 | 19      |
| isGuardian                                                     | 690             | 1690   | 1690   | 2690   | 2       |
| isGuardianOfAccount                                            | 800             | 1800   | 1800   | 2800   | 6       |
| onInstall                                                      | 22843           | 22843  | 22843  | 22843  | 39      |
| pluginManifest                                                 | 21849           | 21849  | 21849  | 21849  | 78      |
| runtimeValidationFunction                                      | 1071            | 3020   | 3090   | 6716   | 11      |
| supportsInterface                                              | 529             | 561    | 578    | 578    | 117     |


| src/ERC6900/plugins/MultipleOwnerPlugin.sol:MultipleOwnerPlugin contract |                 |       |        |       |         |
|--------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                                                          | Deployment Size |       |        |       |         |
| 1810705                                                                  | 9076            |       |        |       |         |
| Function Name                                                            | min             | avg   | median | max   | # calls |
| addOwner                                                                 | 25300           | 36653 | 38453  | 44806 | 6       |
| isOwnerOfAccount                                                         | 996             | 1764  | 1390   | 2996  | 69      |
| onInstall                                                                | 47311           | 47311 | 47311  | 47311 | 39      |
| ownersOf                                                                 | 1210            | 2174  | 1484   | 5210  | 5       |
| pluginManifest                                                           | 23476           | 23476 | 23476  | 23476 | 117     |
| removeOwner                                                              | 6268            | 6268  | 6268   | 6268  | 1       |
| runtimeValidationFunction                                                | 1651            | 2173  | 1651   | 5728  | 54      |
| supportsInterface                                                        | 412             | 523   | 555    | 555   | 234     |
| transferOwnership                                                        | 6318            | 38454 | 46988  | 46988 | 5       |


| src/ERC6900/wallet/EtherspotWalletV2.sol:EtherspotWalletV2 contract |                 |        |        |        |         |
|---------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                     | Deployment Size |        |        |        |         |
| 5962283                                                             | 30025           |        |        |        |         |
| Function Name                                                       | min             | avg    | median | max    | # calls |
| addGuardian                                                         | 16744           | 45035  | 31588  | 72488  | 13      |
| discardCurrentProposal                                              | 13626           | 13626  | 13626  | 13626  | 2       |
| executeFromPlugin                                                   | 4644            | 8854   | 4994   | 16644  | 5       |
| getOwnersForAccount                                                 | 10421           | 19036  | 11114  | 32921  | 5       |
| guardianCosign                                                      | 11606           | 11606  | 11606  | 11606  | 1       |
| guardianPropose                                                     | 11612           | 113716 | 147751 | 147751 | 4       |
| initialize                                                          | 903521          | 903521 | 903521 | 903521 | 39      |
| installPlugin                                                       | 857206          | 857206 | 857206 | 857206 | 39      |
| removeGuardian                                                      | 10245           | 10245  | 10245  | 10245  | 1       |
| transferOwnership                                                   | 18936           | 18936  | 18936  | 18936  | 1       |


| test/foundry/mocks/MSCAFactoryFixture.sol:MSCAFactoryFixture contract |                 |         |         |         |         |
|-----------------------------------------------------------------------|-----------------|---------|---------|---------|---------|
| Deployment Cost                                                       | Deployment Size |         |         |         |         |
| 7494947                                                               | 41992           |         |         |         |         |
| Function Name                                                         | min             | avg     | median  | max     | # calls |
| createAccount                                                         | 1065060         | 1065060 | 1065060 | 1065060 | 39      |
