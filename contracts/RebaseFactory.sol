// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.5.16;

import './interfaces/IRebaseFactory.sol';
import './RebasePair.sol';

contract RebaseFactory is IRebaseFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(RebasePair).creationCode));

    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Rebase: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Rebase: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Rebase: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(RebasePair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IRebasePair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Rebase: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Rebase: FORBIDDEN');
        require(_feeToSetter != address(0), 'Rebase: ZERO address');
        
        feeToSetter = _feeToSetter;
    }

    function getBeneficiary(address _pair) external view returns (address) {
        return IRebasePair(_pair).beneficiary();
    }

    function setBeneficiary(address _pair, address _beneficiary) external {
        require(msg.sender == feeToSetter, 'Rebase: FORBIDDEN');
        require(_pair != address(0), 'Rebase: ZERO address');
        require(_beneficiary != address(0), 'Rebase: ZERO address');

        IRebasePair(_pair).setBeneficiary(_beneficiary);
    }
}
