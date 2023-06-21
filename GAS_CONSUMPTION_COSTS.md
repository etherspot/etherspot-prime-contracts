## Gas consumption costs of various account abstraction implementations

### Taken as of 06/06/2023

|Implementation|Native Transfer|ERC20 Transfer|NFT Transfer|NFT Mint|Swap|Wallet Deployment|
|--------------|:-------------:|:------------:|:----------:|:------:|:--:|:---------------:|
| Etherspot |[105k](https://mumbai.polygonscan.com/tx/0xfde380a76d67e6201b5313e564107ceb72541d243c6afdf892f7dbcee993d223)|[113k](https://mumbai.polygonscan.com/tx/0x311a69483c4ab77c3716c9daa01adbdaaaa60f11dcd671b56777949d28bc8db2)|[263k](https://mumbai.polygonscan.com/tx/0xe3093ba3551313d947c9753c27529c19f5079abbf73fc6b0d66dc7a7a287274b)|[203k](https://mumbai.polygonscan.com/tx/0x89c4ea8e7f3683305f30a2f60d7e716923eaaac9087a5d71eaf507b3635c6431)|[194k](https://mumbai.polygonscan.com/tx/0x3a198487d62e4af12fbc5bb188faacffe8022bcb0e87d9df7bdce4670121e46a)|
|Stackup/SimpleAccount|[96k](https://mumbai.polygonscan.com/tx/0x969778adca19122e402c5c12a65248f5cc75b42f19d1d38045b70dfe6a9c8655)|[105k](https://mumbai.polygonscan.com/tx/0xa168918dfc8d611b0063ae8b193cabccce88e02ea8d869e7dc5449f0ace5ab02)|[169k](https://mumbai.polygonscan.com/tx/0xe7d0f2ec8821b1215f1be27feb82491d7db303d6539f949db7e10a3fff92d17d)|[258k](https://mumbai.polygonscan.com/tx/0x3249685ada8e89ea4d07f0ede55d65a1b349ee10d661eec5d6f54b8259013b89)|[198k](https://mumbai.polygonscan.com/tx/0xb22269bdd03203085ec1a0843da452a6922f589aa4e7a269832e2e4679e9770d)|[300k](https://mumbai.polygonscan.com/tx/0x20322da82dbdc13ea69ae462ab60bab9ee71b82ca4dd963ec939caf66e632dfc#internal)|
|Biconomy|[]()|[]()|[]()|[]()|[]()|[]()|
|Pimlico|[]()|[]()|[]()|[]()|[]()|[]()|
|* Kernel|[114k](https://mumbai.polygonscan.com/tx/0xe07ecbe7bee4cf4874f86ca0b515167bc6c4ae87d9fc523f793d23758f29d19d)|[117k](https://mumbai.polygonscan.com/tx/0x410caad89e0d7edffba23c6fa67c0a1ee3eaf2a669ae6c1ddd8ff60f522ce199)|[]()|[]()|[]()|[250k](https://mumbai.polygonscan.com/tx/0x20c25b162fc0b0dd2f5597a0c911b7e7aa660b859800684fd1d60203e314aac7)|

*Tested with Stackup bundler as it doesn't have a public bundler.
