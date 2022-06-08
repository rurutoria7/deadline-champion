// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "./ERC721Salable.sol";

contract ERC721Land is ERC721Salable {
    using Counters for Counters.Counter;    
    Counters.Counter private _tokenIdTracker;

    struct Land
    {
        //[minX, maxX), [minY, maxY)
        int minX;
        int maxX;
        int minY;
        int maxY;
        bool getFired;
    }
    
    constructor(
        string memory name, string memory symbol, string memory baseTokenURI, 
        ERC20PresetMinterPauser _erc20
    ) ERC721PresetMinterPauserAutoId(name, symbol, baseTokenURI) ERC721Salable(_erc20) {}

    function _area(Land memory land) pure internal returns (int) { return (land.maxX-land.minX)*(land.maxY-land.minY); }
    function max(int a, int b) internal pure returns (int) {return a >= b ? a : b;}
    function min(int a, int b) internal pure returns (int) {return a <= b ? a : b;}


    //Mapping from tokenId address to a land
    mapping(uint256 => Land) landOfToken;

    //requre: send is owner
    //split token to two, setTokenURI for original one, create new one
    //send new one to sender

    function mint(address to) override public virtual {
        mintReturnTokenId(to);
    }    

    function mintReturnTokenId(address to) public virtual returns (uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721Land: must have minter role to mint");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());
        uint256 createdTokenId = _tokenIdTracker.current();
        _tokenIdTracker.increment();
        return createdTokenId;
    }

    function splitToken(uint256 tokenId, int splitX, int splitY) public virtual {
        require(_exists(tokenId), "ERC721Land: requre tokenId exist");        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Land: caller is not owner nor approved");
        _burn(tokenId);

        //split to 4
        Land storage original = landOfToken[tokenId];
        Land[4] memory res = [Land(original.minX,splitX,original.minY,splitY,false)
                            , Land(splitX,original.maxX,original.minY,splitY,false)
                            , Land(original.minX,splitX,splitY,original.maxY,false)
                            , Land(splitX,original.maxX,splitY,original.maxY,false)];
        //if has area, mint, setLand, send to sender
        for (uint256 i=0; i<4; i++){
            if (_area(res[i]) > 0){
                uint256 createdTokenId = mintReturnTokenId(_msgSender());
                setTokenLand(createdTokenId, res[i]);
            }
        }
    }

    function mergeToken(uint256 tokenIdA, uint256 tokenIdB) public virtual {
        require(_exists(tokenIdA), "ERC721Land: requre tokenId exist");
        require(_exists(tokenIdB), "ERC721Land: requre tokenId exist");
        require(_isApprovedOrOwner(_msgSender(), tokenIdA), "ERC721Land: caller is not owner nor approved");
        require(_isApprovedOrOwner(_msgSender(), tokenIdB), "ERC721Land: caller is not owner nor approved");

        Land memory lA = landOfToken[tokenIdA];
        Land memory lB = landOfToken[tokenIdB];
        Land memory res;

        //merge horizontal
        if (lA.minY==lB.minY && lA.maxY==lB.maxY && (lA.maxX==lB.minX || lA.minX==lB.maxX)) {
            res = Land(min(lA.minX,lB.minX), max(lA.maxX,lB.maxX), lA.minY, lA.maxY, false);
        }
        //merge vertical
        else if (lA.minX==lB.minX && lA.maxX==lB.maxX && (lA.maxY==lB.minY || lA.minY==lB.maxY)) {
            res = Land(lA.minX, lA.maxX, min(lA.minY,lB.minY), max(lA.maxY,lB.maxY), false);
        }
        //cannot merge to rectangle
        else{
            require(false, "ERC721Land: targets shoulde be rectangle land after merged");
        }

        //burn tokenB
        //set tokenIdA's Land to res
        burn(tokenIdB);
        setTokenLand(tokenIdA, res);
    }

    function setTokenLand(uint256 tokenId, Land memory land) public virtual {
        require(_exists(tokenId), "ERC721Land: requre tokenId exist");
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
        landOfToken[tokenId] = land;
    }

    function queryTokenLand(uint256 tokenId) public view virtual returns (Land memory){
        require(_exists(tokenId), "ERC721Land: requre tokenId exist");
        return landOfToken[tokenId];
    }
}