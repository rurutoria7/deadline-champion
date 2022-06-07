// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Insurance.sol";
import "./ERC721Land.sol";
import "./ERC20Dlc.sol";

contract Exchange {

    ERC721Land erc721land;
    ERC20Dlc erc20dlc;
    Insurance insurance;

    constructor(
        string memory ERC20name, string memory ERC20symbol, 
        string memory ERC721name, string memory ERC721symbol,
        string memory ERC721baseTokenURI 
    ) {
        erc20dlc = new ERC20Dlc(ERC20name, ERC20symbol);
        erc721land = new ERC721Land(
                ERC721name, ERC721symbol,
                ERC721baseTokenURI, erc20dlc
        );
        insurance = new Insurance(erc20dlc);
    }

    function getERC721Land() public view returns(ERC721Land) {
        return erc721land;
    }

    function getERC20Dlc() public view returns(ERC20Dlc) {
        return erc20dlc;
    }

    function getInsurance() public view returns(Insurance) {
        return insurance;
    }
}