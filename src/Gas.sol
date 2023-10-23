// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Ownable.sol";

contract Constants {
    uint256 public tradeFlag = 1;
    uint256 public basicFlag = 0;
    uint256 public dividendFlag = 1;
}

contract GasContract is Ownable, Constants {
    uint256 public totalSupply = 0; // cannot be updated
    uint256 public paymentCounter = 0;
    mapping(address => uint256) public balances;
    uint256 public tradePercent = 12;
    address public contractOwner;
    uint256 public tradeMode = 0;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    bool public isReady = false;
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    PaymentType constant defaultPayment = PaymentType.Unknown;

    History[] public paymentHistory; // when a payment was updated

    // TODO reorder
    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct History {
        uint256 lastUpdate;
        address updatedBy;
        uint256 blockNumber;
    }
    uint256 wasLastOdd = 1;
    mapping(address => uint256) public isOddWhitelistUser;

    struct ImportantStruct {
        uint256 amount;
        uint256 bigValue;
        address sender;
        uint8 valueA; // max 3 digits
        uint8 valueB; // max 3 digits
        bool paymentStatus;
    }
    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    modifier onlyAdminOrOwner() {
        address senderOfTx = msg.sender;
        if (checkForAdmin(senderOfTx)) {
            require(
                checkForAdmin(senderOfTx),
                "r001"
            );
            _;
        } else if (senderOfTx == contractOwner) {
            _;
        } else {
            revert(
                "revert001"
            );
        }
    }

    modifier checkIfWhiteListed(address sender) {
//        address senderOfTx = msg.sender;
//        require(
//            senderOfTx == sender,
//            "r002"
//        );
        uint256 usersTier = whitelist[sender];
        require(
            usersTier > 0 && usersTier < 4,
            "r003"
        );
//        require(
//            usersTier < 4,
//            "r004"
//        );
        _;
    }

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == contractOwner) {
                    balances[contractOwner] = totalSupply;
                } else {
                    balances[_admins[ii]] = 0;
                }
                if (_admins[ii] == contractOwner) {
                    emit supplyChanged(_admins[ii], totalSupply);
                } else if (_admins[ii] != contractOwner) {
                    emit supplyChanged(_admins[ii], 0);
                }
            }
        }
    }

    function getPaymentHistory()
        external
        payable
        returns (History[] memory paymentHistory_)
    {
        return paymentHistory;
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        bool admin = false;
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                admin = true;
            }
        }
        return admin;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }

    function getTradingMode() public view returns (bool mode_) {
        bool mode = false;
        if (tradeFlag == 1 || dividendFlag == 1) {
            mode = true;
        } else {
            mode = false;
        }
        return mode;
    }


    function addHistory(address _updateAddress, bool _tradeMode)
        public
        returns (bool status_, bool tradeMode_)
    {
        History memory history;
        history.blockNumber = block.number;
        history.lastUpdate = block.timestamp;
        history.updatedBy = _updateAddress;
        paymentHistory.push(history);
        bool[] memory status = new bool[](tradePercent);
        for (uint256 i = 0; i < tradePercent; i++) {
            status[i] = true;
        }
        return ((status[0] == true), _tradeMode);
    }

    function getPayments(address _user)
        public
        view
        returns (Payment[] memory payments_)
    {
        require(
            _user != address(0),
            "r005"
        );
        return payments[_user];
    }

    // init: 189726
    // external:
    // remote unused code： 168460
    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name // TODO bytes8?
    ) external returns (bool status_) {
        address senderOfTx = msg.sender;
        require(
            balances[senderOfTx] >= _amount,
            "r006"
        );
        require(
            bytes(_name).length < 9,
            "r007"
        );
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        Payment memory payment;
        payment.admin = address(0); //？？？ remove？
        payment.adminUpdated = false;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name; // bytes8
        payment.paymentID = ++paymentCounter;
        payments[senderOfTx].push(payment);

//        bool[] memory status = new bool[](tradePercent);
//        for (uint256 i = 0; i < tradePercent; i++) {
//            status[i] = true;
//        }
//        return (status[0] == true);

        return true;
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) external onlyAdminOrOwner {
        require(
            _ID > 0,
            "r008"
        );
        require(
            _amount > 0,
            "r009"
        );
        require(
            _user != address(0),
            "r010"
        );

        address senderOfTx = msg.sender;

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _ID) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                bool tradingMode = getTradingMode();
                addHistory(_user, tradingMode);
                emit PaymentUpdated(
                    senderOfTx,
                    _ID,
                    _amount,
                    payments[_user][ii].recipientName
                );
            }
        }
    }

    // init: 13885
    // opt logic: 13849
    function addToWhitelist(address _userAddrs, uint256 _tier)
    external
        onlyAdminOrOwner
    {
        require(_tier < 255, "r011");
        whitelist[_userAddrs] = _tier;
        whitelist[_userAddrs] = _tier >= 3? 3:(
            _tier == 1? 1:2
        );
        uint256 wasLastAddedOdd = wasLastOdd;
        if (wasLastAddedOdd == 1 || wasLastAddedOdd == 0) {
            wasLastOdd= wasLastAddedOdd == 1 ? wasLastOdd = 0 : 1;
            isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        } else {
            revert("revert002");
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    // init： 75937
    // merge add/minus: 74695
    // move require to top: 74664
    // reorder struct field: 70373
    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) external checkIfWhiteListed(msg.sender) {
//        address senderOfTx = msg.sender;
        require(
            balances[msg.sender] >= _amount,
            "r012"
        );
        require(
            _amount > 3,
            "r013"
        );

        whiteListStruct[msg.sender] = ImportantStruct(_amount, 0, msg.sender, 0, 0, true);

        balances[msg.sender] =balances[msg.sender] + whitelist[msg.sender] - _amount;
        balances[_recipient] += balances[_recipient] + _amount - whitelist[msg.sender];
//        balances[senderOfTx] += whitelist[senderOfTx];
//        balances[_recipient] -= whitelist[senderOfTx];

        emit WhiteListTransfer(_recipient);
    }


    function getPaymentStatus(address sender) external returns (bool, uint256) {
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }


    fallback() external payable {
         payable(msg.sender).transfer(msg.value);
    }
}
