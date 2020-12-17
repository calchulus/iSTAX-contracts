// SPDX-License-Identifier: MIT

// This contract is used 
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import './iSTAXIssuer.sol';
import './EnumerableSet.sol';

contract iSTAXmarket is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public startCoverageBlock;
    uint256 public matureBlock;
    uint256 public poolId;

    iStaxIssuer public issuer;
    IERC20 public stax;
    IERC20 public stakingToken;
    
    // address public multisig;

    uint256 public poolAmount;
    uint256 public totalReward;

    mapping (address => uint256) public poolsInfo;
    mapping (address => uint256) public preRewardAllocation;
    EnumerableSet public addressList;

    // Declare a set state variable
    EnumerableSet.AddressSet private addressSet;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        // address _multisig,
        iStaxIssuer _issuer,
        IERC20 _iStax,
        IERC20 _iStaxMarketToken,
        uint256 _startCoverageBlock,
        uint256 _matureBlock,
        uint256 _poolId
    ) public {
        // multisig = _multisig;
        issuer = _issuer;
        iStax = _iStax;
        iStaxMarketToken = _iStaxMarketToken;
        matureBlock = _matureBlock;
        startCoverageBlock = _startCoverageBlock;
        poolId = _poolId;
    }
    // There are not rewards to capture 
    // View function to see pending Tokens on frontend.

      function pendingExercisableCoverage(address _user) external view returns (uint256) {
        uint256 amount = poolsInfo[msg.sender];
        if (block.number < startCoverageBlock) {
            return 0;
        }
        if (block.number > matureBlock && amount > 0 && totalReward == 0) {
            // Add some check if the parameter is exercisable
            uint256 pending = issuer.pendingiStax(poolId, address(this));
            return pending.mul(amount).div(poolAmount);
        }
        if (block.number > matureBlock && amount > 0 && totalReward > 0) {
            return totalReward.mul(amount).div(poolAmount);
        }
        if (totalReward == 0 && amount > 0) {
            uint256 pending = issuer.pendingiStax(poolId, address(this));
            return pending.mul(amount).div(poolAmount);
        }
        return 0;
    }
  

    // Deposit iStax tokens for Participation in insurance staking
    // Depositing gives a user a claim for specific outcome, which will be redeemable for 0 or 1 STAX dependong on the outcome
    // Tokens are not refundable once deposited. All sales final.
    function deposit(uint256 _amount) public {
        require (block.number < startCoverageBlock, 'not deposit time');
        iStax.safeTransferFrom(address(msg.sender), address(this), _amount);
        // This adds the users to the claims list (an enumerable set)
        if (poolsInfo[msg.sender] == 0) {
            addressSet.add(address(msg.sender));
        }
        poolsInfo[msg.sender] = poolsInfo[msg.sender].add(_amount);

        // We may not need to incentivise users for participating ahead of the deadline, since they are covered or incentivised to participate in the earliest active contract
        preRewardAllocation[msg.sender] = preRewardAllocation[msg.sender].add((startCoverageBlock.sub(block.number)).mul(_amount));
        poolAmount = poolAmount.add(_amount);
        issuer.deposit(poolId, 0);
        emit Deposit(msg.sender, _amount);
    }

    // A redeem function to wipe out staked insurance token and redeem for rewards token from issuer.
    function redeem() public {
        // Cannot redeem if the coverage has not been finalised
        require (block.number > matureBlock, 'not redemption time');
        // Check if there's funds deposited by the multisig into this redeem function
        // require funds > 0 
        // Amount that can be claimed from the contract needs to be reduced by the amount redeemed
        uint256 deposit = poolsInfo[msg.sender]);
        poolAmount = poolAmount.sub(poolsInfo[msg.sender]);
        poolsInfo[msg.sender] = 0;
        // First reduce this claim
        claimsToPay = claimsToPay.sub(deposit);
        // combines principal and rewards into one sen
        stax.safeTransfer(address(msg.sender), fullSend);
        emit Withdraw(msg.sender, reward);
    }






    //    In future, if there's a different conversion ratio than 1:1, can be added here
        Stax.safeTransferFrom(address(this), address(msg.sender), fullSend);
        emit Withdraw(msg.sender, reward);
    }

    // Function for the multisig to cash in the deposited iSTAX Insurance tokens
    function cash(uint256 _amount) public onlyOwner {
        uint256 burnAmount = _amount.div(2)
        iStax.safeTransfer(address(msg.sender), burnAmount);
        // confirm this is a safe way to burn
        iStax.safeTransfer(address(0), burnAmount);
        emit Cash(msg.sender, _amount);
    }

    function depositToissuer(uint256 _amount) public onlyOwner {
        stakingToken.safeApprove(address(issuer), _amount);
        issuer.deposit(poolId, _amount);
    }

    // This is to allow Issuer to collect the rewards for the issuer? 
    function harvestFromissuer() public onlyOwner {
        issuer.deposit(poolId, 0);
        
    }
    }