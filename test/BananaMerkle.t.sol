// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test, stdJson } from "forge-std/Test.sol";
import {BananaMerkle} from "../src/BananaMerkle.sol";
import "../src/mock/MockERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BananaMerkle_Unit is Test {
    using stdJson for string;
    event Claimed(address indexed claimer, uint256 amount);

    BananaMerkle bananaMerkle;

    bytes32 root = 0xa178a1ba718a2a1ade417f90e7ca571a7fff4707a3639b4932bdddc73659f1ff;
    bytes32 newRoot = 0x694fd08b0fd824ced0ca9e4617ed454c87d180c0347038663a040660c8b99a3b;
    bytes32[] proof = [
      bytes32(0x5aec4f2d7e5259a3b6f3d63f1d8c4250d66ba45666f356e403b116f56032a392),
      bytes32(0x033a2a3dc993fe3b6b3cc3b6732daab111a77d48f5ad78d492110a4c807c2081),
      bytes32(0x1bd6c175061e5be1e78cf49fcc6d5f1b89225cbfcf568f38f60c52ef141ad42e)
    ];
    bytes32[] newProof = [
      bytes32(0x0cecdf269bc0eb9688fcf9a6317e62df8663ded96759b21a44d184de753e9b17),
      bytes32(0xe21e9cc6e93eb392b7d3f7768fe57f41419d79d66a2174549661ed5636d6bd7d),
      bytes32(0x9eea3421134f1f311a21b59dca63c759554a5b6bf44112df41e1c5972017a678)
    ];

    uint256 claimAmount = 4761904761904761904;
    uint256 newClaimAmount = 4285714285714285714;

    address claimer = 0x5427B5141A6CC8228A9E74248F51210380adbaE9;
    MockERC20 token;


    // Types need to follow the alphabetical order of the json keys!
    struct ProofToTest {
        address _address;
        bytes32 _leaf;
        bytes32 _proof;
        uint256 _value;
    }

    struct Tmp {
        bytes32 _address;
        bytes32 _leaf;
        bytes32 _proof;
        bytes32 _value;
    }

    function setUp() public {
        token = new MockERC20(100_000 ether);
        bananaMerkle = new BananaMerkle(IERC20(token));
        bananaMerkle.updateRoot(root);
        token.transfer(address(bananaMerkle), 50_000 ether);

        string memory json = vm.readFile('./test/proofs.json');
        emit log_string(json);

        // bytes memory _proofs = vm.parseJson(json);
        // ProofToTest[] memory proofs = abi.decode(_proofs, (ProofToTest[]));

        // emit log_address(proofs[0]._address);
        // emit log_bytes32(proofs[0]._leaf);
        // emit log_bytes32(proofs[0]._proof);
        // emit log_uint(proofs[0]._value);
    }

    function test_claimerCanClaimOnce() public {
        bytes32[] memory _proof = new bytes32[](3);
        for (uint8 i = 0; i < proof.length; i++) {
            _proof[i] = proof[i];
        }
        uint256 _tokenBalanceBeforeClaim = token.balanceOf(claimer);

        vm.prank(claimer);
        bananaMerkle.claim(claimAmount, _proof);

        uint256 _tokenBalanceAfterClaim = token.balanceOf(claimer);
        uint256 _diff = _tokenBalanceAfterClaim - _tokenBalanceBeforeClaim;
        assertEq(_diff, claimAmount);

        vm.prank(claimer);
        vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_AlreadyClaimed.selector));
        bananaMerkle.claim(claimAmount, _proof);
    }

    function test_nonClaimerCannotClaim() public {
        bytes32[] memory _proof = new bytes32[](3);
        for (uint8 i = 0; i < proof.length; i++) {
            _proof[i] = proof[i];
        }

        vm.prank(address(123));
        vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_NothingToClaim.selector));
        bananaMerkle.claim(claimAmount, _proof);
    }


    function test_ClaimerCannotClaimWithInvalidProof() public {
        bytes32[] memory _proof = new bytes32[](3);
        for (uint8 i = 0; i < proof.length; i++) {
            _proof[i] = proof[i];
        }
        _proof[2] = 0x1bd6c175061e5be1e78cf49fcc6d5f1b89225cbfcf568f38f60c52ef141ad44e;

        vm.prank(claimer);
        vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_NothingToClaim.selector));
        bananaMerkle.claim(claimAmount, _proof);
    }



    function test_claimerCanClaimOnce_when_root_is_updated() public {
        bytes32[] memory _proof = new bytes32[](3);
        for (uint8 i = 0; i < proof.length; i++) {
            _proof[i] = proof[i];
        }
        uint256 _tokenBalanceBeforeClaim = token.balanceOf(claimer);

        vm.prank(claimer);
        bananaMerkle.claim(claimAmount, _proof);

        uint256 _tokenBalanceAfterClaim = token.balanceOf(claimer);
        uint256 _diff = _tokenBalanceAfterClaim - _tokenBalanceBeforeClaim;
        assertEq(_diff, claimAmount);

        vm.roll(block.number + 1);
        bananaMerkle.updateRoot(newRoot);

        for (uint8 i = 0; i < newProof.length; i++) {
            _proof[i] = newProof[i];
        }
        _tokenBalanceBeforeClaim = token.balanceOf(claimer);

        vm.prank(claimer);
        bananaMerkle.claim(newClaimAmount, _proof);

        _tokenBalanceAfterClaim = token.balanceOf(claimer);
        _diff = _tokenBalanceAfterClaim - _tokenBalanceBeforeClaim;
        assertEq(_diff, newClaimAmount);

        vm.prank(claimer);
        vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_AlreadyClaimed.selector));
        bananaMerkle.claim(newClaimAmount, _proof);
    }

    function test_nonClaimerCannotClaim_when_root_is_updated() public {
        vm.roll(block.number + 1);
        bananaMerkle.updateRoot(newRoot);

        bytes32[] memory _proof = new bytes32[](3);
        for (uint8 i = 0; i < newProof.length; i++) {
            _proof[i] = newProof[i];
        }

        vm.prank(address(123));
        vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_NothingToClaim.selector));
        bananaMerkle.claim(claimAmount, _proof);
    }


    function test_ClaimerCannotClaimWithInvalidProof_when_root_is_updated() public {
        vm.roll(block.number + 1);
        bananaMerkle.updateRoot(newRoot);

        bytes32[] memory _proof = new bytes32[](3);
        for (uint8 i = 0; i < newProof.length; i++) {
            _proof[i] = newProof[i];
        }
        _proof[2] = 0x1bd6c175061e5be1e78cf49fcc6d5f1b89225cbfcf568f38f60c52ef141ad44e;

        vm.prank(claimer);
        vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_NothingToClaim.selector));
        bananaMerkle.claim(claimAmount, _proof);
    }
}
