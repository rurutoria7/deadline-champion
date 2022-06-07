// SPDX-License-Identifier: MIT

import "../node_modules/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

abstract contract HouseInsurance {

    ERC20PresetMinterPauser public erc20;

    mapping (uint256 => address) insurer;
    mapping (uint256 => address) guarantor;
    mapping (uint256 => address) beneficiary;
    mapping (uint256 => address) validator;

    mapping (uint256 => uint256) insuredTarget;
    mapping (uint256 => uint256) soldPrice;
    mapping (uint256 => uint256) sumInsured;
    mapping (uint256 => uint256) expireLn;

    mapping (uint256 => bool) getPaid;
    mapping (uint256 => uint256) bank;
    mapping (uint256 => bool) exists;

    uint256 insuranceIdCounter;

    constructor (ERC20PresetMinterPauser _erc20) {
        erc20 = _erc20;
        insuranceIdCounter = 0;
    }

    modifier insurerOnly(uint256 id) {
        _;
    }
    modifier guarantorOnly(uint256 id) {
        _;
    }
    modifier beneficiaryOnly(uint256 id) {
        _;
    }
    modifier validatorOnly(uint256 id) {
        _;
    }
    modifier requirePaid(uint256 id) {
        _;
    }

    modifier requireExist(uint256 id) {
        _;
    }

    function _saveTokenInBank(
        uint256 id,
        uint256 amount
    ) internal {
        require(erc20.balanceOf(msg.sender) > amount);
        erc20.transfer(address(this), amount);
        bank[id] += amount;
    }

    function _takeTokenOutBank(
        uint256 id, 
        address to, 
        uint256 amount
    ) internal {
        erc20.transferFrom(address(this), to, amount);
        bank[id] -= amount;
    }


    function buildInsurance(
        address _guarantor,
        address _beneficiary,
        address _validator,
        uint256 _insuredTarget,
        uint256 _soldPrice,
        uint256 _sumInsured,
        uint256 _expireLn
    ) public {
        uint256 id = insuranceIdCounter;
        insuranceIdCounter += 1;

        //transfer insurer's money into contract
        _saveTokenInBank(id, _sumInsured);

        //set info
        insurer[id] = msg.sender;
        guarantor[id] = _guarantor;
        beneficiary[id] = _beneficiary;
        validator[id] = _validator;

        insuredTarget[id] = _insuredTarget;
        soldPrice[id] = _soldPrice;
        sumInsured[id] = _sumInsured;
        expireLn[id] = _expireLn;

        getPaid[id] = false;
        exists[id] = true;
    }

    function triggerCompensation(
        uint256 id,
        uint256 sumInsuredPercentage
    ) public requireExist(id) validatorOnly(id) requirePaid(id) {
        //send required money to beneficiary
        uint256 claim = sumInsured[id]*sumInsuredPercentage/100;
        _takeTokenOutBank(id, beneficiary[id], claim);
        //stop contract
        stopContract(id);
    }

    function stopContract(
        uint256 id
    ) public requireExist(id) guarantorOnly(id) { 
        // transfer money to company
        _takeTokenOutBank(
            id,
            insurer[id],
            bank[id]
        );
        // exist = false
        exists[id] = false;
    }

    function setBenificiary(
        uint256 id, address _beneficiary
    ) public requireExist(id) guarantorOnly(id) {
            beneficiary[id] = _beneficiary;
    }

    function pay(
        uint256 id
    ) public requireExist(id) guarantorOnly(id) {
        _saveTokenInBank(id,soldPrice[id]);
        getPaid[id] = true;
    }
}