// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

abstract contract ERC721Salable is ERC721PresetMinterPauserAutoId {

    ERC20PresetMinterPauser erc20;
    mapping(uint256 => bool) forSale;
    mapping(uint256 => uint256) price;
    mapping(uint256 => address) salerOf;

    //reversed mapping
    uint256[] onSaleTokens;

    uint256[] tmp;

    event tradeMaded (address from, address to, uint256 price, uint256 tokenId);

    constructor(ERC20PresetMinterPauser _erc20) {
        erc20 = _erc20;
    }

    function sale(uint256 tokenId, uint256 _price) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Salable: transfer caller is not owner nor approved");
        require(_exists(tokenId), "ERC721Salable: URI query for nonexistent token");

        forSale[tokenId] = true;   
        price[tokenId] = _price;
        salerOf[tokenId] = ownerOf(tokenId);

        onSaleTokens.push(tokenId);
    }

    function unSale(uint256 tokenId) public {
        require(salerOf[tokenId]==_msgSender(), "ERC721Salable: you're not saler of this token.");
        forSale[tokenId] = false;
        transferFrom(address(this), salerOf[tokenId], tokenId);
    }

    function buy(uint256 tokenId) public {
        require(forSale[tokenId], "ERC721Salable: this token is not salable");
        forSale[tokenId] = false;
        erc20.transfer(salerOf[tokenId], price[tokenId]);
        transferFrom(address(this), _msgSender(), tokenId);
        emit tradeMaded(salerOf[tokenId], _msgSender(), price[tokenId], tokenId);
    }

    function queryPrice(uint256 tokenId) public view returns(uint256){
        return price[tokenId];
    }

    function queryOnSaleTokens() public returns(uint256[] memory) {
        uint256 l = onSaleTokens.length;

        while (tmp.length > 0) tmp.pop();
        
        for (uint i=0; i<l; i++){
            if (forSale[onSaleTokens[i]]){
                tmp.push(onSaleTokens[i]);
            }
        }
        onSaleTokens = tmp;
        
        return onSaleTokens;
   }

   function querySaler(uint256 tokenId) public view returns(address) {
       return salerOf[tokenId];
   }
}