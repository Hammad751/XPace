/**
 *Submitted for verification at testnet.bscscan.com on 2023-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
    function getWithdrawable(address _user) external view returns(uint256);
    function setWithdraw(address _user) external;
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;
    constructor() {
        _paused = false;
    }
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }
    modifier whenPaused() {
        _requirePaused();
        _;
    }
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract XpaceStaking is Pausable, Ownable {
    using SafeMath for uint256;
    IERC721 public NFT;
    IERC20 public Space;

    uint256 referDepth = 8;
    uint256 minutesPerMonth = 43200;
    uint256 constant perNFT = 10e18;

    uint256 public unstakeTime = 2 minutes; // 24 hours
    uint256 public tokenPrice;
    uint256 dollerPrice = 10 ether; // 10 ether
    uint256 oneCoin = 1e18;

    bool public canUnstake;

    mapping(address => uint256) public unstakedROI;
    mapping(address => uint256) public canWithdraw;


    uint256[8] levelReward = 
    [
        925925926000,196759250000000,520833330000000,1099537030000000,
        5787037030000000,12731481480000000,27777777770000000,81018518510000000
    ];

    uint256[8] levels = 
    [
        40000000000000000,42500000000000000,45000000000000000,47500000000000000,
        50000000000000000,55000000000000000,60000000000000000,70000000000000000
    ];

    uint256[8] levelsPrice = [10e18,20e18,50e18,100e18,500e18,1000e18,2000e18,5000e18];


    struct userData{
        uint256 tokenId;
        uint256 Tokens;
        uint256 time;
    }

    mapping(address => uint256) public userReward;
    // user = level = count
    mapping(address => mapping(uint256 => uint256)) public userCount;
    mapping(address => uint256) public userLockedTokens;
    // user = level = struct
    mapping(address => mapping(uint256 => userData[])) public userInfo;

    mapping(address => uint256[]) private withdrawlHistory;

    constructor(address _token, uint256 _tokenPrice) // 0.05 ether = 50000000000000000
    {  
        // Space = IERC20(_token);  /// 0x4a53d5A3Aad9Bd8Ed4E4C7eaf7a319F8f71ec896
        Space = IERC20(_token);
        setPrices(dollerPrice, _tokenPrice);
    }

    modifier onlySpaceNft()
    {
        require(address(NFT) != address(0), "Calling null address");
        require(msg.sender == address(NFT)  , "Caller is not from NFT");
        _;
    }

    function lockNFT(address user_, uint256 _level, uint256 _tokenId, uint256 _tokens) 
    external 
    onlySpaceNft
    {
        userCount[user_][_level] = userCount[user_][_level].add(1);
        userInfo[user_][_level].push(
            userData(
                _tokenId,
                _tokens,
                block.timestamp
            )
        );
        userLockedTokens[user_] = userLockedTokens[user_].add(_tokens);
    }

    function getTime(address _user, uint256 _level, uint256 _index) public view returns (uint256){
        uint256 _usertime = userInfo[_user][_level][_index].time;
        uint256 _time = ((block.timestamp).sub(_usertime)).div(60);
        return _time;
    }

    function getMinutReward(address _user, uint256 _level, uint256 _index) public view returns(uint256){
        uint256 _levelAmount = userInfo[_user][_level][_index].Tokens;
        uint256 per_token_reward = levels[_level-1];
        uint256 _totalTokens = (_levelAmount.mul(per_token_reward)).div(1e18);
        uint256 _perMinut = _totalTokens.div(minutesPerMonth);
        return _perMinut;
    }

    function userROI(address _user) public view returns(uint256){
        uint256 _totalReward;
        uint256 _levelAmount;
        uint256 _time;
        uint256 _finalRew;
        for(uint256 i = 1; i<= referDepth; i++){
            for(uint256 j; j< userInfo[_user][i].length; j++){
                _time = getTime(_user, i, j);
                _levelAmount = getMinutReward(_user, i, j);
                _totalReward += _levelAmount.mul(_time);
            }
        }

        _finalRew = _totalReward.add(unstakedROI[_user]);
        return _finalRew.sub(userReward[_user]);
    }

    function withdrawROI() public {
        if((block.timestamp) >= canWithdraw[msg.sender])
        {
            uint256 _userReward = userROI(msg.sender);
            address _user = msg.sender;
            uint256 _reward = NFT.getWithdrawable(_user);
            userReward[msg.sender] = userReward[msg.sender].add(_userReward);
            uint256 _totalReward = _reward.add(_userReward);
            
            require(getTokenPrice(_totalReward), "not enough coins to withdraw");

            NFT.setWithdraw(_user);
            
            withdrawlHistory[msg.sender].push(_totalReward);
            canWithdraw[msg.sender] = block.timestamp.add(unstakeTime); // 24 hours

            Space.transfer(msg.sender, _totalReward);
        }
    }

    function getPoints(uint256 _level) public view returns(uint256){
        uint256 _price = levelsPrice[_level - 1];
        uint256 totalCoins;
        totalCoins = (_price.mul(perNFT)).div(1e18);
        return totalCoins;
    }
 
    function setUnstakeROI(address _user, uint256 _level, uint256 _id) internal {
        uint256 _total;
        uint256 _time = getTime(_user, _level, _id);
        uint256 _roi = getMinutReward(_user, _level, _id);
        _total = _roi.mul(_time);
        uint256 _coins = getPoints(_level);
        unstakedROI[_user] = unstakedROI[_user].add(_total);
        userLockedTokens[_user] = userLockedTokens[_user].sub(_coins);
    }
    
    function unstakeNFTs(address _user, uint256 _level, uint256[] memory _tokenIds) public {
        require(canUnstake, "cannot unstake");
        withdrawROI();
        uint256 _tokens;
        
        for(uint256 i; i< _tokenIds.length; i++){
            (uint256 _index, bool isThere) = isExist(_user, _level, _tokenIds[i]);
            if(isThere)
            {
                _tokens = userInfo[_user][_level][_index].Tokens;
                setUnstakeROI(_user, _level, _index);
                NFT.transferFrom(address(this), _user, _tokenIds[i]);
                Space.transfer(msg.sender, _tokens);

                userInfo[_user][_level][_index].tokenId = userInfo[_user][_level][(userInfo[_user][_level]).length -1].tokenId;
                userInfo[_user][_level][_index].Tokens = userInfo[_user][_level][(userInfo[_user][_level]).length -1].Tokens;
                userInfo[_user][_level][_index].time = userInfo[_user][_level][(userInfo[_user][_level]).length -1].time;

                userInfo[_user][_level].pop();
            }
        }
    }

    function isExist(address _user, uint256 _level, uint256 _tokenId) public view returns(uint256, bool){
        for(uint256 i; i< userInfo[_user][_level].length; i++){
            if(_tokenId == userInfo[_user][_level][i].tokenId){
                return (i ,true);
            }
        }
        return (0, false);
    }

    function getUserIds(address _user, uint256 _level) 
    public  
    view 
    returns(uint256[] memory)
    {
        uint256[] memory ids = new uint256[](userInfo[_user][_level].length);
        for (uint256 i; i< ids.length; i++){
            ids[i] = userInfo[_user][_level][i].tokenId;
        }
        return ids;
    }

    function getWithdrawedHistory(address _user) public view returns(uint256[] memory)
    {    return withdrawlHistory[_user];    }

    function getUserLockedTokens(address _user) public view returns (uint256)
    {    return userLockedTokens[_user];   }

    function getTokenPrice(uint256 _value) public view returns(bool) // withdrawl amount from frontend
    {   
        uint256 _value_1;
        uint256 _finalPrice;
        _value_1 = (oneCoin.mul(1e18)).div(tokenPrice);
        _finalPrice = ((_value_1).mul(dollerPrice)).div(1e18);

        if(_finalPrice <= _value)
        { return true; }
        else{ return false; }
    }

    function setPrices(uint256 _dPrice, uint256 _tPrice) 
    public onlyOwner
    { // 0.05 ether
        dollerPrice = _dPrice*10**18;
        tokenPrice = _tPrice*10**18;
    }

    function setUnstake() 
    external onlyOwner
    {   canUnstake = !canUnstake;   }

    function setNFTAddress(address _nft) 
    external onlyOwner
    {    NFT = IERC721(_nft);   }

    function setTokenAddress(address _token) external onlyOwner{
        Space = IERC20(_token);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) 
    {    return IERC721Receiver.onERC721Received.selector;  }

}