/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../../../common";
import type {
  BootstrapUtil,
  BootstrapUtilInterface,
} from "../../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/Bootstrap.t.sol/BootstrapUtil";

const _abi = [
  {
    inputs: [],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "module",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "_makeBootstrapConfig",
    outputs: [
      {
        components: [
          {
            internalType: "address",
            name: "module",
            type: "address",
          },
          {
            internalType: "bytes",
            name: "data",
            type: "bytes",
          },
        ],
        internalType: "struct BootstrapConfig",
        name: "config",
        type: "tuple",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address[]",
        name: "modules",
        type: "address[]",
      },
      {
        internalType: "bytes[]",
        name: "datas",
        type: "bytes[]",
      },
    ],
    name: "makeBootstrapConfig",
    outputs: [
      {
        components: [
          {
            internalType: "address",
            name: "module",
            type: "address",
          },
          {
            internalType: "bytes",
            name: "data",
            type: "bytes",
          },
        ],
        internalType: "struct BootstrapConfig[]",
        name: "configs",
        type: "tuple[]",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "module",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "makeBootstrapConfig",
    outputs: [
      {
        components: [
          {
            internalType: "address",
            name: "module",
            type: "address",
          },
          {
            internalType: "bytes",
            name: "data",
            type: "bytes",
          },
        ],
        internalType: "struct BootstrapConfig[]",
        name: "config",
        type: "tuple[]",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b5060405161001d9061005f565b604051809103906000f080158015610039573d6000803e3d6000fd5b50600080546001600160a01b0319166001600160a01b039290921691909117905561006c565b6116a58061070383390190565b6106888061007b6000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c8063619f811c146100465780637967ae111461006f578063811fc0dc1461008f575b600080fd5b610059610054366004610432565b6100a2565b6040516100669190610567565b60405180910390f35b61008261007d3660046105cb565b61017b565b604051610066919061060f565b61005961009d3660046105cb565b6101db565b6060825167ffffffffffffffff8111156100be576100be6102ab565b60405190808252806020026020018201604052801561010457816020015b6040805180820190915260008152606060208201528152602001906001900390816100dc5790505b50905060005b83518110156101745761014f84828151811061012857610128610629565b602002602001015184838151811061014257610142610629565b602002602001015161017b565b82828151811061016157610161610629565b602090810291909101015260010161010a565b5092915050565b604080518082018252606060208201526001600160a01b038416815290516101a790839060240161063f565b60408051601f19818403018152919052602080820180516001600160e01b03166306d61fe760e41b17905282015292915050565b604080516001808252818301909252606091816020015b6040805180820190915260008152606060208201528152602001906001900390816101f2579050509050828160008151811061023057610230610629565b60209081029190910101516001600160a01b03909116905260405161025990839060240161063f565b60408051601f198184030181529190526020810180516001600160e01b03166306d61fe760e41b1790528151829060009061029657610296610629565b60200260200101516020018190525092915050565b634e487b7160e01b600052604160045260246000fd5b604051601f8201601f1916810167ffffffffffffffff811182821017156102ea576102ea6102ab565b604052919050565b600067ffffffffffffffff82111561030c5761030c6102ab565b5060051b60200190565b80356001600160a01b038116811461032d57600080fd5b919050565b600082601f83011261034357600080fd5b813567ffffffffffffffff81111561035d5761035d6102ab565b610370601f8201601f19166020016102c1565b81815284602083860101111561038557600080fd5b816020850160208301376000918101602001919091529392505050565b600082601f8301126103b357600080fd5b813560206103c86103c3836102f2565b6102c1565b82815260059290921b840181019181810190868411156103e757600080fd5b8286015b8481101561042757803567ffffffffffffffff81111561040b5760008081fd5b6104198986838b0101610332565b8452509183019183016103eb565b509695505050505050565b6000806040838503121561044557600080fd5b823567ffffffffffffffff8082111561045d57600080fd5b818501915085601f83011261047157600080fd5b813560206104816103c3836102f2565b82815260059290921b840181019181810190898411156104a057600080fd5b948201945b838610156104c5576104b686610316565b825294820194908201906104a5565b965050860135925050808211156104db57600080fd5b506104e8858286016103a2565b9150509250929050565b6000815180845260005b81811015610518576020818501810151868301820152016104fc565b506000602082860101526020601f19601f83011685010191505092915050565b60018060a01b038151168252600060208201516040602085015261055f60408501826104f2565b949350505050565b600060208083016020845280855180835260408601915060408160051b87010192506020870160005b828110156105be57603f198886030184526105ac858351610538565b94509285019290850190600101610590565b5092979650505050505050565b600080604083850312156105de57600080fd5b6105e783610316565b9150602083013567ffffffffffffffff81111561060357600080fd5b6104e885828601610332565b6020815260006106226020830184610538565b9392505050565b634e487b7160e01b600052603260045260246000fd5b60208152600061062260208301846104f256fea26469706673582212200e55172c037198081138e6ede24001288f9f12494289d7d28411c7ab7519d93764736f6c63430008170033608060405234801561001057600080fd5b50611685806100206000396000f3fe60806040526004361061007f5760003560e01c8063855713681161004e578063855713681461025a578063b0d691fe14610288578063ea5f61d0146102ab578063eac9b20d146102cb57610086565b80630a664dba146101bb5780635e87556d146101ed578063642219af1461021a5780636b0d5cc41461023a57610086565b3661008657005b61009b6000356001600160e01b0319166102f8565b600080356001600160e01b031916815260008051602061160d8339815191526020526040902080546001600160a01b03811690600160a01b900460f81b8161010957604051632464e76d60e11b81526001600160e01b03196000351660048201526024015b60405180910390fd5b61011781607f60f91b6103ac565b1561016b5760408051368101909152366000823760408051601481019091523360601b90526000803660140183865afa90506101593d60408051918201905290565b3d6000823e81610167573d81fd5b3d81f35b6101768160006103ac565b156101b95760408051368101909152366000823760408051601481019091523360601b9052600080366014018382875af190506101593d60408051918201905290565b005b3480156101c757600080fd5b506101d06103c3565b6040516001600160a01b0390911681526020015b60405180910390f35b3480156101f957600080fd5b5061020d61020836600461105a565b6103f2565b6040516101e49190611167565b34801561022657600080fd5b506101b961023536600461105a565b61047b565b34801561024657600080fd5b506101b961025536600461118f565b6106c7565b34801561026657600080fd5b5061027a610275366004611214565b6106d7565b6040516101e4929190611240565b34801561029457600080fd5b506f71727de22e5e9d8baf0edac6f37da0326101d0565b3480156102b757600080fd5b5061027a6102c6366004611214565b610714565b3480156102d757600080fd5b506102eb6102e63660046112a3565b610744565b6040516101e491906112cd565b6001600160e01b03198116600090815260008051602061160d833981519152602090815260408083206001018054825181850281018501909352808352919290919083018282801561037357602002820191906000526020600020905b81546001600160a01b03168152600190910190602001808311610355575b505050505090506103848133610817565b15156000036103a8576040516332cf492b60e11b8152336004820152602401610100565b5050565b6001600160f81b0319828116908216145b92915050565b60006103ed7f36e05829dd1b9a4411d96a3549582172d7f071c1c0db5c573fcf94eb284316085490565b905090565b606030306001600160a01b031663642219af8a8a8a8a8a8a8a6040516024016104219796959493929190611452565b604051602081830303815290604052915060e01b6020820180516001600160e01b03838183161783525050505060405160200161045f9291906114b0565b6040516020818303038152906040529050979650505050505050565b60005b868110156104fa576104f288888381811061049b5761049b6114dc565b90506020028101906104ad91906114f2565b6104bb906020810190611512565b8989848181106104cd576104cd6114dc565b90506020028101906104df91906114f2565b6104ed90602081019061152f565b61082d565b60010161047e565b5060005b848110156105bc57600086868381811061051a5761051a6114dc565b905060200281019061052c91906114f2565b61053a906020810190611512565b6001600160a01b0316146105b4576105b486868381811061055d5761055d6114dc565b905060200281019061056f91906114f2565b61057d906020810190611512565b87878481811061058f5761058f6114dc565b90506020028101906105a191906114f2565b6105af90602081019061152f565b6108b4565b6001016104fe565b5060006105cc6020850185611512565b6001600160a01b0316146105fc576105fc6105ea6020850185611512565b6105f7602086018661152f565b6108df565b60005b818110156106bd57600083838381811061061b5761061b6114dc565b905060200281019061062d91906114f2565b61063b906020810190611512565b6001600160a01b0316146106b5576106b583838381811061065e5761065e6114dc565b905060200281019061067091906114f2565b61067e906020810190611512565b848484818110610690576106906114dc565b90506020028101906106a291906114f2565b6106b090602081019061152f565b610966565b6001016105ff565b5050505050505050565b6106d283838361082d565b505050565b606060007ff88ce1fdb7fb1cbd3282e49729100fa3f2d6ee9f797961fe4fb1871cea89ea02610707818686610c14565b92509250505b9250929050565b606060007ff88ce1fdb7fb1cbd3282e49729100fa3f2d6ee9f797961fe4fb1871cea89ea03610707818686610c14565b6040805160608082018352600080835260208084018290528385018390526001600160e01b03198616825260008051602061160d8339815191528152908490208451928301855280546001600160a01b0381168452600160a01b900460f81b6001600160f81b03191683830152600181018054865181850281018501885281815295969495929486019383018282801561080757602002820191906000526020600020905b81546001600160a01b031681526001909101906020018083116107e9575b5050505050815250509050919050565b6000806108248484610db1565b95945050505050565b7ff88ce1fdb7fb1cbd3282e49729100fa3f2d6ee9f797961fe4fb1871cea89ea026108588185610e17565b6040516306d61fe760e41b81526001600160a01b03851690636d61fe70906108869086908690600401611576565b600060405180830381600087803b1580156108a057600080fd5b505af11580156106bd573d6000803e3d6000fd5b7ff88ce1fdb7fb1cbd3282e49729100fa3f2d6ee9f797961fe4fb1871cea89ea036108588185610e17565b60006109097f36e05829dd1b9a4411d96a3549582172d7f071c1c0db5c573fcf94eb284316085490565b90506001600160a01b0381161561093e5760405163741cbe0360e01b81526001600160a01b0382166004820152602401610100565b610858847f36e05829dd1b9a4411d96a3549582172d7f071c1c0db5c573fcf94eb2843160855565b600082828080601f016020809104026020016040519081016040528093929190818152602001838380828437600092018290525060408051818a01356020818102601f01601f19168301909352969750893596918a018035965090945060609350915b818110156109e8576020810283810160600135908601526001016109c9565b505060408101356020818301033560608181528183850160208301379350610a1e92508591506001600160f81b031990506103ac565b15610a3c57604051633accf26360e11b815260040160405180910390fd5b6001600160e01b03198416600090815260008051602061160d83398151915260205260409020546001600160a01b031615610ab95760405162461bcd60e51b815260206004820152601e60248201527f46756e6374696f6e2073656c6563746f7220616c7265616479207573656400006044820152606401610100565b604080516060810182526001600160a01b038a1681526001600160f81b0319851660208201529081018390527ff88ce1fdb7fb1cbd3282e49729100fa3f2d6ee9f797961fe4fb1871cea89ea026001600160e01b0319861660009081526002919091016020908152604091829020835181548584015160f81c600160a01b026001600160a81b03199091166001600160a01b0390921691909117178155918301518051610b6c9260018501920190610f9b565b50905050610bac60405180606001604052806023815260200161162d6023913983600081518110610b9f57610b9f6114dc565b6020026020010151610eed565b6040516306d61fe760e41b81526001600160a01b03891690636d61fe7090610bd8908490600401611167565b600060405180830381600087803b158015610bf257600080fd5b505af1158015610c06573d6000803e3d6000fd5b505050505050505050505050565b606060006001600160a01b038416600114801590610c375750610c378585610f32565b15610c6057604051637c84ecfb60e01b81526001600160a01b0385166004820152602401610100565b82600003610c815760405163f725081760e01b815260040160405180910390fd5b8267ffffffffffffffff811115610c9a57610c9a61158a565b604051908082528060200260200182016040528015610cc3578160200160208202803683370190505b506001600160a01b03808616600090815260208890526040812054929450911691505b6001600160a01b03821615801590610d0857506001600160a01b038216600114155b8015610d1357508381105b15610d6d5781838281518110610d2b57610d2b6114dc565b6001600160a01b039283166020918202929092018101919091529281166000908152928790526040909220549091169080610d65816115b6565b915050610ce6565b6001600160a01b038216600114610da55782610d8a6001836115cf565b81518110610d9a57610d9a6114dc565b602002602001015191505b80835250935093915050565b81516000908190815b81811015610e0957846001600160a01b0316868281518110610dde57610dde6114dc565b60200260200101516001600160a01b031603610e015792506001915061070d9050565b600101610dba565b506000958695509350505050565b6001600160a01b0381161580610e3657506001600160a01b0381166001145b15610e5f57604051637c84ecfb60e01b81526001600160a01b0382166004820152602401610100565b6001600160a01b038181166000908152602084905260409020541615610ea357604051631034f46960e21b81526001600160a01b0382166004820152602401610100565b60016000818152602093909352604080842080546001600160a01b039485168087529286208054959091166001600160a01b03199586161790559190935280549091169091179055565b6103a88282604051602401610f039291906115e2565b60408051601f198184030181529190526020810180516001600160e01b031663319af33360e01b179052610f6e565b600060016001600160a01b03831614801590610f6757506001600160a01b038281166000908152602085905260409020541615155b9392505050565b610f7781610f7a565b50565b80516a636f6e736f6c652e6c6f67602083016000808483855afa5050505050565b828054828255906000526020600020908101928215610ff0579160200282015b82811115610ff057825182546001600160a01b0319166001600160a01b03909116178255602090920191600190910190610fbb565b50610ffc929150611000565b5090565b5b80821115610ffc5760008155600101611001565b60008083601f84011261102757600080fd5b50813567ffffffffffffffff81111561103f57600080fd5b6020830191508360208260051b850101111561070d57600080fd5b60008060008060008060006080888a03121561107557600080fd5b873567ffffffffffffffff8082111561108d57600080fd5b6110998b838c01611015565b909950975060208a01359150808211156110b257600080fd5b6110be8b838c01611015565b909750955060408a01359150808211156110d757600080fd5b908901906040828c0312156110eb57600080fd5b9093506060890135908082111561110157600080fd5b5061110e8a828b01611015565b989b979a50959850939692959293505050565b6000815180845260005b818110156111475760208185018101518683018201520161112b565b506000602082860101526020601f19601f83011685010191505092915050565b602081526000610f676020830184611121565b6001600160a01b0381168114610f7757600080fd5b6000806000604084860312156111a457600080fd5b83356111af8161117a565b9250602084013567ffffffffffffffff808211156111cc57600080fd5b818601915086601f8301126111e057600080fd5b8135818111156111ef57600080fd5b87602082850101111561120157600080fd5b6020830194508093505050509250925092565b6000806040838503121561122757600080fd5b82356112328161117a565b946020939093013593505050565b604080825283519082018190526000906020906060840190828701845b828110156112825781516001600160a01b03168452928401929084019060010161125d565b5050506001600160a01b039490941660209390930192909252509092915050565b6000602082840312156112b557600080fd5b81356001600160e01b031981168114610f6757600080fd5b602080825282516001600160a01b0390811683830152838201516001600160f81b031916604080850191909152840151606080850152805160808501819052600093929183019190849060a08701905b8083101561133f5784518416825293850193600192909201919085019061131d565b50979650505050505050565b81835281816020850137506000828201602090810191909152601f909101601f19169091010190565b600081356113818161117a565b6001600160a01b03168352602082013536839003601e190181126113a457600080fd5b820160208101903567ffffffffffffffff8111156113c157600080fd5b8036038213156113d057600080fd5b6040602086015261082460408601828461134b565b6000838385526020808601955060208560051b830101846000805b8881101561144457858403601f19018a52823536899003603e19018112611425578283fd5b611431858a8301611374565b9a86019a94505091840191600101611400565b509198975050505050505050565b60808152600061146660808301898b6113e5565b828103602084015261147981888a6113e5565b9050828103604084015261148d8187611374565b905082810360608401526114a28185876113e5565b9a9950505050505050505050565b6001600160a01b03831681526040602082018190526000906114d490830184611121565b949350505050565b634e487b7160e01b600052603260045260246000fd5b60008235603e1983360301811261150857600080fd5b9190910192915050565b60006020828403121561152457600080fd5b8135610f678161117a565b6000808335601e1984360301811261154657600080fd5b83018035915067ffffffffffffffff82111561156157600080fd5b60200191503681900382131561070d57600080fd5b6020815260006114d460208301848661134b565b634e487b7160e01b600052604160045260246000fd5b634e487b7160e01b600052601160045260246000fd5b6000600182016115c8576115c86115a0565b5060010190565b818103818111156103bd576103bd6115a0565b6040815260006115f56040830185611121565b905060018060a01b0383166020830152939250505056fef88ce1fdb7fb1cbd3282e49729100fa3f2d6ee9f797961fe4fb1871cea89ea044d6f64756c654d616e61676572203e3e20616c6c6f77656443616c6c6572735b305d3aa264697066735822122049f5676bbe9bb6a275d1f44eb057b1e13384193a35e23d9eb0af38a2d253201164736f6c63430008170033";

type BootstrapUtilConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: BootstrapUtilConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class BootstrapUtil__factory extends ContractFactory {
  constructor(...args: BootstrapUtilConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<BootstrapUtil> {
    return super.deploy(overrides || {}) as Promise<BootstrapUtil>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): BootstrapUtil {
    return super.attach(address) as BootstrapUtil;
  }
  override connect(signer: Signer): BootstrapUtil__factory {
    return super.connect(signer) as BootstrapUtil__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): BootstrapUtilInterface {
    return new utils.Interface(_abi) as BootstrapUtilInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): BootstrapUtil {
    return new Contract(address, _abi, signerOrProvider) as BootstrapUtil;
  }
}